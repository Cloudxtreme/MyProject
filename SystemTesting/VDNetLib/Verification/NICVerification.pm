#!/usr/bin/perl
###############################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::NICVerification;

#
# This module gives object of NIC verification. It deals with gathering
# initial and final stats of all types of nics (vnic, pnic on all os types)
# before a test is executed and then taking a diff
# between the two stats.
#

# Inherit the parent class.
require Exporter;
# ISA was not doing multiple inheritance thus I am using use base which works well
# for multiple inheritance.
use base qw(VDNetLib::Verification::StatsVerification
	    VDNetLib::Verification::Verification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;
use Switch;

use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

###############################################################################
#
# new -
#       This method creates obj of NICVerification class.
#
# Input:
#	none
#
# Results:
#       Obj of StatsVerification module - in case everything goes well.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;
   my $self  = {};
   bless ($self, $class);
   return $self;
}


###############################################################################
#
# RequiredParams -
#       This is a child method. It says what param does it need from testbed,
#       traffic or netadapter to intialize verification.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub RequiredParams
{
   # This is child method. Move it.
   my $self = shift;
   my $os = $self->{os};

   my @params;
   if ($os =~ /win/i) {
      #TODO: Add support for windows
   } elsif ($os =~ /(esx|vmkernel|linux)/i)  {
      @params = ('nic');
   }

   return \@params;
}


##############################################################################
#
# GetChildHash --
#       Its a child method. It returns a conversionHash which is specific to
#       what child wants.
#
# Input:
#       none
#
# Results:
#       converted hash - a hash containging node info in language that
#			 verification module understands.
#       FAILURE - in case of error.
#
# Side effects:
#       None
#
##############################################################################

sub GetChildHash
{
   my $self = shift;
   my $spec = {
      'testbed'   => {
         'adapter'   =>   {
            'interface'   => 'nic',
         },
      },
   };

   return $spec;
}


###############################################################################
#
# GetMyChildren -
#       List of child verifications supported by this Verification module.
#       This list is used in case user does not specify any verification type
#
# Input:
#       None
#
# Results:
#       array - containing names of child modules
#
# Side effects:
#       None
#
###############################################################################

sub GetMyChildren
{
   # NIC Verification has no children.
   return 0;
}


###############################################################################
#
# GetDefaultTargets -
#       Returns the default target to do verification on, in case user does
#       not specify any target.
#
# Input:
#       none
#
# Results:
#       string  - comma sepearted values of default target.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetDefaultTargets
{
   my $self = shift;
   return "dstvm,srcvm";

}


###############################################################################
#
# GetSupportedPlatform -
#       Returns the platforms supported by this module. Only options are guest
#       and host.
#       If some verification is only supported on win/linux, specific flavor
#       of win/linux, specific kernel version, they will be caught later.
#       Every child needs to implement this. Parent should not implement it.
#
# Input:
#       none
#
# Results:
#       string  - comma sepearted values supported platform
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetSupportedPlatform
{

   # This verification is supported inside the guest
   # as well as on host.
   return "guest,host";

}


###############################################################################
#
# GetDefaultNode -
#       Returns the default nodes on each platform type for this kind of
#       verification.
#
# Input:
#       none
#
# Results:
#       hash  - containing all default nodes.
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetDefaultNode
{
   my $self = shift;
   my $nodeTemple;

   #
   # This is our specification. We will get the counters
   # according to this specification.
   # For ESX
   # vsish -e get /net/pNics/vmnic0/stats
   # For Linux
   # ethtool -S ethX.
   #
   $nodeTemple = {
      'vmkernel' => {
         "/net/pNics/VMNIC/stats" => {},
         "/net/portsets/PORTSET/uplinks/VMNIC/vlanStats/1/stats" => {},
      },
      'linux' => {
         "ethtool -S " => { # statistics
         },
         # For future more stats such as these can be gathered.
         # "ethtool -g " # ring size changes
         # "ethtool -C " # coalesce stats
         # "ethtool -k " # offload settings
      },
   };
   return $nodeTemple;
}


###############################################################################
#
# DESTROY -
#       This method is destructor for this class.
#
# Input:
#       None.
#
# Results:
#       SUCCESS
#
# Side effects:
#
###############################################################################

sub DESTROY
{
   return SUCCESS;
}

1;
