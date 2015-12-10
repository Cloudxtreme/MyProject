########################################################################
# Copyright (C) 2011 VMware, Inc.
# All Rights Reserved.
########################################################################

#
# testBackupRestore.pl--
# A unit test script to verify Backup and Restore module.
#

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../../";
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";

use constant FILE_OUTPUT_STREAM                 => 'java.io.FileOutputStream';
use constant FILE_INTPUT_STREAM                 => 'java.io.FileInputStream';
use constant DVS_SELECTION                      => 'com.vmware.vc.DVSSelection';
use constant DVS_PORTGROUP_SELECTION            => 'com.vmware.vc.DVPortgroupSelection';
use constant ENTITY_BACKUP_CONFIG               => 'com.vmware.vc.EntityBackupConfig';
use constant CONNECT_ANCHOR                     => 'com.vmware.vcqa.ConnectAnchor';
use constant DISTRIBUTED_VIRTUAL_SWITCH_MANAGER => 'com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager';
use constant DISTRIBUTED_VIRTUAL_PORTGROUP      => 'com.vmware.vcqa.vim.DistributedVirtualPortgroup';
use constant DISTRIBUTED_VIRTUAL_SWITCH         => 'com.vmware.vcqa.vim.DistributedVirtualSwitch';
use constant FOLDER                             => 'com.vmware.vcqa.vim.Folder';
use constant SESSION_MANAGER                    => 'com.vmware.vcqa.vim.SessionManager';

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                            InlineExceptionHandler);
use constant TRUE  => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;

VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel'    => 9,
                                               'logToFile'   => 0,
                                               'logFileName' => "vdnet.log");
if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::Common::VDLog object";
   exit 1;
}

# Input parameters - update them depending on your test setup
our $classPathDir = '/usr/local/staf/services/VMware5x/lib';
our $vcAddr = '10.112.26.49';

unless
     (GetOptions (
         "vc|vc=s"              => \$vcAddr,
         "classdir|classdir=s"  => \$classPathDir,
         )) {
     }

our $result = 0;

if (not defined $classPathDir) {
   print "--classdir paramater is empty\n";
   exit 1;
}

if (not defined $vcAddr) {
   print "--vc paramater is empty\n";
   exit 1;
}

$result = LoadInlineJava(DEBUG => 0,
                         DIRECTORY => '/tmp',
                         CLASSDIR  => $classPathDir,
                        );

print "** Inline Java module loaded successfully **\n";
CheckResult();


my $vcanchor;
my $sessionMgr;

$result = InitializeVCSession();
CheckResult();

#$result = ExportVDSCfg(dc        => 'NewDatacenter',
#                       vds       => 'dvSwitch',
#                       dvpg      => 'dvPortGroup',
#                       file_vds  => '/root/config-vds.bak',
#                       file_dvpg => '/root/config-dvpg.bak');
#CheckResult();

$result = ImportVDSCfg(dc        => 'NewDatacenter',
                       file_vds  => '/root/config-vds.bak',
                       file_dvpg => '/root/config-dvpg.bak');
CheckResult();

#$result = RestoreVDSCfg(dc => 'NewDatacenter', dvpgName => 'dvPortGroup');
#CheckResult();

#$result = ImportOrgVDSCfg(dc => 'NewDatacenter');
#CheckResult();

$result = CleanUpVCSession();
CheckResult();


sub CheckResult
{
   if (!$result) {
      exit $result;
   }
}


sub InitializeVCSession
{
   print "Initializing VC Session.\n";

   eval {
      # Create VC anchor and login to VC.
      $vcanchor = CreateInlineObject(CONNECT_ANCHOR, $vcAddr, "443");
      $sessionMgr = CreateInlineObject(SESSION_MANAGER, $vcanchor);
      $sessionMgr->login($vcanchor, "Administrator", "ca\$hc0w");
      print "Logged in to $vcAddr \n";
   };
   if ($@) {
      InlineExceptionHandler($@);
      print "Initializing VC Session failed.\n";
      return FALSE;
   }
   return TRUE;
}


sub ExportVDSCfg
{
   my %options = @_;

   my $dc          = $options{dc};
   my $vds         = $options{vds};
   my $dvpg        = $options{dvpg};
   my $file_vds    = $options{file_vds};
   my $file_dvpg   = $options{file_dvpg};
   
   print "Executing Export VDS configuration.\n";

   eval {
      # Create folderObj and goto given data center's network folder.
      my $folderObj = CreateInlineObject(FOLDER, $vcanchor);
      my $dcMor = $folderObj->getDataCenter($dc);
      my $netFolderMor = $folderObj->getNetworkFolder($dcMor);

      # Get VDS-MOR of the given VDS to get UUID.
      my $dvsMor = $folderObj->getDistributedVirtualSwitch($netFolderMor, $vds);

      # Create VDS and DVPG objects.
      my $iDVS = CreateInlineObject(DISTRIBUTED_VIRTUAL_SWITCH, $vcanchor);
      my $idvpg = CreateInlineObject(DISTRIBUTED_VIRTUAL_PORTGROUP, $vcanchor);

      # Create VDS and DVPG selection objects.
      my $dvsSS = CreateInlineObject(DVS_SELECTION);
      my $dvpgSS = CreateInlineObject(DVS_PORTGROUP_SELECTION);

      # Get the UUID of the VDS and set it to VDS selection set.
      my $dvsUUID = $iDVS->getConfig($dvsMor)->getUuid();
      $dvsSS->setDvsUuid($dvsUUID);

      # Get the key of the DVPG and set it to DVPG selection set.
      my $ephepg = $idvpg->getDVPortgroupByName($dvsMor, $dvpg);
      my $dvspgkey = $idvpg->getKey($ephepg);
      $dvpgSS->setDvsUuid($dvsUUID);
      $dvpgSS->getPortgroupKey()->clear();
      $dvpgSS->getPortgroupKey()->add($dvspgkey);

      # Get DVS MOR for exportEntity operation.
      my $iDVSMgr = CreateInlineObject(DISTRIBUTED_VIRTUAL_SWITCH_MANAGER, $vcanchor);
      my $dvsManagerMor = $iDVSMgr->getDvSwitchManager();

      # Create selection set and call exportEntity() method.
      my @selectionSet = ($dvsSS, $dvpgSS);
      my $backupConfig = [];
      $backupConfig = $iDVSMgr->exportEntity($dvsManagerMor, \@selectionSet);

      # Create the backup file for VDS and store the VDS config information in that file.
      my $out = CreateInlineObject(FILE_OUTPUT_STREAM, $file_vds);
      my @vdsSpec = $backupConfig->[0]->getConfigBlob();
      $out->write(@vdsSpec);
      $out->close();

      # Create the backup file for DVPG and store the DVPG config information in that file.
      my $out1 = CreateInlineObject(FILE_OUTPUT_STREAM, $file_dvpg);
      my @dvpgSpec = $backupConfig->[1]->getConfigBlob();
      $out1->write(@dvpgSpec);
      $out1->close();

      print "Successfully executed export VDS configuration.\n";
   };
   if ($@) {
      InlineExceptionHandler($@);
      print "Export VDS configuration failed.\n";
      return FALSE;
   }
   return TRUE;
} # End of ExportVDSCfg


sub ImportVDSCfg
{
   my %options = @_;

   my $dc          = $options{dc};
   my $file_vds    = $options{file_vds};
   my $file_dvpg   = $options{file_dvpg};

   eval {
      # Create folderObj and goto given data center's network folder.
      my $folderObj = CreateInlineObject(FOLDER, $vcanchor);
      my $dcMor = $folderObj->getDataCenter($dc); 
      my $netFolderMor = $folderObj->getNetworkFolder($dcMor);

      # Create objects to read VDS config from the file.
      my $backupConfig = [];
      $backupConfig->[0] = CreateInlineObject(ENTITY_BACKUP_CONFIG);
      $backupConfig->[0]->setName("testVDS");
      $backupConfig->[0]->setEntityType("distributedVirtualSwitch");
      $backupConfig->[0]->setContainer($netFolderMor);

      # Read the VDS configuration from the file.
      my $vdsSpec;
      open INF, $file_vds or die "\nCan't open $file_vds for writing: $!\n";
      binmode INF;
      read(INF, $vdsSpec, 6556);
      my @arr = unpack("c*", $vdsSpec);
      $backupConfig->[0]->setConfigBlob(\@arr);
      close(INF);

      # Get DVS MOR for importEntity operation.
      my $iDVSMgr = CreateInlineObject(DISTRIBUTED_VIRTUAL_SWITCH_MANAGER, $vcanchor);
      my $dvsManagerMor = $iDVSMgr->getDvSwitchManager();

      # Call importEntity() method.
      $iDVSMgr->importEntity($dvsManagerMor, $backupConfig, "createEntityWithNewIdentifier");

      # Create objects to read DVPG config from the file.
      my $backupConfig1 = [];
      $backupConfig1->[0] = CreateInlineObject(ENTITY_BACKUP_CONFIG);
      $backupConfig1->[0]->setName("testDVPG");
      $backupConfig1->[0]->setEntityType("distributedVirtualPortgroup");

      my $dvsMor = $folderObj->getDistributedVirtualSwitch($netFolderMor, "testVDS");

      $backupConfig1->[0]->setContainer($dvsMor);

      # Read the VDS configuration from the file.
      my $dvpgSpec;
      open INF1, $file_dvpg or die "\nCan't open $file_dvpg for writing: $!\n";
      binmode INF1;
      read(INF1, $dvpgSpec, 6556);
      my @arr1 = unpack("c*", $dvpgSpec);
      $backupConfig1->[0]->setConfigBlob(\@arr1);
      close(INF1);

      $iDVSMgr->importEntity($dvsManagerMor, $backupConfig1, "createEntityWithNewIdentifier");
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while executing ImportVDSCfg() method");
      return FALSE;
   }
   return TRUE;
} # End of ImportVDSCfg


sub RestoreVDSCfg
{
   my %options = @_;

   my $dc = $options{dc};
   my $dvpg = $options{dvpgName};

   eval {
      # Create folderObj and goto given data center's network folder.
      my $folderObj = CreateInlineObject(FOLDER, $vcanchor);
      my $dcMor = $folderObj->getDataCenter($dc); 
      my $netFolderMor = $folderObj->getNetworkFolder($dcMor);

      # Create objects to read VDS config from the file.
      my $backupConfig = [];
      $backupConfig->[0] = CreateInlineObject(ENTITY_BACKUP_CONFIG);
#      $backupConfig->[0]->setName("testVDS");
      $backupConfig->[0]->setEntityType("distributedVirtualSwitch");
      $backupConfig->[0]->setContainer($netFolderMor);

      # Read the VDS configuration from the file.
#      my $datasource = CreateInlineObject(FILE_DATA_SOURCE, "sampletest.bak");
#      my $handler = CreateInlineObject(DATA_HANDLER, $datasource);
#      $backupConfig->[0]->setConfigBlob($handler);

      # Get DVS MOR for importEntity operation.
      my $iDVSMgr = CreateInlineObject(DISTRIBUTED_VIRTUAL_SWITCH_MANAGER, $vcanchor);
      my $dvsManagerMor = $iDVSMgr->getDvSwitchManager();

      my $dvsMor = $folderObj->getDistributedVirtualSwitch($netFolderMor, "dvSwitch");
      my $iDVS = CreateInlineObject(DISTRIBUTED_VIRTUAL_SWITCH, $vcanchor);
      my $dvsUUID = $iDVS->getConfig($dvsMor)->getUuid();
      $backupConfig->[0]->setKey($dvsUUID);

      # Call importEntity() method.
      $iDVSMgr->importEntity($dvsManagerMor, $backupConfig, "applyToEntitySpecified");


      # Create objects to read DVPG config from the file.
      my $backupConfig1 = [];
      $backupConfig1->[0] = CreateInlineObject(ENTITY_BACKUP_CONFIG);
#      $backupConfig1->[0]->setName("testDVPG");
      $backupConfig1->[0]->setEntityType("distributedVirtualPortgroup");

      my $dvsMor1 = $folderObj->getDistributedVirtualSwitch($netFolderMor, "dvSwitch");

      $backupConfig1->[0]->setContainer($dvsMor1);

      # Read the VDS configuration from the file.
#      my $datasource1 = CreateInlineObject(FILE_DATA_SOURCE, "dvpgsampletest.bak");
#      my $handler1 = CreateInlineObject(DATA_HANDLER, $datasource1);
#      $backupConfig1->[0]->setConfigBlob($handler1);

      my $idvpg = CreateInlineObject(DISTRIBUTED_VIRTUAL_PORTGROUP, $vcanchor);
      my $ephepg = $idvpg->getDVPortgroupByName($dvsMor1, $dvpg);
      my $dvspgkey = $idvpg->getKey($ephepg);
      $backupConfig1->[0]->setKey($dvspgkey);

      $iDVSMgr->importEntity($dvsManagerMor, $backupConfig1, "applyToEntitySpecified");
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while executing RestoreVDSCfg() method");
      return FALSE;
   }
   return TRUE;
} # End of RestoreVDSCfg


sub ImportOrgVDSCfg
{
   my %options = @_;

   my $dc = $options{dc};

   eval {
      # Create folderObj and goto given data center's network folder.
      my $folderObj = CreateInlineObject(FOLDER, $vcanchor);
      my $dcMor = $folderObj->getDataCenter($dc); 
      my $netFolderMor = $folderObj->getNetworkFolder($dcMor);

      # Create objects to read VDS config from the file.
      my $backupConfig = [];
      $backupConfig->[0] = CreateInlineObject(ENTITY_BACKUP_CONFIG);
      $backupConfig->[0]->setName("testVDS");
      $backupConfig->[0]->setEntityType("distributedVirtualSwitch");
      $backupConfig->[0]->setContainer($netFolderMor);

      # Read the VDS configuration from the file.
#      my $datasource = CreateInlineObject(FILE_DATA_SOURCE, "sampletest.bak");
#      my $handler = CreateInlineObject(DATA_HANDLER, $datasource);
#      $backupConfig->[0]->setConfigBlob($handler);

      # Get DVS MOR for importEntity operation.
      my $iDVSMgr = CreateInlineObject(DISTRIBUTED_VIRTUAL_SWITCH_MANAGER, $vcanchor);
      my $dvsManagerMor = $iDVSMgr->getDvSwitchManager();

      # Call importEntity() method.
      $iDVSMgr->importEntity($dvsManagerMor, $backupConfig, "createEntityWithOriginalIdentifier");

      # Create objects to read DVPG config from the file.
      my $backupConfig1 = [];
      $backupConfig1->[0] = CreateInlineObject(ENTITY_BACKUP_CONFIG);
      $backupConfig1->[0]->setName("testDVPG");
      $backupConfig1->[0]->setEntityType("distributedVirtualPortgroup");

      my $dvsMor = $folderObj->getDistributedVirtualSwitch($netFolderMor, "testVDS");

      $backupConfig1->[0]->setContainer($dvsMor);

      # Read the VDS configuration from the file.
#      my $datasource1 = CreateInlineObject(FILE_DATA_SOURCE, "dvpgsampletest.bak");
#      my $handler1 = CreateInlineObject(DATA_HANDLER, $datasource1);
#      $backupConfig1->[0]->setConfigBlob($handler1);

      $iDVSMgr->importEntity($dvsManagerMor, $backupConfig1, "createEntityWithOriginalIdentifier");
   };
   if ($@) {
      InlineExceptionHandler($@);
      $vdLogger->Error("Exception thrown while executing ImportOrgVDSCfg() method");
      return FALSE;
   }
   return TRUE;
} # End of ImportOrgVDSCfg


sub CleanUpVCSession
{
   eval {
      # Logout from VC to close session.
      $sessionMgr->logout($vcanchor);
   };
   if ($@) {
      InlineExceptionHandler($@);
      print "Cleanup VC session failed.\n";
      return FALSE;
   }
   print "Logged out $vcAddr \n";
   return TRUE;
}

