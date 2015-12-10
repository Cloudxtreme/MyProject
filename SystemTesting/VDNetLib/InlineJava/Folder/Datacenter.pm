###############################################################################
# Copyright (C) 2013 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::Folder::Datacenter;

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
                                            InlineExceptionHandler
                                            NewDataHandler);


use constant TRUE  => 1;
use constant FALSE => 0;
my %INLINELIB = (
   vcqa => "VDNetLib::InlineJava::VDNetInterface::com::vmware::vcqa",
   vc => "VDNetLib::InlineJava::VDNetInterface::com::vmware::vc",
);

########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::Folder::Datacenter
#
# Input:
#     folderObj      : reference to VDNetLib::InlineJava::Folder
#     deviceLabel: device label, for example "Network Adapter "
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
   $self->{'folderObj'} = $options{'folderObj'};
   $self->{'datacenterName'} = $options{'datacenterName'};
   $self->{'anchor'}    = $self->{'folderObj'}{'anchor'};

   eval {
      $self->{'datacenterObj'} = CreateInlineObject(
					"com.vmware.vcqa.vim.Datacenter",
					$self->{'anchor'});
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::Folder::" .
		       "Datacenter obj");
      return FALSE;
   }

   $self->{'datacenterMor'} = $self->{'folderObj'}->GetDataCenterMor(
						$self->{'datacenterName'});
   $self->{'hostFolderMor'} = $self->{'datacenterObj'}->getHostFolder(
						$self->{'datacenterMor'});
   bless $self, $class;

   return $self;
}


########################################################################
#
# CreateCluster--
#     Method to create a new compute resource in this datacenter for a
#     cluster of hosts.
#
# Input:
#     Named value parameters with following keys:
#     clusterSpecHash   : ClusterSpecification (Mandtory)
#			{
#                             clustername => "cluster1",
#                             ha => 1/0,
#                             drs => 1/0,
#			      failoverlevel => 0-31,
#			      admissioncontrol => 0/1,
#			}
#
# Results:
#     cluster Mor, if cluster created successfully;
#     FALSE, if cluster creation fails;
#
# Side effects:
#     None
#
########################################################################

sub CreateCluster
{
   my $self = shift;
   my $clusterSpecHash = shift;

   my $parentFolderMor = $self->{'hostFolderMor'};

   if (not defined $clusterSpecHash) {
      $vdLogger->Error("ClusterSpecHash is missing.");
      return FALSE;
   }
   my $clusterMor; # value need to be return
   my $clusterSpecEx; # Spec variable for configuring cluster
   my $clusterName    = $clusterSpecHash->{'clustername'} || $clusterSpecHash->{'name'};
   my $haRuleEnabled  = $clusterSpecHash->{'ha'};
   my $vsanEnabled    = $clusterSpecHash->{'vsan'};
   my $autoClaimStorage = $clusterSpecHash->{'autoclaimstorage'};
   my $admissionEnabled = $clusterSpecHash->{'admissioncontrol'};
   my $failOverLevel  = $clusterSpecHash->{'failoverlevel'};
   my $drsRuleEnabled = $clusterSpecHash->{'drs'};
   LoadInlineJavaClass('com.vmware.vc.DrsBehavior');
   my $drsVmBehaviour = $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::DrsBehavior::FULLY_AUTOMATED;
   LoadInlineJavaClass('com.vmware.vcqa.TestConstants');
   my $vmotionRate = $VDNetLib::InlineJava::VDNetInterface::com::vmware::vcqa::TestConstants::DRS_NORMAL_VMOTIONRATE;
   eval {
      #
      # Create cluster spec java object and modify it
      #
      my $folderObj = $self->{'folderObj'}{'folderObj'};
      $clusterMor = $folderObj->getClusterByName($clusterName, $self->{'datacenterMor'});
      if ($clusterMor) {
         $vdLogger->Debug("Cluster $clusterName already exists, return directly");
         return $clusterMor;
      }
      $admissionEnabled = ($admissionEnabled) ? $admissionEnabled : 1;
      $failOverLevel = ($failOverLevel) ? $failOverLevel : 1;
      my $dasSpec = undef;
      my $drsSpec = undef;
      $haRuleEnabled = ($haRuleEnabled) ? $haRuleEnabled : 0;
      if ($haRuleEnabled == 1) {
         $dasSpec = $folderObj->createDASConfigInfo($admissionEnabled,
						    $haRuleEnabled,
						    $failOverLevel);
      }
      $drsRuleEnabled = ($drsRuleEnabled) ? $drsRuleEnabled : 0;
      if ($drsRuleEnabled == 1) {
         $drsSpec = $folderObj->createDRSInfo($drsVmBehaviour,
					      $drsRuleEnabled,
					      $vmotionRate);
      }
      $clusterSpecEx = $folderObj->createClusterSpec($dasSpec,
                                                      undef,
                                                      $drsSpec,
                                                      undef,
                                                      undef,
                                                      undef,
                                                      undef);
      #
      # VSAN configuration
      #
      $vsanEnabled = ($vsanEnabled) ? $vsanEnabled: 0;
      $autoClaimStorage = ($autoClaimStorage) ? $autoClaimStorage: 0;
      if (($vsanEnabled == 1) || ($autoClaimStorage == 1)) {
	 my $isAutoClaimStorage = $autoClaimStorage;
	 my $isVsanServiceEnabled = $vsanEnabled;
         my $clusterComputeResource = CreateInlineObject(
                      'com.vmware.vcqa.vim.ClusterComputeResource', $self->{anchor});
	 my $vsanClusterConfigInfo =
	 $clusterComputeResource->initializeVsanClusterConfigInfo($isAutoClaimStorage,
                                                                  undef,
		                                                  $isVsanServiceEnabled);
	 $clusterSpecEx->setVsanConfig($vsanClusterConfigInfo);
      }

      $clusterMor = $folderObj->createClusterEx($parentFolderMor,
                                                $clusterName,
                                                $clusterSpecEx);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while while creating cluster.");
      return FALSE;
   }

   return $clusterMor;
}


########################################################################
#
# ImportVDSConfig--
#     Method to import the specified VDS configuration from a
#     backup file using ImportEntity() method.
#
# Input:
#     importType   :  Type of Import (createEntityWithNewIdentifier or
#                                     createEntityWithOriginalIdentifier)
#
# Results:
#     Returns VDS Name, if import configuration operation is successful
#     FALSE in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ImportVDSConfig
{
   my $self	   = shift;
   my $importType  = shift;
   my $result	   = FALSE;

   my $logDir	   = VDNetLib::Common::GlobalConfig::GetLogsDir();
   my $vdsFileName = $logDir . "vdsCfg.bkp";

   my $vcanchor    = $self->{'anchor'};
   my $folderObj   = $self->{'folderObj'};
   my $idvsManager = undef;
   my $dvsName	   = undef;

   eval {
      $idvsManager = CreateInlineObject(
			"com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager",
			$self->{'anchor'});

      if ($importType =~ m/Orig/i) {
         $importType = "createEntityWithOriginalIdentifier";
      } else {
         $importType = "createEntityWithNewIdentifier";
      }

      my $entityName = VDNetLib::Common::Utilities::GenerateName("vds", "99");
      my $entityType = "distributedVirtualSwitch";

      my $datacenterMOR	   = $self->{'folderObj'}->GetDataCenterMor(
						$self->{'datacenterName'});
      my $networkFolderMOR = $self->{'folderObj'}{'folderObj'}->getNetworkFolder(
						$datacenterMOR);

      # Create objects to read VDS config from the file.
      my $backupConfig = [];
      $backupConfig->[0] = CreateInlineObject(
					"com.vmware.vc.EntityBackupConfig");

      if ($importType =~ m/^createEntityWithNewIdentifier$/i) {
         $backupConfig->[0]->setName($entityName);
      }

      $backupConfig->[0]->setName($entityName);
      $backupConfig->[0]->setEntityType($entityType);
      $backupConfig->[0]->setContainer($networkFolderMOR);

      # Read the VDS / dvPortGroup configuration from the file.
      my $spec;
      $result = open(INF, $vdsFileName);
      if (not defined $result) {
         $vdLogger->Error("Unable to open the $vdsFileName");
         return FALSE;
      }
      binmode INF;
      my $fileSize = -s $vdsFileName;
      read(INF, $spec, $fileSize);
      #
      # unpack with c* - encode the given input to bytes[]
      # because setConfigBlob expects byte-array.
      #
      my @arr = unpack("c*", $spec);
      $backupConfig->[0]->setConfigBlob(\@arr);
      close(INF);

      # Get DVS MOR for importEntity operation.
      my $dvsManagerMor = $idvsManager->getDvSwitchManager();

      # Call importEntity() method.
      $result	 = $idvsManager->importEntity($dvsManagerMor, $backupConfig, $importType);

      my $dvsMor = $result->getDistributedVirtualSwitch();
      $dvsMor	 = $dvsMor->get("0");

      $dvsName	 = $idvsManager->getName($dvsMor);
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while executing ImportVDSConfig() method");
      return FALSE;
   }

   return $dvsName;
}


#############################################################################
#
# GetMORId--
#     Method to get datacenter Managed Object ID (MOID)
#
# Input:
#
# Results:
#	datacenter MORId, of the dataceneter
#	False, in case of any error
#
#
# Side effects:
#     None
#
########################################################################

sub GetMORId
{
   my $self   = shift;
   my $MORId;
   eval {
      $MORId = $self->{datacenterMor}->getValue();
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the datacenter MOR Id " .
                       "of $self->{name}");
      return FALSE;
   }
   return $MORId;
}

1;
