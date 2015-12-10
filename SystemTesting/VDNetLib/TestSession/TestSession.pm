########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::TestSession::TestSession;

#
# This package is a base class which stores attributes and
# implements methods relevant to test session.
# Some of the basic methods include: Initialize(), TestbedSetup(),
# RunTest(), Cleanup()
#
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use VDNetLib::Common::Utilities;
use VDNetLib::Workloads::WorkloadsManager;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                   SUCCESS SKIP VDCleanErrorStack);


########################################################################
#
# new --
#     Contructor to create an instance of
#     VDNetLib::TestSession::TestSession
#
# Input:
#     Named hash parameter with following keys:
#     testcaseHash : reference to a vdnet test case hash
#     userInputHash: user input parameters to vdnet
#
# Results:
#     An object of VDNetLib::TestSession::TestSession, if successful;
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

   # make a local copy of specs
   my %testcase   = %{$options{'testcaseHash'}};
   my %userInput  = %{$options{'userInputHash'}};

   my $testcaseHash = \%testcase;
   my $userInputHash = \%userInput;
   # check basic parameters
   if ((not defined $userInputHash) || (not defined $testcaseHash)) {
      $vdLogger->Error("Testcase hash or user input hash not provided");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $self = {
      'hosted'        => 0,
      'testcaseHash'  => $testcaseHash,
      'userInputHash' => $userInputHash,
      'logDir'        => $options{'logDir'},
      'logger'        => $options{'logger'},
      'interactive'   => $options{'interactive'},
      'testInfoCSVFH' => $options{'testInfoCSVFH'},
      'testFramework'     => undef,
   };
   #
   # TODO: Compose the following attributes based on JSON config spec too
   #
   #
   $self->{'userInputHash'}   = $userInputHash->{'userInputHash'};
   $self->{'userTestbedSpec'} = $userInputHash->{'userTestbedSpec'};
   $self->{'vc'}           = $userInputHash->{cliParams}{vc};
   $self->{'hostlist'}     = $userInputHash->{cliParams}{hostlist};
   $self->{'vmlist'}       = $userInputHash->{cliParams}{vmlist};
   $self->{'pswitch'}      = $userInputHash->{cliParams}{pswitch};
   # Read noCleanup from $session
   $self->{'noCleanup'}	   = $userInputHash->{noCleanup};
   $self->{'skipSetup'}	   = $userInputHash->{cliParams}{skipSetup};
   $self->{'vdnetOptions'} = $userInputHash->{vdnetOptions};
   $self->{'sut'}          = $userInputHash->{sut};
   $self->{'helper'}       = $userInputHash->{helper};
   $self->{'vdNetSrc'}     = $userInputHash->{vdNetSrc};
   $self->{'vdNetShare'}   = $userInputHash->{vdNetShare};
   $self->{'sharedStorage'}= $userInputHash->{'sharedStorage'};
   $self->{'vmServer'}     = $userInputHash->{'vmServer'};
   $self->{'vmShare'}      = $userInputHash->{'vmShare'};
   $self->{'noTools'}      = $userInputHash->{'noTools'};
   $self->{'collectLogs'}  = $userInputHash->{'collectLogs'};
   $self->{'stafHelper'}   = $userInputHash->{'stafHelper'};
   $self->{'maxWorkers'}   = $userInputHash->{'maxWorkers'};
   $self->{'maxWorkerTimeout'}   = $userInputHash->{'maxWorkerTimeout'};
   $self->{'maxWorkloadTimeout'}   = $userInputHash->{'maxWorkloadTimeout'};
   $self->{'testFramework'} = $self->{userInputHash}{'testframework'};
   $self->{testbed}        = undef; # stores reference to testbed object

   my $testID = $testcaseHash->{testID};
   $testID =~ s/^TDS:://; # remove TDS::
   $testID =~ s/::/\./g;  # replace :: with .

   $self->{testName} = $testID;
   $self->{result} = "FAIL";

   if ((defined $self->{'noCleanup'}) &&
       ($self->{'noCleanup'} ne 0)) {
      $vdLogger->Info("Option not to cleanup on failure is provided");
   }

   $testcaseHash->{testID} =~ /.*::([^:]+)::.*/;
   my $tdsKey = lcfirst($1) . "Tds";
   $self->{'tdsObj'} = undef;
   if (defined $userInputHash->{$tdsKey}) {
      my $tdsObj = $userInputHash->{$tdsKey}->new('testSession' => $self,);
      $self->{'tdsObj'} = $tdsObj;
   }

   bless $self, $class;
   return $self;
}


########################################################################
#
# Initialize--
#     Method to initialize test session which includes initializing
#     logger and based configuration to run a test
#
#
# Input:
#     testCount: id to indicate the test count in entire session
#
# Results:
#     SUCCESS, if the test session is initialized successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub Initialize
{
   my $self      = shift;
   my $testcaseHash  = $self->{testcaseHash};
   my $testInfoCSVFH = $self->{testInfoCSVFH};
   my $logDir        = $self->{'logDir'};
   my $logger        = $self->{'logger'};
   my $logLevel      = $logger->{'logLevel'};
   my $logFileLevel  = $logger->{'logFileLevel'};
   my $logToConsole  = $logger->{'logToConsole'};
   my $rtrackObj     = $logger->{'rtrackObj'};
   my $hostUnderTest = "XXXX";
   my $testName      = $testcaseHash->{testID};

   $vdLogger->Debug("Running pre-configuration for $testName");
   if ( defined $self->{'tdsObj'} &&
        $self->{'tdsObj'}->can('Setup') &&
        $self->{'tdsObj'}->Setup() !~ "SUCCESS" ) {
         $vdLogger->Error("Failed to make pre-configuration for $testName");
         VDSetLastError("EOPFAILED");
         return FAILURE;
   } else {
      $vdLogger->Debug("Skipping pre-configuration for $testName");
   }

   $logger->Info("Working on $testName");

   my $tcRef = $testcaseHash;
   my $timeStamp = VDNetLib::Common::Utilities::GetTimeStamp();
   my $file = "testcase.log";
   unless(-d $logDir) {
      system("mkdir -p $logDir");
   }
   my $logFile = $logDir."/".$file;
   $logger->Info("Logs for $testName test are available in $logFile");

   if ($self->{"hosted"} == 0) {
      if(!VDNetLib::InlineJava::VDNetInterface::ConfigureLogger($logDir)) {
         $logger->Error("Failed to configure VCQA logger");
      }
      if(!VDNetLib::InlinePython::VDNetInterface::ConfigureLogger($logDir)) {
         $logger->Warn("Failed to configure Inline Python logger");
      }
   }
   #
   # Creating a sub-session under the given logger and
   # re-setting the vdLogger global variable.
   #
   VDNetLib::Common::GlobalConfig::CreateVDLogObj(
                                            'logFileName' => $logFile,
                                            'logToFile'   => 1,
                                            'logLevel'    => $logLevel,
                                            'logFileLevel' => $logFileLevel,
                                            'rtrackObj'   => $rtrackObj,
                                            'logToConsole'=> $logToConsole,
                                            'glob'        => \*TESTFH,
                                            );
   # Create a new sub racetrack session for every test case
   if (defined $vdLogger->{rtrackObj}) {
      my $testName = $tcRef->{'TestName'} || "UNDEFINED";
      my $comp = "$tcRef->{'Category'}::$tcRef->{'Component'}";
      my $summary = $tcRef->{'Summary'} || "UNDEFINED";

      if (1 == $vdLogger->Start($testName, $comp, $summary, $hostUnderTest)) {
         $vdLogger->Warn(
            "Failed to start racetrack session for test: $testName, " .
            "component: $comp, summary: $summary, host: $hostUnderTest");
      }
      if (!VDNetLib::InlinePython::VDNetInterface::ConfigureReporter(
             $vdLogger->{rtrackObj}->GetHandle())) {
         $vdLogger->Warn("Failed to configure reporter binding on logger");
      }
   }

   $self->{testLog} = $logFile;
   $self->{logDir} = $logDir;
   $self->{starttime} = time();

   #
   # update the testinfo.csv file.
   # In order to prevent CAT from using the test begin record as the
   # test's final result record, we write an empty results value.  This
   # causes CAT to ignore the line.
   # https://wiki.eng.vmware.com/ToolsEng/Projects/CAT/TestInfoCSV
   #
   if (defined $testInfoCSVFH) {
      $testName =~ s/::/./g;
      $self->{testStartOffset} = tell($testInfoCSVFH);
      my $message = "NA," . $self->{testCaseNumber} . "_" .
                    "$testName," . "," . "Running,".
                    "NA,\n";
      printf $testInfoCSVFH ($message);
   }

   return SUCCESS;
}


########################################################################
#
# RunTest--
#     Method to run the test
#
# Input:
#     None
#
# Results:
#     SUCCESS, if the test case executed successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RunTest
{
   my $self = shift;
   my $testName = $self->{testcaseHash}{TestName};
   $self->SetWorkloadsManagerObj();

   $vdLogger->Debug("Test case hash: " . Dumper($self->{testcaseHash}));
   my $workloadObj = $self->GetWorkloadsManagerObj();
   $self->{result} = $workloadObj->RunWorkload();
   $self->{endtime} = time();
   if (defined $self->{interactive}) {
      return SUCCESS;
   }

   if ( defined $self->{'tdsObj'} &&
        $self->{'tdsObj'}->can('Cleanup') &&
        $self->{'tdsObj'}->Cleanup() !~ "SUCCESS" ) {
      $vdLogger->Error("Failed to cleanup for $testName");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $vdLogger->Debug("Skipping cleanup for $testName");
   }

   if ($self->{result} eq "FAIL" || $self->{result} eq "FAILURE") {
      $vdLogger->Error("Testcase $testName returned failure");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# GetWorkloadsManagerObj--
#     Method to return workloads manager object
#
# Input:
#     None
#
# Results:
#     return workloads manager object
#
# Side effects:
#     None
#
########################################################################

sub GetWorkloadsManagerObj
{
   my $self = shift;
   return $self->{workloadsManager};
}


########################################################################
#
# SetWorkloadsManagerObj--
#     Method to set/initialize workloads manager object
#
# Input:
#     None
#
# Results:
#     SUCCESS, if workloads manager object is initialize successfully
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetWorkloadsManagerObj
{
   my $self = shift;
   my $workloadObj = VDNetLib::Workloads::WorkloadsManager->new(
                                             session => $self,
                                             testbed => $self->{testbed},
                                             logDir =>  $self->{logDir},
                                             testcase => $self->{testcaseHash}
                                             );
   if ($workloadObj eq FAILURE) {
      $vdLogger->Error("Failed to create Workloads object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{workloadsManager} = $workloadObj;
   return SUCCESS;
}


########################################################################
#
# Cleanup--
#     Method to do test session cleanup
#
# Input:
#     lastTest: boolean flag to indicate if this is a last test in
#               a session (Optional)
#
# Results:
#     SUCCESS, if the test session is cleaned up successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub Cleanup
{
   my $self = shift;
}


########################################################################
#
# End--
#     Method to close the test session
#
# Input:
#     None
#
# Results:
#     None
#
# Side effects:
#     All objects initialized during test session will not be
#     accessible
#
########################################################################

sub End
{
   my $self       = shift;
   my $testResult = shift || $self->{result};
   my $resultHash = {
      'pass'   => 'Pass',
      'fail'   => 'Fail',
      'skip'   => 'Skip',
      'abort'  => 'Abort',
   };
   my $method = $resultHash->{lc($testResult)};
   $vdLogger->$method("Test $self->{testName} $method" . "ed\n\n");
   my $process_logs = $self->{userInputHash}{options}{process_logs};
   if (defined $process_logs){
      $self->HtmlProcessLogs($process_logs);
   }
   # Fix PR 1435018, Racetrack report FAIL when FAILURE from the cleanup phase
   $vdLogger->End($resultHash->{lc($testResult)}, $self->{testLog});
   $vdLogger->Destroy();
}


########################################################################
#
# HtmlProcessLogs --
#     Method to process testcase log file to html format.
#
#    Please specify bellow lines in the deploy yaml file options
#    to let the testcase logs be with html link.
#
#        options:
#          process_logs:
#             html_conversion: 'true'                  #necessary
#             html_source: 'opengrok.eng.vmware.com'   #optional
#             html_published_dir: '/dbc/pa-dbc1123/haichaom' #optional
#
#
# Input:
#   - process_logs, it has three sub options:
#      html_conversion, Option to enable processing log file to html format.
#      html_source, Option to define the source file location which the error link jump to.
#                   The default value is opengrok.eng.vmware.com.
#                   If defined as 'local', the error link will jump to the cached
#                   html files in log directory.
#      html_published_dir, Option to specfiy the folder which the html files publish to.
#
# Results:
#     SUCCESS, if the method finished sucessfully.
#     FAILURE, in case of error.
#
# Side effects:
#     None
#
########################################################################

sub HtmlProcessLogs
{
   my $self = shift;
   my $process_logs = shift;
   if (defined $process_logs){
      my $html_conversion = $process_logs->{html_conversion};
      my $html_source = $process_logs->{html_source} || 'opengrok.eng.vmware.com';
      my $html_published_dir = $process_logs->{html_published_dir} || 'none';

      if ((defined $html_conversion) &&
          ($html_conversion eq VDNetLib::Common::GlobalConfig::TRUE ||
           lc($html_conversion) eq 'true')) {
         my $process_status = $vdLogger->ProcessHtmlLogs(
                                                         $html_source,
                                                         $html_published_dir
                                                        );
         if ($process_status eq SUCCESS) {
            $vdLogger->Info("Success to process log file : $self->{testLog}");
            return SUCCESS;
         } else {
            $vdLogger->Error("Failed to process log file : $self->{testLog}");
            return FAILURE;
         }
      } else {
         $vdLogger->Warn("html_conversion :". Dumper($html_conversion));
      }
   }
}


########################################################################
#
# GetMainSequence --
#     Method to get main sequence of the test
#
# Input:
#     None
#
# Results:
#     returns reference to array of array which indicates main sequence
#     order
#
# Side effects:
#     None
#
########################################################################

sub GetMainSequence
{
   my $self = shift;
   return $self->{testcaseHash}{WORKLOADS}{Sequence};
}


########################################################################
#
# GetExitSequence --
#     Method to get exit sequence of the test
#
# Input:
#     None
#
# Results:
#     returns reference to array of array which indicates exit sequence
#     order
#
# Side effects:
#     None
#
########################################################################

sub GetExitSequence
{
   my $self = shift;
   return $self->{testcaseHash}{WORKLOADS}{ExitSequence};
}


########################################################################
#
# GetWorkload --
#     Method to get given workload's hash
#
# Input:
#     None
#
# Results:
#     Reference to workload hash
#
# Side effects:
#     None
#
########################################################################

sub GetWorkload
{
   my $self = shift;
   my $workload = shift;
   return $self->{testcaseHash}{WORKLOADS}{$workload};
}


########################################################################
#
# SetInteractivePoint --
#     Method to set interactive point , passing undef will clear it.
#
# Input:
#     interactive point: 'onfailure' or specific workload name
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub SetInteractivePoint
{
   my $self = shift;
   my $interactivePoint = shift;

   if (defined $interactivePoint) {
      $vdLogger->Info("Setting interactive point as $interactivePoint");
   } else {
      $vdLogger->Info("Resetting interactive point");
   }
   $self->{interactive} = $interactivePoint;
}


1;
