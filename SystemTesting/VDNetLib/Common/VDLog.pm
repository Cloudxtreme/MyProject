########################################################################
# Copyright (C) 2010 VMware, Inc.
# All Rights Reserved.
########################################################################

package VDNetLib::Common::VDLog;

########################################################################
#
# new            - Constructor
# SetLogLevel    -
# GetLogLevel    -
# GetLogFileName -
# Log            -
# Fatal          -
# Error          -
# Warn           -
# Info           -
# Debug          -
# Trace          -
# Pass           -
# Fail           -
# Abort          -
# Skip           -
# DESTROY        - Destructor
#
########################################################################


use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use IO::Handle;
use Sys::Hostname;
use VDNetLib::Common::Racetrack;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS);
use Fcntl qw(:flock);
BEGIN {
    use Exporter();
    our (@ISA, @EXPORT, @EXPORT_OK,);
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(@levelStr);
};

use constant PASS  => 0; # Log to indicate Pass conditions
use constant FAIL  => 1; # Log to indicate Fail scenarios
use constant ABORT => 2; # Log to indicate aborting a process/test
use constant SKIP  => 3; # Log to indicate skipping 1 or many tasks/tests in
                         # a given set of tasks/tests

use constant FATAL => 4; # Log to indicate to most serious (negative)
                         # conditions
use constant ERROR => 5; # Log to indicate errors from functions calls, script
                         # execution etc.
use constant WARN  => 6; # Log to specifying warnings
use constant INFO  => 7; # Log to indicate useful information along different
                         # stages of a process execution
use constant DEBUG => 8; # Log to specify in depth values/results while
                         # executing a process/test, scripts, routines etc
use constant TRACE => 9; # Log to indicate very large and in depth details
                         # about a process/test, variables, routines, etc.

use constant LEVEL_MASK_MIN     => TRACE;
use constant LEVEL_MASK_MAX     => FATAL;
use constant LEVEL_MASK_DEFAULT => TRACE;
use constant LEVEL_MIN          => PASS;
use constant LEVEL_MAX          => TRACE;

use constant TRUE => 1;
use constant FALSE => 0;

# gzip the log file once its size exceeds the value
use constant THRESHOLD_FOR_COMPRESS => 1024 * 1024 * 100;

# Global variables.
our @levelStr = ("PASS", "FAIL", "ABORT", "SKIP", "FATAL", "ERROR", "WARN",
                "INFO", "DEBUG", "TRACE");

########################################################################
# new --
#      This is method to create an instance/object of
#      VDNetLib::Common::VDLog class
#
# Input:
#      A hash containing following keys:
#      'logLevel' - it can take one value between 0 and 9
#                   0 - PASS
#                   1 - FAIL
#                   2 - ABORT
#                   3 - SKIP
#                   4 - FATAL
#                   5 - ERROR
#                   6 - WARN
#                   7 - INFO
#                   8 - DEBUG
#                   9 - TRACE
#                   By specifying a loglevel all log messages less than
#                   or equal log level will be printed on console.
#                   Irrespective of loglevel all log information will be
#                   written to a file if 'logToFile' option is set to 1.
#      'logFileLevel' - Its value is similar with logLevel. It controls
#                       level of logs that can be saved into log file
#      'logToFile' - takes value 1 or 0; which indicates whether to
#                    send the logs to a file or not
#      'logFileName' - filename to which all logs should be written. If
#                      no filename is specified, then a file will be
#                      created automatically
#      'verbose'   - 1 or 0 to enable/disable the following information
#                    being printed on the console:
#                    date, time, hostname, package name, line number
#      'rtrackObj'   - instance of VDNetLib::Common::Racetrack
#      'rtrackInfo'  - A reference to a hash containing the following
#                      keys (OPTIONAL). If this hash reference is specified
#                      then results are logged to racetrack.
#                          'server'    -  racetrack server
#                          'user'      -  racetrack user
#                          'buildId'   -  build number being tested
#                          'product'   -  product being tested
#                          'hostOs'    -  host being tested
#                          'buildType' -  build type being tested (OPTIONAL)
#                          'branch'    -  branch being tested (OPTIONAL)
#                          'desc'      -  description for the test run
#
# Results:
#      A VDNetLib::Common::VDLog object is returned
#
# Side effects:
#      A new file is created if 'logToFile' option is set to 1 and
#      no value is provided for 'logFileName'
#
########################################################################

sub new
{
   my $class       = shift;
   my %options     = @_;
   my $logFileName = undef;
   my $self;

   $self = {
      logLevel    => LEVEL_MASK_MIN,
      logFileLevel  => DEBUG,
      logFileName => undef,
      verbose     => FALSE,
      rtrackObj   => $options{rtrackObj} || undef,
      rtrackBegin => FALSE,
      logToConsole => TRUE,
      glob         => $options{glob},
   };

   bless ($self, $class);

   if (defined($options{logLevel})) {
      $self->SetLogLevel($options{logLevel});
   } else {
      #
      # If logLevel is not passed, set it to default logLevel(LEVEL_MASK_MIN).
      # so that all messages can be logged.
      #
      $self->{logLevel} = LEVEL_MASK_MIN;
   }
   if (defined($options{logFileLevel})) {
      $self->{logFileLevel} = $options{logFileLevel};
   }

   # Forces a flush after every write to the STDOUT.
   use IO::Select;
   select->autoflush(1);
   local $| = 1;

   if (defined($options{logToFile}) && $options{logToFile} == TRUE) {
      if (defined($options{logFileName})) {
         $logFileName = $options{logFileName};
      }
      $logFileName = $self->SetLogFileName($logFileName);
      if (!defined($logFileName)) {
         $self->{fileHandle} = undef;
         return undef;
      }
      $self->{logFileName} = $logFileName;
      $self->{logDir} = $self->SetLogDir();
   }
   if (defined($options{verbose}) && $options{verbose} == TRUE) {
      $self->{verbose} = TRUE;
   }

   if (defined($options{logToConsole}) && $options{logToConsole} == FALSE) {
      $self->{logToConsole} = FALSE;
   }
   return $self;
}



########################################################################
#
# SetRacetrack --
#       Create racetrack object if the user has specified in yaml file
#
# Input:
#       $racetrack - racetrack info given by user in yaml file
#
# Results:
#       None.
#
# Side effects:
#       None
#
########################################################################

sub SetRacetrack
{
   my $self = shift;
   my $racetrack = shift;
   my $desc = shift || "";

   my $rtrackInfo;
   my ($user, $server);
   ($user,$server) = split(/@/,$racetrack);
   if (not defined $user || not defined $server) {
      print STDERR "$0: Invalid options" .
                   "$0: $VDNetLib::Common::VDNetUsage::usage";
      DoCleanUPAndExit("FAIL", undef, undef);
   }

   $rtrackInfo->{'server'}    = $server;
   $rtrackInfo->{'user'}      = $user;
   $rtrackInfo->{'buildId'}   = "00000";
   $rtrackInfo->{'product'}   = "ESX";
   $rtrackInfo->{'hostOs'}    = "ESX";
   $rtrackInfo->{'branch'}    = undef;
   $rtrackInfo->{'buildType'} = undef;
   $rtrackInfo->{'desc'}      = "vdNet Test $desc";

   $self->{rtrackObj} = VDNetLib::Common::Racetrack->new(
                              $rtrackInfo->{'server'},
                              $rtrackInfo->{'user'},
                              $rtrackInfo->{'buildId'},
                              $rtrackInfo->{'product'},
                              $rtrackInfo->{'hostOs'},
                              $rtrackInfo->{'desc'},
                              $rtrackInfo->{'buildType'},
                              $rtrackInfo->{'branch'});
   if (not defined $self->{rtrackObj}) {
      print STDERR "\nFailed to create \"Racetrack\" object";
      return FAILURE;
   }
   if(not defined $self->{rtrackObj}->TestSetBegin()) {
      undef $self->{rtrackObj};
      print STDERR "\nFailed to connect to the given racetrack server. " .
                      "Please check if the racetrack server is up and running. ";
      return FAILURE;
   }
   $self->{'rtrackInfo'} = $rtrackInfo;
   $self->{'rtrackID'} = undef;
   return SUCCESS;
}


########################################################################
#
# SetLogLevel --
#       Specifies the lowest-severity log message a logger will handle,
#       where TRACE is the lowest severity level and FATAL is the highest
#       severity. For example, if the severity level is INFO, the logger
#       will handle only INFO, WARNING, ERROR and FATAL messages, and
#       will ignore DEBUG and TRACE messages.
#
# Input:
#       Log Level.
#
# Results:
#       None.
#
# Side effects:
#       Logging messages which are less severe than $logLevel will be
#       ignored by the logger function.
#
########################################################################

sub SetLogLevel
{
   my $self  = shift;
   my $level = shift;

   #TODO: we need to print msg to console when called more than once.
   if (defined($level)) {
      if ($level <= LEVEL_MASK_MIN && $level >= LEVEL_MASK_MAX) {
         $self->{logLevel} = $level;
      } else {
         $self->{logLevel} = LEVEL_MASK_MIN;
      }
   }
}


########################################################################
#
# SetLogFileName --
#       Sets file name for logging. If file name is not given, this
#       function creates an unique filename based on timestamp.
#
# Input:
#       $logFileName - file name for logging. (optional)
#
# Results:
#       Returns file name.
#
# Side effects:
#       If the given filename already exists, content of the file will be
#       truncated.
#
########################################################################

sub SetLogFileName
{
   my $self        = shift;
   my $logFileName = shift;
   my $dateTime;
   my $seconds;
   my $milliSeconds;
   my $microSeconds;
   my $tmp;

   if (not defined($logFileName)) {
      $dateTime = [(localtime(time()))[0..5]];
      $dateTime->[4]++;        # Months go from 0-11
      $dateTime->[5] += 1900;  # Years start at 1900
      ($seconds, $microSeconds) = gettimeofday;
       $tmp = sprintf("%04d-%02d-%02d-%02d:%02d:%02d", reverse @$dateTime);
       $milliSeconds = sprintf(":%03d", $microSeconds/1000);
       $logFileName = "vdLog-" . "$tmp" . "$milliSeconds";
   }
   if (-f $logFileName) {
      if (!unlink($logFileName)) {
         $self->Warn("vdLog: Unable to delete the file: $logFileName, ".
                     "reason: $!\n");
         return undef;
      }
   }
   if (not defined $self->{glob}) {
      $self->{fileHandle} = open(FH, ">$logFileName") ? *FH : undef;
   } else {
      $self->{fileHandle} = open($self->{glob}, ">$logFileName") ?
                                 $self->{glob} : undef;
   }

   if (not defined $self->{fileHandle}) {
      #
      # $self->{fileHandle} will be set even if the open fails.
      # Do undef fileHandle Before calling Warn().
      #
      $self->{fileHandle} = undef;
      $self->Warn("vdLog: Unable to open log file $logFileName for writing: ".
                  "$!\n");
      return undef;
   }
   # Forces a flush right away and after every write.
   $self->{fileHandle}->autoflush(1);

   close(STDERR);
   open(STDERR, '>', "$logFileName-stderr");
   return $logFileName;
}


########################################################################
#
# GetLevelName --
#       Returns level name for the given level.
#
# Input:
#       Level.
#
# Returns:
#       Level name.
#
# Side effects:
#       None.
#
########################################################################

sub GetLevelName($)
{
   my $level = shift;

   if (defined($level) && $level >= LEVEL_MIN && $level <= LEVEL_MAX) {
      return $levelStr[$level];
   } else {
      return "";
   }
}


########################################################################
#
# PrintDateTime --
#       Prints Date and Time in ISO 8601 format.
#
# Input:
#       None.
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub PrintDateTime
{
   my $self = shift;
   my $fileHandle = shift || undef;
   my $dateTime;
   my $seconds;
   my $microSeconds;

   $dateTime = [(localtime(time()))[0..5]];
   $dateTime->[4]++;        # Months go from 0-11
   $dateTime->[5] += 1900;  # Years start at 1900
   ($seconds, $microSeconds) = gettimeofday;
   if (defined($fileHandle)) {
      printf {$fileHandle} ("%04d-%02d-%02d %02d:%02d:%02d",
                            reverse @$dateTime);
      printf {$fileHandle} (".%03d - ", $microSeconds/1000);
   } else {
      printf ("%04d-%02d-%02d %02d:%02d:%02d", reverse @$dateTime);
      printf (".%03d - ", $microSeconds/1000);
   }
}


########################################################################
#
# LogCommon --
#       Log to console screen, and to file if set.
#       if logLevel is not set,
#
# Input:
#       $level - level of the message.
#       $message - Message to log. (optional)
#       $args = Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub LogCommon
{
   my $self    = shift;
   my $level   = shift;
   my $message = shift;
   my @args    = @_;
   my $fileHandle = $self->{fileHandle};
   my ($package, $fileName, $lineNum) = caller(1);
   #
   # VDLog object can be used by many child processes under a parent process.
   # In such, all the processes would access the console/file at same time. To
   # prevent race and garbled data being printed, the console/file is locked
   # during write operation.
   #
   flock(STDOUT, LOCK_EX) if ($self->{logToConsole});
   flock($fileHandle, LOCK_EX) if (defined $fileHandle);
   my $processID = '[' . $$ . ']';
   my $codeInfo = "[\@$package:$lineNum]";
   if (!defined($level) || ($level !~ /^-?\d/)) {
      if (defined($fileHandle)) {
         $self->PrintDateTime($fileHandle);
         printf {$fileHandle} ("%-7s", sprintf("[%s]", GetLevelName(WARN)));
         printf {$fileHandle} (" - ");
         printf {$fileHandle} ("$codeInfo $processID");
         printf {$fileHandle} (" log level is not passed.\n");
      }
      # WARN level is printed to the console irrespective of the logLevel.
      $self->PrintDateTime();
      printf ("%-7s", sprintf("[%s]", GetLevelName(WARN)));
      printf (" - log level is not passed.\n");
      flock($fileHandle, LOCK_UN) if defined ($fileHandle);
      flock(STDOUT, LOCK_UN) if ($self->{logToConsole});
      return;
   }

   if ($level < LEVEL_MIN || $level > LEVEL_MAX) {
      if (defined($fileHandle)) {
         $self->PrintDateTime($fileHandle);
         printf {$fileHandle} ("%-7s", sprintf("[%s]", GetLevelName(WARN)));
         printf {$fileHandle} (" - ");
         printf {$fileHandle} ("$codeInfo $processID");
         printf {$fileHandle} (" Invalid log level (%d).\n", $level);
      }
      $self->PrintDateTime();
      printf ("%-7s", sprintf("[%s]", GetLevelName(WARN)));
      printf (" - Invalid log level (%d).\n", $level);
      flock($fileHandle, LOCK_UN) if defined ($fileHandle);
      flock(STDOUT, LOCK_UN) if ($self->{logToConsole});
      return;
   }

   # If logLevel is not set, set it to LEVEL_MASK_DEFAULT.
   if (not defined($self->{logLevel})) {
      $self->{logLevel} = LEVEL_MASK_DEFAULT;
   }

   # Log everything to file based on logFileLevel.
   if (defined($fileHandle) && ($level <= $self->{logFileLevel})) {
      $self->PrintDateTime($fileHandle);
      printf {$fileHandle} ("%-7s", sprintf("[%s]", GetLevelName($level)));
      printf {$fileHandle} (" - ");
      printf {$fileHandle} ("$codeInfo $processID");
      if (defined($message)) {
         printf {$fileHandle} " ";
         if (@args != 0) {
            printf {$fileHandle} (sprintf($message, @args));
         } else {
            print $fileHandle ($message);
         }
      }
      if (!defined($message) || !($message =~ /\n$/)) {
         print $fileHandle ("\n");
      }
   }
   # Log to console based on level mask.
   if ($level <= $self->{logLevel}) {
      if ($self->{logToConsole}) {
         $self->PrintDateTime();
      }

      my $logStr = sprintf ("%-7s", sprintf("[%s]", GetLevelName($level)));

      if ($self->{verbose}) {
         $logStr = $logStr . " - $codeInfo $processID";
      }
      if (defined($message)) {
         $logStr = $logStr . " - ";
         if (@args != 0) {
            $logStr = $logStr . sprintf($message, @args);
         } else {
            $logStr = $logStr . $message;
         }
         if ($self->{logToConsole}) {
            print $logStr;
         }

         eval {
             ## If racetrack is enabled log to racetrack
             if (defined $self->{rtrackObj} && TRUE == $self->{rtrackBegin}) {
                 $self->{rtrackObj}->TestCaseComment($logStr, $self->{rtrackID});
             }
         };
         if ($@) {
             $self->LogCommon(WARN, 'Failed to add log to racetrack', @_);
         }
      }
      if (!defined($message) || !($message =~ /\n$/)) {
         if ($self->{logToConsole}) {
            print ("\n");
         }
      }
   }
   flock($fileHandle, LOCK_UN) if defined ($fileHandle);
   flock(STDOUT, LOCK_UN) if ($self->{logToConsole});
}


########################################################################
#
# GetLogLevel --
#       Returns current log level.
#
# Input:
#       None.
#
# Returns:
#       log level.
#
# Side effects:
#       None.
#
########################################################################

sub GetLogLevel
{
   my $self = shift;

   return $self->{logLevel};
}


########################################################################
#
# GetLogFileName --
#       Returns logFileName.
#
# Input:
#       None.
#
# Results:
#       Name of the file if the logger is configured to use file,
#       Otherwise undef.
#
# Side effects:
#       None.
#
########################################################################

sub GetLogFileName
{
   my $self = shift;

   return $self->{logFileName};
}


########################################################################
#
# Log --
#       Log a message with the given level.
#
# Input:
#       $level - message level. (required)
#                level should be one of the predefined one.
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Log
{
   my $self = shift;

   $self->LogCommon(@_);
}


########################################################################
#
# Fatal --
#       Log a message with FATAL log level.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Fatal
{
   my $self = shift;

   $self->LogCommon(FATAL, @_);
}


########################################################################
#
# Error --
#       Log a message with ERROR log level.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Error
{
   my $self = shift;

   $self->LogCommon(ERROR, @_);
   #
   # Copy contents of stderr to logfile for better
   # debugging. If this method (Error) is not called, but
   # still there were stderr, then the content of $stdErrLog
   # will still be available.
   # Given that Error() is called mostly on bad conditions,
   # any performance hit on this check should be tolerable.
   #
   #
   if (defined $self->{logFileName}) {
      my $stdErrLog = $self->{logFileName} . "-stderr";
      # if the file is of non-zero size, indicate about stderr captured
      if (-s $stdErrLog) {
         $self->LogCommon(ERROR, "Detected STDERR on $stdErrLog");
      }
   }
}


########################################################################
#
# Warn --
#       Log a message with WARNING log level.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Warn
{
   my $self = shift;

   $self->LogCommon(WARN, @_);
}


########################################################################
#
# Info --
#       Log a message with INFO log level.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Info
{
   my $self = shift;

   $self->LogCommon(INFO, @_);
}


########################################################################
#
# Debug --
#       Log a message with DEBUG log level.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Debug
{
   my $self = shift;

   $self->LogCommon(DEBUG, @_);
}


########################################################################
#
# Trace --
#       Log a message with TRACE log level.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Trace
{
   my $self = shift;

   $self->LogCommon(TRACE, @_);
}


########################################################################
#
# Pass --
#       Log status PASS, with a message if given.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Pass
{
   my $self = shift;

   $self->LogCommon(PASS, @_);
}

########################################################################
#
# Fail --
#       Log status FAIL, with a message if given.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Fail
{
   my $self = shift;

   $self->LogCommon(FAIL, @_);
}


########################################################################
#
# Abort --
#       Log status ABORT, with a message if given.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Abort
{
   my $self = shift;

   $self->LogCommon(ABORT, @_);
}


########################################################################
#
# Skip --
#       Log status SKIP, with a message if given.
#
# Input:
#       $message - Message to log (optional)
#       $args - Parameters to substitute (optional)
#
# Results:
#       None.
#
# Side effects:
#       None.
#
########################################################################

sub Skip
{
   my $self = shift;

   $self->LogCommon(SKIP, @_);
}


########################################################################
#
# Start --
#     Initializes the racetrack testcase for this test
#
# Input:
#       $testName - test case name
#       $feature - feature being tested
#       $desc  -  test case description
#       $host  -  the host being tested
#
# Results:
#       0 if the racetrack test case was initialized.
#       2 if a test case was already initialized (but not closed)
#       1 if initializing athe test case failed
#
# Side effects:
#       None.
#
########################################################################

sub Start
{
   my $self = shift;
   my $testName = shift;
   my $feature = shift;
   my $desc = shift;
   my $host = shift;

   if ((not defined $testName) || (not defined $feature) ||
       (not defined $desc) || (not defined $host)) {
      return FAIL;
   }

   if (TRUE == $self->{rtrackBegin}) {
      return 2;
   }

   if ((not defined $self->{rtrackObj}) ||
       (not defined $self->{rtrackObj}->TestCaseBegin($testName, $feature,
                                                      $desc, $host))) {
      return 1;
   }

   $self->{'rtrackID'} = $self->{rtrackObj}->GetTestCaseId();
   $self->{rtrackBegin} = TRUE;
   return 0;
}


########################################################################
#
# End --
#     Closes the racetrack testcase session for this test
#
# Input:
#     status - The status of the test case
#
# Results:
#       0 if the racetrack test case was closed.
#       2 if there is no open test case session to close
#       1 if closing the test case session failed
#
# Side effects:
#       None.
#
########################################################################

sub End
{
   my $self    = shift;
   my $status  = shift;
   my $logFile = shift || undef;
   my $testcaseID = $self->{'rtrackID'};

   if (not defined $status) {
      return FAIL;
   }

   if (defined $self->{rtrackObj}) {
      if (not defined $self->RaceTrackFileUpload($testcaseID, undef,
                                                 $logFile)) {
         return 1;
      }
   }

   if (TRUE != $self->{rtrackBegin}) {
      return 2;
   }

   if (not defined $self->{rtrackObj}->TestCaseEnd($status, $testcaseID)) {
      return 1;
   }

   $self->{rtrackBegin} = FALSE;
   return 0;
}

########################################################################
#
# ProcessHtmlLogs --
#    Method to process the testcase log file to html format.
#
# Input:
#    html_source - The source file location the error link jumps to.
#    html_published_dir - The folder which the html files publish to.
#
# Results:
#    SUCCESS - if the log process is finished with no error.
#    FAILURE - in case of any error.
#
# Side effects:
#    None.
#
########################################################################

sub ProcessHtmlLogs
{
   my $self     = shift;
   my $html_source = shift;
   my $html_published_dir = shift;

   my $logPath  = $self->GetLogFileName();
   my $codePath = "$FindBin::Bin/../";
   my $cmd = "python $codePath" .
             "scripts/vdnet_log_tool/vdnet_log_tool.py " .
             "--log_path $logPath " .
             "--code_path $codePath " .
             "--html_source $html_source " .
             "--html_published_dir $html_published_dir " .
             "2>&1";
   $self->Debug("Running command: $cmd");
   my $result = `$cmd`;
   my @chunks = split /^/, $result;
   if ($? != 0) {
      $self->Error("Process testcase log failed with error:\n");
      foreach (@chunks) {
         $self->Error("%s", $_);
      }
      return FAILURE;
   } else{
      $self->Info("Process testcase log finished with:\n");
      foreach (@chunks) {
         $self->Info("%s", $_);
      }
      return SUCCESS;
   }
}

########################################################################
#
# GetRacetrackId --
#     Returns the racetrack session ID.
#
# Input:
#
# Results:
#     the test set ID of the racetrack object
#     undef on any error
#
# Side effects:
#       None.
#
########################################################################

sub GetRacetrackId
{
   my $self = shift;

   if (not defined $self->{rtrackObj}) {
      return undef;
   }

   return $self->{rtrackObj}->GetTestSetId();
}


########################################################################
#
# SetRacetrackBuildInfo --
#     Set racetrack - buildID,ESX branch, buildType.
#
# Input:
#    hostOS, buildID, esxBranch, buildType
#
# Results:
#     1 if success,undef on any error
#
# Side effects:
#       None.
#
########################################################################

sub SetRacetrackBuildInfo
{
   my $self = shift;
   my $buildID = shift;
   my $esxBranch = shift;
   my $buildType = shift;

   if ( not defined $buildID || not defined $esxBranch
       || not defined $buildType) {
      return undef;
   }

   if (not defined  $self->{rtrackObj}->TestSetUpdateBuild($buildID,
                                                 $esxBranch, $buildType)){
     return undef;
   }
   return 1;
}


########################################################################
#
# SetRacetrackHostOS --
#     Set racetrack - HostOS.
#
# Input:
#    hostOS
#
# Results:
#     1 if success,undef on any error
#
# Side effects:
#       None.
#
########################################################################

sub SetRacetrackHostOS
{
   my $self = shift;
   my $hostOS = shift;

   if ( not defined $hostOS) {
      return undef;
   }

   if (not defined  $self->{rtrackObj}->TestSetUpdateHostOS($hostOS)){
     return undef;
   }
   return 1;
}


########################################################################
#
# RaceTrackFileUpload --
#     Copies file (usually log file) to the racetrack session.
#
# Input:
#     fileName : name of the file that needs to be uploaded
#
# Results:
#     1 on success, undef on any error
#
# Side effects:
#     None.
#
########################################################################

sub RaceTrackFileUpload
{
   my $self     = shift;
   my $testId   = shift;
   my $desc     = shift;
   my $fileName = shift;

   if (not defined $fileName) {
      return undef;
   }
   # gzip the huge log file if any. HTTP::Request::Common::POST will run into
   # 'out of memory' when the size of log file exceeds ~400M while perl can not
   # handle this kind of exception. It causes vdnet bailing out.
   my $filesize = -s $fileName;
   if (defined $filesize && $filesize > THRESHOLD_FOR_COMPRESS) {
      $self->Debug("VDNet is doing gzip as the file size($filesize) is huge");
      my $newFileName = "$fileName.gz";
      system("gzip -c $fileName > $newFileName");
      if ( -e $newFileName) {
         $fileName = $newFileName;
      } else {
         $self->Warn("Unable to do gzip $fileName");
         return undef;
      }
   }
   my @request = [ ResultID => $testId,
                   Description => $desc,
                   Log => [$fileName]];
   my $result = $self->{rtrackObj}->SendRequest("TestCaseLog.php", @request);
   return 1;
}


########################################################################
#
# DESTROY --
#
# Input:
#
# Results:
#
# Side effects:
#
########################################################################

sub Destroy
{
   my $self = shift;

   if (defined($self->{fileHandle})) {
      close($self->{fileHandle});
      $self->{fileHandle} = undef;
   }

   if (defined $self->{rtrackObj}) {
      $self->{rtrackObj}->TestSetEnd();
   }
}


########################################################################
#
# SetLogDir --
#      Method to set the attribute logDir to complete path of
#      the testcase folder
#
# Input:
#      None
#
# Results:
#      Return the complete path of the testcase folder
#
# Side effects:
#
########################################################################

sub SetLogDir
{
   my $self = shift;

   my $testcasePath = $self->{'logFileName'};
   my @arrayForPath = split('\/', $testcasePath);
   # Deleting the last element testcase.log
   pop @arrayForPath;
   my $parentFolder = join('/', @arrayForPath);
   $parentFolder = $parentFolder . '/';
   return $parentFolder;
}


########################################################################
#
# GetLogDir --
#      Method to return the attribute logDir
#
# Input:
#      None
#
# Results:
#      Return the attribute logDir, i.e. complete path of the testcase folder
#
# Side effects:
#
########################################################################

sub GetLogDir
{
   my $self = shift;
   return $self->{logDir};
}


########################################################################
#
# CheckLogLevel --
#      Method to check log level is valid string or not.
#
# Input:
#      logLevel: Level string
#
# Results:
#      Return "FAILURE" if log level is invalid. Or else return the index in
#      levelStr.
#
# Side effects:
#      None.
#
########################################################################

sub CheckLogLevel
{
   my $logLevel = shift;

   if (not defined $logLevel) {
      return FAILURE;
   }
   if (not grep {uc($logLevel) eq ($_)} @levelStr) {
         return FAILURE;
   }
   ($logLevel) = grep { $levelStr[$_] eq
         uc($logLevel)} 0..$#levelStr;
   return $logLevel;
}

1;
