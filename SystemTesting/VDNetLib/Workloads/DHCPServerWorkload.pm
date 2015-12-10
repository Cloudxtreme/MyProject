########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::DHCPServerWorkload;

#
# This package/module is used to run workload that involves executing
# Controller operations. The supported operations are given in the
# workload hash and all the operations are done sequentially by this
# package.
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::Controller::ContollerOperations object that this module
# uses extensively have to be registered in testbed object of vdNet.
# The workload hash can contain the following keys. The supported values
# are also given below for each key.
#
# All the keys marked * are MANDATORY.
# Management keys:-
# ---------------
# Type      => "Controller" (this is mandatory and the value should be same)
# TestController    => "controller.[1].x.[x]"
#

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base ('VDNetLib::Workloads::ParentWorkload', 'VDNetLib::Workloads::VMWorkload');

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::Workloads::Utils;


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::ControllerWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::ControllerWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
########################################################################

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
      'componentIndex' => undef,
      'targetkey'    => "testdhcpserver",
      'managementkeys' => ['type','iterations','testdhcpserver','expectedresult',
                           'sleepbetweencombos','sleepbetweenworkloads']

      };

    bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();

    return $self;
}
1;
