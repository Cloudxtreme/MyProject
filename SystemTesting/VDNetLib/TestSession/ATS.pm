########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::TestSession::ATS;

#
# This package inherits VDNetLib::TestSession::TestSession Class.
# It stores attributes and implements method to run ATS tests.
#
#
use strict;
use warnings;

use base 'VDNetLib::TestSession::VDNetv2';

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use Storable 'dclone';
use VDNetLib::Common::Utilities;
use VDNetLib::Testbed::Testbedv2;
use VDNetLib::Common::ATSConfig;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);


########################################################################
#
# new --
#     Constructor to create an instance of
#     VDNetLib::TestSession::TestSessionv2
#
# Input:
#     Named hash parameters with following keys:
#     testcaseHash  : reference to vdnet test case hash (version 2)
#     userInputHash : reference to hash containing all user input
#                     TODO: check if all input is really required
#
# Results:
#     An object of VDNetLib::TestSession::TestSessionv2, if successful;
#     FAILURE, in case of any error
#
# Side effects:
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;

   my $self = VDNetLib::TestSession::VDNetv2->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::TestSession::VDNetv2" .
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $self->{'version'} = "ATS";
   bless $self, $class;

   return $self;
}


########################################################################
#
# RunTest --
#     Method to run test using the given testcase hash and testbed
#
# Input:
#     None
#
# Results:
#     SUCCESS, if testbed is created successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RunTest
{
   my $self = shift;
   my $result;

   #
   # Set properties in config file.
   # config.properties is read by ats which
   # contains vc,vsm ip etc.
   #
   $result = $self->SetATSConfigProperties();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to create the config.properties for ATS");
      VDSetLastError("EATS");
      return FAILURE;
   }

   #
   # compile the ats source based on changeset of the build
   # to be used for testing and trigger the run.
   #
   $result = $self->StartATS();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failure while running ATS Tests");
      VDSetLastError("EATS");
      return FAILURE;
   }
   $vdLogger->Info("Completed ATS Test run");
   return SUCCESS;
}


########################################################################
#
# SetATSConfigProperties--
#     This method is responsible for preparing the config.properties
#     file with required parameters.
#
# Input:
#     None
#
# Results:
#     SUCCESS, if testbed if file gets updated with all the options.
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetATSConfigProperties
{
   my $self = shift;
   my $logDir = $self->{logDir};
   my $test = $self->{userInputHash}{testframework}{options}{testareas};
   my $ip = $self->{userInputHash}{testframework}{options}{ip};
   my $testDNS = $self->{userInputHash}{testframework}{options}{dns};
   my $ip1 = $ip->{ip1};
   my $ip2 = $ip->{ip2};
   my $ip3 = $ip->{ip3};
   my $spoofguardIP1 = $ip->{spoofguard}->{1}->{ip};
   my $spoofguardIP2 = $ip->{spoofguard}->{2}->{ip};
   my $testDNSIP = $testDNS->{1}->{ip};
   my $netmask = $ip->{netmask};
   my $gateway = $ip->{gateway};
   my $dns1 = $ip->{dns1};
   my $dns2 = $ip->{dns2};
   my $result;
   my $configFile = "$logDir/config.properties";
   my @components = ("vc.[1]", "vsm.[1]", "host.[1]", "vc.[1].datacenter.[1]",
                      "vc.[1].datacenter.[1].cluster.[1].resourcepool.[1]",
                      "vc.[1].datacenter.[1].cluster.[1]");
   my @obj = ();
   for (my $index = 0; $index < scalar(@components); $index++) {
      $result = $self->{testbed}->GetComponentObject($components[$index]);
      if ($result eq FAILURE) {
         $vdLogger->Error("GetComponentObject failed for $components[$index]");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $obj[$index] = $result->[0];
   }
   my $vc = $obj[0];
   my $vsm = $obj[1];
   my $host = $obj[2];
   my $datacenter = $obj[3];
   my $resourcePool = $obj[4];
   my $cluster = $obj[5];
   my $vcIP = $vc->{vcaddr};
   my $vsmIP = $vsm->{ip};
   my $hostIP = $host->{hostIP};
   my $vsmUser = $vsm->{user};
   my $vsmPassword = $vsm->{password};
   my $vcUser = $vc->{user};
   my $vcPassword = $vc->{passwd};
   my $datacenterName = $datacenter->{datacentername};
   my $poolName = $resourcePool->{resourcePoolName};
   my $clusterName = $cluster->{clusterName};
   my $sampleFile = VDNetLib::Common::ATSConfig::ATSConfig;

   # get the vmfs volume on the esx host.
   my $storage = $self->{stafHelper}->GetCommonVmfsPartition($hostIP);
   if ($storage eq FAILURE) {
      $vdLogger->Error("Failed to find the vmfs datastore");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   #
   # copy config.properties file to the log directory
   # to run test from
   #
   `cp $sampleFile $logDir`;
   open (CONFIGFILE, ">>$configFile");
   print CONFIGFILE "vc.0.ip = $vcIP\n";
   print CONFIGFILE "vc.0.username = $vcUser\n";
   print CONFIGFILE "vc.0.password = $vcPassword\n";
   print CONFIGFILE "vc.0.defaultDatacenterName = $datacenterName\n";
   print CONFIGFILE "vc.0.defaultClusterName = $clusterName\n";
   print CONFIGFILE "vc.0.defaultResourcePoolName = $poolName\n";
   print CONFIGFILE "vsm.0.ip = $vsmIP\n";
   print CONFIGFILE "vsm.0.username = $vsmUser\n";
   print CONFIGFILE "vsm.0.password = $vsmPassword\n";
   print CONFIGFILE "vsm.0.subnetMask = $netmask\n";
   print CONFIGFILE "vsm.0.gateway = $gateway\n";
   print CONFIGFILE "vc.0.defaultHostSystemName = $hostIP\n";
   print CONFIGFILE "vc.0.defaultDatastoreName = $storage\n";
   print CONFIGFILE "sso.0.username = administrator\@vsphere.local\n";
   print CONFIGFILE "sso.0.password = $vcUser\n";
   print CONFIGFILE "sso.0.LookupServiceUrl = https://$vcIP/lookupservice/sdk\n";
   print CONFIGFILE "context = $test\n";
   print CONFIGFILE "vsm.0.dnsPrimary = $dns1\n";
   print CONFIGFILE "vsm.0.dnsSecondary = $dns2\n";
   print CONFIGFILE "dns.primary.server = $dns1\n";
   print CONFIGFILE "dns.secondary.server = $dns2\n";
   print CONFIGFILE "dns.network.gateway = $gateway\n";
   print CONFIGFILE "dns.network.subnet.mask = $netmask\n";
   print CONFIGFILE "dns.external.network.ip = $testDNSIP\n";
   if ($test eq "app") {
      print CONFIGFILE "vm.ip1 = $ip1\n";
      print CONFIGFILE "vm.ip2 = $ip2\n";
      print CONFIGFILE "vm.ip3 = $ip3\n";
      print CONFIGFILE "vm.spoofguard.ip1 = $spoofguardIP1\n";
      print CONFIGFILE "vm.spoofguard.ip2 = $spoofguardIP1\n";
      print CONFIGFILE "vm.netmask = $netmask\n";
      print CONFIGFILE "vm.gateway = $gateway\n";
      print CONFIGFILE "skipDeployVEsx = true\n";
   }

   #
   # if test is either edge or edge_trinity
   # then hpqc test id has to be of type edge.
   #
   if ($test =~ m/edge/i) {
      print CONFIGFILE "hpqc.edge.testSetId = xxxx\n";
   } else {
      print CONFIGFILE "hpqc.$test.testSetId = xxxx\n";
   }
   close CONFIGFILE;
}


########################################################################
#
# StartATSTestrun --
#     Method to start the ats test session.
#
# Input:
#     None
#
# Results:
#     SUCCESS, if testbed if test run is started.
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################


sub StartATSTestRun
{
   my $self = shift;
   my $test = shift;
   my $testID = shift;
   my $branch = shift;
   my $suite;
   my $suiteToSkip = "-DskipRT";
   my $homeDir = $self->{userInputHash}{testframework}{options}{basedir};
   my $workDir = $self->{userInputHash}{testframework}{options}{workdir};
   my $client = $VDNetLib::Common::ATSConfig::clients{$branch};
   my $testBaseDir = $workDir . "/" . $client . "/em/vshield-tests";
   $workDir = $workDir . "/" . $client;
   my $cmd;
   my @cmdOut;


   # check what test suite needs to be run.
   # TODO:
   # populate xml based on the testid's and put
   # them as part of BAT or Regression. If no
   # specific tests are specified it will run the
   # predefined set of tests by ATS for that particular
   # test area.
   #

   my @testCase = split ('\.', $testID);
   $suite = $testCase[-1];
   $cmd = "cp -f $self->{logDir}/config.properties $testBaseDir/$test/src/test/resources/config.properties";
   `$cmd >/dev/null 2>&1`;
    my $testDir = $testBaseDir . "/" . $test;
    if ( -d $testDir) {
       $vdLogger->Info("Running $suite tests for $test");
    } else {
       $vdLogger->Error("No test cases found for: $test in $testDir");
       VDSetLastError("EATS");
       return FAILURE;
    }
    chdir($testDir);
    if ($suite eq "BAT") {
       $suiteToSkip = "-DskipRT";
    } else {
       $suiteToSkip = "";
    }

    $cmd = "HOME=$workDir mvn test $suiteToSkip -Dmaven.repo.local=$workDir/.m2";
    $vdLogger->Info("Starting mvn command $cmd to run test");
    my $atsLog = $testDir . "/target/surefire-reports/TestSuite-output.txt";
    $vdLogger->Info("ATS test logs for this run are available in $atsLog");
    my @sumData = `$cmd`;
    return @sumData;
}


########################################################################
#
# CompileATSTest --
#     Method to compile the ATS test run.
#
# Input:
#     None
#
# Results:
#     SUCCESS, if ATS tests get compiled successfully.
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CompileATSTests
{
   my $self = shift;
   my $vShieldBranch = shift;
   my $baseDir = $self->{userInputHash}{testframework}{options}{basedir};
   my $workDir = $self->{userInputHash}{testframework}{options}{workdir};
   my $tests = $self->{userInputHash}{testframework}{options}{testareas};
   my $client = $VDNetLib::Common::ATSConfig::clients{$vShieldBranch};
   my $testBaseDir = $workDir . "/" . $client . "/em/vshield-tests";
   my $localCfg = $baseDir . "/localcfg";
   $workDir = $workDir . "/" . $client;
   my @testAreas = ();
   my $cmd;
   my $msg;
   my @cmdOut;

   #
   if (defined $tests) {
      @testAreas = split(',', $tests);
   }
   foreach my $test (@testAreas){
      # copy config.properties file to the test directory.
      $cmd = "cp -f $self->{logDir}/config.properties $testBaseDir/$test/src/test/resources/config.properties";
      $vdLogger->Debug($cmd);
      `$cmd`;
   }
   chdir($baseDir);
   `chmod -R 777 ats`;
   $vdLogger->Debug("cd $testBaseDir");
   my $result = chdir($testBaseDir);
   if (! $result) {
      $vdLogger->Error("Failed to change the working dir to $testBaseDir" .
                       " Error". $result);
      VDSetLastError("EATS");
      return FAILURE;
   }
   #Copy configs
   my $src = $localCfg . "/" . $vShieldBranch . "/makeVsm.sh";
   my $dst = $testBaseDir . "/scripts/";
   $cmd = "cp -f $src  $dst";
   @cmdOut = `$cmd`;

   # command to run mvn
   $cmd = "JAVA_DIR=$workDir/em/lib HOME=$workDir mvn install -DskipTests -DskipRT ".
          "-Dmaven.repo.local=$workDir/.m2";
   $vdLogger->Info("Compiling ATS Test source using $cmd");
   @cmdOut = `$cmd`;
   my $errorFlag = 0;
   foreach my $l (@cmdOut) {
      $vdLogger->Debug($l);
      if ($l =~ /COMPILATION ERROR/ ) {
          $errorFlag++;
      }
   }
   if ($errorFlag >0 ) {
      $vdLogger->Error("Failed to compile tests");
      VDSetLastError("EATS");
      return FAILURE;
   }
   return SUCCESS;;
}


########################################################################
#
# SyncATSTestSource --
#     Method to sync the ATS Test source.
#
# Input:
#    SyncTo - change number to which the test code would be synced,
#             typically it should be the change number of the build.
#    buildInfo - Information related to nsx buildinfo
#    p4client - perforce client name to be used.
#    vshieldbranch - name of the nsx manager branch.
#
# Results:
#     SUCCESS, if ATS tests get compiled successfully.
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################


sub SyncATSTestSource
{
   my $self = shift;
   my $syncTo = shift;
   my $buildInfo = shift;
   my $p4ClientName = shift;
   my $vShieldBranch = shift;
   my $baseDir = $self->{userInputHash}{testframework}{options}{basedir};
   my $workDir = $self->{userInputHash}{testframework}{options}{workdir};
   my $client = $VDNetLib::Common::ATSConfig::clients{$vShieldBranch};
   my $testBaseDir = $workDir . "/" . $client . "/em/vshield-tests";

   $vdLogger->Debug("Remove old test source");
   my $cmd = "rm -rf $baseDir/ats/";
   `$cmd`;

   $vdLogger->Debug("Remove old dtos from the maven repository");
   $cmd = "rm -rf $baseDir/.m2/repository/com/vmware/";
   `$cmd`;

   $vdLogger->Info("Check out tests");
   if (! VDNetLib::Common::ATSConfig::p4Login()) {
      $vdLogger->Info("Failed to login to perforce");
      VDSetLastError("EATS");
      return FAILURE;
   }
   my $sync = "";
   if ($syncTo eq "build" && defined $buildInfo->{change}) {
      $sync = "@" . $buildInfo->{change};
      $vdLogger->Debug("Syncing to $sync");
   } else {
      $vdLogger->Debug("Syncing to latest");
   }
   $cmd = VDNetLib::Common::ATSConfig::p4 . " -p " .
          VDNetLib::Common::ATSConfig::p4Server . " -u " .
          VDNetLib::Common::ATSConfig::p4User . " -c " .
          $p4ClientName . " sync -f //...$sync ";
   $vdLogger->Debug("$cmd");
   `$cmd`;

   $vdLogger->Info("Check for test case directory : " .  $testBaseDir);
   if ( -d $testBaseDir) {
       $vdLogger->Info("Test cases available for this branch: $vShieldBranch");
   } else  {
      $vdLogger->Error("No test cases available for this branch $vShieldBranch ".
                      "in  $testBaseDir");
      VDSetLastError("EATS");
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# CopyATSTestResults --
#     Method to copy the ATS results into vdnet directory.The ATS
#     surefireresults are populated in different location. This
#     method copies them to vdnet directory.
#     ToDo:
#     Copy these results
#
# Input:
#     test - Test area for which tests has been run (regression or BAT)
#
# Results:
#     SUCCESS, if ATS tests results get copied.
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################


sub CopyATSResults
{
   my $self = shift;
   my $test = shift;
   my $branch = shift;
   my $workDir = $self->{userInputHash}{testframework}{options}{workdir};
   my $client = $VDNetLib::Common::ATSConfig::clients{$branch};
   my $testBaseDir = $workDir . "/" . $client . "/em/vshield-tests";
   my $logDir = $self->{logDir};
   my $resultDir = $testBaseDir . "/". $test . "/target/surefire-reports";
   my $atsLog = $resultDir . "/TestSuite-output.txt";
   $vdLogger->Info("Copying ATS specific logs to $logDir");
   my $cmd = "cp -rf $resultDir $logDir";
   `$cmd`;
   $cmd = "cp -f $atsLog $logDir";
   `$cmd`;
}


########################################################################
#
# GetBuildDetails --
#     get build details like changeset etc.
#
# Input:
#     build: VSM build
#
# Results:
#     SUCCESS, if build info is retreived correctly.
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetBuildDetails
{
   my $self = shift;
   my $build = shift;
   my $buildType;
   my $result;

   if ($build =~ /ob-/i) {
      $buildType = "official";
   } elsif ($build =~ /sb-/i) {
      $buildType = "sandbox";
   }
   $result = VDNetLib::Common::FindBuildInfo::GetBuildInfo($build, $buildType);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failure to get build info for $build");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# StartATS --
#     main method to handle all the running/compiling/reporting
#     of ATS Tests.
#
# Input:
#     None
#
# Results:
#     SUCCESS, if ATS test run in successful.
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub StartATS
{
   my $self = shift;
   my $build = $self->{testbedSpec}->{vsm}->{1}->{build};
   my $buildInfo = $self->GetBuildDetails($build);
   my $buildKind = $buildInfo->{source} || "ob";
   my $vShieldBranch = $buildInfo->{branch};
   my $vShieldBuildNumber = $buildInfo->{id};
   my $username = $buildInfo->{username};
   my $syncTo = $self->{userInputHash}{testframework}{options}{sync} || "build";
   my @sumData;
   my $testResults = "";
   my $msg = "";
   my $testsRun     = 0;
   my $testsFail    = 0;
   my $testsError   = 0;
   my $testsSkipped = 0;
   my $duration = 0;
   my $timeString = 0;
   my $p4ClientName = $VDNetLib::Common::ATSConfig::p4Clients{"$vShieldBranch"};
   my $client = $VDNetLib::Common::ATSConfig::clients{"$vShieldBranch"};
   my $buildSource = $self->{userInputHash}{testframework}{options}{buildsource};
   my $workDir = $self->{userInputHash}{testframework}{options}{workdir};
   my $baseDir = $self->{userInputHash}{testframework}{options}{basedir};
   my $tests = $self->{userInputHash}{testframework}{options}{testareas};
   my $testID = $self->{testcaseHash}->{testID};
   my @testAreas = ();
   my $testBaseDir = $workDir . "/" .  $client . "/em/vshield-tests";
   my $result;
   my $resultHash = {};

   $vdLogger->Info("Starting test run for $vShieldBranch  $vShieldBuildNumber");

   if ($buildSource) {
      $result = $self->SyncATSTestSource($syncTo, $buildInfo,
                                     $p4ClientName,$vShieldBranch);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get the copy of latest test source");
         VDSetLastError("EATS");
         return FAILURE;
      }
   }

   $testResults = "";
   # compile the source
   if ($buildSource) {
      $result = $self->CompileATSTests($vShieldBranch);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failure while compiling ATS test source");
         VDSetLastError("EATS");
         return FAILURE;
      }
   } else {
      $vdLogger->Info("Using Pre compiled test source from $workDir");
   }

   #
   # check if test areas are defined.
   #
   if (defined $tests) {
      @testAreas = split(',', $tests);
   }
   chdir($baseDir);
   $testResults = "";
   my $failures = 0;
   foreach my $test (@testAreas) {
       @sumData = $self->StartATSTestRun($test, $testID, $vShieldBranch);
       my $saveResult = 0;
       $testResults .= "\nResult Summary for : " . $test . "\n\n";
       foreach my $line (@sumData) {
           $vdLogger->Info($line);
           $testsRun     = 0;
           $testsFail    = 0;
           $testsError   = 0;
           $testsSkipped = 0;
           $duration     = 0;
           if ($line =~ /^Tests run/ ) {
              if ($saveResult == 0) {
                 my @testData = split(/\, /,$line);
                 foreach my $e (@testData) {
                    if ($e =~ /Tests run/) {
                       my ($junk,$value) = split(/:/,$e);
                       $testsRun = VDNetLib::Common::ATSConfig::trim($value);
                       $vdLogger->Info("Tests Run: $testsRun");
                    } elsif ($e =~ /Failures/ ) {
                       my ($junk,$value) = split(/:/,$e);
                       $testsFail = VDNetLib::Common::ATSConfig::trim($value);
                       $vdLogger->Error("Tests Fail: $testsFail");
                       if ($testsFail ne 0) {
                          $failures++;
                       }
                    } elsif ($e =~ /Errors/ ) {
                       my ($junk,$value) = split(/:/,$e);
                       $testsError = VDNetLib::Common::ATSConfig::trim($value);
                       $vdLogger->Error("Tests Error: $testsError");
                       if ($testsError ne 0) {
                          $failures++;
                       }
                    } elsif ($e =~ /Skipped/ ) {
                       my ($junk,$value) = split(/:/,$e);
                       $testsSkipped = VDNetLib::Common::ATSConfig::trim($value);
                       $vdLogger->Info("Tests Skipped: $testsSkipped");
                    } elsif ($e =~ /Time elapsed/ ) {
                       my ($junk,$value) = split(/:/,$e);
                       $duration = VDNetLib::Common::ATSConfig::trim($value);
                       $duration =~ s/,//g;
                       $vdLogger->Info("Tests Time: $duration");
                    }
                 }
                 #$timeString =  convert_time($duration);
               }
               $saveResult = 1;
           }
           if ($line =~ /^\[INFO/) {
               $saveResult = 0;
           }
           if ($saveResult == 1) {
               $testResults .= $line;
           }

       }

       # copy results
       $result = $self->CopyATSResults($test, $vShieldBranch);
   }

   # set the test result for vdnet to report FAIL or PASS.
   if ($failures eq 0) {
      $vdLogger->Info("all tests passed");
      $self->{result} = "PASS";
   } else {
      $vdLogger->Error("One or test failed/skipped please ".
                       "see the surefire reports for details");
      $self->{result} = "FAIL";
   }

   #
   # copy surefire results.
   # TO BE DECIDED - how we want to proceed with
   # respect racetrack, surefire, hpqc.
   #$result = $self->CopySureFireResults();
}

1;
