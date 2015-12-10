##############################################################################
#
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::Workloads::LocalVDRWorkload;

#
# This package is for VDR testing.
# VDR is a distributed component like VDS, and is created and managed
# by VSM/VSE. VSM/VSE release cycles are not in sync with ESX. But VDR
# being part of both needs to be tested even when VSM/VSE are not ready
# Thus, we use whatever api/cli is available to simulate the behavior
# done by VSM/VSE and test it on ESX.

#
# The name "LocalVDR" signifies that this is specifically testing using
# net-vdr binary which configures VDR only on a local host, unlike VSM/VSE
# which do the configuration on distributed environment.
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);



###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::LocalVDRWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::LocalVDRWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
###############################################################################

sub new {
   my $class = shift;
   my %options = @_;

   if ((not defined $options{testbed}) || (not defined $options{workload})) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $self = {
      'testbed'        => $options{testbed},
      'workload'       => $options{workload},
      'targetkey'      => "testvdr",
      'managementkeys' => ['type', 'iterations', 'expectedresult','testvdr',
                           'sleepbetweencombos']
   };
   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}

1;
