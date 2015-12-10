#/* **********************************************************
# * Copyright 2011 VMware, Inc.  All rights reserved.
# * -- VMware Confidential
# * **********************************************************/

package VDNetLib::VM::HostedVMRunOperations;

use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

# Should I be using this in a package?
use strict;
use warnings;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VIX";

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDLog;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Switch;

# Inheriting from VMOperations package.
use vars qw /@ISA/;
@ISA = qw(VDNetLib::VM::VMOperations);
use constant FUSION_DEFAULT_NETWORKING_PATH => '/Library/Preferences/VMware\ Fusion/';

################################################################################
#  new (Constructor)
#
#  Algorithm:
#  Sets the variables specific to HostedVMRunOperations.
#
#  Input:
#       a hash with keys _host and _vmxPath
#
#  Output:
#       child Object of HostedVMRunOperations.
#
#  Side effects:
#       none
#
################################################################################

sub new
{
   my $proto    = shift;
   my $class    = ref($proto) || $proto;
   my $hash_ref = shift;# test bed ref

   $hash_ref->{'_justHostIP'}      = $hash_ref->{'_host'};
   $hash_ref->{'_absoluteVMXPath'} = $hash_ref->{'_vmxPath'};
   $hash_ref->{'_productType'} = $hash_ref->{'_productType'};
   $hash_ref->{'_vmxPathForBashCommands'} = $hash_ref->{'_vmxPath'};
   $hash_ref->{'vmIP'}         = $hash_ref->{'_vmIP'};
   # TODO: This will either be retrieved later on or passed as a parameter
   # in any case, this will be moved from here.
   $hash_ref->{fusionNetworking} = "/Library/Preferences/VMware Fusion/";

   my $self = {
   };

   $self = $hash_ref;

   $self->{staf}  = $self->{testbed}->{stafHelper};
   if (not defined $self->{staf}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp || $temp eq FAILURE) {
         $vdLogger->Error("Failed to create VDNetLib::Common::STAFHelper"
                          ." object");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $self->{staf} = $temp;
   }

   if ( $self->{staf}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      $vdLogger->Error("STAF is not running on $self->{_justHostIP} \n");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $self->{stafHelper} = $self->{staf};
   $self->{'vmrun'} = GetLibPath($self)."vmrun";
   if ($self->{'vmrun'} eq FAILURE) {
      $vdLogger->Error("Error setting vmrun binary in the constructor");
      VDSetLastError("EOPFAILED");
   }

   if($hash_ref->{_absoluteVMXPath} =~ /\\\s/) {
      $hash_ref->{_vmxPathForBashCommands} =~ s/\\//;
   } else {
      my @vmxArray = split(" ", $hash_ref->{_absoluteVMXPath});
      my $count = 1;
      my $vmxPath = $vmxArray[0];
      while($count<@vmxArray) {
         $vmxPath = $vmxPath."\\\ ".$vmxArray[$count];
         $count++;
      }
      $hash_ref->{_absoluteVMXPath} = $vmxPath;
   }

   $self->{vmdbsh} = GetVmdbshToolBinary($self);
   $self->{natConf} = GetNatConfPath($self);
   bless $self, $class;
   return $self;
}


################################################################################
#  ExecuteVMRUN
#     Method to execute VMRUN Binary.
#
#  Input:
#       operationName: Name of operation used in vmrun
#       Option : it can be nogui, soft or hard
#       String(optional): used in operation like take snapshot
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub ExecuteVMRUN
{
   my $self = shift;
   my $operationName = shift;
   my $option = shift;
   my $string = shift;

   if (not defined $operationName || not defined $option) {
      $vdLogger->Error("Operation name or option for vmrun is not supplied.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $wincmd;
   if (defined $string) {
      $wincmd = STAF::WrapData("$self->{vmrun} -T $self->{_productType} ".
                $operationName ." $self->{_absoluteVMXPath} $string $option");
   } else {
      $wincmd = STAF::WrapData("$self->{vmrun} -T $self->{_productType} ".
                $operationName ." $self->{_absoluteVMXPath} $option");
   }

   my $command ="start shell command $wincmd " .
             " wait returnstdout stderrtostdout";

   (my $result, my $data) =
   $self->{staf}->runStafCmd( $self->{_justHostIP}, "process", $command );

   if($result eq FAILURE) {
      $vdLogger->Error("Error processing STAF command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $data;
}

################################################################################
#  VMOpsPowerOff
#  Powers off the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsPowerOff
{
   my $self = shift;

   my $data = $self->ExecuteVMRUN("stop", "soft");
   if ($data eq `` &&
	(($self->VMOpsIsVMRunning($self->{_absoluteVMXPath}) == 0))) {
      $vdLogger->Info("The VM $self->{_absoluteVMXPath} Powered Off successfully.");
   } elsif ($data =~ m/The virtual machine is not powered on/i) {
      $vdLogger->Info("The VM $self->{_absoluteVMXPath} already powered off");
   } else {
      $vdLogger->Error("Error powering off the VM $self->{_absoluteVMXPath}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#  VMOpsPowerOn
#  Powers on the VM
#
#  Input:
#       options: hash value with keys WaitForTools,WaitForSTAF
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsPowerOn
{
   my $self = shift;
   my $options = shift;
   my $controlIP = undef;
   my $result = "SUCCESS";
   if (defined $options->{controlIP}){
      $controlIP = $options->{controlIP};
   }
   if($self->VMOpsGetPowerState() == 1) {
      $vdLogger->Info("VM $self->{_absoluteVMXPath} already powered on");
      return SUCCESS;
   }
   my $data = $self->ExecuteVMRUN("start","nogui");
   if ($self->VMOpsGetPowerState() == 1) {
      $vdLogger->Info("Succesfully powered on VM $self->{_absoluteVMXPath}");
   } else {
      $vdLogger->Error("Error powering on the VM $self->{_absoluteVMXPath},
			Error: $data");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # $options->{waitForSTAF} = 1; # used for unit testing
   # $self->{'vmIP'} = "10.112.73.185"; # used for unit testing
   if (defined $options->{waitForSTAF} && $options->{waitForSTAF}) {
      if (defined $controlIP) {
         #this branch is for resumed VM which already had IP address.
         $result = $self->{staf}->WaitForSTAF($controlIP);
      } else {
         $result = $self->{staf}->WaitForSTAF($self->{'vmIP'});
      }
   }
   if ($result eq FAILURE) {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      return SUCCESS;
   }
}


################################################################################
#  VMOpsRebootUsingSDK
#  Restarts the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsRebootUsingSDK
{
   my $self = shift;
   my $waitForReboot   = shift || 1;
   my $sleepBetweenCombos = shift;

   $vdLogger->Info("Beginning to restart the VM $self->{_absoluteVMXPath}");
   if(($self->VMOpsPowerOff) eq FAILURE) {
      $vdLogger->Info("Could not power off the VM $self->{_absoluteVMXPath}");
      return FAILURE;
   }
   if(($self->VMOpsPowerOn) eq FAILURE) {
      $vdLogger->Info("Could not power on the VM $self->{_absoluteVMXPath}");
      return FAILURE;
   }
   # wait for the staf to ensure reboot is complete
   if (defined $waitForReboot && $waitForReboot == 1) {
      # remove this log prior to submitting
      $vdLogger->Info("waiting for staf to come up on VM, $self->{'vmIP'}");
      return $self->{stafHelper}->WaitForSTAF($self->{'vmIP'});
   }

   return SUCCESS;
}


################################################################################
#  VMOpsPause
#  Pause the the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsPause()
{
   my $self = shift;

   my $data = $self->ExecuteVMRUN("pause","soft");
   if($data eq ``) {
      $vdLogger->Info("Paused the VM $self->{_absoluteVMXPath}");
   } else {
      $vdLogger->Error("Failed to pause VM $self->{_absoluteVMXPath}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#  VMOpsUnpause
#  Powers on the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsUnpause()
{
   my $self = shift;

   my $data = $self->ExecuteVMRUN("unpause","soft");
   if($data eq ``) {
      $vdLogger->Info("UnPaused the VM $self->{_absoluteVMXPath}");
   } else {
      $vdLogger->Error("Error unpausing the VM $self->{_absoluteVMXPath}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#  VMOpsIsVMRunning
#  Check if VM is running or not
#
#  Input:
#       none
#
#  Output:
#       1 if VM is running
#       0 if not running
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsIsVMRunning
{
   my $self = shift;
   my $isRunning = $self->VMOpsGetPowerState();
   if ($isRunning eq FAILURE) {
      $vdLogger->Error("Error getting state of the VM
                               $self->{_absoluteVMXPath}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS ? ($isRunning == 1): return FAILURE;
}


################################################################################
#  VMOpsResume
#  Powers on the VM which is a resume operation if the VM is suspended.
#
#  Input:
#       options: hash value with keys WaitForTools,WaitForSTAF
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsResume()
{
   my $self = shift;
   my $options = shift;
   $vdLogger->Debug("VM resume with options :".Dumper($options));
   return $self->VMOpsPowerOn($options);
}


################################################################################
#  VMOpsReset
#  Powers on the VM which is a resume operation if the VM is suspended.
#
#  Input:
#       options: hash value with keys WaitForTools,WaitForSTAF
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsReset
{
   my $self = shift;
   my $options = shift;
   my $controlIP = undef;
   my $result = "SUCCESS";
   if (defined $options->{controlIP}){
      $controlIP = $options->{controlIP};
   }
   my $data = $self->ExecuteVMRUN("reset", "soft");
   if($data eq ``) {
      $vdLogger->Info("Succesfully Reset the VM $self->{_absoluteVMXPath}");
   } else {
      $vdLogger->Error("Error resetting the VM $self->{_absoluteVMXPath}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # $options->{waitForSTAF} = 1; # used for unit testing
   # $self->{'vmIP'} = "10.112.73.185"; # used for unit testing
   if (defined $options->{waitForSTAF} && $options->{waitForSTAF}) {
      if (defined $controlIP) {
         #this branch is for resumed VM which already had IP address.
         $result = $self->{staf}->WaitForSTAF($controlIP);
      } else {
         $result = $self->{staf}->WaitForSTAF($self->{'vmIP'});
      }
   }
   if ($result eq FAILURE) {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      return SUCCESS;
   }
}


################################################################################
#  VMOpsSuspend
#  Suspends the VM.
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed, FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsSuspend
{
   my $self = shift;

   my $data = $self->ExecuteVMRUN("suspend", "soft");
   if($data eq ``) {
      $vdLogger->Info("Suspended the VM $self->{_absoluteVMXPath}");
   } elsif ($data =~ m/The virtual machine is not powered on:/i) {
      $vdLogger->Error("Virtual Machine $self->{_absoluteVMXPath} is not "
                     ."powered on");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $vdLogger->Error("Error suspending the VM $self->{_absoluteVMXPath}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

################################################################################
#  VMOpsTakeSnapshot
#  Just takes snapshot
#
#  Input:
#       SnapshotName   You should give a name while taking snapshot
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsTakeSnapshot
{
   my $self = shift;
   my $snapShotName = shift;
   if (not defined $snapShotName){
      $vdLogger->Error("VM Ops Take Snapshot called without a snapshot name."
		." Exiting...");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Adding command to check the new snapshots name is uniqly identified
   # or not, if this check is not there same snapshots will  be  created
   # and VMOpsDeleteSnapShots will fail.
   my $data = $self->ExecuteVMRUN("listSnapshots", "soft");
   my @snapshots = split("\n",$data);
   foreach (@snapshots) {
      if($_ eq $snapShotName) {
        $vdLogger->Error("SnapShot $snapShotName alredy has been taken.");
        VDSetLastError("EFAIL");
        return FAILURE;
      }
   }

   $data = $self->ExecuteVMRUN("snapshot", "soft", $snapShotName);
   if($data eq ``) {
      $vdLogger->Info("Snapshot $snapShotName taken successfully.");
   } else {
      $vdLogger->Error("Error while taking snapshot");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

################################################################################
#  VMOpsRevertSnapshot
#  Reverts to the given snapshot
#
#  Input:
#       SnapshotName: Name of the snapshot to revert. If not
#                     provided then current snapshot will be used.
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsRevertSnapshot
{
   my $self = shift;
   my $options  = shift;
   my $snapShotName = $options->{SnapShotName} || undef; # picks current snapshot if not defined
   my $controlIP = $options->{ControlIP};
   if(not defined $snapShotName) {
      $snapShotName = GetCurrentSnapshot();
      if ($snapShotName eq FAILURE) {
         $vdLogger->Error("Exiting VMOpsRevertSnapshot");
         return FAILURE;
      } elsif ($snapShotName eq "0") {
         $vdLogger->Info("No snapshot exists to revert");
         return SUCCESS;
      }
   }
   my $data = $self->ExecuteVMRUN("revertToSnapshot","soft",$snapShotName);
   if (!($data eq ``)) {
      $vdLogger->Error("Error occured while reverting to a snapshot");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # check staf service
   if (defined $controlIP){
      return $self->{stafHelper}->WaitForSTAF($controlIP);
   } else {
      # Revert snapshot from a poweroff VM, there is no control IP
      # Just sleep 10 senconds wait for STAF service.
      $vdLogger->Warn("Revert from snapshot $snapShotName...");
      sleep 10;
   }
   return SUCCESS;
}

################################################################################
#  VMOpsDeleteSnapshot
#  Delete the snapshot with given name
#
#  Input:
#       SnapshotName: Name of the snapshot you want to delete. If not
#                     provided then current snapshot will be used.
#
#  Output:
#       SUCCESS if passed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsDeleteSnapshot
{
   my $self = shift;
   my $snapshotName = shift;

   if (not defined $snapshotName) {
      $snapshotName = GetCurrentSnapshot();
      if ($snapshotName eq FAILURE) {
         $vdLogger->Error("Exiting VMOpsRevertSnapshot");
         return FAILURE;
      } if ($snapshotName eq "0") {
         $vdLogger->Info("No snapshot exists to delete");
         return SUCCESS;
      }
   }

   my $data = $self->ExecuteVMRUN("deleteSnapshot","soft",$snapshotName);
   # vmrun sometimes throw the error after deleting snapshot so neglecting error
   if (!($data eq ``) && ($data !~ "One or more of the disks are busy")
       && ($data !~ "The file is already in use")) {
      $vdLogger->Error("Error occured while deleting the snapshot");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Snap Shot $snapshotName has been deleted successfully.");
   return SUCCESS;
}

################################################################################
#  VMOpsDeleteAllSnapshots
#  Deletes all the snapshots of the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsDeleteAllSnapshots
{
   my $self = shift;
   my $snapShotArrayRef = $self->GetListOfSnapshots();
   my @snapShotArray = @$snapShotArrayRef;
   my $snapShot = '';

   foreach $snapShot (@snapShotArray) {
      my $res = $self->VMOpsDeleteSnapshot($$snapShot);
      if ($res eq "FAILURE") {
         $vdLogger->Error("Error deleting snapshots. All snapshots may not"
			." have been deleted");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   return SUCCESS;
}

################################################################################
#  GetListOfSnapshots
#  Returns the list of all snapshots for a particular VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed
#
#  Side effects:
#       none
#
################################################################################

sub GetListOfSnapshots
{
   my $self = shift;
   my @result;

   my $data = $self->ExecuteVMRUN("listSnapShots","soft");
   @result = split(/\n/, $data);

   my @snapshotList = ();
   my $snapshot='';
   foreach $snapshot (@result) {
      if (!($snapshot =~ m/Total/i && $snapshot =~ m/snapshots:/i)) {
         push(@snapshotList, \$snapshot);
      }
   }
   if(@snapshotList == 0) {
      return FAILURE;
   } else {
      return \@snapshotList;
   }
}

################################################################################
#  GetCurrentSnapshot
#
#  Algorithm:
#      Returns the name of the most recent snapshot.
#
#  Input:
#      none
#
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       none
#
################################################################################

sub GetCurrentSnapshot
{
   my $self = shift;
   my @result;

   my $data = $self->ExecuteVMRUN("listSnapshots","soft");
   @result = split(/\n/, $data);
   # Checking if the number of snapshots is 0, then return 0;
   if ($result[0] =~ m/Total/i && $result[0] =~ m/snapshots:/i) {
      my @splitArray = split(":", $result[0]);
      my $numberOfSnapshots = $splitArray[@splitArray - 1];
      $numberOfSnapshots =~ s/^\s+|\s+$//g;
      if($numberOfSnapshots eq "0") {
         return "0";
      }
   }
   my $mostRecentSnapshot = $result[@result - 1];
   $mostRecentSnapshot =~ s/^\s+|\s+$//g;
   if (not defined $mostRecentSnapshot) {
      $vdLogger->Error("Error occured while retrieving the most recent".
		       " snapshot");
      VDSetLastError("EINVALID");
      return FAILURE;
   } else {
      return $mostRecentSnapshot;
   }
}

################################################################################
#  VMOpsHotRemovevNIC
#
#  Algorithm:
#     Find ethernet unit number by grepping in vmx using MAC address, then use
#     vmdhsh to hot remove vNIC. Again verify by checking for
#     ethernetX.present = False
#
#  Input:
#       MAC address of vNIC you want to hot remove (required)
#
#  Output:
#       SUCCESS if pass, FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsHotRemovevNIC
{
   my $self = shift;
   my $macAddressInput = shift;

   if (not defined $macAddressInput) {
      $vdLogger->Error("Mac address not supplied as a parameter. Exiting..");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $ethUnitNum = VDNetLib::Common::Utilities::GetEthUnitNum( $self->{_justHostIP},
                 $self->{_absoluteVMXPath}, $macAddressInput );
   if ( not defined $ethUnitNum || $ethUnitNum eq "FAILURE" ) {
      $vdLogger->Error("Error returned from function GetEthUnitNum\n");
      VDSetLastError( VDGetLastError() );
      return FAILURE;
   }
   # Preparing the series of command which will do hot remove
   my $command = "cd /vm/#_VMX/vmx/hotplug; begin; newidx ## ;"
	       . "set op deviceRemove; "
               . "set op/deviceRemove/in/key $ethUnitNum; cd .. ;end;";
   $self->ExecuteVMDBSH($command);
   # Let the hot plugging module add entries to vmx file thus wait
   if ($self->{staf}->WaitForSTAF($self->{vmIP}) eq FAILURE){
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $file = VDNetLib::Common::Utilities::CheckForPatternInVMX(
		$self->{_host}, $self->{_absoluteVMXPath}, "$ethUnitNum.present");

   # Logic to parse values of ethernetX.present and check if its false
   if ( defined $file && ($file =~ /TRUE/i) ) {
         $vdLogger->Error("$ethUnitNum.present is not saying FALSE\n");
         VDSetLastError("EFAIL");
         return FAILURE;
   } elsif ( defined $file && ($file eq "") ) {
      $vdLogger->Error("Error in parsing status of $ethUnitNum\n");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info("Successfully removed Virtual Adapter from vm.");
   return SUCCESS;
}


################################################################################
#  VMOpsHotAddvNIC
#
#  Algorithm:
#    Find the next available ethernet unit number by greping the vmx file
#    for ethernet[0-9].present = TRUE and then adding vNIC to next availabe unit
#    number.vmdbsh binary is given series of command to hot add vNIC.
#    Again verify hot add as well as read the vmx file for MAC address of vNIC
#    just added.
#
#  Input:
#      Adapter type: bridged, hostonly, nat (any 1 required)
#      vSwitch: (optional) string like vmnet0
#
#  Output:
#       SUCCESS if pass along with MAC address of vNIC hot added
#       FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsHotAddvNIC
{
   my $self = shift;
   my $deviceName = shift;
   my $vSwitch = shift;
   my $adapterType = shift;
   my $command;
   my @contents;
   my $availableNum =0;
   my $presentNum;

   if (not defined $deviceName || not defined $vSwitch) {
     $vdLogger->Error("DeviceName / Adapter type not defined. Exiting..");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }

   if (not defined $adapterType) {
      $adapterType = "custom";
   }

   # First grep the vmx file and find the next free adapter sequence number
   my $file = VDNetLib::Common::Utilities::CheckForPatternInVMX($self->{_host},
                        $self->{_absoluteVMXPath}, "ethernet[0-9].present");
   @contents = split(/\n/,$file);
   @contents = sort(@contents);
   # Logic for moving on to next available ethernet unit number for adding
   my $data;
   foreach $data (@contents) {
      if ( $data =~ /^\s*ethernet(\d*).*TRUE.*/ ) {
         $presentNum = $1;
         if ( $presentNum != $availableNum ) {
            last;
         } else {
             $availableNum++;
         }
      }
   }
   # if VM is power off then cold adding using updating the vmx file.
   if ($self->VMOpsIsVMRunning($self->{_absoluteVMXPath}) == 0) {
      $self->VMOpsReadWriteVMX("modify","ethernet$availableNum.present = "
			."\"TRUE\"", "ethernet$availableNum.present");
      $self->VMOpsReadWriteVMX("modify","ethernet$availableNum.connectionType = "
			."\"$adapterType\"", "ethernet$availableNum.connectionType");
      $self->VMOpsReadWriteVMX("modify","ethernet$availableNum.vnet = "
			."\"$vSwitch\"", "ethernet$availableNum.vnet");
      if (lc($deviceName) eq "vmxnet2") {
         $self->VMOpsReadWriteVMX("modify","ethernet$availableNum.features = "
			."\"15\"", "ethernet$availableNum.virtualDev");
         $deviceName = "vmxnet";
      }
      $self->VMOpsReadWriteVMX("modify","ethernet$availableNum.virtualDev = "
			."\"$deviceName\"", "ethernet$availableNum.virtualDev");
      $vdLogger->Info("Updated $self->{_absoluteVMXPath} file in poweroff
                      state.");
      return SUCCESS;
   }

   $command = "cd /vm/#_VMX/vmx/hotplug;begin;"
    ."newidx ##;set op deviceAdd;set op/deviceAdd/in/key ethernet$availableNum;"
    ."cd op/deviceAdd/in/options/;newidx #;"
    ."set key ethernet$availableNum.connectionType;"
    ."set value $adapterType;cd ..;newidx #;"
#    ."set key ethernet$availableNum.networkName;"
#    ."set value $vSwitch;cd ..;newidx #;"
    ."set key ethernet$availableNum.vnet;"
    ."set value $vSwitch;cd ..;newidx #;";
    if (lc($deviceName) eq "vmxnet2"){
       $command = $command
       ."set key ethernet$availableNum.virtualDev;"
       ."set value vmxnet;cd ..;newidx #;"
       ."set key ethernet$availableNum.features;"
       ."set value 15;";
       $deviceName = "vmxnet";
    } else {
       $command = $command
       ."set key ethernet$availableNum.virtualDev;"
       ."set value $deviceName;"
    }
    $command = $command."cd ..;cd ../../../../../../;end;";

   $self->ExecuteVMDBSH($command);

   # Wait for updating vmx file.
   sleep(5);
   # Verification of updated values

   $file = VDNetLib::Common::Utilities::CheckForPatternInVMX($self->{_host},
		 $self->{_absoluteVMXPath}, "ethernet$availableNum");
   @contents = split(/\n/,$file);
   my $flag = 0x0;
   foreach my $line (@contents) {
      chomp($line);
      switch($line){
	 case m/ethernet$availableNum\.present.*TRUE/ { $flag |= 0x1; }
	 case m/ethernet$availableNum\.virtualDev.*$deviceName/ { $flag |= 0x2; }
	 case m/ethernet$availableNum\.connectionType.*$adapterType/ {$flag |= 0x4; }
	 case m/ethernet$availableNum\.vnet.*$vSwitch/ { $flag |= 0x8; }
     }
   }
   if ($flag != 0xF) {
      $vdLogger->Error("Virtual Adapter of device $deviceName not added "
		       ."successfully.\n$file");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Check for STAF after hot add

   if ($self->{staf}->WaitForSTAF($self->{vmIP}) eq FAILURE){
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Info("Virtual Adapter added successfully.");
   return SUCCESS;
}


################################################################################
#   VMOpsConnectvNICCable
#
#  Algorithm:
#  Using VIX API.
#
#  Input:
#       1) MAC address of the vNIC you want to connect.
#
#  Output:
#       0 if pass along with MAC address of vNIC hot added
#       1 if fail
#
#  Side effects:
#       Yes. GOS should be up and running(Completely booted) or else the
#       behaviour will be inconsistent.
#
################################################################################

sub VMOpsConnectvNICCable
{
   my $self = shift;
   my $macAddress = shift;
   if(not defined $macAddress) {
      $vdLogger->Error("Mac Address not passed as parameter");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $device = $self->GetDeviceLabelFromMac($macAddress);
   if ($device eq FAILURE) {
      $vdLogger->Error("Device name could not be retrieved");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $arg = "$self->{_vmxPathForBashCommands}"."\*"."'modify'"."\*".
             "$device.startConnected = \"TRUE\""."\*".
             "$device.startConnected";
   my $ret = VDNetLib::Common::Utilities::EditFile($arg);
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to modify $device.startConnected entry in ".
                      "$self->{_vmxPathForBashCommands}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Succesfully connected the NIC");
   return SUCCESS;
}


################################################################################
#  VMOpsDisconnectvNICCable
#
#  Algorithm:
#  Using VIX API.
#
#  Input:
#       1) MAC address of the vNIC you want to disconnect.
#       2) stafIP: IP address to check for STAF,
#                  If this parameter is specified, this method will
#                  wait for staf to be running inside the
#                  guest before disconnecting cable
#                  (Optional)
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       Yes. GOS should be up and running(Completely booted) or else the
#       behaviour will be inconsistent.
#
################################################################################

sub VMOpsDisconnectvNICCable
{
   my $self = shift;
   my $macAddress = shift;
   if(not defined $macAddress) {
      $vdLogger->Error("Mac Address need to be provided");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $device = $self->GetDeviceLabelFromMac($macAddress);
   if ($device eq FAILURE) {
      $vdLogger->Error("Device name could not be retrieved");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $arg = "$self->{_vmxPathForBashCommands}"."\*"."'modify'"."\*".
             "$device.startConnected = \"FALSE\""."\*".
             "$device.startConnected";
   my $ret = VDNetLib::Common::Utilities::EditFile($arg);
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to modify $device.startConnected entry in ".
                      "$self->{_vmxPathForBashCommands}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($self->VMOpsPowerOff() eq FAILURE) {
      $vdLogger->Error("Failed to power off");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


################################################################################
#  VMOpsGetPowerState
#      Returns the power state of the VM as in whether it is powered on or is
#      suspended
#  Input:
#      none
#
#
#  Output:
#       1 if the VM is powered on
#       0 if the VM is powered off
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsGetPowerState()
{
   my $self = shift;
   my $powerState = 0;
   my @listOfPoweredOnVMs = $self->ListOfPoweredOnVMs();
   my $count = 0;
   my $vmxPath = $self->{_vmxPathForBashCommands};
   $vmxPath =~ s/^\s+|\s+$//g;
   while ($count < @listOfPoweredOnVMs) {
      $listOfPoweredOnVMs[$count] =~ s/^\s+|\s+$//g;
      if ($vmxPath =~ $listOfPoweredOnVMs[$count]) {
         $powerState = 1;
         return $powerState;
      } else {
         $count ++;
      }
   }
   return 0;
}

################################################################################
#  GetDeviceLabelFromMac
#      Returns the name of the adapter corresponding the mac address passed.
#  Input:
#      Mac Address.
#
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       none
#
################################################################################

sub GetDeviceLabelFromMac($)
{
   my $self = shift;
   my $macAddress = shift;
   my @macAddressLine;
   if(not defined $macAddress) {
      $vdLogger->Error("Mac address not provided. Cannot proceed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $count = 0;

   my $command = "start shell command \"grep -i \\\"$macAddress\\\" \\\"
      $self->{_vmxPathForBashCommands}\\\"\"
      wait returnstdout stderrtostdout";
   my $service = "process";
   (my $ret,my $data ) = $self->{stafHandle}->runStafCmd(
	$self->{_justHostIP}, $service, $command );
   if ( $ret eq FAILURE ) {
      $vdLogger->Error("Error with staf $command \n");
      VDSetLastError("ESTAF");
      return FAILURE;
   } else {
      @macAddressLine = split( /\n/, $data );
   }

   while ($count < @macAddressLine) {
      if($macAddressLine[$count] =~ m/ethernet/i) {
         my $deviceName = $macAddressLine[$count];
         $deviceName =~ /^([^\.]*)\./;
         return $1;
      } else {
         $count++;
      }
   }
   return FAILURE;
}



################################################################################
#  GetLibPath
#
#  Algorithm:
#      Returns the path where the vmrun binary is stored
#
#  Input:
#      none
#
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       none
#
################################################################################

sub GetLibPath
{
   my $self = shift;
   my $binPath = "";
   # Fetching the vmware binary location to conduct the VM Operations
   $vdLogger->Debug("Fetching the binary location for VM Operations");
   my $globalConfigObj;
   $globalConfigObj = new VDNetLib::Common::GlobalConfig;
   if ($self->{_hostType} =~ /darwin/i || $self->{_hostType} =~ /mac/i ) {
      $binPath = $globalConfigObj->VmwareLibPath(
            VDNetLib::Common::GlobalConfig::OS_MAC);
   } elsif ($self->{_hostType} =~ /linux/i) {
      $binPath = $globalConfigObj->VmwareLibPath(
            VDNetLib::Common::GlobalConfig::OS_LINUX);
   } elsif ($self->{_hostType} =~ /win/i) {
      $binPath = $globalConfigObj->VmwareLibPath(
            VDNetLib::Common::GlobalConfig::OS_WINDOWS);
   } else {
      $vdLogger->Error("OS not supported by vdnet to operate hosted.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($binPath eq "") {
      $vdLogger->Error("Error getting the path to vmrun binary");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $result = $binPath;
   return $result;
}


################################################################################
#  ListOfPoweredOnVMs
#      Returns the list of VMs that are powered ON.
#
#  Input:
#      none
#
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       none
#
################################################################################

sub ListOfPoweredOnVMs()
{
   my $self = shift;
   my @cmd;

   my $data = $self->ExecuteVMRUN("list","soft");
   @cmd = split(/\n/, $data);

   my @listOfPoweredOnVMs = ();
   if ($cmd[0] =~ m/Total running VMs:/i) {
      my $count = 1;
      while($count<@cmd) {
         push(@listOfPoweredOnVMs, $cmd[$count]);
         $count++;
      }
      return @listOfPoweredOnVMs;
   } else {
      $vdLogger->Error("The running VMs could not be obtained");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}

################################################################################
#  GetVmdbshToolBinary
#      Returns the path to the vmdbsh binary
#
#  Input: none
#
#  Output:
#       Path to vmdbsh binary if pass
#       FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub GetVmdbshToolBinary
{
   my $self = shift;
   # Attaching the binary to the staf command according to the OS type.
   my $np = new VDNetLib::Common::GlobalConfig;
   my $binpath;
   my $binary;
   if ( $self->{_hostType} =~ /^win/i ) {
      $binpath = $np->BinariesPath(VDNetLib::Common::GlobalConfig::OS_WINDOWS);
      $binary  = "$binpath" . "x86_32/windows/vmdbsh.exe";
   } elsif ($self->{_hostType} =~ /mac|darwin/i ) {
      $binpath = $np->BinariesPath(VDNetLib::Common::GlobalConfig::OS_MAC);
      $binary  = "$binpath" . "x86_32/esx/vmdbsh";
   } elsif ($self->{_hostType} =~ /linux/i ) {
      $binpath = $np->BinariesPath(VDNetLib::Common::GlobalConfig::OS_LINUX);
      $binary  = "$binpath" . "x86_32/esx/vmdbsh";
   } else {
      $binpath = $np->BinariesPath(VDNetLib::Common::GlobalConfig::OS_ESX);
      $binary  = "$binpath" . "x86_32/esx/vmdbsh";
   }
   if (not defined $binary) {
      $vdLogger->Error("Cannot get vmdbsh binary path");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $binary;
}

################################################################################
#  GetNatConfPath
#      Returns the path to the nat.conf
#
#  Input: none
#
#  Output:
#       Path to vmdbsh binary if pass
#       FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub GetNatConfPath
{
   my $self = shift;
   my $np = new VDNetLib::Common::GlobalConfig;
   my $confpath = "";
   my $confFile;
#TODO implement a function to get configuration file.
   if ( $self->{_hostType} =~ /^win/i ) {
      #$confpath = $np->ConfPath(VDNetLib::Common::GlobalConfig::OS_WINDOWS);
      $confFile = "C:\\ProgramData\\VMware\\vmnetnat.conf";
   } elsif ($self->{_hostType} =~ /mac|darwin/i ) {
      #$confpath = $np->ConfPath(VDNetLib::Common::GlobalConfig::OS_MAC);
      $confFile  = "$confpath" . "nat.conf";
   } elsif ($self->{_hostType} =~ /linux/i ) {
      #$confpath = $np->ConfPath(VDNetLib::Common::GlobalConfig::OS_LINUX);
      $confFile = "/etc/vmware/vmnet8/nat/nat.conf";
   } else {
      #$confpath = $np->ConfPath(VDNetLib::Common::GlobalConfig::OS_ESX);
      #$binary  = "$binpath" . "x86_32/esx/vmdbsh";
   }

   return $confFile;
}

################################################################################
#  ExecuteVMDBSH
#      execute vmdbsh command and return result
#
#  Input:
#     command: vmdbsh command
#
#  Output:
#       data  is output
#       FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub ExecuteVMDBSH
{
   my $self = shift;
   my $commands = shift;
   my $wincmd = STAF::WrapData("\"connect -v \\\"$self->{_absoluteVMXPath}\\\";"
	     ."mount /vm;"
	     .$commands."exit\"");
   $vdLogger->Debug("Executing vmdbsh command $wincmd");
   my $newcommand = "start shell command $self->{vmdbsh} -e "
                . $wincmd
                . " wait returnstdout stderrtostdout";
   my ( $ret, $data ) = $self->{stafHandle}
            ->runStafCmd( $self->{_justHostIP}, "process", $newcommand );
   if ( $ret eq FAILURE ) {
      $vdLogger->Error("error with staf $newcommand \n");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $data;
}

################################################################################
#  VMOpsSetvNICConnectionType
#    Changing the connection type of vNIC e.g. bridged to hostonly
#
#  Input:
#      connectionType: connection type in which vNIC will go
#      macAddress: source vNIC mac address of the vNIC
#      vmnetName: (Optional) only required in custom mode
#  Output:
#       SUCCESS if adapter type is changed.
#       FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsSetvNICConnectionType
{
   my $self = shift;
   my $options = shift;
   my $connectionType = $options->{ConnectionType};
   my $macAddress = $options->{MACAddress};
   my $vmnetName = $options->{VMNet};

   if(not defined $connectionType) {
     $vdLogger->Error("Connection type not supplied as a parameter. Exiting..");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }
   if(not defined $macAddress) {
     $vdLogger->Error("MAC Address is not supplied as a parameter. Exiting..");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }

   $vdLogger->Info("Changing the Adapter of mac $macAddress mode to "
		."$connectionType network.");
   my $ethUnitNum = VDNetLib::Common::Utilities::GetEthUnitNum( $self->{_justHostIP},
                 $self->{_absoluteVMXPath}, $macAddress );
   if (not defined $ethUnitNum || $ethUnitNum eq "FAILURE") {
      $vdLogger->Error("Error returned from function GetEthUnitNum\n");
      VDSetLastError( VDGetLastError() );
      return FAILURE;
   }

   my $connection = join(".",($ethUnitNum,"connectionType"));
   my $oldConnectionType = VDNetLib::Common::Utilities::CheckForPatternInVMX(
			$self->{_host}, $self->{_absoluteVMXPath}, $connection);

   if ($oldConnectionType eq FAILURE) {
      $vdLogger->Error("Failed to get pattern $connection in
				$self->{_absoluteVMXPath}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if ($oldConnectionType =~ $connectionType) {
      $vdLogger->Info("Adapter is already in $connectionType mode.");
      return SUCCESS;
   }
   my $command;
   my $data;
   $connectionType = lc($connectionType);
   if ($connectionType ne "nat" && $connectionType ne "hostonly" &&
       $connectionType ne "bridged" && $connectionType ne "custom") {
      $vdLogger->Error("$connectionType is not supported in hosted.");
      return FAILURE;
   }
   my $ethNo;
   if ($ethUnitNum =~ /^\s*ethernet(\d*).*/) {
      $ethNo = $1;
   }

   $connectionType =~ s/hostonly/hostOnly/;
   if ($connectionType =~ "custom") {
      if (not defined $vmnetName) {
         $vdLogger->Error("vmnetName should be defined if adapter mode "
                         ."is custom.");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $command = "cd /vm/#_VMX/vmx/cfgState;"
      ."set req/#17/val/dev/#_nic$ethNo/class/nic/hostif/ $connectionType;"
      ."set req/#17/val/dev/#_nic$ethNo/class/nic/hostif/custom/vmnet/ "
      ."/dev/$vmnetName;"
      ."set new ../req/#17;";
   } else {
      $command = "cd /vm/#_VMX/vmx/cfgState;"
      ."set req/#17/val/dev/#_nic$ethNo/class/nic/hostif/ $connectionType;"
      ."set new ../req/#17;";
   }
   $data = $self->ExecuteVMDBSH($command);
   #varification of changed value
   $ethUnitNum = VDNetLib::Common::Utilities::GetEthUnitNum( $self->{_justHostIP},
                 $self->{_absoluteVMXPath}, $macAddress );
   $connection = join(".",($ethUnitNum,"connectionType"));
   my $newConnectionType = VDNetLib::Common::Utilities::CheckForPatternInVMX(
			$self->{_host}, $self->{_absoluteVMXPath}, $connection);

   if ($newConnectionType =~ $connectionType) {
      $oldConnectionType =~ s/(^.*=)|[\n "]//g;
      $vdLogger->Info("Adapter mode ".$oldConnectionType.
	" to $connectionType Successfully changed.");
      return SUCCESS;
   }
   $vdLogger->Error("Trying to change adapter mode from $oldConnectionType to"
                   ." $connectionType failed.");
   VDSetLastError("EFAIL");
   return FAILURE;
}

################################################################################
#  VMOpsGetvNICConnectionType
#    Getting the connection type of vNIC e.g. bridged
#
#  Input:
#      macAddress: source vNIC mac address of the vNIC
#  Output:
#       adapterType if adapter type .
#       FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsGetvNICConnectionType
{
   my $self = shift;
   my $macAddress = shift;
   my $vmnetName;

   if(not defined $macAddress) {
     $vdLogger->Error("MAC Address is not supplied as a parameter. Exiting..");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }

   my $ethUnitNum = VDNetLib::Common::Utilities::GetEthUnitNum( $self->{_justHostIP},
                 $self->{_absoluteVMXPath}, $macAddress );
   my $command = "cd /vm/#_VMX/vmx/cfgState;"
      ."get /val/dev/#_nic$ethUnitNum/class/nic/hostif/;";
   my $data = $self->ExecuteVMDBSH($command);
   if (($data eq FAILURE) or ($data eq "")){
      $vdLogger->Error("Failed to get adapter connection type.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return $data;
}

################################################################################
#  VMOpsSetvNICtrafficSpeed
#    Change the incomming transfer and outgoing transfer speed of vnic
#
#  Input:
#      macAddress: source vNIC mac address of the vNIC
#      trafficName: name of traffic type e.g. incoming, outgoing
#      traffic: hash reference of outgoing taffic
#      e.g.
#      TrafficHash = {
#           bandwidth => "", #mandatary
#           speed     => "", #optional
#           packetLoss=> "", #optional should be in %
#      }
#  Output:
#       SUCCESS if adapter type is changed.
#       FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub VMOpsSetvNICtrafficSpeed
{
   my $self = shift;
   my $macAddress = shift;
   my $trafficName = shift;
   my $traffic = shift;
   if(not defined $macAddress) {
     $vdLogger->Error("MAC Address is not supplied as a parameter. Exiting..");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }
   if(not defined $trafficName) {
     $vdLogger->Error("taffic name is not supplied as a parameter. Exiting..");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }
   if(not defined $traffic->{bandwidth}) {
     $vdLogger->Error("$trafficName Traffic bandwidth parameter is not defined.
		Exiting..");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }
   # define speed according to bandwidth value
   if ($traffic->{bandwidth} =~ /Modem-28.8/i) {
      $traffic->{speed} = "28";
   } elsif ($traffic->{bandwidth} =~ /Modem-56/i) {
      $traffic->{speed} = "56";
   } elsif ($traffic->{bandwidth} =~ /ISDN 1b-64/i) {
      $traffic->{speed} = "64";
   } elsif ($traffic->{bandwidth} =~ /ISDN 2b-64/i) {
      $traffic->{speed} = "128";
   } elsif ($traffic->{bandwidth} =~ /Leased Line-192/i) {
      $traffic->{speed} = "192";
   } elsif ($traffic->{bandwidth} =~ /Leased Line T1-1.544/i) {
      $traffic->{speed} = "1544";
   } elsif ($traffic->{bandwidth} =~ /Cable-4/i) {
      $traffic->{speed} = "4000";
   } elsif ($traffic->{bandwidth} =~ /Cable-10/i) {
      $traffic->{speed} = "10000";
   } elsif ($traffic->{bandwidth} =~ /Leased Line T3-45/i) {
      $traffic->{speed} = "45000";
   } elsif ($traffic->{bandwidth} =~ /Cable-100/i) {
      $traffic->{speed} = "100000";
   } elsif ($traffic->{bandwidth} =~ /Unlimited/i) {
      $traffic->{speed} = "-1";
   } else { if (not defined $traffic->{speed}) {
      $vdLogger->Error("Speed is not defined when bandwidth is custom.");
      VDSetLastError("EFAIL");
      return FAILURE;
      }
   }

   my $numPackets = 0;
   if(defined $traffic->{packetLoss} && $traffic->{packetLoss} > 0) {
     $traffic->{packetLoss} *= 10;
     $numPackets = 1;
   } else {
     # Assign default value if it is not defined.
     $traffic->{packetLoss} = 0;
   }
   my $ethUnitNum = VDNetLib::Common::Utilities::GetEthUnitNum( $self->{_justHostIP},
                 $self->{_absoluteVMXPath}, $macAddress );
   if ( not defined $ethUnitNum || $ethUnitNum eq "FAILURE") {
      $vdLogger->Error("Error returned from function GetEthUnitNum\n");
      VDSetLastError( VDGetLastError() );
      return FAILURE;
   }

   my $ethNo;
   if ($ethUnitNum =~ /^\s*ethernet(\d*).*/) {
      $ethNo = $1;
   }

   my $command = "cd /vm/#_VMX/vmx/cfgState;"
   ."set req/#17/val/dev/#_nic$ethNo/class/nic/bandwidthLimitKbps/$trafficName/"
   ." $traffic->{speed};"
   ."set req/#17/val/dev/#_nic$ethNo/class/nic/packetLoss/$trafficName/"
   ."millirate/ $traffic->{packetLoss};"
   ."set req/#17/val/dev/#_nic$ethNo/class/nic/packetLoss/$trafficName/"
   ."numPackets/ $numPackets;"
   ."set new ../req/#17;";
   my $data = $self->ExecuteVMDBSH($command);
   #varification of changed value
   my $file = VDNetLib::Common::Utilities::CheckForPatternInVMX($self->{_host},
                                $self->{_absoluteVMXPath}, $macAddress);
   if (not defined $file) {
      $vdLogger->Error("Mac Address not present in $self->{_absoluteVMXPath}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my @adapter = split(/\./,$file);
   my $xLimit;
   my $xDropSize;
   my $xDropRate;
   if ($trafficName eq "incoming") {
      $xLimit = join(".",($adapter[0],"rxbw.limit"));
      $xDropSize = join(".",($adapter[0],"rxfi.dropsize"));
      $xDropRate = join(".",($adapter[0],"rxfi.droprate"));
   } else {
      $xLimit = join(".",($adapter[0],"txbw.limit"));
      $xDropSize = join(".",($adapter[0],"txfi.dropsize"));
      $xDropRate = join(".",($adapter[0],"txfi.droprate"));
   }
   my @temp;
   # temp array used for result return by grep
   my $flag = 0;
   # Validating all the value updated
   $file = VDNetLib::Common::Utilities::CheckForPatternInVMX($self->{_host},
                                $self->{_absoluteVMXPath}, $xLimit);
   if (defined $file && ($file =~ /.*=.*$traffic->{speed}/)){
      $vdLogger->Debug("$trafficName speed is updated successfully.");
   } else {
      $flag = 1;
   }

   $file = VDNetLib::Common::Utilities::CheckForPatternInVMX($self->{_host},
                                $self->{_absoluteVMXPath}, $xDropSize);
   if (defined $file && ($file =~ /.*=.*$numPackets/)){
      $vdLogger->Debug("$trafficName Drop Size is updated successfully.");
   } else {
      $flag = 1;
   }

   $file = VDNetLib::Common::Utilities::CheckForPatternInVMX($self->{_host},
                                $self->{_absoluteVMXPath}, $xDropRate);
   if (defined $file && ($file =~ /.*=.*$traffic->{packetLoss}/)){
      $vdLogger->Debug("$trafficName Drop rate is updated successfully.");
   } else {
      $flag = 1;
   }
   # Check if any one of them not updated
   if ($flag) {
      $vdLogger->Error("$trafficName Traffic is not updates successfully.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info("vNIC Traffic speed is updated successfully.");
   return SUCCESS;
}

################################################################################
#  GetVMDBNumFromMAC
#    Getting the nic number stored in vmdb database
#
#  Input:
#      macAddress: source vNIC mac address of the vNIC
#  Output:
#       $nicNo adapter number in vmdb database.
#       FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub GetVMDBNumFromMAC
{
   my $self = shift;
   my $macAddress = shift;
   if(not defined $macAddress) {
     $vdLogger->Error("MAC Address is not supplied as a parameter. Exiting..");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }
   $vdLogger->Info("Getting vnic number in vmdb database of mac $macAddress.");
   my $nicNo=0;
   my $data;
   my $command;
   while ($nicNo < 10) {
      $command =
      "get /vm/#_VMX/vmx/cfgState/val/dev/#_nic$nicNo/class/nic/address;";
      $data = $self->ExecuteVMDBSH($command);
      if ( $data =~ $macAddress ) {
         last;
      }
      $nicNo++;
   }
   if ( $nicNo < 10 ) {
      return $nicNo;
   } else {
      $vdLogger->Error("Adapterr of MAC Address $macAddress is not present.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}

################################################################################
#  VMOpsAssignMACAddress
#      Manually assign the mac address to the adapter
#
#  Input:
#      vnicNo: Adapter number stored in vmdb database
#      macAddress: explicit mac address in format xx:xx:xx:xx:xx:xx
#  Output:
#      SUCCESS: if test pass
#      FILURE: if test fail
#
#  Side effects:
#       none
#
################################################################################
sub VMOpsAssignMACAddress
{
   my $self = shift;
   my $vnicNo = shift;
   my $macAddress = shift;
   if (not defined $macAddress) {
      $vdLogger->Error("MAC Address is not supplied as a parameter. Exiting..");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if (not defined $vnicNo) {
      $vdLogger->Error("vNIC number of vmdb is not supplied as a parameter.
			Exiting..");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($vnicNo < 0 && $vnicNo > 9) {
      $vdLogger->Error("vNIC number provided is not supported in VM.
			It should be [0-9].");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($macAddress !~ /^([0-9a-fA-F]{2}[:]){5}([0-9a-fA-F]{2})$/) {
      $vdLogger->Error("MAC Address provided is not in correct format.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $command = "cd /vm/#_VMX/vmx/cfgState;"
	."set req/#17/val/dev/#_nic$vnicNo/class/nic/address/ $macAddress;"
	."set new ../req/#17;";
   $self->ExecuteVMDBSH($command);

   my $vmxMac = VDNetLib::Common::Utilities::CheckForPatternInVMX($self->{_host},
                $self->{_absoluteVMXPath}, "ethernet".$vnicNo.".generatedAddress");
   if (not defined $vmxMac || $vmxMac eq FAILURE || $vmxMac !~ $macAddress) {
      $vdLogger->Error("Failed to modify the mac address to $macAddress"
                      ." of ethernet$vnicNo.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

################################################################################
#  VMOpsReadWriteVMX
#      API to add, delete or modify line in vmx file
#  Input:
#       editOption - insert - Insert a line
#                    delete - delete a matching line
#                    modify - modify a line with new content
#       Line       - Line that you want to insert, modify or delete
#       MatchString- Line that you want to insert, modify or delete
#                    (This is optional input and is required only
#                    when task is modify. If line to be modified is
#                    available in the given file, we use the line
#                    parameter, to replace a matched line.).
#  Output:
#      SUCCESS: if test pass
#      FILURE: if test fail
#
#  Side effects:
#       none
#
################################################################################
sub VMOpsReadWriteVMX
{
   my $self = shift;
   my $editOption = shift;
   my $line = shift;
   my $matchString = shift;

   # make arguments as string seperated by *
   my $arg = '';
   if (not defined $matchString) {
      $arg = "$self->{_vmxPathForBashCommands}"."\*".$editOption."\*".$line;
   } else {
      $arg = "$self->{_vmxPathForBashCommands}"."\*".$editOption."\*".
             $line."\*".$matchString;
   }

   my $ret = VDNetLib::Common::Utilities::EditFile($arg);
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to update entry $line in ".
                      "$self->{_vmxPathForBashCommands}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Successfully updated $self->{_vmxPathForBashCommands}"
                   ." file.");
   return SUCCESS;
}

################################################################################
#  ConnectAtPowerOn
#      Function used to change checkbox value of connect at poweron
#  Input:
#      macAddress: vNIC mac address
#      startConnected: used for check and uncheck the checkbox (true/false)
#                      default is yes
#  Output:
#      SUCCESS: if test pass
#      FILURE: if test fail
#
#  Side effects:
#       none
#
################################################################################
sub ConnectAtPowerOn
{
   my $self = shift;
   my $macAddress = shift;
   my $startConnected = shift;
   if(not defined $macAddress || not defined $startConnected) {
     $vdLogger->Error("MAC Address or Start connect is not supplied as"
                     ." parameter.Exiting..");
     VDSetLastError("EOPFAILED");
     return FAILURE;
   }
   my $checkvalue;
   if (defined $startConnected && $startConnected =~ /no/i){
      $checkvalue = 0;
   } elsif (defined $startConnected && $startConnected =~ /yes/i) {
      $checkvalue = 1;
   } else {
      $vdLogger->Error("$startConnected is not supported. It should be Yes/No");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $ethUnitNum = VDNetLib::Common::Utilities::GetEthUnitNum($self->{_justHostIP},
                 $self->{_absoluteVMXPath}, $macAddress );
   if (not defined $ethUnitNum || $ethUnitNum eq "FAILURE") {
      $vdLogger->Error("Error returned from function GetEthUnitNum\n");
      VDSetLastError( VDGetLastError() );
      return FAILURE;
   }
   my $ethNo;
   if ($ethUnitNum =~ /^\s*ethernet(\d*).*/) {
      $ethNo = $1;
   }
   my $command = "cd /vm/#_VMX/vmx/cfgState;"
      ."set req/#17/val/dev/#_nic$ethNo/media/removable/startConnected/ "
      ."$checkvalue;"
      ."set new ../req/#17;";
   my $data = $self->ExecuteVMDBSH($command);
   #verification
   my $startStatus = join(".",($ethUnitNum,"startConnected"));
   my $statusLine = VDNetLib::Common::Utilities::CheckForPatternInVMX($self->{_host},
                                $self->{_absoluteVMXPath}, $startStatus);
   if (not defined $statusLine || ($statusLine !~ $startConnected)) {
      $vdLogger->Error("Failed to update the Connect at power on to "
                      ."$startConnected");
      VDSetLastError("EFAIL");
      return FAILURE
   }
   $vdLogger->Info("Successfully updated Connect at power on to "
                  ."$startConnected");
   return SUCCESS;
}

#############################################################################
#
# VMOpsChangePortgroup --
#     Method to change the portgroup(we say vmnet for hosted) of a virtual
#     network adapter.
#
# Input:
#     macAddress: mac address of the adapter to be disconnected # Required
#     vswitch: vmnet name (ensure this portgroup(vmnet) exists)
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
   my $vswitch = shift;
   if ((not defined $macAddress) || (not defined $vswitch)) {
      $vdLogger->Error("MAC address and/or portgroup(vswitch) of the device
			not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->VMOpsSetvNICConnectionType("custom",$macAddress,$vswitch);
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
#     array of hash with following keys
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
   my $nicsInfo;
   my $osType = undef;

   my @etherInfo = split("\n",VDNetLib::Common::Utilities::CheckForPatternInVMX(
			$self->{_host}, $self->{_absoluteVMXPath}, "ethernet"));

   # $array is ref of array containing hash ref which will return as output
   my $array;
   # Converting keys and values into hash format.
   foreach (@etherInfo) {
      my @KV = split("=",$_);
      my $key = $KV[0];
      my $value = $KV[1];
      if ($key =~ /ethernet(\d)\.(.*)/i) {
         my $index = $1;
         $key = $2;
         $key =~ s/\s//g;
         if (not defined $array->[$index]) {
            $array->[$index] = {};
         }
         $value =~ s/^ |\"//g;
         $array->[$index]->{$key} = $value;
      }
   }
   # Mapp keys according to supported ESX keys.
   my $vdnetAdapterInfo;
   my $i = 0;
   my $j = 0;
   foreach (@$array) {
      if (defined $_->{present} && $_->{present} =~ /TRUE/i) {
         $vdnetAdapterInfo->[$j]->{'ADAPTER CLASS'} =
            defined $_->{virtualDev} ? "Virtual".ucfirst($_->{virtualDev}):
				       "VirtualUndefined",
         $vdnetAdapterInfo->[$j]->{Label} = "Network Adapter $i",
         $vdnetAdapterInfo->[$j]->{'MAC Address'} =
            defined $_->{address} ? $_->{address}:$_->{generatedAddress};
         if ((not defined $_->{connectionType}) ||
			($_->{connectionType} =~ /bridged/i)) {
            $vdnetAdapterInfo->[$j]->{NETWORK} = "VM Network",
            $vdnetAdapterInfo->[$j]->{PortGroup} = "VM Network",
         } elsif ($_->{connectionType} =~ /custom/i) {
            $vdnetAdapterInfo->[$j]->{NETWORK} = $_->{vnet},
            $vdnetAdapterInfo->[$j]->{PortGroup} = $_->{vnet},
         } else {
            $vdnetAdapterInfo->[$j]->{NETWORK} = $_->{connectionType},
            $vdnetAdapterInfo->[$j]->{PortGroup} = $_->{connectionType},
         }
         my $key;
         my $value;
         while (($key, $value) = each(%$_)){
            $vdnetAdapterInfo->[$j]->{$key} = $value;
         }
         $j++;
      }
      $i++;
   }
   #
   # Make all hash keys to lower case to match with the output
   # format of GetAdapterInfo() in ESXSTAF4xVMOperations.pm
   #

   foreach my $adapter (@{$vdnetAdapterInfo}) {
      %$adapter = (map { lc $_ => $adapter->{$_}} keys %$adapter);
   }

   $vdLogger->Debug("Adapters information on $self->{_absoluteVMXPath}:\n"
		    .Dumper($vdnetAdapterInfo));
   return $vdnetAdapterInfo;
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
   if ($device !~ /(floppy|serial|parallel|^cd|ethernet)/i) {
      $vdLogger->Error("Unsupported Device:$device");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Getting devices which are presents
   my @presentDevices = split('\n',
		VDNetLib::Common::Utilities::CheckForPatternInVMX(
		$self->{_host}, $self->{_absoluteVMXPath}, "present"));

   foreach (@presentDevices) {
      if ($_ =~ /$device.*TRUE/i){
	 return 1;
      }
   }
   return 0;
}

########################################################################
#
# VMOpsAddRemoveVirtualDevice --
#     Method to attach or remove a virtual device to/from a powered off VM.
#     Supported devices by this method are 'FLOPPY DRIVE' or
#    'CD/DVD DRIVE' or 'Serial port' or 'Parallel port'
#
# Input:
#     task - (add or remove)
#     deviceType (mandatory)
#     deviceName (optional) - when task is remove and deviceType is not
#                             CDROM
#
# Results:
#     "SUCCESS", if device is successfully added or removed.
#     "FAILURE", in case of any error.
#
# Side effects:
#
#
########################################################################

sub VMOpsAddRemoveVirtualDevice
{
   my $self = shift;
   my $deviceType = shift;
   my $task = shift;
   my $deviceName = shift || undef;
   my $initPowerState;
   my $vmName = $self->{_absoluteVMXPath};
   my $result;

   if((not defined $task) || (not defined $deviceType)) {
      $vdLogger->Error("deviceName or task misssing in ".
                       "VMOpsAddRemoveVirtualDevice");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Checking for supported values
   if($task !~ /(add|remove)/i ||
      $deviceType !~ /(floppy|serial|parallel|^cd|ethernet)/i ) {
      $vdLogger->Error("Unsupported Device:$deviceType or Task:$task");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $devStat;
   $devStat = "TRUE" if $task =~ /add/i;
   $devStat = "FALSE" if $task =~ /remove/i;

   # Getting all information about the deviceType
   my $data = VDNetLib::Common::Utilities::CheckForPatternInVMX(
		$self->{_host}, $self->{_absoluteVMXPath}, $deviceType);
   if (not defined $data) {
      $vdLogger->Error("Unable to find the information about the device $deviceType.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my @devicesStats = split("\n",VDNetLib::Common::Utilities::CheckForPatternInVMX($deviceType));

   if (!scalar(@devicesStats)) {
      $result = $self->VMOpsReadWriteVMX("insert",$deviceType.
                                         "0.present = \"$devStat\"");
      $vdLogger->Info("Device ".uc($deviceType)." ".$devStat."ed successfully"
		     ." on $vmName ");
      return SUCCESS;
   }
   foreach my $presentStats (@devicesStats){
      if ($presentStats =~ /present.*$devStat/i) {
         $vdLogger->Info("Device $deviceType is already $task"."ed.");
         return SUCCESS;
      }
   }
   # Check if CD ROM is connected. If not then
   # Check the state of the VM. If running then power it down.
   # VMOpsGetPowerState() return 1 if VM is power on
   $result = $self->VMOpsGetPowerState();

   $initPowerState = $result;

   # Check the state of the VM. If running then power it down.
   if ($result) {
      $vdLogger->Info("Powering off VM $self->{_absoluteVMXPath} to $task "
		     ."$deviceType.");
      $result =  $self->VMOpsPowerOff();
     if ($result eq FAILURE) {
        $vdLogger->Error("Failed to power off VM $self->{_absoluteVMXPath}");
        VDSetLastError(VDGetLastError());
        return FAILURE;
     }
   }

   my $oldDeviceStats;
   foreach my $newDeviceStats (@devicesStats){
      if ($newDeviceStats !~ /present/) {
	 next;
      }
      $oldDeviceStats = $newDeviceStats;
      $newDeviceStats =~ s/".*"/"$devStat"/i;
      $result = $self->VMOpsReadWriteVMX("modify",$newDeviceStats,$oldDeviceStats);
      if ($result eq FAILURE) {
         return FAILURE;
      }
   }

   # We bring the VM back in the same state as it was before
   # after adding/removing the virtual CDROM.
   if ($initPowerState =~ /1/i) {
      $result = $self->VMOpsPowerOn();
      if ($result  eq FAILURE ) {
         $vdLogger->Error( "Powering on VM failed ");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
      # We can do WaitForVDNet if this creates issues in future.
      $vdLogger->Info("Waiting for STAF on $self->{'vmIP'} ...");
      $result = $self->{stafHelper}->WaitForSTAF($self->{'vmIP'});
      if ($result  eq FAILURE ) {
         $vdLogger->Error( "WaitForSTAF failed on $self->{'vmIP'} ".
                           "in VMOpsAddRemoveVirtualDevice");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
   }

   # Get the current state of the VM and verify that device got
   # added or removed
   my $devStatus = $self->VMOpsDeviceAttachState($deviceType);
   if ($devStatus eq 0 && $task =~ /add/i) {
      $vdLogger->Error("Didnt add $deviceType to $vmName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   } elsif ($devStatus ne 0 && $task =~ /remove/i) {
      # A VM might have more than one devices of that type
      $vdLogger->Info("Removed one ".uc($deviceType)." but still more ".
                      uc($deviceType). " devices are attached to $vmName");
      return SUCCESS;
   } elsif ($devStatus ne 0 && $task =~ /add/i) {
        $vdLogger->Info("Device ".uc($deviceType)." added successfully on $vmName ");
        return SUCCESS;
   } elsif ($devStatus eq 0 && $task =~ /remove/i) {
        $vdLogger->Info("All $deviceType devices removed successfully ".
                        "from $vmName ");
        return SUCCESS;
   }

   VDSetLastError(VDGetLastError());
   return FAILURE;
}

1;
