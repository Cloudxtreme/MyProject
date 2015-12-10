##########################################################
# Copyright 2011 VMware, Inc.  All rights reserved.
# VMware Confidential
##########################################################

package VDNetLib::VM::ESXSTAF4xVMOperations;

#
# ESXSTAF4xVMOperations.pm --
#     This package provides methods to do VM related operations using the
#     STAF SDK https://wiki.eng.vmware.com/SDKSTAFServices
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

# Inheriting from VDNetLib::VMOperations package.
use vars qw /@ISA/;
@ISA = qw(VDNetLib::VM::VMOperations);

# Define constants
use constant PASS => 0;
use constant DEFAULT_TIMEOUT => 90;
use constant STANDBY_TIMEOUT => 120;
use constant DEFAULT_SLEEP => 5;
use constant VM_POWER_STATE_ON => 136;
use constant VM_POWER_STATE_OFF => 2;
use constant VM_POWER_STATE_SUSPENDED => 32;
use constant VM_ALREADY_EXISTS => 5113;
use constant VM_INVALID_STATE => 7149;
use constant DEFAULT_MAX_RETRIES => 5;
use constant WIN_SCRIPTS_PATH => 'M:\scripts';
use constant LINUX_SCRIPTS_PATH => '/automation/scripts';
# rc 7028 is snapshot not found, which is fine, do not return error
use constant NO_SNAPSHOTS_FOUND => 7028;

########################################################################
#
# new --
#      Entry point to create an object of this class
#      (VDNetLib::VM::ESXSTAF4xVMOperations)
#
# Input:
#      A hash with following keys:
#      '_vmxPath' : absolute vmx path of the VM # Required
#      '_host'    : host ip on which the VM is present #Required
#      '_stafHelper' : Object of VDNetLib::Common::STAFHelper # Optional
#                      (a new object will be created if not
#                      provided)
#
# Results:
#      A VDNetLib::VM::ESXSTAF4xVMOperations object,
#         if successful;
#      FAILURE, in case of any script error
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class   = shift;
   my $options = shift;
   my $self;

   if ((not defined($options->{_host})) || (not defined($options->{_vmxPath}))) {
      $vdLogger->Error("Host and/or vmx not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{'esxHost'}      = $options->{'_host'};
   $self->{'vmx'}          = $options->{'_vmxPath'};
   $self->{'stafHelper'}   = $options->{'_stafHelper'};
   $self->{'vmIP'}         = $options->{'_vmIP'};
   $self->{'vmName'}       = undef;
   $self->{'stafVMAnchor'} = undef;

   bless ($self, $class);
   #
   # Create a VDNetLib::Common::STAFHelper object with default parameters if it not
   # provided in the input parameters.
   #
   if (not defined $self->{stafHelper}) {
      my $args;
      $args->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($args);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::Common::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }

   # Get the anchor for VM staf services
   my $stafVMAnchor = VDNetLib::Common::Utilities::GetSTAFAnchor($self->{stafHelper},
                                                               $self->{esxHost},
                                                               "VM");
   if ($stafVMAnchor eq FAILURE) {
      $vdLogger->Error("Failed to get STAF VM anchor");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{'stafVMAnchor'} = $stafVMAnchor;

   if ($self->VMOpsRegisterVM() eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Find the registered VM name for the given vmx. This VM name is used for
   # all VM operations using STAF SDK.
   #
   $self->{'vmName'}  = VDNetLib::Common::Utilities::GetRegisteredVMName($self->{esxHost},
                                                                 $self->{vmx},
                                                                 $self->{stafHelper},
                                                                 $self->{stafVMAnchor});
   if ($self->{'vmName'} eq FAILURE) {
      $vdLogger->Error("Failed to get registered vm name for $self->{vmx} on " .
                       $self->{'esxHost'});
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $self;
}


########################################################################
#
# VMOpsRegisterVM --
#     Method to register a VM using the given vmx file.
#
# Input:
#     None (since vmx is already defined as class attribute)
#
# Results:
#     "SUCCESS", if the VM is registered successfully;
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub VMOpsRegisterVM
{
   my $self = shift;

   my $esxHost = $self->{'esxHost'};
   my $vmx = $self->{'vmx'};
   my $anchor = $self->{'stafVMAnchor'};

   $vmx = VDNetLib::Common::Utilities::GetVMFSRelativePathFromAbsPath($vmx,
                                                                      $esxHost,
                                                                      $self->{stafHelper});
   if ($vmx eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $cmd = "REG ANCHOR $anchor HOST $esxHost VMXPATH \"$vmx\"";

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd,
                                                             VM_ALREADY_EXISTS);
   if ($stafResult->{rc} != $STAF::kOk) {
      $vdLogger->Error("Unable to register $vmx on $esxHost");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# VMOpsUnRegisterVM --
#     Method to unregister the VM that is defined the class object.
#
# Input:
#     None (since vmName is already defined as class attribute)
#
# Results:
#     "SUCCESS", if the VM is unregistered successfully;
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub VMOpsUnRegisterVM
{
   my $self = shift;

   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};


   my $cmd = "UNREG ANCHOR $anchor VM \"$vmName\"";

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if ($stafResult->{rc} != $STAF::kOk) {
      $vdLogger->Error("Unable to unregister $vmName on $esxHost");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# VMOpsGetPowerState --
#     Method to get the current power state of the VM.
#
# Input:
#     None
#
# Results:
#     A scalar string, which could be "poweredon"/"poweredoff"/
#     "suspended", if successful,
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub VMOpsGetPowerState
{
   my $self = shift;

   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};

   my $cmd = "GETSTATE ANCHOR $anchor VM \"$vmName\"";

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (not defined $stafResult) {
      $vdLogger->Error("Command $cmd returned undef.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable get power state of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $stafResult;
}


#############################################################################
#
# VMOpsPowerOn --
#     Power on the specified VM.
#
# Input:
#     options  -  Reference to a hash containing the following keys (Optional).
#                  waitForTools - (0/1) # Optional.
#
# Results:
#     "SUCCESS", if the VM was successfully powered on.
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
#############################################################################

sub VMOpsPowerOn
{
   my $self = shift;
   my $options = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $result;

   # Power on the VM.
   my $cmd = "POWERON ANCHOR $anchor VM \"$vmName\"";
   if ((defined $options->{waitForTools}) &&
      ($options->{waitForTools} == 1)) {
      $cmd = $cmd . " WAITFORTOOLS " . $options->{waitForTools};
   }

   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd,
                                                          VM_INVALID_STATE);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable power on $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Get the current state of the VM and verify that the VM is actually powered
   # on.
   $result = $self->VMOpsGetPowerState();
   if ($result->{rc} != $STAF::kOk) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$vmName entered $result->{result} state");
   if ($result->{result} !~ /poweredon/i) {
      $vdLogger->Error("Mismatch in requested (poweron) and current state " .
                       $result->{result});
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   if ($options->{waitForSTAF}) {
      return $self->{stafHelper}->WaitForSTAF($self->{'vmIP'});
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsPowerOff --
#     Power off the specified VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the VM was successfully powered off;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsPowerOff
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $result;

   # Power off the VM.
   my $cmd = "POWEROFF ANCHOR $anchor VM \"$vmName\"";
   # rc 7149 - invalid state, reason could be VM already powered off
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd,
                                                          VM_INVALID_STATE);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to power off $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Get the current state of the VM and verify that the VM is actually powered
   # off.
   $result = $self->VMOpsGetPowerState();
   if ($result->{rc} != $STAF::kOk) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$vmName entered $result->{result} state");
   if ($result->{result} !~ /poweredoff/i) {
      $vdLogger->Error("Mismatch is requested (poweroff) and current state " .
                       $result->{result});
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}



#############################################################################
#
# VMOpsSuspend --
#     Suspend the specified VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the VM was suspended successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsSuspend
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $result;

   # Suspend the VM.
   my $cmd = "SUSPEND ANCHOR $anchor VM \"$vmName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to suspend $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $result = $self->VMOpsGetPowerState();
   if ($result->{rc} != $STAF::kOk) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Get the current state of the VM and verify that the VM is actually powered
   # suspended.
   $vdLogger->Info("$vmName entered $result->{result} state");
   if ($result->{result} !~ /suspended/i) {
      $vdLogger->Error("Mismatch is requested (suspended) and current state " .
                       $result->{result});
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsResume --
#     Method to resume the specified VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the VM was resumed successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsResume
{
   my $self = shift;
   my $options = shift;

   return $self->VMOpsPowerOn($options);
}


#############################################################################
#
# VMOpsReset --
#     Method to reset the specified VM (not guest shutdown).
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the VM is reset successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsReset
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $result;

   # reset the VM.
   my $cmd = "RESET ANCHOR $anchor VM \"$vmName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to reset $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Get the current state of the VM and verify that the VM is actually powered
   # on.
   $result = $self->VMOpsGetPowerState();
   if ($result->{rc} != $STAF::kOk) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("$vmName entered $result->{result} state");
   if ($result->{result} !~ /poweredon/i) {
      $vdLogger->Error("Mismatch is requested (poweron) and current state " .
                       $result->{result});
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# WaitForVMState --
#     Waits until the specified VM is powered off or until a timeout occurs.
#
# Input:
#     state: "poweredon" or "poweredoff" or "suspended" # Required
#     timeout: time to wait in seconds # Optional
#
# Results:
#     "SUCCESS", if the VM enters the given state;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub WaitForVMState
{
   my $self = shift;
   my $state = shift;
   my $timeout = shift || DEFAULT_TIMEOUT;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $powerState = undef;
   my $result;


   my $startTime = time();
   while ((time() - $startTime) <= $timeout) {
      # Get VM's Power state
      $result = $self->VMOpsGetPowerState();
      if ($result->{rc} != $STAF::kOk) {
         $vdLogger->Error("Unable to get state of $vmName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if ($result->{result} =~ /$state/i) {
         return SUCCESS;
      }
      sleep(DEFAULT_SLEEP);
   }
   $vdLogger->Error("Last state of the VM:$result->{result}," .
                  "expected: $state");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


#############################################################################
#
# GetGuestInfo --
#     Method to get the guest information.
#
# Input:
#     None
#
# Results:
#     TODO:  return a hash of all the parameters returned from
#     "GETGUESTINFO" command in STAF SDK
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetGuestInfo
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};


   my $cmd = "GETGUESTINFO ANCHOR $anchor VM \"$vmName\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest information of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $stafResult->{result};
}


#############################################################################
#
# VMOpsShutdownUsingCLI --
#     Shut down the specified VM using guest CLI.
#
# Input:
#     ip: ip address of the guest # Optional
#     waitForShutdown: 0/1 - to indicate whether to wait for complete
#                      shutdown # Optional
#
# Results:
#     "SUCCESS", if the VM/guest is shutdown without any error;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsShutdownUsingCLI
{
   my $self            = shift;
   my $ip              = shift;
   my $waitForShutdown = shift || 1;
   my $esxHost = $self->{'esxHost'};
   my $vmx    = $self->{'vmx'};
   my $stafResult = undef;
   my $cmd;
   my $result;

   if (not defined $ip) {
      $ip = VDNetLib::Common::Utilities::GetGuestControlIP($esxHost, $vmx);
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get ip address of $vmx");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   # Find the OS type
   my $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($osType =~ m/Win/i) {
      $cmd = "shutdown /s /f";
   } else {
      $cmd = "shutdown -h -t 1 now";
   }

   $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
   if (PASS != $stafResult->{rc}) {
      $vdLogger->Error("Failed to send $cmd to $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $waitForShutdown && $waitForShutdown == 1) {
      return $self->WaitForVMState("poweredoff");
   }
   return SUCCESS;
}


#############################################################################
#
# VMOpsShutdownUsingSDK --
#     Shut down the specified VM using STAF SDK.
#
# Input:
#     waitForShutdown: 0/1 - to indicate whether to wait for complete
#                      shutdown # Optional
#
# Results:
#     "SUCCESS", if the VM is shutdown without any error;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsShutdownUsingSDK
{
   my $self            = shift;
   my $waitForShutdown = shift || 1;
   my $vmName = $self->{'vmName'};
   my $vmx    = $self->{'vmx'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $cmd;
   my $result;

   # Shutdown the VM.
   $cmd = "SHUTDOWN ANCHOR $anchor VM \"$vmName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to shutdown $vmName.");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $waitForShutdown && $waitForShutdown == 1) {
      return $self->WaitForVMState("poweredoff");
   }
   return SUCCESS;
}

#############################################################################
#
# VMOpsRebootUsingSDK --
#     Reboot the specified VM using STAF SDK.
#
# Input:
#     waitForReboot: 0/1 - to indicate whether to wait for tools to be
#                      initialiized # Optional
#
# Results:
#     "SUCCESS", if the VM is rebooted without any error;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsRebootUsingSDK
{
   my $self            = shift;
   my $waitForReboot   = shift || 1;
   my $vmName = $self->{'vmName'};
   my $vmx    = $self->{'vmx'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $cmd;
   my $result;

   # Reboot the VM.
   $cmd = "REBOOT ANCHOR $anchor VM \"$vmName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to reboot $vmName.");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # wait for the staf to ensure reboot is complete
   if (defined $waitForReboot && $waitForReboot == 1) {
      return $self->{stafHelper}->WaitForSTAF($self->{'vmIP'});
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsShutdown --
#     Shut down the specified VM.
#
# Input:
#     ip : ip address of the guest # Optional
#     waitForShutdown: 0/1 - to indicate whether to wait for complete
#                      shutdown # Optional
#     method: "cli" to shutdown using command line inside guest
#             "sdk" to use staf sdk to shutdown  (Optional)
#
# Results:
#     "SUCCESS", if the VM enters the given state;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsShutdown
{
   my $self            = shift;
   my $ip              = shift;
   my $waitForShutdown = shift || 1;
   my $method          = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $vmx    = $self->{'vmx'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $cmd;
   my $result;

   if (not defined $method) {

      $result = $self->GetGuestInfo();

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get guest information of $vmName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      #
      # Check whether tools is installed in the given VM.
      # If yes, then use the STAF SDK command to shutdown the VM, that way
      # the "shutdown" option in VI client is tested (assuming users will use
      # that). If tools is not installed, then using the ip address and guest type
      # issue the appropriate shutdown command inside the guest.
      #
      if ($result =~ /Tools Status: toolsNotInstalled/i) {
      # Get VM ip address
      $vdLogger->Info("Tools not installed on $vmName, using CLI to shutdown");
         $method = "cli";
      } else {
         $method = "sdk";
      }
   }

   if ($method =~ /cli/i) {
      $result = $self->VMOpsShutdownUsingCLI($ip, $waitForShutdown);
   } else {
      $result = $self->VMOpsShutdownUsingSDK($waitForShutdown);
   }

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


#############################################################################
#
# VMOpsHibernate --
#     Method to hibernate the guest
#
# Input:
#     ip: ip address of the VM # Optional
#
# Results:
#     "SUCCESS", if the guest enters the hibernate state;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsHibernate
{
   my $self = shift;
   my $ip   = shift;

   my $vmx = $self->{'vmx'};
   my $host = $self->{'esxHost'};
   my $stafResult = undef;
   my $osType = undef;
   my $cmd;
   my $result;

   #
   # Check if the ip address is given, otherwise find it using
   # GetGuestControlIP() utility function.
   #
   if (not defined $ip) {
      $vdLogger->Info("Finding IP address of $vmx");
      $ip = VDNetLib::Common::Utilities::GetGuestControlIP($host, $vmx);
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get ip address of $vmx");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   # Find the OS type
   $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($osType =~ m/Win/i) {
      # Turn on hibernate option
      $cmd = "powercfg /hibernate on";
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $cmd,
                                                         DEFAULT_TIMEOUT);
      if (PASS != $stafResult->{rc} || PASS != $stafResult->{exitCode}) {
         $vdLogger->Error("Failed to enable hibernate option on $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      #
      # The command for hibernating windows is different on Windows XP.
      # So find the windows version and execute the appropriate command
      #
      $cmd = "systeminfo";
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $cmd,
                                                         DEFAULT_TIMEOUT);
      if (PASS != $stafResult->{rc} || PASS != $stafResult->{exitCode}) {
         $vdLogger->Error("Unable to get windows version of $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if($stafResult->{stdout} =~ m/OS Name:.*Windows\s*XP/i) {
         $cmd = "rundll32 powerprof.dll,SetSuspendState";
      } else {
         $cmd = "shutdown /h";
      }

      $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
      if (PASS != $stafResult->{rc}) {
         $vdLogger->Error("Failed to send $cmd to $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } elsif ($osType =~ m/Linux/i) {
      #
      # Check if hibernation is supported.
      # Hibernation is supported if /sys/power/state has 'mem'
      # or 'disk'
      #
      $cmd = "cat /sys/power/state";
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $cmd,
                                                         DEFAULT_TIMEOUT);
      if (PASS != $stafResult->{rc} || PASS != $stafResult->{exitCode}) {
         $vdLogger->Error("Failed to check hiberantion support on $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($stafResult->{stdout} !~ m/mem/i &&
          $stafResult->{stdout} !~ m/disk/i) {
         $vdLogger->Error("Hibernation is not supported on $ip");
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }

      # Send the hibernate command
      # TODO - verify if this command works on all linux flavors
      $cmd = 'sleep 3;echo "mem" > /sys/power/state';
      $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
      if (PASS != $stafResult->{rc}) {
         $vdLogger->Error("Failed to send $cmd to $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Unsupported OS $osType");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   if ($self->WaitForVMState("poweredoff") eq FAILURE) {
      $vdLogger->Error("Failed to enter poweredoff state");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsStandby --
#     Method to put the guest to standby.
#
# Input:
#     ip: ip address of the VM # Optional
#
# Results:
#     "SUCCESS", if the guest enters the standby state;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsStandby
{
   my $self = shift;
   my $ip = shift;

   my $vmx = $self->{'vmx'};
   my $host = $self->{'esxHost'};
   my $stafResult = undef;
   my $result;
   my $osType = undef;
   my $cmd = "";

   #
   # Check if the ip address is given, otherwise find it using
   # GetGuestControlIP() utility function.
   #
   if (not defined $ip) {
      $vdLogger->Info("Finding IP address of $vmx");
      $ip = VDNetLib::Common::Utilities::GetGuestControlIP($host, $vmx);
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get ip address of $vmx");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   # Find the OS type
   $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my @path;
   @path = split('/', $vmx);
   $vmx =~ s/$path[$#path]//;
   $cmd = "cd $vmx;grep -i 'standby sleep state' vmware.log | wc -l";
   $stafResult = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   if ($STAF::kOk != $stafResult->{rc}) {
      $vdLogger->Error("Failed to grep vmware.log file");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $data1 = $stafResult->{stdout};

   if ($osType =~ m/Win/i) {
      #
      # to disable resume password on windows 2003
      # powercfg /GLOBALPOWERFLAG OFF /OPTION RESUMEPASSWORD
      # the above didn't work for Windows 2008
      # C:\Users\Administrator>cmd /c regedit /s screenSaver.reg
      # [HKEY_CURRENT_USER\Cont
      # rol Panel\Desktop] "ScreenSaveIsSecure"=0
      # "ScreenSaveActive"="1"
      # disable hibernation if it is a windows VM
      #
      $cmd = "powercfg /hibernate off";
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $cmd,
                                                         DEFAULT_TIMEOUT);
      if (PASS != $stafResult->{rc} || PASS != $stafResult->{exitCode}) {
         $vdLogger->Error("Failed to enable hibernate option on $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      $vdLogger->Debug("Turned off Hibernation on $ip");
      # TODO: disable asking for passwd on wake up

      $cmd = '%windir%\System32\rundll32.exe powrprof.dll,SetSuspendState';
      $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to put $ip to standby");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } elsif ($osType =~ /lin/i ) {
      #
      # running sleep command before standby because executing just standby
      # command by the linux guest to sleep immediately and staf hangs awaiting
      # result from the process command.
      #
      $cmd = 'sleep 3;echo "standby" > /sys/power/state';
      $vdLogger->Debug("standby command: $cmd ");
      $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to put $ip to standby");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   $vdLogger->Info("Guest $ip has been put into standby mode");

   # Checking the vmware.log to verify if the guest entered standby state.
   sleep(STANDBY_TIMEOUT);
   $cmd = "cd $vmx;grep -i 'standby sleep state' vmware.log | wc -l";
   $stafResult = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   if ($STAF::kOk != $stafResult->{rc}) {
      $vdLogger->Error("Failed to grep vmware.log file");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $data2 = $stafResult->{stdout};
   if ($data2 <= $data1) {
      $vdLogger->Error("Failed to put guest $ip in standby-state");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


#############################################################################
#
# GetVMXPID --
#     Method to get the vmx process id corresponding to the VM object.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the pid is found;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetVMXPID
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};

   # TODO - verify on classic esx
   my $cmd = "ps | grep \"$vmName\"";
   my $stafResult = $self->{stafHelper}->STAFSyncProcess($esxHost, $cmd);
   if ($STAF::kOk != $stafResult->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $data = $stafResult->{stdout};

   if ($data =~ /\n(\d+)\s(\d+)\s/) {
      return $2;
   } else {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


#############################################################################
#
# VMOpsKill --
#     Method to kill the process corresponding to the VM object.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the vmx process is killed successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsKill
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};

   my $retry = DEFAULT_MAX_RETRIES;
   my $count = 0;

   my $pid = $self->GetVMXPID();

   if ($pid eq FAILURE) {
      $vdLogger->Error("Couldn't find process id of VM $vmName on $esxHost");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   while ($count < $retry) {
      my $cmd = "kill -9 $pid";
      my $stafResult = $self->{stafHelper}->STAFSyncProcess($esxHost, $cmd);

      if ($STAF::kOk != $stafResult->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($self->GetVMXPID() eq FAILURE) {
         return SUCCESS;
      } else {
         VDCleanErrorStack();
      }
   }

   $vdLogger->Error("$pid not killed on $esxHost");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


#############################################################################
#
# VMOpsListSnapshots --
#     Method to list all snapshots in the VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the snapshot list obtained successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsListSnapshots
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;

   # List all snapshots in the VM.
   my $cmd = "LISTSNAPS ANCHOR $anchor VM \"$vmName\" SNAPDESC";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc} && NO_SNAPSHOTS_FOUND != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get list of snapshots in $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $stafResult->{result};
}


#############################################################################
#
# VMOpsTakeSnapshot --
#     Method to take snapshot with the given snapshot name.
#
# Input:
#     snapName: name of the snapshot # Required
#
# Results:
#     "SUCCESS", if the snapshot is created successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsTakeSnapshot
{
   my $self     = shift;
   my $snapName = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $result;

   if (not defined $snapName) {
      $vdLogger->Error("Snapshot name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Create a snapshot of the VM.
   my $cmd = "CREATESNAP $snapName ANCHOR $anchor VM \"$vmName\" MEMORY";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to create a snapshot of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $result = $self->VMOpsListSnapshots();
   if ($result !~ /$snapName/) {
      $vdLogger->Error("No snapshot with name $snapName found");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsDeleteSnapshot --
#     Method to delete the given snapshot in the VM.
#
# Input:
#     snapName: name of the snapshot to be deleted # Required
#
# Results:
#     "SUCCESS", if the snapshot is deleted successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsDeleteSnapshot
{
   my $self     = shift;
   my $snapName = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $result;

   if (not defined $snapName) {
      $vdLogger->Error("No snapshot name given to delete");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Delete the given snapshot from the VM.
   my $cmd = "RMSNAP ANCHOR $anchor VM \"$vmName\" SNAPNAME \"$snapName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   #
   # rc 7028 is snapshot not found, which is fine if it is already removed.
   #
   if ((0 != $stafResult->{rc}) && (7028 != $stafResult->{rc})) {
      $vdLogger->Warn("Unable to delete snapshot $snapName on $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $result = $self->VMOpsListSnapshots();
   if ($result =~ /$snapName/) {
      $vdLogger->Warn("Snapshot name with name \"$snapName\" still exists, " .
                      "may be duplicate names?");
   }
   return SUCCESS;
}


#############################################################################
#
# VMOpsRevertSnapshot --
#     Method to revert VM to the given snapshot.
#
# Input:
#     snapName: name of the snapshot # Required
#
# Results:
#     "SUCCESS", if the vm is reverted successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsRevertSnapshot
{
   my $self     = shift;
   my $options = shift;
   # picks current snapshot if not defined
   my $snapName = $options->{SnapShotName} || undef;
   my $esxHost = $self->{'esxHost'};
   my $vmName  = $self->{'vmName'};
   my $anchor  = $self->{'stafVMAnchor'};
   my $stafResult = undef;
   my $result;

   # Revert the VM to the given snapshot.
   my $cmd = "USESNAP ANCHOR $anchor VM \"$vmName\" SNAPNAME \"$snapName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to revert $vmName to snapshot $snapName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsHotRemovevNIC --
#     Method to remove (hot/cold) a virtual network adapter from a VM.
#
# Input:
#     macAddress: mac address of the adapter to be removed # Required
#
# Results:
#     "SUCCESS", if the adapter is removed successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsHotRemovevNIC
{
   my $self       = shift;
   my $macAddress = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName  = $self->{'vmName'};
   my $anchor  = $self->{'stafVMAnchor'};

   if (not defined $macAddress) {
      $vdLogger->Error("MAC address of the device to be removed not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $device = $self->GetDeviceLabelFromMac($macAddress);
   if (not defined $device) {
      $vdLogger->Error("Unable to find the adapter label for $macAddress");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # execute the STAF command to remove the virtual network adapter
   my $cmd = "REMOVEVIRTUALNIC ANCHOR $anchor VM \"$vmName\" " .
             "VIRTUALNIC_NAME \"$device\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest information of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# GetAdaptersInfo --
#     Method to get information about the network adapters in the VM.
#
# Input:
#     None
#
# Results:
#     reference to a hash containing the following keys:
#     'vm network <x>', where x refers to the adapter number.
#
#     Each of these keys is a hash, which has the following keys:
#     'network'      - name of the network,
#     'portgroup'    - name of the portgroup,
#     'mac address'   - mac address of the adapter,
#     'adapter class'- adapter type,
#     'label'        - label (adapter name seen in VI client)
#
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetAdaptersInfo
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};
   my $nicsInfo;

   my $cmd = "VMNICINFO ANCHOR $anchor VM \"$vmName\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest information of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $data = $stafResult->{result};
   my @array = split(/\n/,$data);
   my $identifier = undef;
   foreach my $line (@array) {
      if ($line =~ /^VM NETWORK (\d+)/i) {
         $identifier = "vm network $1";
         next;
      }
      if ((not defined $line) || ($line eq "")) {
         next;
      }
      my ($key, $value) = split(/: /,$line);
      #  Convert all the keys to lower case, since there are some inconsistencies
      #  in the result from staf command.
      #
      $key = lc $key;
      if ($key eq "macaddress") {
         $key = "mac address";
      }
      $nicsInfo->{$identifier}{$key} = $value;
   }
   my @list = ();
   foreach my $adapter (keys %$nicsInfo) {
      push (@list, $nicsInfo->{$adapter});
   }

   return \@list;
}


#############################################################################
#
# VMOpsChangePortgroup --
#     Method to change the portgroup of a virtual network adapter.
#
# Input:
#     macAddress: mac address of the adapter to be disconnected # Required
#     portgroup : name of the new portgroup (ensure this portgroup exists)
#                 # Required
#
# Results:
#     "SUCCESS", if the portgroup of the adapter is changed successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsChangePortgroup
{
   my $self = shift;
   my $macAddress = shift;
   my $portgroup  = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};

   if (not defined $macAddress || not defined $portgroup) {
      $vdLogger->Error("MAC address and/or portgroup of the device not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Get the adaperter label
   my $device = $self->GetDeviceLabelFromMac($macAddress);
   if (not defined $device) {
      $vdLogger->Error("Unable to find the adapter label for $macAddress");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $cmd = "CHANGEVIRTUALNIC ANCHOR $anchor VM \"$vmName\" " .
             "VIRTUALNIC_NAME \"$device\" PGNAME \"$portgroup\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest information of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# VMOpsDeviceAttachState --
#     Method to check if a device is attached or not.
#
# Input:
#     Device - which is to be checked.
#
# Results:
#     1, if it is attached.
#     0, if not attached.
#     FAILURE in case of any error.
#
# Side effects:
#
#
########################################################################

sub VMOpsDeviceAttachState
{
   my $self = shift;
   my $device = shift;

   # Checking for supported values
   if($device !~ /(floppy|serial|parallel|^cd)/i) {
      $vdLogger->Error("Unsupported Device:$device");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'};

   $device = "CD\/DVD drive" if $device =~ /^cd/i;
   $device = "Floppy drive"  if $device =~ /floppy/i;
   $device = "Serial port"   if $device =~ /serial/i;
   $device = "Parallel port" if $device =~ /parallel/i;

   my $cmd;
   $cmd = "VMHWDETAILS ANCHOR $anchor VM $vmName ";

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if ($stafResult->{rc} != $STAF::kOk) {
      $vdLogger->Error("Unable to upgrade $vmName on $esxHost");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # We just see if the device is present in this array
   # We dont care about the connection state of the device at this time.
   # result format
   # CD/DVD drive 1          Remote device
   # CD/DVD drive 2          Remote device
   # CD/DVD drive 3          Remote device
   # Network adapter 1       vswitchpg-0-23021
   # ADAPTERTYPE             VMXNET3
   # Network adapter 2       VM Network
   # ADAPTERTYPE             E1000
   # Floppy drive 1          Remote
   # Floppy drive 2          Remote
   # Serial port 1           /dev/char/serial/uart1
   # Serial port 2           /dev/char/serial/uart1
   # Parallel port 1         File [automation] watever


   my $result = $stafResult->{result};
   my @lines = split('\n', $result);
   foreach my $line (@lines) {
      if ($line =~ /$device/i) {
         # Replace the space in CD/DVD drive 1      Remote device
         # with : so that its easier to split
         $line =~ s/\s{2,8}/:/;
         my @element = split(':', $line);
         return $element[0] if $element[0] =~ /$device/i;
      }
   }

   return 0;
}


########################################################################
#
# VMOpsGetToolsStatus --
#     Check the status, version etc of VMware Tools and suggest if it
#     needs upgrade or not.
#
# Input:
#     none.
#
# Results:
#     1 - if upgrade needed
#     0 - if no upgrade required
#     "FAILURE", in case of any error.
#
# Side effects:
#
#
########################################################################

sub VMOpsGetToolsStatus
{
   my $self = shift;
   my ($needUpgrade, $version);

   my $result = $self->GetGuestInfo();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get guest information in ".
                       "GetToolsStatus");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Current logic is - if user gives path to iso in <tools> option then
   # perform upgrade with it irrespective of current tools status/version.
   # If upgrade is with default build then no need to upgrade if Tools Version
   # Status says 'guestToolsCurrent'.
   # If Tools Version Status says 'ToolsNeedUpgrade' then of course
   # upgrade tools.

   # Stdout of GetGuestInfo for staf 4x.
   # Tools Info: true
   # Guest OS Info: null
   # Tools Version: 8353
   # Screen Info: null
   # Disk Info: null
   # NIC Info: null
   # Tools Status: toolsNotRunning

   if($result !~ /Tools Info: true/i) {
      $vdLogger->Warn("VMware Tools Info not found using GetGuestInfo".
                      "for $self->{'vmIP'}. Cannot Upgrade!");
      return FAILURE;
   }

   $result =~ /Tools Version\: (\d+)/i;
   $version = $1;
   $version = VDNetLib::Common::Utilities::VMwareToolsVIMCMDVersion(
                                  $version);

   if($result =~ /toolsOK/i) {
      $vdLogger->Info("VMware Tools in $self->{'vmIP'} is ".
                      "Updated. Version:$version");
      $needUpgrade = 0;
   } elsif($result =~ /toolsOld/i) {
      $vdLogger->Info("VMware Tools in $self->{'vmIP'} is ".
                      "Old. Version:$version");
      $needUpgrade = 1;
   } elsif($result =~ /toolsnotrunning/i) {
      #
      # If tools are not running it might be becasue the VM is
      # poweredoff/suspended. We poweron the VM try to check
      # the status again with a recursive call to this same method
      #
      my ($initPowerState);
      $result = $self->VMOpsGetPowerState();
      if ($result->{rc} != $STAF::kOk) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # Check the state of the VM. If running then power it down.
      if ($result->{result} =~ /poweredoff/i) {
         $vdLogger->Info("Powering On VM $self->{vmName} to check tools status");
         $result =  $self->VMOpsPowerOn();
         if ($result eq FAILURE) {
           $vdLogger->Error("Failed to power off VM $self->{vmName}");
           VDSetLastError(VDGetLastError());
           return FAILURE;
         }
         $vdLogger->Info("Waiting for STAF on $self->{'vmIP'} ...");
         $result = $self->{stafHelper}->WaitForSTAF($self->{'vmIP'});
         if ($result  eq FAILURE ) {
            $vdLogger->Error("WaitForSTAF failed on $self->{'vmIP'} ".
                             "in VMOpsGetToolsStatus");
            VDSetLastError(VDGetLastError());
            return "FAILURE";
         }
         #
         # Making a recursive call to same method to check the status
         # of tools now that we have powered on the VM.
         #
         $self->GetToolsStatus();
      } else {
         $vdLogger->Error("VMware Tools in $self->{'vmIP'} is ".
                          "ToolsNotRunning. Version:$version");
         VDSetLastError(VDGetLastError());
         return "FAILURE";

      }
   }

   return $needUpgrade;
}

1;
