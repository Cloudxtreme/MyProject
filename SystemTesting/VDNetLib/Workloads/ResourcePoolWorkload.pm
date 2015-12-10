########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

###############################################################################
#
# package VDNetLib::Workloads::ResourcePoolWorkload;
# This package is used to run resource pool  workload that involves
# various operations related to resource pool.
#
#
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads module.
#
#
###############################################################################

package VDNetLib::Workloads::ResourcePoolWorkload;

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

# Database of Keys
# KEYNOTE: keys movehoststocluster and movehostsfromcluster should not be used in
# same workload



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
      'targetkey'      => "testresourcepool",
      'managementkeys' => ['type', 'iterations', 'testresourcepool'],
      'componentIndex' => undef,
      };

    bless ($self, $class);
   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
    return $self;
}

1;
