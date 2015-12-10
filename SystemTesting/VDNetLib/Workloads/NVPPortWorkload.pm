##############################################################################
#
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::Workloads::NVPPortWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::PortWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;



###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::NVPWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::PortWorkload object, if successful;
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
   $self->{targetkey} = "testport";
   $self->{managementkeys} = ['type', 'iterations', 'testport'];
   $self->{componentIndex} = undef;
   bless ($self, $class);

   # Extending the KEYSDATABASE of PortGroup
   my $portKeysDatabase = $self->GetKeysTable();
   my $refNewKeysDataBase = {%{$self->{keysdatabase}}, %$portKeysDatabase};
   $self->{keysdatabase} = $refNewKeysDataBase;
   #$self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}


########################################################################
#
# ConfigureComponent --
#      This method is used to configure devices using the
#      ConfigureComponet() of ParentWorkload
#
# Input:
#      dupWorkload : a copy of the workload
#      $testObject : datacenter object
#
# Result:
#      "SUCCESS" - if all the network configurations are successful,
#      "FAILURE" - in case of any error.
#      "SKIP"    - incase the return value is SKIP
#
# Side effects:
#      None
#
########################################################################

sub ConfigureComponent
{
   my $self = shift;
   my %args        = @_;
   my $dupWorkload = $args{configHash};
   my $testObject  = $args{testObject};

   # For ver2 we will call the ConfigureComponent from parent class first.
   my $result = $self->SUPER::ConfigureComponent('configHash' => $dupWorkload,
                                                 'testObject' => $testObject);

   if (defined $result) {
      if ($result eq "FAILURE") {
         return "FAILURE";
      } elsif ($result eq "SKIP") {
         return "SKIP";
      } elsif ($result eq "SUCCESS") {
         return "SUCCESS";
      }
   }
}
1;
