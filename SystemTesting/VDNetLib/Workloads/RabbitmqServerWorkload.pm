########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::RabbitmqServerWorkload;

#
# This package/module is used to run workload that involves executing
# Rabbitmqentication Server operations. The supported operations are given
# in the workload hash and all the operations are done sequentially by this
# package.
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::VSM::RabbitmqServerOperations object that this module
# uses extensively have to be registered in testbed object of vdNet.
# The workload hash can contain the following keys. The supported values
# are also given below for each key.
#
# Management keys:-
# ---------------
# Type      => "RabbitmqServer" (this is mandatory and the value
#                                  should be same)
# TestRabbitmqServer    => "rabbitmqserver.[1]"
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
#      VDNetLib::Workloads::RabbitmqServerWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::RabbitmqServerWorkload object, if successful;
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
      'targetkey'    => "testrabbitmqserver",
      'managementkeys' => ['type','iterations','testrabbitmqserver','expectedresult',
                           'sleepbetweencombos','sleepbetweenworkloads'],
      'componentIndex' => undef
      };

    $vdLogger->Debug("Creating RabbitmqServer Workload Object");
    bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}

1;
