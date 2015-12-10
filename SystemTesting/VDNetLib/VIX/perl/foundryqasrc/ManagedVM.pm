package perl::foundryqasrc::ManagedVM;
use strict;
use warnings;
use perl::foundryqasrc::TestOutput;
use perl::foundryqasrc::TestConstants;
use perl::foundryqasrc::ManagedUtil;

use VMware::Vix::API::Constants;
use VMware::Vix::Simple;

require Exporter;
use base qw(Exporter perl::foundryqasrc::ManagedBase);
use vars qw( @ISA @EXPORT );
our @EXPORT = qw(RetrievePowerAndToolsState
                 RetrievePowerState
                 RetrieveToolsState
                 SetVMState
                 DeleteVM);

use VMware::VixSemiPublic::API::Constants;
use VMware::VixSemiPublic::API::API;
use VMware::VixSemiPublic::API::VM;

# to prevent warning because its a recursive call. 
sub SnapshotIsPresentInTree; 

sub new() {
   my $self = shift;
   my $obj = $self->SUPER::new(shift);
   return $obj;
};

sub IsSnapshotUIDSupported() {
   my $self = shift;
   return ($self->{connectAnchor}->{hostType} == VIX_SERVICEPROVIDER_VMWARE_WORKSTATION);
};

# $hostHandle, $vmxPath, $rparam
sub Open($$$) {
   my $self = shift;
   my $err = VIX_OK;
   my $vmHandle = VIX_INVALID_HANDLE;
   my $hostHandle = shift;
   my $vmxPath = shift;
   TestInfo "Issuing VMOpen on ".$vmxPath." ...";
   ($err, $vmHandle) = VMOpen($hostHandle, $vmxPath);
   my $rparam = shift;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      $rparam->{ACTUAL_VM_HANDLE} = $vmHandle;
      if (exists $rparam->{EXPECTED_VM_HANDLE}) {
         $passed = ($rparam->{EXPECTED_VM_HANDLE} == $vmHandle);
      }
      else {
         $passed = (VIX_INVALID_HANDLE != $vmHandle);
      }
   }

   if ($passed && VIX_OK == $err) {
      RetrievePowerState($vmHandle, $rparam);
      if (VIX_OK != $rparam->{ACTUAL_POWER_STATE_ERROR}) {
         $passed = 0;
      }
   }

   return $passed, $err, $vmHandle;
};

sub Suspend($$$) {
   my $self = shift;
   TestInfo "Issuing VMSuspend...";
   my $vmHandle = shift;
   my $err = VMSuspend($vmHandle, shift);
   my $rparam = shift;
   my $passed = CheckError($err, $rparam);
   if ($passed) {
      if (!exists $rparam->{ACTUAL_VM_HANDLE}) {
         $rparam->{ACTUAL_VM_HANDLE} = $vmHandle;
      }
      RetrievePowerAndToolsState($rparam->{ACTUAL_VM_HANDLE}, $rparam);
      if (VIX_OK == $rparam->{ACTUAL_POWER_STATE_ERROR}) {
         if (exists $rparam->{ACTUAL_POWER_STATE}) {
            if (exists $rparam->{EXPECTED_POWER_STATE}) {
               if (!($rparam->{ACTUAL_POWER_STATE} & $rparam->{EXPECTED_POWER_STATE})) {
                  $passed = 0;
               }
            } else {
               if (!($rparam->{ACTUAL_POWER_STATE} & VIX_POWERSTATE_SUSPENDED)) {
                  $passed = 0;
               }
            }
         }
      }
      else {
         $passed = 0;
      }

      if ($passed) {
         if (VIX_OK == $rparam->{ACTUAL_TOOL_STATE_ERROR}) {
            if (exists $rparam->{ACTUAL_TOOL_STATE}) {
               if (exists $rparam->{EXPECTED_TOOL_STATE}) {
                  if (!($rparam->{ACTUAL_TOOL_STATE} & $rparam->{EXPECTED_TOOL_STATE})) {
                     $passed = 0;
                  }
               } else {
                  if (!($rparam->{ACTUAL_TOOL_STATE} & VIX_TOOLSSTATE_UNKNOWN)) {
                     $passed = 0;
                  }
               }
            }
         }
         else {
            $passed = 0;
         }
      }
   }

   if ($passed) {
      TestInfo "Suspend passed";
   } else {
      TestWarning "Suspend not passed";
   }

   return $passed;
};

sub CaptureScreenImage($$$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $captureType = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   my $err = VIX_E_FAIL;
   my $imageSize = undef;
   my $imageBytes = 0;
   my $passed = 0;

   TestInfo "Issuing VMCaptureScreenImage...";

   ($err, $imageSize, $imageBytes) =
      VMCaptureScreenImage($vmHandle, $captureType,
                           $propertyListHandle);
   $passed = CheckError($err, $rparam);


   if ($passed) {
      TestInfo "CaptureScreenImage passed";
   } else {
      TestWarning "CaptureScreenImage not passed";
   }

   return $passed, $imageSize, $imageBytes;
};

sub CloneVM($$$$$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $snapshotHandle = shift;
   my $cloneType = shift;
   my $destConfigPathName = shift;
   my $options = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   my $err = VIX_E_FAIL;
   my $cloneHandle = undef;
   my $passed = 0;

   TestInfo "Issuing VMClone..";

   ($err, $cloneHandle) =
      VMClone($vmHandle,
              $snapshotHandle,
              $cloneType,
              $destConfigPathName,
              $options,
              $propertyListHandle);

   $passed = CheckError($err, $rparam);


   if ($passed) {
      TestInfo "VMClone passed";
   } else {
      TestWarning "VMClone not passed";
   }

   return $passed, $cloneHandle;
};

sub BeginRecording($$$$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $name = shift;
   my $description = shift;
   my $options = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   my $err = VIX_E_FAIL;
   my $snapshotHandle = undef;
   my $passed = 0;

   TestInfo "Issuing VMBeginRecording..";
   ($err, $snapshotHandle) =
      VMBeginRecording($vmHandle,
                       $name,
                       $description,
                       $options,
                       $propertyListHandle);


   $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "VMBeginRecording passed";
   } else {
      TestWarning "VMBeginRecording not passed";
   }

   return $passed, $snapshotHandle;
};

sub EndRecording($$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $options = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   my $err = VIX_E_FAIL;
   my $passed = 0;

   TestInfo "Issuing VMEndRecording..";

   $err =
      VMEndRecording($vmHandle,
                     $options,
                     $propertyListHandle);

   $passed = CheckError($err, $rparam);


   if ($passed) {
      TestInfo "VMEndRecording passed";
   } else {
      TestWarning "VMEndRecording not passed";
   }

   return $passed;
};

sub BeginReplay($$$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $snapshotHandle = shift;
   my $options = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   my $err = VIX_E_FAIL;
   my $passed = 0;

   TestInfo "Issuing VMBeginReplay..";

   $err =
      VMBeginReplay($vmHandle,
                    $snapshotHandle,
                    $options,
                    $propertyListHandle);

   $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "VMBeginReplay passed";
   } else {
      TestWarning "VMBeginReplay not passed";
   }

   return $passed;
};

sub EndReplay($$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $options = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   my $err = VIX_E_FAIL;
   my $passed = 0;

   TestInfo "Issuing VMEndReplay..";
   $err =
      VMEndReplay($vmHandle,
                  $options,
                  $propertyListHandle);
   $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "VMEndReplay passed";
   } else {
      TestWarning "VMEndReplay not passed";
   }

   return $passed;
};

sub PauseVM($$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $options = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   my $err = VIX_E_FAIL;
   my $passed = 0;

   TestInfo "Issuing VMPause...";

   ($err) =
      VMPause($vmHandle, $options,
              $propertyListHandle);
   $passed = CheckError($err, $rparam);


   if ($passed) {
      TestInfo "Pause VM passed";
      if(VIX_OK == $err) {
         TestInfo "Verifying the state of the VM is paused";
         if(IsVMPaused($vmHandle)) {
            TestInfo "Verified that the VM is paused";
         } else {
            TestError "Could not verify that the VM is paused";
            $passed = $passed && 0;
         }
      }
   } else {
      TestWarning "Pause VM not passed";
   }

   return $passed;
};

sub UnPauseVM($$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $options = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   my $err = VIX_E_FAIL;
   my $passed = 0;

   TestInfo "Issuing VMUnpause...";

   ($err) =
      VMUnpause($vmHandle, $options,
                $propertyListHandle);
   $passed = CheckError($err, $rparam);


   if ($passed) {
      TestInfo "UnPause VM passed";
      if(VIX_OK == $err) {
         TestInfo "Verifying the state of the VM is running after unpause";
         if(IsVMRunning($vmHandle)) {
            TestInfo "Verified that the VM is running after unpause";
         } else {
            TestError "Could not verify that the VM is running after unpause";
            $passed = $passed && 0;
         }
      }
   } else {
      TestWarning "UnPause VM not passed";
   }

   return $passed;
};


sub ConnectNamedDeviceImpl($$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $deviceName = shift;
   my $rparam = shift;
   my $connected =  1;
   my $err = VIX_E_FAIL;
   my $passed = 0;
   my $jobHandle = VIX_INVALID_HANDLE;

   TestInfo "Issuing ConnectNamedDevice...";

   # TODO: Ask the dev team what the other two params are
   $jobHandle =
      VMware::VixSemiPublic::API::VM::ConnectNamedDevice($vmHandle, $deviceName,
                                                         $connected, undef, undef);

   $err = VMware::Vix::API::Job::Wait($jobHandle, VIX_PROPERTY_NONE);
   $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "ConnectNamedDevice passed";
      # TODO: The value of connected returned is 0
      # when the api passes
      # Is this what is expected
      if((VIX_OK == $err)) { # && ($connected)) {
         # TODO: Do we move this code to common code
         TestInfo "Verifying the device is connected";
         $jobHandle =
            VMware::VixSemiPublic::API::VM::IsNamedDeviceConnected($vmHandle,
                                                                   $deviceName,
                                                                   undef,
                                                                   undef);

         $err = VMware::Vix::API::Job::Wait($jobHandle, VIX_PROPERTY_NONE);
         if(VIX_OK == $err) {
            TestInfo "Verified that IsNamedDeviceConnected passes";
         }
      }
   } else {
      TestWarning "ConnectNamedDevice not passed";
   }

   return $passed;
};

sub DisconnectNamedDeviceImpl($$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $deviceName = shift;
   my $rparam = shift;
   my $connected =  0;
   my $err = VIX_E_FAIL;
   my $passed = 0;
   my $jobHandle = VIX_INVALID_HANDLE;

   TestInfo "Issuing ConnectNamedDevice...";

   # TODO: Ask the dev team what the other two params are
   $jobHandle =
      VMware::VixSemiPublic::API::VM::ConnectNamedDevice($vmHandle, $deviceName,
                                                         $connected, undef, undef);

   $err = VMware::Vix::API::Job::Wait($jobHandle, VIX_PROPERTY_NONE);
   $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "ConnectNamedDevice passed";
      # TODO: The value of connected returned is 0
      # when the api passes
      # Is this what is expected
      if((VIX_OK == $err)) { # && ($connected)) {
         # TODO: Do we move this code to common code
         TestInfo "Verifying the device is connected";
         $jobHandle =
            VMware::VixSemiPublic::API::VM::IsNamedDeviceConnected($vmHandle,
                                                                   $deviceName,
                                                                   undef,
                                                                   undef);

         $err = VMware::Vix::API::Job::Wait($jobHandle, VIX_PROPERTY_NONE);
         if(VIX_OK == $err) {
            TestInfo "Verified that IsNamedDeviceConnected passes";
         }
      }
   } else {
      TestWarning "ConnectNamedDevice not passed";
   }

   return $passed;
};


sub IsNamedDeviceConnectedImpl($$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $deviceName = shift;
   my $rparam = shift;
   my $err = VIX_E_FAIL;
   my $passed = 0;
   my $jobHandle = VIX_INVALID_HANDLE;

   TestInfo "Issuing IsNamedDeviceConnected...";

   $jobHandle =
      VMware::VixSemiPublic::API::VM::IsNamedDeviceConnected($vmHandle,
                                                             $deviceName,
                                                             undef,
                                                             undef);

   $err = VMware::Vix::API::Job::Wait($jobHandle, VIX_PROPERTY_NONE);
   $passed = CheckError($err, $rparam);


   if ($passed) {
      TestInfo "IsNamedDeviceConnected passed";
      if(VIX_OK == $err) {
         TestInfo "Verifying the device is connected";
      }
   } else {
      TestWarning "IsNamedDeviceConnected not passed";
   }

   return $passed;
};


# vmHandle, name, desc, option, propertyList, param
sub CreateSnapshot($$$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $name = shift;
   my $desc = shift;
   my $option = shift;
   my $propertyList = shift;
   my $rparam = shift;

   TestInfo "Issuing CreateSnapshot...";

   if (!exists $rparam->{EXPECTED_ERROR} || VIX_OK == $rparam->{EXPECTED_ERROR}) {
      $rparam->{ACTUAL_VM_HANDLE} = $vmHandle;
   }

   my $err = VIX_OK;
   my $snapshotHandle = VIX_INVALID_HANDLE;
   ($err, $snapshotHandle) = VMCreateSnapshot($vmHandle, $name, $desc, $option, $propertyList);
   $rparam->{ACTUAL_ERROR} = $err;

   if (VIX_OK == $err) {
      $rparam->{ACTUAL_SNAPSHOT_HANDLE} = $snapshotHandle;
   }
   else {
      TestWarning "VMCreateSnapshot returns error = ".$err;
   }

   my $passed = CheckError($err, $rparam);

   if ($passed) {
      RetrievePowerState($rparam->{ACTUAL_VM_HANDLE}, $rparam);

      if (exists $rparam->{EXPECTED_POWER_STATE}) {
         $passed = ($rparam->{EXPECTED_POWER_STATE} & $rparam->{ACTUAL_POWER_STATE});
      }
      else {
         TestInfo "EXPECTED_POWER_STATE not set";
         $passed = ($rparam->{ACTUAL_POWER_STATE} & VIX_POWERSTATE_POWERED_ON);

         if (!$passed) {
            TestWarning "VM is not powered-on, but it is expected to be powered-on";
         }
      }
   }
   if ($passed && exists $rparam->{EXPECTED_TOOL_STATE}) {
      RetrieveToolsState($rparam->{ACTUAL_VM_HANDLE}, $rparam);
      $passed = $rparam->{ACTUAL_TOOL_STATE} & $rparam->{EXPECTED_TOOL_STATE};
   }

   if ($passed) {
      if (exists $rparam->{EXPECTED_SNAPSHOT_HANDLE}) {
         $passed = ($rparam->{EXPECTED_SNAPSHOT_HANDLE} == $rparam->{ACTUAL_SNAPSHOT_HANDLE});

         if (!$passed) {
            TestWarning "Snapshot handle not match";
         }
      }
      else {
         TestInfo "EXPECTED_SNAPSHOT_HANDLE not set";

         $passed = VIX_INVALID_HANDLE != $rparam->{ACTUAL_SNAPSHOT_HANDLE};

         if (!$passed) {
            TestWarning "Snapshot handle is VIX_INVALID_HANDLE";
         }
      }
   }

   if ($passed) {
      $self->GetCurrentSnapshot($rparam->{ACTUAL_VM_HANDLE}, $rparam);

      if (exists $rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR}) {
         $passed = $rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR} == $rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR};

         if (!$passed) {
            TestWarning "GetCurrentSnapshot error mismatch, expected = ".$rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR}." actual = ".$rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR};
         }
      }
      else {
         TestInfo("EXPECTED_GETCURRENTSNAPSHOT_ERROR not set");
         $passed = (VIX_OK == $rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR});

         if (!$passed) {
            TestWarning "GetCurrentSnapshot error = ".$rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR};
         }
      }
   }

   # if not set, assume it has to match created snapshot
   if ($passed) {
      if (exists $rparam->{EXPECTED_CURRENTSNAPSHOT_HANDLE}) {
         $passed = $rparam->{ACTUAL_CURRENTSNAPSHOT_HANDLE} == $rparam->{EXPECTED_CURRENTSNAPSHOT_HANDLE};

         if (!$passed) {
            TestWarning "GetCurrentSnapshot mismatch";
         }
      }
      elsif ($rparam->{ACTUAL_CURRENTSNAPSHOT_HANDLE} != $rparam->{ACTUAL_SNAPSHOT_HANDLE}) {
         $passed = 0;
         TestWarning "GetCurrentSnapshot does not match snapshotHandle returned from [VMCreateSnapshot()]";
      }
   }

   # perform this check only for positive test, when a snapshot is created
   if ($passed) {
      if (VIX_OK == $rparam->{ACTUAL_ERROR} && ($self->IsSnapshotUIDSupported())) {
         if (VIX_INVALID_HANDLE != $rparam->{ACTUAL_SNAPSHOT_HANDLE}) {
            $passed = RetrieveSnapshotUID($rparam->{ACTUAL_SNAPSHOT_HANDLE}, $rparam);

            if ($passed) {
               if (exists $rparam->{EXPECTED_SNAPSHOT_UID}) {
                  if ($rparam->{EXPECTED_SNAPSHOT_UID} != $rparam->{ACTUAL_SNAPSHOT_UID}) {
                     TestWarning "Snapshot UID mismatch expected = ".$rparam->{EXPECTED_SNAPSHOT_UID}." actual = ".$rparam->{ACTUAL_SNAPSHOT_UID};
                     $passed = 0;
                  }
               }
               elsif ($rparam->{ACTUAL_SNAPSHOT_UID} == 0) {
                  TestWarning "Snapshot UID is zero";
                  $passed = 0;
               }
            }
         }
         else {
            TestWarning "Snapshot handle is invalid";
         }
      }
   }

   # perform this check only for positive test
   if ($passed) {
      if(VIX_OK == $rparam->{ACTUAL_ERROR} && ($self->IsSnapshotUIDSupported())) {
         TestInfo "VIX_SUCCEEDED, check snapshot is present in VM";
         TestInfo "VM handle = ".$rparam->{ACTUAL_VM_HANDLE};
         $passed = $self->SnapshotIsPresentInVM($rparam->{ACTUAL_VM_HANDLE}, $rparam->{ACTUAL_SNAPSHOT_UID}, $rparam);

         if (!$passed) {
            TestWarning "Snapshot is unexpectedly absent from the VM";
         }
      }
   }

   if ($passed) {
      TestInfo "[VMCreateSnapshot] call succeeded";
   } else {
      TestWarning "[VMCreateSnapshot] call failed";
   }

   return $passed;
};

# $vmHandle, $snapshotHandle, option, $rparam
sub RemoveSnapshot($$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $snapshotHandle = shift;
   my $option = shift;
   my $rparam = shift;
   my $passed = 1;
   my $err = VIX_OK;

   # positive test
   if (!(exists $rparam->{EXPECTED_ERROR}) || (VIX_OK == $rparam->{EXPECTED_ERROR})) {
      $rparam->{ACTUAL_VM_HANDLE} = $vmHandle;
   }

   if (($self->IsSnapshotUIDSupported()) && (VIX_OK == $rparam->{EXPECTED_ERROR}
       || !(exists $rparam->{EXPECTED_ERROR}))) {
      $passed = RetrieveSnapshotUID($snapshotHandle, $rparam);
   }

   if ($passed) {
      TestInfo "Issuing VMRemoveSnapshot";
      $err = VMRemoveSnapshot($vmHandle, $snapshotHandle, $option);
      $rparam->{ACTUAL_ERROR} = $err;
      RetrievePowerAndToolsState($rparam->{ACTUAL_VM_HANDLE}, $rparam);
   }

   if ((exists $rparam->{ACTUAL_SNAPSHOT_UID_ERROR}) && (VIX_OK != $rparam->{ACTUAL_SNAPSHOT_UID_ERROR})) {
      # VMRemoveSnapshot() will not have been called
      TestWarning "Get snapshot UID unsuccessful".$rparam->{ACTUAL_SNAPSHOT_UID_ERROR};
      $passed = 0;
   }

   if ($passed) {
      $passed = CheckError($err, $rparam);
   }

   if ($passed) {
      RetrievePowerState($rparam->{ACTUAL_VM_HANDLE}, $rparam);

      if (exists $rparam->{EXPECTED_POWER_STATE}) {
         $passed = ($rparam->{EXPECTED_POWER_STATE} & $rparam->{ACTUAL_POWER_STATE});
      }
      else {
         TestInfo "EXPECTED_POWER_STATE not set";
         $passed = ($rparam->{ACTUAL_POWER_STATE} & VIX_POWERSTATE_POWERED_ON);

         if (!$passed) {
            TestWarning "VM is not powered-on, but it is expected to be powered-on";
         }
      }
   }

   if ($passed && exists $rparam->{EXPECTED_TOOL_STATE}) {
      RetrieveToolsState($rparam->{ACTUAL_VM_HANDLE}, $rparam);
      $passed = $rparam->{ACTUAL_TOOL_STATE} & $rparam->{EXPECTED_TOOL_STATE};
   }

   # perform this check only for positive test
   if ($passed && VIX_OK == $rparam->{ACTUAL_ERROR}
       && ($self->IsSnapshotUIDSupported())) {
      TestInfo "VIX_SUCCEEDED, check snapshot is present in VM";
      $passed = !($self->SnapshotIsPresentInVM($rparam->{ACTUAL_VM_HANDLE}, $rparam->{ACTUAL_SNAPSHOT_UID}, $rparam));

      if (!$passed) {
         TestWarning "Snapshot is found after VMRemoveSnapshot()";
      }
   }

   if ($passed) {
      TestInfo "[VMRemoveSnapshot] call succeeded";
   } else {
      TestWarning "[VMRemoveSnapshot] call failed";
   }

   return $passed;
};

# $vmHandle, $snapshotHandle, $options, $propertyListHandle, $rparam
sub RevertToSnapshot($$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $snapshotHandle = shift;
   my $option = shift;
   my $propertyList = shift;
   my $rparam = shift;

   # unless specified, CurrentSnapshotHandle should match the snapshotHandle
   #   passed in (most common in positive test)
   if (!exists $rparam->{EXPECTED_CURRENT_SNAPSHOT_HANDLE}) {
      $rparam->{EXPECTED_CURRENTSNAPSHOT_HANDLE} = $snapshotHandle;
   }

   if ( !(exists $rparam->{EXPECTED_ERROR})) {
      $rparam->{ACTUAL_VM_HANDLE} = $vmHandle;
   }

   TestInfo "Issuing VMRevertToSnapshot...";
   my $err = VMRevertToSnapshot($vmHandle, $snapshotHandle, $option, $propertyList);
   $rparam->{ACTUAL_ERROR} = $err;
   RetrievePowerAndToolsState($rparam->{ACTUAL_VM_HANDLE}, $rparam);
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      if (exists $rparam->{EXPECTED_POWER_STATE}) {
         $passed = ($rparam->{EXPECTED_POWER_STATE} & $rparam->{ACTUAL_POWER_STATE});
      }
      else {
         TestInfo "EXPECTED_POWER_STATE not set";
         $passed = ($rparam->{ACTUAL_POWER_STATE} & VIX_POWERSTATE_POWERED_ON);

         if (!$passed) {
            TestWarning "VM is not powered-on, but it is expected to be powered-on";
         }
      }
   }

   if ($passed && exists $rparam->{EXPECTED_TOOL_STATE}) {
      $passed = $rparam->{ACTUAL_TOOL_STATE} & $rparam->{EXPECTED_TOOL_STATE};
   }

   if ($passed) {
      $self->GetCurrentSnapshot($rparam->{ACTUAL_VM_HANDLE}, $rparam);

      if (exists $rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR}) {
         $passed = $rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR} == $rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR};

         if (!$passed) {
            TestWarning "GetCurrentSnapshot error mismatch, expected = ".$rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR}." actual = ".$rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR};
         }
      }
      else {
         TestInfo("EXPECTED_GETCURRENTSNAPSHOT_ERROR not set");
         $passed = (VIX_OK == $rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR});

         if (!$passed) {
            TestWarning "GetCurrentSnapshot error = ".$rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR};
         }
      }
   }

   # if not set, assume it has to match created snapshot
   if ($passed) {
      if (exists $rparam->{EXPECTED_CURRENTSNAPSHOT_HANDLE}) {
         $passed = $rparam->{ACTUAL_CURRENTSNAPSHOT_HANDLE} == $rparam->{EXPECTED_CURRENTSNAPSHOT_HANDLE};

         if (!$passed) {
            TestWarning "GetCurrentSnapshot mismatch";
         }
      }
      elsif ($rparam->{ACTUAL_CURRENTSNAPSHOT_HANDLE} != $rparam->{ACTUAL_SNAPSHOT_HANDLE}) {
         $passed = 0;
         TestWarning "GetCurrentSnapshot does not match snapshotHandle returned from [VMCreateSnapshot()]";
      }
   }

   if ($passed) {
      TestInfo "VMRevertToSnapshot call succeeded";
   }
   else {
      TestWarning "VMRevertToSnapshot call failed";
   }

   return $passed;
}

# vmHandle, snapshotUID, rparam
sub SnapshotIsPresentInVM($$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $snapshotUID = shift;
   my $rparam = shift;
   TestInfo "Checking is snapshot ".$snapshotUID." present in VM...";
   TestInfo "VM handle = ".$vmHandle;

   if (!$self->IsSnapshotUIDSupported()) {
      TestWarning("Snapshot UID not supported");
      return 0;
   }

   if (VIX_INVALID_HANDLE == $vmHandle) {
      TestWarning "vmHandle is VIX_INVALID_HANDLE";
      return 0;
   }

   $self->GetNumRootSnapshots($vmHandle, $rparam);
   my $numRootSnapshot = $rparam->{ACTUAL_NUMROOTSNAPSHOTS};
   if ($numRootSnapshot == 0) {
      TestWarning "zero root snapshot";
      return 0;
   }

   if (VIX_OK != $rparam->{ACTUAL_GETNUMROOTSNAPSHOTS_ERROR}) {
      TestWarning "GetNumRootSnapshot error = ".$rparam->{ACTUAL_GETNUMROOTSNAPSHOTS_ERROR};
      return 0;
   }

   my $rootSnapshotHandle = VIX_INVALID_HANDLE;
   my $present = 0;

   for (my $i=0; $i<$numRootSnapshot; $i=$i+1) {
      $self->GetRootSnapshot($vmHandle, $i, $rparam);

      if (VIX_OK != $rparam->{ACTUAL_GETROOTSNAPSHOT_ERROR}) {
         TestWarning "GetRootSnapshot error = ".$rparam->{ACTUAL_GETNUMROOTSNAPSHOTS_ERROR};
         $present = 0;
         last;
      }

      $rootSnapshotHandle = $rparam->{ACTUAL_ROOTSNAPSHOT_HANDLE};
      if (VIX_INVALID_HANDLE == $rootSnapshotHandle) {
         TestWarning "rootSnapshotHandle is VIX_INVALID_HANDLE";
         $present = 0;
         last;
      }

      if (SnapshotIsPresentInTree($self, $rootSnapshotHandle, $snapshotUID)) {
         $present = 1;
         ReleaseHandle($rootSnapshotHandle);
         last;
      }
   }

   if ($present == 0) {
      TestInfo "Snapshot UID ".$snapshotUID." is not found in VM";
   }

   return $present;
};

# rootSnapshotHandle, snapshotUID
sub SnapshotIsPresentInTree($$$)
{
   my $self = shift;
   my $rootSnapshotHandle = shift;
   my $snapshotUID = shift;
   my $rootSnapshotUID = 0;
   my $err = -1;
   #my $vm = perl::foundryqasrc::ManagedVM->new(0);
   # VIX_PROPERTY_SNAPSHOT_UID = 4202

   ($err, $rootSnapshotUID) = GetProperties($rootSnapshotHandle, 4202);

   if ($snapshotUID == $rootSnapshotUID) {
      TestInfo "ManagedUtil::SnapshotIsPresentInTree snapshot UID = ".$snapshotUID;
      return 1;
   }

   my %param;
   $self->GetNumChildren($rootSnapshotHandle, \%param);
   $err = $param{ACTUAL_GETNUMCHILDREN_ERROR};

   if (VIX_OK != $err) {
      return 0;
   }

   my $numChildSnapshot = $param{ACTUAL_NUMCHILDREN};

   if ($numChildSnapshot <= 0) {
      return 0;
   }

   my $childSnapshotHandle = VIX_INVALID_HANDLE;
   my $present = 0;

   for (my $i = 0; $i<$numChildSnapshot && !$present; $i=$i+1) {
      $self->GetChild($rootSnapshotHandle, $i, \%param);
      $err = $param{ACTUAL_GETCHILD_ERROR};

      if (VIX_OK == $err) {
         $childSnapshotHandle = $param{ACTUAL_CHILD_HANDLE};
         if (VIX_INVALID_HANDLE != $childSnapshotHandle) {
            if (SnapshotIsPresentInTree($self, $childSnapshotHandle, $snapshotUID)) {
               $present = 1;
            }
            ReleaseHandle($childSnapshotHandle);
         }
         else {
            TestWarning "ManagedUtil::SnapshotIsPresentInTree GetChild returns INVALID handle";
            last;
         }
      }
      else {
         TestWarning "ManagedUtil::SnapshotIsPresentInTree GetChild error = ".$err;
         last;
      }
   }

   return $present;
};

# snapshotHandle, rparam
sub GetNumChildren($$) {
   my $self = shift;
   my $snapshotHandle = shift;
   my $rparam= shift;
   my $err = VIX_OK;
   my $numChildren = -1;
   my $passed = 1;

   TestInfo "Issuing SnapshotGetNumChildren...";
   print "\n The snapshot handle received is $snapshotHandle \n";
   ($err, $numChildren) = SnapshotGetNumChildren($snapshotHandle);
   $rparam->{ACTUAL_GETNUMCHILDREN_ERROR} = $err;
   $rparam->{ACTUAL_NUMCHILDREN} = $numChildren;

   if (exists $rparam->{EXPECTED_GETNUMCHILDREN_ERROR}) {
      if ($rparam->{EXPECTED_GETNUMCHILDREN_ERROR} != $rparam->{ACTUAL_GETNUMCHILDREN_ERROR}) {
         $passed = 0;
         TestWarning "GetNumChildren error mismatch expected = ".$rparam->{EXPECTED_GETNUMCHILDREN_ERROR}." actual = ".$rparam->{ACTUAL_GETNUMCHILDREN_ERROR};
      }
      else {
         TestInfo "Expected error = ".$rparam->{EXPECTED_GETNUMCHILDREN_ERROR}." matches actual error = ".$rparam->{ACTUAL_GETNUMCHILDREN_ERROR};
      }
   }
   else {
      TestInfo "EXPECTED_GETNUMCHILDREN_ERROR not set";
      if (VIX_OK != $rparam->{ACTUAL_GETNUMCHILDREN_ERROR}) {
         $passed = 0;
         TestWarning "GetNumChildren error = ".$rparam->{ACTUAL_GETNUMCHILDREN_ERROR};
      }
   }

   if ($passed) {
      TestInfo "GetNumChildren error checking passed, actual error = ".$rparam->{ACTUAL_GETNUMCHILDREN_ERROR};

      if (exists $rparam->{EXPECTED_NUMCHILDREN}) {
         if ($rparam->{ACTUAL_NUMCHILDREN} != $rparam->{EXPECTED_NUMCHILDREN}) {
            $passed = 0;
            TestWarning "GetNumChildren mismatch expected = ".$rparam->{EXPECTED_NUMCHILDREN}." actual = ".$rparam->{ACTUAL_NUMCHILDREN};
         }
      }
      else {
         TestInfo "Actual number of children = ".$rparam->{ACTUAL_NUMCHILDREN};
      }
   }

   if ($passed) {
      TestInfo "SnapshotGetNumChildren call succeeded";
   }
   else {
      TestWarning "SnapshotGetNumChildren call failed";
   }

   return $passed;
};

# $snapshotHandle, rparam
sub GetParent($$) {
   my $self = shift;
   my $snapshotHandle = shift;
   my $rparam = shift;
   my $err = -1;
   my $parentSnapshotHandle = -1;

   TestInfo "Issuing GetParent...";
   ($err, $parentSnapshotHandle) = SnapshotGetParent($snapshotHandle);
   $rparam->{ACTUAL_PARENT_HANDLE} = $parentSnapshotHandle;
   $rparam->{ACTUAL_GETPARENT_ERROR} = $err;

   my $passed = 1;

   if (exists $rparam->{EXPECTED_GETPARENT_ERROR}) {
      if ($rparam->{EXPECTED_GETPARENT_ERROR} != $rparam->{ACTUAL_GETPARENT_ERROR}) {
         $passed = 0;
         TestWarning "GetParent error mismatch expected = ".$rparam->{EXPECTED_GETPARENT_ERROR}." actual = ".$rparam->{ACTUAL_GETPARENT_ERROR};
      }
   }
   else {
      TestInfo "EXPECTED_GETPARENT_ERROR not set";
      if (VIX_OK != $rparam->{ACTUAL_GETPARENT_ERROR}) {
         $passed = 0;
         TestWarning "GetParent error = ".$rparam->{ACTUAL_GETPARENT_ERROR};
      }
   }

   if ($passed) {
      TestInfo "GetParent error checking passed, actual error = ".$rparam->{ACTUAL_GETPARENT_ERROR};

      if (exists $rparam->{EXPECTED_PARENT_HANDLE}) {
         if ($rparam->{ACTUAL_PARENT_HANDLE} != $rparam->{EXPECTED_PARENT_HANDLE}) {
            $passed = 0;
            TestWarning "GetParent mismatch expected = ".$rparam->{EXPECTED_PARENT_HANDLE}." actual = ".$rparam->{ACTUAL_PARENT_HANDLE};
         }
      }
      elsif (VIX_INVALID_HANDLE == $rparam->{ACTUAL_PARENT_HANDLE}) {
         $passed = 0;
         TestWarning "GetParent returns INVALID";
      }
   }

   if ($passed) {
      TestInfo "GetParent handle checking passed, actual handle = ".$rparam->{ACTUAL_PARENT_HANDLE};
   }

   if ($passed && (VIX_INVALID_HANDLE != $rparam->{ACTUAL_PARENT_HANDLE}
       && VIX_OK == $rparam->{ACTUAL_GETPARENT_ERROR})
       && ($self->IsSnapshotUIDSupported())) {
      $passed = RetrieveSnapshotUID($rparam->{ACTUAL_PARENT_HANDLE}, $rparam);

      if ($passed) {
         if (exists $rparam->{EXPECTED_SNAPSHOT_UID}) {
            if ($rparam->{EXPECTED_SNAPSHOT_UID} != $rparam->{ACTUAL_SNAPSHOT_UID}) {
               TestWarning "Snapshot UID mismatch expected = ".$rparam->{EXPECTED_SNAPSHOT_UID}." actual = ".$rparam->{ACTUAL_SNAPSHOT_UID};
               $passed = 0;
            }
         }
         elsif (!$rparam->{ACTUAL_SNAPSHOT_UID}) {
            TestWarning "Snapshot UID is zero";
            $passed = 0;
         }
      }

      if ($passed) {
         TestInfo "GetParent Snapshot UID checking passed actual UID = ".$rparam->{ACTUAL_SNAPSHOT_UID};
      }
   }

   if ($passed) {
      TestInfo "SnapshotGetParent call succeeded";
   } else {
      TestWarning "SnapshotGetParent call failed";
   }

   return $passed;
};

# $parentSnapshotHandle, index, rparam
sub GetChild($$$) {
   my $self = shift;
   my $parentSnapshotHandle = shift;
   my $index = shift;
   my $rparam = shift;
   my $err = -1;
   my $childSnapshotHandle = -1;

   TestInfo "Issuing GetChild..";
   ($err, $childSnapshotHandle) = SnapshotGetChild($parentSnapshotHandle, $index);
   $rparam->{ACTUAL_CHILD_HANDLE} = $childSnapshotHandle;
   $rparam->{ACTUAL_GETCHILD_ERROR} = $err;

   my $passed = 1;

   if (exists $rparam->{EXPECTED_GETCHILD_ERROR}) {
      if ($rparam->{EXPECTED_GETCHILD_ERROR} != $rparam->{ACTUAL_GETCHILD_ERROR}) {
         $passed = 0;
         TestWarning "GetChild error mismatch expected = ".$rparam->{EXPECTED_GETCHILD_ERROR}." actual = ".$rparam->{ACTUAL_GETCHILD_ERROR};
      }
   }
   else {
      TestInfo "EXPECTED_GETCHILD_ERROR not set";
      if (VIX_OK != $rparam->{ACTUAL_GETCHILD_ERROR}) {
         $passed = 0;
         TestWarning "GetChild error = ".$rparam->{ACTUAL_GETCHILD_ERROR};
      }
   }

   if ($passed) {
      TestInfo "GetChild error checking passed, actual error = ".$rparam->{ACTUAL_GETCHILD_ERROR};

      if (exists $rparam->{EXPECTED_CHILD_HANDLE}) {
         if ($rparam->{ACTUAL_CHILD_HANDLE} != $rparam->{EXPECTED_CHILD_HANDLE}) {
            $passed = 0;
            TestWarning "GetChild mismatch expected = ".$rparam->{EXPECTED_CHILD_HANDLE}." actual = ".$rparam->{ACTUAL_CHILD_HANDLE};
         }
      }
      elsif (VIX_INVALID_HANDLE == $rparam->{ACTUAL_CHILD_HANDLE}) {
         $passed = 0;
         TestWarning "GetChild returns INVALID";
      }
   }

   if ($passed) {
      TestInfo "GetChild handle checking passed, actual handle = ".$rparam->{ACTUAL_CHILD_HANDLE};
   }

   if ($passed && (VIX_INVALID_HANDLE != $rparam->{ACTUAL_CHILD_HANDLE}
       && VIX_OK == $rparam->{ACTUAL_GETCHILD_ERROR})
       && ($self->IsSnapshotUIDSupported())) {
      $passed = RetrieveSnapshotUID($rparam->{ACTUAL_CHILD_HANDLE}, $rparam);

      if ($passed) {
         if (exists $rparam->{EXPECTED_SNAPSHOT_UID}) {
            if ($rparam->{EXPECTED_SNAPSHOT_UID} != $rparam->{ACTUAL_SNAPSHOT_UID}) {
               TestWarning "Snapshot UID mismatch expected = ".$rparam->{EXPECTED_SNAPSHOT_UID}." actual = ".$rparam->{ACTUAL_SNAPSHOT_UID};
               $passed = 0;
            }
         }
         elsif (!$rparam->{ACTUAL_SNAPSHOT_UID}) {
            TestWarning "Snapshot UID is zero";
            $passed = 0;
         }
      }

      if ($passed) {
         TestInfo "GetChild Snapshot UID checking passed actual UID = ".$rparam->{ACTUAL_SNAPSHOT_UID};
      }
   }

   if ($passed) {
      TestInfo "SnapshotGetChild call succeeded";
   } else {
      TestWarning "SnapshotGetChild call failed";
   }

   return $passed;
};


sub GetRootSnapshot($$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $index = shift;
   my $rparam = shift;
   my $err = VIX_OK;
   my $snapshotHandle = VIX_INVALID_HANDLE;

   TestInfo "Issue VMGetRootSnapshot...";
   ($err, $snapshotHandle) = VMGetRootSnapshot($vmHandle, $index);
   $rparam->{ACTUAL_ROOTSNAPSHOT_HANDLE} = $snapshotHandle;
   $rparam->{ACTUAL_GETROOTSNAPSHOT_ERROR} = $err;

   my $passed = 1;

   if (exists $rparam->{EXPECTED_GETROOTSNAPSHOT_ERROR}) {
      if ($rparam->{EXPECTED_GETROOTSNAPSHOT_ERROR} != $rparam->{ACTUAL_GETROOTSNAPSHOT_ERROR}) {
         $passed = 0;
         TestWarning "GetRootSnapshot error mismatch expected = ".$rparam->{EXPECTED_GETROOTSNAPSHOT_ERROR}." actual = ".$rparam->{ACTUAL_GETROOTSNAPSHOT_ERROR};
      }
   }
   else {
      TestInfo "EXPECTED_GETROOTSNAPSHOT_ERROR not set";
      if (VIX_OK != $rparam->{ACTUAL_GETROOTSNAPSHOT_ERROR}) {
         $passed = 0;
         TestWarning "GetRootSnapshot error = ".$rparam->{ACTUAL_GETROOTSNAPSHOT_ERROR};
      }
   }

   if ($passed) {
      if (exists $rparam->{EXPECTED_ROOTSNAPSHOT_HANDLE}) {
         if ($rparam->{ACTUAL_ROOTSNAPSHOT_HANDLE} != $rparam->{EXPECTED_ROOTSNAPSHOT_HANDLE}) {
            $passed = 0;
            TestWarning "GetRootSnapshot mismatch expected = ".$rparam->{EXPECTED_ROOTSNAPSHOT_HANDLE}." actual = ".$rparam->{ACTUAL_ROOTSNAPSHOT_HANDLE};
         }
      }
      elsif (VIX_INVALID_HANDLE == $rparam->{ACTUAL_ROOTSNAPSHOT_HANDLE}) {
         $passed = 0;
         TestWarning "GetRootSnapshot returns INVALID";
      }
   }

   if ($passed && VIX_OK == $rparam->{ACTUAL_GETROOTSNAPSHOT_ERROR}
       && ($self->IsSnapshotUIDSupported())) {
      $passed = RetrieveSnapshotUID($rparam->{ACTUAL_ROOTSNAPSHOT_HANDLE}, $rparam);

      if ($passed) {
         if (exists $rparam->{EXPECTED_SNAPSHOT_UID}) {
            if ($rparam->{EXPECTED_SNAPSHOT_UID} != $rparam->{ACTUAL_SNAPSHOT_UID}) {
               TestWarning "Snapshot UID mismatch expected = ".$rparam->{EXPECTED_SNAPSHOT_UID}." actual = ".$rparam->{ACTUAL_SNAPSHOT_UID};
               $passed = 0;
            }
         }
         elsif ($rparam->{ACTUAL_SNAPSHOT_UID} == 0) {
            TestWarning "Snapshot UID is zero";
            $passed = 0;
         }
      }
   }

   if ($passed) {
      TestInfo "VMGetRootSnapshot call succeeded";
   }
   else {
      TestWarning "VMGetRootSnapshot call failed";
   }

   return $passed;
};

# vmHandle, param
sub GetNumRootSnapshots($$) {
   my $self = shift;
   my $vmHandle = shift;
   my $rparam = shift;
   my $numRootSnapshots = 0;
   my $err = VIX_OK;

   TestInfo "Issuing VMGetNumRootSnapshots...";
   ($err, $numRootSnapshots) = VMGetNumRootSnapshots($vmHandle);
   $rparam->{ACTUAL_GETNUMROOTSNAPSHOTS_ERROR} = $err;
   $rparam->{ACTUAL_NUMROOTSNAPSHOTS} = $numRootSnapshots;

   my $passed = 0;
   if (exists $rparam->{EXPECTED_GETNUMROOTSNAPSHOTS_ERROR}) {
      $passed = ($rparam->{EXPECTED_GETNUMROOTSNAPSHOTS_ERROR} == $err);
      if (!$passed) {
         TestWarning "GetNumRootSnapshots error mismatch expected = ".$rparam->{EXPECTED_GETNUMROOTSNAPSHOTS_ERROR}." actual = ".$err;
      }
   }
   else {
      TestInfo "EXPECTED_GETNUMROOTSNAPSHOTS_ERROR not set.";
      $passed = (VIX_OK == $err);
      if (!$passed) {
         TestWarning "GetNumRootSnapshots error = ".$err;
      }
   }

   if ($passed) {
      if (exists $rparam->{EXPECTED_NUMROOTSNAPSHOTS}) {
         if ($rparam->{ACTUAL_NUMROOTSNAPSHOTS} != $rparam->{EXPECTED_NUMROOTSNAPSHOTS}) {
            $passed = 0;
            TestWarning "GetNumRootSnapshots mismatch expected = ".$rparam->{EXPECTED_NUMROOTSNAPSHOTS}." actual = ".$rparam->{ACTUAL_NUMROOTSNAPSHOTS};
         }
      }
      else {
         TestInfo "Actual number of root snapshots = ".$rparam->{ACTUAL_NUMROOTSNAPSHOTS};
      }
   }

   if ($passed) {
      TestInfo "VMGetNumRootSnapshots call succeeded";
   }
   else {
      TestWarning "VMGetNumRootSnapshots call failed";
   }

   return $passed;
};

#class level
sub RetrieveSnapshotUID($$) {
   my $vmHandle = shift;
   my $rparam = shift;
   my $snapshotUID = 0;
   my $err = VIX_OK;

   # VIX_PROPERTY_SNAPSHOT_UID = 4202

   ($err, $snapshotUID) = GetProperties($vmHandle, 4202);
   $rparam->{ACTUAL_SNAPSHOT_UID_ERROR} = $err;
   $rparam->{ACTUAL_SNAPSHOT_UID} = $snapshotUID;

   if (VIX_OK == $err) {
      TestInfo "Retreived Snapshot UID sucessfully, Snapshot UID is ".$snapshotUID;
      return 1;
   }
   else {
      TestWarning "Unable to retrieve Snapshot UID error = ".$err;
      return 0;
   }
};

sub GetCurrentSnapshot($$) {
   my $self = shift;
   my $vmHandle = shift;
   my $rparam = shift;
   TestInfo "Issuing GetCurrentSnapshot...";
   ($rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR}, $rparam->{ACTUAL_CURRENTSNAPSHOT_HANDLE}) = VMGetCurrentSnapshot($vmHandle);
   my $passed = 0;
   TestInfo "Actual error = ".$rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR};

   if (exists $rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR}) {
      TestInfo "Expected error = ".$rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR};
      $passed = ($rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR} == $rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR});

      if (!$passed) {
         TestWarning "Error mistmatch, expected = ".$rparam->{EXPECTED_GETCURRENTSNAPSHOT_ERROR}." actual = ".$rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR};
      }
   }
   else {
      $passed = (VIX_OK == $rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR});

      if (!$passed) {
         TestWarning "No expected error specified, error = ".$rparam->{ACTUAL_GETCURRENTSNAPSHOT_ERROR};
      }
   }

   if ($passed) {
      TestInfo "GetCurrentSnapshot passed";
   }
   else {
      TestWarning "GetCurrentSnapshot not passed";
   }

   return $passed;
};

# $vmHandle, option, propertyListHandle
sub PowerOn($$$$) {
   my $self = shift;
   TestInfo "Issuing VMPowerOn...";
   my $vmHandle = shift;
   my $err = VMPowerOn($vmHandle, shift, VIX_INVALID_HANDLE);
   my $waitForTools = shift;
   my $rparam = shift;
   my $passed =  CheckError($err, $rparam);
   if ($passed) {
      if (!exists $rparam->{ACTUAL_VM_HANDLE}) {
         $rparam->{ACTUAL_VM_HANDLE} = $vmHandle;
      }

      RetrievePowerState($rparam->{ACTUAL_VM_HANDLE}, $rparam);
      if (VIX_OK == $rparam->{ACTUAL_POWER_STATE_ERROR}) {
         if (exists $rparam->{ACTUAL_POWER_STATE}) {
            if (exists $rparam->{EXPECTED_POWER_STATE}) {
               if (!($rparam->{ACTUAL_POWER_STATE} & $rparam->{EXPECTED_POWER_STATE})) {
                  $passed = 0;
               }
            } else {
               if (!($rparam->{ACTUAL_POWER_STATE} & VIX_POWERSTATE_POWERED_ON)) {
                  $passed = 0;
               }
            }
         }
      }
      else {
         $passed = 0;
      }
   }

   if ($passed && $waitForTools) {
      my $guest = perl::foundryqasrc::ManagedGuest->new($self->{connectAnchor});
      ClearParam($rparam);
      $passed = $guest->WaitForToolsInGuest($vmHandle, TIMEOUT_WAIT_FOR_TOOLS_IN_SEC, $rparam);
      if ($passed) {
         TestInfo "Tools are running";
      }
      else {
         TestWarning "Tools are not running";
      }
   }

   if ($passed) {
      TestInfo "PowerOn passed";
   }
   else {
      TestWarning "PowerOn not passed";
   }

   return $passed;
};

sub PowerOff($$$) {
   my $self = shift;
   TestInfo "Issuing VMPowerOff...";
   my $err = VMPowerOff(shift, shift);
   my $rparam = shift;
   return CheckError($err, $rparam);
};

# class level
sub RetrievePowerAndToolsState($$) {
   my $vmHandle = shift;
   my $rparam = shift;
   RetrievePowerState($vmHandle, $rparam);
   RetrieveToolsState($vmHandle, $rparam);
}

# class level
# $vmHandle, $rparam
sub RetrievePowerState($$) {
   my $vmHandle = shift;
   my $rparam = shift;
   my $err = VIX_OK;
   my $powerState = -1;
   ($err, $powerState) = GetProperties($vmHandle, VIX_PROPERTY_VM_POWER_STATE);

   if (VIX_OK == $err) {
      TestInfo "Retreived power state sucessfully, power state is ".$powerState;
   }
   else {
      TestWarning "Unable to retrieve the actual power state error = ".$err;
   }

   $rparam->{ACTUAL_POWER_STATE} = $powerState;
   $rparam->{ACTUAL_POWER_STATE_ERROR} = $err;

   return ($err, $powerState);
}

# class level
# $vmHandle, $rparam
sub RetrieveToolsState($$) {
   TestInfo "Retrieving Tools State...";
   my $vmHandle = shift;
   my $rparam = shift;
   my $err = VIX_OK;
   my $toolState = -1;
   TestInfo "VM Handle = ".$vmHandle;
   ($err, $toolState) = GetProperties($vmHandle, VIX_PROPERTY_VM_TOOLS_STATE);

   if (VIX_OK == $err) {
      TestInfo "Retreived tool state sucessfully, tool state is ".$toolState;
   }
   else {
      TestWarning "Unable to retrieve the actual tool state error = ".$err;
   }

   $rparam->{ACTUAL_TOOL_STATE} = $toolState;
   $rparam->{ACTUAL_TOOL_STATE_ERROR} = $err;

   return ($err, $toolState);
}

sub SetVMState($$$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $expectedState = shift;
   my $waitForTools = shift;
   my $rparam2 = shift;
   my $powerOption = shift;
   if(not defined $powerOption) {
      $powerOption = POWEROPTION;
   }

   if (!(($expectedState & VIX_POWERSTATE_POWERED_OFF)
       || ($expectedState & VIX_POWERSTATE_POWERED_ON)
       || ($expectedState & VIX_POWERSTATE_SUSPENDED))) {
      TestWarning "Trying to set VM power state to invalid state";
      return 0;
   }
   else {
      TestInfo "Setting the VM power state to ".$expectedState;
   }

   my $err = VIX_OK;
   my $actualState = -1;
   ($err, $actualState) = RetrievePowerState($vmHandle, $rparam2);
   if (VIX_OK != $err) {
      return 0;
   }

   my $stateSet = 0;
   if ($actualState & $expectedState) {
      TestInfo "Expected state and actual state matched";

      if (($expectedState & VIX_POWERSTATE_POWERED_ON) && $waitForTools) {
         my $guest = perl::foundryqasrc::ManagedGuest->new($self->{connectAnchor});
         ClearParam($rparam2);
         $stateSet = $guest->WaitForToolsInGuest($vmHandle, TIMEOUT_WAIT_FOR_TOOLS_IN_SEC, $rparam2);
      }
      else {
         $stateSet = 1;
      }
   }
   else {
      my $poweredOn = 1;
      if (!($actualState & VIX_POWERSTATE_POWERED_ON)) {
         TestInfo "Actual state is not VIX_POWERSTATE_POWERED_ON we are issuing PowerOn";
         ClearParam($rparam2);
         $poweredOn = $self->PowerOn($vmHandle, $powerOption, $waitForTools, $rparam2);
      }

      if ($poweredOn) {
         if ($expectedState & VIX_POWERSTATE_POWERED_ON) {
            $stateSet = 1;
         }
         elsif ($expectedState & VIX_POWERSTATE_POWERED_OFF) {
            TestInfo "Expected state is VIX_POWERSTATE_POWERED_OFF trying to power-off the VM";
            ClearParam($rparam2);
            $stateSet = $self->PowerOff($vmHandle, $powerOption, $rparam2);
         }
         elsif ($expectedState & VIX_POWERSTATE_SUSPENDED) {
            TestInfo "Expected state is VIX_POWERSTATE_SUSPENDED trying to suspend the VM";
            ClearParam($rparam2);
            $stateSet = $self->Suspend($vmHandle, $powerOption, $rparam2);
         }
      }
   }

   if ($stateSet) {
      TestInfo "SetVMState set the state sucessfully to ".$expectedState;
   }
   else {
      TestInfo "SetVMState was unable to set the state to ".$expectedState;
   }

   return $stateSet;
};

# $vmHandle, $options, $params
sub DeleteVM($$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $options = shift;
   my $rparam = shift;
   TestInfo "Issuing call to DeleteVM...";

   if (!exists $rparam->{ACTUAL_VM_HANDLE}) {
      $rparam->{ACTUAL_VM_HANDLE} = $vmHandle;
   }

   my $err = VMDelete($vmHandle, $options);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      # to do: remove this condition after Foundry bug is fixed
      if (VIX_OK != $err) {
         RetrievePowerState($rparam->{ACTUAL_VM_HANDLE}, $rparam);

         if (VIX_OK == $err) {
            if (VIX_OK == $rparam->{ACTUAL_POWER_STATE_ERROR}) {
               TestWarning "After deleting VM, incorrectly successful in retrieving VM power state.";
               $passed = 0;
            }
         }
         else {
            if (VIX_OK != $rparam->{ACTUAL_POWER_STATE_ERROR}) {
               TestWarning "After deleting VM in negative test, unsuccessful in retrieving VM power state.";
               $passed = 0;
            }
         }
      }
   }


   if ($passed) {
      TestInfo "VMDelete() succeeded";
   }
   else {
      TestWarning "VMDelete() failed";
   }

   return $passed;
};

# $vmHandle, $options, $rparam
sub Reset($$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $options = shift;
   my $rparam = shift;
   TestInfo "Issuing call to VMReset...";
   my $err = VMReset($vmHandle, $options);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "VMReset() succeeded";
   }
   else {
      TestWarning "VMReset() failed";
   }

   return $passed;
};

# $vmHandle, $options, $rparam
sub UpgradeVirtualHardware($$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $options = shift;
   my $rparam = shift;
   my $serviceProvider = $rparam->{SERVICE_PROVIDER};
   my $vmxPath = $rparam->{ABSOLUTE_VMX_PATH};
   TestInfo "Issuing call to UpgradeVirtualHardware...";
   my $err = VMUpgradeVirtualHardware($vmHandle, $options);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);
   if ($err == VIX_OK) {
      $passed = CheckConfigVersion($rparam->{ACTUAL_VM_HANDLE},$serviceProvider,$vmxPath,$rparam);
      if ($passed) {
      $passed = CheckHardwareVersion($rparam->{ACTUAL_VM_HANDLE}, $rparam);
      }
   }
   if ($passed) {
      TestInfo "VMUpgradeVirtualHardware() succeeded";
   }
   else {
      TestError "VMUpgradeVirtualHardware() failed";
   }

   return $passed;
};

# $vmHandle, $variableType, $valueName, $value, $options, $rparam
sub WriteVariable($$$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $variableType = shift;
   my $variableName = shift;
   my $value = shift;
   my $options = shift;
   my $rparam = shift;
   TestInfo "Issuing call to VMWriteVariable variableType = ".$variableType." variableName = ".$variableName." value = ".$value;
   my $err = VMWriteVariable($vmHandle, $variableType, $variableName, $value, $options);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "VMWriteVariable() succeeded";
   }
   else {
      TestWarning "VMWriteVariable() failed";
   }

   return $passed;
};

# $vmHandle, $variableType, $name, $options, $rparam
sub ReadVariable($$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $variableType = shift;
   my $variableName = shift;
   my $options = shift;
   my $rparam = shift;
   TestInfo "Issuing VMReadVariable variableType = ".$variableType." variableName = ".$variableName;
   my ($err, $value) = VMReadVariable($vmHandle, $variableType, $variableName, $options);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed && (VIX_OK == $err)) {
      $rparam->{ACTUAL_VAR_VALUE} = $value;
      if (exists $rparam->{EXPECTED_VAR_VALUE}) {
         if ($value != $rparam->{EXPECTED_VAR_VALUE}) {
            TestWarning "Variable value mismatch, expected = ".$rparam->{EXPECTED_VAR_VALUE}." actual = ".$rparam->{ACTUAL_VAR_VALUE};
            $passed = 0;
         }
      }
      else {
         TestInfo "Expected variable value is not set";
      }

   }

   if ($passed) {
      TestInfo "VMReadVariable() succeeded";
   }
   else {
      TestWarning "VMReadVariable() failed";
   }

   return $passed;
};

# $vmHandle, $name, $rparam
sub GetNamedSnapshot($$) {
   my ($self, $vmHandle, $name, $rparam) = (shift, shift, shift, shift);
   TestInfo "Issuing VMGetNamedSnapshot name = ".$name;
   my ($err, $snapshotHandle) = VMGetNamedSnapshot($vmHandle, $name);
   $rparam->{ACTUAL_NAMEDSNAPSHOT_HANDLE} = $snapshotHandle;
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      if (exists $rparam->{EXPECTED_NAMEDSNAPSHOT_HANDLE}) {
         $passed = ($rparam->{EXPECTED_NAMEDSNAPSHOT_HANDLE} == $snapshotHandle);

         if (!$passed) {
            TestWarning "snapshot handle mismatch expected = ".$rparam->{EXPECTED_NAMEDSNAPSHOT_HANDLE}." actual = ".$snapshotHandle;
         }
      }
      else {
         $passed = ($snapshotHandle != VIX_INVALID_HANDLE);

         if (!$passed) {
            TestWarning "No expected snapshot handle, actual snapshot handle is invalid";
         }
      }
   }

   if ($passed && VIX_OK == $err && ($self->IsSnapshotUIDSupported())) {
      $passed = RetrieveSnapshotUID($snapshotHandle, $rparam);

      if ($passed) {
         if (exists $rparam->{EXPECTED_SNAPSHOT_UID}) {
            if ($rparam->{EXPECTED_SNAPSHOT_UID} != $rparam->{ACTUAL_SNAPSHOT_UID}) {
               TestWarning "Snapshot UID mismatch expected = ".$rparam->{EXPECTED_SNAPSHOT_UID}." actual = ".$rparam->{ACTUAL_SNAPSHOT_UID};
               $passed = 0;
            }
         }
         elsif (!$rparam->{ACTUAL_SNAPSHOT_UID}) {
            TestWarning("Snapshot UID is zero");
            $passed = 0;
         }
      }
   }

   if ($passed) {
      TestInfo "VMGetNamedSnapshot passed";
   }
   else {
      TestWarning "VMGetNamedSnapshot failed";
   }

   return $passed;
};

1;
