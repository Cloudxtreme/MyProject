#/* **********************************************************
# * Copyright 2009 VMware, Inc.  All rights reserved.
# * -- VMware Confidential
# * **********************************************************/

package VDNetLib::VM::ESXVMOperations;

use strict;
use warnings;

use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VIX";
use perl::foundryqasrc::TestBase;
use perl::foundryqasrc::TestConstants;
use perl::foundryqasrc::TestOutput;
use perl::foundryqasrc::Enumerations;
use perl::foundryqasrc::ManagedVM;
use perl::foundryqasrc::ManagedUtil;


# These packages belong with VIX-PERL API
use VMware::Vix::Simple;
use VMware::Vix::API::Constants;


# Inheriting from VMOperations package.
use vars qw /@ISA/;
@ISA = qw(VDNetLib::VM::VMOperations);

#-----------------------------------------------------------------------------
#  new (Constructor)
#
#  Algorithm:
#  Sets the variables specific to ESXVMOperations.
#
#  Input:
#       None
#
#  Output:
#       child Object of HostedVMOperations.
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------

sub new
{
   my $proto    = shift;
   my $class    = ref($proto) || $proto;
   my $hash_ref = shift;
   $hash_ref->{'_justHostIP'} = $hash_ref->{'_host'};
   $hash_ref->{'_host'}       = 'https://' . $hash_ref->{'_host'} . '/sdk';
   $hash_ref->{'_hostType'}   = "esx";
   $hash_ref->{'_vmxPath'} =
      VDNetLib::Common::Utilities::GetVMFSRelativePathFromAbsPath($hash_ref->{'_vmxPath'});
   $hash_ref->{'_absoluteVMXPath'} =
      VDNetLib::Common::Utilities::GetAbsFileofVMX( $hash_ref->{'_vmxPath'} );

   my $self = {

      # Right now I dont have any ESXVMOperation specific variables settings.
   };
   bless $self, $class;
   return $self;
}

# Methods specific to ESX Operations

#-----------------------------------------------------------------------------
#  InsterBackdoorLineESX
#
#  Algorithm:
#  Inserts backdoor lines in vmx file on ESX.
#  It is required for the CableDisconnect function to work on ESX
#
#  Input:
#  Object which has connection of ESX server.
#
#  Output:
#       child Object of HostedVMOperations.
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------

sub InsterBackdoorLineESX
{
   my $self = shift;
   my $line1 =
      'vix.commandSecurityOverride.VIX_COMMAND_CONNECT_DEVICE' . ' = \"TRUE\"';
   my $line2 = 'vix.commandSecurityOverride.VIX_COMMAND_IS_DEVICE_CONNECTED'
      . ' = \"TRUE\"';
   my @vmxlines = ( $line1, $line2 );
   my $pattern = "VIX_COMMAND_CONNECT\|VIX_COMMAND_IS_DEVICE_CONNECTED";

   my $data = VDNetLib::Common::Utilities::CheckForPatternInVMX(
		$self->{_justHostIP}, $self->{_absoluteVMXPath}, $pattern );

   if ( ( not defined $data ) || ( $data eq "" ) ) {
      TestError "adding VIX SemiPublic Backdoor lines to the vmxfile for vNIC CableDisconnect Functionality";
      if ( $self->VMOpsPowerOff() eq FAILURE ) {
    TestError "VM power off failed";
    VDSetLastError("EINVALID");
    return FAILURE;
      }

 #TODO: Use GetPowerState method to find power state instead of blindly sleeping
      sleep(45);

      if (
    VDNetLib::Common::Utilities::UpdateVMX( $self->{_justHostIP}, \@vmxlines,
       $self->{_absoluteVMXPath} ) eq FAILURE
    ) {
    TestError "Update vmxFile failed";
    VDSetLastError("EINVALID");
    return FAILURE;
      } else {
    if ( $self->VMOpsPowerOn() eq FAILURE ) {
       TestError "VM power On failed after updating vmx file";
       VDSetLastError("EINVALID");
       return FAILURE;
    }

      }
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsUnRegisterVM
#  Unregister the VM from ESX/ESXi
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed along with powerstate value
#       FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsUnRegisterVM
{
   my $self       = shift;
   my $passed     = 0;
   my $testobj    = 0;
   ( $passed, $testobj ) = $self->TestSetup(TP_HTU_HANDLE_USE_VM | TP_UNREG_ON_CLEANUP);
   if ($passed) {
      TestInfo "VMOps Unregistering VM from esx/esxi Started";
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}



#-----------------------------------------------------------------------------
#  GetNamedSnapshot
#  Gives the handle of snapshot with a specific name.
#
#  Input:
#       testObj        bunch of foundary qa handles anchored on host, vm, snaopshot, job
#       SnapshotName   Name of the snapshot you want to get handle of
#
#  Output:
#       SUCCESS if passed along with the handle to named snapshot.
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub GetNamedSnapshot($$)
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $passed               = 0;
   my $testobj              = 0;
   my $snapshotName;
   if ( 2 == @_ ) {
      $snapshotName = shift;
      $testobj      = shift;
   } else {
      TestError
"VM Ops Get Named Snapshot Called without name or testobj. Exiting....";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   TestInfo "VMOps Get Named Snapshot started ";
   $self->ClearGlobalParam();

   $passed =
      $testobj->GetManagedVM()
      ->GetNamedSnapshot( $testobj->GetHandleToUse(), $snapshotName, \%param );
   if ($passed) {
      $testobj->SetOutcome("PASS");
      $createSnapshotHandle = $param{ACTUAL_NAMEDSNAPSHOT_HANDLE};
      TestInfo "Test Passed";
   } else {
      $testobj->SetOutcome("FAIL");
      TestError "Test Failed";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return $passed, $createSnapshotHandle;
}

#-----------------------------------------------------------------------------
#  VMOpsTakeSnapshot
#  Just takes snapshot
#
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
#-----------------------------------------------------------------------------
sub VMOpsTakeSnapshot($)
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $passed               = 0;
   my $testobj              = 0;
   my $snapshotName;
   if ( 1 <= @_ ) {
      $snapshotName = shift;
   } else {
      TestError
    "VM Ops Take Snapshot called without a snapshot name. Exiting...";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   ( $passed, $testobj ) = $self->TestSetup( TP_HTU_HANDLE_USE_VM,
      VIX_POWERSTATE_POWERED_OFF | VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Take Snapshot Started";
      $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
      $passed = $testobj->GetManagedVM()->CreateSnapshot(
    $testobj->GetHandleToUse(),
    $snapshotName, $snapshotName, DEFAULT_CREATE_SNAPSHOT_OPTION,
    VIX_INVALID_HANDLE, \%param
      );

      if ($passed) {
    $createSnapshotHandle = $param{ACTUAL_SNAPSHOT_HANDLE};
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Take Snapshot Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Take Snapshot Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
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
#-----------------------------------------------------------------------------
sub VMOpsRevertSnapshot($)
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $snapshotName         = shift;
   my $passed               = 0;
   my $testobj              = 0;
   ( $passed, $testobj ) = $self->TestSetup( TP_HTU_HANDLE_USE_VM,
      VIX_POWERSTATE_POWERED_OFF | VIX_POWERSTATE_POWERED_ON );

   if (defined $snapshotName) {
      ($passed,$createSnapshotHandle ) =
         $self->GetNamedSnapshot($snapshotName, $testobj);
   } else {
      #
      # if snapshot name is not given then get the current snapshot, if any
      # exists.
      #
      $self->ClearGlobalParam();
      ($passed) =
         $testobj->GetManagedVM()->GetCurrentSnapshot($testobj->GetHandleToUse(),
                                                      \%param);
      $createSnapshotHandle = $param{ACTUAL_CURRENTSNAPSHOT_HANDLE};
   }

   # If there exists no snapshot, then return SUCCESS
   if (!$createSnapshotHandle) {
      TestWarning "Snapshot handle undefined or no snapshot exists to revert";
      return SUCCESS;
   }

   if ($passed) {
      TestInfo "VMOps Revert Snapshot Started";
      $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;

      #      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF;
      #      $param{EXPECTED_TOOL_STATE}  = VIX_TOOLSSTATE_UNKNOWN;
      $passed = $testobj->GetManagedVM()->RevertToSnapshot(
    $testobj->GetHandleToUse(),
    $createSnapshotHandle, DEFAULT_REVERT_SNAPSHOT_OPTION,
    VIX_INVALID_HANDLE, \%param
      );
      if ($passed) {

    # ReleaseHandle($createSnapshotHandle);
    # $createSnapshotHandle = VIX_INVALID_HANDLE;
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Revert Snapshot Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Revert Snapshot Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
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
#-----------------------------------------------------------------------------
sub VMOpsDeleteSnapshot($)
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $snapshotName = shift;
   my $passed               = 0;
   my $testobj              = 0;
   ( $passed, $testobj ) = $self->TestSetup( TP_HTU_HANDLE_USE_VM,
      VIX_POWERSTATE_POWERED_ON | VIX_POWERSTATE_POWERED_OFF );
   if (defined $snapshotName) {
      ($passed,$createSnapshotHandle ) =
         $self->GetNamedSnapshot( $snapshotName, $testobj );
   } else {
      #
      # if snapshot name is not given then get the current snapshot, if any
      # exists.
      #
      $self->ClearGlobalParam();
      ($passed) =
         $testobj->GetManagedVM()->GetCurrentSnapshot($testobj->GetHandleToUse(),
                                                      \%param);
      $createSnapshotHandle = $param{ACTUAL_CURRENTSNAPSHOT_HANDLE};
   }

   # If there exists no snapshot, then return SUCCESS
   if (!$createSnapshotHandle) {
      TestWarning "Snapshot handle undefined or no snapshot exists to delete";
      return SUCCESS;
   }

   if ($passed) {
      TestInfo "Test Started";
      $self->ClearGlobalParam();
      for (keys %param) {
        delete $hash{$_};
      }
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
      $passed =
    $testobj->GetManagedVM()->RemoveSnapshot( $testobj->GetHandleToUse(),
    $createSnapshotHandle, DEFAULT_REMOVE_SNAPSHOT_OPTION, \%param );
      if ($passed) {

    #         ReleaseHandle($createSnapshotHandle);
    #         $createSnapshotHandle = VIX_INVALID_HANDLE;
    $testobj->SetOutcome("PASS");
    TestInfo "Test Passed";
    $passed = 1;
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "Test Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
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
#-----------------------------------------------------------------------------
sub VMOpsDeleteAllSnapshots()
{
   my $createSnapshotHandle = VIX_INVALID_HANDLE;
   my $self                 = shift;
   my $passed               = 0;
   my $testobj              = 0;
   my $vmHandle             = undef;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Delete All snapshots started";
      $vmHandle = $testobj->GetVMHandle();
      my $numSnapshotsRemoved = 0;
      TestInfo "Removing all existing snapshots in VMOps";
      while ($passed) {
    $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
    $passed =
       $testobj->GetManagedVM->GetNumRootSnapshots( $vmHandle, \%param );
    if ( $passed && $param{ACTUAL_NUMROOTSNAPSHOTS} > 0 ) {
       $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
       $passed =
          $testobj->GetManagedVM->GetRootSnapshot( $vmHandle, 0, \%param );
       if ($passed) {
          $createSnapshotHandle = $param{ACTUAL_ROOTSNAPSHOT_HANDLE};
          $self->ClearGlobalParam();
         $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
          $passed =
        $testobj->GetManagedVM->RemoveSnapshot( $vmHandle,
        $createSnapshotHandle, DEFAULT_REMOVE_SNAPSHOT_OPTION,
        \%param );
          if ($passed) {
        $numSnapshotsRemoved = $numSnapshotsRemoved + 1;
          } else {
        TestError "Removing of snapshot failed";
          }
       } else {
          TestError "Removing of snapshot failed";
       }
    } else {
       last;
    }
      }    # end of while
      TestInfo "Removed " . $numSnapshotsRemoved . " snapshots.";
   }
   if ($passed) {
      TestInfo "VMOps Delete All snapshots  Passed";
   } else {
      TestInfo("VMOps Delete All snapshots  Failed");
      $testobj->SetOutcome("SETUPFAIL");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsWaitForToolsInGuest
#  TODO: Yet to be fully coded and testing. Will work on it if we have requirement for it.
#  VMOpsInstallTools
#  From VIX API Documentation
#  If the guest operating system has the autorun feature enabled, the installer starts
#  automatically. Many guest operating systems require manual intervention to complete
#  the Tools installation. You can connect a console window to the virtual machine and
#  use the mouse or keyboard to complete the procedure as described in the documentation
#  for your VMware platform product.
#  I did replace the second parameter with VIX_VM_SUPPORT_TOOLS_INSTALL
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsInstallTools()
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Install Tools Started";
      $passed =
    $testobj->GetManagedGuest()
    ->InstallTools( $testobj->GetVMHandle(), VIX_VM_SUPPORT_TOOLS_INSTALL,
    undef, \%param );

      # I guess you can check if the tools are up to date using this
      # $param{EXPECTED_ERROR} = VIX_E_TOOLS_INSTALL_ALREADY_UP_TO_DATE;
      # TODO: ask kishore if he need such functionality
      if ($passed) {
    TestInfo "VMOps Install Tools Passed";
      } else {
    TestError "VMOps Install Tools Failed";
    $testobj->SetOutcome("SETUPFAIL");
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsWaitForToolsInGuest
#  TODO: Yet to be fully coded and testing. Will work on it if we have requirement for it.
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed
#       FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsWaitForToolsInGuest
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Wait For Tools In Guest Started";
      $self->ClearGlobalParam();
      $passed =
    $testobj->GetManagedGuest()
    ->WaitForToolsInGuest( $testobj->GetHandleToUse(),
    TIMEOUT_WAIT_FOR_TOOLS_IN_SEC, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Wait For Tools In Guest Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Wait For Tools In Guest Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
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
#-----------------------------------------------------------------------------
sub VMOpsPowerOff
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Power Off Started";
      $self->ClearGlobalParam();
      $passed =
    $testobj->GetManagedVM()
    ->PowerOff( $testobj->GetHandleToUse(), POWEROPTION, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Power Off Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Power Off Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return $passed;
}

#-----------------------------------------------------------------------------
#  VMOpsPowerOn
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
#-----------------------------------------------------------------------------
sub VMOpsPowerOn
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) = $self->TestSetup( TP_HTU_HANDLE_USE_VM,
      VIX_POWERSTATE_POWERED_OFF | VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Power On Started";

      #      my %param = undef;
      $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
      $passed = $testobj->GetManagedVM()->PowerOn($testobj->GetHandleToUse(),
                                                  VIX_VMPOWEROP_LAUNCH_GUI,
                                                  0,
                                                  \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Power On Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Power On Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsResume
#  Powers on the VM which is a resume operation if the VM is suspended.
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
#-----------------------------------------------------------------------------
sub VMOpsResume
{
   my $self = shift;
   $self->VMOpsPowerOn;
}

#-----------------------------------------------------------------------------
#  VMOpsReset
#  Resets the VM.
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
#-----------------------------------------------------------------------------
sub VMOpsReset()
{
   my $self     = shift;
   my $passed   = 0;
   my $vmHandle = undef;
   my $testobj  = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Reset Started";
      $self->ClearGlobalParam();
      $vmHandle = $testobj->GetVMHandle();
      $passed =
    $testobj->GetManagedVM()->Reset( $testobj->GetHandleToUse(),
                                                 VIX_VMPOWEROP_NORMAL,
                                                 \%param );
      if ($passed) {
    TestInfo("VMOps Reset Passed");
    $testobj->SetOutcome("PASS");
      } else {
    TestError("VMOps Reset Failed");
    $testobj->SetOutcome("FAIL");
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
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
#-----------------------------------------------------------------------------
sub VMOpsSuspend
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Suspend Started";
      $self->ClearGlobalParam();
      $passed =
    $testobj->GetManagedVM()
    ->Suspend( $testobj->GetHandleToUse(), VIX_VMPOWEROP_NORMAL, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Suspend Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Suspend Failed";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


#-----------------------------------------------------------------------------
#   VMOpsConnectvNICCable
#
#  Algorithm:
#  Using VIX API.
#
#  Input:
#       1) MAC address of the vNIC you want to connect.
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       Yes. GOS should be up and running(Completely booted) or else the
#       behaviour will be inconsistent.
#
#-----------------------------------------------------------------------------
sub VMOpsConnectvNICCable()
{
   my $self   = shift;
   my $passed = 0;
   my $deviceName;
   my $macAddress;

   # Check if staf handle is created
   if ( not defined $self->{stafHandle}->{_handle} ) {
      TestError "STAF Handle in VMOperations object is undefined ";
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if staf is running on host
   if ( $self->{stafHandle}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ( lc( $self->{_productType} ) eq "esx" ) {

      # For cable disconnect to work VIX requires 2 lines in VMX file.
      $self->InsterBackdoorLineESX();
   }

   # Mapping from MAC address to ethernetX
   if ( 1 == @_ ) {
      $macAddress = shift;
      $deviceName = VDNetLib::Common::Utilities::GetEthUnitNum(
		$self->{_justHostIP}, $self->{_absoluteVMXPath}, $macAddress );
   } else {
      TestError "VM Ops Connect vNIC called without NIC name . Exiting...";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Connect vNIC Cable started";
      TestInfo "Calling a ConnectNamedDevice on $deviceName";
      $self->ClearGlobalParam();
      $passed =
    $testobj->GetManagedVM()
    ->ConnectNamedDeviceImpl( $testobj->GetHandleToUse(),
    $deviceName, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Connect vNIC Cable Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Connect vNIC Cable  Failed";
    VDSetLastError("ENETDOWN");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
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
#-----------------------------------------------------------------------------
sub VMOpsDisconnectvNICCable()
{
   my $self   = shift;
   my $macAddress = shift;
   my $stafIP = shift;
   my $passed = 0;
   my $deviceName;

   # Check if staf handle is created
   if ( not defined $self->{stafHandle}->{_handle} ) {
      TestError "STAF Handle in VMOperations object is undefined ";
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check if staf is running on host
   if ( $self->{stafHandle}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      TestError "STAF not running on $self->{_justHostIP} ";
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ( lc( $self->{_productType} ) eq "esx" ) {
      $self->InsterBackdoorLineESX();
   }

   if (defined $stafIP) {
      TestInfo "Waiting for STAF to be running inside the guest $stafIP";
      my $ret = $self->{stafHandle}->WaitForSTAF($stafIP);
      if ($ret ne SUCCESS) {
         TestError "STAF is not running on $stafIP";
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   if (defined $macAddress) {
      TestInfo "VMOpsDisconnectvNICCable: hostIP: " . $self->{_justHostIP} .
               " vmx path:" . $self->{_absoluteVMXPath} . " mac address: " .
               $macAddress;
      $deviceName = VDNetLib::Common::Utilities::GetEthUnitNum(
		$self->{_justHostIP}, $self->{_absoluteVMXPath}, $macAddress );
      if ($deviceName eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      TestError "VM Ops Connect vNIC called without NIC name . Exiting...";
      VDSetLastError("ENETDOWN");
      return FAILURE;
   }
   my $testobj = 0;
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {
      TestInfo "VMOps Disconnect vNIC Cable started";
      TestInfo "Calling a DisconnectNamedDevice on $deviceName";
      $self->ClearGlobalParam();
      $param{EXPECTED_POWER_STATE} = VIX_POWERSTATE_POWERED_OFF |
                                     VIX_POWERSTATE_POWERED_ON;
      $passed = $testobj->GetManagedVM()->PowerOn( $testobj->GetHandleToUse(),
    VIX_VMPOWEROP_LAUNCH_GUI, 0, \%param );
      $passed =
    $testobj->GetManagedVM()
    ->DisconnectNamedDeviceImpl( $testobj->GetHandleToUse(),
    $deviceName, \%param );
      if ($passed) {
    $testobj->SetOutcome("PASS");
    TestInfo "VMOps Disconnect vNIC Cable Passed";
      } else {
    $testobj->SetOutcome("FAIL");
    TestError "VMOps Disconnect vNIC Cable  Failed";
    VDSetLastError("EOPFAILED");
    return FAILURE;
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


#-----------------------------------------------------------------------------
#  VMOpsHotAddvNIC
#
#  Algorithm:
#    Find the next available ethernet unit number by greping the vmx file
#    for ethernet.present = TRUE and then adding vNIC to next unit number.
#    vmdbsh binary along with a wrapper script is used to hot add vNIC.
#    vmxnet2 needs ethernet.features = 15. Rest of the driver just need
#    driver name and port group
#    Again verify as well as read the vmx file for MAC address of vNIC
#    just added.
#
#  Input:
#       1) Any of driver Name: vmxnet, vmxnet2, vmxnet3, e1000
#       2) Port Group. eg vdtest, VM Network
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsHotAddvNIC
{
   my $self    = shift;
   my $passed  = 0;
   my $testobj = 0;
   my $driverType;
   my $portgroup;
   my $command;
   my $errorString;
   my $service;
   my $ret;
   my $data;
   my @data_array;
   my $handle;
   my $macAddress;
   my $presentNum;
   my $availableNum = 0;
   my $binary;

   # Validate input parameters
   if ( not defined $self->{stafHandle}->{_handle} ) {
      TestError "STAF Handle in VMOperations object is undefined ";
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ( 2 != @_ ) {
      TestError "VM hot add vNIC called wihout required parameters. Exiting...";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $driverType = shift;
   if (  $driverType ne "vmxnet"
      && $driverType ne "vmxnet2"
      && $driverType ne "vmxnet3"
      && $driverType ne "e1000" ) {
      TestError "Supported drivers are: vmxnet3, vmxnet, vmxnet2, or e1000"
    . " Others might corrupt the GOS";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $portgroup = shift;

   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ( !$passed ) {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if ( $self->{stafHandle}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      TestError "STAF is not running on $self->{_justHostIP} ";
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   #grep for ethernet entried which are present
   $command =
"start shell command \"grep -i \\\"^[' ']*ethernet[0-9]\\.present = \\\\\\\"TRUE\\\\\\\"\\\" \\\"$self->{_absoluteVMXPath}\\\" | sort -u \" wait returnstdout stderrtostdout";

   $service = "process";
   ( $ret, $data ) =
      $self->{stafHandle}
      ->runStafCmd( $self->{_justHostIP}, $service, $command );
   if ( $ret eq FAILURE ) {
      TestError "Error with staf $command @data_array ";
      VDSetLastError("ESTAF");
      return FAILURE;
   } else {
      @data_array = split( /\n/, $data );
   }

   # Move on to next available ethernet unit number of adding vNIC
   foreach $data (@data_array) {
      if ( $data =~ /^\s*ethernet(\d*).*/ ) {
    $presentNum = $1;
    if ( $presentNum != $availableNum ) {
       last;
    } else {
       $availableNum++;
    }
      }
   }

   # add vNIC using vmdbsh binary and wrapper script.
   if ( $self->{_productType} =~ /esx/i ) {
      my $np      = new VDNetLib::Common::GlobalConfig;
      my $binpath = $np->BinariesPath(VDNetLib::Common::GlobalConfig::OS_ESX);

      # vmdbsh binary is same for 32/64 bit and hence it is hardcoded here
      # for binaries that are different, get the architecture from staf
      # helper module and replace x86_32 with it.
      $binary = "$binpath" . "x86_32/esx/vmdbsh";
      if ( lc($driverType) eq "vmxnet2" ) {
    my $wincmd = STAF::WrapData(
"\"connect -H 127.0.0.1 -U root -P ca\\\$hc0w -v \\\"$self->{_absoluteVMXPath}\\\"; mount /vm; cd /vm/#_VMX/vmx/hotplug;begin;newidx ##;set op deviceAdd;set op/deviceAdd/in/key ethernet$availableNum;cd op/deviceAdd/in/options/;newidx #;set key ethernet$availableNum.virtualDev;set value vmxnet;cd ..;newidx #;set key ethernet$availableNum.networkName;set value $portgroup;cd ..;newidx #;set key ethernet$availableNum.features;set value 15;cd ../../../../../../;end;exit\""
    );
    $command =
         "start shell command $binary -e "
       . $wincmd
       . " wait returnstdout stderrtostdout";
      } else {
    my $wincmd = STAF::WrapData(
"\"connect -H 127.0.0.1 -U root -P ca\\\$hc0w -v \\\"$self->{_absoluteVMXPath}\\\"; mount /vm; cd /vm/#_VMX/vmx/hotplug;begin;newidx ##;set op deviceAdd;set op/deviceAdd/in/key ethernet$availableNum;cd op/deviceAdd/in/options/;newidx #;set key ethernet$availableNum.virtualDev;set value $driverType;cd ..;newidx #;set key ethernet$availableNum.networkName;set value $portgroup;cd ../../../../../../;end;exit\""
    );
    $command =
         "start shell command $binary -e "
       . $wincmd
       . " wait returnstdout stderrtostdout";
      }

      $service = "process";
      ( $ret, $data ) =
    $self->{stafHandle}
    ->runStafCmd( $self->{_justHostIP}, $service, $command );
      sleep(10);
      if ( $ret eq FAILURE ) {
    TestError "error with staf $command ";
    VDSetLastError("ESTAF");
    return FAILURE;
      }
   } elsif ( $self->{_productType} =~ /workstation/i ) {
      TestError("***  Later   ****\n");
   } else {
      TestError("Really!! what product is this\n");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Read the MAC address of the vNIC just added.
   $command =
"start shell command \"grep -i \\\"^[' ']*ethernet$availableNum\\.generatedAddress =\\\" \\\"$self->{_absoluteVMXPath}\\\" \" wait returnstdout stderrtostdout";
   $service = "process";
   ( $ret, $data ) =
      $self->{stafHandle}
      ->runStafCmd( $self->{_justHostIP}, $service, $command );
   if ( $ret eq FAILURE ) {
      TestError "Error with staf $command ";
      VDSetLastError("ESTAF");
      return FAILURE;
   } else {
      if ( $data =~ /^\s*ethernet$availableNum.generatedAddress = (.*?)\n/ ) {
    $macAddress = $1;
    $macAddress =~ s/(\")//g;
    chomp($macAddress);
      } else {
    TestError "error parsing MAC address $data";
    VDSetLastError("EFAIL");
    return FAILURE;
      }
   }
   $self->TestCleanup($testobj);
   return SUCCESS, $macAddress;
}

#-----------------------------------------------------------------------------
#  VMOpsHotRemovevNIC
#
#  Algorithm:
#   Find ethernet unit number by grepping in vmx using MAC address, then use vmdhsh to hot remove vNIC.
#   Again verify by checking for ethernetX.present = False
#
#  Input:
#       MAC address of vNIC you want to hot remove
#
#  Output:
#       1 if pass, 0 if fail
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsHotRemovevNIC
{
   my $self       = shift;
   my $passed     = 0;
   my $testobj    = 0;
   my $driverType = "watever";
   my $portgroup  = "watever";
   my $command;
   my $errorString;
   my $service;
   my $macAddress;
   my $ret;
   my $data;
   my ( $handle, $binary );

   # Validate input parameters
   if ( not defined $self->{stafHandle}->{_handle} ) {
      TestError "STAF Handle in VMOperations object is undefined ";
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ( 1 == @_ ) {
      $macAddress = shift;
      if ( not defined $macAddress ) {
    TestError "Inappropriate MAC address";
    VDSetLastError("EINVALID");
    return FAILURE;
      }
   } else {
      TestError "VM hot add vNIC called without MAC address input Exiting...";
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   ( $passed, $testobj ) =
      $self->TestSetup( TP_HTU_HANDLE_USE_VM, VIX_POWERSTATE_POWERED_ON );
   if ($passed) {

# TODO: Future: my $connectionType = shift; # for workstation - bridged, nat, hostonly
#Registering with STAF
      if ( $self->{stafHandle}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
    TestError "Staf not running on remote machine";
    VDSetLastError("ESTAF");
    return FAILURE;
      }
      my $ethUnitNum = VDNetLib::Common::Utilities::GetEthUnitNum(
		$self->{_justHostIP}, $self->{_absoluteVMXPath},
    		$macAddress );
      if ( not defined $ethUnitNum ) {
    TestError "Error returned from function GetEthUnitNum";
    VDSetLastError(VDGetLastError());
    return FAILURE;
      }
      if ( $self->{_productType} =~ /esx/i ) {
    my $np      = new VDNetLib::Common::GlobalConfig;
    my $binpath = $np->BinariesPath(VDNetLib::Common::GlobalConfig::OS_ESX);

    # vmdbsh binary is same for 32/64 bit and hence it is hardcoded here
    # for binaries that are different, get the architecture from staf
    # helper module and replace x86_32 with it.
    $binary = "$binpath" . "x86_32/esx/vmdbsh";
    my $wincmd = STAF::WrapData(
   "\"connect -H 127.0.0.1 -U root -P ca\\\$hc0w -v \\\"$self->{_absoluteVMXPath}\\\"; mount /vm; cd /vm/#_VMX/vmx/hotplug; begin; newidx ## ;set op deviceRemove; set op/deviceRemove/in/key $ethUnitNum; cd .. ;end; exit\""
    );
    $command =
         "start shell command $binary -e "
       . $wincmd
       . " wait returnstdout stderrtostdout";

    $service = "process";
    ( $ret, $data ) =
       $self->{stafHandle}
       ->runStafCmd( $self->{_justHostIP}, $service, $command );
    if ( $ret eq FAILURE ) {
       TestError "error with staf $command";
       VDSetLastError("ESTAF");
       return FAILURE;
    }
    sleep(10);
      } elsif ( $self->{_productType} =~ /workstation/i ) {
    TestError("***  Later   ****\n");
      } else {
    TestError("Really!! what product is this\n");
    VDSetLastError("EFAIL");
    return FAILURE;
      }
      $command =
"start shell command \"grep -i \\\"^[' ']*$ethUnitNum\\.present = \\\" \\\"$self->{_absoluteVMXPath}\\\" | sort -u \" wait returnstdout stderrtostdout";
      $service = "process";
      ( $ret, $data ) =
    $self->{stafHandle}
    ->runStafCmd( $self->{_justHostIP}, $service, $command );
      if ( $ret eq FAILURE ) {
    TestError "error with staf $command ";
    VDSetLastError("ESTAF");
    return FAILURE;
      } else {
    if ( $data =~ /^\s*ethernet\d+.present = (.*?)\n/ ) {
       my $status = $1;
       $status =~ s/(\")//g;
       chomp($status);
       if ( lc($status) eq "false" ) {
          $passed = 1;
       } else {
          $passed = 0;
          TestError("$ethUnitNum.present is not saying False\n");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    } else {
       $passed = 0;
       TestError("error parsing status of $ethUnitNum\n");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
      }
      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

#-----------------------------------------------------------------------------
#  VMOpsGetPowerState
#  Gets the Power State of the VM
#
#  Input:
#       none
#
#  Output:
#       SUCCESS if passed along with powerstate value
#       FAILURE if failed
#
#  Side effects:
#       none
#
#-----------------------------------------------------------------------------
sub VMOpsGetPowerState
{
   my $self       = shift;
   my $passed     = 0;
   my $testobj    = 0;
   my $powerstate = 0;
   ( $passed, $testobj ) = $self->TestSetup(TP_HTU_HANDLE_USE_VM);
   if ($passed) {
      TestInfo "VMOps Get Power state Started";
      $powerstate = $testobj->{param}->{ACTUAL_POWER_STATE};

      $self->TestCleanup($testobj);
   } else {
      TestError "Handle Creation failed so exiting without Operation";
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS, $powerstate;
}

#-----------------------------------------------------------------------------
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
#-----------------------------------------------------------------------------

sub VMOpsIsVMRunning
{
   my $self = shift;
   my $powerState = $self->VMOpsGetPowerState();
   if ($powerState eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if($powerState & VIX_POWERSTATE_POWERED_ON) {
      return 1;
   } else {
      return 0;
   }
}
1;
