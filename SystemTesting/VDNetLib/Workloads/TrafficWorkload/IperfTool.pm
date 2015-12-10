########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::IperfTool;

#
# This module gives client/server objects for Iperf application
# It mostly deals with configuration of Iperf tool.
# Running the tool, getting result and stopping it is done by parent
# class of the tool. Child just inherits these methods.
# E.g. building command and testoptions is done by parent.
# This module just populates the Iperf specific parameters and thus
# contains methods specific to Iperf. Other functionalites include:
# - Specifies constants related to Iperf.
# - Maintains the knowdlege of the traffic it supports
#


# Inherit the parent class.
require Exporter;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::Workloads::TrafficWorkload::TrafficTool);


##TODO: Verify if this block if required as parent class already has it
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Switch;
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);


# Same binary works in both client and server mode.
use constant BINARY_IPERF => "iperf";


########################################################################
#
# new --
#       Instantiates Iperf client or server object
#
# Input:
#       none
#
# Results:
#       returns object of IperfTool class(in either client or server
#       mode)
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my $class    = shift;

   # mode is to identify if the object is client or server
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
#       In future if Iperf does not support any traffic just make an entry
#       in this table
#       It can be expanded to contain more rules.
#
# Input:
#       Traffic Key (required) - A hash key in Session hash
#       Traffic Value (required) - Value of that key in Session hash
#
# Results:
#       SUCCESS in case of Supported traffic
#       0 in case of unsupported traffic.
#       FAILURE in case of any error.
#
# Side effects:
#       None
#
########################################################################

sub SupportedKeys
{

   my ($self, $sessionKey, $sessionValue)  = @_;
   if (not defined $sessionKey || not defined $sessionValue) {
      $vdLogger->Warn("SupportedKeys called with ".
                      "$sessionKey=$sessionValue");
   }
   # Return 0 for all the traffic keys this tool does not support
   if (($sessionKey =~ m/ReceiveMessageSize/i ||
        $sessionKey =~ m/RequestSize/i ||
        $sessionKey =~ m/ResponseSize/i ||
        $sessionKey =~ m/pktfragmentation/i ||
        $sessionKey =~ m/pingpktsize/i ||
        $sessionKey =~ m/AlterBufferAlignment/i) && ($sessionValue ne ""))  {
      $vdLogger->Trace("Traffic with $sessionKey=$sessionValue ".
                       "is not supported by Iperf module");
      return 0;
   } elsif($sessionKey =~ m/bursttype/i &&
           $sessionValue =~ m/rr/i) {
      $vdLogger->Warn("Traffic with burstType=rr is not supported by Iperf ".
                      "module. Please use Netperf. Ignoring burstType=rr");
      return SUCCESS;
   } elsif($sessionKey =~ m/routingscheme/i &&
           $sessionValue =~ m/(flood|broadcast)/i) {
      $vdLogger->Trace("Traffic with $sessionKey=$sessionValue  is not".
                       " supported by Iperf ".
                      "module. Please use Netperf. Ignoring burstType=rr");
      return 0;
   } else {
      return SUCCESS;
   }
   return FAILURE;
}


########################################################################
#
# GetToolBinary -
#       Returns the Iperf binary depending on win or linux and
#       client or server mode
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

   if ($os =~ m/linux|mac|darwin/i) {
         return BINARY_IPERF;
   } elsif ($os =~ m/win/i) {
         return BINARY_IPERF . ".exe";
   } elsif ($os =~ m/(esx|vmkernel)/i) {
         return BINARY_IPERF . "-uw";
   } else {
      $vdLogger->Error("Iperf binary requested for unknow os=$os ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Trace("Iperf client uses source binding using -B. Server killed".
                    " from previous session take time to clean up. Thus sleep");
   sleep(5);
}


########################################################################
#
# GetToolOptions -
#       This translates the traffic keyworkds into the language which
#       Iperf understands. E.g. When a session says run multicast of
#       this method converts it -B MULTICASTIP. Simiarly,
#       for a udp traffic its -u
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


   #TODO: Yet to implement. Not sure if they are required as per
   # current requirements.
   # -N set TCP no delay
   switch ($sessionKey) {
      case m/(l3protocol|addressfamily)/i {
         if ($sessionValue =~ m/ipv6/i ||  $sessionValue =~ m/af_inet6/i) {
            # Iperf take -V to Set the domain to IPv6
            return " -V ";
         }
      }
      case m/(l4protocol)/i {
         # This applied for both client and server
         # tcp is default, nothing to do.
         if ($sessionValue =~ m/udp/i ||
             $sessionID->{routingscheme} =~ m/multicast/i ||
             $sessionID->{multicasttimetolive} ne "" ||
             $sessionID->{udpbandwidth} ne "" ) {
            $sessionID->{l4protocol} = "udp";
            return " --- -u ";
         }
      }
      case m/(server)/i {
         if ($self->{mode} =~ m/client/i) {
            # Some windows flavors does not allow multiple binding on
            # same local interface thus when we try to run multiple parallel
            # sessions of iperf client on windows with source binding enabled
            # it fails for no of clients > 2. Thus not doing -B on win.
            if($sessionID->{client}->{os} =~ m/(esx|vmkernel|linux|mac|darwin)/i){
               # Code block for non windows
               if($sessionID->{routingscheme} =~ m/multicast/i ||
                  $sessionID->{multicasttimetolive} ne "" ) {
                  return " -c $sessionValue->{'multicastip'} -B ".
                    "$sessionID->{client}->{testip}";
               } else {
                  return " -c $sessionValue->{'testip'} -B ".
                         "$sessionID->{client}->{testip}";
               }
            } else {
               # Code block for windows
               if($sessionID->{routingscheme} =~ m/multicast/i ||
                  $sessionID->{multicasttimetolive} ne "" ) {
                  return " -c $sessionValue->{'multicastip'}";
               } else {
                  return " -c $sessionValue->{'testip'}";
               }
            }
         } elsif($self->{mode} =~ m/server/i){
            if($sessionID->{routingscheme} =~ m/multicast/i ||
            $sessionID->{multicasttimetolive} ne "" ){
               return "-s -B $sessionValue->{'multicastip'}";
            } elsif((defined $sessionID->{bindingenable})
                     and ($sessionID->{bindingenable} == 0 )) {
               return "-s ";
            } else {
               return "-s -B $sessionValue->{'testip'}";
            }
         }
         last;
      }
      case m/(testduration)/i {
          if ($self->{mode} =~ m/client/i) {
             return " -t $sessionValue ";
          }
          last;
      }
      case m/(sessionport)/i {
          if ($self->{mode} =~ m/client/i && $sessionID->{natedport} ne "") {
             return " -p $sessionID->{natedport}";
          }
          # This applied for both client and server
          return " -p $sessionValue";
      }
      case m/(sendmessagesize)/i {
         # number of bytes to transmit(Reference:iperf help)
         if ($self->{mode} =~ m/client/i) {
            return " -n $sessionValue";
         }
      }
      case m/(localsendsocketsize|localreceivesocketsize)/i {
         # Length of buffer to read or write(Reference:iperf help)
         if ($self->{mode} =~ m/client/i) {
            return " -l $sessionValue";
         }
      }
      case m/(tcpwindowsize)/i {
         #  TCP window size (socket buffer size)
         if ($self->{mode} =~ m/client/i) {
            return " -w $sessionValue";
         }
      }
      case m/(tcpmss)/i {
         #  set TCP maximum segment size (MTU - 40 bytes)
         if ($self->{mode} =~ m/client/i) {
            return " -M $sessionValue";
         }
      }
      case m/(disablenagle)/i {
         #  set TCP no delay, disabling Nagle's Algorithm
         if ($sessionValue =~ m/(all|yes|both)/i &&
             $self->{mode} =~ m/client/i) {
            return " -N ";
         }
      }
      case m/(iperfthreads)/i {
         #  number of parallel client threads to run
         if ($self->{mode} =~ m/client/i) {
            return " -P $sessionValue";
         }
      }
      case m/(dataintegritycheck)/i {
         if ($sessionValue =~ m/enable/i &&
             $self->{mode} =~ m/client/i) {
            return " -X ";
         }
      }
      case m/(multicasttimetolive)/i {
         if ($self->{mode} =~ m/client/i) {
            if($sessionValue ne ""){
               $sessionID->{routingscheme} = "multicast";
               return " -T $sessionValue";
            }
         }
      }
      case m/(udpbandwidth)/i {
         if ($self->{mode} =~ m/client/i) {
            # In client mode of iperf it has support for setting the
            # bandwidth in case of UDP traffic. This feature is
            # very useful in case of multicast testing.
            if($sessionValue ne ""){
               return " --- -b $sessionValue";
            }
         }
      }
      case m/(tos)/i {
        if ($self->{mode} =~ m/client/i) {
            if ($sessionValue ne "") {
                return " --tos $sessionValue";
            }
        }
      }
      else {
         return 0;
      }
   }
   return 0;
}


########################################################################
# AppendTestOptions --
#       Attaches the options string to existing options and builds up
#       test options for Iperf.
#
# Input:
#       option (required)    - A string containing values like -B IP
#
# Results:
#       SUCCESS in case everything goes well
#       FAILURE otherwise
#
# Side effects;
#       none
#
########################################################################

sub AppendTestOptions
{
   my $self = shift;
   my $option = shift;
   if (not defined $option || $option eq "") {
      $vdLogger->Error("option parameter missing in ".
                       "AppendTestOptions");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my @optionParams;
   if ($option =~ m/---/) {
      ## Check the flag
      # if the flag is set then dont append --- or else append it
      @optionParams = split('---',$option);
      $option = $optionParams[1];
      $self->{testOptions} =  $self->{testOptions} . " $option";
   } else {
      if (defined $option) {
         $self->{testOptions} =  "$option " . $self->{testOptions};
      }
   }
   return SUCCESS;
}

1;
