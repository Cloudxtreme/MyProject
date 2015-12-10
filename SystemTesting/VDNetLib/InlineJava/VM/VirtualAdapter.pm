###############################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::VM::VirtualAdapter;

#
# This package contains attributes and methods to configure virtual
# ethernet adapter on a VM
#
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Inline::Java qw(cast coerce);

use VDNetLib::Common::GlobalConfig qw ($vdLogger);

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass
                                            CreateInlineObject
                                            InlineExceptionHandler);


use constant TRUE  => 1;
use constant FALSE => 0;
use constant OPAQUE_NETWORK_WAIT_TIME => 30;
use constant SLEEP_BETWEEN_RETRIES => 5;

########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::VM::VirtualAdapter
#
# Input:
#     vmobj      : reference to VDNetLib::InlineJava::VM
#     deviceLabel: device label, for example "Network Adapter 1"
#
# Results:
#     Blessed reference of VDNetLib::InlineJava::VM::VirtualAdapter
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
   $self->{'vmObj'}  = $options{'vmObj'};
   $self->{'deviceLabel'}  = $options{'deviceLabel'};
   $self->{'anchor'} = $self->{'vmObj'}{'anchor'};
   bless $self, $class;

   return $self;
}


########################################################################
#
# GetEthernetCardSpecFromLabel --
#     Method to get current ethernet card spec using device label
#
# Input:
#     None
#
# Results:
#     reference to inline java object of
#     com.vmware.vc.VirtualDeviceConfigSpec; or
#     FALSE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetEthernetCardSpecFromLabel
{
   my $self       = shift;
   my $inputLabel = $self->{'deviceLabel'};
   my $vmObj = $self->{'vmObj'};

   my $adaptersList = $vmObj->GetVirtualDevices();
   foreach my $deviceSpec (@{$adaptersList}) {
      my $device = $deviceSpec->getDevice();
      my $label = $device->getDeviceInfo()->getLabel();
      # Don't use =~ since there "Network adapter 1" and
      # "Network adapter 1x" will match
      if ($label eq $inputLabel) {
         return $deviceSpec;
      }
   }
   return FALSE;
}

########################################################################
#
# ConfigureEthernetCardSpec --
#     Method to configure ethernet card spec using the given
#     parameters
#
# Input:
#     action          : add/remove/edit (default is add)
#     userParameters  : reference to a hash with keys defined in
#                      VDNetLib::InlineJava::VM::AddVirtualAdapters()
#     ethernetCardSpec: reference to inline object of
#                       com.vmware.vc.VirtualMachineConfigSpec (optional)
#
#
# Results:
#     Updated ethernetCardSpec, if successful;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureEthernetCardSpec
{
   my $self             = shift;
   my $action           = shift || "add";
   my $userParameters   = shift;
   my $ethernetCardSpec = shift;
   my $vmObj = $self->{'vmObj'};

   my $deltaEthernetCardSpec;
   eval {
      my $ethernetCard;
      my $key;
      if (defined $ethernetCardSpec) {
         $ethernetCard = $ethernetCardSpec->getDevice();
         $key = $ethernetCard->getKey();
      } else {
         $vdLogger->Debug("Adding a vnic spec for $userParameters->{'driver'}");
         $ethernetCard = $self->GetDeviceTypeClass($userParameters->{'driver'});
         $key = $userParameters->{'key'};
      }
      $ethernetCard->setKey($key);
      $deltaEthernetCardSpec = CreateInlineObject("com.vmware.vc.VirtualDeviceConfigSpec");
      LoadInlineJavaClass('com.vmware.vc.VirtualDeviceConfigSpecOperation');
      my $actionHash = {
         'add' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VirtualDeviceConfigSpecOperation::ADD,
         'edit' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VirtualDeviceConfigSpecOperation::EDIT,
         'remove' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VirtualDeviceConfigSpecOperation::REMOVE,
      };
      $deltaEthernetCardSpec->setOperation($actionHash->{lc($action)});
      # configure network backing
      my $pgObj = $userParameters->{'portgroup'};
      $self->SetNetworkBacking($ethernetCard, $pgObj) if defined $pgObj;
      if ((defined $userParameters) && (keys %$userParameters) ) {
         $vdLogger->Debug("TODO (Aditya) : 1363965");

         # configure connection state
         $self->SetConnectionStatus($ethernetCard,
                                    $userParameters->{'connected'},
                                    $userParameters->{'startConnected'},
                                    $userParameters->{'allowGuestControl'}
                                    );

         # configure NIOC
         if (defined $userParameters->{'driver'}) {
            $vdLogger->Debug("TODO (Aditya) : 1363965");
            if ($userParameters->{'driver'} ne "fpt") {
               $self->ConfigureNIOC($ethernetCard,
                  $userParameters->{'reservation'},
                  $userParameters->{'limit'},
                  $userParameters->{'sharesLevel'},
                  $userParameters->{'shares'},
               );
            }
         }

      # configure SRIOV or PCI passthrough according to vnic driver type
         $vdLogger->Debug("Configure fpt/sriov for".Dumper($userParameters));
         if (defined $userParameters->{'driver'}) {
            $vdLogger->Debug("TODO (Aditya) : 1363965");
            if ($userParameters->{'driver'} eq "fpt") {
             $self->ConfigureFPT($ethernetCard,
                                 $userParameters->{'deviceId'},
                                 $userParameters->{'id'},
                                 $userParameters->{'deviceName'},
                                 $userParameters->{'systemId'},
                                 $userParameters->{'vendorId'},
                                );
          } elsif ($userParameters->{'driver'} eq "sriov") {
             $self->ConfigureSRIOV($ethernetCard,
                                  $userParameters->{'deviceId'},
                                  $userParameters->{'id'},
                                  $userParameters->{'deviceName'},
                                  'BYPASS',#The system Id is BYPASS for sriov device
                                  $userParameters->{'vendorId'},
                                );
         }
      }
         if (defined $userParameters->{'addressType'}) {
            $ethernetCard->setAddressType($userParameters->{'addressType'});
         }
         if (defined $userParameters->{'macaddress'}) {
            $vdLogger->Debug("Configure macAddress
                            $userParameters->{'macaddress'} on the adapter");
            $ethernetCard->setAddressType('Manual');
            $ethernetCard->setMacAddress($userParameters->{'macaddress'});
         }
      }
      my $description = CreateInlineObject("com.vmware.vc.Description");
      $description->setSummary("Network adapter $key");
      $description->setLabel("Network adapter $key");
      $ethernetCard->setDeviceInfo($description);
      # TODO: add other parameters on need basis
      $deltaEthernetCardSpec->setDevice($ethernetCard);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while updating VM configuration " .
                       "of $self->{vmObj}{vmName} on $self->{vmObj}{host}");
      return FALSE;
   }
   $self->{'ethernetCardSpec'} = $deltaEthernetCardSpec;
   while(my($k,$v)=each(%$deltaEthernetCardSpec)){$vdLogger->Info("The delta:$k--->$v");}
   while(my($k,$v)=each(%$deltaEthernetCardSpec)){print "Theaaa delta:$k--->$v\n";}
   while(my($k,$v)=each(%$self)){$vdLogger->Info("The selfdelta:$k--->$v");}
   my $eth = $self->{'ethernetCardSpec'};
   while(my($k,$v)=each(%$eth)) {$vdLogger->Info("The speceth:$k--->$v");}
   return $deltaEthernetCardSpec;
}


########################################################################
#
# GetDeviceTypeClass --
#     Method to get inline java class for the given device type
#
# Input:
#     deviceType: vmxnet3/e1000/sriov
#
# Results:
#     reference to object of com.vmware.vc.Virtual<deviceType>;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetDeviceTypeClass
{
   my $self = shift;
   my $deviceType = shift || 'vmxnet3';
   my $ethernetCard;
   my $deviceClassHash = {
      'vmxnet3'   => 'com.vmware.vc.VirtualVmxnet3',
      'vmxnet2'   => 'com.vmware.vc.VirtualVmxnet2',
      'e1000'     => 'com.vmware.vc.VirtualE1000',
      'e1000e'    => 'com.vmware.vc.VirtualE1000E',
      'sriov'     => 'com.vmware.vc.VirtualSriovEthernetCard',
      'fpt'       => 'com.vmware.vc.VirtualPCIPassthrough',
      'vlance'    => 'com.vmware.vc.VirtualPCNet32',
   };
   eval {
      $ethernetCard = CreateInlineObject($deviceClassHash->{lc($deviceType)});
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create inline object for " .
                       "device $deviceType");
      return FALSE;
   }
   return $ethernetCard;
}

########################################################################
#
# SetNetworkBacking --
#     Method to configure ethernet card's network backing
#
# Input:
#     ethernetCard : reference to object of
#                    com.vmware.vc.Virtual<deviceType>
#     pgObj        : reference to portgroup object
#
# Results:
#     TRUE, if backing info is updated on ethernetCard;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetNetworkBacking
{
   my $self          = shift;
   my $ethernetCard  = shift;
   my $pgObj         = shift;
   eval {
      my $backingInfo;
      if ($pgObj->{'type'} eq "standard") {
         $backingInfo = CreateInlineObject(
            "com.vmware.vc.VirtualEthernetCardNetworkBackingInfo");
         $backingInfo->setDeviceName($pgObj->{'name'});
      } elsif ($pgObj->{'type'} eq "nsx") {
         $backingInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo");
         $backingInfo->setOpaqueNetworkType("nsx.network");
         $backingInfo->setOpaqueNetworkId($pgObj->{'id'});
      } elsif ($pgObj->{'type'} eq "logicalSwitch") {
         $backingInfo = CreateInlineObject(
            "com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo");
         my $hostMOR =  $self->{vmObj}{vmObj}->getHost($self->{vmObj}{'vmMOR'});
         my $networkSystem = CreateInlineObject(
            "com.vmware.vcqa.vim.host.NetworkSystem",
            $self->{'anchor'});
         my $nsMOR =$networkSystem->getNetworkSystem($hostMOR);
         my $opaqueNetworkInfo = $networkSystem->getNetworkInfo(
            $nsMOR)->getOpaqueNetwork();

         my $opaqueNetworkType;
         my $opaqueNetworkId = undef;
         my $startTime = time();
         # XXX (gjayavelu/salmanm): Opaque network might take some time to be
         # pushed down to host, this loop will retry to fetch opaque network
         # depending on the configured params.
         while (time() - $startTime < OPAQUE_NETWORK_WAIT_TIME) {
            $vdLogger->Debug("Trying to find opaque network for lswitch");
            for (my $index=0; $index < $opaqueNetworkInfo->size(); $index++) {
               if ($opaqueNetworkInfo->get($index)->getOpaqueNetworkId() eq $pgObj->{id}) {
                  $opaqueNetworkId = $pgObj->{id};
                  $opaqueNetworkType = $opaqueNetworkInfo->get(
                     $index)->getOpaqueNetworkType();
                  last;
               }
            }
            if (defined $opaqueNetworkId) {
                last;
            }
            $vdLogger->Debug("Did not find the opaque network matching " .
                             "lswitch $pgObj->{id}, sleeping " .
                             SLEEP_BETWEEN_RETRIES ." seconds " .
                             "before retry ...");
            sleep SLEEP_BETWEEN_RETRIES;
         }
         if (not defined $opaqueNetworkId) {
            $vdLogger->Error("Could not find opaque network matching the " .
                             "logical switch id $pgObj->{id}");
            return FALSE;
         } else {
            $backingInfo->setOpaqueNetworkId($opaqueNetworkId);
            $backingInfo->setOpaqueNetworkType($opaqueNetworkType);
         }
      } elsif ($pgObj->{'type'} eq "vwire") {
         $backingInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo");
         my $dvsPortConnection = $pgObj->GetPortConnection(inlineJavaVMObj => $self->{vmObj});
         $backingInfo->setPort($dvsPortConnection);
      } else {
         $backingInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo");
         my $dvsPortConnection = $pgObj->GetPortConnection();
         $backingInfo->setPort($dvsPortConnection);
      }
      $ethernetCard->setBacking($backingInfo);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to configure networking backing");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# SetConnectionStatus --
#     Method to configure connection state of ethernet card
#
# Input:
#     ethernetCard : reference to object of
#                    com.vmware.vc.Virtual<deviceType>
#     connected         : 1/0
#     startConnected    : 1/0
#     allowGuestControl : 1/0
#
# Results:
#     TRUE, if connection state is updated on ethernetCard;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetConnectionStatus
{
   my $self                = shift;
   my $ethernetCard        = shift;
   my $connected           = shift;
   my $startConnected      = shift;
   my $allowGuestControl   = shift;

   my $reconfigure = 0;
   eval {
      my $connectionInfo = CreateInlineObject("com.vmware.vc.VirtualDeviceConnectInfo");
      if (defined $startConnected) {
         $connectionInfo->setStartConnected(int($startConnected));
         $reconfigure = 1;
      }
      if (defined $connected) {
         $connectionInfo->setConnected(int($connected));
         $reconfigure = 1;
      }
      if (defined $allowGuestControl) {
         $connectionInfo->setAllowGuestControl(int($allowGuestControl));
         $reconfigure = 1;
      }
      $ethernetCard->setConnectable($connectionInfo) if $reconfigure;
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to configure connection status");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# ConfigureNIOC --
#     Method to configure NIOC on the ethernet card
#
# Input:
#     ethernetCard : reference to object of
#                    com.vmware.vc.Virtual<deviceType>
#     reservation  : integer in Mbps
#     limit        : integer in Mbps
#     sharesLevel  : low/normal/high/custom
#     shares       : integer between 0-100
#
# Results:
#     TRUE, if nioc info is updated on ethernetCard;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureNIOC
{
   my $self        = shift;
   my $ethernetCard= shift;
   my $reservation = shift;
   my $limit       = shift;
   my $sharesLevel = shift;
   my $shares      = shift;

   $sharesLevel = (defined $shares) ? "custom" : "normal";
   my $reconfigure = 0;
   eval {
      my $niocInfo = CreateInlineObject("com.vmware.vc.VirtualEthernetCardResourceAllocation");
      if (defined $reservation) {
         $niocInfo->setReservation($reservation);
         $reconfigure = 1;
      }
      if (defined $limit) {
         $niocInfo->setLimit($limit);
         $reconfigure = 1;
      }
      my $sharesInfo = CreateInlineObject("com.vmware.vc.SharesInfo");

      LoadInlineJavaClass('com.vmware.vc.SharesLevel');
      my $sharesHash = {
         'low'    =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::LOW,
         'normal' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::NORMAL,
         'high'   =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::HIGH,
         'custom' =>
            $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::CUSTOM,
      };
      if (defined $sharesLevel) {
         $sharesInfo->setLevel($sharesHash->{lc($sharesLevel)});
         $sharesInfo->setShares($shares);
         $niocInfo->setShare($sharesInfo);
         $reconfigure = 1;
      }
      $ethernetCard->setResourceAllocation($niocInfo) if $reconfigure;
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to configure NIOC");
      return FALSE;
   }
   return TRUE;
}

########################################################################
#
# ConfigurePassthru --
#     Method to configure passthrough backing info on the ethernet card,
#     which is used by both ConfigureSRIOV and ConfigureFPT
#
# Input:
#     ethernetCard : reference to object of
#                    com.vmware.vc.Virtual<deviceType>
#     deviceId     : device id
#     id           : The name ID of this PCI, composed of "bus:slot.function"
#     systemId     : The ID of the system the PCI device is attached to
#     vendorId     : The vendor ID for this PCI device
#
# Results:
#     backinginfo struct and changed;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigurePassthru
{
   my $self         = shift;
   my $ethernetCard = shift;
   my $deviceId     = shift;
   my $id           = shift;
   my $deviceName   = shift;
   my $systemId     = shift;
   my $vendorId     = shift;
   my $changed      = 0;
   my $devBackingInfo;

   # Get the deviceId, id etc of the vmnic

   eval {
      $devBackingInfo = CreateInlineObject("com.vmware.vc.VirtualPCIPassthroughDeviceBackingInfo");
      if (defined $deviceId) {
         $vdLogger->Debug("Device Id is $deviceId");
         $devBackingInfo->setDeviceId($deviceId);
         $changed = 1;
      }
      if (defined $deviceName) {
         $vdLogger->Debug("Device name is $deviceName");
         $devBackingInfo->setDeviceName($deviceName);
         $changed = 1;
      }
      if (defined $id) {
         $vdLogger->Debug("Id is $id");
         $devBackingInfo->setId($id);
         $changed = 1;
         #Save the PCI ID for mapping from PCI ID to MAC in InitializeVnicInterface
         $self->{"pciId"} = $id;
      }
      if (defined $systemId) {
         $vdLogger->Debug("System Id is $systemId");
         $devBackingInfo->setSystemId($systemId);
         $changed = 1;
      }
      if (defined $vendorId) {
         $vdLogger->Debug("Convert vendor ID($vendorId) from hex to decimal due to PR#1034974");
         $vendorId = unpack('s', pack('S', hex($vendorId)));
         $vdLogger->Debug("Vendor Id is $vendorId");
         $devBackingInfo->setVendorId($vendorId);
         $changed = 1;
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to configure SRIOV");
      return FALSE;
   }
   if ($changed){
      return $devBackingInfo;
   } else {
      return undef;
   }
}

########################################################################
#
# ConfigureSRIOV --
#     Method to configure SRIOV on the ethernet card
#
# Input:
#     ethernetCard : reference to object of
#                    com.vmware.vc.Virtual<deviceType>
#     deviceId     : device id
#     id           : The name ID of this PCI, composed of "bus:slot.function"
#     deviceName   : The name of the device
#     systemId     : The ID of the system the PCI device is attached to
#     vendorId     : The vendor ID for this PCI device
#
# Results:
#     TRUE, if SRIOV info is updated on ethernetCard;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureSRIOV
{
   my $self         = shift;
   my $ethernetCard = shift;
   my $deviceId     = shift;
   my $id           = shift;
   my $deviceName   = shift;
   my $systemId     = shift;
   my $vendorId     = shift;
   my $devBackingInfo;

   eval {
      $devBackingInfo = $self->ConfigurePassthru($ethernetCard,
                            $deviceId,
                            $id,
                            $deviceName,
                            $systemId,
                            $vendorId,
                            );
      my $sriovBackingInfo =
      CreateInlineObject("com.vmware.vc.VirtualSriovEthernetCardSriovBackingInfo");
      if ($devBackingInfo) {
         $sriovBackingInfo->setPhysicalFunctionBacking($devBackingInfo);
         $ethernetCard->setSriovBacking($sriovBackingInfo);
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to configure SRIOV");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# ConfigureFPT --
#     Method to configure FPT on the ethernet card
#
# Input:
#     ethernetCard : reference to object of
#                    com.vmware.vc.Virtual<deviceType>
#     deviceId     : device id
#     id           : The name ID of this PCI, composed of "bus:slot.function"
#     deviceName   : The name of the device
#     systemId     : The ID of the system the PCI device is attached to
#     vendorId     : The vendor ID for this PCI device
#
# Results:
#     TRUE, if SRIOV info is updated on ethernetCard;
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureFPT
{
   my $self         = shift;
   my $ethernetCard = shift;
   my $deviceId     = shift;
   my $id           = shift;
   my $deviceName   = shift;
   my $systemId     = shift;
   my $vendorId     = shift;
   my $devBackingInfo;

   eval {
      $devBackingInfo = $self->ConfigurePassthru($ethernetCard,
                            $deviceId,
                            $id,
                            $deviceName,
                            $systemId,
                            $vendorId,
                            );
      if ($devBackingInfo) {
         $ethernetCard->setBacking($devBackingInfo);
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to configure FPT");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# GetMACAddress --
#     Method to get the mac address
#
# Input:
#
# Results:
#     Return the mac address
#     FALSE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetMACAddress
{
   my $self = shift;
   my $macAddress;

   eval {
       my $ethernetCardSpec = $self->GetEthernetCardSpecFromLabel();
       if ($ethernetCardSpec == FALSE) {
          $vdLogger->Error("Did not find ethernet card spec with label " .
                           $self->{'deviceLabel'});
          return FALSE;
       }
       $self->{ethernetCardSpec} = $ethernetCardSpec;
       $macAddress = $self->{ethernetCardSpec}->getDevice()->getMacAddress();
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get mac address " . Dumper($@));
      return FALSE;
   }
   return $macAddress;
}


########################################################################
#
# GetUUID --
#     Method to get UUID of Vnic
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

sub GetUUID
{
   my $self = shift;
   my $vmObj = $self->{'vmObj'};

   my $uuid;
   eval {
      $uuid = $vmObj->GetInstanceUUID();
      my $label = $1 if ($self->{'deviceLabel'} =~ /(\d+)$/);
      $label = int($label)-1;
      $uuid .= "-$label";
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Debug("Failed to get Vnic UUID");
      return FALSE;
   }
   return $uuid;
}
1;
