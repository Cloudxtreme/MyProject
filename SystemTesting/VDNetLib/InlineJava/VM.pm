###############################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::VM;

#
# This class captures all common methods to configure or get information
# from a DVS. This package mainly uses VDNetLib::InlineJava::VDNetInterface
# class to interact with DVS.
#
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use List::Util qw(first);
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Inline::Java qw(cast coerce);

#
# Importing only vdLogger for now and nothing else to keep this package
# re-usable for frameworks/tools other than VDNet
#
use VDNetLib::Common::GlobalConfig qw ($vdLogger);

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler NewDataHandler
                                         LoadInlineJavaClass);
use VDNetLib::InlineJava::VM::VirtualAdapter;

use constant TRUE  => 1;
use constant FALSE => 0;
use constant OPAQUE_NETWORK_WAIT_TIME => 30;
use constant SLEEP_BETWEEN_RETRIES => 5;

########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::VM
#
# Input:
#     Named value parameters with following keys:
#     dvsName     : Name of the DVS (Required)
#     datacenter  : Name of the datacenter on which the given DVS
#                   exists (Required)
#     anchor      : Anchor to the VC on which given DVS exists (Required)
#
# Results:
#     An object of VDNetLib::InlineJava::DVS class if successful;
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
   $self->{'vmx'}       = $options{'vmx'};
   $self->{'vmName'}    = $options{'vmName'};
   $self->{'vmMOR'}     = $options{'vmMOR'};
   $self->{'host'}      = $options{'host'};
   $self->{'user'}      = $options{'user'} || "root";
   $self->{'password'}  = $options{'password'};

   $self-> {'password'} = (defined $self->{'password'}) ? $self->{'password'} :
                          'ca\$hc0w';
   eval {
      if (not defined $self->{'anchor'}) {
         $self->{anchor} = CreateInlineObject("com.vmware.vcqa.ConnectAnchor",
                                              $self->{host}, "443");
         $self->{sessionMgr} = CreateInlineObject("com.vmware.vcqa.vim.SessionManager",
         $self->{'anchor'});
         $self->{sessionMgr}->login($self->{anchor}, $self->{'user'},
                                    $self->{'password'});
      }
      if (not defined $self->{'vmObj'}) {
         $self->{'vmObj'} = CreateInlineObject("com.vmware.vcqa.vim.VirtualMachine",
                                               $self->{'anchor'});
      }

      if (not defined $self->{'vmMOR'}) {
         $self->{'vmMOR'} = $self->{vmObj}->getVMByName($self->{vmName}, undef);
      }

      if (not defined $self->{'ftHelper'}) {
         $self->{'ftHelper'} = CreateInlineObject("com.vmware.vcqa.vim.FaultToleranceHelper",
         $self->{'anchor'});
      }
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while creating " .
                       "VDNetLib::InlineJava::VM object");
      return FALSE;
   }

   bless($self, $class);
   return $self;
}


########################################################################
#
# UpdateVMExtraConfig--
#     Method to update VMX configuration. Note that this API works only
#     when the VM is in powered off state
#
# Input:
#     A hash representing vmx config and it's value as key/value pairs
#
# Results:
#     1, if the VMX configuration is updated successfully;
#     0, in case of any error
#
# Side effects:
#     VM Configuration will be changed.
#
########################################################################

sub UpdateVMExtraConfig
{
   my $self = shift;
   my $configHash = shift;

   eval {
      my $optionValue = [];
      my $index = 0;
      foreach my $key (keys %$configHash) {
         $vdLogger->Debug("Update key: $key value: $configHash->{$key}");
         $optionValue->[$index] = CreateInlineObject("com.vmware.vc.OptionValue");
         $optionValue->[$index]->setKey($key);
         $optionValue->[$index]->setValue($configHash->{$key});
         $index++;
      }

      $self->{vmObj}->setVMExtraConfig($self->{vmMOR}, $optionValue);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while updating VM configuration " .
                       "of $self->{vmName} on $self->{host}");
      return FALSE;
   }

   return TRUE;
}


########################################################################
#
# GetVMExtraConfig--
#     Method to retrieve VM's extra configuration
#
# Input:
#     None
#
# Results:
#     Reference to a hash in which each key/value pairs contains
#     a VMX configuration;
#     0, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetVMExtraConfig
{
   my $self = shift;
   my $extraConfigVector;
   my $extraConfigHash;
   eval {
      $extraConfigVector = $self->{vmObj}->getVMExtraConfigInfoList($self->{vmMOR});
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while retrieving VM extra config " .
                       "of $self->{vmName}");
      return FALSE;
   }

   for (my $i = 0; $i < $extraConfigVector->size(); $i++) {
      my $key = $extraConfigVector->get($i)->getKey();
      my $value = $extraConfigVector->get($i)->getValue();
      $extraConfigHash->{$key} = $value;
   }
   return $extraConfigHash;
}


########################################################################
#
# GetVMMor
#     Method to get VM Managed Object Reference (MOR) from VM's
#     displat/registered name
#
# Input:
#     vmName : VM display/registered Name as in the inventory
#
# Results:
#     Instance of com.vmware.vc.ManagedObjectReference (perl object)
#
# Side effects:
#     None
#
########################################################################

sub GetVMMor
{
   my $self   = shift;
   my $vmName = shift;

   my $vmMOR;

   eval {
      $vmMOR = $self->{vmObj}->getVMByName($vmName);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to acquire MKS ticket " .
                       "of $self->{vmName} on $self->{host}");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# GetVMMoID--
#     Method to get VM Managed Object ID (MOID) from VM's
#     display/registered name
#
# Input:
#     vmName : VM display/registered Name as in the inventory
#
# Results:
#	  vmMOID, of the VM found with the vmName (eg: vm-2062);
#	  FALSE, if VM is not found or in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetVMMoID
{
   my $self   = shift;
   my ($vmName,$vmFolderName) = @_;

   my $vmMOR;
   eval {
      $vmMOR = $self->{vmObj}->getVMByName($vmName, $vmFolderName);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to acquire MKS ticket " .
                       "of $self->{vmName} on $self->{host}");
      return FALSE;
   }

   my $vmMOID;
   eval {
      $vmMOID = $vmMOR->getValue();
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the VM MOID " .
                       "of $self->{vmName} on $self->{host}");
      return FALSE;
   }

   return $vmMOID;
}


########################################################################
#
# CreateLinkedClone--
#     Method to create linked clone of given VM instanace with VC
#
# Input:
#     Named value parameters with following keys:
#     templateVM   :  VM name which need to be cloned; (Mandatory)
#     cloneVMName  :  new linked clone VM name; (Mandatory)
#     cloneVMDir   :  where to place cloned VM; (Optional)
#     diskMoveType :  Specifies how a virtual disk is moved or copied
#                     to a datastore; (Optional and Enum). Anyone of
#                     below is valid:
#                     createNewChildDiskBacking, (DEFAULT)
#                     moveAllDiskBackingsAndAllowSharing,
#                     moveAllDiskBackingsAndDisallowSharing,
#                     moveChildMostDiskBacking,
#
# Results:
#     VM Mor object, if VM template cloned successfully;
#     FALSE, on any exceptions;
#
# Side effects:
#     None
#
#     Note: CreateLinkedClone is not supported by hostd;
#
########################################################################

sub CreateLinkedClone
{
   my $self = shift;
   my %options = @_;

   my $templateVM      = $options{'templateVM'};
   my $cloneVMName     = $options{'cloneVMName'};
   my $cloneVMDir      = $options{'cloneVMDir'};
   my $diskMoveType    = $options{'diskMoveType'};

   my $folderObj = CreateInlineObject("com.vmware.vcqa.vim.Folder",
                                      $self->{'anchor'});
   my $hostFolderMor;

   if (not defined $cloneVMDir) {
      my $datacenterMORs = [];
      $datacenterMORs = $folderObj->getDataCenters();
      $hostFolderMor = $folderObj->getHostFolder($datacenterMORs->get(0));
   } else {
      my $dcMor = $folderObj->getDataCenter($cloneVMDir);
      $hostFolderMor = $folderObj->getHostFolder($dcMor);
   }

   if (not defined $diskMoveType) {
      $diskMoveType = "createNewChildDiskBacking";
   }

   my $newVMMor;
   eval {
      my $VMMor =  $self->{vmObj}->getVMByName($templateVM, undef);
      my $snapshotMor =  $self->{vmObj}->createSnapshot($VMMor,
                                                        $cloneVMName,
                                                        $cloneVMName,
                                                        undef, undef);

      my $MySimUtil = CreateInlineObject("com.vmware.vcqa.vim.SIMUtil");
      my $cloneSpec =  $MySimUtil->createVMLinkedCloneSpec($diskMoveType,
                                                           $snapshotMor);

      $newVMMor = $self->{vmObj}->cloneVM($VMMor,
                                          $hostFolderMor,
                                          $cloneVMName,
                                          $cloneSpec);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create linked clone of $templateVM" .
                       " on $self->{host}");
      return FALSE;
   }

   return $newVMMor;
}


########################################################################
#
# CreateSecondaryVM--
#     Method to creates a secondary virtual machine of the passed
#     Primary virtual machine to be part of a fault tolerant group.
#
# Input:
#     Named value parameters with following keys:
#     vmSrcMor    :  ManagedObjectReference Primary VM Mor; (Mandatory)
#     hostSrcMor  :  The host where the secondary virtual machine is to
#                    be created. (Optional)
#
# Results:
#     FaultToleranceSecondaryOpResult, which has a reference to
#                                      the secondaryVM;
#     FALSE, on any exceptions;
#
# Side effects:
#     None
#
########################################################################

sub CreateSecondaryVM
{
   my $self = shift;
   my %options = @_;

   my $vmSrcMor      = $options{'vmSrcMor'};
   my $hostSrcMor     = $options{'hostSrcMor'};

   if (not defined $vmSrcMor) {
      $vdLogger->Error("vmSrcMor is missing in CreateSecondaryVM");
      return FALSE;
   }

   my $newVMMor;
   eval {
      my $VMMor =  $self->{vmObj}->createSecondaryVM($vmSrcMor,
                                                     $hostSrcMor);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in CreateSecondaryVM.");
      return FALSE;
   }

   return $newVMMor;
}


########################################################################
#
# GetVMByName--
#     Method to Search for VM by Name and gets its VM Mor
#
# Input:
#     Named value parameters with following keys:
#     vmName    :  VM Name (Display name) Display name is the name
#                  appears in the inventory; (Mandatory)
#     vmFolderName  :  VM FolderName; (Optional) If vmFolderName is
#                      specified, then VM name and the VM folder name
#                      should match. If vmFolderName is null, then first
#                      matching VM by name in the inventory will be returned.
#
# Results:
#     VM Mor null, if finds VM in given VM folder;
#     null, if VM not found;
#
# Side effects:
#     None
#
########################################################################

sub GetVMByName
{
   my $self = shift;
   my %options = @_;

   my $vmName         = $options{'vmName'};
   my $vmFolderName   = $options{'vmFolderName'};

   if (not defined $vmName ) {
      $vdLogger->Error("vmName is missing in GetVMByName");
      return FALSE;
   }

   my $vmMor;
   eval {
      $vmMor =  $self->{'vmObj'}->getVMByName($vmName,
                                              $vmFolderName);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in GetVMByName.");
      return FALSE;
   }

   return $vmMor;
}

########################################################################
#
# AddVirtualAdapters --
#     Method to add virtual ethernet adapters to the VM
#
# Input:
#     vnicSpec: reference to array of hash, hash with following keys
#               driver              : <vmxnet3/e1000>
#               portgroup           : reference to portgroup object
#               connected           : boolean
#               startConnected      : boolean
#               allowGuestControl   : boolean
#               reservation         : integer value in Mbps
#               limit               : integer value in Mbps
#               shareslevel         : normal/low/high/custom
#               shares              : integer between 0-100
#     type  : "ethernet" or "pcipassthru"
#
#
# Results:
#     Reference to an array of objects
#     (VDNetLib::InlineJava::VM::VirtualAdapter), if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub AddVirtualAdapters
{
   my $self     = shift;
   my $vnicSpec = shift;
   my $type     = shift || "ethernet";
   my $vmObj    = shift;

   my $labelPrefix = ($type eq "ethernet") ? "(Network adapter)" :
                     "(SR-IOV network adapter|PCI device)"; # Note: lower case n for network
   my @arrayOfVnicObjects;
   my $virtualDeviceConfigSpec = []; # new
   eval {
      my $existingAdapters = $self->GetVirtualDevices();
      if (!$existingAdapters) {
         $vdLogger->Error("Failed to get existing adapters");
         return FALSE;
      }
      foreach my $adapters (@$existingAdapters) {
         $vdLogger->Info("The existingadapters: $adapters");
      }

      # maintain an array to map free network label
      my @deviceMap;
      if ($type eq "pcipassthru") {
         @deviceMap = ((0) x 16); # max 16 devices for pcipassthru
      } else {
         @deviceMap = ((0) x 10); # max 10 devices for ethernet cards
      }
      my $indexvmnic;
      foreach my $deviceSpec (@{$existingAdapters}) {
         my $label = $deviceSpec->getDevice()->getDeviceInfo()->getLabel();
         $vdLogger->Info("The label ::: $label");
         if ($label =~ /^$labelPrefix (\d+)/i) {
            my $count = int($2);
            $vdLogger->Info("The ocujnt : $count");
            $deviceMap[$count-1] = 1;
            if ($count == 2) {
               $indexvmnic = $deviceSpec;
            } 
#else {
#               $virtualDeviceConfigSpec->[0] = $deviceSpec;
#            }
         }
      }
      my $len = scalar(@{$vnicSpec});
      $vdLogger->Info("The length of spec: $len");
      for (my $index = 0; $index < scalar(@{$vnicSpec}); $index++) {
         my $sp = $vnicSpec->[$index];
         while(my($k,$v)=each(%$sp)){$vdLogger->Info("vnicspec is :: $k--->$v");}
         # find the first index that matches 0 i.e available
         my $vnicCount = first { $deviceMap[$_] eq '0' } 0..$#deviceMap;
         $deviceMap[$vnicCount] = 1; # update the devicemap again
         $vnicCount++; # increment by 1 since Network label starts from 1 not 0
         $labelPrefix = ($vnicSpec->[$index]->{driver} eq "sriov") ? "SR-IOV network adapter" :
                        ($vnicSpec->[$index]->{driver} eq "fpt") ? "PCI device" :
                        "Network adapter";
         $vdLogger->Debug("Adding vnic $labelPrefix $vnicCount");
#         $vLogger->Debug("Adding vnic $labelPrefix $t");
         my $inlineVnicObj;
         while(my($k,$v)=each(%$self)){$vdLogger->Info("The self:$k--->$v");}
         if (defined $vmObj && defined $vmObj->{'nestedesx'}) {
            my $t = '2';
            $inlineVnicObj = VDNetLib::InlineJava::VM::VirtualAdapter->new(
                                 'vmObj' => $self,
            #                    'deviceLabel' => "$labelPrefix $vnicCount");
                                 'deviceLabel' => "$labelPrefix $t");
            $vnicSpec->[$index]->{key} = $vnicCount;
            $vdLogger->Info("The vniccount is $vnicCount, $index");
            $virtualDeviceConfigSpec->[$index] =
            $inlineVnicObj->ConfigureEthernetCardSpec("edit",
                                                $vnicSpec->[$index], $indexvmnic);
         } else {
            $vdLogger->Debug("Adding vnic $labelPrefix $vnicCount");
            $inlineVnicObj = VDNetLib::InlineJava::VM::VirtualAdapter->new(
                              'vmObj' => $self,
                              'deviceLabel' => "$labelPrefix $vnicCount");
            $vnicSpec->[$index]->{key} = $vnicCount;
            $virtualDeviceConfigSpec->[$index] =
            $inlineVnicObj->ConfigureEthernetCardSpec("add",
                                                $vnicSpec->[$index]); 
         } 
         push(@arrayOfVnicObjects, $inlineVnicObj);
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while adding adapters " .
                       "to $self->{vmName} on $self->{host}");
      return FALSE;
   }

   if (!$self->ReconfigureVirtualAdapters($virtualDeviceConfigSpec)) {
      $vdLogger->Error("Exception thrown reconfiguring adapters " .
                       "on $self->{vmName} on $self->{host}");
      return FALSE;
   }
   return \@arrayOfVnicObjects;
}

########################################################################
#
# ReconfigureVirtualAdapters --
#     Method to reconfigureVM spefically virtual adapters configuration
#
# Input:
#     virtualDeviceConfigSpec : reference to array of inline java
#                               objects of
#                               com.vmware.vc.VirtualDeviceConfigSpec
#
# Results:
#     boolean
#
# Side effects:
#     None
#
########################################################################

sub ReconfigureVirtualAdapters
{
   my $self = shift;
   my $virtualDeviceConfigSpec = shift;

   eval {
      my $newVMSpec =
         CreateInlineObject('com.vmware.vc.VirtualMachineConfigSpec');
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      $newVMSpec->getDeviceChange()->clear();
      $newVMSpec->setDeviceChange($util->arrayToVector(
                                                       $virtualDeviceConfigSpec));
      $self->{vmObj}->reconfigVM($self->{vmMOR}, $newVMSpec);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while updating VM configuration " .
                       "of $self->{vmName} on $self->{host}");
      if (defined $self->{'nestedesx'}) {
         $vdLogger->Debug("Nested esx vnic can't be removed with power on status");
         return TRUE;
      }
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# GetVirtualDevices --
#     Method to get list of existing ethernet adapters
#
# Input:
#     None
#
# Results:
#     Reference to array of adapter objects, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetVirtualDevices
{
   my $self = shift;
   my @existingAdapters;
   eval {
      my $currentVMConfigSpec = $self->{vmObj}->getVMConfigSpec(
                                                $self->{'vmMOR'});
      my $deviceConfig = $currentVMConfigSpec->getDeviceChange();
      for (my $i = 0; $i < $deviceConfig->size(); $i++) {
         my $deviceSpec = $deviceConfig->get($i);
         push(@existingAdapters, $deviceSpec);
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while getting " .
                       "list of existing adapters");
      return FALSE;
   }
   return \@existingAdapters;
}

########################################################################
#
# GetSystemId --
#     Method to get system Id for a pci passthrough device
#
# Input:
#     Id : Id for the pci passthrough device
#
# Results:
#     The system Id of the device
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetSystemId
{
   my $self = shift;
   my $id = shift;
   my $systemId;

   if (not defined $id) {
      $vdLogger->Error("ID of the pci pass through device is missing");
      return FALSE;
   }

   eval {
      my $environmentBrowser =
         CreateInlineObject("com.vmware.vcqa.vim.EnvironmentBrowser",
                                      $self->{'anchor'});
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      my $vmEnvironment = $self->{vmObj}->getVMEnvironment(
                                       $self->{'vmMOR'});
      my $configTargets = $environmentBrowser->queryConfigTarget(
                                                 $vmEnvironment,undef);
      my $refArrayofDevices = $util->vectorToArray(
                                   $configTargets->getPciPassthrough());
      foreach my $device (@$refArrayofDevices) {
          if ($device->getPciDevice->getId() eq $id) {
            $systemId = $device->getSystemId();
            $vdLogger->Debug("The systemId for $id is $systemId");
            last;
         }
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while getting " .
                       "system Id for pci device $id");
      return FALSE;
   }
   return $systemId;
}

########################################################################
#
# RemoveVirtualAdapters --
#     Method to remove ethernet adapters from VM
#
# Input:
#     adapters: reference to an array adapters
#
# Results:
#     TRUE, if given adapters are removed from VM;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RemoveVirtualAdapters
{
   my $self     = shift;
   my $adapters = shift;
   my $type     = shift || "ethernet";
   my $includeControlAdapter = shift || FALSE;
   my $existingAdapterstartingIndex = 0;
   my @finalAdaptersList;
   eval {
      if (not defined @$adapters) {
         $adapters = $self->GetVirtualDevices();
         if (!$adapters) {
            $vdLogger->Error("Failed to get existing adapters list");
            VDSetLastError(VDGetLastError());
            return FALSE;
         }
         my $deviceCount = scalar(@{$adapters});
         for (my $index = 0; $index < $deviceCount; $index++) {
            my $device = $adapters->[$index]->getDevice();
            my $name = $device->getDeviceInfo()->getLabel();
            $vdLogger->Debug("Current device label is $name");
            my $labelPrefix = "Network adapter|PCI device";
            # ignore all non-network/pci devices, note not using ^
            if ($name !~ /$labelPrefix/i) {
               next;
            }
            my $backing = $device->getBacking();
            my $portgroup =
         VDNetLib::Common::GlobalConfig::DEFAULT_VM_MANAGEMENT_PORTGROUP;
            if (($backing =~ /VirtualEthernetCardNetworkBackingInfo/i) &&
               ($backing->getDeviceName() =~ /$portgroup/i)) {
               if ($includeControlAdapter eq FALSE) {
                  $vdLogger->Debug("Deleting all the adapters" .
                     " except management adapter.");
                  next;
               }
            }
            push(@finalAdaptersList, $adapters->[$index]);
            $vdLogger->Debug("Adding $name to removing nic list");
         }
      } else {
         @finalAdaptersList = @$adapters;
      }
      my $virtualDeviceConfigSpec = []; # new
      my $existingCount = scalar(@finalAdaptersList);
      if (defined $self->{'nestedesx'}) {
        $vdLogger->Info("Nested esx vnic can't be removed");
        return TRUE;
      }
      $vdLogger->Info("Removing $existingCount $type devices from $self->{vmName}");
      for (my $index = 0; $index < $existingCount; $index++) {
         my $inlineVnicObj = VDNetLib::InlineJava::VM::VirtualAdapter->new(
                                                           'vmObj' => $self);
         $virtualDeviceConfigSpec->[$index] =
            $inlineVnicObj->ConfigureEthernetCardSpec("remove",
                                                      undef,
                                                      $finalAdaptersList[$index]);
      }

      if (!$self->ReconfigureVirtualAdapters($virtualDeviceConfigSpec)) {
         $vdLogger->Error("Exception thrown reconfiguring adapters " .
                          "on $self->{vmName} on $self->{host}");
         return FALSE;
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while removing adapters " .
                       "of $self->{vmName} on $self->{host}");
      return FALSE;
   }
   return TRUE;
}

########################################################################
#
# UpdateVCUUID --
#     Method to update VM's VC UUID
#
# Input:
#     vcUUID: RFC 4122 based UUID
#
# Results:
#     1, if vcUUID updated successfully;
#     0, otherwise
#
# Side effects:
#     None
#
########################################################################

sub UpdateVCUUID
{
   my $self    = shift;
   my $vcUUID  = shift;
   eval {
      if (not defined $vcUUID) {
         LoadInlineJavaClass('java.util.UUID');
         my $uuid = VDNetLib::InlineJava::VDNetInterface::java::util::UUID->randomUUID();
         $vcUUID = $uuid->toString();
      }

      my $newVMSpec =
         CreateInlineObject('com.vmware.vc.VirtualMachineConfigSpec');
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      $newVMSpec->setInstanceUuid($vcUUID);
      $self->{vmObj}->reconfigVM($self->{vmMOR}, $newVMSpec);
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# UpgradeVM --
#     Method to upgrade VM to given version
#
# Input:
#     version: version number
#
# Results:
#     1, if the VM version is upgraded successfully;
#     0, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub UpgradeVM
{
   my $self    = shift;
   my $version = shift;

   my $result;
   eval {
      $result = $self->{vmObj}->upgradeVM($self->{vmMOR}, $version);
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
   return $result;
}


########################################################################
#
# UpgradeTools --
#     Method to upgrade VMTools on given VM object;
#     UpgradeToolsFromImage has long been tagged @transitional in the vsphere-2015 branch;
#     UpgradeTools() can instead of the unused API;
#
# Input:
#     None
#
# Results:
#     TRUE, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub UpgradeTools
{
   my $self     = shift;

   $vdLogger->Debug("Upgrading VMTools" .
                    "on $self->{vmName} on $self->{host}");
   eval {
      $self->{vmObj}->upgradeTools($self->{vmMOR},
                                           undef);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to upgrade vmtools");
      $vdLogger->Error("Exception thrown while upgrade VMTools " .
                       "on $self->{vmName} on $self->{host}");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# UpgradeToolsFromImage --
#     Method to upgrade VMTools on given VM object;
#
# Input:
#     isoSrc:   The iso location in local storage or iso link in URI(MANDATORY);
#
# Results:
#     TRUE if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub UpgradeToolsFromImage
{
   my $self     = shift;
   my $isoSrc   = shift;

   $vdLogger->Debug("Upgrading VMTools with image source $isoSrc");
   eval {
      if ($isoSrc =~ /\[.*\]/i) {
         # if we use iso in local storage, $isoSrc should be in format of
         # [Storage Name]path to iso,
         # e.g. [store]packages/6.0.0/vmtools/linux.iso
         #
         my $virtualDeviceFileBackingInfo =
                CreateInlineObject("com.vmware.vc.VirtualDeviceFileBackingInfo");
         $virtualDeviceFileBackingInfo->setFileName($isoSrc);
         $self->{vmObj}->upgradeToolsFromImage($self->{vmMOR},
                                               undef,
                                               $virtualDeviceFileBackingInfo,
                                               undef);
      } else {
         # if we use iso in build-web, $isoSrc should be a valid URL. E.g
         # http://build-squid.eng.vmware.com/build/mts/release/bora-1420547/
         # publish/pxe/packages/6.0.0/vmtools/linux.iso
         #
         my $virtualDeviceURIBackingInfo =
                CreateInlineObject("com.vmware.vc.VirtualDeviceURIBackingInfo");
         $virtualDeviceURIBackingInfo->setDirection("client");
         $virtualDeviceURIBackingInfo->setServiceURI($isoSrc);
         $self->{vmObj}->upgradeToolsFromImage($self->{vmMOR},
                                               undef,
                                               $virtualDeviceURIBackingInfo,
                                               undef);
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to upgrade vmtools with image $isoSrc");
      $vdLogger->Error("Exception thrown while upgrade VMTools " .
                       "on $self->{vmName} on $self->{host}");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# GetInstanceUUID --
#     Method to get instance UUID of VM
#
# Input:
#     None
#
# Results:
#     UUID, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetInstanceUUID
{
   my $self = shift;
   my $uuid;
   eval {
      $uuid = $self->{vmObj}->getInstanceUuid($self->{vmMOR});
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
   return $uuid;
}


########################################################################
#
# GetToolsInfo --
#     Method to retrieve the VMTools info of given VM
#
# Input:
#     $vmName: VM name we need to get vmtool info;
#
# Results:
#     $toolsInfo: Reference to hash which contains VMTools info;
#     FALSE, in case of any error.
#
# Side effects:
#
#
########################################################################

sub GetToolsInfo
{
   my $self = shift;
   my $vmName = shift;
   my ($guestInfo, $toolsInfo);

   eval {
      $guestInfo = $self->{vmObj}->getVMGuestInfo($self->{vmMOR});
      $toolsInfo->{'toolsRunningStatus'} =
                                     $guestInfo->getToolsVersionStatus();
      $toolsInfo->{'toolsVersion'} = $guestInfo->getToolsVersion();
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to retrieve VM guest info for VM $vmName");
      return FALSE;
   }

   return $toolsInfo;
}

########################################################################
#
# UpdateMemReservation --
#     Method to update VM's Memory reservation
#
# Input:
#     memSize: memory size in MB
#     pin: whether the reservation is locked to max
#
# Results:
#     TRUE, if memory reservation updated successfully;
#     FALSE, otherwise
#
# Side effects:
#     None
#
########################################################################

sub UpdateMemReservation
{
   my $self    = shift;
   my $memSize  = shift;
   my $pin = shift;
   eval {
      my $newVMSpec =
         CreateInlineObject('com.vmware.vc.VirtualMachineConfigSpec');
      my $resourceAlloc = CreateInlineObject('com.vmware.vc.ResourceAllocationInfo');
      $resourceAlloc->setReservation($memSize);
      $newVMSpec->setMemoryAllocation($resourceAlloc);
      $newVMSpec->setMemoryReservationLockedToMax($pin);
      if (!$self->{vmObj}->reconfigVM($self->{vmMOR}, $newVMSpec)) {
           return FALSE;
      };
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to update Memory Reservation
                                       info for VM $self->{vmName}");
      return FALSE;
   }
   return TRUE;
}

###############################################################################
#
# Vmotion
#      This method will vmotion this vm to either destination host or Datastore
#      or both
#
# Input:
#      datastore -  Destination Datastore
#      host      -  Destination host
#
# Results:
#      Returns TRUE, if operation success
#      Returns FALSE, if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub Vmotion
{
   my $self = shift;
   my $inlineDatastoreObj = shift;
   my $inlineHostObj      = shift;
   my $ret = FALSE;
   eval {
      my $virtualMachineRelocateSpec = CreateInlineObject("com.vmware.vc.VirtualMachineRelocateSpec");
      if (defined $inlineDatastoreObj) {
         $virtualMachineRelocateSpec->setDatastore($inlineDatastoreObj->{datastoreMor});
      }
      if (defined $inlineHostObj) {
         $virtualMachineRelocateSpec->setHost($inlineHostObj->{hostMOR});
      }
      $ret = $self->{vmObj}->relocateVM($self->{vmMOR},
                                        $virtualMachineRelocateSpec,
					undef,
					TRUE);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to perform storage vmotion of $self->{vmName}" .
                       "to $inlineDatastoreObj->{datastoreName} on $self->{host}");
      return FALSE;
   }
   return $ret;
}

###############################################################################
#
# Xvmotion
#      This method will vmotion this vm to dest host/vc/datacenter/datastore
#
# Input:
#      dsthost      - Destination host
#      priority     - The priority of vmotion task
#
# Results:
#      Returns TRUE, if operation success
#      Returns FALSE, if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub Xvmotion
{
   my $self = shift;
   my %args = @_;
   my $dstHostObj = $args{dsthost};
   my $priority = $args{priority};
   my $ret = FALSE;
   if (defined $dstHostObj) {
      $dstHostObj = $dstHostObj->[0];
      $dstHostObj = $dstHostObj->GetInlineHostObject();
      $vdLogger->Info("Migrating VM:$self->{vmName} to $dstHostObj->{host} ...");
   }
   eval {
      LoadInlineJavaClass('com.vmware.vc.VirtualMachineMovePriority');
      my $actionHash = {
         'default' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VirtualMachineMovePriority::DEFAULTPRIORITY,
         'high' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VirtualMachineMovePriority::HIGHPRIORITY,
         'low' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VirtualMachineMovePriority::LOWPRIORITY,
      };
      my $virtualMachineRelocateSpec = CreateInlineObject("com.vmware.vc.VirtualMachineRelocateSpec");
      $virtualMachineRelocateSpec = $self->GenerateRelocateSpec(%args);

      # migrate the dest vm $self->{'vmMOR'}
      $ret = $self->{vmObj}->relocateVM($self->{'vmMOR'},
                                        $virtualMachineRelocateSpec,
                                        $actionHash->{lc{$priority}},
                                        TRUE);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to perform cross vmotion of $self->{vmName}" .
                       " to $dstHostObj->{'host'}");
      return FALSE;
   }
   return $ret;
}

###############################################################################
#
# GenerateRelocateSpec
#      This method will vmotion this vm to dest host/vc/datacenter/datastore
#
# Input:
#      crossdatastore - If cross Datastore
#      dsthost        - Destination host
#      portgroup      - Desination portgroup
#      vc             - src vc
#
# Results:
#      Returns TRUE, if operation success
#      Returns FALSE, if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub GenerateRelocateSpec
{
   my $self = shift;
   my %args = @_;
   my $dstHostObj = $args{dsthost};
   my $dstnetObj = $args{portgroup};
   my $crossDatastore = $args{crossdatastore};
   my $vcObj = $args{vc};
   my $switchType = undef;
   my $ret = FALSE;
   my $dstHostMor = undef;
   my $srcProvOpsStorageHelper = undef;
   my $dstProvOpsStorageHelper = undef;
   my $datastoreMorList = undef;
   my $srcAnchor = undef;
   my $dstAnchor = undef;
   my $folderObj = undef;
   my $dstDatacenterMor = undef;
   my $vcUser = undef;
   my $vcPasswd = undef;
   my $virtualMachineRelocateSpec = CreateInlineObject("com.vmware.vc.VirtualMachineRelocateSpec");

   eval {
      my $TestUtil = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      my $switchObj = undef;
      my $pgName = undef;

      if (defined $dstHostObj) {
         $dstHostObj = $dstHostObj->[0];
         # get srcAnchor and dstAnchor, and get/set service if cross vc
         if (defined $dstHostObj->{vcObj}) {
            my $dstVCIP = $dstHostObj->{vcObj}->{vcaddr};
            my $srcVCIP = undef;
            if (not defined $vcObj) {
               $vcObj = $dstHostObj->{vcObj};
               $vdLogger->Debug("Src vcObj is " . Dumper($vcObj));
            }
            $srcVCIP = $vcObj->{vcaddr};
            $vcUser = $vcObj->{user};
            $vcPasswd = $vcObj->{passwd};

            $srcAnchor = CreateInlineObject("com.vmware.vcqa.ConnectAnchor",
                                   $srcVCIP,"443");
            my $srcSessionMgr = CreateInlineObject("com.vmware.vcqa.vim.SessionManager",$srcAnchor);
            $srcSessionMgr->login($srcSessionMgr->getSessionManager(),$vcUser,$vcPasswd,undef);
            $dstAnchor = CreateInlineObject("com.vmware.vcqa.ConnectAnchor",
                                   $dstVCIP,"443");
            my $dstSessionMgr = CreateInlineObject("com.vmware.vcqa.vim.SessionManager",$dstAnchor);
            $dstSessionMgr->login($dstSessionMgr->getSessionManager(),$vcUser,$vcPasswd,undef);
            $vdLogger->Debug("Src vcaddr is " . Dumper($srcVCIP));
            $vdLogger->Debug("Dst vcaddr is " . Dumper($dstVCIP));
            if (not defined $dstAnchor || not defined $srcAnchor) {
               $vdLogger->Error("Failed to get dstAnchor/srcAnchor");
               VDSetLastError("EINVALID");
               return FALSE;
            }
            if (not defined $srcVCIP || not defined $dstVCIP) {
               $vdLogger->Error("Failed to get src/dst vc ip");
               VDSetLastError("EINVALID");
               return FALSE;
            }
            if (!($srcVCIP eq $dstVCIP)) {
               #Build /cm-keystore.jks into vcqa.jar and copy it into the same directory with vcqa.jar
               my $cp = $ENV{CLASSPATH};
               my @temp = split(":", $cp);
               my $vcqaPath = $temp[1];
               my @cmdResults = `jar uf $vcqaPath /cm-keystore.jks`;
               if (index ($cmdResults[0], "no such file or directory") != -1) {
                  $vdLogger->Error("Please copy $FindBin::Bin/../bin/staf/lib/cm-keystore.jks into root folder / as user root");
               }
               my $libPath = substr($vcqaPath, 0, length($vcqaPath)-8);
               $vdLogger->Debug("The parent folder of vcqa.jar is :" . $libPath);
               `cp $FindBin::Bin/../bin/staf/lib/cm-keystore.jks $libPath`;
               my $xvcProvisioningHelper = CreateInlineObject("com.vmware.vcqa.vim.xvcprovisioning.XvcProvisioningHelper",$srcAnchor,$dstAnchor);
               #Set service for vmRelocateSpec
               $virtualMachineRelocateSpec->setService($xvcProvisioningHelper->getServiceLocator($vcUser,$vcPasswd));
            }
         } else {
            $vdLogger->Error("Failed to get dest vcObj");
            VDSetLastError("EINVALID");
            return FALSE;
         }
      }
      # get switchObj and switch type
      $vdLogger->Debug("The dstnetObj is ".Dumper($dstnetObj));
      if (not defined $dstnetObj) {
            $vdLogger->Warn("dstnetObj not defined");
      } else {
         if (defined $dstnetObj->{'switchObj'}) {
            $switchObj = $dstnetObj->{'switchObj'};
            $switchType = $switchObj->{'switchType'};
         }
         my $ethernetCardListDeviceChange;
         my $inlinePortgroup = $dstnetObj->GetInlinePortgroupObject();
         if (not defined $inlinePortgroup) {
            $vdLogger->Error("GetInlinePortgroupObject failed");
            VDSetLastError("EOPFAILED");
            return FALSE;
         }
         $vdLogger->Debug("The inlinePortgroup is ".Dumper($inlinePortgroup));
         if (($inlinePortgroup->{'type'} eq "vwire") || ($inlinePortgroup->{'type'} eq "logicalSwitch")) {
            $ethernetCardListDeviceChange = $self->GenerateDeviceChange($inlinePortgroup,$dstHostObj);
         } else {
            # get dest pgName
            if ($switchType eq "vswitch") {
               $pgName = $dstnetObj->{pgName};
            } else {
               $pgName = $dstnetObj->{'DVPGName'};
            }
            $vdLogger->Debug("The dest pgName is: " . Dumper($pgName));

            # generate and set ethernetCardListDeviceChange for $virtualMachineRelocateSpec
            $ethernetCardListDeviceChange = $self->GenerateDeviceChange($switchObj, $pgName);
         }
         $virtualMachineRelocateSpec->setDeviceChange($ethernetCardListDeviceChange);
      }
      # generate dest datacenter mor and folder obj
      $folderObj = CreateInlineObject("com.vmware.vcqa.vim.Folder",$dstAnchor);
      if (not defined $folderObj) {
            $vdLogger->Error("Failed to get folderObj $folderObj");
            VDSetLastError("EINVALID");
            return FALSE;
      }
      $dstHostObj = $dstHostObj->GetInlineHostObject();
      if (not defined $dstHostObj) {
         $vdLogger->Error("Failed to get dstHostObj $dstHostObj");
         VDSetLastError("EINVALID");
         return FALSE;
      }
      if (defined $dstHostObj->{'hostMOR'}) {
         $dstHostMor = $dstHostObj->{'hostMOR'};
         $dstDatacenterMor = $folderObj->getDataCenter($dstHostMor);
      }

      # generate and set dest folder for $virtualMachineRelocateSpec
      if (defined $dstDatacenterMor) {
         my $dstFolder = $folderObj->getVMFolder($dstDatacenterMor);
         $virtualMachineRelocateSpec->setFolder($dstFolder);
         $vdLogger->Debug("The dest datacenter name is: ".Dumper($folderObj->getName($dstDatacenterMor)));
       } else {
         $vdLogger->Error("Failed to get dstDatacenterMor $dstDatacenterMor");
         VDSetLastError("EINVALID");
         return FALSE;
       }

      # generate and set dest host and pool for $virtualMachineRelocateSpec
      $virtualMachineRelocateSpec->setHost($dstHostMor);
      $virtualMachineRelocateSpec->setPool($dstHostObj->{'hostSystem'}->getResourcePool($dstHostMor)->get(0));

      # generate and set dest datastore mor for $virtualMachineRelocateSpec
      $srcProvOpsStorageHelper = CreateInlineObject(
          "com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper",$srcAnchor);
      $vdLogger->Debug("VM mor id is: ".Dumper($self->{vmMOR}->getValue()));
      my $datastoreMor = $srcProvOpsStorageHelper->getVMConfigDatastore($self->{vmMOR});
      $vdLogger->Debug("Src datastore name is: ".Dumper($datastoreMor));
      my $datastoreName = "vdnetSharedStorage";
      if (defined $datastoreMor) {
         $datastoreName = $self->GetVMDatastoreName($srcAnchor,$datastoreMor);
         $vdLogger->Debug("Src datastore name is: ".Dumper($datastoreName));
      }
      $dstProvOpsStorageHelper = CreateInlineObject(
          "com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper",$dstAnchor);
      $datastoreMorList = $dstProvOpsStorageHelper->getHostDatastores($dstHostMor,undef,undef);
      my $tmpDatastoreMor = undef;
      if (defined $datastoreMorList) {
         $vdLogger->Debug("The datastore list size is: ".Dumper($datastoreMorList->size()));
         my $i = 0;
         if (defined $crossDatastore && !($crossDatastore eq "false")) {
            while ($i < $datastoreMorList->size()) {
               $tmpDatastoreMor = $datastoreMorList->get($i);
               if (!$datastoreName eq $self->GetVMDatastoreName($dstAnchor, $tmpDatastoreMor)) {
                  $datastoreMor = $tmpDatastoreMor;
                  $datastoreName = $self->GetVMDatastoreName($dstAnchor, $tmpDatastoreMor);
                  last;
               }
               $i++;
            }
         } else {
            $datastoreMor = $dstHostObj->GetDatastore($datastoreName);
         }
         $vdLogger->Debug("The dest datastore is: ".Dumper($datastoreName));
         $virtualMachineRelocateSpec->setDatastore($datastoreMor);
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to configure virtualmachinerelocatespec.");
      return FALSE;
   }
   return $virtualMachineRelocateSpec;
}

###############################################################################
#
# GenerateDeviceChange
#      This method will generate the required VirtualDeviceConfigSpec for VirtualMachineRelocateSpec
#
# Input:
#      @_ -  args
#      switchObj - Destination Switch
#      pgName - Destination portgroup name
#
# Results:
#      Returns a list of VirtualDeviceConfigSpece, if operation success
#      Returns FALSE, if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub GenerateDeviceChange
{
   my $self = shift;
   my $switchObj = shift;
   my $pgName = shift;
   my $switchType = $switchObj->{'switchType'};
   my $ethernetCardListDeviceChange = undef;
   my $virtualDeviceConfigSpec = undef;
   eval {
      my $DVSUtil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");
      my $TestUtil = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      my $tmpBackInfo = CreateInlineObject("com.vmware.vc.VirtualDeviceDeviceBackingInfo");
      my $vd = CreateInlineObject("com.vmware.vc.VirtualDevice");
      LoadInlineJavaClass('com.vmware.vc.VirtualDeviceConfigSpecOperation');
      my $actionHash = {
         'add' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VirtualDeviceConfigSpecOperation::ADD,
         'edit' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VirtualDeviceConfigSpecOperation::EDIT,
         'remove' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VirtualDeviceConfigSpecOperation::REMOVE,
      };
      $ethernetCardListDeviceChange = $DVSUtil->getAllVirtualEthernetCardDevices($self->{'vmMOR'}, $self->{'anchor'});
      my $i = 0;
      my $label = undef;
      if ((defined $switchType) and ($switchType eq "vswitch")) {
         while ($i < $ethernetCardListDeviceChange->size()) {
            my $destBackInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardNetworkBackingInfo");
            $virtualDeviceConfigSpec = $ethernetCardListDeviceChange->get($i);
            $vd = $virtualDeviceConfigSpec->getDevice();
            $label = $vd->getDeviceInfo()->getLabel();
            if ($label eq ('Network adapter 1')) {
               $destBackInfo->setDeviceName("VM Network");
               $vdLogger->Info("Configure the default Network adapter1 to connect to default VM Network");
            } else {
               $destBackInfo->setDeviceName($pgName);
               $vdLogger->Info("Configure the second vnic to connect to " . $destBackInfo->getDeviceName());
            }
            $vd->setBacking($destBackInfo);
            $virtualDeviceConfigSpec->setOperation($actionHash->{lc('edit')});
            $i++;
         }
      } elsif ((defined $switchType) and ($switchType eq "vds")) {
         my $inlineDVS = $switchObj->GetInlineDVS();
         if (defined $inlineDVS) {
            while ($i < $ethernetCardListDeviceChange->size()) {
               $virtualDeviceConfigSpec = $ethernetCardListDeviceChange->get($i);
               $vd = $virtualDeviceConfigSpec->getDevice();
               $label = $vd->getDeviceInfo()->getLabel();
               if ($label eq ('Network adapter 1')) {
                  my $destBackInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardNetworkBackingInfo");
                  $destBackInfo->setDeviceName("VM Network");
                  $vd->setBacking($destBackInfo);
               } else {
                  my $inlineVnicObj = VDNetLib::InlineJava::VM::VirtualAdapter->new(
                                                     'vmObj' => $self,
                                                     'deviceLabel' => $label);
                  my $inlinePG = VDNetLib::InlineJava::Portgroup::DVPortgroup->new(
                                                     'name' => $pgName,
                                                     'switchObj' => $inlineDVS);
                  $inlineVnicObj->SetNetworkBacking($vd,$inlinePG);
               }
               $virtualDeviceConfigSpec->setOperation($actionHash->{lc('edit')});
               $i++;
            }
         }
      } elsif ((defined $switchObj) and ($switchObj->{'type'} eq "vwire")) {
         while ($i < $ethernetCardListDeviceChange->size()) {
            $virtualDeviceConfigSpec = $ethernetCardListDeviceChange->get($i);
            $vd = $virtualDeviceConfigSpec->getDevice();
            $label = $vd->getDeviceInfo()->getLabel();
            if ($label eq ('Network adapter 1')) {
               my $destBackInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardNetworkBackingInfo");
               $destBackInfo->setDeviceName("VM Network");
               $vd->setBacking($destBackInfo);
            } else {
               my $backingInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo");
               my $dvsPortConnection = $switchObj->GetPortConnection(inlineJavaHostObj => $pgName->GetInlineHostObject());
               $backingInfo->setPort($dvsPortConnection);
               $vd->setBacking($backingInfo);
            }
            $virtualDeviceConfigSpec->setOperation($actionHash->{lc('edit')});
            $i++;
         }
      } elsif ((defined $switchObj) and ($switchObj->{'type'} eq "logicalSwitch")) {
         $vdLogger->Debug("Configure the logicalSwitch with devicechange ");
         while ($i < $ethernetCardListDeviceChange->size()) {
            $virtualDeviceConfigSpec = $ethernetCardListDeviceChange->get($i);
            $vd = $virtualDeviceConfigSpec->getDevice();
            $label = $vd->getDeviceInfo()->getLabel();
            if ($label eq ('Network adapter 1')) {
               my $destBackInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardNetworkBackingInfo");
               $destBackInfo->setDeviceName("VM Network");
               $vd->setBacking($destBackInfo);
            } else {
               $vdLogger->Debug("Configure the device $label:");
               my $backingInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo");
               my $hostMOR = $self->{vmObj}->getHost($self->{'vmMOR'});
               my $networkSystem = CreateInlineObject(
                  "com.vmware.vcqa.vim.host.NetworkSystem",
                  $self->{'anchor'});
               my $nsMOR =$networkSystem->getNetworkSystem($hostMOR);
               my $opaqueNetworkInfo = $networkSystem->getNetworkInfo(
                  $nsMOR)->getOpaqueNetwork();
               my $opaqueNetworkType;
               my $opaqueNetworkId = undef;
               my $startTime = time();
               while (time() - $startTime < OPAQUE_NETWORK_WAIT_TIME) {
                  $vdLogger->Debug("Trying to find opaque network for lswitch: ".$switchObj->{id});
                  for (my $index=0; $index < $opaqueNetworkInfo->size(); $index++) {
                     $vdLogger->Debug("The opaque network id is: ". $opaqueNetworkInfo->get($index)->getOpaqueNetworkId());
                     if ($opaqueNetworkInfo->get($index)->getOpaqueNetworkId() eq $switchObj->{id}) {
                        $opaqueNetworkId = $switchObj->{id};
                        $opaqueNetworkType = $opaqueNetworkInfo->get(
                           $index)->getOpaqueNetworkType();
                        last;
                     }
                  }
                  if (defined $opaqueNetworkId) {
                      $vdLogger->Debug("Find the opaque network id: ".$opaqueNetworkId);
                      $vdLogger->Debug("Find the opaque network type: ".$opaqueNetworkType);
                      last;
                  }
                  $vdLogger->Trace("Did not find the opaque network matching " .
                                   "lswitch $switchObj->{id}, sleeping " .
                                   SLEEP_BETWEEN_RETRIES ." seconds " .
                                   "before retry ...");
                  sleep SLEEP_BETWEEN_RETRIES;
               }
               if (not defined $opaqueNetworkId) {
                  $vdLogger->Error("Could not find opaque network matching the " .
                                   "logical switch id $switchObj->{id}");
                  return FALSE;
               } else {
                  $backingInfo->setOpaqueNetworkId($opaqueNetworkId);
                  $backingInfo->setOpaqueNetworkType($opaqueNetworkType);
                  $vd->setBacking($backingInfo);
               }
            }
            $virtualDeviceConfigSpec->setOperation($actionHash->{lc('edit')});
            $i++;
         }
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
   return $ethernetCardListDeviceChange;
}

###############################################################################
#
# GetVMDatastoreName
#      This method will get the datastore name according to the datastore mor and host.
#
# Input:
#      anchor -  Connection Anchor
#      datastoreMor - Datastore Mor Object
#
# Results:
#      Returns datastore name, if operation success
#      Returns FALSE, if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub GetVMDatastoreName
{
   my $self = shift;
   my $anchor = shift;
   my $datastoreMor = shift;
   my $datastorename = FALSE;

   if (defined $anchor) {
      my $folder = CreateInlineObject("com.vmware.vcqa.vim.Folder",$anchor);
      if (defined $datastoreMor) {
         $datastorename = $folder->getName($datastoreMor);
      }
   }
   return $datastorename;
}

########################################################################
#
# FindVM
#     Method to get check if the VM exists in the inventory or not
#     if it exists we update the anchor at inline layer(do we need this?)
#
# Input:
#
# Results:
#     hostname
#
# Side effects:
#     None
#
########################################################################

sub FindVM
{
   my $self = shift;
   my $inlineDatacenterObj= undef;
   my $ret = FALSE;
   eval {
      my $searchIndex = CreateInlineObject("com.vmware.vcqa.vim.SearchIndex",
                            $self->{'anchor'});
      my $uuid = $self->GetInstanceUUID();
      my $searchIndexMOR = $searchIndex->getSearchIndex();
      $ret = $searchIndex->findByUuid($searchIndexMOR, $inlineDatacenterObj, $uuid, TRUE, TRUE);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to find VM $self->{vmName} It no longer exists");
      return FALSE;
   }
   #TODO: Check this with vdnet core team
   $self->{'vmObj'} = $ret;
   $self->{'vmMOR'} = $ret;
   return $ret;
}

########################################################################
#
# GetHostName
#     Method to get the host name on which the VM is sitting
#
# Input:
#
# Results:
#     hostname
#
# Side effects:
#     None
#
########################################################################

sub GetHostName
{
   my $self   = shift;
   my $host = FALSE;

   eval {
      $host = $self->{vmObj}->getHostName($self->{'vmMOR'});
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get hostname of $self->{vmName}");
      return FALSE;
   }
   return $host;
}


########################################################################
#
# GetHostIP
#     Method to get the host IP on which the VM is sitting
#
# Input:
#
# Results:
#     hostIP
#
# Side effects:
#     None
#
########################################################################

sub GetHostIP
{
   my $self   = shift;
   my $hostIP = FALSE;
   my $hostMOR = undef;

   eval {
      $hostMOR =  $self->{vmObj}->getHost($self->{'vmMOR'});
      my $hostSystem = CreateInlineObject("com.vmware.vcqa.vim.HostSystem",
                                          $self->{'anchor'});
      $hostIP = $hostSystem->getIPAddress($hostMOR);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get host IP of $self->{vmName}:$@");
      return FALSE;
   }
   return $hostIP;
}
########################################################################
#
# GenerateFaultToleranceConfigSpec --
#     Method to generate an obj of FaultToleranceConfigSpec
#
# Input:
#     vmMor               : (Optional) MOR of primary VM. If vmMor is not
#                           provided, $self->{vmMOR} will be used.
#     hostMor             : (Conditionally Optional, it's required if
#                           vmxDatastoreMor or vmDiskDatastoreMor is undef)
#                           MOR of host to place secondary VM
#     vmxDatastoreMor     : (Optional) MOR of datastore to place vmx of the
#                           secondary VM. If vmxDatastore is not provided,
#                           a writable NFS datastore will be used.
#     metaDataDatastoreMor: (Optional) MOR of datastore to place meta data of
#                           the secondary VM. If metaDataDatastore is not
#                           provided, value of vmxDatastoreMor will be used.
#     vmDiskDatastoreMor  : (Optional) MOR of datastore to place virtual disks
#                           of the secondary VM. If vmDiskDatastore is not
#                           provided, a local storage in secondary host will
#                           be used. If a usable local storage can't be found,
#                           value of vmxDatastoreMor will be used.
#
# Results:
#     Success: if an obj of FaultToleranceConfigSpec is generated successfully.
#     FALSE, if this is a error
#
# Side effects:
#     None
#
########################################################################

sub GenerateFaultToleranceConfigSpec
{
   my $self    = shift;
   my %options = @_;

   my $vmxDatastoreMor = $options{'vmxDatastoreMor'};
   my $metaDataDatastoreMor = $options{'metaDataDatastoreMor'};
   my $vmDiskDatastoreMor = $options{'vmDiskDatastoreMor'};
   my $vmMor = $options{'vmMor'};
   if (not defined $vmMor) {
      $vmMor = $self->{vmMOR};
   }
   my $hostMor = $options{'hostMor'};
   if (((not defined $vmxDatastoreMor) || (not defined $vmDiskDatastoreMor))
       &&
       (not defined $hostMor)) {
      $vdLogger->Error("hostMor must be defined when vmxDatastoreMor or " .
                                   "vmDiskDatastoreMor are not provided");
      return FALSE;
   }

   my $objFtConfigSpec = FALSE;
   eval {
       my $vmObj = $self->{vmObj};
       my $objVmConfigInfo = $vmObj->getVMConfigInfo($vmMor);
       my $provOpsStorageHelper = undef;

       if (not defined $vmxDatastoreMor) {
          $provOpsStorageHelper = CreateInlineObject(
             "com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper",
                                                           $self->{'anchor'});
          # To get writable NAS' list in the host
          my $nasList = $provOpsStorageHelper->getHostDatastores(
                                          $hostMor, "NFS", TRUE);
          if (not defined $nasList) {
             $vdLogger->Error("Couldn't find writable NFS datastore");
             return;
          }
          $vmxDatastoreMor = $nasList->get(0);
       }
       if (not defined $metaDataDatastoreMor) {
          $metaDataDatastoreMor = $vmxDatastoreMor;
       }
       if (not defined $vmDiskDatastoreMor) {
          if (not defined $provOpsStorageHelper) {
             $provOpsStorageHelper = CreateInlineObject(
                "com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper",
                                                             $self->{'anchor'});
          }
          # To get writable local datastores' list in the host
          my $localdsList = $provOpsStorageHelper->getHostDatastores(
                                            $hostMor, "VMFS", FALSE);
          if (not defined $localdsList) {
             $vmDiskDatastoreMor = $vmxDatastoreMor;
          } else {
             $vmDiskDatastoreMor = $localdsList->get(0);
          }
       }

       my $objFolder = CreateInlineObject("com.vmware.vcqa.vim.Folder",
                                                    $self->{'anchor'});
       my $vmxDatastoreName = $objFolder->getName($vmxDatastoreMor);
       my $metaDataDatastoreName = $objFolder->getName($metaDataDatastoreMor);
       my $vmDiskDatastoreName = $objFolder->getName($vmDiskDatastoreMor);
       $vdLogger->Debug("vmxDatastoreName is $vmxDatastoreName");
       $vdLogger->Debug("metaDataDatastoreMor is $metaDataDatastoreName");
       $vdLogger->Debug("vmDiskDatastoreMor is $vmDiskDatastoreName");

       # Create Config Spec
       $objFtConfigSpec = CreateInlineObject(
                              "com.vmware.vc.FaultToleranceConfigSpec");
       my $objFtVMConfigSpec = CreateInlineObject(
                              "com.vmware.vc.FaultToleranceVMConfigSpec");
       my $objFtMetaSpec = CreateInlineObject(
                              "com.vmware.vc.FaultToleranceMetaSpec");
       $objFtConfigSpec->setSecondaryVmSpec($objFtVMConfigSpec);
       $objFtConfigSpec->setMetaDataPath($objFtMetaSpec);

       # Set VMX and META datastore
       $objFtVMConfigSpec->setVmConfig($vmxDatastoreMor);
       $objFtMetaSpec->setMetaDataDatastore($metaDataDatastoreMor);

       # Build secondary vm disks Spec
       my $TestUtil = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
       my $objDeviceList = $objVmConfigInfo->getHardware->getDevice();
       my $refArrayofDevices = $TestUtil->vectorToArray($objDeviceList);
       my $objDiskSpecArray = [];
       foreach my $device (@$refArrayofDevices) {
          if ($device->getClass->getName() eq "com.vmware.vc.VirtualDisk") {
              my $objDiskSpec = CreateInlineObject(
                                    "com.vmware.vc.FaultToleranceDiskSpec");
              $objDiskSpec->setDisk($device);
              $objDiskSpec->setDatastore($vmDiskDatastoreMor);
              push @$objDiskSpecArray, $objDiskSpec;
          }
       }
       $objFtVMConfigSpec->setDisks(
                              $TestUtil->arrayToVector($objDiskSpecArray));
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to generate FaultToleranceConfigSpec obj ($@)");
      return FALSE;
   }

   return $objFtConfigSpec;
}


########################################################################
#
# EnableFaultTolerance--
#     Method to enable Fault Tolerance for the given VMMor.
#
# Input:
#     Named value parameters with following keys:
#     HostMor - Managed object reference of the Host
#     vmxDatastoreMor - Managed object reference of the vmxdatastore
#     metaDatastoreMor - Managed Object reference of the metaDatastore
#     vmDiskDatastoreMor - Managed Object reference of the vmDiskDatastore
#
# Results:
#     Returns secondaryvmMor if succesfull
#
# Side effects:
#     None
#############################################################

sub EnableFaultTolerance
{

   my $self = shift;
   my %options = @_;

   my $hostMor   = $options{'hostMor'};
   my $vmxDatastoreMor = $options{'vmxDatastoreMor'},
   my $metaDataDatastoreMor = $options{'metaDataDatastoreMor'},
   my $vmDiskDatastoreMor = $options{'vmDiskDatastoreMor'},
   my $secondaryvmMor;
   my $ftconfigspec;
   my $ftSecondaryOpResult;
   my $fthelper;
   my $res;
   my $ftstate = "disabled";
   my $count = 50;
   $ftconfigspec = $self->GenerateFaultToleranceConfigSpec('hostMor'=> $hostMor,
                                            'vmxDatastoreMor' => $vmxDatastoreMor,
                                            'metaDataDatastoreMor' => $metaDataDatastoreMor,
                                            'vmDiskDatastoreMor' => $vmDiskDatastoreMor);

   if (!defined($ftconfigspec)){
      return FALSE;
   }
   eval {
       $ftSecondaryOpResult = $self->{vmObj}->createSecondaryVM($self->{vmMOR},$hostMor,$ftconfigspec); #this doesnt and gives an error
       $secondaryvmMor = $ftSecondaryOpResult->getVm();
       $vdLogger->Info("Secondary VM Mor: $secondaryvmMor\n\n\n\n");
   };
   while ($ftstate eq "disabled" && $count !=0  ){
       eval {
            $vdLogger->Info("$count: Checking for Fault Tolerance of the VM");
            $res = $self->{ftHelper}->isFaultToleranceEnabled($self->{vmMOR});
       };
       if ($res == 1){
          $vdLogger->Info("Fault Tolerance Enabled");
          $ftstate = "enabled";
       }
       sleep(10);
       $count = $count - 1;
   }
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in createSecondaryVM.");
      return FALSE;
   }

   return $secondaryvmMor;

}


########################################################################
#
# DisableFaultTolerance--
#     Method to disable Fault Tolerance for the given VMMor.
#
# Input:
#
# Results:
#     VM Mor null, if finds VM in given VM folder;
#     null, if VM not found;
#
# Side effects:
#     None
########################################################################

sub DisableFaultTolerance
{
   my $self = shift;
   my $result;

   eval {
      my $primaryvm = $self->{ftHelper}->getPrimaryVM($self->{vmMOR});
      $result = $self->{vmObj}->turnOffFaultToleranceForVM($primaryvm);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown in Turning off Fault Tolerance.");
      return FALSE;
   }

   return TRUE;
}


1;
