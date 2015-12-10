########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::RootWorkload;

#
# This package/module is used to run workload that involves initializing
# testbed inventory items like vc, host, vm etc.
#

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              ConfigureLogger
                                              CallMethodWithKWArgs);
use Inline::Python qw(py_call_function);

# TODO: Re-organize testbed init() code and move the APIs to
# core API layer and make use of keysdatabase for clean implementation


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::RootWorkload
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
      'targetkey'    => "testnode",
      'managementkeys' => ['type', 'iterations','testnode','expectedresult','sleepbetweencombos'],
      'componentIndex' => undef
      };

    bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}


########################################################################
#
# CreateInventoryPreProcess --
#      This method will process the workload hash  of type 'Root'
#      and initialize root level inventory items
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if workload is executed successfully,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CreateInventoryPreProcess
{
   # Creating Inventory from workload required testbed as Init is in testbed
   # Core API does not have access to testbed
   # so we call Init on testbed in this Preprocess itself and just
   # pass the return to the core API.
   my $self = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};

   # Create a duplicate copy of the given workload hash
   my %temp = %{$workload};
   my $dupWorkload = \%temp;

   # Convert keys in the hash $workload to lower case before any processing
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);
   my $testbedSpec = {
      'testbedSpec'  => $dupWorkload,
   };
   delete $dupWorkload->{testnode};
   delete $dupWorkload->{type};
   foreach my $component (keys %$dupWorkload) {
      if ($component eq 'nsxmanager' || $component eq 'nsxedge' || $component eq 'nsxcontroller') {
         my $dupWorkload->{$component} = VDNetLib::Common::Utilities::ExpandTuplesInSpec(
                                                                      $dupWorkload->{$component});
         if ($dupWorkload->{$component} eq FAILURE) {
            $vdLogger->Error("Failed to expand tuples for component '$component'");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         my $indexHash = $dupWorkload->{$component};
         foreach my $index (keys %$indexHash) {
            my ($ip, $instanceName, $build) =
               $self->DeployNSXComponent($component, $index,
                                         $dupWorkload->{$component}->{$index});
            if ($ip eq FAILURE) {
               $vdLogger->Error("DeployNSXComponent for $component and index ".
                                "$index failed and did not return a valid ip");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            $vdLogger->Info("component: $component, build: $build, instance: $instanceName, ip: $ip");
            ${$dupWorkload}{$component}{$index}{'ip'} = $ip;
            ${$dupWorkload}{$component}{$index}{'vmInstance'} = $instanceName;
            ${$dupWorkload}{$component}{$index}{'build'} = $build;
         }
      }
   }
   #
   # Perl threads not working yet with nested workload invocation
   # i.e WorkloadsManager->RootWorkload->Testbedv2->Threads
   # Need to revisit when workloads are made mult-threaded
   #
   my $threadsOption = $ENV{VDNET_USE_THREADS};
   $ENV{VDNET_USE_THREADS} = 0;
   $dupWorkload = VDNetLib::Common::Utilities::ProcessSpec($dupWorkload);
   my $result = $testbed->Init($dupWorkload);
   # set VDNET_USE_THREADS back to original value
   $ENV{VDNET_USE_THREADS} = $threadsOption;
   if (FAILURE eq $result) {
      $vdLogger->Error("Root workload failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   } else {
      return [SUCCESS];
   }
}

########################################################################
#
# DeployNSXComponent --
#      This method will deploy nsx components provided in
#      workload hash  of type 'Root'
#
# Input:
#      A named parameter hash with the following keys:
#      component      - name of component to be deployed;
#                       example: <nsxmanager/nsxcontroller/nsxedge>
#      index          - index of component to be deployed
#      deploymentSpec - reference to component deployment parameters
#                        hash
#
# Results:
#     "SUCCESS", if deployment is successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub DeployNSXComponent
{
   my $self = shift;
   my $component = shift;
   my $index = shift;
   my $deploymentSpec = shift;
   my $testbed = $self->{testbed};
   my ($hostObj, $memory, $cpus, $esxUser, $esxPassword);
   foreach my $key (keys %$deploymentSpec) {
      if ($key eq 'esx') {
         my $result = $testbed->GetComponentObject(${$deploymentSpec}{$key});
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to initialize VM.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $hostObj = pop(@$result);
         if (not defined $hostObj) {
            $vdLogger->Error("Failed to access host");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      } elsif($key eq 'memory' and exists ${$deploymentSpec}{$key}{'size'}) {
         $memory = ${$deploymentSpec}{$key}{'size'};
      } elsif($key eq 'cpus' and exists ${$deploymentSpec}{$key}{'cores'}) {
         $cpus = ${$deploymentSpec}{$key}{'cores'};
      }
   }
   my $build = GetBuild(${$deploymentSpec}{'build'});
   my $instanceName = GetInstanceName($component, $build, $index);
   my $searchPattern;
   if ($component eq 'nsxmanager') {
      $searchPattern = "nsx-manager-.*.ovf";
   } elsif($component eq 'nsxedge') {
      $searchPattern = "NSXEdge-" . ${$deploymentSpec}{'edgetype'} . ".*.ovf";
   } elsif($component eq 'nsxcontroller') {
      $searchPattern = "nsx-controller-.*.ovf";
   }
   my $ovfUrl = GetBuildDeliverableUrl($build, $searchPattern);
   my @networkList = GetNetworkListForNSXComponent($component, $deploymentSpec);
   my %propertyHash = GetPropertyHashForNSXComponent($component);
   eval {
      LoadInlinePythonModule('vsphere_utilities');
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while loading " .
                       "inline component of vsphere_utilities:\n". $@);
      return FAILURE;
   }
   my $result;
   eval {
      $result = py_call_function("vsphere_utilities",
                                 "deploy_standalone_vm",
                                 $instanceName,
                                 $component,
                                 [@networkList],
                                 ${$deploymentSpec}{'datastore'},
                                 $ovfUrl,
                                 $hostObj->{hostIP},
                                 $esxUser,
                                 $esxPassword,
                                 {%propertyHash},
                                 $memory,
                                 $cpus);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while deploying nested vm for " .
                       "component $component:\n". $@);
      return FAILURE;
   }
   return ($result, $instanceName, $build);
}

########################################################################
#
# GetNetworkListForNSXComponent --
#      This method will return the list of networks for given
#      nsx component.
#
# Input:
#      A named parameter hash with the following keys:
#      component - name of component to be deployed
#      options   - reference to network parameters hash
#
# Results:
#      list object with network parameters.
#
# Side effects:
#     None
#
########################################################################

sub GetNetworkListForNSXComponent
{
   my $component = shift;
   my $options = shift;
   my @networkList = ();
   my %NETWORK_NAME_HASH = ('nsxmanager'=> ['Network 1'],
                            'nsxedge'=> ['management', 'uplink', 'internal']);
   my %NETWORK_OPT_VALUE_HASH = ('nsxmanager'=> ['network'],
                                 'nsxedge'=> ['management_network',
                                              'uplink_network',
                                              'internal_network']);
   my @SPECIAL_COMPONENTS = ('nsxmanager', 'nsxedge');
   if ($component ~~ @SPECIAL_COMPONENTS) {
      my @networkNameArray = @{$NETWORK_NAME_HASH{$component}};
      my @networkOptValueArray = @{$NETWORK_OPT_VALUE_HASH{$component}};
      for my $i (0 .. (scalar @networkNameArray - 1)) {
         push @networkList, "--net:$networkNameArray[$i]=${$options}{$networkOptValueArray[$i]}";
      }
   } else {
      push @networkList, "--network=${$options}{'network'}";
   }
   return @networkList;
}

########################################################################
#
# GetPropertyHashForNSXComponent --
#      This method will return the hash containing the properties for
#      given nsx component.
#
# Input:
#      A named parameter hash with the following keys:
#      component - name of component to be deployed
#
# Results:
#      hash containing the properties for given nsx component.
#
# Side effects:
#     None
#
########################################################################

sub GetPropertyHashForNSXComponent
{
   my $component = shift;
   my %propertyHash;
   if ($component eq 'nsxmanager') {
      %propertyHash = GetPropertyHashForNSXManager();
   } elsif($component eq 'nsxedge') {
      %propertyHash = GetPropertyHashForNSXEdge();
   }
   return %propertyHash;
}

########################################################################
#
# GetPropertyHashForNSXManager --
#      This method will return the hash containing the properties for
#      nsx manager.
#
# Input:
#      None
#
# Results:
#      hash containing the properties for nsx manager.
#
# Side effects:
#     None
#
########################################################################

sub GetPropertyHashForNSXManager
{
   my %propertyHash;
   $propertyHash{'nsx_passwd_0'} = 'default';
   $propertyHash{'nsx_cli_passwd_0'} = 'default';
   $propertyHash{'nsx_hostname'} = 'vdnet-nsxmanager';
   $propertyHash{'nsx_isSSHEnabled'} = 'True';
   return %propertyHash;
}

########################################################################
#
# GetPropertyHashForNSXEdge --
#      This method will return the hash containing the properties for
#      nsx edge.
#
# Input:
#      None
#
# Results:
#      hash containing the properties for nsx edge.
#
# Side effects:
#     None
#
########################################################################

sub GetPropertyHashForNSXEdge
{
    my %propertyHash;
    $propertyHash{'root_passwd'} = 'C@shc0w12345';
    $propertyHash{'admin_passwd'} = 'C@shc0w12345';
    $propertyHash{'enable_passwd'} = 'C@shc0w12345';
    #
    # For now hard-coding the nsx manager properties as they will be removed from
    # edge ovf property mappings in the future.
    #
    $propertyHash{'manager_ip_port'} = '1.1.1.1';
    $propertyHash{'manager_thumbprint'} = '11:22:3D:3C:11:22:3D:3C:11:22:3D:3C:11:22:3D:3C:11:22:3D:3C';
    $propertyHash{'api_user'} = 'admin';
    $propertyHash{'api_passwd'} = 'default';
    $propertyHash{'cli_config'} = '{"mgmtInterface": {"ipAddressDhcpEnabled": "true", "status": "up", "name": "vNic_0", "description": "managemet interface"}, "ssh": {"enabled": "true"}}';
   return %propertyHash;
}

########################################################################
#
# GetInstanceName --
#      This method will return the instance name for given nsx component.
#
# Input:
#      A named parameter hash with the following keys:
#      component - name of component to be deployed
#      build     - build number for given component
#      index     - index of nsx component to be deployed
#
# Results:
#      instance name for given nsx component.
#
# Side effects:
#     None
#
########################################################################

sub GetInstanceName
{
   my $component = shift;
   my $build = shift;
   my $index = shift;
   my $user = `echo \$USER`;
   chomp($user);
   return $user . '-vdnet-' . $component . '-' . $build . '-' . $index;
}

########################################################################
#
# GetBuildDeliverableUrl --
#      This method will return ovf url for given nsx component.
#
# Input:
#      A named parameter hash with the following keys:
#      component     - name of component to be deployed
#      searchPattern - Pattern to be searched to get build url
#
# Results:
#      ovf url for given nsx component.
#
# Side effects:
#     None
#
########################################################################

sub GetBuildDeliverableUrl {
   my $build = shift;
   my $searchPattern = shift;
   eval {
      LoadInlinePythonModule('build_utilities');
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while loading " .
                       "inline component of build_utilities:\n". $@);
      return FAILURE;
   }
   my $result;
   eval {
      $result = py_call_function("build_utilities",
                                 "get_build_deliverable_url",
                                 $build,
                                 $searchPattern);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while getting build deliverable " .
                       "url for build $build:\n". $@);
      return FAILURE;
   }
   return $result;
}

########################################################################
#
# GetBuild --
#      This method will return the build number for given build tuple.
#
# Input:
#      A named parameter hash with the following keys:
#      buildTuple - build tuple for which build is to be found.
#
# Results:
#      ovf url for given nsx component.
#
# Side effects:
#     None
#
########################################################################

sub GetBuild
{
   my $buildTuple = shift;
   if (index($buildTuple, ':')) {
      eval {
         LoadInlinePythonModule('build_utilities');
      };
      if ($@) {
         $vdLogger->Error("Exception thrown while creating " .
                          "inline component of build_utilities:\n". $@);
         return FAILURE;
      }
      eval {
         $buildTuple = py_call_function("build_utilities",
                                        "get_build_from_tuple",
                                        $buildTuple);
      };
      if ($@) {
         $vdLogger->Error("Exception thrown while getting build for " .
                          "tuple $buildTuple:\n". $@);
         return FAILURE;
      }
   }
   return $buildTuple;
}

########################################################################
#
# DeleteVMInventoryPreProcess
#      This method will process the workload hash  of type 'Root'
#      and delete root level VM inventory items
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if workload is executed successfully,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub DeleteVMInventoryPreProcess
{
   my $self = shift;
   my $workload = $self->{workload};
   my $testbed = $self->{testbed};

   # Create a duplicate copy of the given workload hash
   my %temp = %{$workload};
   my $dupWorkload = \%temp;

   # Convert keys in the hash $workload to lower case before any processing
   %$dupWorkload = (map { lc $_ => $dupWorkload->{$_}} keys %$dupWorkload);
   my $testbedSpec = {
      'testbedSpec'  => $dupWorkload,
   };
   delete $dupWorkload->{testnode};
   delete $dupWorkload->{type};
   #
   # Perl threads not working yet with nested workload invocation
   # i.e WorkloadsManager->RootWorkload->Testbedv2->Threads
   # Need to revisit when workloads are made mult-threaded
   #
   $ENV{VDNET_USE_THREADS} = 0;
   $dupWorkload = VDNetLib::Common::Utilities::ProcessSpec($dupWorkload);
   if (FAILURE eq $testbed->CleanupVM($dupWorkload->{deletevm})) {
      $vdLogger->Error("CleanupVM failed for RootWorkload");
   }
   if (FAILURE eq $testbed->CleanupTestbedVMs($dupWorkload->{deletevm})) {
      $vdLogger->Error("Root workload failed calling CleanupTestbedVMs");
      VDSetLastError(VDGetLastError());
      return ["FAILURE"];
   } else {
      return ["SUCCESS"]
   }
}

1;

