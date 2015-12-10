package perl::foundryqasrc::ManagedGuest;
use strict;
use warnings;
use perl::foundryqasrc::TestOutput;
use perl::foundryqasrc::TestConstants;
use perl::foundryqasrc::ManagedUtil;

use VMware::Vix::API::Constants;
use VMware::Vix::Simple;

use base qw(Exporter perl::foundryqasrc::ManagedBase);
our @EXPORT = qw(WaitForToolsInGuest
                 LoginInGuest);

sub new() {
   my $self = shift;
   my $obj = $self->SUPER::new(shift);
   return $obj;
};

# vmHandle, timeout
sub WaitForToolsInGuest($$$) {
   TestInfo "\nIssuing WaitForToolsInGuest...";
   my $self = shift;
   my $vmHandle = shift;
   my $err = VMWaitForToolsInGuest($vmHandle, shift);
   my $rparam = shift;
   $rparam->{ACTUAL_VM_HANDLE} = $vmHandle;
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);
   perl::foundryqasrc::ManagedVM::RetrievePowerAndToolsState($rparam->{ACTUAL_VM_HANDLE},
                                                             $rparam);

   if ($passed) {
      if (VIX_OK == $rparam->{ACTUAL_TOOL_STATE_ERROR}) {
         if (exists $rparam->{ACTUAL_TOOL_STATE}) {
            if (exists $rparam->{EXPECTED_TOOL_STATE}) {
               if (!($rparam->{ACTUAL_TOOL_STATE} & $rparam->{EXPECTED_TOOL_STATE})) {
                  $passed = 0;
               }
            }
            else {
               if (!($rparam->{ACTUAL_TOOL_STATE} & VIX_TOOLSSTATE_RUNNING)) {
                  $passed = 0;
               }
            }
         }
      }
      else {
         $passed = 0;
      }
   }

   if ($passed) {
      TestInfo "WaitForToolsInGuest passed";
   }
   else {
      TestWarning "WaitForToolsInGuest not passed";
   }

   return $passed;
};

# vmHandle, userName, password, option, rparam
sub LoginInGuest($$$$$) {
   my $self = shift;
   TestInfo "\nIssuing VMLoginInGuest...";
   my $err = VMLoginInGuest(shift, shift, shift, shift);
   my $rparam = shift;
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "LoginInGuest passed";
   }
   else {
      TestWarning "LoginInGuest not passed";
   }

   return $passed;
};

# vmHandle, rparam
sub LogoutFromGuest($$) {
   my $self = shift;
   TestInfo "\nIssuing VMLogoutFromGuest...";
   my $err = VMLogoutFromGuest(shift);
   my $rparam = shift;
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "LogoutFromGuest passed";
   } else {
      TestWarning "LogoutFromGuest not passed";
   }

   return $passed;
};

# vmHandle, $guestProgramName, $commandLineArgs, $options, $propertyListHandle
sub RunProgramInGuest($$$$$$) {
   my ($self, $vmHandle, $guestProgramName, $commandLineArgs, $options, $propertyListHandle, $rparam) = (shift, shift, shift, shift, shift, shift, shift);
   TestInfo "\nIssuing RunProgramInGuest for ".$guestProgramName;
   my $err = VMRunProgramInGuest($vmHandle, $guestProgramName, $commandLineArgs, $options, $propertyListHandle);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "RunProgramInGuest passed";
   }
   else {
      TestWarning "RunProgramInGuest not passed";
   }

   return $passed;
};

# vmHandle, options, propertyListHandle
sub CreateTempFileInGuest($$$$) {
   TestInfo "\nIssuing CreateTempFileInGuest...";
   my $self = shift;
   my $err = VIX_OK;
   my $tempFileName = 0;
   ($err, $tempFileName) = VMCreateTempFileInGuest(shift, shift, shift);
   my $rparam = shift;
   $rparam->{ACTUAL_ERROR} = $err;
   $rparam->{ACTUAL_TEMPFILE_NAME} = $tempFileName;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "CreateTempFileInGuest passed";
   }
   else {
      TestWarning "CreateTempFileInGuest not passed";
   }

   return $passed;
};

# vmHandle, hostPathName, guestPathName, options, propertyListHandle, param
sub CopyFileFromHostToGuest($$$$$$) {
   TestInfo "\nIssuing CopyFileFrmoHostToGuest...";
   my $self = shift;
   my $vmHandle = shift;
   my $hostPathName = shift;
   $hostPathName = RemoveTrailingSlashFromString($hostPathName);
   my $guestPathName = shift;
   $guestPathName = RemoveTrailingSlashFromString($guestPathName);
   my $err = VMCopyFileFromHostToGuest($vmHandle, $hostPathName, $guestPathName, shift, shift);
   my $rparam = shift;
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "CopyFileFromHostToGuest passed";
   }
   else {
      TestWarning "CopyFileFromHostToGuest not passed";
   }

   return $passed;
};

# vmHandle, guestPathName, hostPathName, options, propertyListHandle, param
sub CopyFileFromGuestToHost($$$$$$) {
   TestInfo "\nIssuing CopyFileFromGuestToHost...";
   my $self = shift;
   my $vmHandle = shift;
   my $guestPathName = shift;
   $guestPathName = RemoveTrailingSlashFromString($guestPathName);
   my $hostPathName = shift;
   $hostPathName = RemoveTrailingSlashFromString($hostPathName);
   my $err = VMCopyFileFromGuestToHost($vmHandle, $guestPathName, $hostPathName, shift, shift);
   my $rparam = shift;

   if (!exists $rparam->{HOST_FILEPATH}) {
      $rparam->{HOST_FILEPATH} = $hostPathName;
   }

   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "CopyFileFromGuestToHost passed";
   }
   else {
      TestWarning "CopyFileFromGuestToHost not passed";
   }

   return $passed;
};

# $vmHandle, $guestFilePath, $param
sub DeleteFileInGuest($$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $filePath = shift;
   TestInfo "\nIssuing DeleteFileInGuest on file ".$filePath;
   my $err = VMDeleteFileInGuest($vmHandle, $filePath);
   my $rparam = shift;
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "DeleteFileInGuest passed";
   }
   else {
      TestWarning "DeleteFileInGuest not passed";
   }
   return $passed;
};

# $vmHandle, $pathName, $propertyListHandle, $param
sub CreateDirectoryInGuest($$$$) {
   TestInfo "\nIssuing CreateDirectoryInGuest...";
   my $self = shift;
   my $vmHandle = shift;
   my $pathName = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;

   if ($pathName) {
      RemoveTrailingSlashFromString($pathName);
   }

   my $err = VMCreateDirectoryInGuest($vmHandle, $pathName, $propertyListHandle);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "CreateDirectoryInGuest passed";
   }
   else {
      TestWarning "CreateDirectoryInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $pathName, $options
sub DeleteDirectoryInGuest($$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $pathName = shift;
   my $options = shift;
   my $rparam = shift;
   TestInfo "\nIssuing DeleteDirectoryInGuest...";

   if ($pathName) {
      RemoveTrailingSlashFromString($pathName);
   }

   TestInfo "Guest directory to delete = ".$pathName;
   my $err = VMDeleteDirectoryInGuest($vmHandle, $pathName, $options);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "DeleteDirectoryInGuest passed";
   }
   else {
      TestWarning "DeleteDirectoryInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $oldName, $newName, $options, $propertyListHandle, $param
sub RenameFileInGuest($$$$$$) {
   TestInfo "\nIssuing RenameFileInGuest...";
   my $self = shift;
   my $vmHandle = shift;
   my $oldName = shift;
   my $newName = shift;
   my $options = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;

   if ($oldName) {
      RemoveTrailingSlashFromString($oldName);
   }

   if ($newName) {
      RemoveTrailingSlashFromString($newName);
   }

   my $err = VMRenameFileInGuest($vmHandle, $oldName, $newName, $options, $propertyListHandle);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "RenameFileInGuest passed";
   }
   else {
      TestWarning "RenameFileInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $guestFilePath, $param
sub FileExistsInGuest($$$) {
   my ($self, $vmHandle, $guestFilePath, $rparam) = (shift, shift, shift, shift);
   TestInfo "\nIssuing FileExistsInGuest on ".$guestFilePath;
   my $err = -1;
   my $exists = -1;
   ($err, $exists) = VMFileExistsInGuest($vmHandle, $guestFilePath);
   TestInfo "Exists = ".$exists;
   $rparam->{ACTUAL_ERROR} = $err;
   $rparam->{ACTUAL_FILE_EXISTS_INGUEST} = $exists;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      if (exists $rparam->{EXPECTED_FILE_EXISTS_INGUEST}) {
         $passed = ($rparam->{EXPECTED_FILE_EXISTS_INGUEST} == $rparam->{ACTUAL_FILE_EXISTS_INGUEST});
      }
      else {
         $passed = $rparam->{ACTUAL_FILE_EXISTS_INGUEST};
      }
   }

   if ($passed) {
      TestInfo "FileExistsInGuest passed";
   }
   else {
      TestWarning "FileExistsInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $guestFilePath, $param
sub GetFileInfoInGuest($$$) {
   my ($self, $vmHandle, $guestFilePath, $rparam) = (shift, shift, shift, shift);
   TestInfo "\nIssuing GetFileInfoInGuest on ".$guestFilePath;
   my $err = -1;
   my %info;
   ($err,%info) = VMGetFileInfoInGuest($vmHandle, $guestFilePath);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);
   if ($passed)
   {
      if (exists $rparam->{FILE_SIZE}) {
         if ( $info{FILE_SIZE} == $rparam->{FILE_SIZE} ) {
            TestInfo "File size matches.";
         } else {
            TestError "File size does not match.";
            $passed = 0;
         }
      }
      if (exists $rparam->{FILE_FLAGS}) {
         if ( $info{FILE_FLAGS} == $rparam->{FILE_FLAGS} ) {
            TestInfo "File flag match.";
         } else {
            TestError "File flag does not match.";
            $passed = 0;
         }
      }
      if (exists $rparam->{FILE_MOD_TIME}) {
         if ( $info{FILE_MOD_TIME} == $rparam->{FILE_MOD_TIME} ) {
            TestInfo "File Modification Time matches.";
         } else {
            TestError "File Modification Time does not match.";
            $passed = 0;
         }
      }
   }
   if ($passed) {
      TestInfo "GetFileInfoInGuest passed";
   }
   else {
      TestError "GetFileInfoInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $pathName, $param
sub DirectoryExistsInGuest($$$) {
   my $self = shift;
   TestInfo "\nIssuing DirectoryExistsInGuest...";
   my $vmHandle = shift;
   my $pathName = shift;
   my $rparam = shift;
   my $err = -1;
   my $exists = -1;

   RemoveTrailingSlashFromString($pathName);
   ($err, $exists) = VMDirectoryExistsInGuest($vmHandle, $pathName);
   $rparam->{ACTUAL_ERROR} = $err;
   $rparam->{ACTUAL_DIREXISTS_INGUEST} = $exists;
   my $passed = CheckError($err, $rparam);
   TestInfo "Exists = ".$exists;

   if ($passed) {
      if (exists $rparam->{EXPECTED_DIREXISTS_INGUEST}) {
         $passed = ($rparam->{EXPECTED_DIREXISTS_INGUEST} == $exists);
      }
      else {
         $passed = $exists;
      }
   }

   if ($passed) {
      TestInfo "DirectoryExistsInGuest passed";
   }
   else {
      TestWarning "DirectoryExistsInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $pathName, $options, $param
sub ListDirectoryInGuest($$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $pathName = shift;
   my $options = shift;
   my $rparam = shift;

   if ($pathName) {
      RemoveTrailingSlashFromString($pathName);
   }

   TestInfo "\nIssuing call to ListDirectoryInGuest on ".$pathName;
   my ($err, @directoryContents) = VMListDirectoryInGuest($vmHandle, $pathName, $options);
   $rparam->{ACTUAL_ERROR} = $err;
   $rparam->{ACTUAL_FILES_INGUEST} = \@directoryContents;
   my $passed = CheckError($err, $rparam);

   if (VIX_OK == $rparam->{ACTUAL_ERROR}) {
      $passed = DoesFileInDirMatch($rparam->{DIR_PATH}, $rparam->{ACTUAL_FILES_INGUEST});
   }

   if ($passed) {
      TestInfo "ListDirectoryInGuest passed";
   }
   else {
      TestWarning "ListDirectoryInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $interpreter, $scriptText, $options, $propertyListHandle
sub RunScriptInGuest($$$$$$) {
   my $self = shift;
   TestInfo "\nIssuing RunScriptInGuest...";
   my $vmHandle = shift;
   my $interpreter = shift;
   my $scriptText = shift;
   my $options = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   my $err = VMRunScriptInGuest($vmHandle, $interpreter, $scriptText, $options,
                                 $propertyListHandle);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "RunScriptInGuest passed";
   }
   else {
      TestWarning "RunScriptInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $options, $param
sub ListProcessesInGuest($$$) {
   my $self = shift;
   TestInfo "\nIssuing ListProcessesInGuest...";
   my $vmHandle = shift;
   my $options = shift;
   my $rparam = shift;
   my $err = -1;
   my @processProperties = 0;

   ($err, @processProperties) = VMListProcessesInGuest($vmHandle, $options);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed && VIX_OK == $err) {
      if (!exists $rparam->{EXPECTED_PROCESS_NAME}) {
         TestWarning "EXPECTED_PROCESS_NAME not set, no process to search for.";
         $passed = 0;
      }
      else {
         my $num = @processProperties;
         my $i;

         foreach $i (1..$num) {
            TestInfo $processProperties[$i-1]{'PROCESS_NAME'};
            if ((!IsWin9XGuest($vmHandle) && $processProperties[$i-1]{'PROCESS_NAME'} eq $rparam->{EXPECTED_PROCESS_NAME})
                || (IsWin9XGuest($vmHandle) && ($processProperties[$i-1]{'PROCESS_NAME'} eq uc($rparam->{EXPECTED_PROCESS_NAME})))) {
               TestInfo "ListProcessesInGuest passed";
               return 1;
            }
         }

         TestWarning "Could not find ".$rparam->{EXPECTED_PROCESS_NAME};
         $passed = 0;
      }
   }

   TestWarning "ListProcessesInGuest not passed";
   return $passed;
};

# $vmHandle, $pid, $options, $param
sub KillProcessInGuest($$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $pid = shift;
   my $option = shift;
   my $rparam = shift;
   TestInfo "\nIssuing KillProcessInGuest on ".$pid."...";

   my $err = VMKillProcessInGuest($vmHandle, $pid, $option);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed && VIX_OK == $err) {
      my $procName = GetProcessName($pid, $vmHandle);
      $passed = ($procName eq "NOTFOUND");
   }

   if ($passed) {
      TestInfo "KillProcessInGuest passed";
   }
   else {
      TestWarning "KillProcessInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $url, $windowState, $propertyListHandle, $param
sub OpenUrlInGuest($$$$$) {
   my $self = shift;
   my $vmHandle = shift;
   my $url = shift;
   my $windowState = shift;
   my $propertyListHandle = shift;
   my $rparam = shift;
   TestInfo "\nIssuing OpenUrlInGuest on ".$url;

   my $err = VMOpenUrlInGuest($vmHandle, $url, $windowState, $propertyListHandle);
   $rparam->{ACTUAL_ERROR} = $err;
   my $passed = CheckError($err, $rparam);

   if ($passed) {
      TestInfo "OpenUrlInGuest passed";
   }
   else {
      TestWarning "OpenUrlInGuest not passed";
   }

   return $passed;
};

# $vmHandle, $options, $commandLineArgs
sub InstallTools($$$$) {
   TestInfo "\nIssuing InstallTools...";
   my $self = shift;
   my $vmHandle = shift;
   my $options = shift;
   my $commandArgs = shift;
   my $rparam = shift;
   my $err = VMInstallTools($vmHandle, $options, $commandArgs);
   my $passed = CheckError($err, $rparam);
   if ($passed) {
      TestInfo "InstallTools passed";
   }
   else {
      TestError "InstallTools not passed";
   }
   return $passed, $err;
};

1;