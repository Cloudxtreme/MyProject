package perl::foundryqasrc::ManagedSharedFolder;
use strict;
use warnings;
use perl::foundryqasrc::TestOutput;
use perl::foundryqasrc::TestConstants;
use perl::foundryqasrc::ManagedUtil;

use VMware::Vix::API::Constants;
use VMware::Vix::Simple;

use base qw(Exporter perl::foundryqasrc::ManagedBase);
our @EXPORT = qw();

sub new() {
   my $self = shift;
   my $obj = $self->SUPER::new(shift);
   return $obj;
};

# $vmHandle, $shareName, $hostPathName, $flags, $rparam
sub AddSharedFolder($$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $shareName = shift;
   my $hostPathName = shift;
   my $flags = shift;
   my $rparam = shift;
   TestInfo "\nIssuing call to VMAddSharedFolder shareName = ".$shareName." hostPathName = ".$hostPathName." flags = ".$flags;
   my $err = VMAddSharedFolder($vmHandle, $shareName, $hostPathName, $flags);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "AddSharedFolder passed";
   }
   else {
      TestWarning "AddSharedFolder not passed";
   }

   return $passed;
};

# $vmHandle, $shareName, $flags, $rparam
sub RemoveSharedFolder($$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $shareName = shift;
   my $flags = shift;
   my $rparam = shift;
   TestInfo("\nCalling VMRemoveSharedFolder()");
   my $err = VMRemoveSharedFolder($vmHandle, $shareName, $flags);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "RemoveSharedFolder passed";
   }
   else {
      TestWarning "RemoveSharedFolder not passed";
   }

   return $passed;
};

# $vmHandle, $rparam
sub GetNumSharedFolders($$) {
   my $self = shift;
   my $vmHandle = shift;
   my $rparam = shift;
   TestInfo "\nCalling VMGetNumSharedFolders";
   my $err = -1;
   my $num = -1;
   ($err, $num) = VMGetNumSharedFolders($vmHandle);
   $rparam->{ACTUAL_ERROR} = $err;
   $rparam->{ACTUAL_NUMSHAREDFOLDERS} = $num;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      if (exists $rparam->{EXPECTED_NUMSHAREDFOLDERS}) {
         $passed = ($rparam->{ACTUAL_NUMSHAREDFOLDERS} == $rparam->{EXPECTED_NUMSHAREDFOLDERS});

         if (!$passed) {
            TestWarning "Actual number of shared folders = ".$rparam->{ACTUAL_NUMSHAREDFOLDERS}." does not match expected = ".$rparam->{EXPECTED_NUMSHAREDFOLDERS};
         }
      }
   }

   if ($passed) {
      TestInfo "GetNumSharedFolders passed";
   }
   else {
      TestWarning "GetNumSharedFolders not passed";
   }

   return $passed;
};

# vmHandle, rUserParam
sub RemoveAllSharedFolders($$) {
   TestInfo "\nRemove all shared folders.";
   my $self = shift;
   my $vmHandle = shift;
   my $rUserParam = shift;
   my %param;
   my $numFolders = 0;
   my $allRemoved = 1;
   my $expectedPowerState = VIX_POWERSTATE_POWERED_ON;
   my $actualPowerState = -1;
   my $vm = perl::foundryqasrc::ManagedVM->new(0);
   perl::foundryqasrc::ManagedVM::RetrievePowerState($vmHandle, \%param);

   if (exists $param{ACTUAL_POWER_STATE}) {
      $actualPowerState = $param{ACTUAL_POWER_STATE};
      TestInfo "Actual Power State = ".$actualPowerState;
   }
   else{
      TestError "Couldnt retrieve actual power state.";
      return 0;
   }

   if (undef != $rUserParam) {
      if (exists $rUserParam->{EXPECTED_POWER_STATE}) {
         $expectedPowerState = $rUserParam->{EXPECTED_POWER_STATE};
         TestInfo "Expected Power State = ".$expectedPowerState;
      }
      else {
         TestError "Expected Power State is not set.";
         return 0;
      }
   }

   if (!($expectedPowerState & $actualPowerState)) {
      TestWarning "Expected power state ".$expectedPowerState." does not match actual power state ".$actualPowerState;
      return 0;
   }

   ClearParam \%param;

   if ($self->GetNumSharedFolders($vmHandle, \%param)) {
      $numFolders = $param{ACTUAL_NUMSHAREDFOLDERS};

      if (!$numFolders){
         TestInfo("Found zero shared folders. Nothing to remove");
      }
      else{
         TestInfo "No. of shared folders reported: ".$numFolders;
         my $i = 0;
         my $err = -1;
         my $flags = -1;
         my $shareName = 0;
         my $host = 0;

         for (; $i < $numFolders; $i++) {
            TestInfo "Trying iteration no.: ".$i;
            ($err, $flags, $shareName, $host) = VMGetSharedFolderState($vmHandle, 0);
            ClearParam \%param;

            if (CheckError($err, \%param)) {
	            TestInfo "Share name found: ".$shareName;
               $err = VMRemoveSharedFolder($vmHandle, $shareName, 0);

               if (VIX_OK != $err) {
                  TestWarning "Could not remove share called: ".$shareName." error = ".$err." Breaking out of removal loop.";
                  $allRemoved = 0;
                  last;
               }
               else {
                  TestInfo "Removed a share ".$shareName;
               }
            }
            else {
               TestWarning "Unable to retrieve the share name";
               $allRemoved = 0;
               last;
            }
         } # for
      }
   }
   else {
      TestError "RemoveAllSharedFolders failed";
      $allRemoved = 0;
   }

   return $allRemoved;
};

# $vmHandle, $shareName, $hostPathName, $flags, $rparam
sub SetSharedFolderState($$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $shareName = shift;
   my $hostPathName = shift;
   my $flags = shift;
   my $rparam = shift;
   my $err = -1;
   TestInfo "\nIssuing call to SetSharedFodlerState";
   $err = VMSetSharedFolderState($vmHandle, $shareName, $hostPathName, $flags);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "SetSharedFolderState passed";
   }
   else {
      TestWarning "SetSharedFolderState not passed";
   }

   return $passed;
};

# $vmHandle, $index, $rparam
sub GetSharedFolderState($$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $index = shift;
   my $rparam = shift;
   my $err = -1;
   my $flags = -1;
   my $shareName = 0;
   my $host = 0;
   TestInfo "\nIssuing call to GetSharedFolderState";
   ($err, $flags, $shareName, $host) = VMGetSharedFolderState($vmHandle, $index);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);
   $rparam->{FLAGS} = $flags;
   $rparam->{HOST_PATH_NAME} = $host;
   $rparam->{FOLDER_NAME} = $shareName;

   if ($passed) {
      TestInfo "GetSharedFolderState passed";
   }
   else {
      TestWarning "GetSharedFolderState not passed";
   }

   return $passed;
};

# $vmHandle, $enable, $options, $rparam
sub EnableSharedFolders($$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $enable = shift;
   my $options = shift;
   my $rparam = shift;
   TestInfo "\nIssuing call to EnableSharedFolder";
   my $err = VMEnableSharedFolders($vmHandle, $enable, $options);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "EnableSharedFolders passed";
   }
   else {
      TestWarning "EnableSharedFolders not passed";
   }

   return $passed;
};

1;