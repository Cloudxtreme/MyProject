##############################################################################
#
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# package VDNetLib::Workloads::ClusterNodeWorkload;
# This package is used to run ClusterNode workload that involves
#
#
# The interfaces new(), have been implemented to work with
# VDNetLib::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::NSXController::ClusterWorkload object will be created in new function
# In this way, all the Cluster workloads can be run parallelly with no
# reentrant issue.
#
###############################################################################

package VDNetLib::Workloads::ClusterNodeWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;


###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::ClusterNodeWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::ClusterNodeWorkload object, if successful;
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

   if ((not defined $options{testbed}) || (not defined $options{workload})) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $self = {
      'testbed'        => $options{testbed},
      'workload'       => $options{workload},
      'targetkey'      => "testclusternode",
      'managementkeys' => ['type', 'iterations', 'testclusternode'],
      'componentIndex' => undef
      };
   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}

1;
