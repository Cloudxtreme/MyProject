########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

###############################################################################
#
# package VDNetLib::Workloads::ClusterWorkload;
# This package is used to run Cluster workload that involves
#
#
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::VC::ClusterWorkload object will be created in new function
# In this way, all the Cluster workloads can be run parallelly with no
# reentrant issue.
#
###############################################################################

package VDNetLib::Workloads::ClusterWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::FeaturesMatrix qw(%vdFeatures);
use VDNetLib::Common::Iterator;
use VDNetLib::Common::Utilities;
use VDNetLib::Workloads::Utils;
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use File::Basename;


###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::ClusterWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::VCWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
###############################################################################

sub new {
   my $class = shift;
   my %options = @_;
   my $self;

   if (not defined $options{testbed} || not defined $options{workload}) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }
   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
      'targetkey'      => "testcluster",
      'managementkeys' => ['type', 'iterations', 'testcluster'],
      'componentIndex' => undef,
      };

    bless ($self, $class);
   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
    return $self;
}


########################################################################
#
#  PreProcessEditClusterSettings --
#       This method pushes runtime parameters into an array in proper oder
#       and returns the reference to array. This API is used mainly where
#       the arguments are shift type and not hash based input.
#
# Input:
#       runtimeParamsHash - reference to the hash containing values which
#                           will be used as arguments.
#       argumentOrder     - reference to array of params defined under action
#                           key.
#       action            - add/delete.
#
# Results:
#      SUCCESS - return reference to array if array is filled with values
#      FAILURE - incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessEditClusterSettings
{
   my $self              = shift;
   my ($testObject, $keyName, $keyValue, $runtimeParamsHash, $argumentOrder) = @_;

   my @array ;
   my $hashRef;
   my $keyMap = {
      ha		=> 'HA',
      admissioncontrol  => 'admissionControl',
      failoverlevel     => 'failoverLevel',
      isolationresponse => 'isolationResponse',
      waithaconf        => 'waitHAConf',
      drs		=> 'DRS',
      vsan		=> 'VSAN',
      autoclaimstorage  => 'AutoClaimStorage',
      advancedoptions   => "advancedoptions",
   };
   foreach my $parameter (@$argumentOrder){
      my $key = $keyMap->{$parameter};
      $hashRef->{$key} = $runtimeParamsHash->{$parameter};
   }

   push(@array, $hashRef);
   return \@array;
}

1;
