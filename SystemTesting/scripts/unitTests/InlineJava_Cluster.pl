########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved.
########################################################################

#
# inlineJava.pl--
#  A unit test script to verify Inline::Java CPAN module
#  Sample code as tests can be added here for reference
#
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../../";
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler ConfigureLogger
                                         StopInlineJVM);
use VDNetLib::InlineJava::VM;
use VDNetLib::InlineJava::Folder;
use VDNetLib::InlineJava::Cluster;

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
our $classPathDir = "/usr/local/staf/services/VMware5x/lib";
our $vcAddr = "10.117.7.167";
our @hosts;

my $anchor    = undef;
my $vmx       = "WinXP";
my $vmName    = $vmx;
my $vmMOR     = undef;
my $host      = "10.111.6.33";
my $user      = "root";
my $password  = 'ca$hc0w';

my $host1 = "10.111.6.37";
my $port  = VDNetLib::Common::GlobalConfig::INLINE_JVM_INITIAL_PORT;

our $result = 0;
$result = LoadInlineJava(DEBUG => 0,
                         DIRECTORY => '/tmp',
                         CLASSDIR  => $classPathDir,
                         PORT => $port
                        );

print "** Inline Java module loaded successfully **\n";

if ( 0 ) {
   # Test CreateLinkedClone
   our $vcanchor = CreateInlineObject(CONNECT_ANCHOR, $vcAddr, "443");
   our $sessionMgr = CreateInlineObject(SESSION_MANAGER, $vcanchor);

   our $self->{folderObj} = CreateInlineObject("com.vmware.vcqa.vim.Folder", $vcanchor);
   #my $dcMor = $folderObj->getDataCenter("MyDC");

   # Create a VM object;
   my $vmObj = VDNetLib::InlineJava::VM->new('anchor' => $anchor,
                                                 'vmx'   => $vmx,
                                                 'vmName'    => $vmx,
                                                 'vmMOR'  => $vmMOR,
                                                 'host'  => $host,
                                                 'user'  => $user,
                                                 'password'  => $password);

   my $newVMName = $vmx . "_lc";
   $vmObj->CreateLinkedClone( 'templateVM' => $vmx,
                              'cloneVMName' => $newVMName);
}

if ( 1 ) {
   # Test CreateCluster
   my $vcanchor = CreateInlineObject(CONNECT_ANCHOR, $vcAddr, "443");
   my $sessionMgr = CreateInlineObject(SESSION_MANAGER, $vcanchor);
   $sessionMgr->login($vcanchor, "Administrator", 'ca$hc0w');
   $vdLogger->Info("Logged in to $vcAddr\n");

   my $basefolderObj = CreateInlineObject("com.vmware.vcqa.vim.Folder", $vcanchor);
   my $baseVmObj = CreateInlineObject("com.vmware.vcqa.vim.VirtualMachine", $vcanchor);

   # Creating a new datacenter
   my $dcname = "NewDC";
   my $managedEntity = CreateInlineObject("com.vmware.vcqa.vim.ManagedEntity", $vcanchor);
   my $rootFolderMor = $managedEntity->getRootFolder();

   my $newDCMor = $basefolderObj->createDatacenter($rootFolderMor, $dcname);
   my $hostFolderMor = $basefolderObj->getHostFolder($newDCMor);

   my $folderObj = VDNetLib::InlineJava::Folder->new('anchor' => $vcanchor);

   my $clusterSpec = $folderObj->CreateClusterSpec();
   my $clusterMor = $folderObj->CreateCluster( 'parentFolderMor' => $hostFolderMor,
                                               'clusterName' => "MyCluster",
                                               'clusterSpec' => $clusterSpec );

   my $clusterConfigSpec = $folderObj->CreateClusterConfigSpecEx();
   my $clusterObj = VDNetLib::InlineJava::Cluster->new('anchor' => $vcanchor);
   $vdLogger->Info("Reconfigure Cluster");
   my $ReConfigRes = $clusterObj->ReconfigureClusterEx( 'compResMor' => $clusterMor,
                                                        'clusterSpec' => $clusterConfigSpec);
   $vdLogger->Info("Result of ReconfigureCluster ->  $ReConfigRes");

   $vdLogger->Info("Configuring DRS");
   my $SetDRSRes = $clusterObj->SetDRS( 'compResMor' => $clusterMor,
                                        'enable' => 1);
   $vdLogger->Info("Result of SetDRS ->  $SetDRSRes");

   $vdLogger->Info("Configuring DAS(HA)");
   my $SetDASRes = $clusterObj->SetDAS( 'compResMor' => $clusterMor,
                                        'enable' => 1,
                                        'admissionControl' => 0,
                                        'failoverLevel' => 1,
                                        'isolationResponse' => "none",
                                        'waitHAConf' => 0);
   $vdLogger->Info("Result of SetDAS ->  $SetDASRes");

   my $host1 = "10.111.6.33";
   $vdLogger->Info("Adding host $host1 to datacenter $dcname on VC $vcAddr\n");
   my $hostCnxSpec = $folderObj->CreateHostConnectSpec ( 'hostName' => $host1 );
   $folderObj->AddHost( 'hostCnxSpec' => $hostCnxSpec,
                        'folderMor' => $hostFolderMor);

   $vdLogger->Info("Creating VM Object");
   my $vmObj = VDNetLib::InlineJava::VM->new('anchor' => $vcanchor,
                                             'vmx'   => $vmx,
                                             'vmName'    => $vmx,
                                             'vmMOR'  => $vmMOR,
                                             'host'  => $vcAddr,
                                             'user'  => "Administrator",
                                             'password'  => 'ca$hc0w');

   $vdLogger->Info("Get VM Mor of a given VM name");
   my $vmMor = $vmObj->GetVMByName( 'vmName' => $vmx );
   $vdLogger->Info("Returned VM Mor of $vmx is $vmMor");

   $vdLogger->Info("Trying to turn on Fault Torlence");
   $vmObj->CreateSecondaryVM( 'vmSrcMor' => $vmMor );
}

StopInlineJVM();

