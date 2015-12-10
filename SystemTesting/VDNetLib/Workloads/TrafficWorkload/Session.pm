#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::Session;
my $version = "1.0";

#
# Session describes a flow of traffic between two machines. It
# collects all the information needed to generate traffic flow
# like Duration, PacketSize, Source, Destination etc and give it
# to TrafficTool in a format which TrafficTool understands.
# Provides a list of Rules to check if a given combination
# of traffic keys makes sense or not. E.g requestSize(TCP_RR) and
# messageSize (TCP_STREAM) in same session cannot exist.
# Currently supported traffic keys are:

use strict;
use warnings;
use Data::Dumper;
use Switch;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw( FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Workloads::TrafficWorkload::TrafficTool;

BEGIN {
    use Exporter();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK,);
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(UpdateDefaults);
};

# Use for reading and writing port numbers engine calls parallel
# instances of traffic workload modules.
use Fcntl qw(:flock);

#unreserved public ports being with 49152.Because linux or windows always need run
#some other service that will be ocuppied port begin 49152.So we start traffic port
# at 49162,that will cut the time that vdnet checked the port is ocuppied .
#This value is incremented for every session thus every session runs on a unique port.

my  $defaultSessionPort = 49162;

# Default values to set in session when a user does not provide them
# as they are minimum values required to run a session.
# These values should be thoughtfully selected.
# Only the minimum values to run a traffic session will go here
# Please do not set default values for all types of possbile traffic keys.
my %sessionDefaults = (
                   'l3protocol' => "IPv4",# IPv6,ICMP,ICMPv6
                   'l4protocol' => "TCP",# UDP
                   'bursttype' => "STREAM", # RR
                   'noofoutbound' => 1, # client on SUT (a common scenario)
                   'testduration'  => 5, # in seconds
                   'dataintegritycheck' => "disable",
);

# Session defaults specific to each session which might change depending upon
# the user input
my %currentSessionDefaults = %sessionDefaults;


########################################################################
#
# new -
#       Creates object of Session class. Each session will have its own
#       stdout, result and status of the traffic.
#
# Input:
#       Session Key (optional)
#       Session Value (optional)
#
# Results:
#       An instance/object of Session class.
#
# Side effects:
#       None
#
########################################################################

sub new
{

   my $class = shift;
   my %args  = @_;
   my $sessionKey   = $args{'sessionKey'} || undef ;
   my $sessionValue = $args{'sessionValue'} || undef;
   my $sessionPort  = $args{'port'};
   my $logDir       = $args{'logdir'};
   my $staf         = $args{'staf'};

   if (not defined $logDir) {
      $vdLogger->Error("logDir input missing in new of Session()");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $sessionPort) {
      $sessionPort = $class->ReadAndWritePort();
   }

   my $sessionID = VDNetLib::Common::Utilities::GetTimeStamp() . "-" . int(rand(1000));
   $sessionID = "session-" . $sessionID;
   my $sessionLogs = $logDir. $sessionID . "/";
   my $self = {
      'result'      => "",
      'sessionport' => $sessionPort,
      'toolname'    => "",
      'noofinbound' => "",
      'noofoutbound' => "",
      'bursttype' => "",
      'localsendsocketsize' => "",
      'localreceivesocketsize' => "",
      'remotesendsocketsize' => "",
      'remotereceivesocketsize' => "",
      'sendmessagesize' => "",
      'receivemessagesize' => "",
      'requestsize' => "",
      'responsesize' => "",
      'routingscheme' => "",
      'testduration' => "",
      'l3protocol' => "",
      'l4protocol' => "",
      'alterbufferalignment' => "",
      'dataintegritycheck' => "",
      'multicasttimetolive' => "",
      'udpbandwidth' => "",
      'pktfragmentation' => "",
      'pingpktsize' => "",
      'reuseport' => "",
      'tcpmss' => "",
      'tcpwindowsize' => "",
      'iperfthreads' => "",
      'natedport' => "",
      'minexpresult' => "",
      'maxthroughput' => "",
      'dvportnum' => "",
      'statstype' => "",
      'packetfile' => "",
      'packettype' => "",
      'disablenagle' => "",
      'sessionflow' => "",
      'clientport' => "",
      # Folder which will contain the session logs, post mortem logs etc
      'sessionlogs' => $sessionLogs,
      'sessionid' => $sessionID,
      # Array of temp files
      'sessionscratchfiles' => [],
      'staf' => $staf,
   };

   if (defined $sessionKey && defined $sessionValue) {
      $self->{$sessionKey} = $sessionValue;
   }

   unless(-d $self->{sessionlogs}){
      my $ret = `mkdir -p $self->{sessionlogs}`;
      if ($ret ne "") {
         $vdLogger->Error("Failed to create session logs dir:".
                          "$self->{sessionlogs}");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   }
   # A new session should start on a new server and client port.
   # Also helps when workloads.pm calls traffic workload twice in
   # parallel. Both the calls will get different port numbers.
   bless $self, $class;
   return $self;

}


########################################################################
#
# ReadAndWritePort -
#       Provides a locking mechanism for reading and writing ports.
#       Prevents contentions between parallel processes trying to
#       read and write port at the same time. If one provides a port
#       the count will start from that port number otherwise ports will
#       allocated from default number 49152.
#
# Input:
#       currentPort (optional)
#
# Results:
#       Port Number
#
# Side effects:
#       This method will keep incrementing port by 1. But according to
#       TCPIP fundamentals maximum port can be 65535. Thus when we
#       run a test with more than 16383 (65535 - 49152) we will have
#       the risk of giving out invalid port number. If we ever run
#       into that issue, I we can recycle the defaultSessionPort
#
########################################################################

sub ReadAndWritePort
{
   my $self = shift;
   my $currentPort = shift;
   my $ret = undef;
   if (defined $currentPort) {
      $defaultSessionPort = $currentPort + 1;
   }

   $ret = $defaultSessionPort;
   $defaultSessionPort++;
   return $ret;
}


########################################################################
#
# UpdateDefaults -
#       There are session defaults(minimum traffic values to run a session)
#       This method gives user the control to modify those defaults
#       as well.
#
# Input:
#       Traffic hash (optional)
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case trafficHash is not defined
#
# Side effects:
#       My wild guess is that when two parallel traffic workload be
#       running, one workload might update the default session values
#       of the other workload. Lets see.
#
########################################################################

sub UpdateDefaults
{
   # For every key passed in the hash if that key exists in sessionDefaults
   # and value of that key is unique (without any - or ,) then we update
   # this unique value in CurrentSessionDefaults array.
   my $trafficHash = shift;
   if (not defined $trafficHash) {
      $vdLogger->Error("Parameters missing in UpdateDefaults of Traffic".
                       "Workload. trafficHash:$trafficHash ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Initialize currentSessionDefaults to be same as sessionDefaults
   %currentSessionDefaults = %sessionDefaults;

   my $trafficKey;
   foreach $trafficKey (keys %$trafficHash) {
      if (defined $currentSessionDefaults{$trafficKey}) {
         if ($trafficHash->{$trafficKey} =~ m/(,|-)/) {
            # No need to update the defaults
         } else {
            $currentSessionDefaults{$trafficKey} = $trafficHash->{$trafficKey};
            $vdLogger->Trace("Updating Key:$trafficKey in CurrentSessionDefaults ".
                          "hash to value:$trafficHash->{$trafficKey}");
         }
      }
   } # end of for loop
   return SUCCESS;
}


########################################################################
#
# ApplySessionDefaults -
#       There are session defaults(minimum traffic values to run a session)
#       This method applies those default values to sessions missing them
#       For each key in sessionDefaults global array check if value of the
#       key conflicts with the existing key=values of traffic by consulting
#       SessionRuleCheck method.
#
# Input:
#       string - a flag to check rule or not before applying defaults.
#
# Results:
#       None
#
# Side effects:
#
########################################################################

sub ApplySessionDefaults
{
   my $self = shift;
   my $checkrule = shift || "checkrule";
   my ($ruleCheckResult, $defaultSessionKey);
   foreach $defaultSessionKey (keys %currentSessionDefaults) {
      if ($checkrule =~ /^checkrule$/i) {
         $ruleCheckResult = $self->SessionRuleCheck(
                                    $defaultSessionKey,
                                    $currentSessionDefaults{$defaultSessionKey}
                                                   );
         if ($ruleCheckResult ne 0) {
            $self->SetKeyValueInSession($defaultSessionKey,$ruleCheckResult);
         }
      } else {
         $self->SetKeyValueInSession($defaultSessionKey,
                                     $currentSessionDefaults{$defaultSessionKey});
      }
   }
}


########################################################################
#
# CloneSessionObject -
#       Clones session objects which helps in generating a combination of
#       traffic keys, thus generating different sessions.
#       It handles conflicting trafficWorkload Keys also. E.g. Session
#       Object with inbound session set cannot be cloned for creating session
#       object with outbound session as they are conflicting parameters
#       Thus it called SessionRuleCheck before cloning object.
#
# Input:
#       SessionKey (optional)
#       SessionValue (optional)
#
# Results:
#       0 in case of conflict(suggesting it cannot be cloned)
#       Session Object - A cloned object in case of success.
#       FAILURE - in case of error.
#
# Side effects:
#       Only does a shallow copy so if the hash to be cloned
#       contains another nested hash the cloned object will
#       also point to the same nested hash.
#
########################################################################

sub CloneSessionObject
{
   my ($self, $sessionKey, $sessionValue)  = @_;
   if (not defined $sessionKey || not defined $sessionValue) {
      $vdLogger->Trace("CloneSessionObject() called without new ".
                       "key value for cloned object");
   }

   my $newObj;
   if (defined $sessionKey && defined $sessionValue) {
      my $ret = $self->SessionRuleCheck($sessionKey,$sessionValue);
      if ($ret eq 0 ) {
         $vdLogger->Trace("SessionRuleCheck didnt allow key:$sessionKey ".
                          "value:$sessionValue while cloning");
         return 0;
      }
   }

   # We do a deep copy for 2 level (Copy Constructor concept)
   # if $self has client and server defined then we dont want to
   # copy the instance of client and server, we just want to
   # copy the tempalte of client and server. Thus we remove the instance
   foreach my $key (keys %$self) {
      # While cloning we dont clone the verification handle.
      # This is for old Verification module. New Verification handle
      # is not with Session.pm but with TrafficWorklload.pm itself.
      if ($key =~ /sessionid/) {
         $newObj->{$key} = "session-" .
                           VDNetLib::Common::Utilities::GetTimeStamp() .
                           "-" . int(rand(1000));
         my $origlogs = $self->{sessionlogs};
         my $logDir = $origlogs =~ m/(.*\/)(session.*)$/;
         $newObj->{sessionlogs} =  $1. $newObj->{$key} . "/";
         unless(-d $self->{sessionlogs}){
            my $ret = `mkdir -p $self->{sessionlogs}`;
            if ($ret ne "") {
               $vdLogger->Error("Failed to create session logs dir:".
                                "$self->{sessionlogs}");
               VDSetLastError("EFAILED");
               return FAILURE;
            }
         }
         $newObj->{sessionscratchfiles} =  [];
         next;
      }
      if ($key =~ /veriObj/i || $key =~ /verificationHandle/i ||
         $key =~ /sessionlogs/i) {
         next;
      }
      my $value = $self->{$key};
      if (($value =~ /HASH/) && ($key !~ /staf/i)){
         my $nestedHash = $value;
         foreach my $nestedKey (keys %$nestedHash) {
            my $nestedValue = $nestedHash->{$nestedKey};
            if ($nestedKey !~ /instance/) {
               $newObj->{$key}->{$nestedKey} = $nestedValue;
            }
         }
      } else {
         $newObj->{$key} = $value
      }
   }
   if (defined $sessionKey && defined $sessionValue) {
      $newObj->{"$sessionKey"} = "$sessionValue";
   }
   bless $newObj, __PACKAGE__;
   return $newObj;
}


########################################################################
#
# SessionRuleCheck -
#       Checks the rule table{swtich-case} so that values in a session
#       do not conflict each other.
#       E.g. bursttype => "STREAM", and
#       l3protocol => ICMP is a conflicting case
#       More Examples of conflicting traffic
#       1) Inbound & Outbound - a session cannot be both at the same time
#       If one wants to run both he can run two different sessions on
#       same set of machines.
#       2) ToolName & RoutingType - toolname netperf means routing will
#       be unicast, toolname iperf means routing will be multicast,
#       toolname ping means routing can be broadcast.

#
# Input:
#       SessionKey (required)
#       SessionValue (required)
#
# Results:
#       0 in case of conflict
#       default sessionKey value or SUCCESS in case of no conflict
#
# Side effects:
#       Every traffic key should have a swtich case other wise it will
#       return 0. This makes sure no new key is used by User of traffic
#       hash without the knowledge of Session Rule Check method.
#
########################################################################
# TODO: IPv6 Based netperf tests like TCP_STREAM,RR,CRR,MAERTS needs
# to be fixed as and when requirements arise.

sub SessionRuleCheck
{
   my ($self, $sessionKey, $sessionValue)  = @_;
   if (not defined $sessionKey || not defined $sessionValue) {
      $vdLogger->Error("one or more parameters missing in ".
                       "SessionRuleCheck");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # I will try to explain all the rule violations for all thses switch
   # cases.
   switch ($sessionKey) {
      # No special rule at this moment for the following keys
      case m/(testadapter|testinttype|supportadapter|supportinttype)/i {
         return SUCCESS;
      }
      # If you are trying to apply bursttype to a session then that session
      # should not have an already defined bursttype. OR have ICMP defined.
      # One can also not set bursttype as stream when request and response
      # sizes are already defined.
      case m/(bursttype)/i {
         if ($self->{'bursttype'} ne "" || ($self->{'l3protocol'} ne "" &&
             $self->{'l3protocol'} =~ m/(ICMP|ICMPv6)/i) ||
             ( ($self->{requestsize} ne "" ||
                $self->{responsesize}) ne "" &&
                $sessionValue =~ m/stream/i ) ||
             ( ($self->{sendmessagesize} ne "" ||
                $self->{receivemessagesize} ne "") &&
                $sessionValue =~ m/rr/i )) {
            return 0;
         } else {
            return $currentSessionDefaults{'bursttype'};
         }
      }
      # If you are trying to apply messagesize traffic to a session then that
      # session should not have bursttype = rr or have some value of request
      # and response size. This is because messagesize belongs to stream
      # and request response belong to rr type of burst data.
      case m/(sendmessagesize|receivemessagesize)/i {
         if ($self->{'bursttype'} =~ m/rr/i ||
             $self->{requestsize} ne ""||
             $self->{responsesize} ne "") {
            return 0;
         }
         last;
      }
      # If you are trying to set some value of request or response size
      # traffic to a session then that session should not have bursttype
      # as stream already defined.
      # That session should not have either send or receive message size
      # defined.
      case m/(requestsize|responsesize)/i {
         if ($self->{'bursttype'} =~ m/stream/i ||
             $self->{sendmessagesize} ne "" ||
             $self->{receivemessagesize} ne "") {
            return 0;
         }
         last;
      }
      # A generic data that applies to all kinds of traffic(at least).
      # according to my Understanding. Thus it has no rule.
      case m/(localsendsocketsize|remotesendsocketsize)/i {
         last;
      }
      # A generic data that applies to all kinds of traffic(at least).
      # according to my Understanding. Thus it has no rule.
      case m/(localreceivesocketsize|remotereceivesocketsize)/i {
         last;
      }
      case m/(bindingenable)/i {
         last;
      }
      # If you are trying to set a value of l3protocol in a session of
      # traffic then that session should not have already defined l3protocol
      # (as we prevent overwrite while applying currentSessionDefaults). It should
      # not have l4protocol (tcp or udp) defined in case the value we are
      # trying to set is ICMP
      case m/(l3protocol)/i {
         if ( $self->{'l3protocol'} ne ""||
             ( $self->{'l4protocol'} ne ""&&
             $sessionValue =~ m/ICMP|ICMPv6/i )) {
            return 0;
         } else {
           return $currentSessionDefaults{'l3protocol'};
         }
      }
      # If you are trying to set a value of l4protocol in a session of
      # traffic then that session should not have already defined l4protocol
      # (as we prevent overwrite while applying currentSessionDefaults). It should
      # not have l3protocol as ICMP
      case m/(l4protocol)/i {
         if ($self->{'l4protocol'} ne "" || ($self->{'l3protocol'} ne "" &&
              $self->{'l3protocol'}=~ m/(ICMP|ICMPv6)/i)) {
            return 0;
         } else {
            return $currentSessionDefaults{'l4protocol'};
         }
      }
      # If you are trying to set a value of routingScheme in a session of
      # traffic then that session should not have already defined l4protocol
      # (as we prevent overwrite while applying currentSessionDefaults). It should
      # not have l3protocol as ICMP
      case m/(routingscheme)/i {
         if ($self->{'toolname'} ne "" && (
             $self->{'toolname'} =~ m/(netperf|ping)/i &&
             $sessionValue=~m/multicast/i)) {
            return 0;
         }
         last;
      }
      # If you are trying to set a value of testDuration in a session of
      # traffic then that session should not have already defined testDuration
      case m/(testduration)/i {
         if ($self->{'testduration'} ne "") {
            return 0;
         } else {
            return $currentSessionDefaults{'testduration'};
         }
      }
      # If you are trying to set a value of toolName in a session of
      # traffic then that session should not have multicast as routingScheme
      # when value of toolName key is netperf or ping
      case m/(toolname)/i {
         if ($self->{'routingscheme'} ne "" &&
             $self->{'routingscheme'} =~ m/multicast/i &&
             $sessionValue=~m/(netperf)/i) {
            return 0;
         }
         last;
      }
      # This just prevents overwriting value of inbound or outbound
      case m/(noofinbound|noofoutbound)/i {
         if ($self->{'noofoutbound'} ne ""||
             $self->{'noofinbound'} ne "") {
            return 0;
         } else {
            return $currentSessionDefaults{'noofoutbound'};
         }
         last;
      }
      # This just prevents overwriting value of alterbufferalignment
      case m/(alterbufferalignment)/i {
         if ($self->{'alterbufferalignment'} ne "") {
            return 0;
         }
         last;
      }
      case m/(dataintegritycheck)/i {
         if ($self->{'dataintegritycheck'} ne "") {
            return 0;
         } else {
            return $currentSessionDefaults{'dataintegritycheck'};
         }
      }
      # If multicasttimetolive is defined we cannot overwrite it.
      # if multicast time to love is to be used tool should not
      # be netperf or ping
      case m/(multicasttimetolive)/i {
         if ($self->{'multicasttimetolive'} ne "") {
            return 0;
         }
         last;
      }
      case m/(udpbandwidth)/i {
         # Setting the buffer size to 1M as default when a UDP
         # bandwidth is used.
         $self->{'tcpwindowsize'} = "1M" if $self->{'tcpwindowsize'} eq "";
         if ($self->{'udpbandwidth'} ne "" ||
             $self->{'l4protocol'} =~ m/tcp/i) {
            return 0;
         }
         last;
      }
      # If tcpwindowsize is defined we should not have UDP
      # as a testing protocol defined or even ICMP
      case m/(tcpwindowsize)/i {
         if ($self->{'tcpwindowsize'} ne "" ||
             $self->{'l4protocol'} =~ m/udp/i ||
             ($self->{'l3protocol'} =~ m/ICMP|ICMPv6/i)) {
            return 0;
         }
         last;
      }
      # If tcpmss is defined we should not have UDP
      # as a testing protocol defined or even ICMP
      case m/(tcpmss)/i {
         if ($self->{'tcpmss'} ne "" ||
             $self->{'l4protocol'} =~ m/udp/i ||
             ($self->{'l3protocol'} =~ m/ICMP|ICMPv6/i)) {
            return 0;
         }
         last;
      }
      case m/(pktfragmentation)/i {
         if ($self->{'pktfragmentation'} ne "") {
            return 0;
         }
         last;
      }
      case m/(iperfthreads)/i {
         if ($self->{'iperfthreads'} ne "") {
            return 0;
         }
         last;
      }
      case m/(tos)/i {
         # iperf ToS parameter
         last;
      }
      case m/(pingpktsize)/i {
         if ($self->{'pingpktsize'} ne "") {
            return 0;
         }
         last;
      }
      # For case when there is NAT router between client and server
      case m/(natedport)/i {
         if ($self->{'natedport'} ne "") {
            return 0;
         }
         last;
      }
      # This sets the minimum expected result value for the session.
      case m/(minexpresult)/i {
         if ($self->{'minexpresult'} ne "") {
            return 0;
         }
         last;
      }
      # This defines max exp througput value.
      # It helps in traffic shapping.
      case m/(maxthroughput)/i {
         if ($self->{'maxthroughput'} ne "") {
            return 0;
         }
         last;
      }
      case m/(dvportnum)/i {
         if ($self->{'dvportnum'} ne "") {
            return 0;
         }
         last;
      }
      case m/(statstype)/i {
         if ($self->{'statstype'} ne "") {
            return 0;
         }
         last;
      }
      # This is used for tcpreplay
      case m/(packetfile)/i {
         if ($self->{packetfile} ne "") {
            return 0;
         }
         last;
      }
      case m/(packettype)/i {
         if ($self->{packettype} ne "") {
            return 0;
         }
         last;
      }
      case m/(disablenagle)/i {
         if ($self->{disablenagle} ne "") {
            return 0;
         }
         last;
      }
      case m/(maxtimeout)/i {
    # Do nothing. This is the generic maxtimeout
    # key,  which  is  used to set the alarm for
    # the given value in "Workload.pm".  This is
    # to make sure that no  workload  takes more
    # than the maximum expected time to   finish
    # or hangs forever.
         last;
      }
      case m/(StreamBlockSize)/i {
	 last;
      }
      case m/(StreamBlockSizeType)/i {
	 last;
      }
      case m/(stream)/i {
	 last;
      }
      # This sets the local  client port to be used for netperf traffic.
      case m/(clientport)/i {
         if ($self->{'clientport'} ne "") {
            return 0;
         }
         last;
      }
      #Below set of keys used for fragroute tool
      case m/(fragmentsize)/i {
         last;
      }
      case m/(fragmenttobedelayed)/i {
         last;
      }
      case m/(fragmentdelay)/i {
         last;
      }
      case m/(dropfragment)/{
         last;
      }
      case m/(dropprobability)/i {
         last;
      }
      case m/(duplicatefragment)/i {
         last;
      }
      case m/(duplicateprobability)/i {
         last;
      }
      case m/(orderfragments)/i {
         last;
      }
      case m/(ipttl)/i {
         last;
      }
      case m/(tcpchaff)/i {
         last;
      }
      case m/(ipchaff)/i {
         last;
      }
      case m/(segmentsize)/i {
         last;
      }
      # key to define the source ip address
      case m/(sourceip)/i {
         last;
      }
      case m/(McastMethod)/i {
	     last;
      }
      case m/(McastGroupAddr)/i {
	     last;
      }
      case m/(McastIpFamily)/i {
	     last;
      }
      case m/(McastSourceAddrs)/i {
	     last;
      }
      case m/(maxlossrate)/i {
	     last;
      }
      case m/(arpprobe)/i {
         last;
      }
      case m/(requestcount|threadcount|concurrentclients)/i {
	     last;
      }
      # For scapy
      case m/(DestinationAddress|protocol|interval|ipttl|pktcount)/i {
         last;
      }
      case m/(sourceport|destport|SourceAddress|SourceMAC|DestinationMAC)/i {
         last;
      }
      case m/(packetinterval)/i {
         last;
      }
      case m/(multicastip)/i {
         last;
      }
      case m/(payload)/i {
         last;
      }
      case m/(tcpflags|tcpseq|tcpack)/i {
         last;
      }
      else {
         $vdLogger->Error("Not able to handle $sessionKey=$sessionValue ".
                          "pair in RuleCheck of TrafficWorkload");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# SetKeyValueInSession -
#       Sets a Key and Value in a Session. Keeps them lowercase.
#
# Input:
#       SessionKey (required)
#       SessionValue (required)
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetKeyValueInSession
{
   my ($self, $sessionKey, $sessionValue)  = @_;

   if (defined $sessionKey && defined $sessionValue) {
      $sessionValue =~ s/^\s+//; #remove leading space
      $sessionValue =~ s/\s+$//; #remove trailing space
      $self->{lc($sessionKey)} = lc($sessionValue);
   } else {
      $vdLogger->Error("one or more parameters missing in ".
                       "SetKeyValueInSession. sessionKey:$sessionKey ".
                       "sessionValue:$sessionValue");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# SetSessionServerClient -
#       1) Assuming that for inbound traffic means - SUT is running
#       Server of that Tool(Netserver) .
#       2) Port is assisgned in such a way that ports of multiple
#       session present on same host don't content with each other.
#       Client and Server object both contain same port for a session.
#       TrafficTool starts server on that port and client connects to
#       server on that port.
#
# Input:
#       Pointer to SUT Hash
#       Pointer to Helper Hash
#
# Results:
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
########################################################################

sub SetSessionServerClient
{
   my ($self, $SUT, $helper)  = @_;
   if ((not defined $SUT) || ($SUT eq FAILURE)) {
      $vdLogger->Error("SUT parameter missing in ".
                       "SetSessionServerClient");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ((not defined $helper) || ($helper eq FAILURE)) {
      $vdLogger->Error("Helper parameter missing in ".
                       "SetSessionServerClient");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my %sessionSUT = %$SUT;
   my %sessionHelper = %$helper;


   #TODO: deprecate this if in future multicast doesnt use it.
   my $count;
   if (not defined $self->{'noofmachines'}) {
      $self->{'noofmachines'} = 1;
   }
   $count = $self->{'noofmachines'};

   if ($self->{'noofinbound'} ne "") {
      # Server is on SUT and Client is on Helper
      $self->{"server"} = \%sessionSUT;
      $self->{"client"} = \%sessionHelper;
   } else {
      # Server is on Helper and Client is on SUT
      $self->{"client"} = \%sessionSUT;
      $self->{"server"} = \%sessionHelper;
   }

   # This is a hack to set the number of parallel sessions to 1
   # as ESX client or server wont be able to handle multiple netperf or
   # iperf clients.
   # Ref: https://wiki.eng.vmware.com/Netperf-Iperf
   if ($self->{"client"}->{'os'} =~ m/esx|vmkernel/i ||
      $self->{"server"}->{'os'} =~ m/esx|vmkernel/i) {
      if (defined $self->{'noofinbound'} && $self->{'noofinbound'} gt 1){
         $self->{'noofinbound'} = 1;
      }
      if (defined $self->{'noofoutbound'} && $self->{'noofoutbound'} gt 1){
         $self->{'noofoutbound'} = 1;
      }
   }

   #
   # Now that we know the client and server for this session we
   # can generated a session id based on that.
   #
   $self->{sessionflow} = $self->{'client'}->{nodeid} . " --> " .
                          $self->{'server'}->{nodeid};
   $self->{'noofmachines'} = $self->{'noofmachines'} + 1;
}

########################################################################
#
# StartSession -
#       Starts the session by calling the traffictool module.
#       Creates Server and then client instances depending on the value
#       of either noofinbound or noofoutbound
#
# Input:
#       None
#
# Results:
#       SUCCESS - in case session is started successfully
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
########################################################################

sub StartSession
{

   my ($self) = shift;
   my $verificationType = shift;
   my $verifyMachine = shift;
   my $noofSessions = $self->{noofinbound} || $self->{noofoutbound};
   my $trafficToolObj;

   my $verificationCalled = 0;
   # A session will have either noofinbound defined or noofoutbound defined
   # both cannot be defined simultaneously.
   # if noofoutbound=2 that means start one server and then two clients in
   # parellel, which will connect to that server.
   # $instance is the id attached to these objects.
   # Server will always have id 0 attached to it and client will have 1, 2...
   # depending on the number of clients in the session.

   $noofSessions = $noofSessions + 1;
   my $instance = 0;
   while($noofSessions--) {
      $trafficToolObj = VDNetLib::Workloads::TrafficWorkload::TrafficTool->new(
                                                                    $self,
                                                                    $instance);
      if ($trafficToolObj eq FAILURE) {
         $vdLogger->Error("TrafficTool new method returned failure");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      if ($verificationCalled == 0 && $verificationType ne "") {
         # Merging the traffic and netadpter hash.
         my $verificationHash = {};
         %$verificationHash = %$self;
         if (defined $verifyMachine){
            # This means that verification has to be launched on machine
            # which is different from client/server on which traffic is flowing
            # To leverage the code of verification lets strip the existing
            # server hash in traffic speicification and attach the new machine
            # as server and then call verification.
            $vdLogger->Trace("Attaching ".Dumper($verifyMachine) .
                           "for launching verification on seperate machine");
            $verificationHash->{sniffer} = $verifyMachine;
         }
         #
         # Switching to dynamic loading. This saves memory and it was
         # also conflicinting with same fileName in different folder
         # saying new redefined in Verification.pm
         #
         my $veriModule = "VDNetLib::OldVerification::Verification";
         eval "require $veriModule";
         if ($@) {
            $vdLogger->Error("Failed to load Verification $veriModule $@");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         my $veriObj = $veriModule->new(workload => $verificationHash,
                                        verification => $verificationType,
                                        );
         if ($veriObj eq FAILURE) {
            $vdLogger->Error("Verification new method returned failure ".
                              Dumper($veriObj));
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         if ($veriObj->StartVerification() eq FAILURE) {
            $vdLogger->Error("StartVerification method returned failure");
            $vdLogger->Debug(Dumper($veriObj));
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $self->{veriObj} = $veriObj;
         $verificationCalled = 1;
      }

      $instance++;
   }
   return SUCCESS;
}

#########################################################################
#
# GetSessionResult -
#       Fetches the result of a session by calling GetResult on all client
#       objects.
#
# Input:
#       None
#
# Results:
#       FAILURE - in case of any execution error
#       FAIL - if expectations are not met
#       PASS - if expectaitons are met.
#
# Side effects:
#       None
#
########################################################################

sub GetSessionResult
{
   my $self = shift;
   my $timeout = shift;
   my $expVerificationResult = shift;
   my $minExpResult = undef;
   my $maxThroughput = undef;
   my $maxLossRate   = undef;
   my $postMortemFlag = 0;
   my $sid = $self->{sessionid};


   if (defined $self->{minexpresult} && $self->{minexpresult} ne ""){
      $minExpResult = $self->{minexpresult};
   }

   if (defined $self->{maxthroughput} && $self->{maxthroughput} ne ""){
      $maxThroughput = $self->{maxthroughput};
   }
   if (defined $self->{maxlossrate} && $self->{maxlossrate} ne "") {
      $maxLossRate = $self->{maxlossrate};
   }

   my $trafficResult = "NULL";
   my $verificationResult = SUCCESS;
   # A session will have either noofinbound defined or noofoutbound defined
   # both cannot be defined simultaneously.
   # if noofoutbound=2 that means start one server and two clients in
   # parellel which connect to that server.
   my $noofSessions = $self->{noofinbound} || $self->{noofoutbound};
   if ($self->{client}{os} =~ /spirent/i) {
      $noofSessions = 1;
   }

   my $clientCount = 1;
   do{
      # Put it in an array and combine the result of all parallel sessions
      my $clientInstance = 'instance'.$clientCount;

      $trafficResult = $self->{'client'}->{$clientInstance}->GetResult(
                                                        $self,
                                                        $timeout,
                                                        $minExpResult,
                                                         $maxThroughput);
      if ($trafficResult !~ m/SUCCESS|PASS/){
         # We cannot Warn or Error here as expected result might be to
         # fail. But lets put this in log file.
         $vdLogger->Trace( "Client-". $clientCount . ":".
                           $self->{'client'}->{controlip} .
                           " to Server:" . $self->{'server'}->{controlip} .
                           " returned " . $trafficResult);
      }
      $self->{'client'}->{$clientInstance}->{result} = $trafficResult;
      $clientCount++;
   } while($clientCount <= $noofSessions);

   # For iperf multicast traffic, also verify result from server side.
   if (($self->{toolname} =~ /iperf/i) &&
       ($self->{routingscheme} =~ m/multicast/i)) {
      $vdLogger->Info("Parse iperf multicast server side result for " .
                      "$self->{'server'}->{controlip}");
      my $trafficServerResult = undef;
      $trafficServerResult = $self->{'server'}->{'instance0'}->GetServerResult(
                                                               $self,
                                                               $minExpResult,
                                                               $maxThroughput,
                                                               $maxLossRate);
      if ($trafficServerResult !~ m/SUCCESS|PASS/) {
         $vdLogger->Error("Server side result for " .
                          "$self->{'server'}->{controlip} " .
                          " returned $trafficServerResult");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      }
   }

   if (defined $self->{veriObj}){
      my $veriObj = $self->{veriObj};
      if ($veriObj->StopVerification() eq FAILURE) {
         $vdLogger->Error("StopVerification method returned failure");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $verificationResult = $veriObj->GetResult();
      if ($verificationResult eq FAILURE) {
         $vdLogger->Error("Verification of traffic failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # Explicitly calling destructor of Verification's child module.
      $veriObj->DESTROY;
      $self->{veriObj} = "";
   }

   my $loopCount = 1;
   my $passCount = 0;
   my $failCount = 0;
   do {
      $trafficResult = $self->{'client'}->{'instance'.$loopCount}->{result};
      if ($trafficResult =~ m/SUCCESS|PASS/){
         $passCount++
      } else {
         $failCount++;
         if ($trafficResult =~ m/FAILURE/) {
            $vdLogger->Trace("Return value is FAILURE.");
            return FAILURE;
         }
      }
      $loopCount++;
   } while($loopCount <= $noofSessions);

   if ($passCount == 0) {
      $vdLogger->Warn("Traffic flow failed. $failCount client(s) failed"
                       ." in $sid");
      return "FAIL";
   } elsif ($failCount == 0) {
      $vdLogger->Trace("Traffic passed with flying colors for $sid");
      if (defined $expVerificationResult) {
         $vdLogger->Debug("Actual Verification result:".$verificationResult);
         if (($expVerificationResult =~ m/PASS/i &&
             $verificationResult ne "0") ||
            ($expVerificationResult =~ m/FAIL/i &&
            $verificationResult eq "0")) {
            $vdLogger->Info("Expected verification result: " .
                            $expVerificationResult . " matches " .
                            $verificationResult);
            return SUCCESS;
         } else {
            $vdLogger->Error("Expected verification result: " .
                            $expVerificationResult . " ! = " .
                            $verificationResult);
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
      return "PASS";
   } elsif ($passCount > $failCount) {
      $vdLogger->Info("Traffic results acceptable ". $failCount .
                      " flow(s) failed and " . $passCount . " flow(s) ".
                      "passed for $sid");
      if (defined $expVerificationResult) {
         $vdLogger->Debug("Actual Verification result:".$verificationResult);
         if (($expVerificationResult =~ m/PASS/i &&
             $verificationResult ne "0") ||
            ($expVerificationResult =~ m/FAIL/i &&
            $verificationResult eq "0")) {
            $vdLogger->Info("Expected verification result: " .
                            $expVerificationResult . " matches " .
                            $verificationResult);
            return SUCCESS;
         } else {
            $vdLogger->Error("Expected verification result: " .
                            $expVerificationResult . " ! = " .
                            $verificationResult);
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
      return "PASS";
   } elsif ($passCount <= $failCount) {
      $vdLogger->Warn("Intermittent traffic, results unacceptable.".
                      $failCount . " flow(s) failed and " . $passCount .
                      " flow(s) passed for $sid".
                      "Should re-run test.");
      VDSetLastError("EFAIL");
      return "FAIL";
   }
}

########################################################################
#
# GetFamily -
#       A utility method which returns string ipv6 in case the session's
#       l3protocol is ipv6.
#
# Input:
#       None
#
# Results:
#       string ipv6 - in case l3protocol is ipv6 or addressfamily is
#                     af_inet6.
#       string ipv4 (default) - otherwise
#
# Side effects:
#       None
#
########################################################################

sub GetFamily
{
   my $self = shift;
   if (($self->{l3protocol} =~ m/ipv6/i)) {
      return "ipv6";
   } else {
      return "ipv4";
   }
}


########################################################################
#
# GetRouting -
#       A utility method which returns routing Type.
#
# Input:
#       None
#
# Results:
#       string unicast - in case its unicast traffic
#       string multicast - in case its unicast traffic
#       string broadcast - in case its broadcast traffic
#       string flood - in case its flood traffic
#
# Side effects:
#       None
#
########################################################################

sub GetRouting
{
   my $self = shift;
   if ($self->{routingscheme} =~ m/broadcast/i) {
      return "broadcast";
   } elsif ($self->{routingscheme} =~ m/multicast/i) {
      return "multicast";
   }  elsif ($self->{routingscheme} =~ m/flood/i) {
      return "flood";
   } else {
      return "unicast";
   }
}


########################################################################
#
# SetTestSession -
#       As we clone hashes to reduce our work, sometimes we require to
#       reset the hash to just basic elements.
#
# Input:
#       None
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
########################################################################

sub SetTestSession
{
   my $self = shift;
   my $testSessionType = shift || "connectivity";
   my $options = shift;

   # Here we will preserve testbed, l3protocol (in case we want to test
   # IPv6 basic connectivity before running traffics).
   # We will reset most of the unwanted things. Ping modules will ignore
   # things which he does not understand like sendsocketsize, requestsize
   # etc. He we reset the things which he understand and as we want to
   # test just basic connectivity.
   $self->{noofinbound} = 1 if $self->{noofinbound} ne "";
   $self->{noofoutbound} = 1 if $self->{noofoutbound} ne "";
   if ($testSessionType =~ /connectivity/i) {
      $self->{testduration} = 5; # To send 5 Ping packets.
      $self->{pktfragmentation} = "";
      $self->{routingscheme} = "";
      $self->{pingpktsize} = "";
      # Connectivity test will pass even if 50% pass loss.
      $self->{minexpresult} = 49;
   } elsif ($testSessionType =~ /basic/i) {
      foreach my $key (keys %$self) {
         # We want to preserve the client and server hash
         # and wipe out rest of the stuff and then apply
         # session Defaults.
         my $value = $self->{$key};
         if (($value =~ /HASH/) || ($key =~ /^session/i)) {
             next;
         } else {
            $self->{$key} = "";
         }
      }
      $self->{'l3protocol'} = "IPv4";
      $self->{'l4protocol'} = "TCP";
      $self->{'bursttype'}  = "STREAM";
      $self->{'noofoutbound'} = 1;
      $self->{'testduration'} = 5;
   }

   return SUCCESS;

}


########################################################################
#
# StartSessionServer -
#       Starts the session by calling the traffictool module.
#       Creates Server and then client instances depending on the value
#       of either noofinbound or noofoutbound
#
# Input:
#       None
#
# Results:
#       SUCCESS - in case session is started successfully
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
########################################################################

sub StartSessionServer
{

   my ($self) = shift;
   my $trafficToolObj;

   my $os = $self->{toolname};

   if ($os =~ /spirent/i) {
      $self->{'server'}->{'instance0'} = "spirent_does_not_need_server";
      return SUCCESS;
   }

   my $verificationCalled = 0;
   # A session will have either noofinbound defined or noofoutbound defined
   # both cannot be defined simultaneously.
   # if noofoutbound=2 that means start one server and then two clients in
   # parellel, which will connect to that server.
   # $instance is the id attached to these objects.
   # Server will always have id 0 attached to it and client will have 1, 2...
   # depending on the number of clients in the session.
   my $instance = 0;
      $trafficToolObj = VDNetLib::Workloads::TrafficWorkload::TrafficTool->new(
                                                                    $self,
                                                                    $instance);
   if ($trafficToolObj eq FAILURE) {
      $vdLogger->Error("TrafficTool new method returned failure");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# StartSessionClient -
#       Starts the session by calling the traffictool module.
#       Creates Server and then client instances depending on the value
#       of either noofinbound or noofoutbound
#
# Input:
#       None
#
# Results:
#       SUCCESS - in case session is started successfully
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
########################################################################

sub StartSessionClient
{

   my ($self) = shift;
   my $noofSessions = $self->{noofinbound} || $self->{noofoutbound};
   my $trafficToolObj;

   my $verificationCalled = 0;
   # A session will have either noofinbound defined or noofoutbound defined
   # both cannot be defined simultaneously.
   # if noofoutbound=2 that means start one server and then two clients in
   # parellel, which will connect to that server.
   # $instance is the id attached to these objects.
   # Server will always have id 0 attached to it and client will have 1, 2...
   # depending on the number of clients in the session.
   my $instance = 1;

   #
   # For Spirent Tool traffic, Spirent Module takes care of initiating
   # the required number of parallel outbound streams.
   #
   if ($self->{client}{os} =~ /spirent/i) {
      $noofSessions = 1;
   }

   while($noofSessions--) {
      $trafficToolObj = VDNetLib::Workloads::TrafficWorkload::TrafficTool->new(
                                                                    $self,
                                                                    $instance);
      if ($trafficToolObj eq FAILURE) {
         $vdLogger->Error("TrafficTool new method returned failure");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $instance++;
   }
   return SUCCESS;
}

#########################################################################
#
# SessionPostMortem -
#       Does a post mortem on the session
#
# Input:
#       string - type of postmortem (mandatory)
#
# Results:
#       PASS/FAIL - post mortem result
#       FAILURE - in case of error while doing post mortem
#
# Side effects:
#       None
#
########################################################################

sub SessionPostMortem
{
   my $self = shift;
   my $postmortemType = shift;

   if (not defined $postmortemType){
      $vdLogger->Error("PostMortem type not defined");
      return FAILURE;
   }

   my $postMortemHash = {
      'binarytest' => {
         'method' => "TestBinary",
      },
      'logsAndState' => {
         'method' => "CollectLogsAndState",
      },
   };


   foreach my $pmType (keys %$postMortemHash) {
      if ($postmortemType =~ /$pmType/i)   {
         my $pmResult;
         my $method = $postMortemHash->{$pmType}->{'method'};
         my $server = $self->{'server'}->{"instance".0};
         if (defined $server) {
            $pmResult = $server->$method($self);
            if ($pmResult =~ /FAIL/i) {
               $vdLogger->Debug("Server $pmType test failed");
               return "FAIL";
            }
         } else {
            $vdLogger->Debug("traffic server not defined for $pmType");
         }
         # A session can have multiple clients but they are on
         # same machine and use the same client binary so we can
         # just test one instance.
         my $client = $pmResult = $self->{'client'}->{"instance".1};
         if (defined $client) {
            $pmResult = $client->$method($self);
            if ($pmResult =~ /FAIL/i) {
               $vdLogger->Debug("Client $pmType test failed");
               return "FAIL";
            }
         } else {
            $vdLogger->Debug("traffic client not defined for $pmType");
         }
      } else {
         next;
      }
   }

   return SUCCESS;
}


########################################################################
#
# DESTROY -
#       Destructor method which stops the session by killing the server
#       of the session.
#
# Input:
#       None
#
# Results:
#       None
#
# Side effects:
#       None
#
########################################################################

sub DESTROY
{
   my $self = shift;
   # This will help in case the session terminates abruptly. The destructor
   # is called no matter what. Thus it will dump the details in the log fie.
   foreach my $key (keys %$self){
      if ((defined $self->{$key}) && ($self->{$key} eq "")) {
         delete( $self->{$key});
      }
   }
   # Stopping the server of this session will stop the session.
   if (defined $self->{'server'}->{'instance0'}) {
      $vdLogger->Debug("Freeing resources occupied by this session object");
         $self->{'server'}->{'instance0'}->Stop($self);
   }

}


1;
