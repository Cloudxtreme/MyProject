########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::NSXWorkload;

#
# This package/module is used to run workload that involves executing
# NSX operations. The supported operations are given in the
# workload hash and all the operations are done sequentially by this
# package.
# The interfaces new(), StartWorkload() and CleanUpWorkload() have been
# implemented to work with VDNetLib::Workloads::Workloads module.
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::VSM::VSMOperations object that this module
# uses extensively have to be registered in testbed object of vdNet.
# The workload hash can contain the following keys. The supported values
# are also given below for each key.
#
# All the keys marked * are MANDATORY.
# Management keys:-
# ---------------
# Type      => "NSX" (this is mandatory and the value should be same)
# TestNSX    => "nsx.[1].x.[x]"
#

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Workloads::GroupingObjectWorkload;
use VDNetLib::Workloads::ServiceWorkload;
use VDNetLib::Workloads::TransportZoneWorkload;
use VDNetLib::Workloads::TransportNodeWorkload;

use VDNetLib::InlinePython::VDNetInterface qw(Boolean);



########################################################################
#
# GetVCInfo --
#     Method to get VC Info
#
# Input:
#     vcTuple  : vc tuple in format vc.[<x>].x.x
#
# Results:
#     Reference to hash with following keys
#      'ipAddress'
#      'userName'
#      'password'
#
# Side effects:
#     None
#
########################################################################

sub GetVCInfo
{
   my $self = shift;
   my $keyValue = shift;
   my $vcObj  = $self->GetOneObjectFromOneTuple($keyValue);
   my $user    = $vcObj->{user};
   my $passwd  = $vcObj->{passwd};
   my $vc      = $vcObj->{vcaddr};
   my $thumbprint = $vcObj->GetThumbprint();
   my $vcInfo = {
      'ipaddress' => $vc,
      'username'   => $user,
      'password'  => $passwd,
      'certificatethumbprint' => $thumbprint,
   };
   return $vcInfo;

}


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::NSXWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::NSXWorkload object, if successful;
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
      'targetkey'    => "testnsx",
      'managementkeys' => ['type','iterations','testnsx','expectedresult',
                           'sleepbetweencombos','sleepbetweenworkloads'],
      'componentIndex' => undef
      };

    bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}


########################################################################
#
# GetPythonBoolean --
#      Method which converts a 1/0 to an
#      object of Inline Python Boolean
#
# Input:
#      A value of 1 or 0:
#
# Results:
#      Returns an object of Inline Python Boolean type
#      or Perl object if the input is a tuple
#
# Side effects:
#      None
#
########################################################################

sub GetPythonBoolean
{
   my $self = shift;
   my $bool = shift;

   if ($bool =~ m/\.\[/i) {
      return $self->ProcessParameters($bool);
   } else {
      return Boolean($bool);
   }
}


########################################################################
#
# PreProcessNSXHashTypeAPI --
#     Method to process NSX specs which does not involve any vdnet component
#     creation. REST calls are POST, we use CreateAndVerifyComponent from vdnet
#     point of view as the obj is new but there is no need to store it as object
#     in zookeeper or tuple thus we just create it and forget about it
#     treating it as configuration on exisiting vdnet object
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue   - Value assigned to action key in config hash
#
# Results:
#     Reference to an array which has 3 elements:
#     [0]: name of the component
#     [1]: reference to the test object
#     [2]: reference to an array of hash which contains hash as
#          spec
#
# Side effects:
#     None
#
########################################################################

sub PreProcessNSXHashTypeAPI
{
   my $self       = shift;
   my $testObject = shift;
   my $keyName    = shift;
   my $keyValue   = shift;
   my $paramValue = shift;
   my $paramList  = shift;

   my @array;
   push(@array, %$paramValue);
   return [$keyName, \@array];
}


########################################################################
#
# PostProcessApplianceVM --
#     Method to postprocess appliance VM action keys
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     runtimeResult: order in which the arguments will be passed to core api
#
# Results:
#     SUCCESS if all the appliance VMs init succesfully
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PostProcessApplianceVM
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;
   my $originalPerlObjs = $runtimeResult->[0];
   my $applianceObjs   = $runtimeResult->[1];
   my $originalPerlObjsCount = @$originalPerlObjs;
   my $applianceObjsCount   = @$applianceObjs;

   if ($applianceObjsCount < $originalPerlObjsCount) {
      $self->StoreSubComponentObjects($testObject, $keyName, $keyValue,
                                      $paramValues, $originalPerlObjs);
      return FAILURE;
   } else {
      $self->StoreSubComponentObjects($testObject, $keyName, $keyValue,
                                      $paramValues, $applianceObjs);
      return SUCCESS;
   }
}


########################################################################
#
# PreProcessVerifyIpsetAttributes --
#     Method to preprocess the attributes of Ipset endpoint
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array containing object references & params will
#     be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVerifyIpsetAttributes
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData = {};
      if ($parameter eq $keyName) {
         foreach my $key (keys %$keyValue) {

            if (ref($keyValue->{$key}) =~ /ARRAY/) {
               foreach my $element (@{$keyValue->{value}}){
                  #
                  # If the key is a tuple
                  #
                  if ($element =~ m/vm\.\[\d+\]\.vnic\.\[\d+\]/i) {
                     my $vnicObj = $self->GetOneObjectFromOneTuple($element);
                     if ($vnicObj eq FAILURE) {
                        $vdLogger->Error("Tuple has not been passed in the ".
                           "required tuple format : vm.[#].vnic.[#] or the ".
                           "object does not exist");
                        VDSetLastError("ENOTDEF");
                        return FAILURE;
                     }
                     push(@{$userData->{$key}},$vnicObj->GetIPv4());
                  } else {
                     push(@{$userData->{$key}},$element);
                  }
               }
            } else {
               $userData->{$key} = $keyValue->{$key};
            }
         }
      } else {
          $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }

   return \@array;
}


########################################################################
#
# PreProcessVerifyMacsetAttributes --
#     Method to preprocess the attributes of Macset endpoint
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array containing object references & params will
#     be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVerifyMacsetAttributes
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData = {};
      if ($parameter eq $keyName) {
         foreach my $key (keys %$keyValue) {

            if (ref($keyValue->{$key}) =~ /ARRAY/) {
               foreach my $element (@{$keyValue->{value}}){
                  #
                  # If the key is a tuple
                  #
                  if ($element =~ m/vm\.\[\d+\]\.vnic\.\[\d+\]/i) {
                     my $vnicObj = $self->GetOneObjectFromOneTuple($element);
                     if ($vnicObj eq FAILURE) {
                        $vdLogger->Error("Tuple has not been passed in the ".
                           "required tuple format : vm.[#].vnic.[#] or the ".
                           "object does not exist");
                        VDSetLastError("ENOTDEF");
                        return FAILURE;
                     }
                     push(@{$userData->{$key}},$vnicObj->GetMACAddress());
                  } else {
                     push(@{$userData->{$key}},$element);
                  }
               }
            } else {
               $userData->{$key} = $keyValue->{$key};
            }
         }
      } else {
          $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }

   return \@array;
}


########################################################################
# PreProcessVerifyApplicationServiceAttributes --
#     Method to preprocess the attributes of ApplicationService endpoint
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array containing object references & params will
#     be returned, if successful
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVerifyApplicationServiceAttributes
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   my $userData = {};
   foreach my $parameter (@$paramList) {
      if ($parameter eq $keyName) {
         foreach my $key (keys %$keyValue) {
            $userData->{$key} = $keyValue->{$key};
         }
      } else {
          $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }

   return \@array;
}


########################################################################
#
# PostProcessDeleteActiveController --
#     Method to postprocess "deleteactivecontroller" action
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     runtimeResult: order in which the arguments will be passed to core api
#
# Results:
#     SUCCESS if all the controller appliance VM deleted succesfully
#     FAILURE, if any error
#
# Side effects:
#     None
#
########################################################################

sub PostProcessDeleteActiveController
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $runtimeResult) = @_;

   my $result = $self->{testbed}->SetComponentObject($runtimeResult->{objID},
                                                     "delete");
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to update the testbed hash.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# PreProcessVtepTableForLogicalSwitch --
#     Method to process user spec data parameters
#
# Input:
#     testObject : Testbed object being used here
#     keyName    : Name of the key being worked upon here
#     keyValue   : Value of the key being worked upon here
#     paramValues: Values of the params in the test hash
#     paramList  : List / order of the params being passed
#
# Results:
#     Reference to an array which contains arguments for
#     method PreProcessVtepTableForLogicalSwitch.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVtepTableForLogicalSwitch
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData;
      my @handledData;
      if ($parameter eq $keyName) {
         my $userProcessedData = $self->ProcessParameters($paramValues->{$keyName});
         $userProcessedData = $userProcessedData->{'table'};
         foreach my $entry (@$userProcessedData) {
            my $lsObj  = $entry->{switch_vni};
            my $hostObj = $entry->{ipaddress};
            my $vtepdetail = $hostObj->GetAllVxlanVtepDetailOnHost();
            foreach my $vtep (@$vtepdetail) {
               push @handledData, {'switch_vni' => $lsObj->{vxlanId},
                                   'ipaddress'  => $vtep->{"adapter_ip"},
                                   'adapter_mac'  => uc($vtep->{"adapter_mac"}),
                                   'segmentid' => $vtep->{"segment_id"}};
            }
         }
         $vdLogger->Debug("Data after processing user input " . Dumper(@handledData));
         $userData = {'table' => \@handledData};
      } else {
         $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }
   return \@array;
}


1;
