#!/usr/bin/perl
###############################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::VOBVerification;

#
# This module gives object of VOB verification. It deals with gathering
# initial and final vob.log before a test is executed and then taking a diff
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
#       This method returns the obj of DmesgVerification package.
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
   my $self  = {};
   bless ($self, $class);
   return $self;
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
   # VMkernelVerification has no children.
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
   return "dsthost,srchost";

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

   # This verification is supported inside the guest
   # as well as on host.
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

   $logTemple = {
      'vob' => {
         "vob" => {
            'method'          => 'GetVOB',
            'obj'             => 'hostobj',
         },
      },
   };
   return $logTemple;
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
