########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::TestSession::VCQE;

#
# This class inherits VDNetLib::TestSession::VDNetv2 class.
# It stores attributes and implements methods to run VCQE tests
#
use strict;
use warnings;

use base 'VDNetLib::TestSession::VDNetv2';

use FindBin;
use lib "$FindBin::Bin/../";

use JSON;
use Data::Dumper;
use XML::LibXML;
use File::Basename;
use Storable 'dclone';
use VDNetLib::Common::FindBuildInfo;
use VDNetLib::Common::Utilities;
use VDNetLib::Testbed::Testbedv2;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);


#######################################################################
#
# new --
#     Constructor to create an instance of
#     VDNetLib::TestSession::VCQE
#
# Input:
#     Named hash parameters with following keys:
#     testcaseHash  : reference to vdnet test case hash (version 2)
#     userInputHash : reference to hash containing all user input
#
#
# Results:
#     An object of VDNetLib::TestSession::VCQE
#
# Side effects :
#     None
#
# #####################################################################

sub new
{
   my $class = shift;
   my %options = @_;

   my $self = VDNetLib::TestSession::VDNetv2->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::TestSession::VDNetv2".
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   bless $self, $class;
   return $self;
}


########################################################################
#
# GetTestwareBuildType --
#    Method to get the type of the testware build (official/sandbox)
#
# Input:
#    buildNum : build number
#
#
# Results:
#    Build type (ob/sb)
#
# Side effects:
#    None
#
########################################################################

sub GetTestwareBuildType
{
   my $self = shift;
   my $buildNum = shift;
   my $buildType = undef;
   my $buildInfo = undef;
   # Get the build information using official build url
   $buildInfo = VDNetLib::Common::FindBuildInfo::GetBuildInfo($buildNum);
   if (defined ($buildInfo->{'buildsystem'}) ) {
      $buildType=$buildInfo->{'buildsystem'};
   } else {
      # Get the build information using sandbox build url
      $buildInfo = VDNetLib::Common::FindBuildInfo::GetBuildInfo($buildNum,
                   "sandbox");
      if(defined ($buildInfo->{'buildsystem'}) ){
         $buildType=$buildInfo->{'buildsystem'};
      }
   }
   return $buildType;
}

#########################################################################
#
# GetTestwareBuild --
#    Method to download and unzip the testware build
#
# Input:
#    None
#
# Results:
#    None
#
# Side effects:
#    None
#
#########################################################################

sub GetTestwareBuild
{
   my $self = shift;
   my $buildNum = $self->{userInputHash}{testframework}{options}{build};
   my $endpoint = $self->{userInputHash}{testframework}{options}{endpoint};
   # "endpoint" has to be defined in the yaml file, fail otherwise
   if (not defined $endpoint) {
      $vdLogger->Error("No endpoint provided in yaml file");
      VDSetlastError("EFAIL");
      return FAILURE;
   }
   my $componentObj = $self->{testbed}->GetComponentObject($endpoint);
   # If componentObj returned has a FAILURE, there might be problems with
   # retrieval of nodes from zookeeper or they may not exist.
   # Return failure in these cases.
   if ($componentObj eq FAILURE) {
      $vdLogger->Error("GetComponentObject failed for $endpoint");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # If testware build number was not provided in the yaml file,
   # try retrieving the build number from vc endpoint
   if (not defined $buildNum ) {
      # No testware build number was provided, take the build number from endpoint
      # If the endpoint is vc, get the vc ipaddress from the component object
      $vdLogger->Info("Testware build is not provided, trying to get".
                       " the data from endpoint information");
      if (index ($endpoint, "vc") != -1) {
         $vdLogger->Info("Endpoint is a vCenter server.".
                         "Trying to get the testware build from vc... ");
         my $ipaddress = $componentObj->[0]->{vcaddr};
         $buildNum = VDNetLib::Common::FindBuildInfo::GetBuildNumber($ipaddress);
      } else {
         # If endpoint is not a vc server, prompt the user to specify
         # a build number and return FAILURE
         $vdLogger->Error("Endpoint is not a vCenter server.".
                          "Please specify testware build number in yaml");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   $vdLogger->Debug("Testware build number = $buildNum");
   my $buildType = $self->GetTestwareBuildType($buildNum);
   $vdLogger->Info("Testware build type = $buildType");
   my $baseDir = VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FOLDER;
   my $testBuildDir = $baseDir."/vcqe-".$buildNum;
   $self->{vcqeBuildDir} = $testBuildDir;
   if (! (-d $testBuildDir) ) {
      $vdLogger->Info("Downloading testware build ".$buildNum." into".
                     " directory ".$testBuildDir);
      my $createDirCmd = `mkdir -p $testBuildDir`;
      my $baseUrl = undef;
      my $suffixUrl = "/publish/vcqetestwarezip.zip";
      if($buildType eq "ob") {
         $baseUrl = VDNetLib::Common::GlobalConfig::BUILDWEB."bora-";
      } else {
         $baseUrl = VDNetLib::Common::GlobalConfig::BUILDWEB."sb-";
      }
      my $url = $baseUrl.$buildNum.$suffixUrl;
      $vdLogger->Info("Testware build url = $url");
      my $downloadCmd = `wget --directory-prefix=$testBuildDir $url 2>&1`;
      $vdLogger->Info("Downloading vcqetestware package : $downloadCmd");
      # If the link does not have the testware build, try an alternate link
      if(index($downloadCmd, "404") != -1){
         $suffixUrl = "/compcache/vcqetestwarezip/".$buildType."-".$buildNum.
                      "/windows-2008/vcqetestwarezip.zip";
         $url = $baseUrl.$buildNum.$suffixUrl;
         $vdLogger->Info("Trying a different url for vcqetestwarezip : $url");
         $downloadCmd = `wget --directory-prefix=$testBuildDir $url 2>&1`;
         $vdLogger->Info($downloadCmd);
      }
      my $unzipCmd = `unzip $testBuildDir/vcqetestwarezip.zip -d $testBuildDir 2>&1`;
      my $deleteCmd = `rm -f $testBuildDir/vcqetestwarezip.zip 2>&1`;
   } else {
      $vdLogger->Info("Testware build ".$buildNum." is already ".
                      "downloaded in folder ".$testBuildDir);
   }
}

##########################################################################
#
# SetVCQEConfigProperties --
#    Method to set the properties in config.properties file
#
# Input:
#    None
#
# Results:
#    returns FAILURE if an erroneous path is taken
#
# Side effects:
#    None
#
##########################################################################

sub SetVCQEConfigProperties
{
   my $self = shift;
   my $hostname = undef;
   my $username = undef;
   my $password = undef;
   my $esxPasswd = undef;
   my $endpoint = $self->{userInputHash}{testframework}{options}{endpoint};
   my $componentObj = $self->{testbed}->GetComponentObject($endpoint);
   if ($componentObj eq FAILURE || not defined $componentObj) {
      $vdLogger->Error("GetComponentObject failed for $endpoint");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $testBuildDir = $self->{vcqeBuildDir};
   if (index ($endpoint, "vc") != -1) {
      $hostname = $componentObj->[0]->{vcaddr};
      $username = $componentObj->[0]->{user};
      $password = $componentObj->[0]->{passwd};
      my $esxComponentObj = $self->{testbed}->GetComponentObject("host.[-1]");
      if ($esxComponentObj eq FAILURE || not defined $esxComponentObj) {
         $vdLogger->Error("GetComponentObject failed for host.[-1]");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $esxPasswd = $esxComponentObj->[0]->{password};
   } elsif (index ($endpoint, "host")!= -1) {
      $hostname = $componentObj->[0]->{hostIP};
      $username = $componentObj->[0]->{userid};
      $password = $componentObj->[0]->{password};
      $esxPasswd = $password;
   } else {
      $vdLogger->Error("$endpoint cannot be used as endpoint for ".
                       "running vcqe tests");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # Populate the config.properties based on these values
   my $configFile = $testBuildDir."/resources/config.properties";
   # Replace default property values with the new values
   $vdLogger->Debug("Esx host passwd is: $esxPasswd ");
   `sed -i 's/\\(hostname=\\).*/\\1$hostname/g' $configFile`;
   `sed -i '0,/username=/{s/\\(username=\\).*/\\1$username/}' $configFile`;
   `sed -i '0,/password=/{s/\\(password=\\).*/\\1$password/}' $configFile`;
   `sed -i '0,/esx.password=/{s/\\(esx.password=\\).*/\\1$esxPasswd/}' $configFile`;
}

#########################################################################
#
# StartVCQETestRun --
#    Method to start the vcqe test run
#
# Input:
#    None
#
# Results:
#    None
#
# Side effects:
#    None
#
#########################################################################

sub StartVCQETestRun
{
   my $self = shift;
   my $testBuildDir = $self->{vcqeBuildDir};
   my ($vcqe, $testID) =
       split(/VCQE./, $self->{testcaseHash}->{testID}, 2);
   return $self->ExecuteVCQETest($testID);
}


#########################################################################
#
# ExecuteVCQETest --
#     Method to execute the vcqe test class or the test suite
#
# Input:
#     testID - test class to be executed
#
# Results:
#     SUCCESS, if test was run successfully and it passed
#     FAILURE, if test failed
#
# Side effects:
#     None
#
#########################################################################

sub ExecuteVCQETest
{
   my $self = shift;
   my $testID = shift;
   my $testBuildDir = $self->{vcqeBuildDir};
   my $resultDir = undef;
   my $testResult = 1;
   my $outcome = 0;
   my $runlistDir = $self->{userInputHash}{testframework}{options}{runlistpath};
   my @antCmdResults = undef;
   my $testName = "security.setup.SecurityTestsSetup";
   $ENV{CLASSPATH} = $ENV{CLASSPATH} . ":$testBuildDir/lib/testng-6.8-nobsh-guice.jar";
   $vdLogger->Debug("Classpath:" . $ENV{CLASSPATH});
   #
   # Run test case security.setup.SecurityTestsSetup for vc/esx to create ACL users.
   #
   $vdLogger->Info("Executing test $testName to create ACL users.");
   @antCmdResults = `ant -buildfile $testBuildDir/build.xml \\
                     -Dbase.dir=$testBuildDir run-class -Dclass.name=$testName`;
   if (index ($testID, ".xml") != -1) {
      # If a test suite xml file is specified, make sure that runlist path
      # is defined in the yaml file, return FAILURE otherwise
      if (not defined $runlistDir) {
         $vdLogger->Error("No runlist path defined for $testID in yaml");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      # Get the absolute path of the test/test suite
      my $filename=$testBuildDir."/".$runlistDir."/".$testID;
      $vdLogger->Info("Executing test suite $testID");
      @antCmdResults = `ant -buildfile $testBuildDir/build.xml \\
                        -Dbase.dir=$testBuildDir run-tests -Dsuite=$filename`;
   } else {
      $vdLogger->Info("Executing test $testID");
      @antCmdResults = `ant -buildfile $testBuildDir/build.xml \\
                        -Dbase.dir=$testBuildDir run-class -Dclass.name=$testID`;
   }
   # Iterate through the results of executing ant command
   for my $result(@antCmdResults){
      $vdLogger->Info($result);
      if (index ($result, "Created dir") != -1) {
         my @parts = split(/ /, $result);
         for my $part (@parts) {
            if (index ($part, "/") != -1) {
               $resultDir = $part;
               $vdLogger->Info("Please find all relevant test log(s) for ".
                               "$testID in $resultDir");
               last;
            }
         }
      }
      if (index ($result, "OUTCOME") != -1) {
         # The test has an outcome. Check whether this outcome is PASS
         $outcome = 1;
         #TODO: Once the test result reporting interface is finalized,
         # revisit this part to collect the necessary data and publish
         # it to the interface
         if (index ($result, "PASS") != -1) {
            $testResult &= 1;
         } else {
            $testResult &= 0;
         }
      }
   }
   if (!$outcome) {
      $vdLogger->Error("There was no test outcome... ".
                       "Test may not exist, please check the test class name");
   }
   if ($testResult && $outcome) {
      return SUCCESS;
   } else {
      return FAILURE;
   }
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
#     SUCCESS, if test is run successfully
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RunTest
{
   my $self = shift;
   my $result = FAILURE;
   $self->{'result'} = "FAIL";

   #
   # Download the testware build as specified in the build parameter
   #
   if ($self->GetTestwareBuild() ne FAILURE) {
      $self->SetVCQEConfigProperties();
      $result = $self->StartVCQETestRun();
      # TODO: Result reporting for VCQE tests needs to be revisited
      if ($result eq SUCCESS) {
         $self->{'result'} = "PASS";
      }
   }
   return $result;
}
1;
