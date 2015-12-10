########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::IOWorkload;

#
# This package/module is used to run workload that involves executing
# Storage Network IO operations. The supported operations are given in the
# workload hash and all the operations are done sequentially by this
# package.
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads::Workloads module.
#
# All the keys marked * are MANDATORY.
# Management keys:-
# ---------------
# Type           => "IO" (this is mandatory and the value should be same)
# TestIO         => "vm.[1]" or "host.[1].datastore.[1]"
#

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::IOWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::IOWorkload object, if successful;
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
      'targetkey'    => "testdisk",
      'managementkeys' => ['type','testdisk','testadapter','supportadapter','iterations',
	                   'expectedresult','sleepbetweencombos','sleepbetweenworkloads'],
      'componentIndex' => undef
      };

    bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();
   return $self;
}


########################################################################
#
#  PreProcessSendOnePyDictToPythonObj--
#       This method pushes runtime parameters into a hash and returns the
#       hash. Python Objects will not handle variable arguments as it needs
#       to be consistent with arguments of a method (unlike perl)
#       Thus we sending all parameters in just one hash/pyDict
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessSendOnePyDictToPythonObj
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @array;
   push(@array, $paramValues);
   return \@array;
}


########################################################################
#
#  PreProcessGetNodeInfo --
#       We need to send os, arch, username, password as common attributes
#       to IO tools
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#      Return a hash of node info
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessGetNodeInfo
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   # Get the os and arch from the VM obj and remove the vm obj before sending
   # the paramValues
   my $nodeObj  = $self->GetOneObjectFromOneTuple($testObject);
   # Node can be VM, ESX Host or other host, these classes
   # should have below method
   # This should match the attributes in node.py class at python layer
   my $nodeInfo = {
      'controlip' => $nodeObj->GetControlIP(),
      'testip'    => undef,
      'username'  => $nodeObj->GetUsername(),
      'password'  => $nodeObj->GetPassword(),
      'os'        => $nodeObj->GetOS(),
      'arch'      => $nodeObj->GetArchitecture(),
   };
   return $nodeInfo;
}

########################################################################
#
#  AnalyzePyResultObject
#       This method reads the result object from python layer and decides
#       pass or fail
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       runtimeResult - Result from the core api
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub AnalyzePyResultObject
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   if ((defined $runtimeResult->{status_code}) &&
       ($runtimeResult->{status_code} == 0)) {
      $vdLogger->Debug("Result object from python layer returned Status Code:" .
                       "$runtimeResult->{status_code}");
      return SUCCESS;
   } else {
      if (defined $runtimeResult->{status_code}) {
         $vdLogger->Error("Result object from python layer returned Status Code:" .
                          "$runtimeResult->{status_code}");
      }
      if (defined $runtimeResult->{error}) {
         $vdLogger->Error("Result object from python layer returned " .
                          "Error:$runtimeResult->{error}");
      }
      if (defined $runtimeResult->{reason}) {
         $vdLogger->Error("Result object from python layer returned " .
                          "Reason:$runtimeResult->{reason}");
      }
      if (defined $runtimeResult->{response_data}) {
         $vdLogger->Error("Result object from python layer returned " .
                          "Response data:$runtimeResult->{response_data}");
      }
      $vdLogger->Debug("Analyzing Python ResultObject resulted in failure");
      return FAILURE;
   }
}



1;
