#!/usr/bin/perl
###############################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
###############################################################################
package VDNetLib::Verification::StressVerification;

#
# This package inherits VDNetLib::Verification::Verification class.
# This is used for verifying if stress options in vsish are being exercised
# or not

# Inherit the parent class.
require Exporter;
#use vars (qw(@ISA));
use base qw(VDNetLib::Verification::StatsVerification VDNetLib::Verification::Verification);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;

use PLSTAF;
use VDNetLib::TestData::StressTestData;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use constant VMKSTRESS_BASE_PATH => "/reliability/vmkstress/";

###############################################################################
#
# new -
#       This method creates obj of this class. 
#
# Input:
#       none 
#
# Results:
#       Obj of StressVerification module, if successful;
#
# Side effects:
#       None
#
###############################################################################

sub new
{
   my $class = shift;
   my $self  = {
     # Stress Verification is always done on the host 
     'os'          => "vmkernel",
     'arch'        => "x86_32",
     # How to display the info on console. There are different types
     # of data displays.
     displaytype   => "targetcentric",
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
   @params = ("drivername", "hostobj", "host", "mac");

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
            'hostobj'         =>   {
                  'hostIP'            =>  'host',
            },
            'adapter'         =>   {
                  'driver'            => 'drivername',
                  'macAddress'        => 'mac',
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
   return SUCCESS;
}


###############################################################################
#
# VerificationSpecificDeletion -
#       Remove children which are not supported. Remove childrens for which
#       there is no expectation set.
#
# Input:
#       none
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub VerificationSpecificDeletion
{
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
# ProcessExpectationHash -
#       Overriding parent method just to save time.
#
# Input:
#       None
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ProcessExpectationHash
{
   return SUCCESS;
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
   return "srcvm,srchost,dstvm,dsthost";
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

   $nodeTemple = {
      # For ESX
      # this is for unit testing as this stress option is available on
      # all builds.
      'vmkernel' => {
         "IOForceCopy" => {
         },
      },
      # Verification of stress on other OSes can added in future.
   };

   return $nodeTemple;
}


###############################################################################
#
# InitVerification -
#       Initialize verification on this object.
#
# Input:
#       expectation key (mandatory)
#       expectation value (mandatory)
#       expectation type (optional)
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub InitVerification
{
   my $self = shift;
   $self->{os} = "vmkernel" if $self->{os} =~ /(vmkernel|esx)/i;
   my $veriType = $self->{veritype};

   my $allparams = $self->RequiredParams();
   foreach my $param (@$allparams) {
      if(not exists $self->{$param}) {
      $vdLogger->Error("Param:$param missing in InitVerification for $veriType".
                       "Verification");
      }
   }

   my $stressOptions = $self->{expectedchange}->{'stressoptions'};
   delete $self->{expectedchange}->{'stressoptions'};
   if(defined $stressOptions) {
      if($stressOptions =~ /^\%/i) {
         my %temp = eval($stressOptions);
         $stressOptions = \%temp;
      } else {
         # User can also supply a single hash value as stressOptions
         # E.g. stressoptions => "{NetCopyToLowSG => 150}",
         my $hash;
         if($stressOptions =~ /=/) {
            my @stressOption = split(/=/,$stressOptions);
            $stressOption[0] =~ s/^\s+//; #remove leading space
            $stressOption[0] =~ s/\s+$//; #remove trailing space
            if ((not defined $stressOption[1]) || (not defined $stressOption[0])) {
               $vdLogger->Error("Cannot understand stressoptions format:".
                                "$stressOptions");
               VDSetLastError("EINVALID");
               return FAILURE;
            }
            $hash->{$stressOption[0]} = $stressOption[1];
         } else {
            $hash->{$stressOptions} = undef;
         }
         $stressOptions = $hash;
      }
   } else {
      # If user has not defined any stressOptions then see if there are
      # any stressOptions preconfigured for this target OS.
      my $defaultNode = $self->GetDefaultNode();
      $stressOptions = $defaultNode->{$self->{os}};
   }


   $self->{expectedchange}->{'Hit count'} = "1+";

   foreach my $nodeKey (keys %$stressOptions) {
      my $actualNode;
      if ($self->{os} =~ /(vmkernel|esx)/i) {
         $actualNode = VMKSTRESS_BASE_PATH . $nodeKey;
      } else {
         $actualNode = $nodeKey;
      }
      # Command will either return 'unsupported' or raw data.
      # in case of later we convert it to hash and store it as template so
      # that we can set expected values on 'Hit count' which is 1+ by
      # default, user can override this value.
      # we also say supported = 'yes/no' for these nodes.
      my $ret = $self->ExecuteStatsCmd($self->{targetip}, $actualNode);
      if ($ret =~ /unsupported/i) {
         $ret = "no";
      } else {
         # Convert from raw data to Hash.
         my $hash = $self->ConvertRawDataToHash($ret, 0);
         $self->{statsbucket}->{nodes}->{$actualNode}->{"template"} = $hash;
         $ret = "yes";
      }
      $self->{statsbucket}->{nodes}->{$actualNode}->{"supported"} = $ret;
   }

   return SUCCESS;

}


###############################################################################
#
# GetBucket -
#       Get the name of the bucket storing stats.
#
# Input:
#       None
#
# Results:
#       ptr to bucket.
#
# Side effects:
#       None
#
###############################################################################

sub GetBucket
{
   my $self = shift;
   return $self->{statsbucket};
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
   my $self = shift;
   return SUCCESS;
}

1;
