###############################################################################
#  Copyright (C) 2011 VMware, Inc.                                            #
#  All Rights Reserved                                                        #
###############################################################################

package VDNetLib::Common::STAFHelper;

use strict;
use warnings;
no warnings 'redefine'; # TODO - windows throws redefine warnings when loading
                        # this package from exit14 (from other nfs server,
                        # it works fine), fix it.
use Time::HiRes qw(gettimeofday);
use PLSTAF;
use Data::Dumper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDLog;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort
                                      $STAF_DEFAULT_PORT
                                      $STAF_STATIC_HANDLE
                                      $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE
                                         SUCCESS VDCleanErrorStack);

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/";

use base 'Exporter';
our @EXPORT    = qw(@stafTrash);
@VDNetLib::Common::STAFHelper::ISA = qw(Exporter);

use constant DEFAULT_PROCESS_WAIT_TIME => 300;
use constant DEFAULT_STAF_WAIT_TIME => 300;
# The below contant is used in WaitForSTAF routine
# it is max wait time after which we timeout. Hitting
# timeout could mean, staf was unable to restart,
# or machine hung or it took more than this default time
# to come up.
use constant MAX_DEFAULT_WAITTIME_FOR_STAFTOCOMEUP => 600;
use constant DEFAULT_SLEEP_BETWEEN_PROCESS => 20;
use constant TRUE => 1;
use constant FALSE => 0;

use constant VMFS_BLOCK_SIZE =>  1048576;
our @stafTrash;
my $globalHandle = undef;

########################################################################
#
# new --
#      Entry point to create an object of this class STAFHelper
#
# Input:
#      A hash with following key:
#      'logObj' - VDLog object for logging # Required
#      TODO: pass old staf handle also
#
# Results:
#      A STAFHelper object if successful,
#      undef in case of any script error
#
# Side effects:
#      None
#
# Example:
#      my $options;
#      $options->{logObj} = $vdLogObj;
#      $stafHelperObj =
#         VDNetLib::Common::STAFHelper->new($options)
#
########################################################################

sub new
{
   my $class   = shift;
   my $options = shift;
   my $self;
   my $handleName;
   if (!defined($options->{logObj})) {
      return undef;
   }
   # Any attributes of this class should be declared here
   $self = {
      handle => undef,
      logObj => $options->{logObj}, # stores the VDLog object
      tcpport => $sessionSTAFPort,
   };
   $handleName = VDNetLib::Common::Utilities::GetDateTime();
   if (defined $STAF_STATIC_HANDLE) {
      $self->{handle} = $STAF_STATIC_HANDLE;
   } else {
      $self->{handle} = STAF::STAFHandle->new($handleName);
      $self->{tcpport} = (defined  $self->{tcpport}) ? $self->{tcpport} : 6500;
      if ($self->{handle}->{rc} != $STAF::kOk) {
         $self->{logObj}->Error("Unable to create STAF handle:" .
                                $self->{handle}->{rc});
         return undef;
      }
      $STAF_STATIC_HANDLE = $self->{handle};
   }
   $self->{_handle}=$self->{handle};
   push(@stafTrash, $self);
   bless ($self, $class);
   return $self;
}


########################################################################
#
# STAFProcess --
#      Launches a process on remote host using the STAF process service.
#      The process is executed synchronously or asynchronously
#      depending on the user input. Default is synchronuous.
#
# Input:
#      1) host: host ip/name of the host on which the command
#               needs to be executed.
#      2) command: The command to be executed
#      3) processType: SYNC or ASYNC for synchronous/asynchronous
#                      operation
#      4) opts:  A hash with any optional parameters of the
#                PROCESS service. In addition, following key
#                is supported (optional):
#                'NoShell' - To execute command without shell
#
# Results:
#      Returns a result hash with following keys:
#      'rc': 0 if command executed successfully, positive integer which
#            represents staf rc in case of staf error, -1 in case of any
#            other error
#      if $processType is ASYNC:
#      'handle': process handle if 'rc' is 0, otherwise undef
#
#      if $processType is SYNC:
#      'exitCode': return code from the process executed
#      'stdout': stdout from the process/command executed
#      'stderr': stderr from the process/command executed
#
# Side effects:
#      Depends on what the command does.
#
# Example:
#      my $opts;
#      my $command = "ping 10.20.84.51";
#      my $opts->{ENV} = "PATH = $PATH:/automation/bin";
#      $result = VDNetLib::Common::STAFHelper->STAFProcess($host,
#                                                          $command,
#                                                          "ASYNC",
#                                                          $opts)
#
########################################################################

sub STAFProcess
{
   my $self        = shift;
   my $host        = shift;
   my $command     = shift;
   my $processType = shift || "";
   my $opts        = shift || undef;

   my $mcRootObject;
   my $stafResult;
   my $submitCmd;
   my $result = undef;
   my $mc;
   $result->{rc}     = -1;

   if (not defined $host || not defined $command) {
      $self->{logObj}->Error("One or more parameters not supplied");
      $result->{rc} = -1;
      return $result;
   }

   $command = STAF::WrapData($command);

   #
   # Sometimes it preferred to run asynchronuous process without shell
   # especially on windows since the handle returned would referring to cmd.exe
   # process through which the actual command gets executed. In such running
   # with NoShell option would start the process directly and return the
   # process handle/id corresponding to the command executed.
   #
   if ($opts->{noshell}) {
      $self->{logObj}->Debug("Starting process without shell");
      $submitCmd = "START COMMAND $command";
      delete $opts->{NoShell};
   } else {
      $submitCmd = "START SHELL COMMAND $command";
   }

   if ($processType =~ /async/i) {
      $submitCmd = $submitCmd . " ASYNC NOTIFY ONEND";
   }

   if (!$opts or ($opts and !$opts->{stdout})) {
      $submitCmd .= " RETURNSTDOUT RETURNSTDERR";
   }

   #
   # Optional parameters like ENV, WORKLOAD, STDIN, STDOUT etc
   # can be concatenated with the actual command. It is user responsibility to
   # use the parameters supported by PROCESS service.
   #
   # Delete keys in the hash $opts that are hard-coded in this method
   for my $key (keys %$opts) {
      if ($opts && ($key =~ /Noshell|command|async|notify onend/i)) {
         delete $opts->{"$key"};
      } else {
         $submitCmd .= " $key ". $opts->{$key};
      }
   }

   $self->{logObj}->Debug("Executing command: $submitCmd on $host");
   $stafResult = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
			$host, "PROCESS", $submitCmd);
   $result->{rc} = $stafResult->{rc};
   if ($stafResult->{rc} != $STAF::kOk) {
      if ($processType =~ /async/i) {
         $result->{handle} = $stafResult->{result};
      } else {
         $result->{stderr} = $stafResult->{result};
      }
      return $result;
   }

   if ($processType =~ /async/i) {
      $result->{handle} = $stafResult->{result};
      return $result;
   }

   # Get STDOUT and STDERR if the processType is SYNC
   $mc = STAF::STAFUnmarshall($stafResult->{result});
   $mcRootObject = $mc->getRootObject();

   $vdLogger->Info("The rc ifno: $stafResult->{rc}");
   #while(my($k,$v)=each(%$stafResult)){print"staf result $k--->$v\n";}
   #my $context = $stafResult->{'resultContext'};
   #while(my($k,$v)=each(%$context)){print "resultcontext $k--->$v\n"}
   #while(my($k,$v)=each(%$mc)){print"mc $k--->$v\n";}
   #while(my($k,$v)=each(%$mcRootObject)){print"rootobj $k--->$v\n";}


   $result->{rc}       = $stafResult->{rc};
   $result->{exitCode} = $mcRootObject->{rc};
   $result->{stdout}   = $mcRootObject->{fileList}[0]{data};
   $result->{stderr}   = $mcRootObject->{fileList}[1]{data};

   return $result;
}


########################################################################
#
# ExamineSTAFResult --
#      Method examines the result of an operation done via STAFSyncProcess
#      and logs the failure based on expectation of the user.
#
# Input:
#      retHash: Result returned by STAFSyncProcess method.
#      command: Command that was executed by STAF.
#      logLevel: Determine how the failure should be reported. Default is Error
#          level logging.
#      expectedRC: Expected return code from STAF command as a list. Defaults
#          to (0).
#      expectedExitCode: Expected exit code of the executed command. Defaults
#          to (0).
#
# Results:
#     FAILURE when failure happens
#     SUCCESS otherwise.
#
# Side effects:
#     None
#
########################################################################

sub ExamineSTAFResult
{
   my $self = shift;
   my $ret = shift;
   my $command = shift;
   my $logLevel = shift;
   my $expectedRC = shift;
   my $expectedExitCode = shift;
   if (not defined $logLevel) {
       $logLevel = 'Error';
   }
   if (not defined $expectedRC) {
      @$expectedRC = (0);
   }
   if (not defined $expectedExitCode) {
      @$expectedExitCode = (0);
   }
   if (ref($expectedRC) ne 'ARRAY' ||
       grep {$_ !~ /[0-9]+/} @$expectedRC) {
      $vdLogger->Error("Can only accept list of numeric expected return codes, got:" .
                      Dumper($expectedRC));
      VDSetLastError("ERUNTIME");
      return FAILURE;
   } else {
      @$expectedRC = map (int, @$expectedRC);
   }
   if (ref($expectedExitCode) ne 'ARRAY' ||
       grep {$_ !~ /[0-9]+/} @$expectedExitCode) {
      $vdLogger->Error("Can only accept list of numeric expected exit codes, got: " .
                       Dumper($expectedExitCode));
      VDSetLastError("ERUNTIME");
      return FAILURE;
   } else {
      @$expectedExitCode = map (int, @$expectedExitCode);
   }
   my $failed = 0;

   if (not grep {$logLevel eq ucfirst(lc($_))} @VDNetLib::Common::VDLog::levelStr) {
       $vdLogger->Error("Unexpected log level: $logLevel. Only following " .
                        "levels are supported: " .
                        Dumper(\@VDNetLib::Common::VDLog::levelStr));
       VDSetLastError("ERUNTIME");
       return FAILURE;
   }
   if ((defined $ret->{rc} && $ret->{rc}) || (defined $ret->{exitCode} && $ret->{exitCode})) {
       if (defined $ret->{rc}) {
            if ($ret->{rc}) {
                $vdLogger->Warn("STAF command \"$command\" failed due to STAF " .
                                "return code: $ret->{rc}");
            }
            if (not grep {$ret->{rc} == $_} @$expectedRC) {
                $vdLogger->$logLevel("STAF command \"$command\" failed due to STAF" .
                                     "return code: $ret->{rc}, was expecting " .
                                     Dumper($expectedRC));
                VDSetLastError("ESTAF");
                $failed = 1;
            }
       }
       if (defined $ret->{exitCode}) {
          if ($ret->{exitCode}) {
              $vdLogger->Warn("Command \"$command\" failed with exit code: " .
                              "$ret->{exitCode}");
          }
          if ( not grep {$ret->{exitCode} == $_} @$expectedExitCode) {
            $vdLogger->$logLevel("Command \"$command\" failed with exit code: " .
                                 "$ret->{exitCode}, was expecting " .
                                 Dumper($expectedExitCode));
            if (defined $ret->{stdout} and $ret->{stdout} ne "") {
               $vdLogger->$logLevel("STDOUT: $ret->{stdout}");
            }
            if (defined $ret->{stderr} and $ret->{stderr} ne "") {
               $vdLogger->$logLevel("STDERR: $ret->{stderr}");
            }
            VDSetLastError("EFAIL");
            $failed = 1;
          }
       }
   }
   if ($failed) {
       return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# STAFSyncProcess --
#      Launches a process on remote host using the STAF process service.
#      The process is executed synchronously.
#
# Input:
#      1) host: host ip/name of the host on which the command
#               needs to be executed.
#      2) command: The command to be executed
#      3) timeout: Timeout (in seconds) for the process to return
#      4) opts:  A hash with any optional parameters of the
#                PROCESS service. In addition, following key
#                is supported (optional):
#                'NoShell' - To execute command without shell
#      5) logFailure: Flag when set to 1 will cause this method to examine the
#          result of the execution of command and log appropriate log messages.
#          Defaults to 0.
#      6) logLevel: Determine how the failure should be reported. This option
#          is only useful when logFailure is set to 1.
#      7) expectedRC: Expected return code from STAF command as a list. Defaults
#          to (0). This option is useful only when logFailure is set to 1.
#      8) expectedExitCode: Expected exit code of the executed command. Defaults
#          to (0). This option is useful only when logFailure is set to 1.

# Results:
#      Returns a result hash with following keys:
#      'rc': 0 if command executed successfully, positive integer which
#            represents staf rc in case of staf error, -1 in case of any
#            other error
#      'exitCode': return code from the process executed
#      'stdout': stdout from the process/command executed
#      'stderr': stderr from the process/command executed
#
# Side effects:
#      Depends on what the command does.
#
# Example:
#      my $opts;
#      my $command = "ping 10.20.84.51";
#      my $opts->{ENV} = "PATH = $PATH:/automation/bin";
#      $result = VDNetLib::Common::STAFHelper->STAFSyncProcess($host,
#                                                             $command,
#                                                             "10",
#                                                             $opts)
#
########################################################################

sub STAFSyncProcess
{
   my $self    = shift;
   my $host    = shift;
   my $command = shift;
   my $timeout = shift;
   my $opts    = shift || undef;
   my $logFailure = shift || 0;
   my $logLevel = shift;
   my $expectedRC = shift;
   my $expectedExitCode = shift;

   my $result = undef;
   $result->{rc}     = -1;

   if (not defined $host || not defined $command) {
      $self->{logObj}->Error("One or more parameters not supplied");
      $result->{rc} = -1;
      return $result;
   }

   # Convert keys in the hash $opts to lower case before any processing
   %$opts = (map { lc $_ => $opts->{$_}} keys %$opts);

   #
   # By default, STAF considers given timeout value in millisecs,
   # so converting the given timeout in seconds to milliseconds.
   # If timeout is not defined, STAF will wait forever for the process
   # to return.
   #
   $timeout = ($timeout) ? ($timeout * 1000) :
            VDNetLib::Common::GlobalConfig::STAF_CALL_TIMEOUT * 1000;

   # If the user specifies $opts->{wait}, it will be passed directly without
   # any unit conversion
   if (!$opts or ($opts and !$opts->{wait})) {
      $opts->{wait} = $timeout; # wait forever
   }
   my $sshOption = (defined $ENV{VDNET_USE_SSH}) ? $ENV{VDNET_USE_SSH} : 1;
   $vdLogger->Debug("Executing command \"$command\" on $host");
   if ((defined $sshSession->{$host}) && ($sshOption)) {
      $result = $self->SSHSyncProcess($host, $command, $timeout,
                                      $sshSession->{$host});
   } else {
      $result = $self->STAFProcess($host, $command, "SYNC", $opts);
   }
   if ($logFailure) {
       $self->ExamineSTAFResult($result, $command, $logLevel, $expectedRC,
                                $expectedExitCode);
   }
   return $result;

}


########################################################################
#
# STAFAsyncProcess --
#      Launches a process on remote host using the STAF process service.
#      The process is executed asynchronously i.e. handle to the process
#      executed is returned immediately if no STAF error occurs.
#
# Input:
#      1) host: host ip/name of the host on which the command
#               needs to be executed.
#      2) command: The command to be executed
#      3) opts:  A hash with any optional parameters of the
#                PROCESS service. In addition, following key
#                is supported (optional):
#                'NoShell'    - To execute command without shell
#
# Results:
#      Returns a result hash with following keys:
#      'rc': 0 if command executed successfully,
#            STAF RC code in case of any staf error,
#            -1 in case of any other error
#      'handle': process handle if 'rc' is 0, otherwise undef
#
# Side effects:
#      Depends on what the command does.
#
# Example:
#      my $opts;
#      my $command = "netserver -p 12860";
#      my $opts->{ENV} = "PATH = $PATH:/automation/bin";
#      my $opts->{NoShell} = 1;
#      $result = VDNetLib::Common::STAFHelper->STAFAsyncProcess($host,
#                                                              $command,
#                                                              './out',
#                                                              $opts)
#
########################################################################

sub STAFAsyncProcess
{
   my $self    = shift;
   my $host    = shift;
   my $command = shift;
   my $outputFile = shift || undef;
   my $opts    = shift || undef;

   my $result = undef;
   my $submitCmd;

   if (not defined $host || not defined $command) {
      $self->{logObj}->Error("One or more parameters not supplied");
      $result->{rc} = -1;
      return $result;
   }

   # Convert keys in the hash $opts to lower case before any processing
   %$opts = (map { lc $_ => $opts->{$_}} keys %$opts);

   # For executing process asynchronously the parameter WAIT should not be
   # sent. Deleting if $opts->{wait} option is specified
   if ($opts && $opts->{wait}) {
      delete $opts->{wait};
   }

   # If outputFile is specified, update that info under $opts->{stdout} option
   if ($outputFile) {
      $opts->{stdout} = $outputFile;
      $opts->{stderrtostdout} = "";
   }

   $result = $self->STAFProcess($host, $command, "ASYNC", $opts);
   return $result;
}


########################################################################
#
# CheckProcessStatus --
#      Returns the status of a process launched using PROCESS service.
#
# Input:
#      1) host: host ip/name of the host on which the process
#               was executed.
#      2) processHandle: The handle (staf) referring to the process
#                        executed
#
# Results:
#      Returns return code of the process, if process is completed;
#      undef if process if still running,
#      -1 in case of script error.
#
# Side effects:
#       None.
#
########################################################################

sub CheckProcessStatus
{
   my $self          = shift;
   my $host          = shift;
   my $processHandle = shift;

   if (not defined $host || not defined $processHandle) {
      $self->{logObj}->Error("One or more parameters not supplied");
      return -1;
   }

   my $processRc = undef;

   my $handleInfo = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
			$host, "PROCESS", "QUERY HANDLE $processHandle");
   if ($handleInfo->{rc} != $STAF::kOk) {
      return $handleInfo->{rc};
   }
   my $mc = STAF::STAFUnmarshall($handleInfo->{result});
   my $entryMap = $mc->getRootObject();
   if ($entryMap->{handle} == $processHandle) {
      if (defined($entryMap->{rc})) {
         $self->{logObj}->Debug("Process on $host referred by handle " .
                               "$processHandle completed.");
         return $entryMap->{rc};
      } else {
         $self->{logObj}->Debug("Process on $host referred by handle " .
                               "$processHandle is still running");
         return undef;
      }
   }
}


########################################################################
#
# WaitForProcess --
#      Waits for the given process to complete until timeout is reached
#
# Input:
#      1) host: host ip/name of the host on which the process
#               has to be monitored
#      2) processHandle: the staf process handle
#      3) timeout: timeout value in seconds (optional)
#
# Results: Returns a result hash with following keys:
#          'rc': 0 if command executed successfully,
#                STAF RC code in case of any staf error,
#                -1 in case of any other error
#          'exitCode': return code from the process if 'rc' eq 0
#          'stdout': stdout from the process
#          'stderr': stderr from the process
#
# Side effects:
#       Depends on what the command does.
#
########################################################################

sub WaitForProcess
{
   my $self          = shift;
   my $host          = shift;
   my $processHandle = shift;
   my $timeout       = shift || DEFAULT_PROCESS_WAIT_TIME;
   my $processRc = undef;
   my $resulthash;
   my $handle = $processHandle;
   my $processId = $processHandle;

   if (not defined $host || not defined $processHandle) {
      $self->{logObj}->Error("One or more parameters not supplied");
      $resulthash->{rc} = -1;
      return $resulthash;
   }

   #
   # The process completion is identified by reading the incoming message
   # queue from where the process was launched. The messages in the queue
   # contain marshalled  data, specifically, the handle information is
   # marshalled. Therefore, the given handle is marshalled before calling
   # GetMessage() to read the queue
   #
   my $handleMC = STAF::STAFMarshallingContext->new();
   $handleMC->setRootObject("$processId");
   my $handleData = "handle".$handleMC->marshall();

   ## Get the machine name of the host
   my $machineName = $self->GetMachineName($host);
   if (not defined $machineName) {
      $resulthash->{rc} = -1;
      return $resulthash;
   }

   my $failedPings = 0;
   my $maxFailedPings = 5;
   while ((not defined $processRc) && ($timeout > 0)) {
      #
      # After launching a process, it would be better to check the status of
      # the host by pinging to make sure the process is being monitored on a
      # system that is active.
      #
      if ($self->STAFPing($host)) {
         $self->{logObj}->Debug("$host failed to respond to staf ping.");
         $failedPings++;
         if ($failedPings > $maxFailedPings) {
            $self->{logObj}->Error("Test likely failed, please check the " .
                                   "system for any faults.");
            # update result hash
            $resulthash->{rc} = -1;
            return $resulthash;
         }
      }

      #
      # An end notification message will be sent to the host which launched the
      # process (referred by processHandle) on $host
      #
      $self->{logObj}->Debug("Waiting for process to return");

      my $mapResult = $self->GetMessage(DEFAULT_SLEEP_BETWEEN_PROCESS,
                                        "STAF/Process/End",
                                        $machineName,
                                        $handleData);
      unless ($mapResult) {
         $resulthash->{rc} = $processRc;
      } else {
         $self->{logObj}->Debug("Got end notification");

         $processRc = $mapResult->{message}->{rc};
         $self->{logObj}->Debug("Process RC: $processRc");
         $resulthash->{stdout} =
            $mapResult->{message}->{fileList}[0]{data};
         $resulthash->{stderr} =
            $mapResult->{message}->{fileList}[1]{data};

         $resulthash->{rc} = 0;
         $resulthash->{exitCode} = $processRc;
      }
      $timeout = $timeout - DEFAULT_SLEEP_BETWEEN_PROCESS;
   }
   if ($timeout <= 0) {
      $self->{logObj}->Error("Hit timeout to get process end notification");
      $resulthash->{rc} = -1;
   }
   return $resulthash;
}


########################################################################
#
# GetMessage --
#      Gets all messages of specific type from the internal queue of a
#      STAF handle
#
# Input:
#      1) wait: number of seconds to wait for a message (optional)
#      2) type: type of message, for example 'STAF/Process/End' (optional)
#      3) contains: array of string which has to exist in the message
#                   (optional)
#
# Results:
#      The rootObject hash which contains keys like 'message', 'handle'
#      etc. from queue if successful, undef otherwise
#
# Side effects:
#      None
#
########################################################################

sub GetMessage
{
   my $self = shift;
   my $wait = shift || DEFAULT_STAF_WAIT_TIME;
   my $type = shift;
   my $endpoint = shift;
   my $contains = shift;
   my $containsString = "";

   #
   # If the contains array has more than one string, then the message that
   # contains ALL the strings in the queue will be retrieved
   #
   $containsString = $contains;

   $wait = $wait * 1000;
   my $cmd = "GET WAIT $wait";
   if ($type) {
      $cmd .= " TYPE $type";
   }
   if ($endpoint) {
      $cmd .= " MACHINE $endpoint";
   }
   if (defined $contains) {
      $cmd .= " CONTAINS $contains";
   }

   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
			"local", "QUEUE", "$cmd");

   if ($result and $result->{rc} == 0) {
       my $mc = STAF::STAFUnmarshall($result->{result});
       return $mc->getRootObject();
   }
   return undef;
}


########################################################################
#
# SendMessage --
#      This method send the given message using STAF QUEUE service.
#
# Input:
#      message: message (scalar string) to be sent (Required)
#      host   : host to which the message should be sent (Required)
#      opts   : reference to a hash which supports following keys,
#               (Optional)
#                 handle - staf handle
#                 priority - priority to be used to send message
#                 name     - handle name
#                 type     - message type
#                 For more information on these options, refer to
#                 staf command reference page.
#
# Results:
#      0, if message is sent successfully;
#      undef, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub SendMessage
{
   my $self    = shift;
   my $message = shift;
   my $host    = shift || "local";
   my $opts    = shift;

   my $cmd = "QUEUE MESSAGE \"$message\"";
   if (defined $opts) {
      # Convert keys in the hash $opts to lower case before any processing
      %$opts = (map { lc $_ => $opts->{$_}} keys %$opts);
   }

   if ($opts->{'handle'}) {
      $cmd = $cmd . " HANDLE " . $opts->{handle};
   }

   if ($opts->{'priority'}) {
      $cmd = $cmd . " PRIORITY " . $opts->{'priority'};
   }

   if ($opts->{'name'}) {
      $cmd = $cmd . " NAME " . $opts->{'name'};
   }

   if ($opts->{'type'}) {
      $cmd = $cmd . " TYPE " . $opts->{'type'};
   }

   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
		$host, "QUEUE", $cmd);
   if ($result->{rc} != 0) {
      $self->{logObj}->Error("Failed to send the message $message: " .
                             $result->{rc});
      return undef;
   }

   return 0;
}


########################################################################
#
# STAFPing --
#      Sends a STAF ping to a client to determine availability
#
# Input:
#      host: which needs to be pinged
#
# Results:
#      non-zero on error, 0 on success
#
# Side effects:
#      None
#
########################################################################

sub STAFPing
{
   my $self = shift;
   my $host = shift;
   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
		$host, "PING", "PING");
   if ($result->{rc} != $STAF::kOk) {
      return FAILURE;
   }

   return SUCCESS;
}

########################################################################
#
# GetMachineName --
#      Gets the Machine/Endpoint name of the given host. This is the
#      name used by STAF for the given machine to communicate
#      across multiple hosts. It is also the dns hostname of the given
#      system.
#
# Input:
#      host: whose Machine name need to be determined.
#
# Results:
#      Machine name of the given host, if successful
#      (for example tcp://prme-elab2-dhcp224.eng.vmware.com@6500),
#      undef, in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetMachineName
{
   my $self = shift;
   my $host = shift;

   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   if (not defined $localIP) {
      $self->{logObj}->Error("Failed to find local ip address");
      return undef;
   }

   #
   # nslookup command does not work reliably when the host belongs to different
   # subnets.
   # hostname command does not refer to the dns hostname in case of
   # windows. Instead, it refers to the computer name.
   # whoami command in STAF MISC service also returns the computer name in case
   # of windows.
   #

   #
   # QUEUE service in STAF makes use of machine names correctly. Even in case
   # of windows, STAF somehow finds the correct machine name (dns hostname).
   # In this method, a STAF process is started on the given host to send a
   # unique message to the local machine (where this method is executed).
   # Then, this unique message is searched on the local machine's queue.
   # The queue will have both the unique message and sender's "machine name".
   #
   my $message = "GetMachineName" . VDNetLib::Common::Utilities::GetDateTime();
   my $command = 'staf ' . $localIP . '@' . $self->{tcpport} .
                 ' queue queue handle ' .
                 $STAF::Handle . ' message ' . $message;
   my $result = $self->STAFSyncProcess($host, $command);
   if ($result->{rc} != $STAF::kOk) {
      $self->{logObj}->Error("STAF failure:$result->{rc}");
      return undef;
   }
   $result = $self->GetMessage(60, undef, undef, $message);
   if (defined $result) {
      return $result->{machine};
   } else {
      $self->{logObj}->Error("GetMessage() failed");
      $self->{logObj}->Debug("STAF failure:" . Dumper($result));
      return undef;
   }
}


########################################################################
#
# GetOS --
#      The function retrevies the type of os
#      (VMKernel,Linux,Windows,MAC) by retreiving the staf
#      variable STAF/Config/OS/Name 's value
#
# Input:
#      host -- Host whose OS type need to be determined.
#
# Results:
#      A string with the os type (Linux/Win/Darwin/VMkernel)
#
# Side effects:
#   None.
#
########################################################################

sub GetOS
{
   my $self   = shift;
   my $host   = shift;
   if (not defined $host) {
      $vdLogger->Error("Host IP not supplied to GetOS");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},$host, "VAR",
                                        "GET SYSTEM VAR STAF/Config/OS/Name");

   if ($result->{rc}) {
      return undef;
   }

   $result->{result} = ($result->{result} =~ /winnt/i) ? "windows" :
                        $result->{result};

   return $result->{result};
}


########################################################################
#
# CheckSTAF --
#      Checks whether STAF is running on the given host
#
# Input:
#      host - host on which STAF process needs to be checked
#
# Results:
#      0 - if STAF is running
#      non-zero - if STAF is not running on the given host
#
# Side effects:
#      None
#
########################################################################

sub CheckSTAF
{
   my $self = shift;
   my $host = shift;

   return $self->STAFPing($host);
}


########################################################################
#
# WaitForSTAF --
#      Waits (until timeout) for STAF to be available on the given host
#
# Input:
#      host - host on which this method need to run
#      timeout - timeout value in seconds (optional)
#
# Results:
#      SUCCESS if STAF is available within timeout value,
#      FAILURE if timeout is hit
#
# Side effects:
#      None
#
########################################################################

sub WaitForSTAF
{
   my $self = shift;
   my $host = shift;
   my $timeout = shift || MAX_DEFAULT_WAITTIME_FOR_STAFTOCOMEUP;
   my $retries = shift;

   if (not defined $host) {
      $self->{logObj}->Error("Host on which staf should wait not provided");
      return FAILURE;
   }

   $retries = 1 if (not defined $retries);

WAITFORSTAF:
   my $stafStatus = 1;
   my $startTime = time();
   $self->{logObj}->Debug("Waiting for STAF to be up and running on $host...");
   while ($timeout && $startTime + $timeout > time() &&
				$stafStatus ne SUCCESS) {
      $stafStatus = $self->CheckSTAF($host);
      sleep 10 if $stafStatus eq FAILURE;
   }
   if ($stafStatus eq SUCCESS) {
      $self->{logObj}->Debug("STAF is up and running on $host");
      return SUCCESS;
   } else {
      $self->{logObj}->Error("Hit timeout waiting for staf to be up in $host");
      # Check if ping to the VM works fine, if it does then this VM could be
      # taking too long to boot, so give it another retry before giving up on
      # it.
      if ($retries && !(VDNetLib::Common::Utilities::Ping($host))) {
         $self->{logObj}->Info("Check if ping $host works, if so, " .
                               "retry $retries times waiting for STAF " .
                               "to come up");
	 --$retries;
         goto WAITFORSTAF;
      }
      return FAILURE;
   }
}


########################################################################
#
# STAFFSGetNodeType --
#      Returns whether the given file system node is a file or
#      directory.
#
# Input:
#      1) host:  host on which to check for node type
#      2) fsNode : path to the file / directory (if file, enter
#                     filename with extension)
#
# Results:
#      'D' : if the given FS node is a directory,
#      'F' : if the given FS node is a file,
#      undef : in case of any error
#
# Side effects:
#      None
#
# Example:
#      VDNetLib::Common::STAFHelper::STAFFSGetNodeType($host,
#                                              "/usr/bin/migrate")
#
########################################################################

sub STAFFSGetNodeType
{
   my $self = shift;
   my $host = shift;
   my $fsNode = shift;

   if (not defined $host || not defined $fsNode) {
      $self->{logObj}->Error("Host and/or fsNode not provided");
      return undef;
   }
   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},$host, "FS",
                "GET ENTRY ". STAF::WrapData($fsNode) . " TYPE");

   if ($result->{rc} != $STAF::kOk) {
      $self->{logObj}->Debug("Failed to get fs node type:RC" . $result->{rc} .
                             (($result->{result}) ? "-$result->{result}" : ""));
      return undef;
   }
   return $result->{result};
}

########################################################################
#
# IsDirectory --
#      Method to find whether the give FS node is a directory or not.
#
# Input:
#      1) host:  host on which the given fs node is located
#      2) fsNode : path to the file / directory (if file, enter
#                  filename with extension)
#
# Results:
#      1 : if the given FS node is a directory,
#      0 : if the given FS node is not a directory,
#      undef : in case of any error
#
# Side effects:
#      None
#
# Example:
#      VDNetLib::Common::STAFHelper::IsDirectory($host,
#                                             "/usr/bin")
#
########################################################################

#TODO - move this method to common utilities
sub IsDirectory
{
   my $self = shift;
   my $host = shift;
   my $fsNode = shift;


   my $result = $self->STAFFSGetNodeType($host,
                                         $fsNode);
   if ($result) {
      if ($result eq "D") {
         return TRUE;
      } else {
         return FALSE;
      }
   } else {
      return undef;
   }
}

########################################################################
#
# IsFile --
#      Method to find whether the give FS node is a file or not.
#
# Input:
#      1) host:  host on which the given fs node is located
#      2) fsNode : path to the file / directory (if file, enter
#                  filename with extension)
#
# Results:
#      1 : if the given FS node is a file,
#      0 : if the given FS node is not a file,
#      undef : in case of any error
#
# Side effects:
#      None
#
# Example:
#      VDNetLib::Common::STAFHelper::IsFile($host,
#                                   "/usr/bin/migrate")
#
########################################################################

#TODO - move this method to common utilities
sub IsFile
{
   my $self = shift;
   my $host = shift;
   my $fsNode = shift;


   my $result = $self->STAFFSGetNodeType($host,
                                         $fsNode);
   if ($result) {
      if ($result eq "F") {
         return TRUE;
      } else {
         return FALSE;
      }
   } else {
      return undef;
   }
}

########################################################################
#
# STAFFSGetNodeSize --
#      Returns the size of the given file or directory
#
# Input:
#      1) host:  host on which to check for file/directory 's size
#      2) fsNode : path to the file / directory
#
# Results:
#      Size of the given file/directory if successful,
#      undef otherwise
#
# Side effects:
#      None
#
# Example:
#      VDNetLib::Common::STAFHelper::STAFFSGetNodeSize($host,
#                                              "/usr/bin/migrate");
#
########################################################################

sub STAFFSGetNodeSize
{
   my $self = shift;
   my $host = shift;
   my $entryPath = shift;

   if (not defined $host || not defined $entryPath) {
      $self->{logObj}->Error("One or more parameters not supplied");
      return undef;
   }

   $entryPath = STAF::WrapData($entryPath);
   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},$host, "FS",
                                        "GET ENTRY " . $entryPath . " SIZE");

   if ($result->{rc} != $STAF::kOk) {
      $self->{logObj}->Error("Failed to get node size:RC" . $result->{rc} .
                             (($result->{result}) ? "-$result->{result}" : ""));
      return undef;
   }
   my $mc = STAF::STAFUnmarshall($result->{result});
   my $mcRootObject = $mc->getRootObject();
   return undef unless $mcRootObject;
   return $mcRootObject->{lowerSize};
}


########################################################################
#
# STAFFSListDirectory --
#      Lists all the entries in the given directory
#
# Input:
#      1) host: host on which the directory exists
#      2) directory : directory which has to be listed
#      3) extraOptions: Additional options for FS Service to list
#                       directory (optional)
#
# Results:
#      Returns an array of entries in the given directory if successful,
#      undef otherwise
#
# Side effects:
#      None
#
# Example:
#      VDNetLib::Common::STAFHelper::STAFFSListDirectory($host, "/usr")
#
########################################################################

sub STAFFSListDirectory
{
   my $self = shift;
   my $host = shift;
   my $directory = shift;
   my $extraOptions = shift || "";

   if (not defined $host || not defined $directory) {
      $self->{logObj}->Error("Host and/or directory not specified to " .
                              "STAFFSListDirectory");
      return undef;
   }
   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},$host, "FS",
                                        "LIST DIRECTORY " .
                                        STAF::WrapData($directory) .
                                        " $extraOptions");

   if ($result->{rc} != $STAF::kOk) {
      $self->{logObj}->Error("Failed to get files in under $directory on " .
                             "host $host:RC" . $result->{rc} .
                             (($result->{result}) ?
                             " - $result->{result}" : ""));
      return undef;
   }

   my $mc = STAF::STAFUnmarshall($result->{result});
   return $mc->getRootObject();
}


########################################################################
#
# GetOSArch --
#      Get the OS architecture (x86_32 or x86_64)
#
# Input:
#      1) host : Host whose OS architecture need to be found
#
# Results:
#      A string "x86_32" for 32-bit systems or
#      "x86_64" for 64-bit systems,
#      undef in case of any error
#
# Side effects:
#      None
# Example:
#      VDNetLib::Common::STAFHelper::GetRevision($host);
#
########################################################################

sub GetOSArch
{
   my $self = shift;
   my $host = shift;

   if (not defined $host) {
      $self->{logObj}->Error("Host not specified to find architecture");
      return undef;
   }

   my $osType = $self->GetOS($host);
   my $stafVar;
   if ($osType) {
      if ($osType =~ /Win/i) {
         $stafVar = "STAF/Env/PROCESSOR_ARCHITECTURE";
      } else {
         $stafVar = "STAF/Config/OS/Revision";
      }
   } else {
      $self->{logObj}->Error("Failed to get $host os type");
      return undef;
   }

   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
			$host, "VAR","GET SYSTEM VAR " .$stafVar);

   if ($result->{rc} != $STAF::kOk) {
      $self->{logObj}->Error("Failed to get $host architecture:$result->{rc}");
      return undef;
   }

   return ($result->{result} =~ /64/) ? "x86_64" : "x86_32";
}


########################################################################
#
# STAFFSCopyDirectory --
#      This method copies the directory from one location to another
#
# Input:
#      srcDir : the source directory
#      dstDir : the destination directory
#      srcMachine : if passed the source directory is taken from this
#                   machine.
#      dstMachine : the destination host where directory is to be copied
#      extraOpt   : if passed considers this option for the STAF copy
#                   command, if not, considers the RECURSE FAILIFNEW
#                   as the option. (Optional)
#
# Results:
#      If successful returns 0, else returns -1
#
# Side Effects:
#      None
#
# Example:
#      VDNetLib::Common::STAFHelper::STAFFSCopyDirectory('C:\STAF\bin',
#                                                '/usr/local/bin,
#                                                "10.115.155.83",
#                                                "10.115.155.232")
#
########################################################################

sub STAFFSCopyDirectory
{
   my $self       = shift;
   my $srcDir     = shift;
   my $dstDir     = shift;
   my $srcMachine = shift;
   my $dstMachine = shift;
   my $extraOpt   = shift || "RECURSE";

   if (not defined $srcDir || not defined $dstDir ||
       not defined $srcMachine || not defined $dstMachine) {
      $self->{logObj}->Error("Insufficient arguments provided to copy directory");
      return -1;
   }

   my $localIP;
   if (($localIP = VDNetLib::Common::Utilities::GetLocalIP()) eq "FAILURE") {
      $self->{logObj}->Error("Unable to get local IP address");
      return -1;
   }
   $dstMachine = ($dstMachine =~ /$localIP/) ? "$dstMachine\@$sessionSTAFPort" :
                                               "$dstMachine\@$STAF_DEFAULT_PORT";

   my $command = "COPY DIRECTORY ". STAF::WrapData($srcDir) .
                 " TOMACHINE ". STAF::WrapData($dstMachine) .
                 " TODIRECTORY " . STAF::WrapData($dstDir) .
                 " $extraOpt";

   my $stafResult = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
			$srcMachine, "FS", $command);

   if ($stafResult->{rc} != $STAF::kOk) {
      $self->{logObj}->Error("Copying directory $srcDir failed, " .
                             Dumper($stafResult));
      return -1;
   }
   return 0;
}


########################################################################
#
# STAFFSCopyFile --
#      This method copies the file from one location to another
#
# Input:
#      source : the source filename
#      dest   : the destination filename
#      srcMachine : if passed the source file is taken from this machine
#                   if not, the source file is taken from the local
#                   machine calling this method. (optional)
#      dstMachine : the destination host where file is to be copied
#                   (optional)
#
#                   If 'srcMachine' and 'dstMachine' are not specified
#                   then 'local' will be used. In that case, the
#                   'source' and 'dest' path should match to same file
#                   system (for example, source and dest should use /
#                   in case of linux, or \ in case of windows to
#                   specify path) to avoid RC:17 (File Open Error)
#
# Results:
#      If successful returns 0, else returns -1
#
# Side Effects:
#      None
#
# Example:
#      VDNetLib::Common::STAFHelper::STAFFSCopyFile('C:\STAF\bin\STAF.cfg',
#                                           '/usr/bin/STAF.cfg,
#                                           "10.115.155.83",
#                                           "10.115.155.232")
#
########################################################################

sub STAFFSCopyFile
{
   my $self = shift;
   my $source = shift;
   my $dest = shift;
   my $srcMachine = shift || "local";
   my $dstMachine = shift || "local";

   if (not defined $source || not defined $dest) {
      $self->{logObj}->Error("source and/or dest not specified to copy file");
      return -1;
   }

   my $nodeType = $self->STAFFSGetNodeType($srcMachine,$source);
   if (not defined $nodeType) {
      $self->{logObj}->Debug("File $source does not exist on $srcMachine");
      return 0;
   }
   #
   # If '$dest' is a directory then use TODIRECTORY option to copy the source
   # file
   #
   my $toWhere = "TOFILE";
   if ($self->STAFFSGetNodeType($dstMachine,$dest) &&
       "D" eq $self->STAFFSGetNodeType($dstMachine,$dest)) {
      $toWhere = "TODIRECTORY";
   }
   my $localIP;
   if (($localIP = VDNetLib::Common::Utilities::GetLocalIP()) eq "FAILURE") {
      $self->{logObj}->Error("Unable to get local IP address");
      return -1;
   }

   $dstMachine = ($dstMachine =~ /$localIP/) ? "$dstMachine\@$sessionSTAFPort" :
                                               "$dstMachine\@$STAF_DEFAULT_PORT";


   #
   # Optional argument 'srcMachine' indicates from where the file is being
   # copied. If not specified, it will default to 'local', the machine which
   # calls this method.
   #
   my %result;
   my $cmd = "COPY FILE ".STAF::WrapData($source). " TOMACHINE ".
             $dstMachine." $toWhere ".$dest;

   my $stafResult = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
                                                            $srcMachine,
                                                            "FS", $cmd);
   if ($stafResult->{rc} != $STAF::kOk) {
      $self->{logObj}->Error("Copying file $source failed, RC:$stafResult->{rc}");
      return -1;
   }
   return 0;
}


########################################################################
#
# STAFFSReadFile --
#      This method returns content of the given text file
#
# Input:
#      host       : host on which the file is located
#      fileName   : absolute path to the file
#
# Results:
#      If successful returns content of the file as a string,
#      else returns undef
#
# Side Effects:
#      None
#
# Example:
#      VDNetLib::Common::STAFHelper::STAFFSReadFile("10.115.155.232",
#                                                'C:\STAF.cfg');
#
########################################################################

sub STAFFSReadFile
{
   my $self     = shift;
   my $host     = shift;
   my $fileName = shift;
   my $stafResult;

   if (not defined $host || not defined $fileName) {
      $self->{logObj}->Error("host and/or fileName not specified to read file");
      return undef;
   }

   $stafResult = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
			$host, "FS", "GET FILE $fileName TEXT");

   if ($stafResult->{rc} != $STAF::kOk) {
      $self->{logObj}->Debug("Reading file $fileName failed, " .
                             "RC:$stafResult->{rc}");
      return undef;
   }
   return $stafResult->{result};
}


########################################################################
#
# GetProcessInfo --
#       The method returns information about process started on a remote
#      machine using STAF.
#
# Input:
#      1) host: host on which the given process was started
#      2) processHandle: the STAF process handle for the process
#                        started on 'host'
#
# Results:
#      Returns undef in case of any error,
#      if successful, returns a hash with following keys:
#      'workdir', 'focus', 'staf-map-class-name', key', 'pid',
#      'startTimestamp', 'startMode', 'userName', 'shell', 'handleName',
#      'command', 'rc', 'parms', 'handle', 'title', 'endTimestamp',
#      'workload'
#
# Side effects:
#      None.
#
# Example:
#      $result = VDNetLib::Common::STAFHelper::STAFAsyncProcess($host,
#                                                       $command);
#      VDNetLib::Common::STAFHelper::GetProcessInfo($host,
#                                           $result->{handle});
#
########################################################################

sub GetProcessInfo
{
   my $self          = shift;
   my $host          = shift;
   my $processHandle = shift;

   if (not defined $host || not defined $processHandle) {
      $self->{logObj}->Error("One or more parameters not supplied");
      return undef;
   }

   my $processRc = undef;

   my $handleInfo = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
			$host, "PROCESS", "QUERY HANDLE $processHandle");
   if ($handleInfo->{rc} != $STAF::kOk) {
      $self->{logObj}->Error("STAF error to get list of handles:RC" .
                             $handleInfo->{rc} .
                             (($handleInfo->{result}) ?
                             " - $handleInfo->{result}" : ""));
      return undef;
   }
   my $mc = STAF::STAFUnmarshall($handleInfo->{result});
   my $entryMap = $mc->getRootObject();
   if ($entryMap->{handle} == $processHandle) {
      return $entryMap;
   } else {
      $self->{logObj}->Error("Failed to get process handle information");
      return undef;
   }
}


########################################################################
#
# GetProcessId --
#      The method returns the process id (pid) of the given staf process
#      handle (for example, the key value 'handle' from
#      STAFAsyncProcess() method's return hash)
#
# Input:
#      1) host: host on which the given process was started
#      2) processHandle: the STAF process handle for the process
#                        started on 'host'
#
# Results:
#      Process ID if successful, undef otherwise
#
# Side effects:
#      None.
#
# Example:
#      $result = VDNetLib::Common::STAFHelper::STAFAsyncProcess($host,
#                                                       $command);
#      VDNetLib::Common::STAFHelper::GetProcessId($host,$result->{handle});
#
########################################################################

sub GetProcessId
{
   my $self          = shift;
   my $host          = shift;
   my $processHandle = shift;

   my $result = $self->GetProcessInfo($host, $processHandle);
   if ($result->{shell}) {
      $self->{logObj}->Debug("The process ID indicates shell process");
   }
   return $result->{pid};
}


########################################################################
#
# STAFSubmitVMCommand --
#      Executes a VM service command.
#
# Input:
#      1) host:  host on which the VM command is to be executed.
#      2) command: the command to be executed.
#      3) expectedRC: staf rc value that is acceptable # Optional
#
# Results:
#      A hash with the following keys,
#      'rc' - The return code of the staf VM command
#      'result' - The result (if any) of the staf VM command. If the
#                 command does not have a result, it is set to undef.
#
# Side effects:
#      None
#
# Example:
#       VDNetLib::Common::STAFHelper::STAFSubmitVMCommand("local",
#       "ADDSERIALPORT ANCHOR esx-host1 VM win2k3 DEVICE /dev/ttyS0")
#
########################################################################

sub STAFSubmitVMCommand
{
   my $self       = shift;
   my $host       = shift;
   my $command    = shift;
   my $expectedRC = shift || $STAF::kOk;
   my $resultHash;

   if (not defined $host || not defined $command) {
      $self->{logObj}->Error("Host and/or command not provided");
      return undef;
   }

   $self->{logObj}->Debug("host:$host,VM service command:$command");
   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
		$host, "VM", $command);
   if (ref($result->{resultObj}) eq "HASH") {
      $resultHash->{result} = $result->{resultObj}{result};
   } else {
      $resultHash->{result} = $result->{result};
   }

   #
   # Check whether the rc returned from executing the above staf command
   # is equal to 0 ($STAF::kOk) or equal to the expectedRC value that the
   # caller specified. If yes, set 'rc' in the resultHash to 0, otherwise
   # throw an error with the returned rc code.
   #
   if (($result->{rc} != $STAF::kOk) &&
       ($result->{rc} != $expectedRC)) {
      $self->{logObj}->Debug("STAF VM command failed with RC: " .
                             $result->{rc});
      if (defined $result->{resultObj}) {
         $self->{logObj}->Debug(Dumper($result->{resultObj}));
      }
      $resultHash->{rc} = $result->{rc};
   } else {
      $resultHash->{rc} = 0;
   }
   return $resultHash;
}

########################################################################
#
# STAFSubmitHostCommand --
#      Executes a Host service command.
#
# Input:
#      1) host:  host on which the VM command is to be executed.
#      2) command: the command to be executed.
#      3) expectedRC: staf rc value that is acceptable # Optional
#
# Results:
#      A hash with the following keys,
#      'rc' - The return code of the staf VM command
#      'result' - The result (if any) of the staf VM command. If the
#                 command does not have a result, it is set to undef.
#
# Side effects:
#      None
#
# Example:
#       VDNetLib::Common::STAFHelper::STAFSubmitHostCommand("local",
#       "ADDSERIALPORT ANCHOR esx-host1 VM win2k3 DEVICE /dev/ttyS0")
#
########################################################################

sub STAFSubmitHostCommand
{
   my $self       = shift;
   my $host       = shift;
   my $command    = shift;;
   my $expectedRC = shift || $STAF::kOk;
   my $resultHash;

   if (not defined $host || not defined $command) {
      $self->{logObj}->Error("Host and/or command not provided");
      return undef;
   }

   $self->{logObj}->Debug("Host service command:$command");
   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
	$host, "HOST", $command);
   if (ref($result->{resultObj}) eq "HASH") {
      $resultHash->{result} = $result->{resultObj}{result};
   } else {
      $resultHash->{result} = $result->{result};
   }

   #
   # Check whether the rc returned from executing the above staf command
   # is equal to 0 ($STAF::kOk) or equal to the expectedRC value that the
   # caller specified. If yes, set 'rc' in the resultHash to 0, otherwise
   # throw an error with the returned rc code.
   #
   if (($result->{rc} != $STAF::kOk) &&
       ($result->{rc} != $expectedRC)) {
      $self->{logObj}->Debug("STAF Host command failed with RC: " .
                             $result->{rc});
      if (defined $result->{resultObj}) {
         $self->{logObj}->Debug(Dumper($result->{resultObj}));
      }
      $resultHash->{rc} = $result->{rc};
   } else {
      $resultHash->{rc} = 0;
   }


   return $resultHash;
}


########################################################################
#
# STAFSubmitSetupCommand --
#      Executes a setup service command.
#
# Input:
#      1) host   :  host on which the VM command is to be executed.
#      2) command: the command to be executed.
#
# Results:
#      A hash with the following keys,
#      'rc' - The return code of the staf setup command
#      'result' - The result (if any) of the staf setup command. If the
#                 command does not have a result, it is set to undef.
#      'expectedRC' - staf rc value that is acceptable # Optional
#
# Side effects:
#      None
#
# Example:
#       VDNetLib::STAFHelper::STAFSubmitSetupCommand("local",
#       "createdc "libo"  anchor 10.112.119.158")
#
########################################################################

sub STAFSubmitSetupCommand
{
   my $self       = shift;
   my $host       = shift;
   my $command    = shift;;
   my $expectedRC = shift || $STAF::kOk;
   my $resultHash;

   if (not defined $host) {
      $self->{logObj}->Error("Host not provided");
      return undef;
   }
   if (not defined $command) {
      $self->{logObj}->Error("Command not provided");
      return undef;
   }

   $self->{logObj}->Debug("Setup service command:$command");
   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
		$host, "SETUP", $command);
   if (ref($result->{resultObj}) eq "HASH") {
      $resultHash->{result} = $result->{resultObj}{result};
   } else {
      $resultHash->{result} = $result->{result};
   }

   #
   # Check whether the rc returned from executing the above staf command
   # is equal to 0 ($STAF::kOk) or equal to the expectedRC value that the
   # caller specified. If yes, set 'rc' in the resultHash to 0, otherwise
   # throw an error with the returned rc code.
   #
   if (($result->{rc} != $STAF::kOk) &&
       ($result->{rc} != $expectedRC)) {
      $self->{logObj}->Debug("STAF Setup command failed with RC: " .
                             $result->{rc});
      if (defined $result->{resultObj}) {
         $self->{logObj}->Debug(Dumper($result->{resultObj}));
      }
      $resultHash->{rc} = $result->{rc};
   } else {
      $resultHash->{rc} = 0;
   }
   return $resultHash;
}


########################################################################
#
# STAFDisconnectAllAnchors --
#      Disconnects all STAF ANCHORs.
#
# Input:
#      1) ANCHOR   :  ANCHOR to disconnect.
#
# Results:
#      None
#
# Side effects:
#      Disconnects all STAF ANCHORs
#
# Example:
#       VDNetLib::STAFHelper::STAFDisconnectAllAnchors("<hostIP>:root")
#
########################################################################

sub STAFDisconnectAllAnchors
{
   my $self         = shift;
   my $anchor       = shift;

   $vdLogger->Info("Disconnecting all STAF ANCHORs");

   # Disconnect the SETUP ANCHOR
   my $command = " DISCONNECT ANCHOR " . $anchor;
   my $result = $self->STAFSubmitSetupCommand("local", $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Could not disconnect setup anchor:" . Dumper($result));
   }

   # Disconnect the HOST ANCHOR
   $result = $self->STAFSubmitHostCommand("local", $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Could not disconnect host anchor:" . Dumper($result));
   }
   # Disconnect the VM ANCHOR
   $result = $self->STAFSubmitVMCommand("local", $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Could not disconnect vm anchor:" . Dumper($result));
   }
}


########################################################################
#
# runStafCmd --
#       Run the given command on the given host using given STAF service
#	via STAF
#       1. Check the host if defined use it else check self->_host and
#	   use this host
#	2. Using STAF submit, launch the command
#	3. If no staf error, Unmarshall the result and return
#
# Input:
#       host, service, and command
#
# Results:
#       returns "SUCCESS",<data> if successful
#       returns "FAILURE",0
#
# Side effects:
#       None
#
########################################################################

sub runStafCmd
{
   my $self    = shift;
   my $host    = shift;
   my $service = shift;
   my $command = shift;

   my $staf_timeout = VDNetLib::Common::GlobalConfig::STAF_CALL_TIMEOUT;
   my $errorString;
   my $data;
   my $result;
   my $entryMap;
   my $mc;

   my $parent = ( caller(1) )[3];
   if ( (not defined $self->{_handle}) ||
        ((not defined $host) && (not defined $self->{_host})) ) {
      $vdLogger->Error("Either STAF handle or host is not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
      # if both host and self->{_host} are defined then host will
      # be given preference. So caller has to pass undef for host
      # if he wants to use self->{_host}
   } elsif ( (not defined $host) && (defined $self->{_host}) &&
             ($self->{_host} ne "") ) {
      $host = $self->{_host};
   }

   if ($self->CheckSTAF($host) eq FAILURE) {
      $vdLogger->Error("runStafCmd $parent: STAF is not running on $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (lc($host) eq "localhost" || lc($host) eq "local") {
      $host = "local";
   }

   #
   # By default, STAF considers given timeout value in milliseconds,
   # hence  converting the given timeout in seconds to milliseconds.
   # If timeout is not defined,  STAF will wait forever for the call
   # to return.
   #
   $staf_timeout = $staf_timeout * 1000;

   # add the timeout value to wait option in the command, if present.
   $command =~ s/\s+wait/ wait $staf_timeout/ig;

   $vdLogger->Debug("runStafCmd: $host $service $command");

   $result = VDNetLib::Common::Utilities::STAFSubmit($self->{_handle},"$host",$service,
	"$command");

   if ( ($result->{rc}) != $STAF::kOk ) {
      if ( ( not defined($result->{result}) ) ||
           ( (defined ($result->{result})) &&
             (length($result->{result}) != 0) ) ) {
         $errorString = (defined($result->{result})) ? $result->{result} : "";
         VDSetLastError("ESTAF");
         $vdLogger->Debug("$errorString") if $errorString ne "";
         return FAILURE, $errorString;
      }
   }

   #
   # TODO: Is it possible for STAF to retrun nothing in
   # in the resutl->{result} for any command?  If so,
   # the below condition should be removed.
   # With FS create directory command though the command succeeds,
   # $result{result} is undefined, for now closing the below block
   # of code and will open this later if necessary
   #
   if ( not defined($result->{result}) ) {
      return SUCCESS, "";
   }
   # some commands do not return the result object instead return
   # the data directly.
   if ( (!ref($result->{result})) &&
        ($result->{result} =~ /^\d+$/) ) {
      return SUCCESS, $result->{result};
   }
   $mc = STAF::STAFUnmarshall($result->{result});
   $entryMap = $mc->getRootObject();
   if ( ref($entryMap) ) {
      # TODO: need to test the below code path with VM service
      # before using for VM service
      if ( $service eq "vm" ) {
         return SUCCESS, $mc->formatObject();
      }
      if ( ref($entryMap) eq 'ARRAY' ) {
          $data = $entryMap;
      } elsif ( exists $entryMap->{fileList} ) {
         $data = $entryMap->{fileList}[0]{data};
      } else {
         $data = $entryMap;
      }
      # Added following three lines to take care of
      # empty result, though result is present.
      if ($data eq "" && defined $entryMap->{fileList}[1]{data}) {
         $data = $entryMap->{fileList}[1]{data};
      }
      return SUCCESS, $data;
   } else {
      return SUCCESS, $entryMap;
   }
}


########################################################################
#
# STAFFSGetLinkTarget --
#      Method to get the target name of symlink file.
#
# Input:
#      file: path to the symlink file (Required)
#      host: host name or ip address on which the file exists (Optional)
#            (default is "local")
#
# Results:
#      target name (scalar string) if a target exists for the given
#      symlink;
#      "<None>", if no target exists;
#      undef in case of any error.
#
# Side effects:
#     None
#
########################################################################

sub STAFFSGetLinkTarget
{
   my $self = shift;
   my $file = shift;
   my $host = shift || "local";

   my $command = "GET ENTRY $file LINKTARGET";

   my $stafResult = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
		$host, "FS", $command);
   if ($stafResult->{rc} != $STAF::kOk) {
      $self->{logObj}->Error("Failed to find link target of $file ".
                             "on $host: $stafResult->{rc}");
      return undef;
   }

   return $stafResult->{result};
}

########################################################################
#
# STAFFSCreateDir--
#      Method to create the directory.
#
# Input:
#      host : host on which the file/directory is present (Required)
#      directory : directory name.
#      opts : Other option to create directory under staf
#             FS service (Optional).
#             opts is reference to a hash with following keys:
#             FULLPATH: Full path where directory is to be created.
#             FAILIFEXISTS : If the directory already exists return
#                            fail.
#
# Results:
#      undef, if the given file/directory is not created successfully;
#      stdout of create operation in case of success, which is
#      usually empty character.
#
# Side effects:
#      User is responsible for the files/directory created
#
########################################################################

sub STAFFSCreateDir
{
   my $self = shift;
   my $directory = shift;
   my $host = shift || "local";
   my $fullPath = shift || "yes";
   my $failIfExists = shift;
   my $command;
   my $stafResult;

   if (not defined $directory) {
      $self->{logObj}->Error("Failed to create directory ".
                             "$directory");
      VDSetLastError("ENOTDEF");
      return undef;
   }

   $command = "CREATE DIRECTORY $directory";
   if($fullPath =~ m/yes/i) {
      $command = "$command FULLPATH ";
   }
   $stafResult = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
		$host, "FS", $command);
   if ($stafResult->{rc} != $STAF::kOk) {
      $self->{logObj}->Error("Failed to create directory $directory".
                             " on $host: $stafResult->{rc}");
      return undef;
   }
   return $stafResult->{result};
}


########################################################################
#
# STAFFSDeleteFileOrDir--
#      Method to delete the given file or directory.
#
# Input:
#      host : host on which the file/directory is present (Required)
#      entry: file or directory name in absolute path (Required)
#      opts : Other option to delete entry command under staf
#             FS service (Optional).
#             opts is reference to a hash with following keys:
#             'recurse' - value is not considered
#             'ignoreerrors' - value is not considered, can be anything
#             'type' - children entry types
#             'name' - entry pattern
#             'ext'  - entry extension
#             'casesensitive' - can be any value
#             'caseinsensitive' - can be any value
#      ignoreRC: ignore RC error (in case of negative testing) (Optional)
#
# Results:
#      undef, if the given file/directory is not deleted successfully;
#      stdout of delete operation in case of success, which is
#      usually empty character.
#
# Side effects:
#      User is responsible for the files/directory deleted.
#
########################################################################

sub STAFFSDeleteFileOrDir
{
   my $self = shift;
   my $host = shift;
   my $entry = shift;
   my $opts  = shift || undef;
   my $ignoreRC  = shift || $STAF::kOk;

   if (not defined $host || not defined $entry) {
      $self->{logObj}->Error("Host or entry name not provided to delete");
      return undef;
   }

   # Convert keys in the hash $opts to lower case before any processing
   %$opts = (map { lc $_ => $opts->{$_}} keys %$opts);

   my $command  = "DELETE ENTRY $entry";
   if (defined $opts->{recurse}) {
      $command = $command . " CONFIRM RECURSE";
      delete $opts->{recurse}; # not needed anymore
   } else {
      $command = $command . " CONFIRM";
   }

   if (defined $opts->{ignoreerrors}) {
      $command = $command . " IGNOREERRORS";
      delete $opts->{ignoreerrors};
   }

   if (keys %$opts) { # still more options exits, assume it under CHILDREN
      $command = $command . " CHILDREN";
   }

   for my $key (keys %$opts) {
      $command = $command . " $opts->{$key}";
   }

   my $stafResult = VDNetLib::Common::Utilities::STAFSubmit($self->{handle},
                                                            $host, "FS",
                                                            $command);
   if (($stafResult->{rc} != $STAF::kOk) && ($stafResult->{rc} != $ignoreRC)) {
      $self->{logObj}->Error("Failed to delete $entry on $host");
      $self->{logObj}->Debug("Error:" . Dumper($stafResult));
      return undef;
   }

   return (defined $stafResult->{result}) ? $stafResult->{result} : '';
}


#######################################################################
# RunStafCmdAsync --
#       To run staf Checks if STAF is running or not on the given host
#
# Input:
#       host (optional if SetHostParms is called before)
#       service (supported STAF services like PROCESS, VAR, FS etc)
#       command - command to execute for the given service
#       options - reference to a hash. Currently supported keys are:
#                 'NoShell' - if true, run a process without shell on
#                             any machine, otherwise start process
#                             with shell
#                 'NoWinShell' - if true, run a process without shell on
#                                any windows specifically, otherwise
#                                start process with shell
#
# Results:
#       FAILURE in case of any error
#       SUCCESS if STAF is running on the given HOST
#
# Side effects:
#       None
#
#######################################################################

sub RunStafCmdAsync
{
   my $self    = shift;
   my $host    = shift;
   my $service = shift;
   my $command = shift;
   my $options = shift;

   my $errorString;
   my $data;
   my $result;
   my $entryMap;
   my $mc;

   if (lc($service) eq "process") {
      if ((defined $options->{NoShell} && $options->{NoShell}) ||
          (defined $options->{NoWinShell} && $options->{NoWinShell} &&
          $self->GetOS($host) =~ /win/i)) {
         $vdLogger->Debug("Starting process without shell");
         $command = "start command $command async notify onend " .
                  "returnstdout stderrtostdout";
      } else {
         $command = "start shell command $command async notify onend " .
                    "returnstdout stderrtostdout";
      }
   }

   if ($host eq "localhost" || $host eq "local") {
      $host = "local";
   }

   $result = VDNetLib::Common::Utilities::STAFSubmit($self->{_handle},
			"$host",$service,"$command");

   if (($result->{rc})!=$STAF::kOk) {

      if(defined ($result->{result}) && length($result->{result})!=0){
         $errorString = $result->{result};
         $vdLogger->Error("STAF Error: $errorString ");
         VDSetLastError("ESTAF");
         return FAILURE, $errorString;
      }
   } else {
      if (defined $result->{result}) {
          $mc = STAF::STAFUnmarshall($result->{result});
          $entryMap = $mc->getRootObject();

          if (ref($entryMap) ne "") {
              if ( ($service eq "vm") && ( !defined $data) ) {
                  return SUCCESS, $mc->formatObject();
              }
              $data = $entryMap->{fileList}[0]{data};
              return SUCCESS, $data;
          } else {
              return SUCCESS, $entryMap;
          }
      }
      return SUCCESS, "";
   }
}


#######################################################################
# ProcessResult --
#       This helper function is used to check for standard error
#
# Input:
#       The required argument 'unmarshalledresult' is the unmarshalled
#       result
#       which is processed to extract the any return error
#
# Results:
#       SUCCESS OR FAILURE
#
# Side effects:
#       None
#
#######################################################################

sub ProcessResult
{
   my $mc;
   my $entryMap;

   my ($self, $result) = @_;

   if ( (not defined $result) || ($result eq "") ) {
      $vdLogger->Error("invalid result or empty Result");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $vdLogger->Info(STAF::STAFFormatObject($result->{resultObject},
                                          $result->{resultContext}));
   $mc = STAF::STAFUnmarshall($result);

   $entryMap = $mc->getRootObject();

   my $len = 0;

   $len = length($entryMap->{fileList});

   if ( $len != 0 ) {
      $vdLogger->Error("Could not process the result");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


#######################################################################
# Arch --
#     This helper function is used to get the architecture of the host
#
# Input:
#     The required argument 'unmarshalledresult' is the unmarshalled
#     result
#     which is processed to extract the any return error
#
# Results:
#     Architecture info on SUCCESS OR FAILURE
#
# Side effects:
#       None
#
#######################################################################

sub Arch
{
   my $self = shift;
   my $host = shift;
   my $command;
   my $result;
   my $service;
   my $error;

   if (not defined $host) {
      $vdLogger->Error("Host IP/name not provided to find arch type");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($self->CheckSTAF($host) eq FAILURE) {
      $vdLogger->Error("Arch: STAF is not running on $host");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Do not return self->{ARCH} though it is defined as it might
   # be called for different host $host
   $service = "process";

   $self->{_OS} = $self->GetOS($host);

   $command = "uname \-m" if ($self->{_OS} =~m/linux|esx|vmkernel|BSD/i);

   $command = "systeminfo" if ($self->{_OS} =~ m/win/i);

   $command = $command . " wait returnstdout stderrtostdout";
   $command = "start shell command " . "$command";
   $vdLogger->Debug("Arch: $host $service, $command");

   $result = VDNetLib::Common::Utilities::STAFSubmit($self->{_handle},
				"$host","$service","$command");

   if ( $result->{rc} != $STAF::kOk ) {
      # TODO report the right error
      if (defined ($result->{result}) && length($result->{result})!=0) {
         my $errorString = $result->{result};
         $vdLogger->Error("$errorString ");
      }
      VDSetLastError("ESTAF");
      return FAILURE;
   } else {
      my $mc = STAF::STAFUnmarshall($result->{result});
      my $entryMap = $mc->getRootObject();
      $self->{_ARCH} = $entryMap->{fileList}[0]{data};

      if ( $self->{_OS} =~ m/linux/i ) {
         $self->{_ARCH} = ( $self->{_ARCH} =~ m/64/i ) ? "x86_64" :"x86_32";
      } elsif ($self->{_OS} =~ m/BSD/i) {
         $self->{_ARCH} = "x86_32";
      } elsif ($self->{_OS} =~ m/win/i) {
         $self->{_ARCH} = ( $self->{_ARCH} =~ m/System Type\:\s+x64.*/ )?
                                "x86_64" : "x86_32";
      }
      return ($self->{_ARCH});
   }
}


#######################################################################
# CleanupSTAFHandles --
#       Cleanup staf handles on remote machine (test VM) which has
#       given pattern.
#       1. Do staf $ip process list handles
#       2. If the line starts with handle id, then stop it and free the
#       same
#
# Input:
#       Remote machine's IP address
#
# Results:
#       SUCCESS - this is best effort, we don't care about errors
#
# Side effects:
#       None
#
#######################################################################

sub CleanupSTAFHandles
{
   my $self = shift;
   # remote host from which magic packet has to be sent
   my $host = shift;
   my $pattern = shift;

   my $command;
   my $result;
   my $service;
   my $cmd;
   my $data;
   my $ret;

   if ( (not defined $self->{_handle}) ||
        ((not defined $host) &&
        ((not defined $self->{_host})||($self->{_host} eq "")) ) ) {
      VDSetLastError("EINVALID");
      return FAILURE;
   } elsif ((not defined $host) && (defined $self->{_host}) ) {
      $host = $self->{_host};
   } elsif (defined $host and $host ne "") {
      $ret = VDNetLib::Common::Utilities::IsValidIP($host);

      if ($ret ne "SUCCESS") {
          $vdLogger->Error("Invalid Host parameter supplied");
          VDSetLastError("EINVALID");
          return FAILURE;
       }
   } else {
       $vdLogger->Error("Invalid Host IP supplied to CleanupSTAFHandles");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   $command = "list handles";

   ($result, $data) = $self->runStafCmd($host, "process", $command);

   if ( $result eq FAILURE ) {
      $vdLogger->Error("running $command failed");
      VDSetLastError(VDGetLastError());
      return $result;
   }

   foreach my $item (@$data) {
      if ( $item->{endTimestamp} && ($item->{command} =~ /$pattern/i) ) {
         $vdLogger->Debug("$item->{command}");
         if ( defined $item->{handle} ) {
            $command = "free handle $item->{handle}";
            $vdLogger->Debug("command: $command");
            ($result, $data) = $self->runStafCmd($host, 'process', $command);
           if ( $result eq FAILURE ) {
              $vdLogger->Error("data: $data");
              $vdLogger->Error("command: $command");
              VDSetLastError(VDGetLastError());
              return $result;
           }
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# DirExists --
#       Method to check if the given directory exists on the given host.
#
# Input:
#       <host> host ip where the directory has to be queried (Required)
#       <dir> directory (absolute path) to be checked (Required)
#
# Results:
#       1 - if directory exists; 0 - if directory does not exist
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub DirExists
{
   my $self = shift;
   my $host = shift;
   my $dir = shift;

   if ((not defined $dir) ||
      (not defined $host) ||
      ($dir eq "")) {
      $vdLogger->Error("Insufficient or invalid directory given");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #
   # Staf 'FS' service is used which works independent of OS
   # It is caller's responsibility to give the path in appropriate
   # format
   #
   $dir =~ s/\/$|\\$//; # remove any trailing slash
   $dir =~ s/\\ / /;    # remove any escape \ before empty space
   $dir =~ s/\\\(/\(/;  # remove any escape \ before (
   $dir =~ s/\\\)/\)/;  # remove any escape \ before )
   my $command = "QUERY ENTRY " . "$dir";
   my ($result, $data) = $self->runStafCmd($host,
                                           'FS',
                                           $command);
   if ($result eq FAILURE) {
      if ($data =~ /does not exist/i) {
         return 0;
      } else {
         $vdLogger->Error("Failed to query the given dir $dir on $host:$data");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   if ((ref($data) eq "HASH") &&
      ($data->{name} eq $dir)) {
      return TRUE;
   } else {
      return FALSE;
   }
}


########################################################################
#
# DeleteDir --
#       Deletes the directory specified (recursively) on the given host
#
# Input:
#       <host> host ip where the directory has to be deleted (Required)
#       <dir> directory (absolute path) to be deleted (Required)
#
# Results:
#       "SUCCESS", if the directory is deleted successfully
#       "FAILURE", in case of any error
#
# Side effects:
#       This method doesn't work. Please don't use it. i.e.
#       /directory exists on 10.144.138.233, run below command manually
#       can successfully delete /directory,
#       staf 10.144.138.233 FS DELETE ENTRY '/directory' CONFIRM RECURSE
#       however, call this method will complain "Entry '/directory' does
#       not exist", the message comes from runStafCmd. There is a bug in
#       this call stack.
#
########################################################################

sub DeleteDir
{
   my $self = shift;
   my $host = shift;
   my $dir = shift;

   if ((not defined $dir) ||
      (not defined $host) ||
      ($dir eq "")) {
      $vdLogger->Error("Insufficient or invalid directory given");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #
   # Staf 'FS' service is used which works independent of OS
   # It is caller's responsibility to give the path in appropriate
   # format
   #
   my $command = "DELETE ENTRY " . "'$dir'" . " CONFIRM RECURSE";
   my ($result, $data) = $self->runStafCmd($host,
                                           'FS',
                                           $command);
   if ($result eq FAILURE) {
      $vdLogger->Error("failed to delete the given dir $dir on $host");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# CreateSymlinks --
#       Method to create symlinks using STAF
#
# Input:
#       <host>       - host on which this operation should be done
#                      (Required)
#       <destDir>    - destination directory (absolute path) (Required)
#       <sourceFile> - name of the file to be symlinked (absolute path)
#                      (Required)
#       <symlinkName> - name of symbolic link to <sourceFile>
#                       (Optional)
#
# Results:
#       "SUCCESS", if symlink is created
#       "FAILURE", in case of any error
# Results:
#       None
#
# Side effects:
#       None
#
########################################################################

sub CreateSymlinks
{
   my $self = shift;
   my $host = shift;
   my $sourceFile = shift;
   my $destDir = shift;
   my $symlinkName = shift;

   if ((not defined $host) ||
      (not defined $sourceFile) ||
      (not defined $destDir)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $symlinkName = "" if (not defined $symlinkName);
   my ($command, $result, $data);
   if ($self->GetOS($host) !~ /win/i) {
      $command = "START SHELL COMMAND ln -sf $sourceFile " .
                 " '$destDir/$symlinkName'" .
                 " WAIT RETURNSTDOUT STDERRTOSTDOUT";
      ($result, $data) = $self->runStafCmd($host,
                                           'PROCESS',
                                           $command);

      if (($result eq FAILURE) || ($data ne "")) {
         $vdLogger->Error("Staf error while creating symlink on ".
		"$self->GetOS($host), error:$data");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Not Implemented on this host type");
      VDSetLastError("ENOTIMPL");
      return FAILURE;
   }
}


########################################################################
#
# CopyDirectory --
#       Copies the source directory specified to the destination
#       (within the same host) on the given host
#
# Input:
#       <host> - host on which this operation should be done (Required)
#       <sourceDir> - source directory (absolute path) (Required)
#       <destDir> - destination directory (absolute path) (Required)
#       <sourceFile> - name of any specific file to be copied (Optional)
#
# Results:
#       "SUCCESS", if the directory/file is copied successfully
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub CopyDirectory
{
   my $self = shift;
   my $host = shift;
   my $sourceDir = shift;
   my $destDir = shift;
   my $sourceFile = shift;

   if ((not defined $host) ||
      (not defined $sourceDir) ||
      (not defined $destDir)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my ($command, $result, $data);

   $self->{_OS} = $self->GetOS($host);
   if ($self->{_OS} !~ /win/i) {
      $command = "START SHELL COMMAND cp -r $sourceDir".
                "/". "$sourceFile" . " '$destDir'" .
                 " WAIT RETURNSTDOUT STDERRTOSTDOUT";
      ($result, $data) = $self->runStafCmd($host,
                                           'PROCESS',
                                           $command);

      if (($result eq FAILURE) || ($data ne "")) {
         $vdLogger->Error("Staf error while copying directory ".
		"$sourceDir/$sourceFile to $destDir on ".
		"$self->GetOS($host) error:$data");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Not Implemented on this host type");
      VDSetLastError("ENOTIMPL");
      return FAILURE;
   }
}


########################################################################
#
# GetCommonVmfsPartition --
#       Method to find vmfs partition on esx with largest space
#       available
#
# Input:
#       <host> - esx host ip (Required)
#
# Results:
#       Datastore name (vmfs partition only) on esx with largest space
#       available;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
#######################################################################

sub GetCommonVmfsPartition
{
   my $self = shift;
   my $host = shift;

   if (not defined $host) {
      $vdLogger->Error("Host undefined");
      VDSetLastError("EINVAID");
      return FAILURE;
   }
   #
   # Get the list of vmfs partitions available on the host. This method
   # will
   # return both vmfs and nfs partitions.
   #
   my @volumes = $self->ListVmfsPartitions($host);

   if ($volumes[0] eq FAILURE) {
      $vdLogger->Error("Failed to get the list of vmfs partition $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $largest = undef;
   my $maxsize = 0;

   foreach my $volume (@volumes) {
      # Get the size of each partition.
      my $size = $self->GetVMFSSpaceAvail($host, $volume);

      if ($size eq FAILURE) {
         $vdLogger->Error("Failed to get VMFS space");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      if ($size != 0) {
         $vdLogger->Debug("Volume: $volume has $size MB free space.");
      }
      # Find the vmfs partition with largest size
      if ($size > $maxsize) {
         $largest = $volume;
         $maxsize = $size;
      }

   }
   # Throw error if no vmfs partition is found
   if (not defined $largest) {
      $vdLogger->Error("Couldn't find any vmfs partition on $host");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Debug("Picking $largest which has $maxsize MB free space");
   return $largest;
}


########################################################################
#
# GetVMFSSpaceAvail --
#       Method to get the size of the given partition on esx host.
#
# Input:
#       <host> - esx host ip
#       <vmfsVol> - name of the vmfs volume whose size has to be
#                   determined
#
# Results:
#       Size of the vmfs volume, size of nfs partition/read-only
#       partition are returned as zero;
#       "FAILURE" , in case of any error
#
# Side effects:
#       None
#
########################################################################

sub GetVMFSSpaceAvail
{
   my $self =  shift;
   my $host = shift;
   my $vmfsVol = shift;

   if ((not defined $host) ||
      (not defined $vmfsVol)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVAID");
      return FAILURE;
   }

   my $cmd = "START SHELL COMMAND vmkfstools -P '/vmfs/volumes/$vmfsVol' ".
             "WAIT RETURNSTDOUT STDERRTOSTDOUT";

   my ($result, $output) = $self->runStafCmd($host, 'PROCESS', $cmd);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to execute Staf command:$cmd on $host, ".
                   "error:$output");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #
   # Regex to get the version X from the string
   # "NFS-X.yy file system spanning Z partitions"
   #
   if ($output =~ /NFS-([\d.]+) file system/mg) {
      # Ignore NFS partitions by returning size as 0
      return 0;
   }
   #
   # Regex to get the version X from the string
   # "VMFS-X.yy file system spanning Z partitions"
   #
   my ($vmfsversion) = $output =~ /VMFS-([\d\.]+) file system/mg;
   if ($vmfsversion && $vmfsversion < 3) {
      $vdLogger->Error("VMFS Version is $vmfsversion. This file systemis " .
                       "readonly");
      return 0;
   }
   #
   # Regex to read the numbers X,Y from the string
   # "Capacity <size1> (<num1> file blocks * <num2>), X (Y blocks) avail"
   #
   if ($output =~ /\((\d+) file blocks \* (\d+)\), \d+ \((\d+) blocks\) avail/mg) {
      $vdLogger->Debug("Capacity $1 blocks with block size of $2, Space available: $3 blocks on $vmfsversion");
      if ($vmfsversion) {
         return ($2*$3/VMFS_BLOCK_SIZE);
      } else {
         return 0;
      }
   } else {
      $vdLogger->Debug("Unable to retrieve info about vmfs volume $vmfsVol");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
#
# ListVmfsPartitions --
#       Method to list all partitions (includes nfs, vmfs etc) on esx
#       host
#
# Input:
#       <host> - esx host ip, other OS/ host type will return error
#
# Results:
#       An array of datastores on the esx host;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub ListVmfsPartitions
{
   my $self = shift;
   my $host = shift;
   if (not defined $host) {
      $vdLogger->Error("Host undefined");
      VDSetLastError("EINVAID");
      return FAILURE;
   }
   my @return = ();
   #
   # Using STAF FS service to list datastores on esx. On esx, the
   # datastores
   # are always under the directory /vmfs/volumes
   #
   my $cmd = "LIST DIRECTORY /vmfs/volumes LONG DETAILS";
   my ($result, $directories) = $self->runStafCmd($host, 'FS', $cmd);
   foreach my $dir (@$directories) {
      if (defined $dir->{'linkTarget'}) {
         push @return, $dir->{'name'};
      }
   }
   return @return;
}


########################################################################
#
# GetEnvVar --
#       Gets the value of given env var on the remote machine using
#       STAF VAR service.  Note: This method is not tested yet.
#
# Input:
#       <ip> - IP address of the remote machine
#       <OS> - OS type of the remote machine
#       <envVar> Name of the environment variable
#
# Results:
#       -1 if the env var doesn't exist
#       SUCCESS and env var's value if it exists
#       "FAILURE", "error code, if applicable" in case of any other
#       error
#
# Side effects:
#       None
#
########################################################################

sub GetEnvVar
{
   my $self = shift;
   my $IP = shift;
   my $envVar = shift;

   if ((not defined $IP) || (not defined $envVar)) {
      $vdLogger->Error("One or more params are undefined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $service = "VAR";
   my $command = "GET SYSTEM VAR STAF/ENV/$envVar";

   $vdLogger->Debug("$IP, $service, $command");

   my $result = VDNetLib::Common::Utilities::STAFSubmit($self->{_handle},$IP,
			$service, $command);

   if ($result->{rc} == 13) { # env var doesn't exist
      return -1;
   } elsif (($result->{rc} != 13) &&
            ($result->{rc} != $STAF::kOk)) {
      VDSetLastError("ESTAF");
      return (FAILURE, $result->{rc});
   } else {
      return (SUCCESS, $result->{result});
   }
}


########################################################################
#
# CleanSTAFHelper --
#      Method to unregister the staf handle created for this object
#
# Input:
#      None
#
# Results:
#      None
#
# Side effects:
#     The given STAFHelper object will not be functional anymore
#
########################################################################

sub CleanSTAFHelper
{
   my $self = shift;

   if (defined $self->{handle}) {
      $self->{logObj}->Debug("Deleting staf handle $self->{handle}");
      $self->{handle}->unRegister();
      $self->{handle} = undef;
   }
}


########################################################################
#
# SSHSyncProcess --
#     Method to execute process on remote machine using SSH
#     and adhere output similar to STAFSyncProcess()
#
# Input:
#     host     : host IP address
#     command  : command to executed on given ip address
#     timeout  : timeout to execute the command
#     sshHost  : reference to VDNetLib::Common:SshHost
#
# Results:
#     reference to a hash with following keys
#      'rc': 0 if command executed successfully, positive integer which
#            represents ssh error,
#      'exitCode': return code from the process executed
#      'stdout': stdout from the process/command executed
#      'stderr': stderr from the process/command executed
#
# Side effects:
#     None
#
########################################################################

sub SSHSyncProcess
{
   my $self    = shift;
   my $host    = shift;
   my $command = shift;
   my $timeout = shift;
   my $sshHost = shift;

   my $opts = {
      'timeout'   => $timeout,
   };
   my ($retValue, $stdout) = $sshHost->SshCommand($command);
   my $out = join("", @$stdout);
   my ($rc, $exitCode);
   # Due to Bug: 1106219, we replaced
   # OSSH_SLAVE_CMD_FAILED with "5" and
   # removed the use of the OpenSSH Package
   # use Net::OpenSSH::Constants qw (OSSH_SLAVE_CMD_FAILED);
   if ($retValue == "5") {
      $rc = 0;
      $exitCode = $1 if($retValue =~ /child exited with code (\d+)/i);
   } elsif ($retValue =~ /master ssh connection broken/i) {
      $vdLogger->Trace("Re-establishing ssh session for host $host");
      $sshHost->Initialize();
      return $self->SSHSyncProcess($host, $command, $timeout, $sshHost);
   } else {
      $rc = $retValue;
      $exitCode = 0;;
   }
   my $result = {
      'rc'       => $rc,
      'exitCode' => $exitCode,
      'stdout'   => $out,
      'stderr'   => undef,
   };
   return $result;
}

########################################################################
#
# Destroy --
#      Perl's default garbage handler.
#
# Input:
#      None
#
# Results:
#      None (deletes the staf handle corresponding to the current
#      object.
#
# Side effects:
#      The object will not be usable anymore.
#
########################################################################

sub Destroy
{
   my $self = shift;
   $self->CleanSTAFHelper();
}


###############################################################################
#
# STAFCopyDirectory
#      This method will check if there is file under one directory in remote
#      or local machine. If yes, copy them to dest directory. This function is
#      implemented to replace STAFFSCopyDirectory since hang occurs sometimes
#      for it.
#
# Input:
#      srcDir : source directory on host (mandatory). This is absolute path.
#      dstDir : destination directory name on MC (mandatory) This is not absolute
#               path, just directory name under vdnet log directory
#      srcIP : IP address of directory source (mandatory)
#      isRemoveNeeded : after copy finished, if we need remove files from source
#                       (optional) By default it is 0, means not remove
#
# Results:
#      SUCCESS: file copy successful
#      FAILURE: in case any error
#
# Side effects:
#      None.
#
###############################################################################

sub STAFCopyDirectory
{
   my $self = shift;
   my %args = @_;
   my $srcDir = $args{srcDir};
   my $dstDir = $args{dstDir};
   my $srcIP = $args{srcIP};
   my $isRemoveNeeded = $args{isRemoveNeeded};
   my $result;
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();

   if ((not defined $srcDir) || (not defined $dstDir) || (not defined $self)) {
      $vdLogger->Error("Directory names or staf helper not defined for copy operation");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $isRemoveNeeded) {
      $isRemoveNeeded = 0;
   }
   if (substr($srcDir, -1) ne "/") {
      $srcDir .= "/";
   }

   my $cmd = "find $srcDir -type f";
   $result = $self->STAFSyncProcess($srcIP, $cmd);
   $vdLogger->Debug("On machine $srcIP $cmd returns " . Dumper($result));

   # Process the result
   if (($result->{rc} ne 0) || ($result->{exitCode} ne 0)) {
      $vdLogger->Info("No file under $srcDir on $srcIP");
      return SUCCESS;
   } elsif ($result->{stdout} eq "") {
      $vdLogger->Info("No file under $srcDir on $srcIP");
      return SUCCESS;
   }

   my @fileList = split (/\n/, $result->{stdout});

   `mkdir -p $dstDir` if (!(-e "$dstDir"));

   foreach my $file (@fileList) {
      my $srcFile = "$file";
      my $filename = substr($srcFile, length($srcDir));
      my $dstFile = "$dstDir/$filename";
      my $logFilePath = substr($dstFile, 0, rindex($dstFile, '/'));
      `mkdir -p $logFilePath` if (!(-e "$logFilePath"));
      $result = $self->STAFFSCopyFile($srcFile, $dstFile,
                                            $srcIP, $localIP);
      if ($result != 0) {
         $vdLogger->Error("Failed to copy $srcFile file " .
                       " to $dstFile");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }
   }
   if ($isRemoveNeeded eq "0") {
      return SUCCESS;
   }

   $cmd = "rm -rf $srcDir*";
   $result = $self->STAFSyncProcess($srcIP, $cmd);
   # Process the result
   if (($result->{rc} ne 0) || ($result->{exitCode} ne 0)) {
      $vdLogger->Error("Command $cmd failed on machine $srcIP " . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetGuestInterfaceFromIP --
#       Method to get the guest VM's interface name corresponding to the
#       given IP address.
#
# Input:
#       <IP> - ip address of specific adapter whose name is needed
#
# Results:
#       Adapter name corresponding to the given IP, or
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub GetGuestInterfaceFromIP
{
   my $self = shift;
   my $IP = shift;
   my $cmd = "ifconfig | grep -B1 $IP | head -n1 | awk '^{print \$1}'";
   my $result = $self->STAFSyncProcess($IP, $cmd);
   # Process the result
   if (($result->{rc} ne 0) || ($result->{exitCode} ne 0)) {
      $vdLogger->Error("Command $cmd failed on machine $IP " . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   chomp($result->{stdout});
   return $result->{stdout};
}
1;
