##############################################################################
#
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# package VDNetLib::Workloads::DatacenterWorkload;
# This package is used to run Datacenter workload that involves
#
#    -- Add/Remove Hosts to Datacenters
#
# The interfaces new() are implemented
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::VC::Datacenter object will be created in new function
# In this way, all the Datacenter workloads can be run parallelly with no
# re-entrant issue.
#
###############################################################################

package VDNetLib::Workloads::DatastoreWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::Host::Datastore;


###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::DatastoreWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::DatastoreWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
###############################################################################

sub new
{
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
      'targetkey'      => "testdatastore",
      'managementkeys' => ['type', 'iterations', 'testdatastore'],
      'componentIndex' => undef
      };
   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}

1;
