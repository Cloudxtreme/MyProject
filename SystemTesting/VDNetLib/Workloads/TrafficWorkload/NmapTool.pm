########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::NmapTool;

#
# This module deals with configuration of Nmap Utility
# Running the tool, getting result and stopping it is done by parent
# class of the tool. Child just inherits these methods.
# E.g. building command and testoptions is done by parent.
# This module just populates the namp specific parameters and thus
# contains methods specific to nmap. Other functionalites include:
# - Specific constants related to nmap.
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

use constant NMAP_COMMAND => "nmap";


########################################################################
#
# new --
#       Instantiates nmap object. Remember that TrafficTool enforces
#       client server model but nmap is standalone thus it has methods
#       like StartServer but they just return SUCCESS as there is no
#       server in case of nmap.
#
# Input:
#       none
#
# Results:
#       returns object of NmapTool class.
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
#       In future if nmap does not support any traffic just make an entry
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
#       Returns the nmap binary/command on linux
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
      return NMAP_COMMAND;
   } else {
      $vdLogger->Error("nmap binary not support $os");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetToolOptions -
#       This translates the traffic keyworkds into the language which
#       nmap understands.
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
            $srcBindStr = " $sessionValue->{'testip'}";
            return $srcBindStr;
         } else {
            $vdLogger->Error("nmap binary is only supported by Linux");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         last;
      }
      case m/(testduration)/i {
          if ($self->{mode} =~ m/client/i) {
             return " --host-timeout $sessionValue ";
          }
          last;
      }
      case m/(l4protocol)/i {
         if ($sessionValue =~ m/udp/i) {
            $sessionID->{l4protocol} = "udp";
            return " -sU ";
         } else {
            $sessionID->{l4protocol} = "tcp";
            return " -sT ";
         }
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
#       nmap does not have any server it just returns SUCCESS.
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
#       nmap does not have any server there is nothing to be stopped. Clients
#       are always started with timer or limited amount of data to be sent after
#       which the client ends on its own. Here also we will start nmap with
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
#       Parses stdout of nmap session and warns if no output.
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

   #
   # Common stdout of nmap is something like this
   # Host is up (0.00043s latency).
   # Not shown: 4929 closed ports
   # PORT     STATE SERVICE
   # 22/tcp   open  ssh
   # 80/tcp   open  http
   # 427/tcp  open  svrloc
   # 443/tcp  open  https
   #

   if (not defined $self->{stdout}) {
      $vdLogger->Error("stdout for $clientInstance nmap not defined.");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ($self->{stdout} eq "") {
      $vdLogger->Error("no stdout of $clientInstance nmap.");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ($self->{stdout} =~ m/\d+\/[tcp|udp]/is) {
      $vdLogger->Debug("Nmap on $clientInstance is working: $self->{stdout}");
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
#       sync as nmap should be executed in sync mode.
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
#	   none.
#
# Results:
#	   none.
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
#       nmap module. Nmap module does not have a server.
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

