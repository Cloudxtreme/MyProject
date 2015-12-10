########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::FragrouteTool;
my $version = "1.0";

#
# This module deals with configuration of Fragroute Utility
# Running the tool, getting result and stopping it is done by parent
# class of the tool. Child just inherits these methods.
# E.g. building command and testoptions is done by parent.
#
# Fragroute options for TDS:
# FragmentSize            <Bytes per Fragment>   --Fragment in chunks of given size
#
# SegmentSize             <Bytes per Segment>    --Divide into segments of given size
#
# FragmentToBeDelayed     <first,last,random>    --Fragment to be delayed
#
# FragmentDelay           <time in ms>           --Time by which to delay the fragment
#
# DropFragment            <first,last,random>    --Fragment to be dropped
#
# DropProbability         <0-100>                --% of fragments dropped
#
# DuplicateFragment      <first,last,random>     --Fragments to be duplicated
#
# DuplicateProbability    <0-100>                --% of fragments duplicated
#
# IPTTL                   <1-255>                --set IP TTL for each packet
#
# OrderFragments          <random, reverse>      --Order of sending Fragments
#
# PrintPackets            <enable, disable>      --Print in TCP dump format
#
# TCPChaff                <cksum,null,paws,rexmit,seq,syn,<ttl 0-255>>
# Interleave TCP segments in the queue with duplicate TCP segments containing
# different payloads, either bearing invalid TCP checksums, null TCP control
# flags, older TCP timestamp options for PAWS elimination, faked retransmits
# scheduled for later delivery, out-of-window sequence numbers, requests to
# re-synchronize sequence numbers mid-stream, or short time-to-live values.
#
# IPChaff                 <dup,opt,<ttl 0-255>>
# Interleave IP packets in the queue with duplicate IP packets containing
# different payloads, either scheduled for later delivery, carrying invalid
# IP options, or bearing short time-to-live values.
#

# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Workloads::TrafficWorkload::TrafficTool);

##TODO: Verify if this block is required as parent class already has it
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Switch;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

#Name of shell script which creates config file and executes fragroute
use constant FRAG_COMMAND => "fragroute_wrapper";

#Default timeout in seconds, for fragroute if not specified in TDS
use constant DEFAULT_TIMEOUT => "30";

########################################################################
#
# new --
#       Instantiates fragroute object. Remember that TrafficTool enforces
#       client server model but fragroute is standalone thus it has methods
#       like StartServer but they just return SUCCESS as there is no
#       server in case of fragroute.
#
# Input:
#       none
#
# Results:
#       returns object of FragrouteTool class.
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
   };

   return (bless($self, $class));
}


########################################################################
#
# SupportedKeys -
#       Maintains a table (in form of switch case) of what type of
#       traffic values it supports.
#       It can be expanded to contain more rules.
#
# Input:
#       None required
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
########################################################################

sub SupportedKeys
{

   return SUCCESS;

}


########################################################################
#
# GetToolBinary -
#       Returns the fragroute binary/command depending on win or linux or esx
#       fragroute is supported on win, linux, solaris (32 and 64 bit)
#       Note: Currently only tested for 32 bit linux
#
# Input:
#       os (required)
#
# Results:
#       tool binary string - in case of success
#       FAILURE in case of failure
#
# Side effects:
#       None
#
########################################################################

sub GetToolBinary
{
   my $self  = shift;
   my $os = shift;

   if ($os =~ m/linux/i) {
      return FRAG_COMMAND;
   } else {
      $vdLogger->Error("Fragroute not supported on os=$os");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetToolOptions -
#       This translates the traffic keywords into the language which
#       fragroute understands.
#
# Input:
#       Session Key (required)   - E.g. fragmentsize
#       Session Value (required) - E.g. 24
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
   my $self  = shift;
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

   #String to construct and return options in correct form
   my $configOption;

   switch ($sessionKey) {
      case m/server/i{

         #set destination IP
         if ($sessionID->{client}->{os} =~ m/linux/i) {
            $configOption = "destip:" . $sessionID->{server}->{testip};
         }

         return $configOption;
      }

      #set test duration
      case m/testduration/i{
         my $configOption = "timeout:";

         if ($sessionID->{testduration} ne "") {
            $configOption = $configOption . $sessionID->{testduration};
         }
         else{
            #use default timeout
            $configOption = $configOption . DEFAULT_TIMEOUT
         }
         return $configOption;
      }

      #set fragment size in bytes
      case m/fragmentsize/i{
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $configOption = "ip_frag:" . $sessionValue;
         }
         return $configOption;
      }

      #set to delay(in milliseconds) the delivery of
      #first, last, or random fragment
      case m/fragmenttobedelayed/i{
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $configOption = "delay:" . $sessionValue;
            if(defined $sessionID->{'FragmentDelay'}){
               $configOption = $configOption . ":" . $sessionID->{'FragmentDelay'};
            }
            else{
               #default delay of 10ms
               $configOption = $configOption . ":10";
            }
         }
         return $configOption;
      }

      #set to drop first, last or random fragment
      case m/dropfragment/i{
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $configOption = "drop:" . $sessionValue;
            if(defined $sessionID->{'DropProbability'}){
               $configOption = $configOption . ":" . $sessionID->{'DropProbability'};
            }
            else{
               #default drop probability of 10%
               $configOption = $configOption . ":10";
            }
         }
         return $configOption;
      }

      #set to duplicate the first, last or random fragment
      case m/duplicatefragment/i{
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $configOption = "dup:" . $sessionValue;
            if(defined $sessionID->{'DuplicateProbability'}){
               $configOption = $configOption . ":" . $sessionID->{'DuplicateProbability'};
            }
            else{
               #default duplicate probability of 10%
               $configOption = $configOption . ":10";
            }
         }
         return $configOption;
      }

      #set the ttl field
      case m/ipttl/i{
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $configOption = "ip_ttl:" . $sessionValue;
         }
         return $configOption;
      }

      #order fragments in reverse or random order
      case m/orderfragments/i{
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $configOption = "order:" . $sessionValue;
         }
         return $configOption;
      }

      #Interleave TCP segments
      case m/tcpchaff/i{
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $configOption = "tcp_chaff:" . $sessionValue;
         }
         return $configOption;
      }

      #Interleave IP fragments
      case m/ipchaff/i{
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $configOption = "ip_chaff:" . $sessionValue;
         }
         return $configOption;
      }

      #Segment TCP data in given size
      case m/segmentsize/i{
         if ($sessionID->{client}->{os} =~ m/linux/i){
            $configOption = "tcp_seg:" . $sessionValue;
         }
         return $configOption;
      }

      #Return 0 if option not supported
      else{
         $vdLogger->Error("Option $sessionKey not supported");
         return 0;
      }
   }
   return 0;
}


#########################################################################
#
# BuildToolCommand -
#       This method sets the fragroute command based on the OS
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
#       A method which the child can override and do things which are specific
#       to that tool.
#
# Input:
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
#       fragroute does not have any server it just returns SUCCESS.
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
#       This method is required as parent enforces a client server model.
#       Need to add functionality to stop fragroute execution.
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
#       This is used to check if fragroute has started running.
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       SUCCESS if "fragroute: " is detected on stdout
#       FAILURE else
#
# Side effects;
#       none
#
########################################################################

sub GetThroughput
{
   my $self = shift;
   my $sessionID = shift;

   if ($self->{mode} =~ /server/i) {
      $vdLogger->Error("Method is valid only for client mode");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $clientInstance = $self->{instance};
   $clientInstance = "Client-" . $clientInstance;

   #
   # Common stdout of fragroute is something like this
   #
   #

   if (not defined $self->{stdout}) {
      $vdLogger->Error("stdout for $clientInstance not defined.");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ($self->{stdout} eq "") {
      $vdLogger->Error("no stdout of $clientInstance.");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ($self->{stdout} =~ m/fragroute: /is) {
      $vdLogger->Debug("Fragroute on $clientInstance is working: $self->{stdout}");
      return SUCCESS;
   }

   VDSetLastError("EFAIL");
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
#       async as fragroute does not create traffic of its own.
#
# Side effects;
#       none
#
########################################################################

sub GetLaunchType
{
   return "async";
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
#	none.
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
#       Overrides the parent method. Returns success as fragroute
#       module does not have a server.
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
