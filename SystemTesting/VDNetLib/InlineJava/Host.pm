###############################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::Host;

#
# This class captures all common methods to configure or get information
# from a Host. This package mainly uses VDNetLib::InlineJava::VDNetInterface
# class to interact with Host.
#
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Inline::Java qw(cast coerce);

#
# Importing only vdLogger for now and nothing else to keep this package
# re-usable for frameworks/tools other than VDNet
#
use VDNetLib::Common::GlobalConfig qw ($vdLogger);

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler NewDataHandler);
use VDNetLib::InlineJava::Host::VmknicManager;
use constant SSLPORT => 443;
use constant TRUE  => 1;
use constant FALSE => 0;
use constant VNIC_SPEC => 'com.vmware.vc.HostVirtualNicSpec';
use constant IPV6_CONFIGURATION => 'com.vmware.vc.HostIpConfigIpV6AddressConfiguration';
use constant IPV6_ADDRESS => 'com.vmware.vc.HostIpConfigIpV6Address';
use constant IPCONFIG => 'com.vmware.vc.HostIpConfig';
use constant OPAQUE_NETWORK_WAIT_TIME => 30;
use constant SLEEP_BETWEEN_RETRIES => 5;

########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::Host
#
# Input:
#     Named value parameters with following keys:
#     host        : Name of the ESX host (Required)
#     user        : User name to login to esx host.
#     password    : Password to login to esx host.
#
# Results:
#     An object of VDNetLib::InlineJava::Host class if successful;
#     0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my %options = @_;

   my $self;

   $self->{'anchor'}    = $options{'anchor'};
   $self->{'host'}      = $options{'host'};
   $self->{'user'}      = $options{'user'} || "root";
   $self->{'password'}  = $options{'password'};

   $self-> {'password'} = (defined $self->{'password'}) ? $self->{'password'} :
                          'ca\$hc0w';
   eval {
      if (not defined $self->{'anchor'}) {
         $self->{anchor} = CreateInlineObject("com.vmware.vcqa.ConnectAnchor",
                                              $self->{host}, SSLPORT);
         $self->{sessionMgr} = CreateInlineObject("com.vmware.vcqa.vim.SessionManager",
         $self->{'anchor'});
         $self->{sessionMgr}->login($self->{anchor}, $self->{'user'},
                                    $self->{'password'});
      }
      if (not defined $self->{'hostSystem'}) {
         $self->{'hostSystem'} = CreateInlineObject("com.vmware.vcqa.vim.HostSystem",
                                               $self->{'anchor'});
      }

      if (not defined $self->{'hostMOR'}) {

         # Use com.vmware.vcqa.vim.ServiceInstance
         # object to decide if the connection anchor
         # is vc based or host based. If it is host
         # based then use getStandaloneHost() to
         # get the host mor else use getHost().
         my $serviceInstanceObj =
            CreateInlineObject("com.vmware.vcqa.vim.ServiceInstance", $self->{'anchor'});
         if ($serviceInstanceObj->isHostAgent()) {
            $self->{'hostMOR'} = $self->{hostSystem}->getStandaloneHost();
         } else {
            $self->{'hostMOR'} = $self->{hostSystem}->getHost($self->{host});
         }
      }
      if (not defined $self->{'networkSystem'}) {
         $self->{networkSystem} = CreateInlineObject("com.vmware.vcqa.vim.host.NetworkSystem",
                                               $self->{'anchor'});
      }
      if (not defined $self->{'networkMOR'}) {
        $self->{networkMOR} = $self->{networkSystem}->getNetworkSystem($self->{hostMOR});
      }
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while creating " .
                       "VDNetLib::InlineJava::Host object");
      return FALSE;
   }

   bless($self, $class);
   return $self;
}


########################################################################
#
# RefreshNetwork--
#     This function refreshes the network configuration on the host.
#
# Input:
#    None.
#
# Results:
#     Returns TRUE if refresh network configuration was successfull,
#     returns FALSE if refresh network configuration fails.
#
# Side effects:
#     None
#
########################################################################

sub RefreshNetwork
{
   my $self = shift;
   my $networkSystem = $self->{networkSystem};
   my $networkMOR = $self->{networkMOR};

   eval {
      $networkSystem->refresh($networkMOR);
   };
   if ($@) {
      $vdLogger->Error("Failed to refresh the networking configuration");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# AddVMKNIC--
#     This function adds vmkernel nic.
#
# Input:
#    None.
#
# Results:
#     Returns TRUE if adding vmknic is succesfull,
#     returns FALSE if adding vmknic fails.
#
# Side effects:
#     None
#
########################################################################

sub AddVMKNIC
{
   my $self = shift;
   my %args = @_;
   my $inlinePortgroup = $args{'portgroup'};
   my $ip = $args{'ip'};
   my $mac = $args{'macaddress'};
   my $netmask = $args{'netmask'};
   my $prefixLen = $args{'prefixLen'};
   my $mtu = $args{'mtu'};
   my $netstack = $args{'netstack'};
   my $networkSystem = $self->{networkSystem};
   my $networkMOR = $self->{networkMOR};
   my $hostMor = $self->{hostMOR};
   my $vmkservicesref = $args{'vmkservices'};
   my ($portgroup, $portConnection, $nicSpec, $hostNetworkInfo, $hostVirtualNic);
   my @beforeAddArray = ();
   my @afterAddArray = ();
   my $deviceId;
   my $result;

   eval {
      # Before adding a new vmknic we find out existing vmkIDs so that
      # we can do a diff before and after adding and find the newly
      # added vmknic's deviceId
      $hostNetworkInfo = $networkSystem->getNetworkInfo($networkMOR);
      $hostVirtualNic = $hostNetworkInfo->getVnic();
      for (my $i = 0; $i < $hostVirtualNic->size() ; $i++) {
         push(@beforeAddArray,$hostVirtualNic->get($i)->getDevice());
      }

      # create vnic spec.
      $nicSpec = CreateInlineObject(VNIC_SPEC);
      if (defined $netstack) {
         $nicSpec->setNetStackInstanceKey($netstack);
      }
      my $ipConfig = CreateInlineObject(IPCONFIG);
      $nicSpec->setIp($ipConfig);
      if ($ip eq "dhcp") {
         $nicSpec->getIp()->setDhcp("true");
      } elsif ($ip eq "dhcpv6") {
         my $ipv6Config = CreateInlineObject(IPV6_CONFIGURATION);
         $ipv6Config->setDhcpV6Enabled("true");
         $nicSpec->getIp()->setIpV6Config($ipv6Config);
      } elsif ($ip eq "autoconf") {
         my $ipv6Config = CreateInlineObject(IPV6_CONFIGURATION);
         $ipv6Config->setAutoConfigurationEnabled("true");
         $nicSpec->getIp()->setIpV6Config($ipv6Config);
      } elsif ($ip =~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/i) {
         $nicSpec->getIp()->setIpAddress($ip);
         $nicSpec->getIp()->setSubnetMask($netmask);
      } else {
         my $ipv6Address = CreateInlineObject(IPV6_ADDRESS);
         $ipv6Address->setIpAddress($ip);
         $ipv6Address->setPrefixLength($prefixLen);
         my $ipv6Config = CreateInlineObject(IPV6_CONFIGURATION);
         $ipv6Config->getIpV6Address()->add($ipv6Address);
         $nicSpec->getIp()->setIpV6Config($ipv6Config);
      }
      if (defined $mtu) {
         $nicSpec->setMtu($mtu);
      }
      if (defined $mac) {
         $nicSpec->setMac($mac);
      }
      if ($inlinePortgroup->{type} eq "standard") {
         $portgroup = $inlinePortgroup->{name};
         $nicSpec->setPortgroup($portgroup);
      } elsif ($inlinePortgroup->{type} eq "vwire") {
         $portConnection = $inlinePortgroup->GetPortConnection(inlineJavaHostObj => $self);
         $nicSpec->setDistributedVirtualPort($portConnection);
         $portgroup = "";
      } elsif ($inlinePortgroup->{type} eq "logicalSwitch") {
         my $opaqueNetworkInfo = $self->GetOpaqueNetworkInfoForPgrp('inlinePortgroup' => $inlinePortgroup);
         if ($opaqueNetworkInfo == FALSE) {
            $vdLogger->Error("Failed to get opqueNetwork information for $inlinePortgroup->{name} .".
                             "Cannot connect the vmknic to opqueNetwork.");
            $result = FALSE;
         } else {
            my $opaqueNetworkSpec = CreateInlineObject("com.vmware.vc.HostVirtualNicOpaqueNetworkSpec");
            $opaqueNetworkSpec->setOpaqueNetworkId($opaqueNetworkInfo->{opaqueNetworkId});
            $opaqueNetworkSpec->setOpaqueNetworkType($opaqueNetworkInfo->{opaqueNetworkType});
            $nicSpec->setOpaqueNetwork($opaqueNetworkSpec);
            $portgroup = "";
         }
      } else {
         $portConnection = $inlinePortgroup->GetPortConnection();
         $nicSpec->setDistributedVirtualPort($portConnection);
         $portgroup = "";
      }
      $deviceId = $networkSystem->addVirtualNic($networkMOR, $portgroup, $nicSpec);
      $self->RefreshNetwork();
      if (defined $vmkservicesref){
           $result = $self->ConfigureVmkServices(vmkservicesref => $vmkservicesref,
                                                 hostMor        => $hostMor,
                                                 deviceid       => $deviceId,
                                                );
       }
   };

   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   } else {
     return $deviceId;
   }
}


########################################################################
#
# RemoveVMKNIC--
#     This function removes vmkernel nic.
#
# Input:
#    vmknic - string containing the vmknic interface name.
#
# Results:
#     Returns TRUE if removing vmknic is succesfull,
#     returns FALSE if removing vmknic fails.
#
# Side effects:
#     None
#
########################################################################

sub RemoveVMKNIC
{
   my $self = shift;
   my %args = @_;
   my $vmknic = $args{vmknic};
   my $networkSystem = $self->{networkSystem};
   my $networkMOR = $self->{networkMOR};

   eval {
      $networkSystem->removeVirtualNic($networkMOR, $vmknic);
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   } else {
     return TRUE;
   }
}


########################################################################
#
# GetVmknicHash--
#     This function gives out all info of vmknic from spec
#
# Input:
#     spec    : vmknic spec
#     ipSpec  : vmknic ip spec
#     ipv6Spec: vmknic ipv6 spec
#
# Results:
#     Returns Hash
#
# Side effects:
#     None
#
########################################################################

sub GetVmknicHash
{
   my $self = shift;
   my $spec = shift;
   my $ipSpec = shift;
   my $ipv6Spec = shift;

   my $vmknicHash = {};
   $vmknicHash->{mac} = $spec->getMac();
   $vmknicHash->{mtu} = $spec->getMtu();
   $vmknicHash->{netstackname} = $spec->getNetStackInstanceKey();
   $vmknicHash->{portgroupname} = $spec->getPortgroup();
   $vmknicHash->{tsoenabled} = $spec->isTsoEnabled();

   $vmknicHash->{ipv4} = $ipSpec->getIpAddress();
   $vmknicHash->{netmask} = $ipSpec->getSubnetMask();
   $vmknicHash->{dhcpenabled} = $ipSpec->isDhcp();

   if (defined $ipv6Spec) {
      $vmknicHash->{dhcpv6enabled} = $ipv6Spec->isDhcpV6Enabled();
      $vmknicHash->{autoconfigurationenabled} = $ipv6Spec->isAutoConfigurationEnabled();

      my $ipv6AddressArrayList = $ipv6Spec->getIpV6Address();
      # Just getting the first Ipv6 address as of now
      # For multiple we need to loop through the ArrayList
      $vmknicHash->{ipv6} = $ipv6AddressArrayList->get(0)->getIpAddress();
      $vmknicHash->{prefixlength} = $ipv6AddressArrayList->get(0)->getPrefixLength();
      $vmknicHash->{origin} = $ipv6AddressArrayList->get(0)->getOrigin();
   }

   return $vmknicHash;
}

########################################################################
#
# GetHostVirtualNic--
#     This function gives out all info of vmknic
#
# Input:
#    deviceId - string containing the vmknic interface name. E.g. vmk1
#
# Results:
#     Returns Hash if operation is succesfull,
#     returns FALSE if removing vmknic fails.
#
# Side effects:
#     None
#
########################################################################

sub GetHostVirtualNic
{
   my $self = shift;
   my %args = @_;
   my $vmknic = $args{vmknic} || $args{deviceId};
   my $networkSystem = $self->{networkSystem};
   my $networkMOR = $self->{networkMOR};
   my ($hostNetworkInfo,  $hostVirtualNicArrayList,
       $opaqueHostVirtualNicArrayList, $hostOpaqueSwitchList);
   my $vmknicHash = {};
   my $vtepHash = {};

   eval {

      $hostNetworkInfo = $networkSystem->getNetworkInfo($networkMOR);

      if ($hostNetworkInfo->can('getOpaqueSwitch')) {

         $hostOpaqueSwitchList = $hostNetworkInfo->getOpaqueSwitch();
         my $size = $hostOpaqueSwitchList->size();
         $vdLogger->Debug("Number of opaque switches found: $size");

         for (my $i = 0; $i < $hostOpaqueSwitchList->size(); $i++) {

            my $switch = $hostOpaqueSwitchList->get($i);
            my $key = $switch->getKey();
            my $name = $switch->getName();

            if ($switch->can('getVtep')) {

               my $vteps = $hostOpaqueSwitchList->get($i)->getVtep();
               my $numVteps = $vteps->size();
               $vdLogger->Debug("Number of vteps found: $numVteps");

               for (my $j = 0; $j < $vteps->size(); $j++) {

                  my $device = $vteps->get($j)->getDevice();
                  if ($device !~ /^$vmknic$/) {
                     next;
                  }
                  $vtepHash->{device} = $device;

                  my $spec = $vteps->get($j)->getSpec();
                  my $ipSpec = $spec->getIp();
                  my $ipv6Spec = $ipSpec->getIpV6Config();

                  $vtepHash = $self->GetVmknicHash($spec, $ipSpec, $ipv6Spec);
                  $vtepHash->{switchName} = $name;
               }
            } else {
               $vdLogger->Error("The version of VC.jar being used is missing the".
                                " getVtep() method. This prevents vteps from being".
                                " recognized as vmknics. Please update the".
                                " version of the java testware version to ensure".
                                " that vteps can be recognized as vmknics. Use".
                                " staf version 2060951 or higher.");
            }
         }
      } else {
         $vdLogger->Error("The version of VC.jar being used is missing the".
                          " getOpaqueSwitch() method. This prevents vteps".
                          " from being recognized as vmknics. Please update".
                          " the version of the java testware version to".
                          " ensure that vteps can be recognized as vmknics.".
                          " Use staf version 2060951 or higher.");
      }

      $hostVirtualNicArrayList = $hostNetworkInfo->getVnic();
      for (my $i = 0; $i < $hostVirtualNicArrayList->size(); $i++) {

         if (keys %{$vtepHash}) {
            last;
         }

         my $device = $hostVirtualNicArrayList->get($i)->getDevice();
         if ($device !~ /^$vmknic$/) {
            next;
         }
         $vmknicHash->{device} = $device;

         my $spec = $hostVirtualNicArrayList->get($i)->getSpec();
         my $ipSpec = $spec->getIp();
         my $ipv6Spec = $ipSpec->getIpV6Config();
         $vmknicHash = $self->GetVmknicHash($spec, $ipSpec, $ipv6Spec);
      }
   };

   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   } else {
     if (keys %{$vtepHash}) {
        return $vtepHash;
     }
     return $vmknicHash;
   }
}


########################################################################
#
# DestroyVMs --
#     Method to destroy all VMs matching the given pattern in name.
#     If matchingName pattern is not given, then all VMs will be
#     destroyed.
#
# Input:
#     matchingNames  : pattern/string that should be matched
#
# Results:
#     boolean, TRUE (1) on success, FALSE (0) on failure;
#
# Side effects:
#     All the VMs on the host will be deleted
#
########################################################################

sub DestroyVMs
{
   my $self          = shift;
   my $matchingNames = shift;

   eval {
      my $hostVector = CreateInlineObject("java.util.Vector");
      $hostVector->add($self->{'hostMOR'});
      my $vmList = $self->{'hostSystem'}->getVMs($hostVector, undef);

      my $vmObj = CreateInlineObject("com.vmware.vcqa.vim.VirtualMachine",
                                     $self->{'anchor'});
      my $size = (defined $vmList) ? $vmList->size() : 0;
      for (my $i = 0; $i < $size; $i++) {
         my $vmMOR = $vmList->get($i);
         if (defined $matchingNames) {
            if ($vmObj->getVMName($vmMOR) !~ /$matchingNames/i) {
               next;
            }
            $vmObj->destroy($vmMOR, 1);
         }
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while destroying VMs ");
      return FALSE;
   }
   return TRUE;
};


########################################################################
#
# ConfigureOpaqueNetwork --
#     Method to configure Opaque network
#
# Input:
#     action         : "add"/"remove"
#     arrayOfSpecs   : reference to an array of hash with following
#                      keys:
#                      'type'    : network type, example 'nvp.network'
#                      'network' : network name
#
# Results:
#     1, if opaque networks are created successfully;
#     0, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureOpaqueNetwork
{
   my $self          = shift;
   my $action       = shift;
   my $arrayOfSpecs = shift;

   eval {
      my $networkSystem = $self->{networkSystem};
      my $cfgMgr = $self->{hostSystem}->getHostConfigManager($self->{'hostMOR'});

      my $networkMOR = $cfgMgr->getNetworkSystem();
      my $javaArray = CreateInlineObject("java.util.ArrayList");
      if ($action eq "remove") {
         $action = "set";
         $arrayOfSpecs = [];
      }
      foreach my $spec (@$arrayOfSpecs) {
         my $hostOpaqueNetwork  = CreateInlineObject("com.vmware.vc.HostOpaqueNetworkData");
         $hostOpaqueNetwork->setId($spec->{'network'});
         $hostOpaqueNetwork->setName($spec->{'network'});
         $hostOpaqueNetwork->setType($spec->{'type'});
         $hostOpaqueNetwork->setPortAttachMode("auto");
         $javaArray->add($hostOpaqueNetwork);
      }
      $self->{'anchor'}->getPortType()->performHostOpaqueNetworkDataOperation(
                                                                  $networkMOR,
                                                                  $action,
                                                                  $javaArray);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("$action action on opaque networks has thrown exception");
      return FALSE;
   }
   return TRUE;
}


#############################################################################
#
# GetMORId--
#     Method to get Host Managed Object ID (MOID) from Host's
#     display/registered name
#
# Input:
#
# Results:
#	HostMORId, of the Host found with the vmName
#	FALSE, if Host is not found or in case of any error
#
#
# Side effects:
#     None
#
########################################################################

sub GetMORId
{
   my $self   = shift;
   my $hostMORId;
   eval {
      $hostMORId = $self->{hostMOR}->getValue();
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the Host MOR Id");
      return FALSE;
   }
   return $hostMORId;
}


#############################################################################
#
# IsHostConnectedToVC--
#     Method to check if the host is connected to VC
#
# Input:
#     None
#
# Results:
#     1, if host is already connected
#     0, if host is not yet connected
#     undef, in case of exception or error
#
# Side effects:
#     None
#
#############################################################################

sub IsHostConnectedToVC
{
   my $self   = shift;
   my $result;

   eval {
      my $serviceInstanceObj =
         CreateInlineObject("com.vmware.vcqa.vim.ServiceInstance", $self->{'anchor'});
      if ($serviceInstanceObj->isHostAgent()) {
         $result = 0;
      } else {
         $result = 1;
      }
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while checking host connection to VC");
      return undef;
   }

   return $result;
}


#############################################################################
#
# IsStandaloneHost--
#     Method to check if the host is a standalone host.
#
# Input:
#     hostMor : Managed Object Reference of the host
#
# Results:
#     1, if host is standalone
#     0, if host is not standalone and in cluster environment
#     undef, in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub IsStandaloneHost
{
   my $self = shift;
   my $result;

   my $hostMor = $self->{hostMOR};
   eval {
      $result = $self->{'hostSystem'}->isStandaloneHost($hostMor);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while checking if host is standalone or
                      part of a cluster");
      return undef;
   }

   return $result;
}


#############################################################################
#
# GetDatastoreMORId--
#     Method to get datastore Managed Object ID (MOID) from datastore's
#     display name
#
# Input:
#     datastoreName : Datastore display name as in the inventory
#
# Results:
#	datastoreMORId, if SUCCESS
#	FALSE, if datstore is not found or in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetDatastoreMORId
{
   my $self          = shift;
   my $datastoreName = shift;
   my $datastoreMORId;

   eval {
      my $datastoreObj = CreateInlineObject("com.vmware.vcqa.vim.Datastore",
                                            $self->{'anchor'});
      my $datastoreMOR = $datastoreObj->getHostDataStoreByName($self->{hostMOR},
                                                           $datastoreName); 
      $datastoreMORId = $datastoreMOR->getValue();
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the datastore MOR Id " .
                       "of $datastoreName");
      return FALSE;
   }
   return $datastoreMORId;
}

#############################################################################
#
# GetDatastore--
#     Method to get datastore Managed Object (MOR) from datastore's
#     display name
#
# Input:
#     datastoreName : Datastore display name as in the inventory
#
# Results:
#	datastoreMOR, if SUCCESS
#	FALSE, if datstore is not found or in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetDatastore
{
   my $self          = shift;
   my $datastoreName = shift;
   my $datastoreMOR;

   eval {
      my $datastoreObj = CreateInlineObject("com.vmware.vcqa.vim.Datastore",
                                            $self->{'anchor'});
      $datastoreMOR = $datastoreObj->getHostDataStoreByName($self->{hostMOR},
                                                           $datastoreName);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the datastore MOR " .
                       "of $datastoreName");
      return FALSE;
   }
   return $datastoreMOR;
}


#######################################################################
#
# ReturnVMXPathIfVMExists --
#   for a given vm name, return the vmx path
#     e.g.: /vmfs/volumes/datastore1/vdtest-007/VM-1/rhel-53-srv-XYZ.vmx
#
# Input:
#   matchingNames: find the vmx path for the vm name.
#
# Results:
#     SUCCESS, retuns the constructed path of vmx;
#     FAILURE, in case of any error;
#
# Side effects:
#
########################################################################

sub ReturnVMXPathIfVMExists
{
   my $self          = shift;
   my $matchingNames = shift;
   my $vmxPath = "FAILURE";
   eval {
      my $hostVector = CreateInlineObject("java.util.Vector");
      $hostVector->add($self->{'hostMOR'});
      my $vmList = $self->{'hostSystem'}->getVMs($hostVector, undef);

      my $vmObj = CreateInlineObject("com.vmware.vcqa.vim.VirtualMachine",
                                     $self->{'anchor'});
      my $size = (defined $vmList) ? $vmList->size() : 0;
      for (my $i = 0; $i < $size; $i++) {
         my $vmMOR = $vmList->get($i);
         if (defined $matchingNames) {
            if ($vmObj->getVMName($vmMOR) =~ /$matchingNames/i) {
               my $path = $vmObj->getVMConfigAbsolutePath($vmMOR);
               my $vmNameRelative = $vmObj->getVmConfigRelativePath($vmMOR);
               my @directories = split ('/', $vmNameRelative);
               $vmxPath = $path . $directories[-1];
               last;
            }
         }
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while destroying VMs ");
      return FALSE;
   }
   return $vmxPath;
};


#############################################################################
#
# GetDatastoreType--
#     Method to get datastore type from datastore's display name
#
# Input:
#     datastoreName : Datastore display name as in the inventory
#     typeReference : A reference to an array to hold result
#
# Results:
#	TRUE, if find datastore type then put it into $typeReference->[0]
#	FALSE, if datstore is not found or in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetDatastoreType
{
   my $self          = shift;
   my $datastoreName = shift;
   my $typeReference = shift;

   # in case name is as  /vmfs/volumes/datastore01 (5)
   my @arry = split('/', $datastoreName);
   if ($#arry >= 3) {
      $datastoreName = $arry[3];
   }

   eval {
      my $datastoreObj = CreateInlineObject("com.vmware.vcqa.vim.Datastore",
                                            $self->{'anchor'});
      my $datastoreMOR = $datastoreObj->getDatastore($self->{hostMOR}, $datastoreName);
      if (not defined $datastoreMOR) {
         $vdLogger->Error("Failed to get datastore management object reference of " .
                       $datastoreName);
         return FALSE;
      }
      my $datastoreInfo =  $datastoreObj->getDatastoreInfo($datastoreMOR);
      if (defined  $datastoreInfo) {
         $vdLogger->Debug("Datastore $datastoreName is of the type " .
                    $datastoreInfo->getType());
         $typeReference->[0] = $datastoreInfo->getType();
         return TRUE;
      }
      $vdLogger->Error("Failed to get datastore information of " .
                       $datastoreName);
      return FALSE;
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the datastore type of $datastoreName");
      return FALSE;
   }
}


#############################################################################
#
# UpdateConfigOption --
#     Method to update the advanced config options on a specified host, this
#     method may be used as a replacement for esxcfg-advcfg.
#
# Input:
#     advoptsHash  : A hash containing key/value pairs.
#
# Results:
#	TRUE , if succeeds to update the config option
#	FALSE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub UpdateConfigOption
{
   my $self        = shift;
   my $advoptsHash = shift;
   my $option;
   my $value;

   eval {
      my $hostSystemHelperObj = CreateInlineObject(
             "com.vmware.vcqa.vim.HostSystemHelper",
             $self->{'anchor'},
             $self->{'hostSystem'});

      foreach my $key ( keys %{$advoptsHash} ) {
         $option = $key;
         $value = $advoptsHash->{$option};
         my $result = $hostSystemHelperObj->updateConfigOptions(
                                 $self->{hostMOR}, $option, $value);
         if (!$result) {
            $vdLogger->Error("Failed to update VMkernel advanced config " .
                               "option \"$option\" with value \"$value\"");
            return FALSE;
         }
         $vdLogger->Debug("Succeeded to update VMkernel advanced config " .
                               "option \"$option\" with value \"$value\"");
      }
      return TRUE;
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to update VMkernel advanced config option " .
                               "option \"$option\" with value \"$value\"");
      return FALSE;
   }
}


########################################################################
#
# ConfigureSRIOV --
#   configure SRIOV vmnic based on the passed in sriov configurations
#
# Input:
#   sriovConfigs: Reference to an array of SRIOV configurations.
#
# Results:
#     TRUE, if the configuration is successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureSRIOV
{
   my $self         = shift;
   my $sriovConfigs = shift;

   eval {
      my $pciPassthruSystem =
            CreateInlineObject("com.vmware.vcqa.vim.host.PciPassthruSystem",
                                                         $self->{'anchor'});
      my $pciMOR = $self->{'hostSystem'}->getHostConfigManager(
                                                     $self->{'hostMOR'})->
                                                     getPciPassthruSystem();
      foreach my $config (@$sriovConfigs) {
         my $sriovConfig = CreateInlineObject("com.vmware.vc.HostSriovConfig");
         $vdLogger->Debug("Configure SRIOV for vmnic $config->{'interface'}");
         $sriovConfig->setId($config->{'pci_id'});
         $sriovConfig->setSriovEnabled($config->{'sriov_enabled'});
         $sriovConfig->setNumVirtualFunction($config->{'vfs'});
         if (!$pciPassthruSystem->updatePassthruConfig($pciMOR,[$sriovConfig],
                                                  $config->{'sriov_enabled'})) {
           $vdLogger->Error("Can't update the passthrough configuration on host");
           return FALSE;
         };
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while configuring SRIOV on the host");
      return FALSE;
   }
   return TRUE;
};


########################################################################
#
# ConfigureVmkServices--
#     This function configure services for VMKnic
#
# Input:
#    deviceId - string containing the vmknic interface name. E.g. vmk1
#    hostMor  - Managed Object Reference of the Host
#    VmkServices - hash of which vmkservice needs to be enabled
#
# Results:
#     Returns the result of the vmkservice
#
# Side effects:
#     None
#
########################################################################

sub ConfigureVmkServices
{
   my $self         = shift;
   my %options = @_;
   my $vmkservicesref  = $options{vmkservicesref};
   my $hostMor = $options{hostMor};
   my $deviceId = $options{deviceid};
   my %vmkservices = %{$vmkservicesref};
   my $result;
   my $inlineVmknicObj = VDNetLib::InlineJava::Host::VmknicManager->new(anchor => $self->{'anchor'});
   for my $service (%vmkservices){
     if ($service eq "FTLOGGING" || "VMOTION" || "MANAGEMENT") {
        $result =  $inlineVmknicObj->ModifyVmkService(service => $service,
                                                      enable  => $vmkservices{$service},
                                                      hostMor => $hostMor,
                                                      device  => $deviceId,
                                                      );
     }
   }
  return $result;
}

########################################################################
#
# GetOpaqueNetworkInfoForPgrp--
#     This function gets the opaqueNetwork information for an inline
#     Portgroup
#
# Input:
#    inlinePortgroup - The inline Portgroup
#
# Results:
#     Returns Hash if operation is successful
#           {'opaqueNetworkId', 'opaqueNetworkType'}
#     returns FALSE if failed to get the opaqueNetwork.
#
# Side effects:
#     None
#
########################################################################

sub GetOpaqueNetworkInfoForPgrp
{
   my $self = shift;
   my %args = @_;
   my $inlinePortgroup = $args{inlinePortgroup};
   my $networkSystem = $self->{networkSystem};
   my $OpaqueNetworkInfoHash = {};

   eval {
       my $nsMOR = $networkSystem->getNetworkSystem($self->{hostMOR});
       my $opaqueNetworkInfo = $networkSystem->getNetworkInfo(
          $nsMOR)->getOpaqueNetwork();
       my $opaqueNetworkType;
       my $opaqueNetworkId = undef;
       my $startTime = time();
       while (time() - $startTime < OPAQUE_NETWORK_WAIT_TIME) {
          $vdLogger->Trace("Trying to find opaque network for lswitch");
          for (my $index=0; $index < $opaqueNetworkInfo->size(); $index++) {
             if ($opaqueNetworkInfo->get($index)->getOpaqueNetworkId() eq $inlinePortgroup->{id}) {
                $opaqueNetworkId = $inlinePortgroup->{id};
                $opaqueNetworkType = $opaqueNetworkInfo->get(
                   $index)->getOpaqueNetworkType();
                last;
             }
          }
          if (defined $opaqueNetworkId) {
              last;
          }
          $vdLogger->Trace("Did not find the opaque network matching " .
                           "lswitch $inlinePortgroup->{id}, sleeping " .
                           SLEEP_BETWEEN_RETRIES ." seconds " .
                           "before retry ...");
          sleep SLEEP_BETWEEN_RETRIES;
       }
       if (not defined $opaqueNetworkId) {
          $vdLogger->Error("Could not find opaque network matching the " .
                           "logical switch id $inlinePortgroup->{id}");
          $OpaqueNetworkInfoHash = FALSE;
       } else {
          $OpaqueNetworkInfoHash->{'opaqueNetworkId'} = $opaqueNetworkId;
          $OpaqueNetworkInfoHash->{'opaqueNetworkType'} = $opaqueNetworkType;
       }

   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   } else {
      return $OpaqueNetworkInfoHash;
   }
}

1;
