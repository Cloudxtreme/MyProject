###############################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::InlineLAG;

#
# This class captures all inline Java related LACP LAG code
#

use strict;
use warnings;
use Data::Dumper;
#
# Inherit the parent class LAG.
# we write non inlineLAG related code in the abstract layer VDSwitch::LAG
# and write inline APIs in this package
#
use base qw(VDNetLib::Switch::VDSwitch::LAG);


#
# Importing only vdLogger for now and nothing else to keep this package
# re-usable for frameworks/tools other than VDNet
#
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass
                                            CreateInlineObject
                                            InlineExceptionHandler);

use constant TRUE  => 1;
use constant FALSE => 0;

########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::InlineLAG
#
# Input:
#
# Results:
#     An object of VDNetLib::InlineJava::InlineLAG class
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class     = shift;
   my %args       = @_;
   my $self = VDNetLib::Switch::VDSwitch::LAG->new(%args);
   if ($self eq "FAILURE") {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::InlineLAG" .
                       " object");
      VDSetLastError(VDGetLastError());
      return FALSE;
   }
   eval {
      $self->{lacpgroupconfig} =
          CreateInlineObject("com.vmware.vc.VMwareDvsLacpGroupConfig");
   };

   if ($@) {
      $vdLogger->Error("Fail to create obj of ".
                       "VDNetLib::InlineJava::Inline");
      InlineExceptionHandler($@);
      return FALSE;
   }
   bless($self, $class);

   return $self;
}


#######################################################################
#
# SetLagName--
#      To set lag name on the inline java lag obj
#
# Input:
#      name: name of this lag
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetLagName
{
   my $self = shift;
   my $spec = shift;
   my $lagName = shift;
   eval {
      $spec->setName($lagName);
   };

   if ($@) {
      $vdLogger->Error("Fail to set new lagname on " . $self->{lagname});
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


#######################################################################
#
# SetLagMode--
#      To set lag mode on the inline java lag obj
#
# Input:
#      mode: mode of this lag
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetLagMode
{
   my $self = shift;
   my $spec = shift;
   my $lagMode = shift;

   if ($self->{lacpversion} =~ /multiplelag/i) {
      eval {
         $spec->setMode($lagMode);
      };

      if ($@) {
         $vdLogger->Error("Fail to set lagmode " . $self->{lagname});
         InlineExceptionHandler($@);
         return FALSE;
      }
   } else {
      $vdLogger->Error("Not YET IMPLEMENTED ");
   }
   return TRUE;
}


#######################################################################
#
# SetLagPorts--
#      To set lag ports on the inline java lag obj
#
# Input:
#      ports: number of ports in this lag
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetLagPorts
{
   my $self = shift;
   my $spec = shift;
   my $lagPorts = shift;
   eval {
      $spec->setUplinkNum($lagPorts);
   };

   if ($@) {
      $vdLogger->Error("Fail to set lagports on " . $self->{lagname});
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


#######################################################################
#
# SetLagLoadbalancing--
#      To set lag loadbalancing on the inline java lag obj
#
# Input:
#      loadbalancing: any of the supported load balancing algorithms
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetLagLoadbalancing
{
   my $self = shift;
   my $spec = shift;
   my $lagLoadbalancing = shift;
   #
   # Check supported values should have been performed as the Workload
   # level so no need to do the check here.
   #
   eval {
      $spec->setLoadbalanceAlgorithm($lagLoadbalancing);
   };

   if ($@) {
      $vdLogger->Error("Fail to set loadbalancing on " . $self->{lagname});
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


#######################################################################
#
# SetLagIdInSpec--
#      To set lag id on the inline java lag obj
#
# Input:
#      id: ID of this lag
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetLagIdInSpec
{
   my $self = shift;
   my $spec = shift;
   my $lagId = shift;
   #
   # Check supported values should have been performed as the Workload
   # level so no need to do the check here.
   #
   eval {
      $spec->setKey($lagId);
   };

   if ($@) {
      $vdLogger->Error("Fail to set LagId on " . $self->{lagname});
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}

#######################################################################
#
# SetLagVlanConfig--
#      To set vlan configuration on this lag
#
# Input:
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetLagVlanConfig
{
   $vdLogger->Error("Not YET IMPLEMENTED ");
   return TRUE;
}


#######################################################################
#
# SetLagIpfixConfig--
#      To set netflow/ipfix configuration on this lag
#
# Input:
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetLagIpfixConfig
{
   $vdLogger->Error("Not YET IMPLEMENTED ");
   return TRUE;
}


#######################################################################
#
# GetLACPGroupConfig--
#      To get inline java lag obj for this vdnet lag obj
#
# Input:
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub GetLACPGroupConfig
{
   my $self = shift;
   my $spec;
   eval {
      $spec = CreateInlineObject("com.vmware.vc.VMwareDvsLacpGroupConfig");
   };
   $self->SetAllInlineParams($spec);
   return $spec;
}


#######################################################################
#
# SetAllInlineParams--
#      To set all inline java params in inline java class for lag
#
# Input:
#      All vars which are set in $self
#
# Results:
#
# Side effects:
#      None
#
#######################################################################

sub SetAllInlineParams
{
   my $self = shift;
   my $spec = shift;
   $self->SetLagName($spec, $self->{lagname}) if defined $self->{lagname};
   $self->SetLagMode($spec, $self->{lagmode}) if defined $self->{lagmode};
   $self->SetLagPorts($spec, $self->{lagports}) if defined $self->{lagports};
   $self->SetLagLoadbalancing($spec, $self->{lagloadbalancing})
                                   if defined $self->{lagloadbalancing};
   $self->SetLagIdInSpec($spec, $self->{lagId})
                                   if defined $self->{lagId};
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# AddUplinkToLag
#      This method add unplinks to a link aggregation group on VDS
#
# Input:
#      refArrHostVmnicMapping -  inline host obj and vmnic names mapping
#                               (mandatory)
#
# Results:
#      "TRUE", if uplinks were added to a lag successfully
#      "FALSE", in case of any error,
#
# Side effects:
#
########################################################################

sub AddUplinkToLag
{
   my $self = shift;
   my $refArrHostVmnicMapping = shift;

   my $inlineDVSObj = $self->{switchObj}->GetInlineDVS();
   my $anchor = $inlineDVSObj->{anchor};
   my $dvsHelper = $inlineDVSObj->{'dvsHelper'};
   my $dvsMor = $inlineDVSObj->{'dvsMOR'};
   my $lagName = $self->{lagname};
   my $lagkey;

   if (not defined $refArrHostVmnicMapping) {
      $vdLogger->Error("Reference to host missing");
      return FALSE;
   }

   eval {
      LoadInlineJavaClass('com.vmware.vcqa.TestConstants');
      LoadInlineJavaClass('com.vmware.vc.HostConfigChangeOperation');
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      my $hostSystem = CreateInlineObject("com.vmware.vcqa.vim.HostSystem",$anchor);
      my $ins = CreateInlineObject("com.vmware.vcqa.vim.host.NetworkSystem",$anchor);
      my $updatedNetworkConfig = CreateInlineObject("com.vmware.vc.HostNetworkConfig");
      my $hostProxySwitchConfigArray = [];

      foreach my $hostVmnicMapping (@$refArrHostVmnicMapping) {
         my $inlineHostObject = $hostVmnicMapping->{inlineHostObj};
         my $hostMor = $inlineHostObject->{hostMOR};
         my $hostNetworkSystem = $hostSystem->getHostConfigManager($hostMor)->getNetworkSystem();
         my $originalHostProxySwitchConfig = $dvsHelper->getDVSVswitchProxyOnHost($dvsMor,$hostMor);
         my $updatedHostProxySwitchConfig = $util->deepCopyObject($originalHostProxySwitchConfig);
         $updatedHostProxySwitchConfig->setChangeOperation($VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::HostConfigChangeOperation::EDIT->value());
         my $pnicBacking = $updatedHostProxySwitchConfig->getSpec()->getBacking();
         my $pnicSpecArray = [];
         my $pnicIndex = 0;

         my $lagPortsInfo = $self->GetLagPortsInfo($inlineHostObject);
         if ($lagPortsInfo == FALSE ) {
            $vdLogger->Error("GetLagPortsInfo failed, returned FALSE");
            return FALSE;
         }

         my $freePorts = $lagPortsInfo->{freePorts};
         my $initialPnicSpec = $lagPortsInfo->{initialPnicSpec};

         if (scalar(@$freePorts) == 0) {
            $vdLogger->Error("AddUplinkToLag failed. No free lag port available".
                             " for $inlineHostObject->{host}.");
            return FALSE;
         }

         foreach my $vmnic (@{$hostVmnicMapping->{vmnicNames}}) {
            # If the vmnic has been connected to another port, remove it.
            for (my $i= 0; $i < $initialPnicSpec->size(); $i++) {
               my $vmnicName = $initialPnicSpec->get($i)->getPnicDevice();
               if ((defined $vmnicName) && ($vmnicName eq $vmnic)) {
                  $initialPnicSpec->remove($i);
                  $vdLogger->Debug("Move $vmnic of $inlineHostObject->{host}".
                       " from where it is to lag $lagName...");
               }
            }

            $lagkey = $freePorts->[0];
            shift @$freePorts;

            my $pnicSpec = CreateInlineObject(
                    "com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec");
            $pnicSpec->setPnicDevice($vmnic);
            $pnicSpec->setUplinkPortKey($lagkey);
            $pnicSpecArray->[$pnicIndex] = $pnicSpec;
            $pnicIndex++;
            $vdLogger->Debug("Add uplink $vmnic to" .
                       " lag $lagName port $lagkey...");
         }

         # Combine pnics to add and pnics already added.
         for (my $i= 0; $i < $initialPnicSpec->size(); $i++) {
            push @$pnicSpecArray, $initialPnicSpec->get($i);
         }

         $pnicBacking->getPnicSpec()->clear();
         $pnicBacking->getPnicSpec()->addAll($util->arrayToVector($pnicSpecArray));

         $updatedHostProxySwitchConfig->getSpec()->setBacking($pnicBacking);
         $hostProxySwitchConfigArray->[0] = $updatedHostProxySwitchConfig;

         $updatedNetworkConfig->getProxySwitch()->clear();
         $updatedNetworkConfig->getProxySwitch()->addAll($util->arrayToVector($hostProxySwitchConfigArray));
         $ins->updateNetworkConfig($hostNetworkSystem, $updatedNetworkConfig,
               $VDNetLib::InlineJava::VDNetInterface::com::vmware::vcqa::TestConstants::CHANGEMODE_MODIFY);
         $vdLogger->Debug("Add uplinks of $inlineHostObject->{host} to" .
                       " lag $lagName...");
      }
   };

   if ($@) {
      $vdLogger->Error("AddUplinkToLag for $lagName failed");
      InlineExceptionHandler($@);
      return FALSE;
   }

   $vdLogger->Info("Successfully added uplinks to lag $lagName");
   return TRUE;
}


########################################################################
#
# RemoveUplinkFromLag
#      This method remove unplinks from a link aggregation group on VDS
#
# Input:
#      refArrHostVmnicMapping -  inline host obj and vmnic names mapping
#                               (mandatory)
#
# Results:
#      "TRUE", if uplinks were removed from a lag successfully
#      "FALSE", in case of any error,
#
# Side effects:
#
########################################################################

sub RemoveUplinkFromLag
{
   my $self = shift;
   my $refArrHostVmnicMapping = shift;

   my $inlineDVSObj = $self->{switchObj}->GetInlineDVS();
   my $anchor = $inlineDVSObj->{anchor};
   my $dvsHelper = $inlineDVSObj->{'dvsHelper'};
   my $dvsMor = $inlineDVSObj->{'dvsMOR'};
   my $lagName = $self->{lagname};
   my $util;
   my $lagkey;

   if (not defined $refArrHostVmnicMapping) {
      $vdLogger->Error("Reference to host missing");
      return FALSE;
   }

   eval {
      LoadInlineJavaClass('com.vmware.vcqa.TestConstants');
      LoadInlineJavaClass('com.vmware.vc.HostConfigChangeOperation');
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      my $hostSystem = CreateInlineObject("com.vmware.vcqa.vim.HostSystem",$anchor);
      my $ins = CreateInlineObject("com.vmware.vcqa.vim.host.NetworkSystem",$anchor);
      my $updatedNetworkConfig = CreateInlineObject("com.vmware.vc.HostNetworkConfig");
      my $hostProxySwitchConfigArray = [];
      my $pnicBacking = CreateInlineObject(
              "com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking");

      foreach my $hostVmnicMapping (@$refArrHostVmnicMapping) {
         my $inlineHostObject = $hostVmnicMapping->{inlineHostObj};
         my $hostMor = $inlineHostObject->{hostMOR};
         my $hostNetworkSystem = $hostSystem->getHostConfigManager($hostMor)->getNetworkSystem();
         my $originalHostProxySwitchConfig = $dvsHelper->getDVSVswitchProxyOnHost($dvsMor,$hostMor);
         my $updatedHostProxySwitchConfig = $util->deepCopyObject($originalHostProxySwitchConfig);
         $updatedHostProxySwitchConfig->setChangeOperation($VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::HostConfigChangeOperation::EDIT->value());
         my $pnicBacking = $updatedHostProxySwitchConfig->getSpec()->getBacking();

         my $lagPortsInfo = $self->GetLagPortsInfo($inlineHostObject);
         if ($lagPortsInfo == FALSE ) {
            $vdLogger->Error("GetLagPortsInfo failed, returned FALSE");
            return FALSE;
         }

         my $pnicSpecArray = $lagPortsInfo->{initialPnicSpec};

         foreach my $vmnic (@{$hostVmnicMapping->{vmnicNames}}) {
            for (my $i= 0; $i < $pnicSpecArray->size(); $i++) {
               my $pnicSpec = CreateInlineObject(
                    "com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec");
               $pnicSpec = $pnicSpecArray->get($i);
               my $vmnicName = $pnicSpec->getPnicDevice();
               if ($vmnicName eq $vmnic) {
                  $pnicSpecArray->remove($i);
                  $vdLogger->Debug("Remove $vmnic of $inlineHostObject->{host}".
                       " from lag $lagName...");
               }
            }
         }

         $pnicBacking->getPnicSpec()->clear();
         $pnicBacking->getPnicSpec()->addAll($pnicSpecArray);

         $updatedHostProxySwitchConfig->getSpec()->setBacking($pnicBacking);
         $hostProxySwitchConfigArray->[0] = $updatedHostProxySwitchConfig;

         $updatedNetworkConfig->getProxySwitch()->clear();
         $updatedNetworkConfig->getProxySwitch()->addAll($util->arrayToVector($hostProxySwitchConfigArray));
         $ins->updateNetworkConfig($hostNetworkSystem, $updatedNetworkConfig,
               $VDNetLib::InlineJava::VDNetInterface::com::vmware::vcqa::TestConstants::CHANGEMODE_MODIFY);
         $vdLogger->Debug("Remove uplinks of $inlineHostObject->{host} from" .
                       " lag $lagName...");
      }
   };

   if ($@) {
      $vdLogger->Error("RemoveUplinkFromLag for $lagName failed");
      InlineExceptionHandler($@);
      return FALSE;
   }

   $vdLogger->Info("Successfully removed uplinks from lag $lagName");
   return TRUE;
}


########################################################################
#
# GetLagPortsInfo
#      This method get free lag ports and initial pnicSpec for host
#
# Input:
#      inlineHostObj - inline host object (mandatory)
#
# Results:
#      Reference to hash containing following keys
#                        initialPnicSpec => {
#                           \@initialpNicSpec
#                        },
#                        freePorts => {
#                           \@freePortIdArray
#                        },
#
# Side effects:
#
########################################################################

sub GetLagPortsInfo
{
   my $self = shift;
   my $inlineHostObject = shift;
   my $lagObjectKey = $self->{lagId};
   my $inlineDVSObj = $self->{switchObj}->GetInlineDVS();
   my $anchor = $inlineDVSObj->{anchor};
   my $lagDvsName = $inlineDVSObj->{dvsName};
   my $dvsMor = $inlineDVSObj->{'dvsMOR'};
   my $dvs = $inlineDVSObj->{'dvs'};

   my @portIdArray = ();
   my @occupiedPortIdArray = ();
   my @freePortIdArray = ();
   my $initialpNicSpecList = [];
   my %returnHash;

   eval {
      my $hostMor = $inlineHostObject->{hostMOR};
      my $hostSystem = CreateInlineObject("com.vmware.vcqa.vim.HostSystem",$anchor);
      my $ins = CreateInlineObject("com.vmware.vcqa.vim.host.NetworkSystem",$anchor);
      my $hostNetworkSystem = $hostSystem->getHostConfigManager($hostMor)->getNetworkSystem();
      my $util = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
      my $hostProxySwitchList = $util->vectorToArray($ins->getNetworkInfo(
                                      $hostNetworkSystem)->getProxySwitch());

      my $dvsConfigInfo = $dvs->getConfig($dvsMor);
      my $hostMemberArray = $util->vectorToArray($dvsConfigInfo->getHost());
      my $hostMember;
      foreach my $host (@$hostMemberArray) {
         if ($host->getConfig()->getHost()->equals($hostMor)) {
            $hostMember = $host;
         }
      }

      foreach my $hostPS (@$hostProxySwitchList) {
         # find the correct dvs
         my $dvsName = $hostPS->getDvsName();
         if ($dvsName ne $lagDvsName) {
            next;
         }
         my $lagList = $hostPS->getHostLag();
         my $numOfLags = $lagList->size();
         if ($numOfLags == 0) {
            $vdLogger->Error("There is no lags found on host ".
                             "$inlineHostObject->{host}");
            return FALSE;
         }
         for (my $i= 0; $i < $numOfLags; $i++) {
            # find the correct lag
            my $hostLagConfig = $lagList->get($i);
            my $groupKey = $hostLagConfig->getLagKey();
            if ($groupKey != $lagObjectKey) {
               next;
            }

            my $hostMemberPnicBacking = $hostMember->getConfig()->getBacking();
            $initialpNicSpecList = $hostMemberPnicBacking->getPnicSpec();

            # get occupied lag ports on the host
            for (my $j= 0; $j < $initialpNicSpecList->size(); $j++) {
               my $pNicSpec = $initialpNicSpecList->get($j);
               push @occupiedPortIdArray, $pNicSpec->getUplinkPortKey();
            }

            # get all lag ports on the host
            my $keyValueList = $hostLagConfig->getUplinkPort();
            for (my $k= 0; $k < $keyValueList->size(); $k++) {
               my $portid = $keyValueList->get($k)->getKey();
               push @portIdArray, $portid;
            }
         }
      }

      # get free lag ports on the host
      foreach my $port (@portIdArray) {
         my $i = 0;
         foreach (@occupiedPortIdArray) {
            if ($_ eq $port) {
               $i = 1;
            }
         }
         if ($i == 0) {
            push @freePortIdArray, $port;
         }
      }
      $vdLogger->Debug("Free ports of $self->{lagname} for ".
                       "$inlineHostObject->{host}:\n". Dumper(@freePortIdArray));

      $returnHash{initialPnicSpec} = $initialpNicSpecList;
      $returnHash{freePorts} = \@freePortIdArray;
   };

   if ($@) {
      $vdLogger->Error("GetLagPortsInfo for $self->{lagname} and ".
                       "$inlineHostObject->{host} failed");
      InlineExceptionHandler($@);
      return FALSE;
   }

   return \%returnHash;
}

1;
