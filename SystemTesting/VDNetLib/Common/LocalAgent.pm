#!/usr/bin/perl -w
########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Common::LocalAgent;

# VDNetLib::Common::LocalAgent.pm
# This is a helper program which calls *REMOTE* methods/functions
# in a package based on the input to ExecuteRemoteMethod()
# STAF's Process service cannot execute remote methods.
# This package makes using remoteAgent.pl to call remote methods (somewhat
# similar to RPC implementation).
#
# remoteAgent.pl code resides on the remote machine where a method has to be
# called. LocalAgent.pm resides on the machine in which applications call
# remote methods.
# The return values, error codes from a method are sent back to LocalAgent.pm
# from remoteAgent.pl using shared variable provided by STAF's VAR service.

use strict;
use base 'Exporter';
use PLSTAF;
use Data::Dumper;
our @EXPORT = qw( ExecuteRemoteMethod );
use VDNetLib::Common::VDErrorno qw ( FAILURE SUCCESS VDGetLastError VDSetLastError );
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_STATIC_HANDLE);
use VDNetLib::Common::VDLog;


########################################################################
#
# ExecuteRemoteMethod --
# This function calls the remoteAgent.pl on the test machine with the
# method to execute as argument.
# Once executed, it collects the result from the remote process using staf
# shared variable
#
# Input:
#       targetIP - control IP address of the remote test machine
#       methodName - method to be executed on the remote machine
#       methodArgs - arguments to be passed along with the method call
#       timeout - timeout value for the process to complete
#
# Results:
#       returns the appropriate values (strings, arrays, references, etc)
#       as returned by the actual method implementation in NetDiscover.pm
#
# Side effects:
#       refer to netDisover.pm
#
########################################################################

sub ExecuteRemoteMethod
{
   my $targetIP = shift;        # required, remote machine's IP
   my $methodName = shift;      # required, NetAdapter method to call
   my $methodArgs = shift;      # optional, argument to pass with above method
   my $timeout = shift || VDNetLib::Common::GlobalConfig::STAF_CALL_TIMEOUT;
   my $request;
   my $result;
   my $processResult;
   my $ostype;
   # Create staf handle to launch discover.pl on remote machine
   # and retrieve STDOUT
   if (not defined $methodName) {
      $vdLogger->Error("No method name provided to ExecuteRemoteMethod");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $targetIP) {
       $vdLogger->Error("Target IP for running method $methodName is not " .
                        "defined");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my $handle = $STAF_STATIC_HANDLE;

   if (not defined $handle) {
      $vdLogger->Error("No staf handle defined");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check connectivity with remote machine using STAF ping service
   my $stafStatus = 1;
   my $startTime = time();

   while ($timeout && $startTime + $timeout > time() && $stafStatus != 0) {
      $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$targetIP, "ping", "ping");
      $stafStatus = $result->{rc};
      sleep 10 if $stafStatus;
   }

   if ($stafStatus) {
      $vdLogger->Error("Error on STAF  ping $targetIP");
      $vdLogger->Error("Expected RC: 0");
      $vdLogger->Error("Received RC: $result->{rc}, Result: $result->{result}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $request = "RESOLVE STRING {STAF/Config/OS/Name}";

   $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$targetIP, "VAR", $request);
   if ($result->{rc} != $STAF::kOk) {
      $vdLogger->Error("Error on staf var resolving string $request");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{result} =~ /Win/i)  {
      $ostype = 2;
   } elsif ($result->{result} =~ /Linux|vmkernel/i) {
      $ostype = 1;
   } elsif ($result->{result} =~ /bsd/i) {
      $ostype = VDNetLib::Common::GlobalConfig::OS_BSD ;
   } else {
      $vdLogger->Error("Unsupported OS type $result->{result}");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   my $command;
   my $script;
   my $agent;
   my $np = new VDNetLib::Common::GlobalConfig;
   if ($result->{result} =~ /Linux/i) {
      # Use the pl file until we write a removeAgent.bat for Windows
      $script = "main";
      $agent = "remoteAgent";
   } else {
      $script = "scripts";
      $agent = "remoteAgent.pl";
   }

   my $testCodePath = $np->TestCasePath($ostype, $script);
   if (not defined $testCodePath) {
      $vdLogger->Error("Test Code Path undefined");
      VDSetLastError("ENOENT");
      return FAILURE;
   }

   $command = "$testCodePath" . $agent;
   my $args = "-m " . $methodName;
   #Escape the start { for $methodArgs with ^  to avoid STAF subtitution for VAR
   if (defined $methodArgs && $methodArgs =~ /^\{/) {
      $methodArgs = "^".$methodArgs;
   }

   if (defined $methodArgs) {
      $args = $args . " -p ". $methodArgs;
   }

   my @timeStamp = localtime(time);
   #
   # Create parent shared variable name with timestamp and pid appended.
   # variable $$ gives process id. pid is used to avoid conflict when running
   # multiple processes which could create same shared variable name.
   #
   my $sharedVarName = "$methodName-$timeStamp[2]-$timeStamp[1]-" .
                       "$timeStamp[0]-" . $$;
   my $errVar = "$methodName-ERR-$timeStamp[2]-$timeStamp[1]-$timeStamp[0]" .
                $$;

   # Submit a PROCESS START request and wait for it to complete
   $timeout = $timeout * 1000; # STAF PROCESS service by default assumes give
                               # timeout value as millisecs.
   $request = "START SHELL COMMAND ".STAF::WrapData($command).
      " PARMS " . "\"" . $args . "\"" . " RETURNSTDOUT STDERRTOSTDOUT WAIT $timeout " .
      "ENV PARENT_SHARED_VAR=". $sharedVarName . " ENV PARENT_SHARED_ERR=" .
      $errVar . " ENV VDNET_LOGLEVEL=" . VDNetLib::Common::VDLog::TRACE .
      " ENV VDNET_LOGTOFILE=0" . " ENV VDNET_VERBOSE=1";

   # Executing command:$request
   $vdLogger->Trace("Executing $request on $targetIP");
   $processResult = VDNetLib::Common::Utilities::STAFSubmit($handle,$targetIP, "PROCESS", $request);

   if ($processResult->{rc} != $STAF::kOk) {
      $vdLogger->Error("Error on STAF local PROCESS $request");
      $vdLogger->Error("Received RC: $processResult->{rc}, Result: $processResult->{result}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $mc = STAF::STAFUnmarshall($processResult->{result});

   #
   # log the stdout from remoteAgent.pl
   # Do NOT remove this block PR822907
   #
   if (defined $mc->{rootObject}->{fileList}[0]->{data}) {
      $vdLogger->Debug(Dumper($mc->{rootObject}->{fileList}[0]->{data}));
   }
   if ($mc->{rootObject}->{rc} != 0) {
      $vdLogger->Error("Error while executing remote method $methodName " .
                       "with args " . Dumper($methodArgs) . " on $targetIP, Exit code:" .
                       "$mc->{rootObject}->{rc} returned");
      if (defined $mc->{rootObject}->{fileList}[1]->{data}) {
         $vdLogger->Debug("ERROR" .
                          Dumper($mc->{rootObject}->{fileList}[1]->{data}));
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # Get the output of the module executed above. The remote module
   # will store the return value in the shared variable $sharedVarName
   # Read the return value using STAF's VAR service
   my $getSharedVarCmd = "get SHARED var $sharedVarName";

   $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$targetIP, "var", $getSharedVarCmd);

   if ($result->{rc} != $STAF::kOk) {
      $vdLogger->Error("Issued staf command: $getSharedVarCmd on $targetIP");
      $vdLogger->Error("Received RC: " . $result->{rc});
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $mc = STAF::STAFUnmarshall($STAF::Result);
   my $returnValue = $mc->getRootObject();   # gets the return value of the
                                             # remote method/sub-routine
   $vdLogger->Debug("$methodName returned: " . Dumper($returnValue));
   if ($returnValue eq "FAILURE") {
      # Get the error code of the module executed above in case failure is
      # returned. The remote module will store the error stack in the shared
      # variable $errVar.
      # Read the error message using STAF's VAR service

      $getSharedVarCmd = "get SHARED var $errVar";

      $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$targetIP, "var", $getSharedVarCmd);

      if ($result->{rc} != $STAF::kOk) {
         $vdLogger->Error("Received RC: " . $result->{rc});
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $mc = STAF::STAFUnmarshall($STAF::Result);
      $result = $mc->getRootObject();   # gets the err string
      VDSetLastError($result);          # updates the last error value
   }

   # Delete the shared variable $sharedVarName after it is read
   my $deleteSharedVarCmd = "delete SHARED var $sharedVarName";

   $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$targetIP, "var", $deleteSharedVarCmd);
   if ($result->{rc} != $STAF::kOk) {
      $vdLogger->Error("Received RC: $result->{rc}, Result: $result->{result}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Delete the shared variable $errVar after it is read
   $deleteSharedVarCmd = "delete SHARED var $errVar";

   $result = VDNetLib::Common::Utilities::STAFSubmit($handle,$targetIP, "var", $deleteSharedVarCmd);
   if ($result->{rc} != $STAF::kOk) {
      $vdLogger->Error("Received RC: $result->{rc}, Result: $result->{result}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return ($returnValue); # return after delete shared variable is successful
}
1;
