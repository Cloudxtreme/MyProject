##############################################################################
#
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# package VDNetLib::Workloads::SwitchWorkload;
# This package is used to run DV Switch Workload workload that involves
#
#
# The interfaces new() are implemented
#
# This package takes vdNet's testbed hash and workload hash.
# The VDNetLib::Switch::Switch object will be created in new function
# In this way, all the Switch workloads can be run parallelly with no
# re-entrant issue.
#
###############################################################################

package VDNetLib::Workloads::SwitchWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::AbstractSwitchWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::Workloads::LACPWorkload;
use VDNetLib::Workloads::NVPPortWorkload;


###############################################################################
#
# new --
#      Method which returns an object of VDNetLib::Workloads::SwitchWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supswitched key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::SwitchWorkload object, if successful;
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
      $vdLogger->Error("Testbed $options{testbed} workload $options{workload}");
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
   $self->{targetkey} = "testswitch";
   $self->{managementkeys} = ['type', 'iterations', 'testswitch', 'expectedresult'];
   $self->{componentIndex} = undef;
   bless ($self, $class);

   # Extending the KEYSDATABASE of PortGroup
   my $switchKeysDatabase = $self->GetKeysTable();
   my $refNewKeysDataBase = {%{$self->{keysdatabase}}, %$switchKeysDatabase};
   $self->{keysdatabase} = $refNewKeysDataBase;

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
   my $tuple       = $args{tuple};
   my $skipPostProcess   = $args{skipPostProcess};
   my $verificationStyle = $args{verificationStyle};
   my $persistData       = $args{persistData};

   # For ver2 we will call the ConfigureComponent from parent class first.
   my $result = $self->SUPER::ConfigureComponent('configHash' => $dupWorkload,
                                                 'testObject' => $testObject,
                                                 'tuple'      => $tuple,
					         'skipPostProcess'   => $skipPostProcess,
						 'verificationStyle' => $verificationStyle,
						 'persistData'      => $persistData,
                                                );

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
# ProcessNIOCTrafficSpec --
#     Method to process the NIOC configuration spec from test case
#
# Input:
#       testObject - An object, whose core api will be executed
#       keyName    - Name of the action key
#       keyValue - Reference to hash/spec that contains NIOC
#                    configuration details
# Results:
#     reference to array which contains argument required to
#     call ConfigureNIOCTraffic() method
#
# Side effects:
#     None
#
########################################################################

sub PreProcessNIOCTrafficSpec
{
   my $self         = shift;
   my ($testObject, $keyName, $keyValue, $paramValue) = @_;
   my %hash;
   foreach my $class (keys %$keyValue) {
      my $spec = $keyValue->{$class};
      my ($reservation, $shares, $limit) = split(/:/, $spec);
      $hash{$class}{reservation} = $reservation;
      $hash{$class}{shares} = $shares;
      $hash{$class}{limit} = $limit;
   }
   $hash{'niocversion'} = $paramValue->{'niocversion'};
   my @array;
   push (@array,\%hash);
   return \@array;
}


########################################################################
#
# PreProcessConfigureHost --
#     Method to process the host and vmnic addapter to add to vds
#
# Input:
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#     reference to array which contains argument required to
#     call ConfigureHosts() method
#
# Side effects:
#     None
#
########################################################################

sub PreProcessConfigureHost
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;

   my @array ;
   foreach my $parameter (@$paramList){
      if (defined $paramValue->{$parameter}) {
         push(@array, $paramValue->{$parameter});
      }
   }
   return \@array;
}


########################################################################
#
# PreProcessBackupRestore --
#     Method to process the host and vmnic addapter to add to vds
#
# Input:
#       paramValue  - Reference to hash where keys are the contents of
#                   'params' and values are the values that are assigned
#                   to these keys in config hash.
#       paramList   - order in which the arguments will be passed to core api
#
# Results:
#     reference to array which contains argument required to
#     call ConfigureHosts() method
#
# Side effects:
#     None
#
########################################################################

sub PreProcessBackupRestore
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValue, $paramList) = @_;

   my $pgObj = $paramValue->{portgroup};
   $paramValue->{portgroup} =  $pgObj->{pgName};

   my @array ;
   foreach my $parameter (@$paramList){
      if (defined $paramValue->{$parameter}) {
         push(@array, $paramValue->{$parameter});
      }
   }
   return \@array;
}


########################################################################
#
#  PreProcessLacp --
#       This method pushes lacp runtime parameters into a hash
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
#
# Results:
#      Return reference to array if array is filled with values
#      Return FAILURE incase array is empty.
#
# Side effetcs:
#       None
#
########################################################################

sub PreProcessLacp
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @array;

   my $refHostArray = $paramValues->{host};
   my $hostObj = $refHostArray->[0];
   my $newHash = {
      'host' => $hostObj->{hostIP},
      'operation' => $paramValues->{lacp},
      'mode' => $paramValues->{lacpmode},
   };

   push(@array, %$newHash);
   return \@array;
}


########################################################################
#
# PreProcessAddFlow --
#     Method to pre-process  arguments need to add flows
#
# Input:
#     testObject  - An object, whose core api will be executed
#     keyName     - Name of the action key
#     keyValue    - Value assigned to action key in config hash
#     paramValue  - Reference to hash where keys are the contents of
#                    'params' and values are the values that are assigned
#                    to these keys in config hash.
#     paramList   - order in which the arguments will be passed to core api
#
# Results:
#     Reference to an array
#
# Side effects:
#     None
#
########################################################################

sub PreProcessAddFlow
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @array;
   my @finalArgs;
   foreach my $flow (@$keyValue) {
      my $destination = $self->GetOneObjectFromOneTuple($flow->{destination});
      my $gateway = $self->GetOneObjectFromOneTuple($flow->{gateway});
      my $spec = {
         'protocol' => $flow->{protocol},
         'destination' => $destination,
         'gateway' => $gateway,
      };
      push(@array, $spec);
   }
   push(@finalArgs, \@array);
   return \@finalArgs;
}


########################################################################
#
# PreProcessProxyPort --
#     Method to pre-process  arguments need to change Proxyport
#
# Input:
#     testObject  - An object, whose core api will be executed
#     keyName     - Name of the action key
#     keyValue    - Value assigned to action key in config hash
#     paramValue  - Reference to hash where keys are the contents of
#                    'params' and values are the values that are assigned
#                    to these keys in config hash.
#     paramList   - order in which the arguments will be passed to core api
#
# Results:
#     Reference to an array
#
# Side effects:
#     None
#
########################################################################

sub PreProcessProxyPort
{
   my $self       = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;
   my @arguments;

   my $refHostArray = $paramValues->{host};
   my $hostObj = $refHostArray->[0];
   my $specHash = {
     'host' => $hostObj->{hostIP},
     'proxyports' => $paramValues->{'proxyports'},
   };
   push (@arguments,%$specHash);
   return \@arguments;
}


########################################################################
#
# PreProcessVerifyMacEntry--
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
#     method PreProcessVerifyMacEntry.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVerifyMacEntry
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData;
      if ($parameter eq $keyName) {
         my $userProcessedData = $self->ProcessParameters($paramValues->{$keyName});
         foreach my $entry (@$userProcessedData) {
            my $netAdapterMacObj = $entry->{mac};
            my $netAdapterMac = $netAdapterMacObj->{macAddress};
            $entry->{mac} = uc($netAdapterMac);
         }

      $vdLogger->Info("Data after processing user input " . Dumper($userProcessedData));
      $userData = $userProcessedData;
      } else {
         $userData = $paramValues->{$parameter};
      }

     push(@array, $userData);
   }

   return \@array;
}


########################################################################
#
# PreProcessVerifyConnectionTable --
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
#     method PreProcessVerifyArpEntryOnController.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVerifyConnectionTable
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData;
      if ($parameter eq $keyName) {
         my $userProcessedData = $self->ProcessParameters($paramValues->{$keyName});
         foreach my $entry (@$userProcessedData) {
            my $hostObj  = $entry->{hostip};
            my $hostIP = $hostObj->{hostIP};
            $entry->{hostip} = $hostIP;
         }
         $vdLogger->Debug("Data after processing user input " . Dumper($userProcessedData));
         $userData = $userProcessedData;
      } else {
         $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }
   return \@array;
}


########################################################################
#
# PreProcessVerifyVtepTable --
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
#     method PreProcessVerifyArpEntryOnController.
#
# Side effects:
#     None
#
########################################################################

sub PreProcessVerifyVtepTable
{
   my $self = shift;
   my ($testObject, $keyName, $keyValue, $paramValues, $paramList) = @_;

   my @array;
   foreach my $parameter (@$paramList) {
      my $userData;
      my @handledData;
      if ($parameter eq $keyName) {
         my $userProcessedData = $self->ProcessParameters($paramValues->{$keyName});
         foreach my $entry (@$userProcessedData) {
            if (exists $entry->{cluster}) {
                # if entry exist cluster key, means passed object is a host obj
                # "VerifyVtepTableOnHost[?]contain_once":
                #    - vtepip:  "esx.[4]"
                #      cluster: "vc.[1].datacenter.[1].cluster.[2]"
                #    - vtepip:  "esx.[5]"
                #      cluster: "vc.[1].datacenter.[1].cluster.[3]"
                my $hostObj  = $entry->{vtepip};
                my $hostId = $hostObj->GetMORId();
                my $clusterObj = $entry->{cluster};
                my $clusterId  = $clusterObj->GetClusterMORId();
                my $vteplist = $testObject->get_vteps($hostId, $clusterId);
                foreach my $vtep (@$vteplist) {
                    push (@handledData, {"vtepip" => $vtep});
                }
            }  else {
                # if not exist cluster key, means passed object is a vnic object
                # we can get ip address from vnic object directly
                #  "VerifyVtepTableOnHost[?]contain_once":
                #      - vtepip:  "torgateway.[1].vnic.[1]"
                #      - vtepip:  "torgateway.[1].vnic.[2]"
                my $vnicObj  = $entry->{vtepip};
                my $vtep = $vnicObj->GetIPv4();
                push (@handledData, {"vtepip" => $vtep});
            }
         }
         $vdLogger->Debug("Data after processing user input " . Dumper(@handledData));
         $userData = \@handledData;
      } else {
         $userData = $paramValues->{$parameter};
      }
      push(@array, $userData);
   }
   return \@array;
}
1;
