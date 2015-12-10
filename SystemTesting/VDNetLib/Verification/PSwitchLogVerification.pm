#!/usr/bin/perl
###############################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
###############################################################################
package VDNetLib::Verification::PSwitchLogVerification;

#
# This module gives object of PSwitchLog verification. It deals with gathering
# initial and final logs before and after the test is executed and then takes a diff
# between the two logs.
#

# Inherit the parent class.
require Exporter;
# ISA was not doing multiple inheritance thus I am using use base which works well
# for multiple inheritance.
use base qw(VDNetLib::Verification::LogVerification
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
#       This method returns the obj of PSwitchLogVerification package.
#
# Input:
#       None
#
# Results:
#       Obj of Dmesg Verification.
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;
   return bless {}, $class;
}


###############################################################################
#
# GetMyChildren -
#       List of child verifications supported by this Verification module.
#
# Input:
#       None
#
# Results:
#       0 - there are no children of dmesg verification.
#
# Side effects:
#       None
#
###############################################################################

sub GetMyChildren
{
   # PSwitchLogVerification has no children.
   return 0;
}


###############################################################################
#
# GetSupportedPlatform -
#       Returns the platforms supported by this module. Only options are guest
#       and host.
#       If some verification is only supported on win/linux, specific flavor
#       of win/linux, specific kernel version it will be caught later.
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
   return "host";
}


###############################################################################
#
# GetDefaultLogType -
#       Returns the default log on each platform type for this kinda of
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

sub GetDefaultLogType
{
   my $self = shift;
   my $logTemple;
   #
   # vmkernel is the os of the target SUT:vmnic:1 and not the os of pswitch.
   # second key is just a tag
   #
   $logTemple = {
      'vmkernel' => {
         "pswitch" => {
            'method'          => 'GetLogs',
            'obj'             => 'pswitchobj',
         },
      },
   };
   return $logTemple;
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
#       converted hash - a hash containging node info in language verification
#                        module understands.
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
         'hostObj'   =>  'hostobj',
         'adapter'   =>   {
            'pswitchObj' => 'pswitchobj',
            'interface'  => 'interface',
            'switchPort' => 'switchport',
         },
      },
   };

   return $spec;
}

###############################################################################
#
# RequiredParams -
#       This is a child method. It says what param does it need from testbed
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
   my $self = shift;
   my @params = ('pswitchobj');
   return \@params;
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
