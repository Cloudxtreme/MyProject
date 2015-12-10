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

package VDNetLib::Workloads::DatacenterWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::VC::Datacenter;


###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::DatacenterWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::DatacenterWorkload object, if successful;
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
      'targetkey'      => "testdatacenter",
      'managementkeys' => ['type', 'iterations', 'testdatacenter'],
      'componentIndex' => undef
      };
   bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
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


########################################################################
#
#  PreProcessDeleteHostFromDC --
#       This method returns reference to array containing hosts objects
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - list of host tuples which needs to be deleted
#
# Results:
#      SUCCESS - returns reference to array containing hosts objects
#      FAILURE - incase of result is undefined
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessDeleteHostFromDC
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue) = @_;

   $vdLogger->Debug("Deleting $keyValue from Datacenter");
   my $refHost = VDNetLib::Common::Utilities::ProcessMultipleTuples($keyValue);
   my $result = $self->GetArrayOfObjects($refHost);
   if ($result eq "FAILURE") {
      $vdLogger->Error("Invalid ref for array of tuples $keyValue");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# PostProcessDeleteHostFromDC --
#     Post process method for "DeleteHostFromDC" key.
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       keyValue      - Value assigned to action key in config hash
#       paramValue    - Reference to hash where keys are the contents of
#                       'params' and values are the values that are assigned
#                       to these keys in config hash.
#       runtimeResult - order in which the arguments will be passed to core api
#
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     None
#
#
########################################################################

sub PostProcessDeleteHostFromDC
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $result;

   my $args = $self->{runtime}{arguments};

   foreach my $hostObj (@$args) {
      if (defined $hostObj) {
	 $result = $self->{testbed}->SetComponentObject($hostObj->{objID},
							$hostObj);
	 if ($result eq FAILURE) {
	    $vdLogger->Error("Failed to update the testbed hash.");
	    VDSetLastError(VDGetLastError());
	    return FAILURE;
	 }
      }
   }

   return SUCCESS;
}


########################################################################
#
# PostProcessImport --
#     Post process method for "import" key.
#
# Input:
#       testObject    - An object, whose core api will be executed
#       keyName       - Name of the action key
#       keyValue      - Value assigned to action key in config hash
#       paramValue    - Reference to hash where keys are the contents of
#                       'params' and values are the values that are assigned
#                       to these keys in config hash.
#       runtimeResult - order in which the arguments will be passed to core api
#
#
# Results:
#     Return paramter hash as an argument
#     Return FAILURE in case of any error
#
# Side effects:
#     None
#
#
########################################################################

sub PostProcessImport
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $result;

   $result = $self->{testbed}->SetComponentObject($keyValue, $runtimeResult);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}

1;
