########################################################################
# Copyright (C) 2011 VMware, Inc.
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
                                            InlineExceptionHandler);
use VDNetLib::VC::InlineJavaVC;

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
our $classPathDir;
our $vcAddr;
our @hosts;

unless
     (GetOptions (
         "vc|vc=s"              => \$vcAddr,
         "classdir|classdir=s"  => \$classPathDir,
         "hosts|hosts=s"        => \@hosts
         )) {
     }

our $result = 0;

our ($host1, $host2) = ($hosts[0], $hosts[1]);

if (not defined $classPathDir) {
   print "--classdir paramater is empty\n";
   exit 1;
}

if (not defined $vcAddr) {
   print "--vc paramater is empty\n";
   exit 1;
}

if (not defined $host1) {
   print "--hosts paramater is empty\n";
   exit 1;
}

$host2 = (not defined $host2) ? $host1 : $host2;


$result = LoadInlineJava(DEBUG => 0,
                         DIRECTORY => '/tmp',
                         CLASSDIR  => $classPathDir,
                        );

print "** Inline Java module loaded successfully **\n";
CheckResult();

# Sample 1
$result = AddRemoveHost();
CheckResult();

# Sample 2
$result = UpdateVCAdvancedSettings();
CheckResult();

# Sample 3
$result = InvalidLogin();
CheckResult();

# Sample 4
$result = CreateDeleteDVS();
CheckResult();

sub CheckResult
{
   if (!$result) {
      exit $result;
   }
}



sub AddRemoveHost
{

   eval {
      print "Running Add/Remove Host test\n";
      my $vcanchor = CreateInlineObject("com.vmware.vcqa.ConnectAnchor",
                                        $vcAddr, "443");
      my $sessionMgr = CreateInlineObject("com.vmware.vcqa.vim.SessionManager",
                                          $vcanchor);
      $sessionMgr->login($vcanchor, "Administrator", "ca\$hc0w");

      my $folderObj = CreateInlineObject("com.vmware.vcqa.vim.Folder", $vcanchor);
      my $dcObj = CreateInlineObject("com.vmware.vcqa.vim.Folder", $vcanchor);
      my $managedEntity = CreateInlineObject("com.vmware.vcqa.vim.ManagedEntity", $vcanchor);

      my $rootFolderMor = $managedEntity->getRootFolder();
      my $dcname = "Inline-dc-" . $$;
      $folderObj->createDatacenter($rootFolderMor, $dcname);

      my $dcMor = $folderObj->getDataCenter($dcname);

      my $hostFolderMor = $folderObj->getHostFolder($dcMor);

      my $hostCnxSpec1 = CreateInlineObject("com.vmware.vc.HostConnectSpec");
      $hostCnxSpec1->setHostName($host1);
      $hostCnxSpec1->setUserName("root");
      $hostCnxSpec1->setPassword("ca\$hc0w");
      $hostCnxSpec1->setPort(443);

      print "***Adding host $host1 to datacenter $dcname on VC $vcAddr\n";
      $folderObj->addStandaloneHost($hostFolderMor, $hostCnxSpec1, undef, 1, undef);

      sleep 30;

      my $hostFolder = $dcObj->getHostFolder($dcMor);
      my $hostFolderObj = $managedEntity->getChildEntity($hostFolder);
      $managedEntity->destroy($hostFolderObj);
      $managedEntity->asyncDestroy($dcMor);
   };

   if ($@) {
      InlineExceptionHandler($@);
      print "Add/Remove host test failed\n";
      return FALSE;
   }
   print "Add/Remove host test passed\n";
   return TRUE;
}


sub CreateDeleteDVS
{
   my $dcname;
   my $dvsMor;
   my $dcMor;
   my $managedEntity;
   eval {
      print "Running CreateDelete DVS test\n";
      my $vcanchor = CreateInlineObject("com.vmware.vcqa.ConnectAnchor",
                                        $vcAddr, "443");
      my $sessionMgr = CreateInlineObject("com.vmware.vcqa.vim.SessionManager",
                                          $vcanchor);
      $sessionMgr->login($vcanchor, "Administrator", "ca\$hc0w");

      my $folderObj = CreateInlineObject("com.vmware.vcqa.vim.Folder", $vcanchor);
      my $dcObj = CreateInlineObject("com.vmware.vcqa.vim.Folder", $vcanchor);
      $managedEntity = CreateInlineObject("com.vmware.vcqa.vim.ManagedEntity", $vcanchor);

      my $rootFolderMor = $managedEntity->getRootFolder();
      $dcname = "Inline-dc-" . $$;
      $dcMor = $folderObj->createDatacenter($rootFolderMor, $dcname);
   };

   my $vcObj = VDNetLib::VC::InlineJavaVC->new($vcAddr, "Administrator",
                                              "ca\$hc0w");
   if (!$vcObj) {
      print "failed to create InlineJavaVC object\n";
      return $vcObj;
   }
   $dvsMor = $vcObj->CreateDistributedVirtualSwitch(dvsName => "inlineVDS-$$",
                                                    datacenter => $dcname);
   if (!$dvsMor) {
      print "Failed to create DVS\n";
   }

   sleep 10;
   print "Deleting DVS\n";
   if (!$vcObj->DeleteDistributedVirtualSwitch($dvsMor)) {
      print "Failed to delete create DVS\n";
   }

   eval {
      $managedEntity->asyncDestroy($dcMor);
   };

   if ($@) {
      InlineExceptionHandler($@);
      print "Create Delete DVS test failed\n";
      return FALSE;
   }

   print "Create Delete DVS test passed\n";
   return TRUE;
}


sub UpdateVCAdvancedSettings
{

   print "Running VC Advanced configuration test\n";
   my $key = "config.vpxd.macAllocScheme.prefixScheme.prefix";
   my $value = "00c029";
   my $vcObj = VDNetLib::VC::InlineJavaVC->new($vcAddr, "Administrator",
                                           "ca\$hc0w");
   if (!$vcObj) {
      print "failed to create InlineJavaVC object\n";
      return $vcObj;
   }

   print "Updating key $key with value $value\n";
   if (!$vcObj->UpdateVPXDConfigValue($key, $value)) {
      print "Updating key $key with value $value failed\n";
      return TRUE;
   }
   sleep 10;

   print "Current value of $key:" . $vcObj->GetVPXDConfigValue($key) . "\n";
   print "VC Advanced configuration test passed\n";
   return TRUE;
}

sub InvalidLogin
{
   eval {
      print "Running Invalid login test\n";

      my $vcanchor = CreateInlineObject("com.vmware.vcqa.ConnectAnchor",
                                        $vcAddr, "443");
      my $sessionMgr = CreateInlineObject("com.vmware.vcqa.vim.SessionManager",
                                          $vcanchor);
      # pass invalid user name
      $sessionMgr->login($vcanchor, "Admin", "ca\$hc0w");
   };

   if ($@) {
      my $exception = $@;
      if (Inline::Java::caught("com.vmware.vc.InvalidLogin")) {
         InlineExceptionHandler($exception);
         print "Invalid Login test passed\n";
         return TRUE;
      } else {
         print "Invalid Login test failed\n";
         return FALSE;
      }
   }
}
