#!/usr/bin/perl
########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::Session::Session;

#
# This class has attributes and methods to process and maintain
# VDNet's session information.
#
use strict;
use warnings;
use List::MoreUtils ':all';

# Load modules
use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../TDS/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use Config;
use Data::Dumper;
use File::Copy;
use File::Basename;
use Cwd qw(abs_path);
use Archive::Tar;
use JSON;
use Memory::Usage;
use Switch;
use Storable 'dclone';
use Inline::Python qw(eval_python
                      py_bind_class
                      py_study_package
                      py_call_function
                      py_call_method
                      py_is_tuple);
use Getopt::Long qw(GetOptions GetOptionsFromString);
use VDNetLib::Common::Utilities;
use YAML::XS qw{ Dump Load LoadFile DumpFile };
use VDNetLib::Common::STAFHelper qw(@stafTrash);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   SKIP VDCleanErrorStack);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler ConfigureLogger
                                         StopInlineJVM);
use VDNetLib::TestSession::VCQE;
use VDNetLib::TestSession::MH;
use VDNetLib::Common::ZooKeeper;
use VDNetLib::Common::VDLog qw(@levelStr);
use constant TEMP_STAF_DIR => '/tmp/stafdir';
use constant PASS => VDNetLib::Common::GlobalConfig::PASS;
use constant FAIL => VDNetLib::Common::GlobalConfig::FAIL;
use constant TRUE => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;

########################################################################
#
# new--
#     Contructor to create an instance of VDNetLib::Session::Session
#
# Input:
#     Reference to a hash which has VDNet's command line parameters
#     as key/values
#
# Results:
#     An object of VDNetLib::Session::Session, if successful;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;

   my $self = {
      'cliParams'       => $options{'cliParams'},
      'tcpport'         => undef,
      'zkPort'          => undef,
      'inlineJavaPort'  => undef,
      'zkDataDir'       => undef,
      'testLevel'       => 'complete',
      'sortTests'       => 'default',
      'cacheTestbed'    => 0,
      'mirrors'         => undef,
      'interactive'     => 0,
      'exitOnInteractive' => FALSE,
      'mailto'          => undef,
      'testcaseList'    => undef,
   };
   bless ($self, $class);
   my $result = $self->ConfigureLogging(
                           'logDirName' => $self->{'cliParams'}{'logDirName'},
                           'logLevel'    => $self->{'cliParams'}{'logLevel'},
                           'logFileLevel'=> $self->{'cliParams'}{'logFileLevel'},
                           'logToConsole'=> $self->{'cliParams'}{'logToConsole'},
                        );

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to configure logger for vdnet session");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # fill in the master controlIP here
   my $masterControlIP = VDNetLib::Common::Utilities::GetLocalIP();
   if ($masterControlIP eq FAILURE) {
      $vdLogger->Error("Unable to Get master controller IP");
      return FAILURE;
   }
   # change the option list array into a string
   $vdLogger->Info("Executing VDNet $self->{'cliParams'}{optionsList} from ".
                   "$FindBin::Bin on $masterControlIP");

   my $commitId = `cd $FindBin::Bin/.. && git rev-parse --verify HEAD`;
   $vdLogger->Info("Current commit id: $commitId");
   # PR 1224718 cleanup stale processes
   my $cleanCmd = "python $FindBin::Bin/../scripts/cleanup_stale_process.py " .
             "--logdir $self->{logDir}";
   $result = system($cleanCmd);
   if ($result) {
      $vdLogger->Error("System command \"$cleanCmd\" failed with " .
                       "return code $result");
   }

   if (FAILURE eq $self->ProcessAndValidateCLI()) {
      $vdLogger->Error("Failed to process and validate VDNet CLI options");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{'currentTestSession'} = undef;
   if (!$self->{'stafGroupPID'}) {
      $self->{'stafGroupPID'} = undef;
   }
   if (!$self->{'stafCfgDir'}) {
      $self->{'stafCfgDir'} = undef;
   }
   $self->{'zookeeperObj'} = undef;
   $self->{'autoupgrade'} = $self->{'userInputHash'}{'options'}{'autoupgrade'};
   $self->{'noCleanup'} = $self->{'userInputHash'}{'options'}{'nocleanup'};
   if (exists $self->{'userInputHash'}{'testframework'}) {
      $self->{'testframeworkOptions'} = $self->{'userInputHash'}{'testframework'}{'options'};
      if (exists $self->{'testframeworkOptions'}{'inventory'}) {
         copy($self->{'testframeworkOptions'}{'inventory'}, $vdLogger->{logDir} . 'inventory.py')
      }
   }
   $self->{'memoryCheckObj'} = Memory::Usage->new();
   $self->{'memoryCheckObj'}->record("", $$);

   return $self;
}


########################################################################
#
# Initialize--
#     Method to initialize session. This involves:
#     - starting STAF, if required;
#     - starting Inline JVM
#     - do initial cleanup
#
# Input:
#     None
#
# Results:
#     SUCCESS, if session is initialized successfully,
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub Initialize
{
   my $self = shift;
   #
   # Get the reference host based on which few initialization is done.
   # Example: Get the VMODL checksum of reference host and get corresponding
   # STAF SDK build.
   #
   my $testHost = $self->GetReferenceHost();

   if (FAILURE eq $self->StartZookeeperSession()) {
      $vdLogger->Error("Failed to start zookeeper session");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (FAILURE eq $self->SavePIDToFile("zookeeper")) {
      $vdLogger->Error("Failed to open file of watchdog PIDs");
   }

   # Try to start STAF SDK services if they are not already running
   if (not defined $self->{tcpport}) {
      if (not defined $ENV{STAFSDKBLD}) {
         my $stafVersion = `STAF local vm version`;
         if ($stafVersion =~ /build number:\s(\d+)/) {
            $vdLogger->Info("STAF is already running with build: $1 ");
         } else {
            #
            # First, ensure there are no stale STAFProcs running using
            # the config file from TEMP_STAF_DIR
            #
            my $processName = 'STAFProc ' . TEMP_STAF_DIR . '/STAF.cfg';
            my @pid = VDNetLib::Common::Utilities::GetProcessInstances($processName);
            my $retry = 5;
            while ((scalar(@pid)) && ($retry)) {
               $vdLogger->Debug("Killing stale STAFProc: $pid[0]");
               my $ret = `kill -9 $pid[0] 2>&1`;
               if ($ret ne "") {
                  $vdLogger->Debug("Kill $pid[0] returns $ret");
               }
               sleep 2;
               $retry--;
               @pid = VDNetLib::Common::Utilities::GetProcessInstances($processName);
            }
            if (scalar(@pid)) {
               $vdLogger->Error("Existing/stale STAFProc could not be cleaned");
               $vdLogger->Debug("List of stale processes:" . Dumper(@pid));
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }
            my $stafDefaultCfgDir = "$FindBin::Bin/../bin/staf";
            my $tempCfgDir = TEMP_STAF_DIR;
            # check if temp dir for staf exists
            if (-d "$tempCfgDir") {
               `rm -f "$tempCfgDir/start.sh"`;
            } else {
               system("mkdir -p $tempCfgDir");
               system("chmod", "ugo+rw", "$tempCfgDir");
            }
            `cp $stafDefaultCfgDir/start.sh $tempCfgDir`;
            $ENV{STAFCFGDIR} = $stafDefaultCfgDir;
            $vdLogger->Info("Running STAF from $tempCfgDir");
            if (FAILURE eq $self->StartSTAFProc($tempCfgDir)) {
               $vdLogger->Error("Failed to start STAFproc");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      } elsif (defined $ENV{STAFSDKBLD}) {
         if (FAILURE eq $self->StartSTAF($testHost)) {
            $vdLogger->Error("Failed to start STAF");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         if (FAILURE eq $self->SavePIDToFile("staf")) {
            $vdLogger->Error("Failed to open file of watchdog PIDs");
         }
      } else {
         $vdLogger->Error("Invalid details passed to start STAF");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   $self->ConfigurePythonPackages();

   #
   # Create a stafhelper object which can use for the ENTIRE vdnet session
   #
   if (FAILURE eq $self->CreateSTAFHelper()) {
      $vdLogger->Error("Failed to create STAFHelper object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # TODO: add ability to get what is the main component/product being tested
   # i.e vSphere, or NSX. For cases, where there is no ESX involved the
   # following block is not required and should be replaced with
   # code to get build information of NSX or whatever product under
   # test
   if (defined $testHost) {
      my ($build, $branch, $buildType, $version) =
         VDNetLib::Host::HostOperations::GetBuildInfoForRacetrack($testHost);
      if (defined $vdLogger->{rtrackObj}) {
         my $result = $vdLogger->SetRacetrackBuildInfo($build, $branch, $buildType);
         if ($result != 1) {
            $vdLogger->WARN("Update Racetrack info failed");
         } else {
            $vdLogger->Debug("Racetrack build info updated.");
         }
      }
   }


   $self->InitialCleanup(); # best effort cleanup
   if (FAILURE eq $self->StartInlineJVM()) {
      $vdLogger->Error("Failed to start Inline JVM process");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
#  SavePIDToFile--
#     Method to save associated PID to file which will be used by
#     vdnet-watchdog.pl
#
# Input:
#     component : whose PID we will save
#     jvmPort : Port used by JVM
#
# Results:
#     "SUCCESS", if all the entries are correct;
#     "FAILURE", in case of any error;
#
# Side effects:
#
########################################################################

sub SavePIDToFile
{
   my $self = shift;
   my $component = shift;
   my $jvmPort = shift;
   my $watchdogFH;
   my $watchdog_pid_filename;

   $watchdog_pid_filename = $self->{'logDir'} . "/" .
                   (VDNetLib::Common::GlobalConfig::WATCHDOG_PID_FILENAME);
   $vdLogger->Debug("watchdog PID file name is $watchdog_pid_filename");

   if (not defined open($watchdogFH, ">> " . $watchdog_pid_filename )) {
      $vdLogger->Error("Unable to open file $watchdog_pid_filename");
      return FAILURE;
   }
   switch ($component) {
      case  m/(zookeeper)/i {
         my $zkPID = $self->{'zookeeperObj'}{'pid'};
         print $watchdogFH  $zkPID;
         print $watchdogFH  "\n";
         last;
      }
      case m/(staf)/i {
         if ( $self->{'stafGroupPID'}) {
            print $watchdogFH  $self->{'stafGroupPID'};
            print $watchdogFH  "\n";
            $vdLogger->Debug("STAF group PID is $self->{'stafGroupPID'}");
         }
         last;
      }
      case m/(inlinejava)/i {
         my $javaString = "grep InlineJavaServer | grep $jvmPort";
         my $javaProcess = `ps ax | grep -v grep | $javaString`;
         my @pidList = split(/\n/, $javaProcess);

         foreach my $childPID (@pidList) {
            $childPID =~ s/^\s+//;
            my @pidInfo = split(/ /, $childPID);
            if ($pidInfo[0] =~ /\d+/) {
               print $watchdogFH  $pidInfo[0];
               print $watchdogFH  "\n";
               $vdLogger->Debug("JVM PID is $pidInfo[0]");
            }
         }
         last;
      }
      else {
         last;
      }
   }

   close $watchdogFH;
   return SUCCESS;
}

########################################################################
#
# ProcessAndValidateCLI--
#     Method to process and validate the user input options (CLI)
#     to vdnet.
#
# Input:
#     None
#
# Results:
#
# Side effects:
#
########################################################################

sub ProcessAndValidateCLI
{
   my $self = shift;

   my $cliParams = $self->{'cliParams'};
   my $forceClean = FALSE;

   #1229291 check which kind of clean
   if ((defined $cliParams->{testbed}) && ($cliParams->{testbed} =~ /clean/i)) {
      my $input = "";
      print "Entering interactive mode...\n\n\n";
      print ("Do you want cleanup VMs deployed on cloud(y or n)?");
      $input .= <STDIN>;
      chomp($input);
      if ($input =~ /^y.*/i) {
         print ("Got it! You want cloud VMs cleaned.\n");
         $forceClean = TRUE;
      } else {
         print ("I see! You want to keep deployed VMs in cloud.\n");
      }
   }

   $self->{'skipSetup'} = (defined $cliParams->{'skipSetup'}) ? 1 : 0;
   $self->{'hosted'}    = (defined $cliParams->{'hosted'}) ? 1 : 0;
   $self->{'hostlist'}  = $cliParams->{'hostlist'};
   $self->{'vmlist'}    = $cliParams->{'vmlist'};
   $self->{'sut'}       = $cliParams->{'sut'};
   $self->{'helper'}    = $cliParams->{'helper'};
   $self->{'cacheTestbed'} = $cliParams->{'cachetestbed'};
   $self->{'noTools'}        = 0;
   $self->{'keepTestbed'} = 1; # default is 1

   if (defined $cliParams->{configJSON}) {
      $self->{userInputHash} = VDNetLib::Common::Utilities::ConvertJSONToHash(
                                                   $cliParams->{configJSON}
                                                );
      if ($self->{userInputHash} eq FAILURE) {
         $vdLogger->Error("Failed to convert user config from json to hash");
         $vdLogger->Debug("Given JSON config: $cliParams->{configJSON}");
         $self->{userInputHash} = undef;
      }
   } elsif (defined $cliParams->{configYAML}) {
      my $userInputHash;
      my $custom_yaml_file = undef;
      if (defined $cliParams->{custom_yaml}){
         $custom_yaml_file = $cliParams->{custom_yaml};
      }
      my $overriding_key = 'options';
      eval {
         VDNetLib::InlinePython::VDNetInterface::LoadInlinePythonModule("vdnet_spec");
         # FIXME(Prabuddh): Add back logging for once the issue
         # with duplicated KeysDB loading is fixed
         # $userInputHash = py_call_function(
         #   "vdnet_spec", "configure_logging", $self->{logDir});
         $userInputHash = py_call_function(
            "vdnet_spec", "load_yaml_with_overrides", $cliParams->{configYAML},
            $self->{logDir}, 1, $custom_yaml_file, $overriding_key);
      };
      if ($@ or ! $userInputHash) {
         $vdLogger->Error("Failed to convert user config from yaml to hash: $@");
         $vdLogger->Debug("Given YAML config: $cliParams->{configYAML}");
         $self->{userInputHash} = undef;
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $self->{userInputHash} = $userInputHash;
   }

   # Change the keys in user options to lower case
   my $userOptions = $self->{'userInputHash'}{'options'};
   %$userOptions = (map { lc $_ => $userOptions->{$_}} keys %{$userOptions});
   # update the original
   $self->{'userInputHash'}{'options'} = $userOptions;

   # For all the options cli will have the 1st priority followed by config file
   my $sharedStorage = (defined $cliParams->{'sharedStorage'}) ?
       $cliParams->{'sharedStorage'} :
       $userOptions->{sharedstorage};

   # If user passed shared storage details use that, otherwise use default one
   $sharedStorage = (defined $sharedStorage) ? $sharedStorage :
                     VDNetLib::Common::GlobalConfig::DEFAULT_SHARED_SERVER . ":" .
                     VDNetLib::Common::GlobalConfig::DEFAULT_SHARED_SHARE;
   $self->{sharedStorage} = $sharedStorage;

   $vdLogger->Debug("Shared storage to use: $sharedStorage");

   #
   # Update vdnet source information. This is required
   # to mount source code on remote hosts and virtual machines
   #
   my $vdNetSrc = $cliParams->{'src'} || $userOptions->{src};
   ($self->{'vdNetSrc'}, $self->{vdNetShare}) =
      VDNetLib::Common::GlobalConfig::GetSourceDir($vdNetSrc);
   if ($self->{'vdNetSrc'} eq FAILURE) {
      $vdLogger->Error("Failed to get vdnet source information");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $vdnetOptions = $cliParams->{'vdnetOptions'};
   $self->{'noTools'} = ((defined $vdnetOptions) &&
                         $vdnetOptions =~ /notools/i) ? 1 :
                         ((defined $userOptions->{notools}) &&
                          ($userOptions->{notools} eq 1)) ? 1 : 0;

   $self->{'collectLogs'} = ((defined $vdnetOptions) &&
                             $vdnetOptions =~ /collectlogs/i) ? 1 :
                             ((defined $userOptions->{collectlogs}) &&
                              ($userOptions->{collectlogs} eq 1)) ? 1 : 0;
   my $vmRepository = $cliParams->{repository} ||
                      $userOptions->{vmrepos};
   if (defined $vmRepository) {
      ($self->{vmServer}, $self->{vmShare})  = split(/:/, $vmRepository);
      $vdLogger->Info("Setting VM repository as " . $self->{vmServer} . ":" .
                      $self->{"vmShare"});
   } else {
      $self->{vmServer} = VDNetLib::Common::GlobalConfig::DEFAULT_VM_SERVER;
      $self->{vmShare}  = VDNetLib::Common::GlobalConfig::DEFAULT_VM_SHARE;
   }

   if (defined $self->{userInputHash}{testframework}) {
      my $framework = $self->{userInputHash}{testframework}{name};
      my $supportedFramework = VDNetLib::Common::GlobalConfig::supportedframework;
      if ($supportedFramework !~ /$framework/i) {
         $vdLogger->Error("Invalid execution framework specified ".
                          "self->{'framework'} ".
                          "valid ones are $supportedFramework");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }
   my $podspec = $userOptions->{podspec};
   if (defined $podspec && $podspec !~ /\//i) {
       $vdLogger->Debug("podspec does not begin with /, so prefix with automation");
       my $mycwd = VDNetLib::Common::Utilities::GetVDNETSourceTree();
       my $auto = "\/automation";
       my $autolen = length $auto;
       my $index = index( $mycwd, $auto);
       $mycwd = substr($mycwd, 0, $index + $autolen);
       $podspec = "$mycwd/$podspec";

       # assert referenced podspec exists
       if (! -e $podspec) {
           $vdLogger->Error("referenced podspec $podspec does not exist");
           return FAILURE;
       }
   }
   $self->{'podSpec'} = $podspec;
   $self->{'contexts'} = $userOptions->{contexts};

   if (not defined $userOptions->{snapshotdir}) {
       my $userName = $ENV{USER} || $ENV{USERNAME};
       $userOptions->{snapshotdir} = "/tmp/$userName-snapshot";
       $vdLogger->Info("Snapshot directory not specified, autogenerating " .
           "snapshot in location $userOptions->{snapshotdir}");
   } else {
       $vdLogger->Info("Using user-defined snapshot directory: " .
                       "$userOptions->{snapshotdir}");
   }

   #
   # If thread limits specified include them in $self
   #
   # Store maxWorker value if specified
   $self->{'maxWorkers'} = (defined $userOptions->{maxworkers}) ?
                            $userOptions->{maxworkers} : undef;

   if (defined $self->{'maxWorkers'}) {
      $vdLogger->Debug("maxWorkers specifed and is $self->{maxWorkers}");
   }

   # Store maxWorkeTimeout value if specified
   $self->{'maxWorkerTimeout'} = (defined $userOptions->{maxworkertimeout}) ?
                                  $userOptions->{maxworkertimeout} : undef;

   if (defined $self->{'maxWorkerTimeout'}) {
      $vdLogger->Debug("maxWorkerTimeout specifed and is $self->{maxWorkerTimeout}");
   }

   #
   # If custom max workload timeout specified include it in $self
   #
   # Store maxWorkloadTimeout value if specified
   $self->{'maxWorkloadTimeout'} = (defined $userOptions->{maxworkloadtimeout}) ?
                            $userOptions->{maxworkloadtimeout} : undef;

   if (defined $self->{'maxWorkloadTimeout'}) {
      $vdLogger->Debug("maxWorkloadTimeout specifed and is $self->{maxWorkloadTimeout}");
   }

   # Update the environment variable STAFSDKBLD (which is already
   # implemented/used) based on user input from yaml/json
   #
   if (defined $userOptions->{stafsdkbuild}) {
      $ENV{STAFSDKBLD} = $userOptions->{stafsdkbuild};
      $vdLogger->Debug("Using the user-specified staf sdk: $ENV{STAFSDKBLD}");
   }
   #
   # processing options for sorting and testbed setup optimization
   #
   if (defined $userOptions->{cachetestbed}) {
      if ($userOptions->{cachetestbed} == 1) {
         $self->{cacheTestbed} = 1;
         $self->{sortTests} = $userOptions->{sorttests};
         #
         # if value for sorttests option is not given, but cachetestbed
         # is set to 1, then set sorttests to use 'testbed' as value
         # for better runtime optimization
         #
         if (not defined $self->{sortTests}) {
            $self->{sortTests} = "testbed";
            $vdLogger->Info("Cache testbed option is given, using " .
                            "$self->{sortTests} sorting");
         } else {
            $vdLogger->Info("cache testbed option is given, using ".
                            "user specified $self->{sortTests} sorting");
         }
      }
   }
   my $testbedDeployment = (defined $cliParams->{testbed} &&
                            $cliParams->{testbed}) || $userOptions->{testbed};
   if ($self->{cacheTestbed} && (defined $testbedDeployment)) {
      $vdLogger->Error("Both testbed:save/reuse/cleanup and cachetestbed:0/1 " .
                       "specified, only one option is supported in same session");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ((defined $testbedDeployment) && ($testbedDeployment =~ /reuse|clean/i)) {
      my $confDir = $userOptions->{snapshotdir};
      my $fileOut = `cat $confDir/vdnet.conf`;
      $ENV{STAF_INSTANCE_NAME} = $1 if ($fileOut =~ /STAF_INSTANCE_NAME=(.*)/);
      if (!defined $ENV{ONECLOUD_REUSE}) {
          $ENV{ONECLOUD_REUSE} = 1;
      }
      $self->{tcpport} = $1 if ($fileOut =~ /STAFPORT=(\d+)/);
      $self->{zkPort} = $1 if ($fileOut =~ /ZOOKEEPERPORT=(\d+)/);
      $self->{inlineJavaPort} = $1 if ($fileOut =~ /INLINEJAVAPORT=(\d+)/);
      $self->{zkDataDir} = $1 if ($fileOut =~ /ZOOKEEPERDATA=(.*)/);
      $self->{stafHandle} = $1 if ($fileOut =~ /STAFHANDLE=(.*)/);
      $self->{'stafCfgDir'} =  $1 if ($fileOut =~ /STAF_CONFIG_DIR=(.*)/);
      $self->{'stafGroupPID'}  = $1 if ($fileOut =~ /STAF_GROUP_PID=(\d+)/);
      $self->{'nsxSDKInstallPath'} = $1 if ($fileOut =~ /NSX_SDK_PATH=(.*)/);
      $self->{'testbedJSON'} = $1 if ($fileOut =~ /TESTBED=(.*)/);
      $self->{'testLevel'} = ($testbedDeployment =~ /reuse/i) ?
                             'workloadsOnly' : 'cleanupOnly';
   } else {
      #
      # Zookeeper entry lives in shapshotDir, so create if it does not
      # already exist
      #
      my ($mkdirRet, $mkdirOut) = VDNetLib::Common::Utilities::ExecuteBashCmd(
        "mkdir -p $userOptions->{snapshotdir}");
      if ($mkdirRet) {
          my $userName = $ENV{USER} || $ENV{USERNAME};
          $vdLogger->Error("Failed to create $userOptions->{snapshotdir} " .
                           "directory on the launcher. Please ensure that " .
                           "user: $userName has correct permissions");
          VDSetLastError("EINVALID");
          return FAILURE;
      }

      #
      # If vdnet in --testbed save mode preemtively remove vdnet.conf from
      # possible previous vdnet --testbed save run
      #
      if ((defined $testbedDeployment) && ($testbedDeployment =~ /save/i)) {
         $self->{'vdnetConf'} = $userOptions->{snapshotdir} . "/vdnet.conf";
         my ($rmRet, $rmOut) = VDNetLib::Common::Utilities::ExecuteBashCmd(
            "rm -f $self->{'vdnetConf'}");
         if ($rmRet) {
            my $userName = $ENV{USER} || $ENV{USERNAME};
            $vdLogger->Error("Could not remove $self->{'vdnetConf'}" .
               "ensure that user: $userName has permissions");
             VDSetLastError("EINVALID");
            return FAILURE;
         }
         $self->{'testLevel'} = 'deployOnly';
      } else {
         $self->{testLevel} = 'complete';
      }
   }
   $vdLogger->Debug("Given testbed deployment option is $self->{'testLevel'}");

   if (defined $userOptions->{keeptestbed}) {
      $self->{keepTestbed} = $userOptions->{keeptestbed};
   }
   if ($forceClean == TRUE) {
      $self->{keepTestbed} = 0;
   } elsif ((defined $cliParams->{testbed}) &&
      ($cliParams->{testbed} =~ /clean/i)) {
      $self->{keepTestbed} = 1;
   }

   if (defined $cliParams->{userTestbedSpec}) {
      my $userTestbedSpec = $cliParams->{userTestbedSpec};
      my $result = $self->LoadTestbedSpec($userTestbedSpec);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to load testbed spec $userTestbedSpec");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{userTestbedSpec} = $result;
   }
   $self->{testRunId} = $userOptions->{testrunid};

   my $racetrack = $userOptions->{racetrack};
   if((defined $racetrack) && $racetrack !~ m/@/) {
      $vdLogger->Error("Incorrect value supplied for racetrack in the config file. ".
                       "Please add it like this: yourname\@racetrack-dev.eng.vmware.com.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if(defined $racetrack && ($racetrack ne '')){
      my $desc = "$self->{testLevel} ". join(" ", @{$cliParams->{tdsIDs}});
      if ($vdLogger->SetRacetrack($racetrack, $desc) eq 'FAILURE') {
         $vdLogger->Warn("Failed to set racetrack");
      }
      my $hostUnderTest = 'xxxxx';
      if (1 == $vdLogger->Start("VDNet configuration and cleanup",
                                "VDNet automation framework",
                                $hostUnderTest,
                                "VDNet Session")) {
         $vdLogger->Warn("Failed to start racetrack session");
      } else {
      $vdLogger->Info("Racetrack link generated from yaml options: http://" .
                       $vdLogger->{rtrackInfo}{'server'} . "/result.php?id=" .
                       $vdLogger->GetRacetrackId());
      }
   }
   $self->{'interactive'} = $cliParams->{interactive} ||
                           $userOptions->{interactive};
   if (defined $self->{'interactive'}) {
      $vdLogger->Info("Interactive option given: $self->{'interactive'}");
      if ((defined $cliParams->{exitoninteractive}) &&
         ($cliParams->{exitoninteractive} =~ /true/i)) {
         $vdLogger->Info("Option to exit on $self->{'interactive'} given");
         $self->{exitOnInteractive} = TRUE;
      }
   }
   $self->{yamlWins}  = 0;
   if (defined $userOptions->{mirrors}{staf}) {
      $ENV{VDNET_STAF_MIRROR} = $userOptions->{mirrors}{staf};
   }
   if (defined $userOptions->{mirrors}{toolchain}) {
      $ENV{VDNET_TOOLCHAIN_MIRROR} = $userOptions->{mirrors}{toolchain};
   }
   if (defined $userOptions->{mailto}) {
      my @temp = split(",", $userOptions->{mailto});
      $self->{mailto} = \@temp;
   }
   return SUCCESS;
}


########################################################################
#
# GetReferenceHost--
#     Method to get reference host for the given vdnet session
#
# Input:
#     None
#
# Results:
#     host: ip address of the reference host;
#     undef: if no reference host is defined
# Side effects:
#     None
#
########################################################################

sub GetReferenceHost
{
   my $self = shift;

   my $host = undef;
   my @temp;
   # 1355098: Both 'defined' and 'exists' add keys if key does not exist.
   # For example, when use following condition:
   # if (exists $self->{userInputHash}{testbed}{host}{'[1]'}{ip})
   # when there is no key '[1]' in host spec, after this if clause, key
   # '[1]' will be added into host spec with value {};
   if (exists $self->{userInputHash}{testbed}{host}) {
      my $hostList = $self->{userInputHash}{testbed}{host};
      foreach my $item (keys %$hostList) {
         if (defined $hostList->{$item}{ip}) {
            $host = $hostList->{$item}{ip};
            $vdLogger->Debug("Reference host $host");
            last;
         }
      }
   } elsif (exists $self->{userInputHash}{testbed}{esx}) {
      my $hostList = $self->{userInputHash}{testbed}{esx};
      foreach my $item (keys %$hostList) {
         if (defined $hostList->{$item}{ip}) {
            $host = $hostList->{$item}{ip};
            $vdLogger->Debug("Reference host $host");
            last;
         }
      }
   } elsif (defined $self->{'cliParams'}{'sut'}) {
      @temp = split(/,/, $self->{'cliParams'}{'sut'});
      #
      # braces required, otherwise "Use of implicit split to @_ is
      # deprecated?" error will be thrown
      #
      (undef, $host) = split(/:/, $temp[0]);
   } elsif ($self->{'cliParams'}{'hostlist'}) {
      @temp = split(/,/, $self->{'cliParams'}{'hostlist'});
      $host = $temp[0];
   } elsif (defined $self->{userInputHash}{hosts}) {
      my $hosts = $self->{userInputHash}{hosts};
      foreach my $item (keys %$hosts) {
         if ($item =~ /\./) { # look for . (dot) in $item
            $host = $item;
            last;
         }
      }
   } else {
      $vdLogger->Warn("No reference host provided");
   }
   return $host;
}


########################################################################
#
# ListKeys--
#     This method provides detailed description about all keys defined
#     in vdnet.
#
# Input:
#     workloadName :  name of the workload whose key list need to be
#                     listed
#
# Results:
#     SUCCESS, if all the keys for given workload is printed;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ListKeys
{
   my $self     = shift;
   my $listKeys = shift;

   my $module = "VDNetLib::Workloads::" . $listKeys . "Workload";
   eval "require $module";
   if ($@) {
      $vdLogger->Error("Failed to load package $module " . $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $dbHash = $module->GetKeysTable();

   require Text::Table;

   my $prettyPrint = Text::Table->new();
   my $value = [];
   $prettyPrint->add('Keyname', 'Type', 'Format', 'Parameters');
   foreach my $entry (keys %$dbHash) {
      my $params = (defined $dbHash->{$entry}{params}) ?
                    join(',', @{$dbHash->{$entry}{params}}) : "none";
      $prettyPrint->add($entry, $dbHash->{$entry}{type},
                        $dbHash->{$entry}{format}, $params);
   }
   $vdLogger->Info("Keys database for $listKeys\n" . $prettyPrint->stringify());
   # Creating JSON file for UI integration
   my $jsonfile = $self->{logDir} . "/" . $listKeys . "-keysDB.json";
   my $result = open FILE, ">$jsonfile";
   if (not defined $result) {
      $vdLogger->Error("Could not open file $jsonfile: $!");
      return undef;
   }
   printf FILE encode_json($dbHash);
   close FILE;
   $vdLogger->Info("Keysdatabase dumped to $jsonfile");
   return SUCCESS;
}


########################################################################
#
# GetVMList --
#      This sub-routine gives the list of VMs (files/folder) under the
#      given the network server and share folder.
#
# Input:
#      server: ip/name of the server
#      share : name of the nfs share
#
# Results:
#      A scalar variable, list of all VMs, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetVMList {
   my $self   = shift;
   my $server = shift;
   my $share  = shift;

   my $mountPoint = VDNetLib::Common::GlobalConfig::DEFAULT_VM_MOUNTPOINT;
   # unmount if the repository exists already
   my $command = "mount 2>&1";
   my $result = `$command`;
   my $temp   = "on " . $mountPoint . " ";
   if ($result =~ /$temp/) {
      $command = "umount " . $mountPoint;
      $result  = `$command`;
   }

   # create the directory (name defined as constant $mountPoint)
   $command = "mkdir " . $mountPoint . " 2>&1";
   $result = `$command`;
   if (($result ne "") && ($result !~ /exists/i)) {
      $vdLogger->Error("Unable to create directory ". $mountPoint);
      $vdLogger->Error($result);
      return FAILURE;
   }


   # Mount the given the network share on $mountPoint
   $command = "sudo mount " . $server . ":" . $share . " /" .
              $mountPoint;
   $vdLogger->Debug("GetVMList mount command:$command");
   $result = `$command 2>&1`;
   if (($result ne "") && ($result !~ /already/i)) {
      $vdLogger->Error("Unable to mount $server" . ":" . "$share on " .
                       $mountPoint);
      $vdLogger->Error($result);
      return FAILURE;
   }

   #
   # Get the list of files available after mounting the network share.
   # List the directory that has vmx file in it. Assuming the directory that
   # has .vmx file as a VM folder.
   #
   $command = "ls " . $mountPoint;
   $result = `$command`;
   my @array = split(/\n/,$result);
   my $vms = "";
   foreach my $dir (@array) {
      $command = "ls " . $mountPoint . "/". $dir .
                 "/" . "*.vmx" . " >/dev/null 2>&1";
      if(!system($command)) {
         $vms = join("\n", $vms, $dir);
      }
   }
   return $vms;
}


########################################################################
#
# PrintListOfTDSIDS --
#      Method to print all Test Case IDs
#
# Input:
#      tds: any specific test case id or tds id in the format
#           <Category>.<Component>.[<SubComponent>].<TDSName>
#           Any of the fields can have a special character "*" to
#           consider all available values.
#            (Optional, default is all test case ids)
#
# Results:
#      Prints test case ids on to stdout
#
# Side effects:
#      None
#
########################################################################

sub PrintListOfTDSIDS
{
   my $self     = shift;
   my $tds      = shift;
   my $userTags = shift;

   my $testcaseArray = $self->GetTestCaseHash($tds, $userTags);
   if (not defined $testcaseArray) {
      print "No test case IDs available";
      return;
   }

   my $temp;
   foreach my $test (@{$testcaseArray}) {
      $test = $test->{testID};
      $test =~ s/^TDS:://; # remove TDS::
      $test =~ s/::/\./g;  # replace :: with .
      push(@$temp, $test);
   }
   $vdLogger->Info("Total tests: " . scalar(@$temp));
   $vdLogger->Info("Test list:" . Dumper($temp));
}


########################################################################
#
# GetTestList--
#     Method to get test list in vdnet after processing
#     list of tests to skip. This is the main method to get the test
#     list which calls GetTestCaseHash() to finds tests to run,
#     tests to skip based on usertags as well.
#
# Input:
#     None. (this method returns test list based on cli param -t.
#     This parameter is stored as attribute of this class
#
# Results:
#     Reference to an array where each element is a test case hash;
#     FAILURE, in case of any error
#
# Side effects:
#
########################################################################

sub GetTestList
{
   my $self = shift;

   #
   # Now process the list of test case IDs given at the command line.
   # Users can specify multiple test case IDs using multiple -t options.
   # Within a test case ID, it can either refer to a specific test case or
   # a group of test cases denoted by wildcard *. * indicates one or more
   # of the given pattern.
   # The list of tests can also be narrowed down to a bunch of selected
   # tests by using the --tags command line option. If --tags is specified,
   # only the tests (given in -t option) that has the given tags will be
   # considered.
   #
   #
   my @tdsIDs   = @{$self->{'cliParams'}{'tdsIDs'}};
   my $userTags = $self->{'cliParams'}{'userTags'};
   my $testFramework = $self->{userInputHash}{testframework}{name};
   my @cmdLineOptionForTests = @tdsIDs;
   @tdsIDs = (); # initialize the array to store all test cases in this vdnet
                 # session

   if (defined($testFramework) && ($testFramework ne "vdnet")) {
      my $framework = uc($testFramework);
      my $method = "Get" . $framework . "Test";
      foreach my $tds (@cmdLineOptionForTests) {
         my $test = $self->$method($tds);
         push(@tdsIDs, $test);
      }
      return \@tdsIDs;
   }

   #
   # As mentioned above, there are 2 groups/levels of tests.
   # One under -t option and another group composed of all different
   # -t options. For example:
   # if the command line option has:
   # -t "EsxServer.MgmtSwitch.*.*" -t "Sample.Sample.UDPTraffic"
   # Then, the final test list will include group of tests
   # (all tests under MgmtSwitch category) under first -t option and also the
   # second -t option.
   #
   foreach my $testOption (@cmdLineOptionForTests) {
      my $testcaseArray;
      $testcaseArray = $self->GetTestCaseHash($testOption, $userTags);
      if (($testcaseArray eq FAILURE) || !scalar(@{$testcaseArray})) {
         $vdLogger->Error("No test case hash available for command line " .
                          "option $testOption: " . Dumper($testcaseArray));
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      push(@tdsIDs,@{$testcaseArray});
   }

   # Upgrading TDS ver1 to ver2
   if ((defined $self->{'autoupgrade'}) && ($self->{'autoupgrade'} == 1)) {
      if (@cmdLineOptionForTests > 1) {
         $vdLogger->Error("If autoupgrade is set, multiple input to -t option" .
                          " is not supported");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      require VDNetLib::TestSession::UpgradeVer1;
      my $upgradeObj =
         VDNetLib::TestSession::UpgradeVer1->new($self->{testcaseHash},
                                                 $self->{'logDir'},
                                                 $self->{'cliParams'}{'tdsIDs'});
      my $result = $upgradeObj->UpgradeTDS(\@tdsIDs);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to upgrade TDS");
      }
   }

   #
   # If --skiptests command line option is given, then first,
   # get the list of testcases to skip. Then remove these test cases
   # from the actual test list computed above
   #
   my $skipTests = $self->{'cliParams'}{'skipTests'};
   if (defined $skipTests) {
      my @skipTDSIDs;
      # split comma separated entries
      my @skipTestsArray = split(/,/,$skipTests);

      # Get the list of test
      foreach my $testOption (@skipTestsArray) {
         my $tempSkipList;
         # Get the complete set of tests to skip (only those that have
         # $userTags, because, other tests without $userTags are not
         # anyways going to be part of final test list)
         #
         $tempSkipList = $self->GetTestCaseHash($testOption, $userTags);
         push(@skipTDSIDs,@{$tempSkipList});
      }

      $vdLogger->Debug("Complete skip test list:");
      foreach my $testcase (@skipTDSIDs) {
         $vdLogger->Debug("$testcase->{testID}");
      }

      # convert list of tests to skip into a hash for faster lookup
      my %tempSkipList = map {$_->{testID} => 1} @skipTDSIDs;

      my @newList;
      foreach my $testcaseHash (@tdsIDs) {
         if (not exists $tempSkipList{$testcaseHash->{'testID'}}) {
            push(@newList, $testcaseHash);
         }
      }
      @tdsIDs = @newList;
   }
   #
   # Do sorting of test cases based on the value set for
   # attribute 'sortTests'
   #
   # TODO: add 'sortTests': 'randomize' to randomize test case
   # based on seed value
   #
   if ($self->{sortTests} eq 'testbed') {
      my $temp = VDNetLib::Common::Utilities::SortTestcasesByTestbed(\@tdsIDs);
      if ($temp eq FAILURE) {
         $vdLogger->Error("Failed to sort testcases by testbed spec");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         @tdsIDs = @$temp;
      }
   }
   $vdLogger->Debug("Final test list");
   foreach my $testcase (@tdsIDs) {
      $vdLogger->Debug($testcase->{testID});
   }
   return \@tdsIDs;
}


########################################################################
#
# GetTestCaseHash--
#      Method to get an array of test case hashes for the given tds id
#
# Input:
#      testcaseID: any specific test case id in the format
#                  <Category>.<Component>.[<SubComponent>].
#                  <TDSName>.<TestName>
#                  Any of the fields can have a special character
#                  "*" to consider all available values.
#                  (Optional, default is all test case ids)
#
# Results:
#      Reference to an array in which each element has reference to
#      a test case hash;
#      FAILURE, in case of any error or no test case information
#      available;
#
# Side effects:
#      None
#
########################################################################

sub GetTestCaseHash
{
   my $self       = shift;
   my $testcaseID = shift;
   my $userTags   = shift;
   my $obj;
   my $TestSetTds;
   my @testcaseArray;
   my $subdir = undef;

   if ($testcaseID eq "all") {
      $testcaseID = "*";
   }
   # Split the given TDS id
   my @temp = split(/\./,$testcaseID);

   #
   # The last 2 fields of a test case id are TDS name and Test name.
   # From the given the test case id, separate the tds and test name
   # from rest of the fields i.e category/components.
   #
   my $limit = scalar(@temp) - 3;
   my @subdirArray = @temp[0 .. $limit];

   #
   # tdsPath has to be provided to GetTDSList() method in
   # GlobalConfig.pm. Therefore, construct the path to tds files
   # using the category and component fields.
   #
   $subdir = join("/",@subdirArray);

   my $testcaseName = $temp[-1];
   $testcaseName =~ s/\*/\.\*/g;

   my $tdsName = $temp[-2];
   $tdsName = (defined $tdsName) ? $tdsName : undef;

   #
   # Get the current working directory based on this script
   # vdNet.pl
   #
   my $mycwd = VDNetLib::Common::Utilities::GetVDNETSourceTree();
   $subdir = (defined $subdir) ? $subdir : "";
   #
   # Append the subdir constructed using category and component fields
   # to the current working directory of vdNet.pl
   #
   my $tdsPath = "$mycwd/TDS/$subdir";

   #
   # Get the tds name(s) based on the input given. If a complete test case id
   # is given without *, then there will be just one value (TDS) returned from
   # GetTDSList(). Otherwise, all available TDSes based on the given input
   # will be returned.
   #
   my $gc = VDNetLib::Common::GlobalConfig->new();
   my $result = $gc->GetTDSList($tdsPath, $tdsName);
   if (not defined $result) {
      $vdLogger->Error("No test case or tds available for the given " .
                       "format $tdsName");
      return FAILURE;
   }

   #
   # Given the complete test case ID for one or more test cases (depending on
   # whether * is given for category/component/tds/test name, load the TDS
   # package and retrieve the test case hash for each test case.
   #
   if (defined $userTags) {
      my $msg = "User tags defined: $userTags";
      if (defined $vdLogger) {
         $vdLogger->Info("$msg");
      } else {
         print "$msg\n";
      }
   }
   foreach my $set (@{$result}) {
      my @tdsIDs = ();
      my $yamlPath = 'TDS.' . $set;
      $vdLogger->Debug("Resolving Tds set '" . $set . "' to yaml '" .
                       $yamlPath . "'");
      $yamlPath =~ s/\./\//g;
      if ($Config{osname} =~ /win/i) {
         $yamlPath =~ s/\./\\/g;
      }
      $vdLogger->Debug("Using yaml path: $yamlPath");
      my $hasYaml = 0;
      my $yamlHash;
      my $yamlFile = "$FindBin::Bin/../" . $yamlPath . 'Tds.yaml';
      $vdLogger->Debug("Resolved yaml file: $yamlFile");
      if (-e $yamlFile) {
         $vdLogger->Info("Yaml found for TDS, resolving aliases if present");
         eval {
            VDNetLib::InlinePython::VDNetInterface::LoadInlinePythonModule("vdnet_spec");
            $yamlHash = py_call_function(
                "vdnet_spec", "configure_logging", $self->{logDir});
            $yamlHash = py_call_function(
                "vdnet_spec", "resolve_tds", $yamlFile, $self->{logDir},
                undef, undef);
         };
         if ($@ or ! $yamlHash) {
            $vdLogger->Error("Failed to resolve TDS $yamlFile:$@".
                             Dumper($yamlHash));
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         eval {
             eval "require TDS::Main::VDNetMainTds.pm";
             $obj = "TDS::Main::VDNetMainTds"->new($yamlHash);
         };
         if ($@) {
            $vdLogger->Error("Tds resolution failure:\n$@");
         }
         $set =~ s/\./::/g;
         $set = "TDS::" . $set . "Tds";
         $set =~ /.*::(.*)/;
         my $tdsPackage = lcfirst($1);
         $self->{$tdsPackage} = $obj;
         $hasYaml = 1;
      } else {

      $set =~ s/\./::/g;
      $set = "TDS::" . $set . "Tds";
      eval  "require $set";
      if ( !$@ ) {
         eval {
            $obj = $set->new();
         };
         if ($@) {
            $vdLogger->Error("Failed to create an instance of $set, please" .
            "check if the folder path or package name or the constructor " .
            "of the TDS is correct: $@");
            next;
         }

         $set =~ /.*::(.*)/;
         my $tdsPackage = lcfirst($1);
         $self->{$tdsPackage} = $obj;

      } else {
         print "Failed to load ${set} " . $@;
         next;
      }
      }
      my $tdsIDs = $obj->GetTDSIDs();
      my $tags = undef; # TODO - look for test cases with given tags
      my $validTest;

      foreach my $testCaseID (@$tdsIDs) {
         my $addTestcase = 0;
         my $testcaseHash;
         if ($hasYaml) {
            $testcaseHash = $yamlHash->{$testCaseID};
         } else {
            $testcaseHash = $obj->GetTestCaseInfo($set,$testCaseID);
         }
         if ($testCaseID !~ /^$testcaseName$/i) {
            next;
         }
         if (not defined $testcaseHash->{WORKLOADS}) {
             if (defined $testcaseHash->{TestName}) {
                $vdLogger->Warn("Workloads not defined, skipping matching test " .
                                $testCaseID);
            }
            next;
         }
         if (not defined $testcaseHash->{TestbedSpec} and
             not defined $testcaseHash->{testbedSpecFile}) {
             $vdLogger->Warn("TestbedSpec or testbedSpecFile is not defined, " .
                             "might be required");
         }
         #
         # if user tags are defined, then check if the test case has any tags
         # defined. If yes, then check if at least one of the test case tags
         # matches one of the user tag. If test case tag is not defined or no
         # matching tags found, ignore the test case.
         #

         #
         # By default, entire tests in vdnet are considered as part of tag
         # "all"
         #
         my $testCaseTags = $testcaseHash->{'Tags'};
         if (not defined $testCaseTags) {
            $testCaseTags = "all";
         } else {
            $testCaseTags = $testCaseTags . ",all";
         }
         if (not defined $userTags) {
            $userTags = "all";
         }

         if (defined $userTags) {
            my @testCaseTagsArray = split(/,/,$testCaseTags);
            my @userTagsArray = split(/,/,$userTags);
            foreach my $tag (@userTagsArray) {
               my $negativeTag = 0;
               # If the userTag has ~, then assume it is a negative tag
               # negativeTag is to NOT consider tests with such tags
               if ($tag =~ /\~/) {
                  $negativeTag = 1;
                  $tag =~ s/\~//;
               }
               #
               # check whether tags match between userTags and test case
               # defined tags
               #
               my $tagsMatch = grep { lc($_) eq lc($tag)} @testCaseTagsArray;
               if (!$negativeTag) {
                  if ($tagsMatch) {
                     $addTestcase = 1;
                     last;
                  }
               } else {
                  if ($tagsMatch) {
                     $addTestcase = 0;
                     last;
                  } else {
                     $addTestcase = 1;
                  }
               }
            }
         } else {
            $addTestcase = 1;
         }
         #
         # At this point the testcase meets all the conditions, so pushing the
         # reference to test case hash into the final array
         #
         if ($addTestcase) {
            $set =~ s/Tds$//;
            $testcaseHash->{testID} =  "$set" . "::$testCaseID";
            push(@testcaseArray, $testcaseHash);
         }
      }
   }
   return \@testcaseArray;
}


########################################################################
#
# StartSTAF --
#      Checks if staf service is already running. If not, it starts a
#      new instance
#
# Input:
#      hostIP: IP address of the system under test (Required)
#
# Results:
#      None
#
# Side effects:
#      None
#
########################################################################

sub StartSTAF
{
   my $self = shift;
   my $hostIP = shift;
   my $stafBldToUse;
   my $installedSTAFBld;
   my @STAFResponse;
   my $stafCfgDir;

   if (not defined $hostIP) {
      $vdLogger->Error("Host IP not given at StartSTAF()");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $stafBldToUse = $ENV{STAFSDKBLD};

   if ($stafBldToUse eq "latest") {
      # Get the VMODL checksum of the host under test
      my $hostChecksum =
         VDNetLib::Common::FindBuildInfo::GetHostVMODLChecksum($hostIP);
      $vdLogger->Debug("Test host $hostIP VMODL checksum: $hostChecksum");
      if ($hostChecksum eq FAILURE) {
         $vdLogger->Debug("Failed to find the vmodl of $hostIP ," .
                          "Check if the host is UP");
      } else {

         # find the STAF SDK build matching the host's vmodl checksum
         $stafBldToUse =
            VDNetLib::Common::FindBuildInfo::GetMatchingSTAFBuild($hostChecksum);
      }

      #
      # TODO: remove this when STAF SDK publishes vmodl checksum in all
      # branches. Currently, vmodl is published only on "vmkernel-main"
      #
      if ((not defined $stafBldToUse) || ($stafBldToUse eq FAILURE) || ($stafBldToUse eq "latest"))  {
         $vdLogger->Debug("Couldn't find staf sdk using vmodl checksum");
         my $branch =
            VDNetLib::Common::FindBuildInfo::GetBranchNameFromIP($hostIP);
         $branch = ($branch ne FAILURE) ? $branch :
                  VDNetLib::Common::GlobalConfig::DEFAULTSTAFSDKBRANCH;
         $stafBldToUse =
            VDNetLib::Common::FindBuildInfo::GetLatestSTAFSDK($branch);
      }
   }

   if ((not defined $stafBldToUse) || (FAILURE eq $stafBldToUse)) {
      $vdLogger->Error("No STAF SDK build defined/found");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Info("Using staf sdk build $stafBldToUse");

   my $stafSdkDir = "/tmp/vdnet";
   if (!(-e "$stafSdkDir/staf-$stafBldToUse.tgz")) {
      $vdLogger->Info("Creating directory for STAF SDK at $stafSdkDir");
      `mkdir -p $stafSdkDir` if (!(-e "$stafSdkDir"));

      # copy the original staf config file
      my $stafbase = `dirname \`which STAFProc\``;
      chomp($stafbase);
      $stafbase = $stafbase . "/..";

      # download the staf sdk jars
      my $buildInfo =
         VDNetLib::Common::FindBuildInfo::getOfficialBuildInfo($stafBldToUse);
      my $url = 'http://build-squid.eng.vmware.com' . $buildInfo->{'buildtree'} .
                "/publish/VMware-staf-service-e.x.p-$stafBldToUse.tar.gz";
      $vdLogger->Info("Downloading VMware STAF SDK Services from $url " .
                      "to $stafSdkDir/staf-$stafBldToUse.tgz...");

      LWP::Simple::getstore($url, "$stafSdkDir/staf-$stafBldToUse.tgz");
    } else {
       $vdLogger->Info("Found and use cached STAF SDK bundle in $stafSdkDir");
    }

   my $stafCfgCmd = 'mktemp -p ' .
                    VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FOLDER .
                    ' -d -t vdnet.staf.XXXXXX';
   $stafCfgDir = `$stafCfgCmd`;
   chomp($stafCfgDir);
   my $stafCfg = "$stafCfgDir/STAF.cfg";

   my $startingPort = VDNetLib::Common::GlobalConfig::STAFPROC_INITIAL_PORT;
   my $endingPort = $startingPort +
      VDNetLib::Common::GlobalConfig::MAX_VDNET_SESSIONS;
   my $port = VDNetLib::Common::Utilities::GetFreePort($startingPort,
                                                       $endingPort);
   if ($port eq FAILURE) {
      $vdLogger->Error("No port available to start staf");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if (defined $self->{'vdnetConf'}) {
      `echo "STAFPORT=$port" >> $self->{'vdnetConf'}`;
   }
   $sessionSTAFPort  = $port; # update the global variable
   my $stafInstanceName = "vdnet-$$-$sessionSTAFPort";
   $vdLogger->Info("STAF instance name $stafInstanceName");
   `tar -C $stafCfgDir -zxvf  $stafSdkDir/staf-$stafBldToUse.tgz`;

   #
   # set the STAF_INSTANCE_NAME env variable which is required
   # for all staf calls in order to use this process than
   # anything else
   #
   $ENV{'STAF_INSTANCE_NAME'} = $stafInstanceName;
   if (defined $self->{'vdnetConf'}) {
      `echo "STAF_INSTANCE_NAME=$stafInstanceName" >> $self->{'vdnetConf'}`;
   }
   # create STAF.cfg on the fly
   my $jvmOptions = "OPTION J2=-Xmx2048m -Xms100m -XX:MaxPermSize=256m " .
                    "-XX:PermSize=128m -XX:+UseConcMarkSweepGC";
   my $sslOption =  "OPTION J2=-DUSESSL=true";
   `echo "TRUST DEFAULT LEVEL 5" > $stafCfg`;
   `echo "interface tcp library STAFTCP OPTION PORT=$sessionSTAFPort" >> $stafCfg`;
   `echo "SET DATADIR $stafCfgDir" >> $stafCfg`;
   `echo "SERVICE host LIBRARY JSTAF EXECUTE $stafCfgDir/host.jar OPTION JVMName=host-$stafInstanceName $jvmOptions $sslOption" >> $stafCfg`;
   `echo "SERVICE vm LIBRARY JSTAF EXECUTE $stafCfgDir/vm.jar OPTION JVMName=vm-$stafInstanceName $jvmOptions $sslOption" >> $stafCfg`;
   `echo "SERVICE setup LIBRARY JSTAF EXECUTE $stafCfgDir/setup.jar OPTION JVMName=vc-$stafInstanceName $jvmOptions $sslOption" >> $stafCfg`;
   `echo "SERVICE util LIBRARY JSTAF EXECUTE $stafCfgDir/util.jar" >> $stafCfg`;
   # increase MAXQUEUESIZE to fix PR 821682
   `echo "SET MAXQUEUESIZE 10000" >> $stafCfg`;
   # actually start staf daemon
   `echo "STAF_INSTANCE_NAME=$stafInstanceName CLASSPATH=$stafCfgDir/lib/lib.jar:\$CLASSPATH STAFProc $stafCfg > $stafCfgDir/staf.log" > $stafCfgDir/start.sh`;
   `chmod +x  $stafCfgDir/start.sh`;

   if (FAILURE eq $self->StartSTAFProc($stafCfgDir)) {
      $vdLogger->Error("Stafproc: Failed to start STAF");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# StartSTAFProc--
#     Method to run the STAF script
#
# Input:
#     stafCfgDir   : Path to STAF cfg dir
#
# Results:
#     If SUCCESS starts STAF and updates vdnetConf;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub StartSTAFProc
{
   my $self = shift;
   my $stafCfgDir = shift;

   my $cmd = "$stafCfgDir/start.sh &";
   system($cmd);
   # it takes a while for staf to spin up all the JVMs, so we wait...
   $vdLogger->Info("Waiting for STAF daemon to start...");
   my $timeout = 120;
   do {
      sleep(1);
      $timeout--;
      `grep -E "STAFException" $stafCfgDir/staf.log`;
      $timeout = 0 if $? == 0;
      `grep initialized $stafCfgDir/staf.log`;
   } while($timeout > 0 && $? != 0);
   if ($timeout <= 0) {
       $vdLogger->Error("STAF failed to start: " . `cat $stafCfgDir/staf.log`);
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   #
   # Now, get the process id of start.sh which will be used to kill
   # start.sh and all child processes (STAFProc, JVMs)
   #
   my $stafProcess = `ps ax | grep -v grep | grep $stafCfgDir/start.sh`;
   $stafProcess =~ s/^\s+//;
   my @pid = split(/ /, $stafProcess);
   if ($pid[0] !~ /\d+/) {
      $vdLogger->Error("Couldn't get PID of STAFProc");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $self->SetSTAFGroupPID($pid[0]);
   $vdLogger->Info("STAFProc running with PID $pid[0]");

   $self->SetSTAFConfigDir($stafCfgDir);
   # write stafCfgDir to vdnet.conf
   if (defined $self->{'vdnetConf'}) {
      `echo "STAF_CONFIG_DIR=$stafCfgDir" >> $self->{'vdnetConf'}`;
      `echo "STAF_GROUP_PID=$pid[0]" >> $self->{'vdnetConf'}`;
   }
   return SUCCESS;
}


########################################################################
#
# CreateSTAFHelper--
#     Method to create an instance of VDNetLib::Common::STAFHelper
#
# Input:
#     None
#
# Results:
#     Sets 'stafHelper' attribute of session class;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CreateSTAFHelper
{
   my $self = shift;
   # Creating new STAFHelper object.
   my $args;
   $args->{logObj} =  $vdLogger;
   $args->{tcpport} = $self->{tcpport};
   my $temp = VDNetLib::Common::STAFHelper->new($args);
   if (not defined $temp) {
      $vdLogger->Error("Failed to create VDNetLib::STAFHelper object");
      VDSetLastError("ETAF");
      return FAILURE;
   }
   $self->{stafHelper} = $temp;
}


########################################################################
#
# StartInlineJVM--
#     Method to start Inline JVM server/process
#
# Input:
#     classpath: list of absolute paths delimited by :
#                which contains all JARs such vc.jar, vcqa.jar etc
#                (Optional, default would use existing CLASSPATH)
#     logDir   : absolute path to log directory for inline process
#
# Results:
#     SUCCESS, if inline JVM is started successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub StartInlineJVM
{
   my $self         = shift;
   my $classPathDir = shift || $self->GetVCQELibPath();
   my $logDir       = shift || $self->{'logDir'};

   $vdLogger->Debug("STAF Classpath directory is $classPathDir");

   #
   # Load Inline Java module using the same VCQA and other JARs
   # downloaded with STAF SDK bundle
   #
   my $port = FAILURE;
   if (defined $self->{inlineJavaPort}) {
      $port = $self->{inlineJavaPort};
   } else {
      $port  = VDNetLib::Common::GlobalConfig::INLINE_JVM_INITIAL_PORT
               + int(rand(10));
      my $retry = 10;

      while ($retry > 0) {
         if (!VDNetLib::Common::Utilities::IsPortOccupied($port)) {
            last;
         }
         $vdLogger->Debug("TCP port $port occupied");
         $retry--;
         $port++;
      }

      if ($retry == 0) {
         $vdLogger->Error("No free port available  in the range from " .
                          ($port - 10) .
                          " to " . $port. " to start inline java");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   if (defined $self->{'vdnetConf'}) {
      `echo "INLINEJAVAPORT=$port" >> $self->{'vdnetConf'}`;
   }
   #In situation that $classPathDir is not valid, we should set it to undef.
   if ($classPathDir eq FAILURE) {
      $classPathDir = undef;
   }
   if (!VDNetLib::InlineJava::VDNetInterface::LoadInlineJava(
                                                DEBUG => 0,
                                                DIRECTORY => $logDir,
                                                PORT => $port,
                                                CLASSDIR  => $classPathDir,
                                                )) {
      $vdLogger->Error("Failed to load VDNetInlineJava module");
      #return FAILURE; should return failure but will do after we have test
      #                cases written using VDNetInlineJava
   }
   $vdLogger->Debug("Started Inline Java server on port $port");
   #
   # Configure the VCQA logger to redirect logs to a file under
   # the directory where vdnet logs are created
   #
   if (!VDNetLib::InlineJava::VDNetInterface::ConfigureLogger($logDir)) {
      $vdLogger->Error("Failed to configure VCQA logger");
      #return FAILURE; should return failure but will do after we have test
      #                cases written using VDNetInlineJava
   }

   $self->{tcpport} = $sessionSTAFPort;
   if (FAILURE eq $self->SavePIDToFile("inlinejava", $port)) {
      $vdLogger->Error("Failed to open file of watchdog PIDs");
   }

   return SUCCESS;
}


########################################################################
#
# SetSTAFConfigDir--
#     Method to set the value of attribute 'stafCfgDir'
#
# Input:
#     stafCfgDir: Directory where STAF config and log files reside
#                 for this session
#
# Results:
#     None (except stafCfgDir value is set)
#
# Side effects:
#     None
#
########################################################################

sub SetSTAFConfigDir
{
   my $self = shift;
   my $stafCfgDir = shift;

   $self->{'stafCfgDir'} = $stafCfgDir;
}


########################################################################
#
# SetSTAFGroupPID--
#     Method to set the value of attribute 'stafGroupPID' which
#     contains the value of group process id of STAFProc
#
# Input:
#     stafGroupPID: Group PID of STAFProc in integer
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub SetSTAFGroupPID
{
   my $self = shift;
   my $stafGroupPID = shift;

   $self->{'stafGroupPID'} = $stafGroupPID;
}


########################################################################
#
# SessionInventoryCleanup --
#     Method to do session testbed cleanup
#
# Input:
#     result: final session result
#
# Results:
#     SUCCESS, if the testbed inventory cleanup is successful;
#     FAILURE, otherwise
#
# Side effects:
#     The testbed inventory will no longer be accessible
#
########################################################################

sub SessionInventoryCleanup
{
   my $self = shift;
   my $result = shift;

   # Collect the support bundle for the failed case
   my $jsonFile = $self->{logDir} . "/" . "testbed.json";
   if (! -e $jsonFile){
      $jsonFile = $self->{logDir} . "/" . "config.json";
   }

   if (! -e $jsonFile){
      $vdLogger->Error("No config file available to cleanup");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # use python as prefix to run python scripts, otherwise the default
   # interpreter path set the script will take over.
   # For example,
   # #!/build/toolchain/lin32/python-2.7.9-openssl1.0.1k/bin/python
   # But in case of private setup for scale, we want to use toolchain that is
   # not from NFS.
   # Also, the environment for running these scripts are controller by
   # main/environment. that should control the binaries used.
   #
   my $baseDeployCmd = "python $FindBin::Bin/../scripts/deployTestbed.py " .
             "--logdir $self->{logDir} " .
             "--config $jsonFile --no-stdout";

   $baseDeployCmd = $baseDeployCmd . " --podspec " .
                    $self->{podSpec} if (defined $self->{podSpec});

   # append contexts value
   $baseDeployCmd = $baseDeployCmd . " --contexts " .
                    $self->{contexts} if (defined $self->{contexts});
   my $cmd;
   $vdLogger->Debug("Begin to clean up session with collectLogs as " .
      $self->{'collectLogs'} . " and keeptestbed as " . $self->{keepTestbed});

   if (($result) && ($self->{'collectLogs'})) {
      $cmd = $baseDeployCmd . " --collectlogs";
      # execute deployTestbed to collect the logs
      system($cmd);
      $vdLogger->Debug("Run command $cmd in Session cleanup.");
   }
   if (defined $self->{testRunId}) {
      $baseDeployCmd = $baseDeployCmd . " --testrunid " . $self->{testRunId};
   }
   if (!$self->{keepTestbed}) {
      $cmd = $baseDeployCmd . " --cleanup";
      # execute deployTestbed to cleanup virtual testbed
      system($cmd);
      $vdLogger->Debug("Run command $cmd in Session cleanup.");
   }

}


########################################################################
#
# Cleanup--
#     Cleanup method for the entire vdnet session
#
# Input:
#     result: final result of the vdnet session
#
# Results:
#     None
#
# Side effects:
#     All processes initialized as part of session will be closed
#
########################################################################

sub Cleanup
{
   my $self = shift;
   my $result = shift;

   if ((($self->{'testLevel'} ne 'complete') &&
      ($self->{'testLevel'} ne 'cleanupOnly') &&
      (!$self->{exitOnInteractive}))) {
      $vdLogger->Debug("No session cleanup since test level is " .
                       "$self->{'testLevel'} or exitoninteractive " .
                       "option is set to False");
      return SUCCESS;
   } else {
      if (FAILURE eq $self->SessionInventoryCleanup($result)) {
         $vdLogger->Error("Failed to cleanup session testbed inventory");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #
   # It is very important to kill all the processes staf/jvm
   # started by start.sh script created in StartSTAF() routine.
   # Otherwise, all the processes will be hanging around consuming
   # resources unnecessarily
   #
   #

   if (FAILURE eq $self->StopZookeeper()) {
      $vdLogger->Error("Failed to stop zookeeper session");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # stop the Inline JVM.
   VDNetLib::InlineJava::VDNetInterface->StopInlineJVM();
   my $stafGroupPID = $self->{'stafGroupPID'};

   if (defined $ENV{STAFSDKBLD}) {
      $vdLogger->Debug("Removing stale STAF SDK bundles from disk caches.");
      #
      # Never ever leave a possibility that files could be deleted from /
      # HZ: 1403018
      my $findRmCmd = 'find ' .
                      VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FOLDER .
                      ' -maxdepth 1 -mtime +3 -iname \'*staf*\' -exec ' .
                      'rm -rf {} \\; > /dev/null 2>&1';
      `$findRmCmd`;
      `STAF local shutdown shutdown`;

      my $retry = 10;
      # Running pkill once is not killing all the associated processes
      # especially if you run vdnet as non-root user. So loop through
      # and make sure we kill all the associated processes.
      while ((defined $stafGroupPID) &&
             (`ps -aef | grep -v grep | grep $stafGroupPID` =~
                      /\s$stafGroupPID\s/) && ($retry > 0)) {
         sleep(2);
         $vdLogger->Debug("Preparing to kill STAF PID $stafGroupPID");
         kill('TERM', $stafGroupPID);
         $retry--;
      }

      if ((defined $stafGroupPID) &&
          (`ps -aef | grep -v grep | grep $stafGroupPID` =~
                      /\s$stafGroupPID\s/) && ($retry == 0)) {
         $vdLogger->Debug("Could not kill STAF PID $stafGroupPID");
         my $ps = `ps -aef`;
         $vdLogger->Debug($ps);
      } elsif (defined $stafGroupPID) {
         $vdLogger->Debug("Killed STAF PID $stafGroupPID");
      }
   }

   foreach my $stafObj (@stafTrash) {
      if (defined $stafObj->{handle}) {
         $stafObj->Destroy();
      }
   }

   #Uploading the entire log directory to racetrack.
   my $source      = $self->{'logDir'} . "/*";
   my $destination = $self->{'logDir'} . "/completeLog.tgz";
   $vdLogger->Debug("About to tar all the files in $source\n");
   eval{
      system("tar --exclude=*_TDS* -zcvPf $destination $source");
      $result = (!$result) ? "PASS" : "FAIL";
      $vdLogger->Debug("Done cleaning up staf process");
      $self->{'logger'}->End($result, $destination);
   };
   if ($@) {
       $vdLogger->Warn("Exception caught in uploading the entire log directory: $@");
   }

   close($self->{testInfoCSVFH});
   return SUCCESS;
}


########################################################################
#
# ConfigureLogging--
#     Method to configure logger for the VDNet session;
#     Details like log directory, log file, racetrack session are
#     initialized/set in this method
#
# Input:
#     named hash parameter with following keys:
#     logDirName    : log folder name (default, unique name will be
#                                      generated)
#     logLevel       : log level string, Default is "INFO"
#     logFileLevel   : log file level, Default is "DEBUG"
#     logToConsole   : boolean flag to indicate logging to console
#     racetrack      : racetrack detail in the format
#                      <user>@<racetrackServer>. This is to indicate
#                      if logs should be uploaded to racetrack server
#
# Results:
#     Global variable $vdLogger will be set;
#     Attribute 'testInfoCSVFH' will be set which stores the file
#     handle to session summary in csv format;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureLogging
{
   my $self = shift;
   my %args = @_;
   my $logDirName  = $args{logDirName};
   my $logLevel     = $args{logLevel};
   my $logFileLevel = $args{logFileLevel};
   my $logToConsole = $args{logToConsole};
   my $file;         #provide log filename
   my $path = VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FOLDER;
   my $completeLogPath;
   #
   # $vdLogger is a global variable shared by VDNetLib::Common::Globalconfig.
   # It refers to a VDNetLib::Common::VDLog object.
   # It is used in all the packages related to vdNet automation.
   # This variable is undefined by default. A value is assigned to it
   # by calling VDNetLib::Common::GlobalConfig::CreateVDLogObj().
   # This function also sets environment variables
   # VDNET_LOGLEVEL, VDNET_LOGTOFILE, VDNET_LOGFILENAME,
   # VDNET_VERBOSE corresponding to the VDLog object created.
   # To pass the value of $vdLogger to remote machines, the agent packages
   # like LocalAgent.pm and RemoteAgent.pm start a staf process remoteAgent.pl
   # along with the environment variables on the remote machines.
   # The script remoteAgent.pl reads the above mentioned environment variables
   # and create a new instance of VDNetLib::Common::VDLog object.
   #
   #

   if (defined $logLevel) {
      my $levelIndex = VDNetLib::Common::VDLog::CheckLogLevel($logLevel);
      if ($levelIndex eq FAILURE) {
         print STDERR "\nUnexpected log level: $logLevel. Only following " .
                      "levels are supported: " .
                      Dumper(\@VDNetLib::Common::VDLog::levelStr);
         return FAILURE;
      }
      $logLevel = $levelIndex;
   } else {
      $logLevel = VDNetLib::Common::GlobalConfig::DEFAULT_LOG_LEVEL;
   }
   if (defined $logFileLevel) {
      my $levelIndex = VDNetLib::Common::VDLog::CheckLogLevel($logFileLevel);
      if ($levelIndex eq FAILURE) {
         print STDERR "\nUnexpected log file level: $logFileLevel. Only following " .
                      "levels are supported: " .
                      Dumper(\@VDNetLib::Common::VDLog::levelStr);
         return FAILURE;
      }
      $logFileLevel = $levelIndex;
   } else {
      $logFileLevel = VDNetLib::Common::GlobalConfig::LOG_LEVEL_DEBUG;
   }

   my $timestamp = VDNetLib::Common::Utilities::GetTimeStamp();

   if (defined $logDirName) {
      $path = $logDirName . "/";
      unless (-d $path) {system("mkdir -p $path")};
   } else {
      $path = $path . "/". $timestamp . "/";
      unless (-d $path) {system("mkdir -p $path")};
   }
   $file = VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FILE;
   $completeLogPath = $path . $file;

   #
   # Create a main logger object. This will be used for
   # log everything which is not test specific.
   # The $vdLogger will be used only for logging test
   # specific logs. The main logger will log everything
   # to <timestamp>-VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FILE
   # while $vdLogger will log
   # everything to <timestamp>-<testName>.log. $mainLogger
   # will also be responsible for uploading log's to racetrack.
   #
   # Pass reference to new entry in symbol table as file handle
   #
   my $sessionLogger = VDNetLib::Common::VDLog->new(
                                            'logFileName' => $completeLogPath,
                                            'logToFile'   => 1,
                                            'logLevel'    => $logLevel,
                                            'logFileLevel'    => $logFileLevel,
                                            'logToConsole'=> $logToConsole,
                                            'glob'        => \*MAINFH,
                                            );
   if (not defined $sessionLogger) {
      print STDERR "\nFailed to create VDNetLib::Common::VDLog Object\n\n";
      return FAILURE;
   }
   $path =~ s/\/$//; # remove trailing /
   $self->{'logDir'} = $path; # update the session log directory
   $self->{'logger'} = $sessionLogger;
   #
   # A logger object (VDNetLib::Common:VDLog) is created
   # for vdnet master session (this class) and also for each test session.
   # Logger object has an attribute 'rtrackObj' which
   # maintains handle to a racetrack session. The racetrack object/handle
   # should be SAME for both vdnet master session and all test sessions
   # so that all the logs appear under on test set in racetrack.
   # Therefore, racetrack object create for vdnet session is re-used
   # in all test sessions.
   #
   # Then, $vdLogger is a global variable which stores reference to a
   # logger object at any point time. In this class, we create an instance
   # of VDLog and update $vdLogger to use it. In every test session,
   # a new VDLog object will be created and updated as $vdLogger.
   #
   $vdLogger = $sessionLogger;

   #
   # Initiating testinfo.csv file for results summary. This is required for
   # CAT.
   #
   our $testInfoCSVFH;
   my $testInfoCSVFile = $path . "/testinfo.csv";
   # create empty file and then open in update mode.
   `touch $testInfoCSVFile`;
   if (not defined open($testInfoCSVFH, "+<$testInfoCSVFile")) {
      $vdLogger->Error("Unable to create $testInfoCSVFile file");
      return FAILURE;
   }
   $self->{'testInfoCSVFH'} = $testInfoCSVFH;
   $vdLogger->Info("Session's log is available at $completeLogPath");
   return SUCCESS;
}


########################################################################
#
# GetVCQELibPath--
#     Method to get the location of VCQE library
#
# Input:
#     None
#
# Results:
#     Returns a scalar string which is absolute path to the location
#     of VCQE library;
#     FAILURE, in case of any error;
#
# Side effects:
#
########################################################################

sub GetVCQELibPath
{
   my $self = shift;
   my $classPathDir;

   #
   # If "stafsdkbuild" option is not set in yaml, then
   # find the location of Java classpath directories needed
   # for VDNetInlineJava
   #
   if (not defined $ENV{STAFSDKBLD}) {
      # first, get the location where staf binary is available
      my $stafbin = "$FindBin::Bin/../bin/staf";

      # Read if symlinks are used for STAF
      $stafbin = `readlink -f $stafbin`;
      if ((not defined $stafbin) || ($stafbin eq '')) {
         $vdLogger->Error("Cannot find STAF binary installed on this machine");
         return FAILURE;
      }

      $stafbin = `dirname $stafbin`;
      $stafbin =~ s/\/\w+$//;
      chomp($stafbin);

      #
      # Search for the vcqa.jar (could be vc.jar too) under
      # the staf installation directory.
      # It is assumed that STAF SDK libraries are copied
      # under the directory where staf is installed
      #
      my $libPath = `find $stafbin -name vcqa.jar`;

      my @temp = split(/\n/, $libPath);
      $classPathDir = $temp[0];
      $classPathDir =~ s/vcqa\.jar$//;

      if (not defined $classPathDir) {
         $vdLogger->Error("Cannot find STAF classpath directory on this machine");
         return FAILURE;
      }
   } else {
      if (!$self->{'stafCfgDir'}) {
         $vdLogger->Error("STAF config directory is not found");
         return FAILURE;
      }
      $classPathDir = $self->{'stafCfgDir'} . '/lib';
   }
   return $classPathDir;
};


sub ConfigurePortMirrorTool
{
   #TODO: move this to Testcase validation/setup part
# foreach my $testcase (@tdsIDs) {
   # my $testName = $testcase->{testID};
   # if (($testName =~ m/PortMirror/i) && (!$session->{"dontUpgSTAFSDK"})) {
      # my $gConfig = new VDNetLib::Common::GlobalConfig();
      # my $vdNetRootPath = $gConfig->GetVdNetRootPath();
      # my $myLibPath = "$vdNetRootPath/bin/PortMirror_jar/vspanCfgTool/lib";
      # my $libClassPath = "$myLibPath/commons-cli-1.2.jar:".
                         # "$myLibPath/vspancfgtool.jar";
      # $vdLogger->Debug("Working on $testName");
      # $vdLogger->Info("Append commons-cli-1.2.jar and vspancfgtool.jar to CLASSPATH".
                                # " for PortMirror Java tools");
      # $ENV{CLASSPATH} = $libClassPath . ":" . $ENV{CLASSPATH};
      # $vdLogger->Info("Classpath:" . $ENV{CLASSPATH});
      # last;
   # }
# }
}


########################################################################
#
# InitialCleanup--
#     Method to do cleanup before starting vdnet session.
#     This is a best effort to solution to avoid failures
#     due to infrastructure problems
#
# Input:
#     None
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub InitialCleanup
{
   my $self = shift;
   #
   # Deleting old files and directory
   #
   $vdLogger->Debug("Deleting old files and directory from Master Controller");

   #
   # Need to pass the command like this '"' . $DEFAULT_LOG_FOLDER . '/*"
   # in quotes otherwise the shell treats it as a special character
   #

   my $commandfordel = 'perl ' . "$FindBin::Bin/../scripts/" . "cleanup.pl " .
                       '"' . VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FOLDER .
                       '/*"';
   my $ret = $self->{stafHelper}->STAFAsyncProcess("local", $commandfordel);
   if ($ret->{rc}) {
      $vdLogger->Warn("Failed to delete the directories");
   }
}


########################################################################
#
# UpdateCATSummary --
#     Method to update test summary for CAT
#
# Input:
#     testSummary- reference to a hash containing following keys:
#                  testname  - name of the test
#                  starttime - test start time
#                  endtime   - test end time
#                  result    - test result
#     testCount  - integer to represent the test instance id
#
# Results:
#     None (updates testinfo.csv file directly)
#
# Side effects:
#     None
#
########################################################################

sub UpdateCATSummary
{
   my $self        = shift;
   my $testSummary = shift;
   my $testCount   = shift;
   my $testStartOffset = $testSummary->{testStartOffset};
   #
   # Now, prepare the summary for testinfo.csv file required by CAT
   # infrastructure PR513799
   #
   my $status = $testSummary->{result};
   my $link;
   my $rtrackObj = $vdLogger->{rtrackObj};
   if (defined $vdLogger->GetRacetrackId()) {
      $link = "http://" . $rtrackObj->{'server'} . "/resultdetails.php?id=" .
              $rtrackObj->GetTestCaseId() . "&resultid=" .
              $rtrackObj->GetTestSetId();
   } else {
      $link = "NA";
   }
   # Give the log information as hyper-link
   $link = '<a href="' . $link . '">Log</a>';
   $status = ($status =~ /pass/i) ? 0 : 1; # CAT considers 0 as pass
   my $duration = $testSummary->{endtime} - $testSummary->{starttime};
   $duration =~ s/ secs//g; # remove the suffix since CAT already
                            # treats duration in secs
   # csv info per test case, separated by new line character between test
   # cases
   my $message = "NA," . $testCount . "_" .
              "$testSummary->{testname}," . "$status," . "$duration,".
              "$link\n";
   my $fh = $self->{testInfoCSVFH};
   # the test status would be 'running', change it with new status.
   seek($fh, $testStartOffset, 0);
   printf $fh ($message);
}


########################################################################
#
# FormatSummary --
#      Routine to format the summary of results.
#
# Input:
#      testType: string mentioning the run is for test/cleanup/save/reuse
#
# Results:
#      Returns formatted string of results summary.
#
# Side effects:
#      None
#
########################################################################

sub FormatSummary
{
   my $self                     = shift;
   my $sessionsSummaryContainer = shift;
   my $testType = shift || 'Name';
   my $summary = "\n";

   my $branch = undef;
   my $buildType = undef;
   my $vcBuild = undef;
   my $build = undef;
   my $logFileName = $self->{'logDir'} . "/" .
      VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FILE;

   if ( defined $branch && defined $build && defined $buildType ){
      $summary = $summary . "-------------------------------------------" .
              "------------------------\n";
      $summary = $summary . "ESX Branch:\t$branch\n";
      $summary = $summary . "ESX Build:\t$build\n";
      $summary = $summary . "ESX BuildType:\t$buildType\n";
   }

   if ( defined $vcBuild ){
      $summary = $summary . "VC Build:\t$vcBuild\n";
   }

   $self->{'memoryCheckObj'}->record("", $$);
   my $memReport = $self->{'memoryCheckObj'}->report();
   my @memRpt = split("\n", $memReport);
   $memReport = $memRpt[0] . "\n" . $memRpt[-1] . "\n";

   my $testSessionCount = 0;
   my $summaryTable = Text::Table->new("Test $testType", "Duration", "Result",
                                       "LogSize");
   my $passCount = 0;
   my $failCount = 0;
   my $bigLogCount = 0;
   foreach my $testSession (@$sessionsSummaryContainer) {
      my $duration = $testSession->{endtime} - $testSession->{starttime};
      $duration = $duration . " secs";
      $testSessionCount++;
      $summaryTable->load([$testSessionCount . "_" . $testSession->{testname},
                           "$duration", $testSession->{result},
                           sprintf("%.2fM",$testSession->{logFileSize}/1024/1024)]);
      $passCount++ if ($testSession->{result} eq "PASS");
      $failCount++ if ($testSession->{result} eq "FAIL");
      $bigLogCount++ if ($testSession->{logFileSize} >=
                         VDNetLib::Common::GlobalConfig::BIG_LOG_SIZE);
   }
   # Draw a line with length equal to length of table object
   my $line = '';
   $line =~ s/^(.*)/'-' x $summaryTable->width() . $1/e;
   $summary = $line;
   $summary = $summary . "\n" . $summaryTable->stringify();
   $summary = $summary . "\n" . "Total Tests\t: " .
              scalar(@{$self->{testcaseList}});
   $summary = $summary . "\n" . "Total Executed\t: " .
              scalar(@$sessionsSummaryContainer);
   $summary = $summary . "\n" . "Total Passed\t: " .
              $passCount;
   $summary = $summary . "\n" . "Total Failed\t: " .
              $failCount;
   $summary = $summary . "\n" . "Total Big Log\t: " .
              $bigLogCount;
   $summary = $summary . "\n" . "Session log file: " .
              $logFileName;
   # Update racetrack info
   my $racetrackLink;
   if (defined $vdLogger->GetRacetrackId()) {
      $racetrackLink = "http://" . $vdLogger->{rtrackInfo}{'server'} .
                       "/result.php?id=" . $vdLogger->GetRacetrackId();
   } else {
      $racetrackLink = "Not Enabled";
   }
   $summary = $summary . "\n" . "Racetrack link\t: " .
              $racetrackLink;
   $summary = $summary . "\n" . "Base log dir for this session: " .
              $self->{'logDir'};
   $summary = $summary . "\n\n" . "Debugging tips\t: " .
              "http://goo.gl/Gllc1k";
   $summary = $summary . "\n\n" .
              "Memory usage of vdNet session $$ (In kB):\n" .
              $memReport . $line;
   $summaryTable->clear();
   if (defined $self->{'mailto'}) {
      VDNetLib::InlinePython::VDNetInterface::LoadInlinePythonModule("notification");
      py_call_function('notification', 'send_email',
                       'vdnet-donotreply',
                       $self->{'mailto'},
                       "VDNet test session " .
                       VDNetLib::Common::Utilities::GetLocalIP() .
                       "-" . $$ .
                       " result",
                       [$summary]
                       );
   }
   return $summary;
}


########################################################################
#
# LoadTestbedSpec --
#     Method to load the pre-defined testbed spec file
#
# Input:
#     testbedSpecPath : Location to testbed spec in the format
#                       <packageName>.<specName>
#
# Results:
#     Testbed spec (hash) if testbed spec is available and loaded
#     correctly;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub LoadTestbedSpec
{
   my $self            = shift;
   my $testbedSpecPath = shift;

   if (not defined $testbedSpecPath) {
      $vdLogger->Error("Path to testbed spec not given");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my @temp = split(/\./, $testbedSpecPath);
   my $specName = pop @temp;

   $testbedSpecPath = 'VDNetLib::TestData::TestbedSpecs::' .
      join('::', @temp);
   $specName = '$'. $testbedSpecPath . '::' . $specName;
   my $testbedSpec = eval ( "require $testbedSpecPath" );
   if ($@) {
      $vdLogger->Error("Failed to load $testbedSpecPath");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $testbedSpec = eval ($specName);

   return $testbedSpec;
}


########################################################################
#
# ConfigureZookeeper --
#     Method to configure zookeeper for the vdnet session
#
# Input:
#     None
#
# Results:
#     SUCCESS, if zookeeper is configured successfully and
#     'zookeeperObj' is updated;
#     FAILURE, in case of any error;
#
# Side effects:
#
########################################################################

sub ConfigureZookeeper
{
   my $self = shift;

   my $configuredSpec = shift;
   my $port = $configuredSpec->{port};
   my $pid = $configuredSpec->{pid};
   my $sessionZkDir= $configuredSpec->{runtimeDir};

   my $masterControlIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $zookeeperObj = VDNetLib::Common::ZooKeeper->new(
                                       'server' => $masterControlIP,
                                       'port'   => $port,
                                       'pid'   => $pid,
                                       'runtimeDir'    => $sessionZkDir,
                                    );
   if ($zookeeperObj eq FAILURE) {
      $vdLogger->Error("Failed to create zookeeper object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{'zookeeperObj'} = $zookeeperObj;
   return SUCCESS;
}


########################################################################
#
# CreateZookeeperSpec --
#     Method to create zookeeper specification
#
# Input:
#     sessionZkDir: runtime directory where spec should be created
#
# Results:
#     Reference to a hash with following keys:
#        port: port number on which zookeeper would be started
#        runtimeDir: runtime directory
#     FAILURE, in case of error
#
# Side effects:
#     None
#
########################################################################

sub CreateZookeperSpec
{
   my $self = shift;
   my $sessionZkDir = shift;

   my $configuredSpec;
   my $srcTree = VDNetLib::Common::Utilities::GetVDNETSourceTree();
   my $zkSrcDir = $srcTree . 'bin/x86_32/linux/zookeeper';
   `cp -r $zkSrcDir $sessionZkDir`;

   #
   # Create customized configuration spec
   #
   `rm -f $sessionZkDir/conf/zoo.cfg`;
   `echo "tickTime=2000" >> $sessionZkDir/conf/zoo.cfg`;
   `echo "initLimit=10" >> $sessionZkDir/conf/zoo.cfg`;
   `echo "syncLimit=5" >> $sessionZkDir/conf/zoo.cfg`;
   `echo "maxClientCnxns=0" >> $sessionZkDir/conf/zoo.cfg`;
   my $tmp = (defined $self->{zkDataDir}) ? $self->{zkDataDir} :
                                            $sessionZkDir;
   `echo "dataDir=$tmp" >> $sessionZkDir/conf/zoo.cfg`;
   $ENV{'ZOO_LOG_DIR'} = $sessionZkDir;
   my $port = FAILURE;
   if (defined $self->{zkPort}) {
      $port = $self->{zkPort};
   } else {
      my $startingPort = VDNetLib::Common::GlobalConfig::ZOOKEEPER_INITIAL_PORT
                         + int(rand(10));
      my $endingPort = $startingPort +
         VDNetLib::Common::GlobalConfig::MAX_VDNET_SESSIONS;
      $port = VDNetLib::Common::Utilities::GetFreePort($startingPort,
                                                       $endingPort);
   }
   if ($port eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   `echo "clientPort=$port" >> $sessionZkDir/conf/zoo.cfg`;
   `touch $sessionZkDir/zookeeper_server.pid`;

   $vdLogger->Debug("zookeeper started on port $port");
   if (defined $self->{'vdnetConf'}) {
      `echo "ZOOKEEPERPORT=$port" >> $self->{'vdnetConf'}`;
      `echo "ZOOKEEPERDATA=$sessionZkDir" >> $self->{'vdnetConf'}`;
   }
   $configuredSpec->{port} = $port;
   $configuredSpec->{runtimeDir} = $sessionZkDir;
   return  $configuredSpec;
}


########################################################################
#
# StartZookeeper --
#     Method to start zookeeper server based on the configuration
#     made in ConfigureZookeeper()
#
# Input:
#     None
#
# Results:
#     zookeeper pid, if the zookeeper server is started successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub StartZookeeper
{
   my $self = shift;
   my $configuredSpec = shift;
   my $sessionZkDir = $configuredSpec->{'runtimeDir'};
   my $cmd = "$sessionZkDir/bin/zkServer.sh start";
   my $logFileName = $self->{'logDir'} . "/" .
      VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FILE;
   my $result = `$cmd 2>&1`;
   $vdLogger->Info("Starting zookeeper: $cmd 2>&1");
   $vdLogger->Debug("Starting zookeeper returned:  $result");
   # 1380684: change the timeout to 180s from 60s
   my $timeout = VDNetLib::Common::GlobalConfig::START_ZOOKEEPER_TIMEOUT;
   my $started = 0;
   my $startTime = time();
   while ($timeout && $startTime + $timeout > time()) {
      $result = `$sessionZkDir/bin/zkServer.sh status 2>&1`;
      if ($result =~ /standalone/i) {
         $started = 1;
         last;
      } else {
         sleep 2;
      }
   }
   if (!$started) {
      $vdLogger->Error("Failed to start zookeeper server: $result");
      VDNetLib::Common::Utilities::CollectMemoryInfo();
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $pid = `cat $sessionZkDir/zookeeper_server.pid`;
   if ((not defined $pid) || ($pid eq "")) {
      $vdLogger->Error("Failed to get the zookeeper pid from $sessionZkDir: " .
                       $result);
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Debug("Zookeeper pid: $pid");
   return $pid;
}


########################################################################
#
# StopZookeeper --
#     Method to stop zookeeper server of this session
#
# Input:
#     cleanup: boolean to indicate whether the runtime directory should
#              be cleaned or not
#
# Results:
#     SUCCESS, if the server is stopped successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     No more connections can be established to zookeeper server
#     started in this session
#
########################################################################

sub StopZookeeper
{
   my $self    = shift;
   my $cleanup = shift;
   $cleanup = (defined $cleanup) ? 1 : 0;
   my $sessionZkDir = $self->{'zookeeperObj'}{'runtimeDir'};
   if (not defined $sessionZkDir) {
      return SUCCESS;
   }
   if ($sessionZkDir eq '/') {
      $vdLogger->Error("Attempting to remove something under root system");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $cmd = "$sessionZkDir/bin/zkServer.sh stop";
   my $logFileName = $self->{'logDir'} . "/" .
      VDNetLib::Common::GlobalConfig::DEFAULT_LOG_FILE;
   my $result = `$cmd 2>&1 > /dev/null`;
   my $timeout = 60;
   my $startTime = time();
   while ($timeout && $startTime + $timeout > time()) {
      $result = `$sessionZkDir/bin/zkServer.sh status 2>&1`;
      if ($result =~ /probably not running/i) {
         if ($cleanup) {
            `rm -rf $sessionZkDir`;
         }
         return SUCCESS;
      } else {
         sleep 2;
      }
   }
   $vdLogger->Error("Failed to stop zookeeper server");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


########################################################################
#
# StartZookeeperSession --
#     Method to configure zookeeper and start the server for this
#     session
#
# Input:
#     None
#
# Results:
#     SUCCESS, if zookeeper session is initialized successfully;
#     FAILURE, in case of any error
#
# Side effects:
#
########################################################################

sub StartZookeeperSession
{
   my $self = shift;
   #
   # Create a runtime directory for zookeeper
   #
   my $userOptions = $self->{'userInputHash'}{'options'};
   $userOptions = VDNetLib::Common::Utilities::ConvertKeysToLowerCase($userOptions);
   my $sessionZkDir;
   my $configuredSpec;
   if ((defined $self->{zkDataDir}) && (defined $self->{zkPort})) {
      $sessionZkDir = $self->{zkDataDir};
      $configuredSpec->{port} = $self->{zkPort};
      $configuredSpec->{runtimeDir} = $sessionZkDir;
   } else {
      $sessionZkDir = $userOptions->{snapshotdir} . "/zookeeper-$$";
      $configuredSpec = $self->CreateZookeperSpec($sessionZkDir);
      if ($configuredSpec eq FAILURE) {
         $vdLogger->Error("Failed to create zookeeper spec");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   my $zkPID = $self->StartZookeeper($configuredSpec);
   if (FAILURE eq $zkPID) {
      $vdLogger->Error("Failed to start zookeeper session");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $configuredSpec->{pid} = $zkPID;
   if (FAILURE eq $self->ConfigureZookeeper($configuredSpec)) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $chmodRet = system("chmod", "-R", "ugo+rw", $sessionZkDir);
   if ($chmodRet) {
      my $userName = $ENV{USER} || $ENV{USERNAME};
      $vdLogger->Error("Could not change permissions to snapshotDir: " .
          "$sessionZkDir ensure that user: $userName has permissions");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# TestbedDeploy --
#     Method to deploy all necessary components like host, vc, vsm etc
#     using deployTestbed.py
#
# Input:
#     spec: user spec (that contains entries from .yaml file)
#
# Results:
#     Updated userspec with ip address, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#
########################################################################

sub TestbedDeploy
{
   my $self = shift;
   my $testSpec = shift;
   my $testbedJSON = shift || $self->{testbedJSON};
   my $json;

   my $spec = VDNetLib::Common::Utilities::ProcessSpec($testSpec);
   %$json = %{$spec};
   my $convertHostToESX = 0;
   foreach my $component (keys %$spec) {
      $json->{$component} = VDNetLib::Common::Utilities::ExpandTuplesInSpec(
                                                         $json->{$component});
      if ($component eq "host") {
         $convertHostToESX = 1;
         $json->{'esx'} = $json->{$component};
         delete $json->{'host'};
      }
   }
   my $updatedHash = $json;
   #
   # convert the user spec to JSON, which is expected
   # by deployTestbed.py
   #
   my $jsonfile = $self->{logDir} . "/" . "config.json";
   my $result = open FILE, ">$jsonfile";
   if (not defined $result) {
      $vdLogger->Error("Could not open file $jsonfile: $!");
      return undef;
   }
   printf FILE encode_json($json);
   if ($self->{'testLevel'} ne 'cleanupOnly') {
      my $cmd = "python $FindBin::Bin/../scripts/deployTestbed.py " .
                "--logdir $self->{logDir} " .
                "--config $jsonfile --no-stdout";
      $cmd = $cmd . " --podspec " . $self->{podSpec} if (defined $self->{podSpec});
      # append contexts value
      $cmd = $cmd . " --contexts " . $self->{contexts} if (defined $self->{contexts});

      # Check if the testrunid is defined, this if for CAT
      if (defined $self->{testRunId}) {
         $cmd = $cmd . " --testrunid " . $self->{testRunId};
      }

      # set perforce environment, this is
      # required to generate ovf builds etc.
      $ENV{"P4USER"} = VDNetLib::Common::GlobalConfig::NETFVT_P4USER;
      $ENV{"P4PASSWORD"} = VDNetLib::Common::GlobalConfig::NETFVT_P4PASSWORD;
      $vdLogger->Debug("Testbed deploy command: $cmd");
      $vdLogger->Info("Checking or deploying testbed, " .
                      "please wait.. watch deployment logs at " . $self->{logDir} .
                      "/deploy_testbed.log");

      if (not defined $testbedJSON) {
         $cmd = $cmd . " 2>&1";
         $result = `$cmd`;
         if ($? != 0) {
            $vdLogger->Error("deployTestbed failed: cmd: $cmd\nerror: $result");
            return FAILURE;
         } else {
            $vdLogger->Trace("deployTestbed Passed: cmd: $cmd\noutput: " .
                             "$result");
         }
         $testbedJSON = $self->{logDir} . "/" . "testbed.json";
         if (defined $self->{'vdnetConf'}) {
            copy($testbedJSON, dirname($self->{'vdnetConf'}));
            $testbedJSON = dirname($self->{'vdnetConf'}) . '/testbed.json';
            `echo "TESTBED=$testbedJSON" >> $self->{'vdnetConf'}`;
         }
      }

      #
      # convert the updated JSON spec returned from deployTestbed.py
      #
      $updatedHash = VDNetLib::Common::Utilities::ConvertJSONToHash(
                                                            $testbedJSON);
      #
      # delete the keys that are primarily used for deployment
      #
      my @deployedKeys = ('instance', 'runid', 'disk');
      my @vmcomponents = ('vm', 'pswitch', 'dhcpserver', 'testinventory',
                          'network', 'torgateway', 'powerclivm', 'linuxrouter');
      foreach my $component (keys %$updatedHash) {
         foreach my $index (keys %{$updatedHash->{$component}}) {
            my $ip = $updatedHash->{$component}{$index}{ip};
            if ((defined $ip) && ($ip ne "unknown") && ($ip ne "None")) {
               $vdLogger->Info("$component\.$index ip address: $ip");
            } elsif (all {$_ ne $component} @vmcomponents) {
               $vdLogger->Error("Failed to deploy $component\.$index," .
                                "see $self->{logDir}/testbed/$component-$index/deploy.log");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
            if ((defined $updatedHash->{$component}{$index}{installtype}) &&
                  ($updatedHash->{$component}{$index}{installtype} eq 'nested')) {
               # save nested vm instance name to get the vmxName in future
               $updatedHash->{$component}{$index}{vmInstance} =
                         $updatedHash->{$component}{$index}{instance};
            }
            my $newIndex = '[' . $index . ']';
            $updatedHash->{$component}{$newIndex} =
               $updatedHash->{$component}{$index};
            delete $updatedHash->{$component}{$index};
            foreach my $deleteKey (@deployedKeys) {
               delete $updatedHash->{$component}{$newIndex}{$deleteKey};
            }
         }
      }
  }
  if (($convertHostToESX) && (defined $updatedHash->{'esx'})) {
     $updatedHash->{'host'} = $updatedHash->{'esx'};
     delete $updatedHash->{'esx'};
  }
  return $updatedHash;
}


########################################################################
#
# ConfigurePythonPackages
#     Method to configure/integrate with other python packages
#
# Input:
#     None
#
# Results:
#     Required python packages are installed and configured
#
# Side effects:
#     None
#
########################################################################

sub ConfigurePythonPackages
{
   my $self = shift;
   my $nsxSDKInstallPath = $self->{nsxSDKInstallPath} ||
      $self->ConfigureNsxSDKPackage();
   if ($nsxSDKInstallPath eq FAILURE) {
      $vdLogger->Error("Error encountered in configuring nsx-sdk package");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (defined $self->{userInputHash}{testbed}{logserver}) {
      $self->ConfigureLogInsightSDKPackage();
   }

   eval "require VDNetLib::InlinePython::VDNetInterface";
   if ($nsxSDKInstallPath ne SKIP) {
      $vdLogger->Info("Configured Nsx SDK package: $nsxSDKInstallPath");
      VDNetLib::InlinePython::VDNetInterface::InsertPath($nsxSDKInstallPath);
      VDNetLib::InlinePython::VDNetInterface::LoadInlinePythonModule("vmware.nsx_api");
   }
   VDNetLib::InlinePython::VDNetInterface::LoadInlinePythonModule("mh");
   VDNetLib::InlinePython::VDNetInterface::LoadInlinePythonModule("pylib");
   if(!VDNetLib::InlinePython::VDNetInterface::ConfigureLogger($self->{logDir})) {
      $vdLogger->Warn("Failed to configure Inline Python logger");
   }

}

##############################################################################
#
# ConfigureLogInsightSDKPackage --
#     Method to install and configure LogInsight SDK package
#     for VDNet consumption
#
# Input:
#     None
#
# Results:
#     LogInsight SDK lib will be updated under
#     ENV{LOGINSIGHT_SDK_INSTALLATION_PATH}
#
# Side effects:
#     None
#
##############################################################################

sub ConfigureLogInsightSDKPackage
{
   my $self = shift;
   my $loginsight_sdk_install_path = $ENV{LOGINSIGHT_INSTALLATION_PATH};
   my $loginsight_sdk_build = $ENV{LOGINSIGHT_SDK_BUILD};
   my $install_script = "$FindBin::Bin/../pylib/vmware/log_server" .
                        "/install_log_insight_sdk.py";
   my $args = '';
   if (defined $loginsight_sdk_install_path) {
      $args = $args . "--install-dir $loginsight_sdk_install_path";
   }
   if (defined $self->{'userInputHash'}{'options'}{'loginsightsdkbuild'}) {
       $args = $args . " --build-id ".
       "$self->{'userInputHash'}{'options'}{'loginsightsdkbuild'}";
   } elsif (defined $loginsight_sdk_build) {
      $args = $args . " --build-id $loginsight_sdk_build";
   }

   $args = $args . " --log-dir $self->{'logDir'}";
   my $log_file = $self->{'logDir'} . '/loginsight_sdk_install.out';
   my $cmd = "python $install_script $args > $log_file 2>&1";
   $vdLogger->Info("Running $cmd");
   `$cmd`;
   my $out = `cat $log_file`;

   my @lines = split(/\n/, $out);
   my $lastline = $lines[$#lines];
   my @words = split(/ /, $lastline);
   $loginsight_sdk_install_path = $words[$#words];
   if ((not defined $loginsight_sdk_install_path) || (!(-e $loginsight_sdk_install_path))) {
      $vdLogger->Error("Failed to install loginsight sdk, check $log_file for errors" .
                       "\nParsed $loginsight_sdk_install_path from $lastline");
      return FAILURE;
   }
   eval "require VDNetLib::InlinePython::VDNetInterface";
   VDNetLib::InlinePython::VDNetInterface::InsertPath($loginsight_sdk_install_path);
   VDNetLib::InlinePython::VDNetInterface::LoadInlinePythonModule("vmware.vapi");
   $vdLogger->Info("Configured Log Insight SDK package: $loginsight_sdk_install_path");
   return SUCCESS;
}


##############################################################################
#
# ConfigureNsxSDKPackage --
#     Method to install and configure NSX SDK package for VDNet consumption
#
# Input:
#     None
#
# Results:
#     Returns NSX_SDK_INSTALLATION_PATH or SKIP if nsxsdkbuild is not provided
#     NSX SDK lib will be updated under ENV{NSX_SDK_INSTALLATION_PATH}
#
# Side effects:
#     None
#
##############################################################################

sub ConfigureNsxSDKPackage
{
   my $self = shift;
   my $nsx_sdk_path = $ENV{NSX_SDK_INSTALLATION_PATH};
   my $nsx_sdk_build = $ENV{NSX_SDK_BUILD};
   my $install_script = "$FindBin::Bin/../pylib/vmware/nsx/install_nsx_sdk.py";
   my $args = '';

   if (defined $nsx_sdk_path) {
      $args = $args . "--install-dir $nsx_sdk_path";
   }
   if (defined $self->{'userInputHash'}{'options'}{'nsxsdkbuild'}) {
       $args = $args . " --build-id ".
       "$self->{'userInputHash'}{'options'}{'nsxsdkbuild'}";
   } elsif (defined $nsx_sdk_build) {
      $args = $args . " --build-id $nsx_sdk_build";
   } else {
      $vdLogger->Warn("Skipping nsx-sdk install, nsxsdkbuild not provided");
      return SKIP;
   }

   $args = $args . " --log-dir $self->{'logDir'}";
   my $log_file = $self->{'logDir'} . '/nsx_sdk_install.out';
   my $cmd = "python $install_script $args > $log_file 2>&1";
   $vdLogger->Info("Running $cmd");
   `$cmd`;
   my $out = `cat $log_file`;

   my @lines = split(/\n/, $out);
   my $lastline = $lines[$#lines];
   my @words = split(/ /, $lastline);
   my $nsxSDKInstallPath = $words[$#words];
   if ((not defined $nsxSDKInstallPath) || (!(-e $nsxSDKInstallPath))) {
      $vdLogger->Error("Failed to install nsx_sdk, check $log_file for errors" .
                       "\nParsed $nsxSDKInstallPath from $lastline");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if (defined $self->{'vdnetConf'}) {
      `echo "NSX_SDK_PATH=$nsxSDKInstallPath" >> $self->{'vdnetConf'}`;
   }
   return $nsxSDKInstallPath;
}



########################################################################
#
# GetDeployTest --
#     Method to return dummy test case hash for deployOnly scenario
#
# Input:
#     None
#
# Results:
#     Reference to a dummy test case hash
#
# Side effects:
#     None
#
########################################################################

sub GetDeployTest
{
   my $self = shift;

   my $dummyTest = {
      Component        => "Infrastructure",
      Category         => "vdnet",
      TestName         => "TestbedDeploy",
      testID           => "TDS::TestbedDeploy",
      Version          => "2" ,
      ExpectedResult   => "PASS",
      TestbedSpec      => {
      },

   };
}

########################################################################
#
# GetCleanupTest --
#     Method to return dummy test case hash for cleanupOnly scenario
#
# Input:
#     None
#
# Results:
#     Reference to a dummy test case hash
#
# Side effects:
#     None
#
########################################################################

sub GetCleanupTest
{
   my $self = shift;

   my $dummyTest = {
      Component        => "Infrastructure",
      Category         => "vdnet",
      TestName         => "TestbedClean",
      testID           => "TDS::TestbedClean",
      Version          => "2" ,
      ExpectedResult   => "PASS",
      TestbedSpec      => {
      },

   };
}

########################################################################
#
# GetATSTest --
#     Method to return dummy test case hash for running ATS test
#     using vdnet.
#
# Input:
#     None
#
# Results:
#     Reference to a dummy test case hash
#
# Side effects:
#     None
#
########################################################################

sub GetATSTest
{
   my $self = shift;
   my $tds  = shift;

   my $ATSTest = {
      Component        => "NSX",
      Category         => "vShield",
      TestName         => "ATSTest",
      testID           => $tds,
      Version          => "ATS" ,
      ExpectedResult   => "PASS",
      TestbedSpec      => dclone $self->{userInputHash}{testbed},
   };
}

########################################################################
#
# GetVCQETest --
#     Method to return dummy test case hash for running vcqe test
#     using vdnet.
#
# Input:
#     None
#
# Results:
#     Reference to a dummy test case hash
#
# Side effects:
#     None
#
########################################################################

sub GetVCQETest
{
   my $self = shift;
   my $tds  = shift;

   my $VCQETest = {
      Component        => "VIM",
      Category         => "VIM API",
      TestName         => "VCQETest",
      testID           => $tds,
      Version          => "VCQE" ,
      ExpectedResult   => "PASS",
      Summary          => "VCQE Test Session",
      TestbedSpec      => dclone $self->{userInputHash}{testbed},
   };
}


########################################################################
#
# GetMHTest --
#     Method to return dummy test case hash for running mh test
#     using vdnet.
#
# Input:
#     None
#
# Results:
#     Reference to a dummy test case hash
#
# Side effects:
#     None
#
########################################################################

sub GetMHTest
{
   my $self = shift;
   my $tds  = shift;

   my $MHTest = {
      Component        => "MH",
      Category         => "MH",
      TestName         => "MHTest",
      testID           => $tds,
      Version          => "MH" ,
      ExpectedResult   => "PASS",
      Summary          => "MH Test Session",
      TestbedSpec      => dclone $self->{userInputHash}{testbed},
   };
}


########################################################################
#
# CanTestbedSetupBeSkipped --
#     Method to check if the testbedspec initialization for the given
#     testcase can be skipped
#
# Input:
#     rootIndex   : unique index to represent the testbed spec
#
# Results:
#     1 if the setup can be skipped;
#     0, if the setup cannot be skipped;
#     FAILURE, in case of any other error;
#
# Side effects:
#     None
#
########################################################################

sub CanTestbedSetupBeSkipped
{
   my $self         = shift;
   my $rootIndex    = shift;

   my $zkHandle = $self->{'zookeeperObj'}->CreateZkHandle();

   if (not defined $zkHandle) {
      $vdLogger->Error("ZooKeeper handle is empty");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   #
   # If there is a node in zookeeper tree with the given unique
   # index; then the setup can be skipped
   #
   my $result = $self->{'zookeeperObj'}->CheckIfNodeExists($rootIndex, $zkHandle);
   $self->{'zookeeperObj'}->CloseSession($zkHandle);
   if ($result ne FAILURE) {
      return 1;
   } else {
      $vdLogger->Debug("Root index $rootIndex does not exist");
      return 0;
   }
}

########################################################################
#
# UpdateRacetrackAttrs--
#   Updates the racetrack attributes.
#
# Input:
#   Attributes defined as a key value pair in a hash.
#
# Results:
#   Returns SUCCESS or FAILURE.
#
# Side effects:
#     None
#
########################################################################

sub UpdateRacetrackAttrs
{
    my $self = shift;
    my $attrs = shift;
    if (not defined $attrs) {
        $vdLogger->Error("Need to define the attribute to be updated");
        VDSetLastError("ENOTDEF");
        return FAILURE;
    }
    if (ref($attrs) ne 'HASH') {
        $vdLogger->Error('The attributes must be defined in a hash');
        VDSetLastError("EINVALID");
        return FAILURE;
    }
    my @modifiableAttrs = ('BuildID', 'User', 'Product', 'Description',
                           'HostOS', 'ServerBuildID', 'Branch', 'BuildType',
                           'TestType');
    my $badKey = undef;
    foreach my $key (keys %$attrs) {
        if (grep {$_ eq $key} (keys %$attrs)) {
            next;
        }
        $badKey = $key;
    }
    if (defined $badKey) {
        $vdLogger->Error("Can not update $badKey, allowed values attrs are:" .
                         Dumper(@modifiableAttrs));
        VDSetLastError("EINVALID");
        return FAILURE;
    }
    my $response = $vdLogger->{rtrackObj}->TestSetUpdate($attrs);
    if (not defined $response) {
        $vdLogger->Error("Failed to update racetrack attributes using hash:" .
                         Dumper($attrs));
        return FAILURE;
    }
    return SUCCESS;
}

########################################################################
#
# Run --
#     Core method which handles multiple testsession including
#     testbed deployment and resource caching
#
# Input:
#     None
#
# Results:
#     sessionSummary: reference to an array of hash containing
#                     result summary for each test session
#
# Side effects:
#     None
#
########################################################################

sub Run
{
   my $self = shift;
   my $result;

   # Get the complete test list for this session
   my $testcaseList = $self->GetTestList();
   if ($testcaseList eq FAILURE) {
      $vdLogger->Error("Failed to testcase list");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{testcaseList} = $testcaseList;

   # Check if multiple testcases are specified in addition to --testbed
   if (defined $self->{'cliParams'}->{testbed}) {
      my $testListCount = scalar(@{$testcaseList});
      if ((defined $testListCount) && ($testListCount > 1)) {
         $vdLogger->Error("Command line option -t : " .
             "Can not specify multiple testcases such as using " .
             "testcase wildcard (*) or tags (-t) in addition to ".
             "--testbed (save|reuse|clean)");
         if ($self->{'cliParams'}->{testbed} =~ /reuse_between_tests/i) {
            $vdLogger->Warn("VDNet go on to run cases with --testbed reuse_between_tests" .
             " specified in case you need this function. Please use it carefully" .
             " and triage failures since it is not a common usage");
          } else {
            return FAILURE;
         }
      }
   }

   # Check if deploy testbed is needed (only when config file is passed)
   if ((defined $self->{userInputHash}{testbed}) &&
      ($self->{testLevel} !~ /reuse/i)){
      my $deployedSpec = $self->TestbedDeploy($self->{userInputHash}{testbed});
      if ($deployedSpec eq FAILURE) {
         $vdLogger->Error("Error encountered in testbed deploy");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         $self->{userInputHash}{testbed} = $deployedSpec;
      }
   }

   #
   # From this point, running test cases are handled
   #

   if (defined $vdLogger->{rtrackObj}) {
      my $racetrackAttrsUpdate = {};
      # exists $testcaseList->[0]->{Product} will add an element at index 0
      # even if 'Product' does not exist. So, better to use defined
      if ((scalar(@$testcaseList)) &&
         (defined $testcaseList->[0]->{Product})) {
         $racetrackAttrsUpdate->{Product} = $testcaseList->[0]->{Product};
         $result = $self->GetBuild(lc($racetrackAttrsUpdate->{Product}));
         if ($result eq FAILURE) {
            $vdLogger->Warn("Error while getting build info for product
                             $racetrackAttrsUpdate->{Product}");
         } else {
            $racetrackAttrsUpdate->{BuildID} = $result->{id};
            $racetrackAttrsUpdate->{Branch} = $result->{branch};
            $racetrackAttrsUpdate->{BuildType} = $result->{buildtype};
         }
      }
      if (defined $self->{cliParams}->{testSetDescription}){
         $racetrackAttrsUpdate->{Description} = $self->{cliParams}->{testSetDescription};
      }
      if (scalar(keys %$racetrackAttrsUpdate)) {
         my $ret = $self->UpdateRacetrackAttrs($racetrackAttrsUpdate);
         if ($ret eq FAILURE) {
             $vdLogger->Error("Failed to update racetrack attributes");
             return FAILURE;
         }
      }
   }
   #
   # If testbed spec is defined in yaml/json and there
   # is no -t option given, then treat this as a deploy
   # only scenario
   #
   if ((defined $self->{userInputHash}{testbed}) &&
       (!scalar(@$testcaseList))) {
      if ($self->{'testLevel'} eq 'cleanupOnly'){
         $vdLogger->Info("Only cleaning up testbed components, no tests will be run");
         push(@$testcaseList, $self->GetCleanupTest());
      } else {
         $vdLogger->Info("Only deploying testbed components, no tests will be run");
         push(@$testcaseList, $self->GetDeployTest());
         $self->{'testLevel'} = 'deployOnly';
         $self->{'yamlWins'} = 1;
      }
   }

   #Initialize the VDNet session
   if (scalar(@$testcaseList)) {
      $result = $self->Initialize();
      # start watchdog no matter Initialize() fail or not
      my $watchdog_pid_filename;
      $watchdog_pid_filename = $self->{'logDir'} . "/" .
         (VDNetLib::Common::GlobalConfig::WATCHDOG_PID_FILENAME);

      #Should check cli params as well as userInputHash
      my $testbedDeployment = $self->{'cliParams'}{testbed} ||
         $self->{userInputHash}{options}{testbed};

      if (-e $watchdog_pid_filename ) {
         $vdLogger->Info("vdNet.pl PID $$ watchdog PID file name " .
                         $watchdog_pid_filename);
         my $ret = system ("$FindBin::Bin/vdnet-watchdog.pl -p $$ -i $watchdog_pid_filename &");
         if ($ret) {
            $vdLogger->Error("System command \"vdnet-watchdog.pl -p $$ -i " .
                             $watchdog_pid_filename . " &\" failed with return code $ret");
         }
      }
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to initialize VDNet session");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   my $testCount = 0;
   my @sessionsSummaryContainer;
   my $previousTestcase;
   foreach my $testcase (@$testcaseList) {
      $testCount = $testCount + 1;
      my ($testName, $testSession, $testSessionResult);

      my $dupTestcase = dclone($testcase);
      %$dupTestcase = (map { lc $_ => $dupTestcase->{$_}} keys %$dupTestcase);
      $testName = $dupTestcase->{testid};
      $testName =~ s/::/./g;
      if ((defined $dupTestcase->{automationstatus}) &&
          ($dupTestcase->{automationstatus} =~ /notautomated/i)) {
         $vdLogger->Warn("$testName marked as NotAutomated, skipped.");
         $testSession = "FAILURE";
         $testSessionResult = "SKIP";
         goto EXIT_TEST;
      }

      my $lastTest = ($testCount == scalar(@$testcaseList)) ? 1 : 0;
      my $testVersion = (defined $dupTestcase->{version}) ?
         $dupTestcase->{version} : 2;
      if ($testVersion =~ m/(^\d+)/) {
         $testVersion = "VDNetv" . $1;
      }
      my $testSessionVersion = "VDNetLib::TestSession::$testVersion";
      # TODO: compose the value for 'userInputHash' from $self instead
      # of directly passing $self
      $testSessionResult = "FAIL"; # set the default test result to FAIL

         my $logDir = $self->{'logDir'} . "/" . $testCount . "_" .
         $testName;

      my $sessionLogger = $self->{'logger'};
      $testSession = $testSessionVersion->new(
                                              'userInputHash' => $self,
                                              'testcaseHash'  => $testcase,
                                              'logger'        => $sessionLogger,
                                              'logDir'        => $logDir,
                                              'testInfoCSVFH' => $self->{'testInfoCSVFH'},
                                              'testCaseNumber'=> $testCount,
                                              'zookeeperObj'  => $self->{'zookeeperObj'},
                                              'interactive'   => $self->{'interactive'});

      if ($testSession eq FAILURE) {
         $vdLogger->Error("Failed to create test session object for $testcase");
         VDSetLastError(VDGetLastError());
         goto EXIT_TEST;
      }
      my $useCacheforTestbedSetup;
      if ($self->{cacheTestbed} && (defined $previousTestcase)) {
         #
         # TestbedSpec optimization
         #
         if ( $previousTestcase->{'isLastTestInTheGroup'} == 1) {
            $useCacheforTestbedSetup = 0;
         } else {
            $vdLogger->Info("Re-using testbed setup from previous test session");
            $useCacheforTestbedSetup = 1;
         }
      } else {
         $useCacheforTestbedSetup = 0;
      }
      $previousTestcase = $testcase; # update previous testcase
      # Store the current test session as an attribute of Session object
      $self->{currentTestSession} = $testSession;

      if (!$useCacheforTestbedSetup &&
          (($self->{'testLevel'} eq 'complete') ||
           ($self->{'testLevel'} eq 'deployOnly'))) {
         eval {
            $result = $testSession->TestbedSetup();
         };
         if ($@)
         {
            $vdLogger->Error("Exception thrown while testbed setup " . $@);
            $result = FAILURE;
         }
         $vdLogger->Debug("Setup result: $result");
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to complete setup for $testName");
            VDSetLastError(VDGetLastError());
            goto EXIT_TEST;
         } elsif ($self->{'testLevel'} eq 'deployOnly') {
            $testSessionResult = "PASS";
         }
      }

      if ($self->{'testLevel'} eq 'complete' ||
          $self->{'testLevel'} eq 'workloadsOnly') {
         eval {
            $result = $testSession->RunTest();
         };
         if ($@) {
            $vdLogger->Error("Exception thrown while run test " . $@);
            $result = FAILURE;
         }
         if ($result eq FAILURE) {
            $vdLogger->Error("$testName returned failure");
            VDSetLastError(VDGetLastError());
         } else {
            $testSessionResult = $testSession->{'result'};
         }
      }
      $testSession->{result} = $testSessionResult;

EXIT_TEST:
      my $doCleanup = FALSE;
      $testSession = (defined $testSession) ? $testSession : FAILURE;
      if ($testSession ne FAILURE) {
         # if interactive mode is defined and in case of failure or
         # other interactive point, enter in to it
         if ((defined $self->{interactive}) &&
             (!$self->{exitOnInteractive}))    {
            if ((($result ne FAILURE) && ($testSession->{result} ne FAIL)) &&
                ($self->{interactive} =~ /onfailure/i)) {
               $vdLogger->Info("Interactive mode $self->{interactive} set, " .
                               "no errors found, so proceeding to exit " .
                               "sequence");
            } else {
               $self->InteractiveMode($testSession);
            }
         }
         if ($testSession->CheckupAndRecovery() eq FAILURE) {
            $vdLogger->Error("Check up and recovery failed after $testName");
            $testSessionResult = "FAIL";
            my $newLogDir = $testSession->{logDir} . "/health_check_logs";
            $testSession->{testbed}->CollectAllLogs(TRUE, $newLogDir);
            my $command = "echo \"health_check_logs\" >> " .
               $testSession->{logDir} . "\/README";
            if (system($command) != 0) {
               $vdLogger->Error("Command $command failed!");
            }
            $command = "echo \"\t- Logs collected when health checks have " .
               "failed due to cores or PSOD\" >> " .
               $testSession->{logDir} . "\/README";
            if (system($command) != 0) {
               $vdLogger->Error("Command $command failed!");
            }
         }
         #
         # There are 2 modes of testbed reuse.
         # 1. manually using testbed: reuse option
         # 2. runtime optimization using cacheTestbed
         # For #1, cleanup should happen only when
         # testbed: cleanup option is specified
         # For #2, cleanup should happen only
         # when it is last test.
         #
         #
         if ($self->{cacheTestbed}) {
            if ( $testcase->{'isLastTestInTheGroup'} == 1 ) {
               $doCleanup = TRUE;
            } else {
               #
               # Fix for PR1211916: destroy testbed zookeeper handle object,
               # otherwise, segment fault would occur in workload process.
               #
               my $testbed = $testSession->{testbed};
               $testbed->{zookeeperObj}->CloseSession($testbed->{zkHandle});
               $vdLogger->Info("Cleanup will be skipped because of cache testbed option ");
            }
         } elsif (($self->{'testLevel'} eq 'complete') ||
                  ($self->{'testLevel'} eq 'cleanupOnly')) {
            $doCleanup = TRUE;
         }
         if ($self->{exitOnInteractive}) {
            $vdLogger->Info("Exiting the session since exit on interactive mode defined");
            $lastTest = TRUE;
            $doCleanup = FALSE;
         }
         if ($doCleanup) {
            $result = $testSession->Cleanup($lastTest);
            $vdLogger->Info("cleanup result: $result");
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to do testcase $testName cleanup");
               VDSetLastError(VDGetLastError());
               $testSessionResult = "FAIL"; # override test result if cleanup failed
            } elsif ($self->{'testLevel'} eq 'cleanupOnly') {
               $testSession->{result} = "PASS";
               $testSessionResult = "Pass";
            }
         }
         $testSession->End($testSessionResult);
         $testSession->{result} = $testSessionResult;
      } else {
         $testSession = {
            'starttime' => time(),
            'result'    => $testSessionResult,
         };
      }

      $vdLogger = $sessionLogger;

      $testSession->{endtime} = (defined $testSession->{endtime}) ?
         $testSession->{endtime} : time();
      $testSession->{logFileSize} = (defined $testSession->{logFileSize}) ?
         $testSession->{logFileSize} : (-s $testSession->{testLog} || 0);
      my $sessionSummary = {
         testname    => $testName,
         starttime   => $testSession->{starttime},
         endtime     => $testSession->{endtime},
         result      => $testSession->{result},
         testID      => $testSession->{testcaseHash}{testID},
         logDir      => $testSession->{'logDir'},
         logFileSize => $testSession->{'logFileSize'},
         testStartOffset => $testSession->{'testStartOffset'}
      };
      push(@sessionsSummaryContainer, $sessionSummary);
      $self->UpdateCATSummary($sessionSummary, $testCount);

      # Remove the coupling across test cases if use hash as the value of
      # ExpectedResult.
      VDCleanErrorStack();

      #
      # if the session result is ABORT, then no point running any more tests.
      # For example, if the host hit psod, we need to quit right which will help
      # figure out the last test that caused psod, otherwise it was difficult
      # to make a decision quickly.
      #
      if ($testSession->{result} =~ /ABORT/i) {
         last;
      }
   }
   $self->CreateReproScript(\@sessionsSummaryContainer);
   return \@sessionsSummaryContainer;
}


########################################################################
#
# InteractiveMode --
#     Entry point for vdnet's interactive mode.
#     The purpose of this method is to run workloads in a test session
#     without modifying the content of the original test case.
#     In addition to running workload, few other commands can
#     also supported, for example:
#     list sequence, show workload, run workload,
#     add workload, set breakpoint, show workload in yaml/hash,
#     set starting point, run sequence etc
#
# Input:
#     testSession: reference to a test session object
#
# Results:
#     The result of a parent/actual test session does not change.
#     The result before entering interactive mode is retained.
#     Within interactive mode, the result depends on users
#     interaction with the test case.
#
# Side effects:
#     None
#
########################################################################

sub InteractiveMode
{
   my $self = shift;
   my $testSession = shift;

   # Resetting interactive point and final result
   # otherwise interactive session may not proceed
   $testSession->SetInteractivePoint();

   #
   # Use print instead of $vdLogger for control commands
   #
   my $marker = '#' x 72;
   print "\n" . $marker . "\n";
   print "Entering interactive mode...\n";
   print "You are now in vdnet's interactive mode.\n" .
         "Enter Ctrl+d to exit this mode.\n" .
         "Once exiting this mode, the testbed will be cleaned up.\n" .
         "At the prompt, enter h for help.\n";
   print $marker ."\n";
   my $promtString = "\ninteractive-mode>>>>>>:";
   my $command;
   print $promtString ;
   do {
      if ($command) {
         eval {
            if (defined $testSession->{workloadsManager}) {
               $testSession->{workloadsManager}->ResetFinalResult();
            }
            $self->ProcessInteractiveCommands($testSession, $command);
         };
         if ($@) {
            print "Caught exception: $@\n";
         }
         print $promtString ;
      }
   } while (defined($command = <STDIN>));
}


########################################################################
#
# ProcessInteractiveCommands --
#     This method handles all input in interactive mode of vdnet
#     session
#
# Input:
#     testSession: reference to a test session object
#     command    : command entered in interactive mode.
#                  Supported commands can be found using
#                  help option
#
# Results:
#     Within interactive mode, the result depends on user's
#     interaction with the test case.
#
# Side effects:
#     None
#
########################################################################

sub ProcessInteractiveCommands
{
   my $self        = shift;
   my $testSession = shift;
   my $command     = shift;

   $command =~ s/^\s+//; # remove leading spaces
   $command =~ s/\s+$//; # remove trailing spaces
   #
   # GetOptionsFromString() method is used to process the command.
   # The advantage of this method is same as GetOpts, especially
   # the short and long form of input can be supported
   #
   if ($command =~ /^\w{2,}/) {
      # prepend -- if the command has 2 or more characters
      # so that GetOptionsFromString() can understand the command
      $command = '--' . $command;
   } else {
      # prepend - if the command has less than 1 character
      $command = '-' . $command;
   }
   my ($help, $listSequence, $runWorkload, $showWorkload,
      $showHash);

   my ($result, $args) = GetOptionsFromString($command,
                    "help|h"      => \$help,
                    "ls|ls"       => \$listSequence,
                    "show|s=s"    => \$showWorkload,
                    "run|r=s"     => \$runWorkload,
                    "hash|hash=s" => \$showHash,
                    );

   # create the help menu for interactive mode
   my $table = Text::Table->new("options", "", "description");
   my $underline = '-' x 12;
   $table->load([$underline, "", $underline]);
   $table->load(["h|help", ":", " displays this help message"]);
   $table->load(["ls", ":", " displays workloads sequence"]);
   $table->load(["r|run", ":", " run the given workload <>"]);
   $table->load(["s|show", ":", " show the given workload <>"]);
   $table->load(["hash", ":", " show the given workload in hash"]);
   $table->load(["ctrl+d", ":", " exit interactive mode"]);
   my $usage = $table->stringify();

   my $workloadManager = $testSession->GetWorkloadsManagerObj();
   my $exitSequence;
   # Process each command
   # Note: use print instead of logger
   if ($listSequence) {
      $result = $testSession->GetMainSequence();
      $exitSequence = $testSession->GetExitSequence();
      print "Sequence  : ".VDNetLib::Common::Utilities::SerializeData($result) ."\n\n";
      if (defined $exitSequence) {
         print "ExitSequence  : ".VDNetLib::Common::Utilities::SerializeData($exitSequence) ."\n";
      }
   } elsif (($runWorkload)) {
      $result = $workloadManager->RunWorkload($runWorkload);
   } elsif ($showWorkload) {
      $result = $testSession->GetWorkload($showWorkload);
      print Dump($result) . "\n";
   } elsif ($showHash) {
      $result = $testSession->GetWorkload($showHash);
      print Dumper($result);
   } elsif ($help) {
      print "$usage\n";
   } else {
      $command =~ s/^-*//;
      print "Unknown command given: $command, enter h for help\n";
   }
   return;
}


########################################################################
#
# CreateReproScript --
#     Method to create a repro script for every test case
#     and a consolidated test case list (failures only)
#
# Input:
#     sessionsSummaryContainer: reference to an array of session's
#                               summary container
#
# Results:
#     repro scripts will be created one for the session and one for
#     each test case
#
# Side effects:
#     None
#
########################################################################

sub CreateReproScript
{
   my $self = shift;
   my $sessionsSummaryContainer = shift;

   my $userInput = $self->{'userInputHash'};

   my $testbed = $userInput->{testbed};
   if (defined $testbed) {
      # remove the ip address of all inventory items if they were deployed
      # on cloud.
      foreach my $inventory (keys %$testbed) {
         foreach my $index (keys %{$testbed->{$inventory}}) {
            if (defined $testbed->{$inventory}{$index}{ip}) {
               delete $userInput->{testbed}{$inventory}{$index}{ip};
            }
         }
      }
   }

   #
   # TODO: currently using vdnet source from /build/trees, but
   # if user's private code is accessible throughout company,
   # like dbc. that should be supported as well.
   #
   my $vdnetSource = VDNetLib::Common::GlobalConfig::GetDefaultVDNetSourceDirectory();
   my $vdnet = '/build' . $vdnetSource . '/main/vdnet';
   my $reproDir = '/dbc/pa-dbc1113/netfvt/repro';
   if ( -d $reproDir) {
      $reproDir = '/dbc/pa-dbc1113/netfvt/repro' . '/' .
                  (getpwuid($<))[0];
   } else {
      $reproDir = $ENV{HOME} . '/' . 'repro';
   }
   `mkdir -p $reproDir`;
   if ( -d $reproDir) {
      $vdLogger->Debug("Repro config will be created in $reproDir");
   } else {
      $vdLogger->Error("Failed to create repro directory: $reproDir");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $reproYaml = "$reproDir/vdnet-config-$$\.yaml";
   # add a suffix "repro" to testrunid to indicate VMs deployed on cloud
   # are for repro purpose
   if (defined $self->{testRunId}) {
      $userInput->{options}{testrunid} = $self->{testRunId} . "-repro";
   }
   DumpFile($reproYaml, $userInput); # create yaml config file

   my $reproLauncher = undef;
   if ($ENV{VDNET_GATEWAY}) {
      $reproLauncher = $ENV{VDNET_GATEWAY};
   } else {
      $reproLauncher = VDNetLib::Common::Utilities::GetLocalIP();
   }
   # Add command to ssh directly to vdnet gateway (preferred) or
   # launcher where test was executed.
   my $baseCommand = 'ssh ' . $reproLauncher . ' -C ' .
                     $vdnet . ' --config ' . $reproYaml;
   my $sessionCommand = $baseCommand;
   my $failedTestSessions = 0;
   foreach my $summary (@$sessionsSummaryContainer) {
      my $logDir = $summary->{logDir};
      my $testID = $summary->{testID};
      $testID =~ s/^TDS:://;
      $testID =~ s/::/./g;
      my $command;
      $command = $baseCommand . ' -t ' . $testID;
      # for session repro script, use only failed tests
      if ($summary->{result} !~ /PASS/i) {
         $sessionCommand = $sessionCommand . ' -t ' . $testID;
         my @temp = split(/\./, $testID);
         $command = $command . ' --interactive onfailure';
         my $reproScript = $logDir . '/repro.sh';
         # creating repro script for test case
         `echo "$command" >> $reproScript`;
         `chmod a+x $reproScript`;
         $failedTestSessions++;
      }
   }
   if ($failedTestSessions) {
      my $reproScript = $self->{logDir} . '/repro.sh';
      # creating repro script for entire session
      `echo "$sessionCommand" >> $self->{logDir}/repro.sh`;
      `chmod a+x $reproScript`;
   }
   `chmod 755 -R $self->{logDir}`;
}


########################################################################
#
# GetBuild --
#     Method to get the build information for given product to be
#     updated in racetrack.
#
# Input:
#     product: 'Name of the product'
#
# Results:
#     ref to hash containing build details for given product.
#     On Failure FAILURE
#
# Side effects:
#     None
#
########################################################################

sub GetBuild
{
   my $self = shift;
   my $product = shift;
   my $testbed = $self->{userInputHash}->{testbed};
   my $result;
   my $build;

   if (not defined $product) {
      $vdLogger->Error("Product is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my %productMap = ('nsxtransformers' => 'nsxmanager',
                      'nsx transformers' => 'nsxmanager',
                      'nsx' => 'vsm',
                      'esx' => 'host' # host is used for ESX products.
                     );

   if (exists $testbed->{$productMap{$product}}) {
      if (defined $testbed->{$productMap{$product}}{'[1]'}->{build}) {
         $build = $testbed->{$productMap{$product}}{'[1]'}->{build};
      } else {
         $vdLogger->Error("Failed to get build for $productMap{$product}");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Given product $product is not valid");
      return FAILURE;
   }

   # get build details like type, branch etc.
   $result = VDNetLib::Common::FindBuildInfo::GetBuildInfo($build);
   return $result;
}

1;
