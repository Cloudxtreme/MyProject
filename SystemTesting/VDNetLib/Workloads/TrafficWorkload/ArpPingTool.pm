########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::ArpPingTool;
my $version = "1.0";


#
# This module deals with configuration of Arp Ping Utility
# Running the tool, getting result and stopping it is done by parent
# class of the tool. Child just inherits these methods.
# E.g. building command and testoptions is done by parent.
# This module just populates the ping specific parameters and thus
# contains methods specific to ping. Other functionalites include:
# - Specific constants related to Ping.
# - Maintains the knowdlege of the traffic it supports
#


# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Workloads::TrafficWorkload::TrafficTool);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Switch;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

use constant PING_COMMAND => "arping";
use constant NUM_PACKET_SECOND => 1;

########################################################################
#
# new --
#       Instantiates arp ping object. Remember that TrafficTool enforces
#       client server model but arp ping is standalone thus it has methods
#       like StartServer but they just return SUCCESS as there is no
#       server in case of ping.
#
# Input:
#       none
#
# Results:
#       returns object of ArpPingTool class.
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my $class    = shift;
   my $self  = {
      'mode' => undef,
      'pktCountFlag' => 0,
   };
   return (bless($self, $class));
}


########################################################################
#
# SupportedKeys -
#       Maintains a table (in form of switch case) of what type of
#       traffic values it supports.
#       In future if Arp Ping does not support any traffic just make an
#       entry in this table
#       It can be expanded to contain more rules.
#
# Input:
#       Traffic Key (required) - A hash key in Session hash
#       Traffic Value (required) - Value of that key in Session hash
#
# Results:
#       SUCCESS in case of Supported traffic
#       0 in case of unsupported traffic.
#       FAILURE in case of any error.#
#
# Side effects:
#       None
#
########################################################################

sub SupportedKeys
{
   my ($self, $sessionKey, $sessionValue)  = @_;
   if ((not defined $sessionKey) || (not defined $sessionValue)) {
      $vdLogger->Warn("SupportedKeys called with ".
                      "$sessionKey=$sessionValue");
      return FAILURE;
   }
   # Return 0 for all the traffic keys this tool does not support
   if (($sessionKey =~ m/routingscheme/i) &&
                    ($sessionValue =~ m/(flood|multicast)/i)) {
      $vdLogger->Trace("Traffic with $sessionKey=$sessionValue  is not".
                       " supported by ArpPing Module." );
      return 0;
   }
   return SUCCESS;
}


########################################################################
#
# GetToolBinary -
#       Returns the arp ping binary/command depending on linux
#
# Input:
#       os (required)
#
# Results:
#       tool binary string - in case of success
#       FAILURE in case of failure
#
# Side effects:
#       None.
#
########################################################################

sub GetToolBinary
{
   my $self  = shift;
   my $os = shift;

   if ($os =~ m/(linux)/i) {
      return "arping -b";
   } else {
      $vdLogger->Error("Unknow os=$os ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetToolOptions -
#       This translates the traffic keyworkds into the language which
#       ping understands. E.g. When a session says run ping for duration
#       of 5 sec. Then this method converts it into number of packets
#       to send for that duration. Currently we send 1 packet per sec.
#
# Input:
#       Session Key (required)   - E.g. localsendsocketsize
#       Session Value (required) - E.g. 4198
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       string in case of success
#       0 in case there is no translation for that key
#       FAILURE in case of failure
#
# Side effects:
#       None
#
########################################################################

sub GetToolOptions
{

   my $self    = shift;
   my %args  = @_;
   my $sessionKey = $args{'sessionkey'};
   my $sessionID  = $args{'sessionID'};
   my $sessionValue = $args{'sessionvalue'} || undef;
   if (not defined $sessionKey || not defined $sessionID ) {
      $vdLogger->Error("one or more parameters missing in ".
                       "GetToolOptions.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $sessionValue) {
      $sessionValue = $sessionID->{$sessionKey};
   }

   if ($sessionValue eq "") {
      return 0;
   }

   switch ($sessionKey) {
      case m/(server)/i {
         my $srcBindStr = "";
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $srcBindStr =  " -s $sessionID->{client}->{testip}";
         }
         # for ip interface like eth0:1, it is not supported by arping command
         # we need to slice the sub ip index, for example, change eth0:1 to eth0
         my $interface = $sessionID->{client}->{'interface'};
         if ($interface =~ m/(.*):\d+/) {
            $interface = $1;
         }
         if ($self->{mode} =~ m/client/i &&
             $sessionID->{routingscheme} !~ m/broadcast/i ) {
            # Changed the format of the parameters passed to ping to the following
            # as the previous format doesnt work with Mac. But this is compatible
            # with Mac and Linux.

            # Add "-I" option (-I device : which ethernet device to use),to make
            # arping can run vm without eth0 (fix PR 1161522)
               if ($sessionID->{arpprobe} =~ m/dad/i ) {
                  if(($sessionID->{client}->{os} =~ m/linux/i)){
                     return " -D $sessionID->{client}->{'testip'} -I $interface";
                  }
               } else {
                  return $srcBindStr . "  $sessionValue->{'testip'} " .
                   "-I $interface";
               }
         } else {
          # As we carry only broadcast address in traffic hash
          # we dont know the address of local interface thus cannot
          # do source binding here.

          # Add "-I" option (-I device : which ethernet device to use),to make
          # arping can run vm without eth0 (fix PR 1161522)
          return " $sessionValue->{'testip'} -I $interface";
         }
         last;
      }
      case m/(testduration)/i {
          if ($self->{mode} =~ m/client/i && $self->{pktCountFlag} == 0) {
             # We try to send 1 packet per sec
             my $numPackets = $sessionValue * NUM_PACKET_SECOND;
             if(($sessionID->{client}->{os} =~ m/linux/i)){
              return "-c $numPackets";
             }
          }
          last;
      }
      else {
         return 0;
      }
   }

   return 0;
}


#########################################################################
#
# BuildToolCommand -
#       This method arp ping command based on the OS
#
# Input:
#       os (required)
#
# Results:
#       SUCCESS - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
########################################################################

sub BuildToolCommand
{
   my $self    = shift;
   if ($self->{mode} =~ m/server/i) {
      return SUCCESS;
   }

   my %args  = @_;
   my $os = $args{'os'};

   if (not defined $os) {
      $vdLogger->Error("Cannot proceed without OS parameter ".
                       "in BuildToolCommand.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{command}  = $self->GetToolBinary($os);
   return SUCCESS;
}


###############################################################################
#
# ToolSpecificJob -
#       A method which the child can override and do things which are
#       specific to that tool.
#
# Input:
#       None
#
# Results:
#       SUCCESS - to comply with interface
#
# Side effects:
#       None
#
###############################################################################

sub ToolSpecificJob
{
   return SUCCESS;
}


########################################################################
#
# StartServer -
#       This method is required as parent enforces a client server model and as
#       ping does not have any server it just returns SUCCESS.
#
# Input:
#       None
#
# Results:
#       SUCCESS - to comply with interface
#
# Side effects:
#       None
#
########################################################################

sub StartServer
{
   return SUCCESS;
}


########################################################################
#
# Stop-
#       This method is required as parent enforces a client server model and as
#       ping does not have any server there is nothing to be stopped. Clients
#       are always started with timer or limited amount of data to be sent after
#       which the client ends on its own. Here also we will start ping with
#       limited number of packets or time duration.
#
# Input:
#       None
#
# Results:
#       SUCCESS - to comply with interface
#
# Side effects:
#       None
#
########################################################################

sub Stop
{
   return SUCCESS;
}


########################################################################
#
# GetThroughput --
#       Parses stdout of arping and make sure at least one reply received
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       SUCCESS if receive at least one arping reply
#       FAILURE in case of error.
#
# Side effects;
#       none
#
########################################################################

sub GetThroughput
{
   my $self = shift;
   my $sessionID = shift;
   my $trafficToolStdOut = "";

   if ($self->{mode} =~ /server/i) {
      $vdLogger->Error("Method is valid only for client mode");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $clientInstance = $self->{instance};
   $clientInstance = "Client-" . $clientInstance;
   if(not defined $self->{stdout}){
      # stderr is set when process is launched in sync mode.
      # In case of async error is in temp file which is then
      # read
      if(defined $self->{stderr}){
         $vdLogger->Warn($clientInstance ."'s stdout not defined.".
                         " stderr is: $self->{stderr}");
      }
   } elsif($self->{stdout} =~ m/bad/i || $self->{stdout} eq "" ||
           $self->{stdout} =~ m/not a valid/i) {
      $vdLogger->Trace("Something went wrong with stdout of $clientInstance".
                       ":$self->{stdout}");
      if(defined $self->{stderr}){
         $vdLogger->Error("$self->{stderr}");
      }
   } else {
      # To remove extra blank lines in stdout as it looks ineligible.
      $self->{stdout}  =~ s/\r\r\n/\n/g;
      my @stats = split(/statistics/,$self->{stdout});
      # As ping is now executed before every run dialing down the
      # verbosity of its output for cleaner logs.
      if (defined $stats[1]) {
          $vdLogger->Debug("Stdout of $clientInstance from ".
                           "$sessionID->{client}->{controlip} to ".
                           "$sessionID->{server}->{controlip}\n$stats[1]");
      } else {
          $vdLogger->Debug("Stdout of $clientInstance from ".
                           "$sessionID->{client}->{controlip} to ".
                           "$sessionID->{server}->{controlip}\n".
                           "$self->{stdout}");
      }
      $trafficToolStdOut = $self->{stdout};
      if (not defined $trafficToolStdOut) {
         $vdLogger->Error("Traffic tool output is undefined");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
   # Common stdout of linux is something like this
   # Unicast reply from 192.168.20.115 [00:50:56:94:AF:47]  0.748ms
   # Unicast reply from 192.168.20.115 [00:50:56:94:AF:47]  237.951ms
   # Unicast reply from 192.168.20.115 [00:50:56:94:AF:47]  0.813ms
   # Unicast reply from 192.168.20.115 [00:50:56:94:AF:47]  238.684ms
   # Unicast reply from 192.168.20.115 [00:50:56:94:AF:47]  0.928ms
   # Unicast reply from 192.168.20.115 [00:50:56:94:AF:47]  239.360ms

   my @lines = split(/\n/,$trafficToolStdOut);
   my ($sent, $loss, $percentage, $line);
   foreach $line (@lines){
      if ($line =~ m/Unicast reply/i){
         # we do not care packet loss for arping, we also count it "pass"
         # if only one reply received
         #return "PASS";
         return "SUCCESS";
      }
   }

   $vdLogger->Error("not get any arping reply from peer site");
   VDSetLastError("EINVALID");
   return FAILURE;
}


########################################################################
#
# GetLaunchType --
#       Overrides the parent method and returns launch type of process.
#
# Input:
#       none
#
# Results:
#       sync as ping should be executed in sync mode.
#
# Side effects;
#       none
#
########################################################################

sub GetLaunchType
{
   return "sync";
}


########################################################################
#
# PrintTrafficStdout --
#       Overrding parent's method.
#
# Input:
#	none.
#
# Results:
#       SUCCESS
#
# Side effects;
#       none
#
########################################################################

sub PrintTrafficStdout
{
   return SUCCESS;
}

########################################################################
#
# IsToolServerRunning --
#       Overrides the parent method as there is nothing to be done in
#       Ping module. Ping module does not have a server.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects;
#       none
#
########################################################################

sub IsToolServerRunning
{
   return SUCCESS;
}
1;
