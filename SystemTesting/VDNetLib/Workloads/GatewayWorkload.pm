########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::GatewayWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload VDNetLib::Workloads::VMWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);




########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::GatewayWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::GatewayWorkload object, if successful;
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
      'targetkey'    => "testgateway",
      'managementkeys' => ['type', 'iterations','testgateway','testtorgateway',
                           'expectedresult','sleepbetweencombos'],
      'componentIndex' => undef
   };
   bless ($self, $class);
   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}


########################################################################
#
# ProcessTOREntriesParameters --
#     Method to process 'tor_entries' key. This method will return the
#         TOR switch and/or vtep component object based on the tuple
#
# Input:
#     binding: reference to an array where each element is
#              one tor switch tuple and/or vtep tuple, like:
#                 - switch: torgateway.[1].torswitch.[1]
#                   vtep: torgateway.[1].vnic.[1]
#                 - switch: torgateway.[1].torswitch.[2]
#                   vtep: torgateway.[1].vnic.[2]
#
# Results:
#     updated TOR entries with TOR switch object and/or Vtep object
#
########################################################################

sub ProcessTOREntriesParameters
{
   my $self = shift;
   my $bindings = shift;
   my $switch = undef;
   my $vtep   = undef;

   if (not defined $bindings) {
      $vdLogger->Error("Binding entries not defined to process");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   foreach my $binding (@$bindings) {
        if (defined $binding->{'switch'}) {
           $switch = $binding->{'switch'};
           $binding->{'switch'} = $self->GetComponentObjects($switch)->[0];
        }
        if (defined $binding->{'vtep'}) {
           $vtep = $binding->{'vtep'};
           $binding->{'vtep'} = $self->GetComponentObjects($vtep)->[0];
        }
   }
   return $bindings;
}
1;
