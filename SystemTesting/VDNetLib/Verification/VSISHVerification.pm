#!/usr/bin/perl
###############################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::VSISHVerification;

#
# This module gives object of Vsish verification. It deals with gathering
# initial and final stats before a test is executed and then taking a diff
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

use constant VSISH_BASE_PATH => "/net/portsets/VSWITCH/ports/PORTNUMBER/";
use constant DEFAULT_INTR_QUEUE_COUNT => 4;


###############################################################################
#
# new -
#       This method creates obj of this class.
#
# Input:
#       none
#
# Results:
#       Obj of VSISHVerification module, if successful;
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;
   my $self  = {
     # We keep arch for esx as 32 as we use most of the 32 bit binaries
     # from vdnet bin folder.
     'os'          => "vmkernel",
     'arch'        => "x86_32"
   };

   bless ($self, $class);
   return $self;
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
   my $os = $self->{os};
   my @params;
   @params = ("drivername", "hostobj", "host", "mac", "vmx");
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
#                        verification module understands.
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
      'testbed'    => {
         'hostobj'         =>  {
              'hostIP'         =>  'host',
              'portgroups' => 'portgroups',
            },
          'adapter'   =>   {
             'driver'      => 'drivername',
             'macAddress'  => 'mac',
          },
          'vmOpsObj'  =>  {
             'vmx'        => 'vmx',
          },
          'portgroups'  => {
             'portgroups' => 'portgroups',
          },
      },
   };

   return $spec;
}


###############################################################################
#
# VerificationSpecificJob -
#       A void method which the child can override and do things which are
#       specific to that child
#       Parents leaves a hook so that future childs can make changes without
#       modifying the parent.
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

sub VerificationSpecificJob
{
   my $self = shift;
   # VSISH is always done in the host. For target srcvm and srchost vsish stats
   # are gathered from host. Thus changing the target to host.
   $self->{targetip} = $self->{host};

   # To keep the code backward compatible to old testcases.
   my $expectedChange = $self->{expectedchange};
   if ((!keys %$expectedChange) && $self->GetBackwardCompatibility()) {
      $self->{expectedchange}->{'/net/portsets/<PORTSET>/ports/<PORT>/clientstats.bytesRxOK'} = "1+";
   }
   return SUCCESS;
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
   return "dstvm";

}


###############################################################################
#
# GetSupportedPlatform -
#       Returns the platforms supported by this module. Only options are guest
#       and host.
#       If some verification is only supported on win/linux, specific flavor
#       of win/linux, specific kernel version they will be caught later.
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
   return "guest,host";

}


###############################################################################
#
# GetDefaultNode -
#       Returns the default nodes on each platform type for this kinda of
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

   # This is our specification. We will get the counters
   # according to this specification.
   # vsish -e get /net/portsets/vss-0-1614/ports/50331982/vmxnet3/txqueues/0/stats
   $nodeTemple = {
      'vmkernel' => {  # ESX Version number
         "stats" => {
         },
         "clientStats" => {
         },
         "vmxnet3/txSummary" => {
         },
         "vmxnet3/rxSummary" => {
         },
         "vmxnet3/intr/X/stats" => {
         },
         "vmxnet3/intrSummary" => {
         },
         "vmxnet3/txqueues/X/stats" => {
         },
         "vmxnet3/rxqueues/X/stats" => {
         },
         "e1000/hdrspStats"   => {
         },
         "vmxnet2clientStats" => {
         },
      },
   };

   # Replace X with Numbers such that you get
   # vmxnet3/txqueues/X/stats where X is from 0 to 3 (4 queues)
   foreach my $os (keys %$nodeTemple) {
      my $allNodes = $nodeTemple->{$os};
      foreach my $node (keys %$allNodes) {
         if($node =~ /\/X\//i) {
            my $newNode;
            for (my $i = 0; $i < DEFAULT_INTR_QUEUE_COUNT; $i++) {
               $newNode = $node;
               $newNode =~ s/\/X\//\/$i\//g;
               $allNodes->{$newNode}->{nodetype} = "known";
            }
            delete $allNodes->{$node};
         } else {
            $allNodes->{$node}->{nodetype} = "known";
         }
      }
   }

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
