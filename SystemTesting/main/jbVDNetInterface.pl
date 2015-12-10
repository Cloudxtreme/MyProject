#!/usr/bin/perl
# Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
#
# JBVDNetInterface.pl --
# This perl script works as interface between FTAuto.py and vdNet.pl
# Given the server and/or client shared var name, this script waits to get
# the guest IP address written to this shared variable. Once the guest IP is
# known, vdNet automation directory is mounted inside the guest(s) and the user
# specified workload is run inside the guest
#
use strict;
use warnings;
use Socket;
use Sys::Hostname;
use Getopt::Long;
use VDNetLib::Common::STAFHelper;

use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);
use constant EXIT_FAILURE => 1;
use constant EXIT_SUCCESS => 0;
use constant BOOTTIME => 90;
use constant SLEEPTIME => 5;
use constant DEFAULT_GUEST_TIMEOUT => 300;
my $childPID;


#--------------------------------------------------------------------
# Log --
#     This routine prints the given message prefixed by 'JBVDNet::'
# Input:
#     Any string that usually passed to print statements
# Output:
#     Given string prefixed by JBVDNet::<string>
# Side effects:
#     None
#--------------------------------------------------------------------

sub Log
{
   print STDOUT "JBVDNet:: @_";
}

#--------------------------------------------------------------------
# INT_handler --
#     Routine to handle SIGINT signal sent to this script
# Input:
#     None
# Output:
#     The child process created in JBVDNetInterface will be killed
# Side effects:
#     None
#--------------------------------------------------------------------

sub INT_handler {
   if (defined $childPID) {
      Log "Signal handler called\n";
      Log "Kill all child processes called at JBVDNet!\n";
      kill 9,$childPID;
   }
   Log "Quit running JBVDNetInterface script\n";
   exit EXIT_FAILURE;
}
$SIG{'TERM'} = 'INT_handler';
$SIG{'INT'} = 'INT_handler';

#--------------------------------------------------------------------
# GetLocalIP --
#     This routine gives the ip address of the host on which this
#     script is running
# Input:
#     None
# Output:
#     IP address of the local host
# Side effects:
#     None
#--------------------------------------------------------------------

sub GetLocalIP
{
   my $host = hostname();
   my $addr = inet_ntoa(scalar gethostbyname($host ||
                           'localhost'));
   return ($addr =~ /[0-9].+/) ? $addr : FAILURE;
}

#--------------------------------------------------------------------
# GetGuestIP --
#     This routine reads the staf shared variable specific to
#     server and client VM to get their IP address. The server and
#     client VMs are expected to write their IP address to the
#     specified shared variable on this host
# Input:
#     <stafHandle> - staf handle on the host to run staf VAR service
#     <varName> - shared variable name to read
#     <timeout> - timeout value in secs,
#                 max time to get guest's ip address
# Output:
#     IP address of the guest which writes to the given shared
#     variable; 'FAILURE' in case of timeout or other errors
# Side effects:
#     None
#--------------------------------------------------------------------

sub GetGuestIP
{
   my $stafHandle = shift;
   my $varName = shift;
   my $timeout = shift;
   my $guestIP;
   my $ret;

   if ((not defined $stafHandle) ||
      (not defined $varName) ||
      (not defined $timeout)) {
      Log "Insufficient parameters\n";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $command = "get shared var $varName";
   my $sleeptime = SLEEPTIME;
   Log "Waiting to get guest IP, handle \"$varName\"...\n";
   while (((not defined $guestIP) ||
         ($guestIP !~ /[0-9].+/)) &&
         ($timeout > 0)) {
      ($ret,$guestIP) = $stafHandle->runStafCmd('local', 'var', $command);
      $timeout = $timeout - $sleeptime;
      sleep($sleeptime);
   }
   if ($timeout <= 0) {
      Log "Hit timeout to get guest IP\n";
      return FAILURE;
   }
   return $guestIP;
}


#--------------------------------------------------------------------
# WriteSharedVar --
#     This routine writes the given string to the given staf shared
#     var name.
# Input:
#     <stafHandle> - staf handle on the host to run staf VAR service
#     <varName> - shared variable name to write
#     <msg> - string to write to the shared variable
# Output:
#     SUCCESS, if the given string is successfully written to the
#     shared variable
#     'FAILURE', in case of any error
# Side effects:
#     None
#--------------------------------------------------------------------

sub WriteSharedVar
{

   my $stafHandle = shift;
   my $varName = shift;
   my $msg = shift;
   my $guestIP;

   if ((not defined $stafHandle) ||
      (not defined $varName) ||
      (not defined $varName)) {
      Log "Insufficient parameters\n";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $command = "set shared var $varName=$msg";
   $guestIP = $stafHandle->runStafCmd('local', 'var', $command);
   if ($guestIP eq FAILURE) {
      Log VDGetLastError() . "\n";
      return FAILURE;
   }
   return SUCCESS;
}

#--------------------------------------------------------------------
# DeleteSharedVar --
#     This routine deletes the given staf shared variable
# Input:
#     <stafHandle> - staf handle on the host to run staf VAR service
#     <varName> - shared variable name to delete
# Output:
#     'SUCCESS', if the given shared variable string is
#        successfully deleted
#     'FAILURE', in case of any error
# Side effects:
#     None
#--------------------------------------------------------------------

sub DeleteSharedVar
{

   my $stafHandle = shift;
   my $varName = shift;
   my $guestIP;

   if ((not defined $stafHandle) ||
      (not defined $varName)) {
      Log "Insufficient parameters\n";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $command = "delete shared var $varName";
   $guestIP = $stafHandle->runStafCmd('local', 'var', $command);
   if ($guestIP eq FAILURE) {
      Log VDGetLastError() . "\n";
      return FAILURE;
   }
   return SUCCESS;
}

#--------------------------------------------------------------------
# MountTestDir --
#     Routine to mount the test directory on the guest before running
#     any test
# Input:
#     <host> - ip address of the host/guest on which the given
#        directory should be mounted
#     <stafHandle> - staf handle to run STAF Process service
#     <testdir> - the test directory to mount on the given machine
# Output:
#     'SUCCESS'. if the given directory is successfully mounted inside
#        the guest
#     'FAILURE', in case of any error
# Side effects:
#     None
#--------------------------------------------------------------------

sub MountTestDir
{
   my $host = shift;
   my $stafHandle = shift;
   my $testdir = shift; # example \\10.20.84.51\automation
   my $ret;
   my $data;
   my $command;

   if ((not defined $host) ||
      (not defined $stafHandle)) {
      Log "Insufficient parameters\n";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $remoteOS = $stafHandle->GetOS($host);
   if ($remoteOS eq FAILURE) {
      Log "Error returned while retreiving $host OS information\n";
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   Log "OS is $remoteOS\n";
    if ($remoteOS =~ /win/i) {
       $command = "start shell command net parms \"use m:\" " .
                  "wait returnstdout stderrtostdout";
       Log "Check existing mapped drive M: on $host\n";
       ($ret,$data) = $stafHandle->runStafCmd($host, 'process', $command);
       if ($ret eq FAILURE) {
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }
       if ($data !~ /success/i) {
          Log "Nothing mapped on M:\n";
       } else {
          $command = "start shell command net parms \"use m: /delete\" " .
                     "wait returnstdout stderrtostdout";
          Log "Unmounting existing mapped drive M: on $host\n";
          ($ret,$data) = $stafHandle->runStafCmd($host, 'process', $command);
          if ($ret eq FAILURE) {
             VDSetLastError(VDGetLastError());
             return FAILURE;
          }
          if ($data !~ /success/i) {
             Log "Unmount error: $data\n";
             VDSetLastError("EOPFAILED");
             return FAILURE;
          }
       }
       # Now mount the test directory
       Log "Mapping \\\\10.20.84.51\\automation to M: on $host\n";
       $command = "net use m: \\\\10.20.84.51\\automation";
       $command = STAF::WrapData($command);
       $command = "start shell command $command wait returnstdout " .
                  "stderrtostdout";
       ($ret,$data) = $stafHandle->runStafCmd($host, 'process', $command);
       if ($ret eq FAILURE) {
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }
       if ($data !~ /success/i) {
          Log "mount error: $data\n";
          VDSetLastError("EOPFAILED");
          return FAILURE;
       }
    } elsif ($remoteOS =~ /linux/i) {
       $command = "start shell command mount " .
                  "wait returnstdout stderrtostdout";
       Log "Check existing mount on \/automation on $host\n";
       ($ret,$data) = $stafHandle->runStafCmd($host, 'process', $command);
       if ($ret eq FAILURE) {
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }
       # TODO remove hard coding
       if ($data !~ /10.20.84.51:\/automation/i) {
          Log "Nothing mounted on \/automation\n";
       } else {
          $command = "start shell command umount parms \"\/automation\" " .
                     "wait returnstdout stderrtostdout";
          Log "Unmounting existing sharepoint on $host\n";
          ($ret,$data) = $stafHandle->runStafCmd($host, 'process', $command);
          if ($ret eq FAILURE) {
             VDSetLastError(VDGetLastError());
             return FAILURE;
          }
          if (($data ne "") &&
             ($data !~ /not mounted/)) {
             Log "Unmount error: $data\n";
             VDSetLastError("EOPFAILED");
             return FAILURE;
          }
       }
       # Now mount the test directory
       Log "Mounting 10.20.84.51:\/automation to \/automation on $host\n";
       $command = "mount 10.20.84.51:\/automation \/automation";
       $command = STAF::WrapData($command);
       $command = "start shell command $command wait returnstdout " .
                  "stderrtostdout";
       ($ret,$data) = $stafHandle->runStafCmd($host, 'process', $command);
       if ($ret eq FAILURE) {
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }
       if ($data ne "") {
          Log "mount error: $data\n";
          VDSetLastError("EOPFAILED");
          return FAILURE;
       }
    } else {
       Log "$host returned unknown os\n";
       VDSetLastError("EOSNOTSUP");
       return FAILURE;
    }
}

#----------------------------------------------------------------
# ExitRoutine ---
#    Sub-routine to decide whether to shutdown the guest or return
#    'FAILURE', or re-start test in case of success and failure.
#    If the given exit method is FTAuto (FTA),
#       The VM is shutdown on any error,
#       Runs the given test again in case of no error
#    If the given exit method is ReplayAuto (RA),
#       The VM is shutdown if the test completes successfully,
#       Returns FAILURE in case of any error which will not
#       shutdown the guest
# Input:
#     <result> - pass or fail
#     <stafHandle> - staf handle to execute shutdown command on
#                    the guest if needed
#     <host> - host ip address
#     <exitMethod> - RA or FTA
# Output:
#    'SUCCESS', if the operation required based on exit method is
#               performed without any error
#    'FAILURE', in case the test failed or any error
# Side effects:
#     The given guest might be shutdown depending the exit method
#     specified
#----------------------------------------------------------------

sub ExitRoutine
{
   my $result = shift;
   my $stafHandle = shift;
   my $host = shift;
   my $exitMethod = shift;
   my $command;

   if ((not defined $result) ||
      (not defined $stafHandle) ||
      (not defined $host) ||
      (not defined $exitMethod)) {
      Log "Insufficient parameters\n";
      return FAILURE;
   }
   Log "exit routine called, result:$result\n";
   my $OSTYPE = $stafHandle->GetOS($host);
   if ($OSTYPE eq FAILURE) {
      Log "Error returned while retreiving $host OS information\n";
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ((($result =~ /pass/i) &&
      ($exitMethod =~ /RA/i)) ||
      (($result =~ /fail/) &&
      ($exitMethod =~ /FTA/i))) {
      Log "Shutting down the machine $host\n";
      if ($OSTYPE =~ /Win/i) {
         $command = "start c:\\windows\\system32\\shutdown.exe /f /s /t 0";
      } elsif ($OSTYPE =~ /linux/i) {
         $command = "\/sbin\/shutdown now -h";
      } else {
        Log "Unknown OS:$OSTYPE\n";
      }
      $command = STAF::WrapData($command);
      $command = "start shell command $command";

      my ($returnVal,$data) = $stafHandle->runStafCmd($host,'process',$command);
      if ($returnVal eq FAILURE) {
         Log "Failed to shutdown:$data, Kill manually\n";
         return FAILURE;
      }
   } elsif (($result =~ /pass/i) &&
           ($exitMethod =~ /FTA/i)) {
       Log "Exiting now without shutting down the VMs\n";
       return SUCCESS;
   } elsif (($result =~ /fail/) &&
       ($exitMethod =~ /RA/i)) {
      Log "Did not shutdown the VM since test failed\n";
      return FAILURE;
   }
   return SUCCESS;
}

# Main routine starts here --------------------
my $usage = "[-s serverHandle] -c <clientHandle> -t <testname> " .
            "[-d testdevice] -e <exitCondition> [-hip hostIP]\n" .
"command-options:
   Short        Long       Takes
   form         form       value?         Description
   -i      --iterations      y      Number of iterations to run
   -s      --serverhandle    y      handle/shared var name used for server
   -c      --clienthandle    y      handle/shared var name used for client
   -t      --testname        y      Name of the test to run
   -d      --testdevice      y      Name of the test device
                                    (e1000/vmxnet2/vmxnet3)
   -g      --guesttimeout    y      Timeout value to wait for guest to send
                                    it's ip address
   -e      --exitmethod      y      Exit method to use (RA/FTA)
   -hip    --hostip          y      host ip address
   -h      --help            n      This help message

\n";

my $result;
my $serverIP;
my $clientIP;
my $iteration = 0;
my $maxIterations = 1;
my ($hostIP, $serverHandle,
    $clientHandle, $testDevice,
    $testName, $exitMethod);
my $guestTimeout = DEFAULT_GUEST_TIMEOUT; # default to 300s
my $tempSharedVar = 'JBVDNetStatus';

$result = GetOptions (
                   "hostip|hip=s"      => \$hostIP,
                   "iterations|i=s"    => \$maxIterations,
                   "serverhandle|s=s"  => \$serverHandle,
                   "clienthandle|c=s"  => \$clientHandle,
                   "testdevice|d=s"    => \$testDevice,
                   "testname|t=s"      => \$testName,
                   "guesttimeout|g=s"      => \$guestTimeout,
                   "exitmethod|e=s"    => \$exitMethod,
                   "help|h"            => sub { Log $usage;
                                               exit EXIT_FAILURE;},
                     );

if ((not defined $clientHandle) ||
   (not defined $testName) ||
   (not defined $exitMethod)) {
   Log "Insufficient parameters passed\n";
   Log $usage;
   exit EXIT_FAILURE;
}

#
# check if exit method is either RA - ReplayAuto or
# FTA - FTAuto
#
if ($exitMethod !~ /RA|FTA/i) {
   Log "Unknown exit method passed:$exitMethod\n";
   Log $usage;
   exit EXIT_FAILURE;
}
Log "Starting JBVDNet script\n";
# Get Host IP address if not provided
if (not defined $hostIP) {
   if (($hostIP = GetLocalIP()) eq FAILURE) {
      Log "Failed to get local host ip address:$?\n";
      exit EXIT_FAILURE;
   }
   Log "Host IP address:$hostIP\n";
}
# Get a STAF Handle to execute all staf operations to communicate between the
# host and the guest(s)
my $stafHandle = VDNetLib::STAFHelper->new();
if ($stafHandle eq FAILURE) {
   Log "Failed to get a STAF handle\n";
   Log VDGetLastError() . "\n";
   exit EXIT_FAILURE;
}
# Before reading the shared variable used between the client VM and the host,
# delete the variable to make sure no stale information is read. Guest
# continuously writes to this shared variable
if (DeleteSharedVar($stafHandle,$clientHandle) eq FAILURE) {
   Log "Error: " . VDGetLastError() . "\n";
}

# Delete the staf shared variable used by the server VM and the host
if (defined $serverHandle) {
   if (DeleteSharedVar($stafHandle,$serverHandle) eq FAILURE) {
      Log "Error: " . VDGetLastError() . "\n";
   }
}

START:

   Log "Total JBVDnet Iterations: $maxIterations\n";
   $iteration = $iteration + 1;
   Log "*** JBVDnet Iteration $iteration ***\n";
   if (1 == $iteration) {
      Log "Waiting " . BOOTTIME . " sec for the VM(s) to boot\n";
      sleep(BOOTTIME);
   }

# TODO close the staf handle, ask VDNetLib::STAFHelper to implement close()

# Read the shared variable given as input to get the IP address of the server
# and client VMs
if (defined $serverHandle) {
   $serverIP = GetGuestIP($stafHandle, $serverHandle, $guestTimeout);
   if ($serverIP eq FAILURE) {
      Log "Failed to get server IP address\n";
      exit EXIT_FAILURE;
   }
   Log "server ip address: $serverIP\n";
   if (DeleteSharedVar($stafHandle,$serverHandle) eq FAILURE) {
      Log "Error: " . VDGetLastError() . "\n";
   }
}

$clientIP = GetGuestIP($stafHandle, $clientHandle, $guestTimeout);
if ($clientIP eq FAILURE) {
   Log "Failed to get client IP address\n";
   exit EXIT_FAILURE;
}

Log "Client ip address: $clientIP\n";
if (DeleteSharedVar($stafHandle,$serverHandle) eq FAILURE) {
   Log "Error: " . VDGetLastError() . "\n";
}

#TODO, for now serverIP is clientIP if server is not defined
if (not defined $serverHandle) {
   $serverIP = $clientIP;
}

if ($iteration == 1) {
   # Now mount the test directory inside the server
   if (defined $serverHandle) {
      if (&MountTestDir($serverIP,$stafHandle) eq FAILURE) {
         Log "Error mounting test directory\n";
         Log VDGetLastError();
         &ExitRoutine('fail', $stafHandle,$serverIP,$exitMethod);
         exit EXIT_FAILURE;
      }
   }

   # Now mount the test directory inside the client
   if (&MountTestDir($clientIP,$stafHandle) eq FAILURE) {
      Log "Error mounting test directory\n";
      Log VDGetLastError();
      &ExitRoutine('fail', $stafHandle,$clientIP,$exitMethod);
      exit EXIT_FAILURE;
   }
}

# Now run vdNet.pl  using information collected above
#
# TODO - remove all hardcoded paths
my $command = "perl //automation//main//vdNet.pl -s -i \"$clientIP,$hostIP\" " .
              "-i \"$serverIP,$hostIP\" -t $testName -resultfile /vdlog 2>&1";
Log "executing command " . $command ."\n";

my $returnVal;
# Using fork to get the process id of the child, otherwise system() does not
# provide any information about the child's process id
#
unless ($childPID = fork()) {
   $returnVal = exec($command);
}
Log "Started a child process, pid:$childPID\n";
$returnVal = wait();
# Get the exit status of the child process
$returnVal = $?;
$result = ($returnVal == 0) ? "pass" : "fail";

if ($iteration >= $maxIterations) {
   Log "Reached max iterations, closing the test\n";
   if (defined $serverHandle) {
      &ExitRoutine($result, $stafHandle, $serverIP, $exitMethod);
   }
   &ExitRoutine($result, $stafHandle, $clientIP, $exitMethod);
} else {
   goto START;
}

if ($result =~ /pass/i) {
   exit EXIT_SUCCESS;
} else {
   exit EXIT_FAILURE;
}
