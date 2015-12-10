########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::InventoryWorkload;

#
# This package/module is used to run workload that involves executing
# Inventory operations. The supported operations are given in the
# workload hash and all the operations are done sequentially by this
# package.

#
# Management keys:-
# ---------------
# Type      => "Inventory"
#

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);

use VDNetLib::InlinePython::VDNetInterface qw(Boolean);


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::InventoryWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::InventoryWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
########################################################################

sub new
{
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
      'targetkey'    => "testinventory",
      'managementkeys' => ['type','iterations','testinventory','expectedresult',
                           'sleepbetweencombos','sleepbetweenworkloads'],
      'componentIndex' => undef
      };

    $vdLogger->Debug("Creating Inventory Workload Object");
    bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}

1;
