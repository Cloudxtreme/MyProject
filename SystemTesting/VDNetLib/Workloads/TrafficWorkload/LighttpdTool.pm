########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TrafficWorkload::LighttpdTool;
my $version = "1.0";

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


use constant BINARY_LIGHTTP_SERVER => "start-lighttpd.sh";
use constant BINARY_WEIGHTTP_CLIENT => "weighttp";


########################################################################
#
# new --
#       Instantiates weighttp client or lighttpd server object
#
# Input:
#       none
#
# Results:
#       returns object of the class(in either client or server
#       mode)
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

   if ($sessionKey =~ /(requestcount|threadcount|concurrentclients)/i) {
      return SUCCESS;
   }
   return FAILURE;
}

########################################################################
#
# GetToolBinary -
#       Returns the lighttpd/weighttp binary depending on win, esx or linux and
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
         return BINARY_LIGHTTP_SERVER;
      } else {
         return BINARY_WEIGHTTP_CLIENT;
      }
   } elsif ($os =~ m/(^win|esx|vmkernel)/i) {
      $vdLogger->Error("Lighttp binary requested for unsupported os=$os ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } else {
      $vdLogger->Error("Lighttp binary requested for unknow os=$os ");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

}


########################################################################
#
# GetToolOptions -
#       This translates the traffic keyworkds into the language which
#       lighttpd/weighttpd understands.
#
# Input:
#       Session Key (required)   - E.g. threadcount
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
         return 0;
   } else {
      switch ($sessionKey) {
         case m/(server)/i {
            return " http://$sessionValue->{'testip'}/index.html";
         }
         case m/requestcount/i {
            return " -n $sessionValue ";
         }
         case m/threadcount/i {
            return " -t $sessionValue ";
         }
         case m/concurrentclients/i {
            return " -c $sessionValue ";
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
#       global options and test options.
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
   if (defined $option) {
         $self->{testOptions} =  "$option " . $self->{testOptions};
   }
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
   my $self = shift;
   my $sessionID  = shift;
   my $os = $sessionID->{$self->{'mode'}}->{'os'};
   if ($self->{'mode'} =~ m/server/i) {
      $self->{command}  = "/root/" . $self->GetToolBinary($os);
   }
   else {
      $self->{command}  = "/usr/local/bin/" . $self->GetToolBinary($os);
   }
   return SUCCESS;
}

########################################################################
#
# IsToolServerRunning --
#       This method is for finding if a trafficToolServer running or did
#       it quit with some error message.
#
# Input:
#
# Results:
#       SUCCESS - in case tool server is running
#       FAILURE - in case of error.
#
# Side effects:
#       none
#
########################################################################

sub IsToolServerRunning
{
   return SUCCESS;
}

1;
