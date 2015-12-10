##############################################################################
#
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::Workloads::LACPWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::AbstractSwitchWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;


###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::LACPWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::LACPWorkload object, if successful;
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
   my $self = VDNetLib::Workloads::AbstractSwitchWorkload->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::Workloads::AbstractSwitchWorkload" .
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{targetkey} = "testlag";
   $self->{managementkeys} = ['type', 'iterations', 'testlag', 'expectedresult'];
   $self->{componentIndex} = undef;
   bless ($self, $class);

   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}


########################################################################
#
#  PreProcessValueCheckCaseSensitive
#       This method checks if the value passed by user falls under
#       supported values of this key.
#       Note: The values should match the case also
#
# Input:
#
# Results:
#      SUCCESS - if matched
#      FAILURE - if did not match
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessValueCheckCaseSensitive
{
   #TODO: Move this method to ParentWorkload so that everyone can use it
   # Have both case sensitive and case insensitive versions
   return SUCCESS;
}

1;
