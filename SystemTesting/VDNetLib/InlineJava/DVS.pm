###############################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

package VDNetLib::InlineJava::DVS;

#
# This class captures all common methods to configure or get information
# from a DVS. This package mainly uses VDNetLib::InlineJava::VDNetInterface
# class to interact with DVS.
#
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Inline::Java qw(cast coerce);

#
# Define constants for java classes.
#
use constant FILE_OUTPUT_STREAM            => 'java.io.FileOutputStream';
use constant FILE_INPUT_STREAM             => 'java.io.FileInputStream';
use constant FILE_DATA_SOURCE              => 'javax.activation.FileDataSource';
#use constant DATA_HANDLER                  => 'javax.activation.DataHandler';

use constant DVS_SELECTION                 => 'com.vmware.vc.DVSSelection';
use constant DVS_PORTGROUP_SELECTION       => 'com.vmware.vc.DVPortgroupSelection';
use constant ENTITY_BACKUP_CONFIG          => 'com.vmware.vc.EntityBackupConfig';

use constant DISTRIBUTED_VIRTUAL_SWITCH    => 'com.vmware.vcqa.vim.DistributedVirtualSwitch';
use constant DISTRIBUTED_VIRTUAL_PORTGROUP => 'com.vmware.vcqa.vim.DistributedVirtualPortgroup';
use constant DISTRIBUTED_VIRTUAL_SWITCH_MANAGER => 'com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager';
use constant PORT_CRITERIA => 'com.vmware.vc.DistributedVirtualSwitchPortCriteria';
#
# Importing only vdLogger for now and nothing else to keep this package
# re-usable for frameworks/tools other than VDNet
#
use VDNetLib::Common::GlobalConfig qw ($vdLogger);

use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass
                                            CreateInlineObject
                                            InlineExceptionHandler);
use constant TRUE  => 1;
use constant FALSE => 0;
use constant DVSSELECTION => 'com.vmware.vc.DVSSelection';
use constant DVPGCONFIGSPEC => 'com.vmware.vc.DVPortgroupConfigSpec';
use constant DVPORT_SELECTION => 'com.vmware.vc.DVPortSelection';
use constant MANAGEDOBJREF  => 'com.vmware.vc.ManagedObjectReference';
use constant INTERNALDVSMGR  =>
     'com.vmware.vcqa.internal.vim.dvs.InternalDistributedVirtualSwitchManager';
########################################################################
#
# new--
#     Constructor for class VDNetLib::InlineJava::DVS
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
   $self->{'anchor'}        = $options{'anchor'};
   $self->{'datacenter'}    = $options{'datacenter'};
   $self->{'dvsName'}       = $options{'dvsName'};

   if ((not defined $self->{'anchor'}) ||
      (not defined $self->{'datacenter'}) ||
      (not defined $self->{'dvsName'})) {
      $vdLogger->Error("Anchor and/or datacenter and/or dvsName not provided");
      return FALSE;
   }

   $self->{'folderObj'}        = $options{'folderObj'};
   $self->{'datacenterMOR'}    = $options{'datacenterMOR'};
   $self->{'networkFolderMOR'} = $options{'networkFolderMOR'};
   $self->{'dvsConfigSpec'}    = $options{'dvsConfigSpec'};
   $self->{'dvsMOR'}           = $options{'dvsMOR'};
   $self->{'dvs'}              = $options{'dvs'};
   $self->{'dvsManager'}           = $options{'dvsManager'};

   eval {
      if (not defined $self->{'folderObj'}) {
         $self->{'folderObj'} = CreateInlineObject("com.vmware.vcqa.vim.Folder",
                                                   $self->{'anchor'});
      }
      if (not defined $self->{'datacenterMOR'}) {
         $self->{'datacenterMOR'} = $self->{'folderObj'}->getDataCenter($self->{'datacenter'});
      }

      if (not defined $self->{'networkFolderMOR'}) {
         $self->{'networkFolderMOR'} =
            $self->{'folderObj'}->getNetworkFolder($self->{'datacenterMOR'});
      }

      if (not defined $self->{'dvsConfigSpec'}) {
         my $dvsUtil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");
         $self->{'dvsConfigSpec'} =
            $dvsUtil->createDefaultDVSConfigSpec($self->{'dvsName'});
      }

      if (not defined $self->{'dvsMOR'}) {
         $self->{'dvsMOR'} = $self->{'folderObj'}->getDistributedVirtualSwitch(
                                                   $self->{'networkFolderMOR'},
                                                   $self->{'dvsName'});
      }

      if (not defined $self->{'dvs'}) {
         $self->{'dvs'} =
            CreateInlineObject("com.vmware.vcqa.vim.DistributedVirtualSwitch",
                               $self->{'anchor'});
      }

      if (not defined $self->{'dvsManager'}) {
         $self->{'dvsManager'} =
            CreateInlineObject("com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager",
                               $self->{'anchor'});
      }

      if (not defined $self->{'dvsHelper'}) {
         $self->{'dvsHelper'} =
            CreateInlineObject("com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper",
                               $self->{'anchor'});
      }

   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while creating " .
                       "VDNetLib::InlineJava::DVS object");
      return FALSE;
   }

   bless($self, $class);
   return $self;
}


########################################################################
#
# ConfigureDVSHealthCheck--
#     Method to configure healthcheck properties for the DVS.This
#     method can enable or disable the vlanmtu check or teaming check.
#
# Input:
#     Named value parameter with following keys:
#     healthcheck: Type of healthcheck to configured, vlanmtu check or
#                  teaming check (Required).
#     operation: Type of operation, to enable or disable healthcheck.
#
# Results:
#     Returns 1 if healthcheck gets configured.
#     0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureDVSHealthCheck
{
   my $self = shift;
   my %options = @_;

   my $operation   = $options{operation};
   my $healthCheck = $options{healthcheck};
   my $interval    = $options{interval};
   my @healthCheckSpec;

   eval {
      #
      # set the healthcheck configuration spec based on the type of operaion
      # specified by the user.
      #
      if ($healthCheck =~ /vlanmtu/i) {
         @healthCheckSpec =
            CreateInlineObject("com.vmware.vc.VMwareDVSVlanMtuHealthCheckConfig");
         $healthCheckSpec[0]->setEnable($operation);
         $healthCheckSpec[0]->setInterval($interval);
      } elsif ($healthCheck =~ /teaming/i) {
         @healthCheckSpec =
            CreateInlineObject("com.vmware.vc.VMwareDVSTeamingHealthCheckConfig");
         $healthCheckSpec[0]->setEnable($operation);
         $healthCheckSpec[0]->setInterval($interval);
      } else {
        $vdLogger->Error("Invalid healthcheck operation : $healthCheck specified");
        return FALSE;
      }

      # call the API to set the healthcheck configuration for the dvs.
      $self->{'dvs'}->updateDVSHealthCheckConfig($self->{'dvsMOR'}, \@healthCheckSpec);
   };

   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# ExportVDSConfig--
#     Method to export the specified VDS and/or dvPort Group
#     configuration in a backup file using exportEntity() method.
#
# Input:
#     Named value parameter with following keys:
#     backup       => <ExportVDS, ExportVDSDVPG, ExportDVPG> (Required)
#     dvpgName     => <Name of the dvPort Group> (Required)
#     vdsFileName  => <File Name for VDS backup> (Required)
#     dvpgFileName => <File Name for dvPort Group backup> (Required)
#
# Results:
#     Returns TRUE if export configuration operation is succceeded.
#     FALSE in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ExportVDSConfig
{
   my $self = shift;
   my %options = @_;

   my $backup       = $options{'backup'};
   my $dvpgName     = $options{'dvpgName'};
   my $vdsFileName  = $options{'vdsFileName'};
   my $dvpgFileName = $options{'dvpgFileName'};

   my $vcanchor     = $self->{'anchor'};
   my $dvsMor       = $self->{'dvsMOR'};
   my $dvs          = $self->{'dvs'};
   my $idvsManager  = $self->{'dvsManager'};

   eval {
      # Get VDS MOR for exportEntity operation.
      my $dvsManagerMor = $idvsManager->getDvSwitchManager();

      # Get the UUID of the VDS and set it to VDS selection set.
      my $dvsUUID = $dvs->getConfig($dvsMor)->getUuid();

      my $dvsSS;
      if ($backup =~ m/VDS/i) {
         $dvsSS = CreateInlineObject(DVS_SELECTION);
         $dvsSS->setDvsUuid($dvsUUID);
      }
      my $dvspgCriteria;

      my $dvpgSS;
      if ($backup =~ m/DVPG/i) {
         # Create dvPortGroup object.
         my $idvpg = CreateInlineObject(DISTRIBUTED_VIRTUAL_PORTGROUP, $vcanchor);

         # dvPortGroup selection object.
         $dvpgSS = CreateInlineObject(DVS_PORTGROUP_SELECTION);

         # Get the key of the DVPG and set it to DVPG selection set.
         my $dvpgMor = $idvpg->getDVPortgroupByName($dvsMor, $dvpgName);
         my $dvspgkey = $idvpg->getKey($dvpgMor);
         $dvpgSS->setDvsUuid($dvsUUID);
         $dvpgSS->getPortgroupKey()->clear();
         $dvpgSS->getPortgroupKey()->add($dvspgkey);
      }

      # Create VDS and/or dvPort Group selection set.
      my @selectionSet;
      if ($backup =~ m/^ExportVDS$/i) {
         @selectionSet = ($dvsSS);
      } elsif ($backup =~ m/^ExportVDSDVPG$/i) {
         @selectionSet = ($dvsSS, $dvpgSS);
      } elsif ($backup =~ m/^exportdvpg$/i) {
         @selectionSet = ($dvpgSS);
      }

      my $backupConfig = [];
      $backupConfig = $idvsManager->exportEntity($dvsManagerMor, \@selectionSet);

      # Store the VDS Spec in a file.
      if ($backup =~ m/VDS/i) {
         my @vdsSpec = $backupConfig->[0]->getConfigBlob();
         my $out = CreateInlineObject(FILE_OUTPUT_STREAM, $vdsFileName);
         $out->write(@vdsSpec);
         $out->close();
      }

      # Store the dvPortGroup Spec in a file.
      if ($backup =~ m/DVPG/i) {
         my $out1 = CreateInlineObject(FILE_OUTPUT_STREAM, $dvpgFileName);
         my @dvpgSpec;
         if ($backup =~ m/^exportDVPG$/i) {
            @dvpgSpec = $backupConfig->[0]->getConfigBlob();
         } else {
            @dvpgSpec = $backupConfig->[1]->getConfigBlob();
         }
         $out1->write(@dvpgSpec);
         $out1->close();
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while executing ExportVDSConfig() method");
      return FALSE;
   }
   return TRUE;
} # End of ExportVDSConfig


########################################################################
#
# ImportVDSConfig--
#     Method to import the specified VDS configuration from a
#     backup file using ImportEntity() method.
#
# Input:
#     Named value parameter with following keys:
#     restore         => <ImportVDS, ImportVDSDVPG, ImportDVPG,
#                         RestoreVDS, RestoreVDSDVPG, RestoreDVPG,
#                         ImportOrigVDS, ImportOrigVDSDVPG,
#                         ImportOrigDVPG > (Required)
#     dvpgName       => <Name of the dvPort Group> (Required)
#     vdsFileName    => <File Name for VDS backup> (Required)
#     dvpgFileName   => <File Name for dvPort Group backup> (Required)
#
# Results:
#     Returns TRUE if import configuration operation is succceeded.
#     FALSE in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ImportVDSConfig
{
   my $self = shift;
   my %options = @_;

   my $restore      = $options{'restore'};
   my $dvpgName     = $options{'dvpgName'};
   my $vdsFileName  = $options{'vdsFileName'};
   my $dvpgFileName = $options{'dvpgFileName'};

   my $vcanchor     = $self->{'anchor'};
   my $folderObj    = $self->{'folderObj'};
   my $netFolderMor = $self->{'networkFolderMOR'};
   my $dvs          = $self->{'dvs'};
   my $dvsMor       = $self->{'dvsMOR'};
   my $idvsManager  = $self->{'dvsManager'};

   my $result = FALSE;

   eval {
      my $operation;
      if ($restore =~ m/ImportOrig/i) {
         $operation = "createEntityWithOriginalIdentifier";
      } else {
         $operation = "createEntityWithNewIdentifier";
      }

      if ($restore =~ m/^ImportVDS$/i || $restore =~ m/^ImportVDSDVPG$/i ||
          $restore =~ m/^ImportOrigVDS$/i || $restore =~ m/^ImportOrigVDSDVPG$/i) {
         $result = ImportVDSDVPGEntity('dvsManager' => $idvsManager,
                           'entityName' => "testVDS",
                           'entityType' => "distributedVirtualSwitch",
                           'container'  => $netFolderMor,
                           'operation'  => $operation,
                           'fileName'   => $vdsFileName);
      }

      if ($restore =~ m/^ImportVDSDVPG$/i || $restore =~ m/^ImportDVPG$/i ||
          $restore =~ m/^ImportOrigVDSDVPG$/i || $restore =~ m/^ImportOrigDVPG$/i) {
         my $dvsMor1;
         if ($restore =~ m/^ImportVDSDVPG$/i || $restore =~ m/^ImportOrigVDSDVPG$/i) {
            $dvsMor1 = $folderObj->getDistributedVirtualSwitch($netFolderMor, "testVDS");
         } else {
            $dvsMor1 = $dvsMor;
         }

         $result = ImportVDSDVPGEntity('dvsManager' => $idvsManager,
                           'entityName' => "testDVPG",
                           'entityType' => "distributedVirtualPortgroup",
                           'container'  => $dvsMor1,
                           'operation'  => $operation,
                           'fileName'   => $dvpgFileName);
      }

      if ($restore =~ m/^RestoreVDS$/i || $restore =~ m/^RestoreVDSDVPG$/i) {
         my $dvsUUID = $dvs->getConfig($dvsMor)->getUuid();
         $result = ImportVDSDVPGEntity('dvsManager' => $idvsManager,
                           'entityName' => "testVDS",
                           'entityType' => "distributedVirtualSwitch",
                           'container'  => $netFolderMor,
                           'operation'  => "applyToEntitySpecified",
                           'entityKey'  => $dvsUUID,
                           'fileName'   => $vdsFileName);
      }

      if ($restore =~ m/^RestoreVDSDVPG$/i || $restore =~ m/^RestoreDVPG$/i) {
         my $idvpg = CreateInlineObject(DISTRIBUTED_VIRTUAL_PORTGROUP, $vcanchor);
         my $dvpgMor = $idvpg->getDVPortgroupByName($dvsMor, $dvpgName);
         my $dvpgkey = $idvpg->getKey($dvpgMor);

         $result = ImportVDSDVPGEntity('dvsManager' => $idvsManager,
                           'entityName' => "testDVPG",
                           'entityType' => "distributedVirtualPortgroup",
                           'container'  => $dvsMor,
                           'operation'  => "applyToEntitySpecified",
                           'entityKey'  => $dvpgkey,
                           'fileName'   => $dvpgFileName);
      }

      if ($result == FALSE) {
         return FALSE;
      }

  };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while executing ImportVDSConfig() method");
      return FALSE;
   }
   return TRUE;
} # End of ImportVDSConfig


########################################################################
#
# ImportVDSDVPGEntity--
#     Method to import the specified VDS configuration from a
#     backup file using ImportEntity() method.
#
# Input:
#     Named value parameter with following keys:
#     dvsManager => <dvsManager Object> (Required)
#     entityName => <VDS Name or DV PortGroup Name> (Required)
#     entityType => <distributedVirtualSwitch or
#                    distributedVirtualPortgroup> (Required)
#     container  => <Network folder MOR or VDS MOR> (Required)
#     operation  => <createEntityWithOriginalIdentifier,
#                    applyToEntitySpecified
#                    createEntityWithNewIdentifier> (Required)
#     fileName   => <File Name of VDS or dvPortGroup backup> (Required)
#     entityKey  => <VDS Key or dvPortGroup Key> (Required)
#
#
# Results:
#     Returns TRUE if import configuration operation is succceeded.
#     FALSE in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ImportVDSDVPGEntity
{
   my %options = @_;

   my $idvsManager = $options{'dvsManager'};
   my $entityName  = $options{'entityName'};
   my $entityType  = $options{'entityType'};
   my $container   = $options{'container'};
   my $operation   = $options{'operation'};
   my $fileName    = $options{'fileName'};
   my $entityKey   = $options{'entityKey'};

   eval {
      # Create objects to read VDS config from the file.
      my $backupConfig = [];
      $backupConfig->[0] = CreateInlineObject(ENTITY_BACKUP_CONFIG);
      if ($operation =~ m/^createEntityWithNewIdentifier$/i) {
         $backupConfig->[0]->setName($entityName);
      }
      $backupConfig->[0]->setEntityType($entityType);
      $backupConfig->[0]->setContainer($container);

      if (defined $entityKey) {
         $backupConfig->[0]->setKey($entityKey);
      }

      # Read the VDS / dvPortGroup configuration from the file.
      my $spec;
      my $result = open(INF, $fileName);
      if (not defined $result) {
         $vdLogger->Error("Unable to open the $fileName");
         return FALSE;
      }
      binmode INF;
      my $fileSize = -s $fileName;
      read(INF, $spec, $fileSize);
      # unpack with c* - encode the given input to bytes[]
      # because setConfigBlob expects byte-array.
      my @arr = unpack("c*", $spec);
      $backupConfig->[0]->setConfigBlob(\@arr);
      close(INF);

      # Get DVS MOR for importEntity operation.
      my $dvsManagerMor = $idvsManager->getDvSwitchManager();

      # Call importEntity() method.
      $idvsManager->importEntity($dvsManagerMor, $backupConfig, $operation);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown: ImportVDSDVPGEntity()");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# DeleteDistributedVirtualSwitch--
#     Method to delete Distributed Virtual Switch referred by the given
#     DVS MOR
#
# Input:
#     None
#
# Results:
#     1 - if the DVS is deleted successfully;
#     0 - in case of any error
#
# Side effects:
#     This object won't be usable again
#
########################################################################

sub DeleteDistributedVirtualSwitch
{
   my $self   = shift;
   my $dvsMOR = $self->{'dvsMOR'};

   my $result = FALSE;
   eval {
      my $managedEntity = CreateInlineObject("com.vmware.vcqa.vim.ManagedEntity",
                                             $self->{'anchor'});
      $result = $managedEntity->destroy($dvsMOR);
   };

   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
   return $result;
}


########################################################################
#
# GetDVPGConfigSpec--
#     This routine returns new DVPGConfigSpec object
#
# Input:
#     None
#
# Results:
#     reference to DVPGConfigSpec if successful
#     FALSE in case of an exception
#
# Side effects:
#     None
#
########################################################################

sub GetDVPGConfigSpec
{
   my $self = shift;
   eval {
      return CreateInlineObject(DVPGCONFIGSPEC);
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
}


########################################################################
#
# AddPG--
#     This routine adds a port groups on a given vDS
#
# Input:
#     DVPGTYPE   - type of the port group like ephemeral
#     DVPGNAMES  - Name of the port group
#     PORTS      - Port number of the port group
#
# Results:
#     pgMorList in case of success
#     FALSE will be returned in case of any error
#
# Side effects:
#     None
#
########################################################################

sub AddPG
{
   my $self = shift;
   my %args = @_;
   my $dvpgType     = $args{DVPGTYPE};
   my $dvpgNames    = $args{DVPGNAMES};
   my $port         = $args{PORTS};
   my $autoExpand   = $args{AUTOEXPAND};
   my @pgMorList;
   my $pgConfigSpecListRef;
   my $pgMor;

   eval {
      foreach my $dvpg (@$dvpgNames) {
         my $pgConfigSpec = CreateInlineObject(DVPGCONFIGSPEC);
         push(@$pgConfigSpecListRef,$pgConfigSpec);
         $pgConfigSpec->setName($dvpg);
         $pgConfigSpec->setType($dvpgType);
         if (defined $port) {
            $pgConfigSpec->setNumPorts($port);
         }
         if ($dvpgType =~ m/earlyBinding/i) {
            if ((defined $autoExpand) && ($autoExpand eq "false")) {
               $autoExpand = 0;
            }
            $pgConfigSpec->setAutoExpand($autoExpand);
         }
      }
      my $dvsMor      = $self->{dvsMOR};
      my $inlineDVS   = $self->{dvs};
      my $pgList = $inlineDVS->addPortGroups($dvsMor, $pgConfigSpecListRef);
      for (my $i=0; $i<$pgList->size(); $i++) {
         $pgMor = $pgList->get($i);
         push(@pgMorList,$pgMor);

      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while creation of dvport group");
      return FALSE;
   }
   return \@pgMorList;
}


########################################################################
#
# SetDVSSelectionSet--
#     This routine creates DVPortSelection object (if necessary)
#     and sets DVSUUID
#
# Input:
#     selectionSet - undefined or defined selectionset instance
#
# Results:
#     returs reference to DVSSelection if no error else FALSE
#
# Side effects:
#     None
#
########################################################################

sub SetDVSSelectionSet
{
   my $self = shift;
   my %options = @_;
   my $dvsSelectionSet;

   $self->{'selectionSet'} = $options{'selectionSet'};

   eval {
      if (not defined $self->{'selectionSet'}) {
         $dvsSelectionSet = CreateInlineObject(DVSSELECTION);
      }
      my $dvsConfig = $self->{dvs}->getConfig($self->{dvsMOR});
      my $dvsUUID = $dvsConfig->getUuid();
      $dvsSelectionSet->setDvsUuid($dvsUUID);
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }

   return $dvsSelectionSet;
}


########################################################################
#
# SetDVPortSelectionSet--
#     This routine creates (if necessary) and sets DVSUUID
#
# Input:
#     selectionSet - undefined or defined selectionset instance
#
# Results:
#     returs reference to DVPortSelection if no error else FALSE
#
# Side effects:
#     None
#
########################################################################

sub SetDVPortSelectionSet
{
   my $self = shift;
   my %options = @_;
   my $dvPortSelectionSet;

   $self->{'selectionSet'} = $options{'selectionSet'};

   eval {
      if (not defined $self->{'selectionSet'}) {
         $dvPortSelectionSet = CreateInlineObject(DVPORT_SELECTION);
      }
      my $dvsConfig = $self->{dvs}->getConfig($self->{dvsMOR});
      my $dvsUUID = $dvsConfig->getUuid();
      $dvPortSelectionSet->setDvsUuid($dvsUUID);
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }

   return $dvPortSelectionSet;
}


########################################################################
#
# SetDVSKeyedOpaqueData--
#     This routine sets DVSKeyedOpaquaData object properties
#
# Input:
#     dvsKeyedOpaqueData - reference to DVSConfigSpec
#
# Results:
#     returs FALSE if there is an error else ref to DVSKeyedOpaqueData
#
# Side effects:
#     None
#
########################################################################

sub SetDVSKeyedOpaqueData
{
   my $self = shift;
   my $dvsKeyedOpaqueData = undef;
   my %options = @_;
   #$vdLogger->Debug("SetDVSKeyedOpaqueData: " . Dumper(\%options));
   eval {
      if (not defined $dvsKeyedOpaqueData) {
         $dvsKeyedOpaqueData = CreateInlineObject(
                                "com.vmware.vc.DVSKeyedOpaqueData");
      }
      foreach my $prop (keys %options) {
        # $vdLogger->Info("setting the prop, $prop with value $options{$prop}");
         my $method = 'set'.$prop;
         $dvsKeyedOpaqueData->$method($options{$prop});
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }

   return $dvsKeyedOpaqueData;
}


########################################################################
#
# SetDVSOpaqueDataConfigSpec--
#     This routine sets the properties of DVSOpaqueDataConfigSpec object
#     passed with the values provided in the hash
#
# Input:
#     dvsOpaqueDataCS - reference to DVSConfigSpec
#
# Results:
#     returs FALSE if there is an error else ref to DVSOpaqueDataConfigSpec
#
# Side effects:
#     None
#
########################################################################

sub SetDVSOpaqueDataConfigSpec
{
   my $self = shift;
   my $dvsOpaqueDataCS = undef;
   my %options = @_;

   eval {
      if (not defined $dvsOpaqueDataCS) {
         $dvsOpaqueDataCS = CreateInlineObject(
                                "com.vmware.vc.DVSOpaqueDataConfigSpec");
      }
      foreach my $prop (keys %options) {
         my $method = 'set'.$prop;
         $dvsOpaqueDataCS->$method($options{$prop});
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }

   return $dvsOpaqueDataCS;
}


########################################################################
#
# GetMOR--
#     This routine gets new ManagedObjectReference object
#
# Input:
#     None
#
# Results:
#     returns ManagedObjectReference object
#
# Side effects:
#     None
#
########################################################################

sub GetMOR
{
   eval {
      return CreateInlineObject(MANAGEDOBJREF);
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }
}


########################################################################
#
# ConfigureLACP--
#     This routine configures LACP on the given VDS.
#
# Input:
#     Operation - Enable/Disable (Mandatory)
#     Mode - Active/Passive (Mandatory when Operation is Enable)
#                           (Optional when Operation is Disable)
#
# Results:
#     SUCCESS - if task is done correctly
#     FAILURE - in case of error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureLACP
{
   my $self = shift;
   my %options = @_;
   my $operation   = $options{'operation'};
   my $lacpMode   = $options{'mode'};

   return TRUE;
}


########################################################################
#
# SetVMwareDVSLacpApiVersion--
#     This routine configures LACP version on the vmware dvs.
#
# Input:
#     LacpVersion - singlelag/multiplelag
#
# Results:
#     SUCCESS - if task is done correctly
#     FAILURE - in case of error
#
# Side effects:
#     None
#
########################################################################

sub SetVMwareDVSLacpApiVersion
{
   my $self = shift;
   my %options = @_;
   my $lacpversion = $options{'lacpversion'};

   if ($lacpversion =~ /nolag/i) {
      # vds version 4.0/4.1.0/5.0.0, which doesn't support LACP.
      return TRUE;
   }

   #
   # Function Spec says VDS 6.x should have LACPv2 by default
   # For backward compatiblity, VDS 6.x is created with LACPv1 when creating
   # VDS using VIM API. On NGC UI takes care of updating it to LACPv2(multiplelag)
   # Thus we as client should take of updating when createing VDS using VIM API
   #
   LoadInlineJavaClass('com.vmware.vc.VMwareDvsLacpApiVersion');
   eval {
      if ($lacpversion =~ /singlelag/) {
         $self->{'dvsHelper'}->setLacpVersion($self->{'dvsMOR'},
         $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VMwareDvsLacpApiVersion::SINGLE_LAG)
      } else {
         $self->{'dvsHelper'}->setLacpVersion($self->{'dvsMOR'},
         $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::VMwareDvsLacpApiVersion::MULTIPLE_LAG)
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      return FALSE;
   }

   $vdLogger->Info("Successfully Set LACP Version:$lacpversion ".
                   "on VDS $self->{'dvsName'} ");
   return TRUE;
}


########################################################################
#
# UpgradeVDSVersion--
#     This method upgrades the vds version.
#
# Input:
#     version   - the new version of the vds upgrade to be upgraded.
#
# Results:
#     "True",if vds upgrade works fine
#     "FALSE",in case of any error
#
# Side effects:
#     None
#
########################################################################

sub UpgradeVDSVersion
{
   my $self = shift;
   my %args = @_;
   my $version = $args{version};
   my $result;

   eval {
      LoadInlineJavaClass('com.vmware.vcqa.vim.dvs.DVSTestConstants');
      my $dvsMor      = $self->{dvsMOR};
      my $inlineDVS   = $self->{dvs};

      my $DVSUtil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");
      my $productSpec = $DVSUtil->getProductSpec($self->{'anchor'}, $version);
      $result = $inlineDVS->performProductSpecOperation($dvsMor,
                                                        $VDNetLib::InlineJava::VDNetInterface::com::vmware::vcqa::vim::dvs::DVSTestConstants::OPERATION_UPGRADE,
                                                        $productSpec);
      # multiple lag is applicable only to vds 5.5 and later.
      if (($version =~ /^(\d+)\.(\d+)/) && ($1 >= 5) && ($version !~ /^5\.1/)) {
         $self->SetVMwareDVSLacpApiVersion(lacpversion => "multiplelag");
      }
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while upgrading VDS to $version");
      return FALSE;
   }
   return $result;
}


########################################################################
#
# ConfigureVDSUplinkPorts --
#     This method sets number of uplink ports
#
# Input:
#     vdsuplink  - the given vds uplink number to be set.
#
# Results:
#     "True",if set vds uplink works fine
#     "FALSE",in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureVDSUplinkPorts
{
   my $self = shift;
   my %args = @_;
   my $vdsuplink = $args{vdsuplink};
   my $result;

   my $uplinkPortNames = [];
   for (my $i = 0; $i < $vdsuplink; $i++) {
      $uplinkPortNames->[$i] = "uplink" . "$i";
   }
   eval {
      my $dvsMor      = $self->{dvsMOR};
      my $inlineDVS   = $self->{dvs};
      my $dvsConfigSpec= CreateInlineObject("com.vmware.vc.DVSConfigSpec");
      my $uplinkPolicyInst = CreateInlineObject("com.vmware.vc.DVSNameArrayUplinkPortPolicy");
      my $vdsUplinkPortName = $uplinkPolicyInst->getUplinkPortName();
      LoadInlineJavaClass('com.vmware.vcqa.util.TestUtil');
      $uplinkPolicyInst->getUplinkPortName()->clear();
      $uplinkPolicyInst->getUplinkPortName()->addAll(
             VDNetLib::InlineJava::VDNetInterface::com::vmware::vcqa::util::TestUtil->arrayToVector($uplinkPortNames));

      $dvsConfigSpec->setUplinkPortPolicy($uplinkPolicyInst);
      $dvsConfigSpec->setConfigVersion($inlineDVS->getConfig($dvsMor)->getConfigVersion());
      $result = $inlineDVS->reconfigure($dvsMor,$dvsConfigSpec);
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while set VDS uplink");
      return FALSE;
   }
   if (!$result) {
      $vdLogger->Error("Failed to set vds uplink " .
                       "$self->{'dvsName'} ");
      VDSetLastError("EINLINE");
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# ConfigureInlineLAG
#      This method configures LACPv2 LAG on VDS, including creation,
#      destroying, editing etc
#
# Input:
#      lagObject - vdnet LAG object (mandatory)
#
# Results:
#      "TRUE", if switch port gets disabled
#      "FALSE", in case of any error,
#
# Side effects:
#
########################################################################

sub ConfigureInlineLAG
{
   my $self = shift;
   my $lagObject = shift;
   my $lagOperation = shift;
   my $lacpGroupConfig;

   if ((not defined $lagObject) || (not defined $lagOperation)) {
      $vdLogger->Error("One or more lag param missing");
      return FALSE;
   }

   if ($lagOperation !~ /(add|remove|edit)/) {
      $vdLogger->Error("Unsupported lagOperation");
      return FALSE;
   }

   eval {
      my $optionValue = [];
      my $index = 0;
      $optionValue->[$index] = CreateInlineObject("com.vmware.vc.VMwareDvsLacpGroupSpec");

      $lacpGroupConfig = $lagObject->GetLACPGroupConfig();
      $optionValue->[$index]->setLacpGroupConfig($lacpGroupConfig);
      # $lagOperation = add, remove, edit as per given by user
      $optionValue->[$index]->setOperation($lagOperation);
      $self->{'dvsHelper'}->updateLacpConfig($self->{'dvsMOR'}, $optionValue);
   };
   if ($@) {
      $vdLogger->Error("ConfigureInlineLAG failed");
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# GetLagGroupConfigFromVDS
#      This method is for making a product call and fetch laggroupconfig
#      obj for the corresponding lagname on a given VDS.
#
# Input:
#      lagname(mandatory)
#
# Results:
#      lagGroupConfig obj in case of SUCCESS,
#      undef, if no such lagname obj exists on this VDS.
#      FALSE, in case of any error,
#
# Side effects:
#
########################################################################

sub GetLagGroupConfigFromVDS
{

   my $self = shift;
   my $expectedLagName = shift;
   my $ret = undef;

   if (not defined $expectedLagName) {
      $vdLogger->Error("One or more param missing in".
                       "GetLagGroupSpecFromVDS()");
      return FALSE;
   }

   eval {
      my $groupSpecArray = $self->{'dvsHelper'}->getLagGroupSpec($self->{'dvsMOR'});
      my $arraySize = scalar(@$groupSpecArray);
      for (my $i = 0; $i < $arraySize; $i++) {
         my $origLagName = $groupSpecArray->[$i]->getLacpGroupConfig()->getName();
         $vdLogger->Trace("i:$i originalLagName:$origLagName ".
                          "expectedLagName:$expectedLagName");
         if ($expectedLagName =~ /^$origLagName$/) {
            $ret = $groupSpecArray->[$i]->getLacpGroupConfig();
         }
      }
   };
   if ($@) {
      $vdLogger->Error("GetLagGroupConfigFromVDS  failed");
      InlineExceptionHandler($@);
      return FALSE;
   }

   return $ret;

}


########################################################################
#
# ConfigureNIOCInfrastructureTraffic --
#     Method to configure NIOC infrastructure traffic
#     with shares, limits and reservation
#
# Input:
#     trafficClassSpec: reference to hash of hash containing following keys
#                        virtualMachine => {
#                           reservation =>
#                           shares      =>
#                           limits      =>
#                        },
#                        ft => {
#                           reservation =>
#                           shares      =>
#                           limits      =>
#                        },
#                        Other supported infrstructure types are
#                        nfs, iscsi, vsan, hbr
#
# Results:
#     1, if configured successfully;
#     0, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureNIOCInfrastructureTraffic
{
   my $self             = shift;
   my $trafficClassSpec = shift;
   my $version = $trafficClassSpec->{'niocversion'} || 'version3';
   eval {
      my $dvsUtil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");
      my $configSpec = $dvsUtil->createDefaultDVSConfigSpec($self->{'dvsName'});
      $self->ConfigureNIOC('enable',$version);
      LoadInlineJavaClass('com.vmware.vc.SharesLevel');
      delete $trafficClassSpec->{'niocversion'};
      foreach my $type (keys %$trafficClassSpec) {
         my $reservation = $trafficClassSpec->{$type}{reservation};
         my $shares = $trafficClassSpec->{$type}{shares};
         my $limit = $trafficClassSpec->{$type}{limit};
         my $key   = $type;
         my $level = $VDNetLib::InlineJava::VDNetInterface::com::vmware::vc::SharesLevel::CUSTOM;
         my $sharesInfo = CreateInlineObject("com.vmware.vc.SharesInfo");
         $sharesInfo->setLevel($level);
         $sharesInfo->setShares($shares);
         my $method =
            'createDVSConfigSpecWithHostInfrastructureTrafficResourceAllocation' ;
         $configSpec->setConfigVersion($self->{dvs}->getConfigVersion($self->{'dvsMOR'}));
         $configSpec->setNetworkResourceControlVersion($version);
         $dvsUtil->$method($self->{anchor},
                           $reservation,
                           $limit,
                           $sharesInfo,
                           $key,
                           $configSpec);
         $self->{'dvs'}->reconfigure($self->{dvsMOR}, $configSpec);
         $vdLogger->Info("Successfully set NIOC Traffic " .
                         "Parameters for $type as \n Shares : $shares " .
                         " Reservation : $reservation Limit : $limit");
      }
   };
   if ($@) {
      $vdLogger->Error("Failed to configure NIOC Infrastructure " .
                                                "Configration on DVS");
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# EnableNetIORM --
#     Method to enable NetIORM on the DVS
#
# Input:
#     None
#
# Results:
#     1, if enabled successfully; 0 in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub EnableNetIORM
{
   my $self = shift;
   eval {
      my $dvsUtil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");
      my $configSpec = $dvsUtil->createDefaultDVSConfigSpec($self->{'dvsName'});
         my $method = "enableNetiorm";
         $configSpec->setConfigVersion($self->{dvs}->getConfigVersion($self->{'dvsMOR'}));
         $configSpec->setNetworkResourceControlVersion("version3");
         $dvsUtil->$method($self->{anchor},  $self->{'dvsMOR'});
   };
   if ($@) {
      $vdLogger->Error("Failed to configure NIOC on DVS");
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


#############################################################################
#
# GetMORId--
#     Method to get VDS Managed Object ID (MOID)
#
# Input:
#
# Results:
#	VDS MORId, of the VDS
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
      $MORId = $self->{dvsMOR}->getValue();
   };

   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Failed to get the VDS MOR Id " .
                       "of $self->{name}");
      return FALSE;
   }
   return $MORId;
}

########################################################################
#
# ConfigureIpfix --
#  Method to config Ipfix on the DVS
#
# Input:
#  collectoerip  : IP address of the ipfix collector,required.
#  internal      : If set to true the traffic analysis would be limited
#                  to the internal traffic i.e. same host. The default
#                  is false,optional.
#  idletimeout   : The time after which idle flows are automatically
#                  exported to the ipfix collector, the default is 15
#                  seconds,required.
#  collectorport : Port for the ipfix collector,required.
#  vdsip         : Parameter to specify the IPv4 address of the vds
#                  required for IPv4 only
#  activetimeout : The time after which active flows are automatically
#                  exported to the ipfix collector.default is 60 seconds,
#                  required.
#  domainid      : Parameter to specify the IPv6 domain ID of the vds
#                  required.
#  samplerate    : Ratio of total number packets to the total number
#                  packets analyzed,required.
# Results:
#		 "SUCCESS", if ipfix has been configured on the vds
#		 "FAILURE", in case of any error,
# Side effects:
#		 None
#
########################################################################

sub ConfigureIpfix
{
   my $self = shift;
   my %args = @_;

   my $collectorIP = $args{collectorip};
   my $internalOnly = $args{internal} || 0;
   my $idleTimeout = $args {idletimeout};
   my $collectorPort = $args{collectorport};
   my $vdsIP = $args{vdsip};
   my $activeTimeout = $args{activetimeout};
   my $sampleRate = $args{samplerate};
   my $domainID = $args{domainid};
   eval {
      my $dvsUtil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");
      my $deltaConfigSpec = CreateInlineObject("com.vmware.vc.VMwareDVSConfigSpec");
      my $ipfixConfig = $dvsUtil->
                        createIpfixConfig($collectorIP,$collectorPort,$activeTimeout,
                                          $idleTimeout,$sampleRate,$internalOnly);
      if (defined($vdsIP)) {
         $deltaConfigSpec->setSwitchIpAddress($vdsIP);
      }
      if (defined($domainID)) {
         $ipfixConfig->setObservationDomainId($domainID);
      }
      $deltaConfigSpec->setIpfixConfig($ipfixConfig);
      $deltaConfigSpec->setConfigVersion($self->{dvs}->getConfigVersion($self->{'dvsMOR'}));
      $self->{dvs}->reconfigure($self->{'dvsMOR'},$deltaConfigSpec);
   };
   if ($@) {
      $vdLogger->Error("Failed to configure Ipfix on DVS");
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# SetMulticastFilteringMode --
#     This routine configures multicast filtering mode on the vmware dvs.
#
# Input:
#     multicastFilteringMode - legacyFiltering/snooping
#
# Results:
#     TRUE  - if multicast filtering mode is set on the vmware dvs correctly.
#     FALSE - in case of error
#
# Side effects:
#     None
#
########################################################################

sub SetMulticastFilteringMode
{
   my $self                   = shift;
   my $multicastFilteringMode = shift;
   my $result                 = FALSE;

   eval {
      $result = $self->{'dvsHelper'}->setMulticastFilteringMode(
                     $self->{'dvsMOR'}, $multicastFilteringMode);
   };
   if ($@) {
      $vdLogger->Error("Failed to set multicast filtering mode on DVS");
      InlineExceptionHandler($@);
      return FALSE;
   }
   if (!$result) {
      $vdLogger->Error("Failed to set multicast filtering mode on DVS");
      VDSetLastError("EINLINE");
      return FALSE;
   }

   $vdLogger->Info("Successfully Set multicast filtering mode ".
                    "on VDS $self->{'dvsName'} ");
   return TRUE;
}


########################################################################
#
# ConfigureNIOC --
#     Method to enable/disable NIOC on the DVS
#
# Input:
#     state: enable or disable NIOC
#     version:NIOC version(version2/version3)
# Results:
#     1, if enabled successfully; 0 in case of any error;
#
# Side effects:
#     None
#
#########################################################################

sub ConfigureNIOC
{
   my $self = shift;
   my $state = shift || "enable";
   my $version = shift || VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION;
   eval {
      my $dvsUtil = CreateInlineObject("com.vmware.vcqa.vim.dvs.DVSUtil");
      my $configSpec = $dvsUtil->createDefaultDVSConfigSpec($self->{'dvsName'});
      $configSpec->setConfigVersion($self->{dvs}->getConfigVersion($self->{'dvsMOR'}));
      $configSpec->setNetworkResourceControlVersion($version);
      $self->{'dvs'}->reconfigure($self->{dvsMOR}, $configSpec);
      $vdLogger->Info("Successfully configured NIOC with $version");

      if ($state eq "enable") {
         $dvsUtil->enableNetiorm($self->{anchor},  $self->{'dvsMOR'});
         $vdLogger->Info("Successfully enabled NIOC on DVS");
      } else {
         $self->{dvs}->enableNetworkResourceManagement($self->{'dvsMOR'}, 0);
         $vdLogger->Info("Successfully disabled NIOC on DVS");
      }
   };
   if ($@) {
      $vdLogger->Error("Failed to configure NIOC on DVS");
      InlineExceptionHandler($@);
      return FALSE;
   }
   return TRUE;
}


########################################################################
#
# GetVirtualWirePortGroupName --
#     Method to get vds port group names based on the vxlan id and vds name
#
# Input:
#     vxlanid: virtual wire id used to get the port group names(required)
#     vds    : vds name(required)
#
# Results:
#     Port Group Name based on the vxlan id and vds name, return 'undef' if
#          find no port group related the vxlan
#     FALSE in case of any error;
#
# Side effects:
#     None
#
#########################################################################

sub GetVirtualWirePortGroupName
{
   my $self           = shift;
   my $vxlanid        = shift;
   my $vds            = shift;
   my $portGroupName  = undef;

   eval {
      my $network    = CreateInlineObject("com.vmware.vcqa.vim.Network",
                                                      $self->{'anchor'});
      my $portgroup  = CreateInlineObject("com.vmware.vcqa.vim.DistributedVirtualPortgroup",
                                                      $self->{'anchor'});
      my $children   = $network->getChildEntity($self->{'networkFolderMOR'});
      for (my $i = 0; $i < $children->size(); $i++) {
         my $type  = $children->get($i)->getType();
         if ($type eq "DistributedVirtualPortgroup") {
             my $pgName     = $portgroup->getName($children->get($i));
             if ($pgName =~ /${vxlanid}-/i) {
                my $configInfo = $portgroup->getConfigInfo($children->get($i));
                my $dvs        = $configInfo->getDistributedVirtualSwitch();
                my $dvsObj     = CreateInlineObject("com.vmware.vcqa.vim.DistributedVirtualSwitch",
                                                         $self->{anchor});
                my $switchName = $dvsObj->getConfig($dvs)->getName();
                if ($switchName eq $vds) {
                   $portGroupName = $pgName;
                   last;
                }
             }
         }
      }
   };
   if ($@) {
      $vdLogger->Error("Failed to get port group names by vxlan id");
      InlineExceptionHandler($@);
      return FALSE;
   }
   return $portGroupName;
}


###############################################################################
#
# AddMultipleHostsToVDS--
#      This method would add multiple esx host to the VDS.
#
# Input:
#      $arrHostVmnicMapping - The input would be in two format:
#                   1. Just reference to array containing host objets
#                   2. Reference to array which will have following values
#                      Ref to array = [
#                                      {
#                                        'hostObj'  => reftohostObj1,
#                                        'vmnicObj' => ["reftoVmnic1",
#                                                       "reftoVmnic2"]
#                                      }
#                                      {
#                                        'hostObj'  => reftohostObj2,
#                                        'vmnicObj' => ["reftoVmnic1",
#                                                       "reftoVmnic2"]
#                                      }
#                                     ]
#
# Results:
#     TRUE  - if all hosts are added into the vds successfully.
#     FALSE - in case of error
#
# Side effects:
#      None.
#
###############################################################################

sub AddMultipleHostsToVDS
{
   my $self                   = shift;
   my $refArrHostVmnicMapping = shift;

   my $result = FALSE;
   eval {
      LoadInlineJavaClass('com.vmware.vcqa.TestConstants');
      my $TestUtil = CreateInlineObject("com.vmware.vcqa.util.TestUtil");

      my $hostMemberArray = [];
      foreach my $hostVmnicMapping (@$refArrHostVmnicMapping) {
         my $pnicSpecArray = [];
         my $vmnicArray = $hostVmnicMapping->{vmnicObj};

         if ((defined $vmnicArray) && (scalar @$vmnicArray)) {
             foreach my $hostVmnic (@$vmnicArray) {
                my $pnicSpec = CreateInlineObject(
                     "com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec");
                $pnicSpec->setPnicDevice($hostVmnic->{'vmnic'});
                push @$pnicSpecArray, $pnicSpec;
             }
         }
         my $pnicBacking = CreateInlineObject(
                  "com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking");
         $pnicBacking->getPnicSpec()->clear();
         $pnicBacking->getPnicSpec()->addAll(
                                      $TestUtil->arrayToVector($pnicSpecArray));
         my $hostMember = CreateInlineObject(
                  "com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec");
         $hostMember->setOperation($VDNetLib::InlineJava::VDNetInterface::com::vmware::vcqa::TestConstants::CONFIG_SPEC_ADD);
         my $hostObj = $hostVmnicMapping->{hostObj};
         my $inlineHostObject = $hostObj->GetInlineHostObject();
         my $hostMor = $inlineHostObject->{hostMOR};
         $hostMember->setHost($hostMor);
         $hostMember->setBacking($pnicBacking);
         push @$hostMemberArray, $hostMember;
      }

      my $dvsHelper = $self->{dvsHelper};
      my $dvsMor = $self->{dvsMOR};
      my $dvsConfigSpec = CreateInlineObject("com.vmware.vc.DVSConfigSpec");
      $dvsConfigSpec->setConfigVersion(
                       $dvsHelper->getConfig($dvsMor)->getConfigVersion());
      $dvsConfigSpec->setName(
                        $dvsHelper->getConfig($self->{dvsMOR})->getName());
      $dvsConfigSpec->getHost()->clear();
      $dvsConfigSpec->getHost()->addAll(
                               $TestUtil->arrayToVector($hostMemberArray));
      $result = $dvsHelper->reconfigure($dvsMor, $dvsConfigSpec);
   };
   if ($@) {
      $vdLogger->Error("Caught exception while adding hosts into vds.");
      InlineExceptionHandler($@);
      return FALSE;
   }

   return $result;
}
1;
