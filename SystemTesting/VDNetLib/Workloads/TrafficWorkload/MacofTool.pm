########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::MacofTool;

#
# This module gives client/server objects for macof application
# It mostly deals with configuration of macof tool.
# Running the tool, getting result and stopping it is done by parent
# class of the tool. Child just inherits these methods.
# E.g. building command and testoptions is done by parent.
# This module just populates the macof specific parameters and thus
# contains methods specific to macof. Other functionalites include:
# - Specifies constants related to Iperf.
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
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

use constant MACOF_COMMAND => "macof";


########################################################################
#
# new --
#       Instantiates macof object. Remember that TrafficTool enforces
#       client server model but macof is standalone thus it has methods
#       like StartServer but they just return SUCCESS as there is no
#       server in case of macof.
#
# Input:
#       none
#
# Results:
#       returns object of MacofTool class.
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
#       In future if macof does not support any traffic just make an entry
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
   return SUCCESS;

}

########################################################################
#
# GetToolBinary -
#       Returns the macof binary/command on linux
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
      return MACOF_COMMAND;
   } else {
      $vdLogger->Error("macof binary not support $os");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetToolOptions -
#       This translates the traffic keyworkds into the language which
#       macof understands.
#
# Input:
#       Session Key (required)   - E.g. testduration
#       Session Value (required) - E.g. 5000
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
            $srcBindStr = "-i $sessionID->{client}->{interface}".
                          " -s $sessionID->{client}->{testip}".
                          " -d $sessionValue->{'testip'}";
            return $srcBindStr;
         } else {
            $vdLogger->Error("macof binary is only supported by Linux");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         last;
      }
      case m/(testduration)/i {
          if ($self->{mode} =~ m/client/i) {
             return " -n $sessionValue ";
          }
          last;
      }
      else {
         return 0;
      }
   }
   return 0;
}


###############################################################################
#
# ToolSpecificJob -
#       A method which the child can override and do things which are
#       specific to that tool.
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
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
#       macof does not have any server it just returns SUCCESS.
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
#       macof does not have any server there is nothing to be stopped. Clients
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
#       Parses stdout of macof session and warns if no output.
#
# Input:
#       Session ID (required)    - A hash containing session keys and
#                                  session values
#
# Results:
#       SUCCESS if test succeeded
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
   my $srcip = $sessionID->{client}->{testip};
   my $dstip = $sessionID->{server}->{testip};

   if ($self->{mode} =~ /server/i) {
      $vdLogger->Error("Method is valid only for client mode");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $clientInstance = $self->{instance};
   $clientInstance = "Client-" . $clientInstance;

   # Common stdout of macof is something like this
   # be:42:f8:34:fc:af cd:16:75:37:aa:95 192.168.24.53.55644 >
   # 192.168.56.212.39240: S 1226859463:1226859463(0) win 512
   # a2:58:8:10:bd:12 d0:2f:ea:7e:8e:b1 192.168.24.53.1671 >
   # 192.168.56.212.59598: S 1841071672:1841071672(0) win 512

   if (not defined $self->{stdout}) {
      $vdLogger->Error("stdout for $clientInstance macof not defined.");
      return FAILURE;
   } elsif ($self->{stdout} eq "") {
      $vdLogger->Error("no stdout of $clientInstance macof.");
      return FAILURE;
   } elsif ($self->{stdout} =~ m/$srcip.*$dstip/i) {
      $vdLogger->Debug("Macof on $clientInstance is working: $self->{stdout}");
      return SUCCESS;
   }

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
#       sync as macof should be executed in sync mode.
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
#       Overrides the parent method as there is nothing to be done in
#       macof module. Macof module does not have a server.
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

