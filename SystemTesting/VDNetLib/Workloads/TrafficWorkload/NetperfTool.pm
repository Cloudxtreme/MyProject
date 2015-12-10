########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::NetperfTool;
my $version = "1.0";


#
# This module gives client/server objects for netperf application
# It mostly deals with configuration of netperf tool.
# Running the tool,getting result and stopping it are done by parent
# class of the tool. Child then inherits these methods.
# E.g. building command and testoptions is done by parent and
# then this package is asked to fill appropriate binary
# This module just populates the netperf specific parameters and thus
# contains methods specific to netperf. Other functionalites include:
# - Specifies constants related to netperf.
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


use constant BINARY_NETPERF_SERVER => "netserver";
use constant BINARY_NETPERF_CLIENT => "netperf";


########################################################################
#
# new --
#       Instantiates netperf client or server object
#
# Input:
#       none
#
# Results:
#       returns object of NetperfTool class(in either client or server
#       mode)
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my $class    = shift;

   # Netperf has two kinda options - global options and test options
   # It is very stringent about the way it accepts test options
   # Thus flags are used to generate testoptions string.
   my $self  = {
      'mode' => undef,
      'rrFlag' => 0,
      'localSocketFlag' => 0,
      'remoteSocketFlag' => 0,
      'localClientPortFlag' => 0,
      'extendedFlag' => 0,
   };
   return (bless($self, $class));
}



########################################################################
#
# SupportedKeys -
#       Maintains a table (in form of switch case) of what type of
#       traffic values it supports.
#       E.g. Netperf does not support multicast.
#       In future if netperf supports multicast just delete this table
#       entry and netperf with multicast can be used without any further
#       code change. Similarly if you want to restrict netperf from
#       running a type of traffic just put a static rule here.
#       It can be expanded to contain more rules.
#
# Input:
#       Traffic Key (required) - A hash key in Session hash
#       Traffic Value (required) - Value of that key in Session hash
#  E.g. RoutingScheme is a key whose value is multicast,unicast,etc
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

   switch ($sessionKey) {
      case m/(routingscheme)/i {
         if ($sessionValue =~ m/multicast/i) {
            $vdLogger->Trace("Traffic with $sessionKey=$sessionValue ".
                             "is not supported by Netperf module");
            return 0;
         }
         last;
      }
      case m/(multicasttimetolive|udpbandwidth|pktfragmentation)/i {
         if($sessionValue ne "") {
            $vdLogger->Trace("Traffic with $sessionKey=$sessionValue ".
                             "is not supported by Netperf module");
            return 0;
         }
      }
      case m/(pingpktsize|tcpmss|tcpwindowsize|iperfthreads)/i {
         if($sessionValue ne "") {
            $vdLogger->Warn("Traffic with $sessionKey=$sessionValue ".
                             "is not supported by Netperf module");
            return SUCCESS;
         }
      }
      #TODO: Remove this rule when support for IPv6 is integrated
      # into Netperf module.
      case m/(addressfamily)/i {
         if ($sessionValue =~ m/af_inet6/i) {
            $vdLogger->Trace("Traffic with $sessionKey=$sessionValue ".
                             "is not supported by Netperf module");
            return 0;
         }
         last;
      }
      else {
         return SUCCESS;
      }
   }
   return FAILURE;
}


########################################################################
#
# GetToolBinary -
#       Returns the netperf binary depending on win, esx or linux and
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
      if ($self->{'mode'} =~ m/server/i ) {
         return BINARY_NETPERF_SERVER;
      } else {
         return BINARY_NETPERF_CLIENT;
      }
   } elsif ($os =~ m/^win/i) {
      if ($self->{'mode'} =~ m/server/i ) {
         return BINARY_NETPERF_SERVER . ".exe";
      } else {
         return BINARY_NETPERF_CLIENT . ".exe";
      }
   } elsif ($os =~ m/(esx|vmkernel)/i) {
      if ($self->{'mode'} =~ m/server/i ) {
         return BINARY_NETPERF_SERVER . "-uw";
      } else {
         return BINARY_NETPERF_CLIENT . "-uw";
      }
   } else {
      $vdLogger->Error("Netperf binary requested for unknow os=$os ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

}


########################################################################
#
# GetToolOptions -
#       This translates the traffic keyworkds into the language which
#       netperf understands. E.g. When a session says run burstType of
#       TCP stream this method converts it into -t tcp_stream. Simiarly,
#       for a localsendsocketsize  it converts it into -- -s X,
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


   if ($self->{'mode'} =~ m/(server)/i ) {
      switch ($sessionKey) {
         case m/(l3protocol|addressfamily)/i {
           if ($sessionValue =~ m/ipv6/i ||  $sessionValue =~ m/af_inet6/i) {
              return " -6 ";
           }
         }
         case m/(sessionport)/i {
            return " -p $sessionValue ";
         }
         case m/(server)/i {
            # This is to bind to local test interface
            # -L name,family    Use name to pick listen address
            #                   and family for family
            return " -L $sessionValue->{'testip'} ";
         }
         else {
            return 0;
         }
      }
   } else {
      switch ($sessionKey) {
      case m/(l3protocol)/i {
         if ($sessionValue =~ m/ipv6/i) {
            # On windows IPv6 is usually sourced. i.e. IPv6 traffic
            # needs to be told which source interface to use for
            # sending traffic.
            if($sessionID->{client}->{os} =~ m/^win/i){
               return " -6 ";
            } else {
               return " -6 ";
            }
         }
      }
      case m/(sessionport|clientport)/i {
         # Skip the key processing if the flag is already set
         # i.e the port option -p for the tool is already initialized
         if ($self->{localClientPortFlag} == 1) {
            $vdLogger->Debug("Skip processing \"$sessionKey\" as \"localClientPortFlag\" was already" .
                      "set during previous execution of this code path for another parameter key.. " .
                      "Since we do not want to return -p options twice for the tool");
            last;
         } else {
            my $ret;
            # By setting this flag we skip the processing for other keys
            # when control comes here in the next pass
            $vdLogger->Debug("Flag \"localClientPortFlag\" is being set while processing the parameter" .
                      "key \"$sessionKey\", this flag is to make sure we do not return the -p option for" .
                      "the tool again while processing the next parameter key");
            $self->{localClientPortFlag} = 1;
            if ($sessionID->{natedport} ne "") {
               $ret = " -p $sessionID->{natedport} ";
            } elsif ($sessionID->{clientport} eq "") {
               # Use only the server remote port and the tool generated
               # random client localport
               $ret = " -p $sessionID->{sessionport} ";
               $vdLogger->Debug("No clientport was specified, Using only the server remote port, " . $ret);
            } else {
               # Append the user specified client localport to the server remoteport
               $ret = " -p $sessionID->{sessionport},".
                      "$sessionID->{clientport} ";
               $vdLogger->Debug("clientport and serverport was specified, " . $ret);
            }
            return $ret;
         }
      }
      case m/(dataintegritycheck)/i {
         if ($sessionValue =~ m/enable/i) {
            return " -x ";
         }
      }
      case m/(bursttype)/i {
         return " -t ".$sessionID->{'l4protocol'}."_$sessionValue -- ";
      }
      case m/(testduration)/i {
         return " -l $sessionValue ";
      }
      case m/(alterbufferalignment)/i {
         return " -a $sessionValue ";
      }
      case m/(server)/i {
        # -H name|ip,fam *  Specify the target machine
        #                   and/or local ip and family
        # -L name|ip,fam *  Specify the local ip|name
        #                   and address family
         return " -H $sessionValue->{'testip'} ".
                "-L $sessionID->{client}->{testip}";
      }
      case m/(sendmessagesize)/i {
         my $ret;
         $ret = "-- -m $sessionValue ";
         $ret =  " -t ".$sessionID->{'l4protocol'}."_stream " . $ret;
         return $ret;
      }
      case m/(receivemessagesize)/i {
         my $ret;
         $ret = "-- -M $sessionValue ";
         $ret =  " -t ".$sessionID->{'l4protocol'}."_stream " . $ret;
         return $ret;
      }
      case m/(disablenagle)/i {
         my $ret;
         if ($sessionValue =~ /local/i) {
            $ret = "-- -D L, ";
         } elsif ($sessionValue =~ /remote/i) {
            $ret = "-- -D ,R ";
         } elsif ($sessionValue =~ /(all|both|yes)/i) {
            $ret = "-- -D L,R ";
         }
         return $ret;
      }
      case m/(requestsize|responsesize)/i {
         if ($self->{rrFlag} == 1) {
            last;
         } else {
            my $ret;
            $self->{rrFlag} = 1;
            $ret = "-- -r $sessionID->{requestsize},".
                   "$sessionID->{responsesize} ";
            $ret =  " -t ".$sessionID->{'l4protocol'}."_rr " . $ret;
            return $ret;
         }
       }
       case m/(localsendsocketsize|localreceivesocketsize)/i {
          if ($self->{localSocketFlag} == 1) {
             last;
          } else {
             my $ret;
             $self->{localSocketFlag} = 1;
             if ($sessionID->{localreceivesocketsize} eq "") {
                $ret = "-- -s $sessionID->{localsendsocketsize}";
             } elsif ($sessionID->{localsendsocketsize} eq "") {
                $ret = "-- -s $sessionID->{localreceivesocketsize}";
             } else {
                $ret = "-- -s $sessionID->{localsendsocketsize},".
                              "$sessionID->{localreceivesocketsize} ";
             }
             if ($sessionID->{requestsize} ne "" ||
                 $sessionID->{responsesize} ne "") {
                $ret =  " -t ".$sessionID->{'l4protocol'}."_rr " . $ret;
             } else {
                $ret =  " -t ".$sessionID->{'l4protocol'}."_stream " . $ret;
             }
             return $ret;
          }
       }
       case m/(remotesendsocketsize|remotereceivesocketsize)/i {
          if ($self->{remoteSocketFlag} == 1) {
             last;
          } else {
             my $ret;
             $self->{remoteSocketFlag} = 1;
             if ($sessionID->{remotereceivesocketsize} eq "") {
                $ret = "-- -S $sessionID->{remotesendsocketsize}";
             } elsif ($sessionID->{remotesendsocketsize} eq "") {
                $ret = "-- -S $sessionID->{remotereceivesocketsize}";
             } else {
                $ret = "-- -S $sessionID->{remotesendsocketsize},".
                    "$sessionID->{remotereceivesocketsize} ";
             }
             if ($sessionID->{requestsize} ne "" ||
                 $sessionID->{responsesize} ne "") {
                $ret =  " -t ".$sessionID->{'l4protocol'}."_rr " . $ret;
             } else {
                $ret =  " -t ".$sessionID->{'l4protocol'}."_stream " . $ret;
             }
             return $ret;
          }
       }
       case m/(trafficType|AddressFamily)/i {
          # -4 is for IPv4 realted traffic.
          # default is -4 thus no need to specify
          if ($sessionValue =~ m/ipv6/i || $sessionValue =~ m/AF_INET6/i) {
             return " -6 ";
          }
          last;
       }
       else {
          return 0;
       }
      }
   }
   return 0;
}

########################################################################
# AppendTestOptions --
#       Attaches the options string to existing options and builds up
#       global options and test options for netperf.
#
# Input:
#       option (required)    - A string containing values like -m 56
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
   if ($option =~ m/--/) {
      ## Check the flag
      # if the flag is set then dont append -- or else append it
      if ($self->{extendedFlag} == 1) {
         # split from -- and only append the later part
         @optionParams = split('--',$option);
         $option = $optionParams[1];
      }
      $self->{testOptions} =  $self->{testOptions} . " $option";
      $self->{extendedFlag} = 1;

   }else{
      if (defined $option) {
         $self->{testOptions} =  "$option " . $self->{testOptions};
      }
   }
   return SUCCESS;
}

1;
