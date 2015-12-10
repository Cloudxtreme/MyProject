package perl::foundryqasrc::ManagedUtil;
use strict;
use warnings;
no warnings 'recursion';

use perl::foundryqasrc::TestOutput;
use perl::foundryqasrc::TestConstants;
use VMware::Vix::Simple;
use VMware::Vix::API::Constants;
use File::Copy;
use File::Basename;
use File::Path;
use perl::foundryqasrc::fqaclient;

require Exporter;
our @ISA = qw(Exporter);
use vars qw( @ISA @EXPORT );
our @EXPORT = qw(ClearParam
                 CheckError
                 InitializeTestSetup
                 IsWindowsGuest
                 IsWin9XGuest
                 IsWindowsHost
                 GetFoundryFilePropertyFlag
                 DoesFileExistOnHost
                 RemoveTrailingSlashFromString
                 GetProcessID
                 GetProcessName
                 CreateFileOnGuest
                 DeleteDirOnGuest
                 DeleteAllSnapshots
                 DeleteFileOrDirFromHost
                 CreateDirectoryOnGuest
                 CreateFileOnHost
                 CreateDirectoryOnHost
                 DirCopy
                 GetFileNameWithExtension
                 DoesFileInDirMatch
                 RetrieveHardwareVersion
                 CheckHardwareVersion
                 RetrieveConfigVersion
                 CheckConfigVersion
                 IsVMRegistered
                 IsVMPaused
                 IsVMRunning
                 IsVMReplaying
                 GetAbsolutePath);

sub DirCopy; 

# class level
sub ClearParam($) {
   my $rparam = shift;
   my $key = 0;
   foreach $key (keys(%$rparam)) {
      delete $rparam->{$key};
   }
};

# class level
sub CheckError($$) {
   my $err = shift;
   my $rparam = shift;
   my $passed = 0;
#   TestInfo "Expected error = ".$rparam->{EXPECTED_ERROR};
   TestInfo "Actual error = ".$err;
   if (exists $rparam->{EXPECTED_ERROR}) {
      if($rparam->{EXPECTED_ERROR} == $err) {
         $passed = 1;
      }
      if (!$passed) {
         TestWarning "Error mistmatch, expected = ".$rparam->{EXPECTED_ERROR}." actual = ".$err;
      }
   }
   else {
      if(VIX_OK == $err) {
         $passed = 1;
      }
      if (!$passed) {
         TestWarning "No expected error specified, error = ".$err;
      }
   }

   if ($passed) {
      TestInfo "CheckError passed";
   }

   return $passed;
};


sub IsWindowsGuest($) {
# VIX_PROPERTY_GUEST_OS_VERSION                   = 4503
   my $err = VIX_OK;
   my $guestFamilyName = 0;
   my $vmHandle = shift;
   ($err, $guestFamilyName) = GetProperties($vmHandle, 4503);

   if (VIX_OK == $err) {
      TestInfo "Guest family is ".$guestFamilyName;
      if (index(lc($guestFamilyName), "win") >= 0) {
         TestInfo "Guest family is Windows";
         return 1;
      }
      else {
         TestInfo "Guest family is non-Windows";
         return 0;
      }
   }
   else {
      TestError "Error upon getting Guest family error = ".$err." ".GetErrorText($err);
      return 0;
   }
};

sub IsWin9XGuest($) {
# VIX_PROPERTY_GUEST_OS_VERSION                   = 4503
   my $err = VIX_OK;
   my $guestFamilyName = 0;
   my $vmHandle = shift;
   ($err, $guestFamilyName) = GetProperties($vmHandle, 4503);

   if (VIX_OK == $err) {
      TestInfo "Guest family is ".$guestFamilyName;
      if (index(lc($guestFamilyName), "windows 9") >= 0) {
         TestInfo "Guest family is Windows 9X";
         return 1;
      }
      else {
         TestInfo "Guest family is NOT Windows 9X";
         return 0;
      }
   }
   else {
      TestError "Error upon getting Guest family error = ".$err." ".GetErrorText($err);
      return 0;
   }
};

sub IsWindowsHost() {
   #$OSNAME
   TestInfo "Host OS is ".$^O;
   if (index($^O, "MSWin") > -1) {
      return 1;
   }
   else {
      return 0;
   }
};

sub GetFoundryFilePropertyFlag($) {
   my $fileName = shift;
   if (!$fileName) {
      return -1;
   }
   elsif (undef != readlink($fileName)) {
      return VIX_FILE_ATTRIBUTES_SYMLINK;
   }
   elsif (-d $fileName) {
      return VIX_FILE_ATTRIBUTES_DIRECTORY;
   }

   return 0;
};

# filePath
sub DoesFileExistOnHost($) {
   my $filePath = shift;
   TestInfo "DoesFileExistOnHost called for file: ".$filePath;

   if (-e $filePath) {
      TestInfo("File exists");
      return 1;
   }
   else {
      TestWarning("File does not exist");
      return 0;
   }
};

# string
sub RemoveTrailingSlashFromString($) {
   if (!$_[0]) {
      return;
   }

   if ((rindex($_[0], "\\") == length($_[0])) || (rindex($_[0], "/") == length($_[0]))) {
      TestInfo "String before removing trailing slash: ".$_[0];
      $_[0] = substr($_[0], 0, length($_[0])-2);
      TestInfo "String after removing trailing slash: ".$_[0];
   }

   return $_[0];
};

# target process name, vmHandle
sub GetProcessID($$) {
   my $targetProcessName = shift;
   my $vmHandle = shift;
   TestInfo "Looking for process: ".$targetProcessName;
   my ($err, @processProperties) = VMListProcessesInGuest($vmHandle, 0);

   if (VIX_OK != $err) {
      TestWarning "VMListProcessesInGuest returns error = ".$err." exiting GetProcessID";
      return -1;
   }

   my $num = @processProperties;
   my $i = 0;
   my $targetPID = 0;
   my $processName = 0;
   my $processID = 0;

   for (; $i < $num; $i = $i + 1) {
      $processName = $processProperties[$i]{PROCESS_NAME};
      $processID = $processProperties[$i]{PROCESS_ID};
      TestInfo "Process: ".$processName." id: ".$processID;

      if ((!IsWin9XGuest($vmHandle) && ($processName eq $targetProcessName))
           || (IsWin9XGuest($vmHandle) && ($processName eq uc($targetProcessName)))) {
         $targetPID = $processID;
         TestInfo "Found ".$processName." ID = ".$processID;
         last;
      }
   }

   return $targetPID;
};

# target process id, vmHandle
sub GetProcessName($$) {
   my $targetProcessID = shift;
   my $vmHandle = shift;
   my $targetProcessName = "NOTFOUND";
   my $err = -l;
   my @processProperties;
   TestInfo "GetProcessName on PID ".$targetProcessID;

   ($err, @processProperties) = VMListProcessesInGuest($vmHandle, 0);

   if (VIX_OK != $err) {
      TestWarning "VMListProcessesInGuest returns error = ".$err." exiting GetProcessName";
      return -1;
   }

   my $num = @processProperties;
   my $i;

   foreach $i (1..$num) {
      TestInfo "Process: ".$processProperties[$i-1]{'PROCESS_NAME'}." id: ".$processProperties[$i-1]{'PROCESS_ID'};

      if ($processProperties[$i-1]{'PROCESS_ID'} == $targetProcessID) {
         TestInfo "Found ".$processProperties[$i-1]{'PROCESS_NAME'};
         $targetProcessName = $processProperties[$i-1]{'PROCESS_NAME'};
         last;
      }
   }

   return $targetProcessName;
};

# vmHandle, filePath, fileName
sub CreateFileOnGuest($$$) {
   my $vmHandle = shift;
   my $filePath = shift;
   my $fileName = shift;
   my $err = -1;
   my $exists = 0;
   my $newFileNameWithPath = $filePath.$fileName;
   my $passed = 0;
   TestInfo "\nCreateFileOnGuestViaRename called for file: ".$newFileNameWithPath;

   ($err, $exists) = VMFileExistsInGuest($vmHandle, $newFileNameWithPath);

   if (VIX_OK == $err) {
      if ($exists) {
         TestInfo "File already exists on Guest.";
         $passed = 1;
      }
      else {
         TestInfo "File does not exist on Guest so creating it";
         $passed = CreateDirectoryOnGuest($vmHandle, $filePath);

         if ($passed) {
            my $tempFileName = 0;
            ($err, $tempFileName) = VMCreateTempFileInGuest($vmHandle, 0, VIX_INVALID_HANDLE);

            if (VIX_OK == $err) {
               TestInfo "Temp file created in Guest";
               TestInfo "Temp file name is ".$tempFileName;
               TestInfo "Renaming temp file now";

               $err = VMRenameFileInGuest($vmHandle, $tempFileName, $newFileNameWithPath, 0, VIX_INVALID_HANDLE);

               if (VIX_OK == $err) {
                  TestInfo "Temp file renamed successfully";
                  TestInfo $newFileNameWithPath." created successfully";
                  TestInfo "Verifying new file existence";

                  ($err, $exists) = VMFileExistsInGuest($vmHandle, $newFileNameWithPath);

                  if (VIX_OK == $err) {
                     if ($exists) {
                        TestInfo "New file exists on Guest";
                     }
                     else {
                        TestWarning "New file does not exist on Guest";
                     }
                  }
                  else {
                     TestWarning "VMFileExistsInGuest on ".$newFileNameWithPath." returns error = ".$err;
                  }
               }
               else {
                  TestWarning "VMRenameFileInGuest from ".$tempFileName." to ".$newFileNameWithPath." returns error = ".$err;
               }
            }
            else {
               TestWarning "VMCreateTempFileInGuest returns error = ".$err;
            }
         }
         else {
            TestWarning "Create directory on guest failed";
         }
      }
   }
   else {
      TestWarning "VMFileExistsInGuest on ".$filePath." returns error = ".$err;
   }

   return $passed;
};

# $vmHandle, $dirPath
sub DeleteDirOnGuest($$) {
   my $vmHandle = shift;
   my $dirPath = shift;
   TestInfo "\nDeleteDirInGuest called for dir ".$dirPath;
   my $guest = perl::foundryqasrc::ManagedGuest->new(0);
   my %param;
   my $passed = $guest->DirectoryExistsInGuest($vmHandle, $dirPath, \%param);

   if ($passed) {
      my $err = VMDeleteDirectoryInGuest($vmHandle, $dirPath, 0);
      $passed = ($err == VIX_OK);

      if ($passed) {
         $passed = !($guest->DirectoryExistsInGuest($vmHandle, $dirPath));
      }
   }
   else {
      TestInfo "Dir does not exist on Guest.";
   }

   return $passed;
};

# fileOrDirPath
sub DeleteFileOrDirFromHost($) {
   my $fileOrDirPath = shift;
   TestInfo "\nDeleteFileOrDirFromHost called for dir/file: ".$fileOrDirPath;

   if (!$fileOrDirPath) {
      TestError "Trying to DeleteFileOrDirFromHost for empty fileOrDirpath";
      return 0;
   }

   RemoveTrailingSlashFromString($fileOrDirPath);
   my $retVal = 0;

   if (-d $fileOrDirPath) {
      $retVal = rmtree($fileOrDirPath, 1);
      TestInfo "Return value from rm -r = ".$retVal;

      if ($retVal) {
         TestInfo "Delete directory successful";
         return 1;
      }
      else {
         TestWarning "Delete Directory failed";
         return 0;
      }
   }
   else {
      $retVal = (unlink $fileOrDirPath);
      TestInfo "Return value from unlink = ".$retVal;

      if ($retVal) {
         TestInfo "Delete file successful";
         return 1;
      }
      else {
         TestWarning "Delete file failed";
         return 0;
      }
   }
};

# $vmHandle, $dirPath
sub CreateDirectoryOnGuest($$) {
   my $vmHandle = shift;
   my $dirPath = shift;
   TestInfo "\nCreating Dir ".$dirPath;
   my $guest = perl::foundryqasrc::ManagedGuest->new(0);
   my %param;

   if (!$guest->DirectoryExistsInGuest($vmHandle, $dirPath, \%param)) {
      TestInfo "directory does not exists, so creating it";
      my $passed = $guest->CreateDirectoryInGuest($vmHandle, $dirPath, VIX_INVALID_HANDLE, \%param);

      if ($passed) {
         $passed = ($guest->DirectoryExistsInGuest($vmHandle, $dirPath, \%param));
      }

      return $passed;
   }
   else {
      return 1;
   }
};

# filePath, fileName
sub CreateFileOnHost($$) {
   my $filePath = shift;
   my $fileName = shift;
   TestInfo "\nCreateFileOnHost called for filepath: ".$filePath." and fileName: ".$fileName;
   my $passed = CreateDirectoryOnHost($filePath);

   if ($passed) {
      my $fileNameWithPath = $filePath.$fileName;
      my $fh;
      $passed = ((open($fh, "> $fileNameWithPath")) != 0);
   }

   return $passed;
};

# dirPath
sub CreateDirectoryOnHost($) {
   my $dirPath = shift;
   TestInfo "\nCreateDirectoryOnHost called for path: ".$dirPath;
   RemoveTrailingSlashFromString($dirPath);
   my $passed = 0;

   if (-e $dirPath) {
      if (-d $dirPath) {
         TestInfo "Directory already exists";
         $passed = 1;
      }
      else {
         TestWarning "a non-directory object already exists";
      }
   }
   else {
      $passed = mkpath($dirPath, 1);
      if (!$passed) {
         TestWarning "Directory creation failed";
      }
   }

   return $passed;
};

# srcPath, dstPath, isVMX; assume parameter does not contain trailing slash
sub DirCopy($$$) {
   my $srcPath = shift;
   my $dstPath = shift;
   my $isVMX = shift;
   TestInfo "ManagedUtil::DirCopy src = ".$srcPath." dst = ".$dstPath;
   my $passed = CreateDirectoryOnHost($dstPath);

   if (!$passed) {
      TestWarning "Creation of destination directory failed, stop copying.";
   }
   else {
      my $srcDirH;
      $passed = opendir($srcDirH, $srcPath);

      if ($passed) {
         my @srcDirContents = grep {$_ ne '.' and $_ ne '..'} readdir($srcDirH);
         my $srcDirContent = 0;
         #my $srcDirContentFileName = 0;

         if (IsWindowsHost()) {
            $srcPath = $srcPath."\\";
            $dstPath = $dstPath."\\";
         }
         else {
            $srcPath = $srcPath."/";
            $dstPath = $dstPath."/";
         }

         #TestInfo "content of src directory:";
         foreach $srcDirContent (@srcDirContents) {
            #TestInfo $srcDirContent." ".(-d $srcDirContent);
            #next;

            #$srcDirContentFileName = fileparse($srcDirContent); # parse the last item from the full path
            if (-d $srcDirContent) {
               TestInfo "Copying directory";
               # check recursion
               $passed = DirCopy($srcPath.$srcDirContent, $dstPath.$srcDirContent, $isVMX);
               if (!$passed) {
                  last;
               }
            }
            else {
               if ($isVMX) {
                  # copy only vmx and vmdk files
                  if (substr($srcDirContent, length($srcDirContent) - 4) eq ".vmx"
                     || substr($srcDirContent, length($srcDirContent) - 5) eq ".vmdk") {
                     $passed = $passed = copy($srcPath.$srcDirContent, $dstPath.$srcDirContent);

                     if (!$passed) {
                        TestWarning "ManagedUtil::DirCopy file copy failed while copying only vmx and vmdk files";
                     }
                     else {
                        TestInfo "File copied successfully";
                     }
                  }
               }
               else {
                  # copy all files
                  TestInfo "Copying file from ".$srcPath.$srcDirContent." to ".$dstPath.$srcDirContent;
                  $passed = copy($srcPath.$srcDirContent, $dstPath.$srcDirContent);

                  if (!$passed) {
                     TestWarning "ManagedUtil::DirCopy file copy failed while copying all files";
                  }
                  else {
                     TestInfo "File copied successfully";
                  }
               }
            }
         } # for
      }
   }

   return $passed;
};

# GetAbsolutePath gets the absoulte path of the VM .$VMPATH
sub GetAbsolutePath($) {
   my $vmxPath = shift;
   my $path ;
   my $index1 ;
   my $index2;
   my $newstr ;
   my $physicalpath ;
   if ($ENV{'FOUNDRYQA_DS'})
   {
      $path = $ENV{'FOUNDRYQA_DS'};
      $index1 = index($path,"=");
      $index2 = index($path,";");
      $path = substr($path,$index1+1,$index2-$index1-1);
  } else {
      if (IsWindowsHost()) {
         $path = WIN_DEFAULT_PATH; #set to the default path
      }
      else {
         $path = LNX_DEFAULT_PATH; #set to the default path
      }
   }
   print "$path\n";
   $index1 = index($vmxPath," ");
   $index2 = index($vmxPath,"/");
   $physicalpath = $path.substr($vmxPath,$index1+1,$index2-$index1-1);
   return $physicalpath
}

# srcPath, extension, rparam
sub GetFileNameWithExtension($$$) {
   my $srcPath = shift;
   my $extension = shift;
   my $rparam = shift;
   TestInfo "ManagedUtil::GetFileNameWithExtension src = ".$srcPath." extension = ".$extension;
   my $srcDirH;
   my $passed = 0;

   if (opendir($srcDirH, $srcPath)) {
      my @srcDirContents = readdir($srcDirH);
      my $srcDirContent = 0;
      my $srcDirContentFileName = 0;

      foreach $srcDirContent (@srcDirContents) {
         if (-f $srcDirContent) {
            if (substr($srcDirContent, length($srcDirContent) - 5) eq ".vmdk") {
               $srcDirContentFileName = fileparse($srcDirContent);
               $rparam->{FileName} = $srcDirContentFileName;
               $passed = 1;
               last;
            }
         }
      }
   }

   return $passed;
};

# hostDir, hash{name}=flag
sub DoesFileInDirMatch($$) {
   TestInfo "DoesFileInDirMatch";
   my $hostDir = shift;
   my $rFilesInGuest = shift;
   TestInfo "List of files on host ".$hostDir.":";
   my $hostDirH;

   unless (opendir($hostDirH, $hostDir)) {
      TestWarning "Unable to open host directory ".$hostDir;
      return 0;
   }

   my @hostDirContents = grep {$_ ne '.' and $_ ne '..'} readdir($hostDirH);
   my $hostDirFile = 0;

   if (IsWindowsHost()) {
      $hostDir = $hostDir."\\";
   }
   else {
      $hostDir = $hostDir."/";
   }

   foreach $hostDirFile (@hostDirContents) {
      TestInfo "Name: ".$hostDir.$hostDirFile."; Attributes: ".GetFoundryFilePropertyFlag($hostDir.$hostDirFile);
   }

   TestInfo "============================";
   TestInfo "List of files in guest:";
   my $i = 0;
   my %nameFlags = 0;
   #my @fileNamesInGuest = keys(%$rFilesInGuest);
   #my $fileNameInGuest = 0;

   #foreach $fileNameInGuest (@fileNamesInGuest) {
   #   TestInfo $fileNameInGuest;
   #}

   foreach $i (1..@$rFilesInGuest) {
      TestInfo $i."Name: ".$rFilesInGuest->[$i-1]{'FILE_NAME'}."; Attributes: ".$rFilesInGuest->[$i-1]{'FILE_ATTRIBUTES'};
      $nameFlags{$rFilesInGuest->[$i-1]{'FILE_NAME'}} = $rFilesInGuest->[$i-1]{'FILE_ATTRIBUTES'};
   }

   if (@hostDirContents != @$rFilesInGuest) {
      TestWarning "ManagedUtil::DoesFileInDirMatch number of files mismatch";
      return 0;
   }

   foreach $hostDirFile (@hostDirContents) {
      TestInfo "Comparing file: ".$hostDirFile;

      if (exists $nameFlags{$hostDirFile}) {
         if ($nameFlags{$hostDirFile} != GetFoundryFilePropertyFlag($hostDir.$hostDirFile)) {
            TestWarning "ManagedUtil::DoesFileInDirMatch file property flag mismatch";
            return 0;
         }
      }
      else {
         TestWarning "ManagedUtil::DoesFileInDirMatch file name mismatch host file not found";
         return 0;
      }
   }

   return 1;
};

# $vmHandle, $serviceProvider, $vmxPath $rparam
sub CheckConfigVersion($$$$) {
   my $vmHandle = shift;
   my $serviceProvider = shift;
   my $vmxPath = shift;
   my $rparam = shift;
   my $passed = RetrieveConfigVersion($vmHandle,$serviceProvider,$vmxPath, $rparam);

   if ($passed) {
      if (exists $rparam->{EXPECTED_CONFIG_VERSION}) {
         if ($rparam->{ACTUAL_CONFIG_VERSION} != $rparam->{EXPECTED_CONFIG_VERSION}) {
            TestWarning "Config version mismatch, expected = ".$rparam->{EXPECTED_CONFIG_VERSION}." actual = ".$rparam->{ACTUAL_CONFIG_VERSION};
            $passed = 0;
         }
      }
      else {
         TestInfo "Expected config version not specified, expected to be ".WS6X_CONFIG_VERSION;

         if ($rparam->{ACTUAL_CONFIG_VERSION} != WS6X_CONFIG_VERSION) {
            TestWarning "Actual config version = ".$rparam->{ACTUAL_CONFIG_VERSION};
            $passed = 0;
         }
      }
   }

   return $passed;
}

# $vmHandle, $serviceProvider, $vmxPath $rparam
sub RetrieveConfigVersion($$$$) {
   my $vmHandle = shift;
   my $serviceProvider = shift;
   my $vmxPath = shift;
   my $rparam = shift;
   my $configVersion = -1;
   my $err = -1;
   my $index1 = 0;
   my $index2 = 0;
   #VIX_PROPERTY_VM_CONFIG_VERSION                  = 111,
   if ( $serviceProvider == 3)
   {
      ($err, $configVersion) = GetProperties($vmHandle, 111);
      $rparam->{ACTUAL_CONFIG_VERSION_ERROR} = $err;
   } else {
      my $searchString = "config.version";
      my $stringFound ;
      open FILE, $vmxPath;
      my @line = <FILE>;
      for (@line) {
         if ($_ =~ /$searchString/) {
            my $stringFound = $_;
            $index1 = index($stringFound,"\"");
            $index2 = index($stringFound,"\"",$index1+1);
            $configVersion = substr($stringFound,$index1+1,$index2-$index1-1);
            $err = VIX_OK;
         }
      }
   }
   if (VIX_OK == $err) {
      $rparam->{ACTUAL_CONFIG_VERSION} = $configVersion;
      TestInfo "Retreived config version sucessfully, config version = ".$configVersion;
      return 1;
   }
   else {
      TestWarning "Unable to retrieve config version";
      return 0;
   }
};

# $vmHandle, $rparam
sub CheckHardwareVersion($$) {
   my $vmHandle = shift;
   my $rparam = shift;
   my $passed = RetrieveHardwareVersion($vmHandle, $rparam);
   if ($passed) {
      if (exists $rparam->{EXPECTED_HW_VERSION}) {
         if ($rparam->{ACTUAL_HW_VERSION} != $rparam->{EXPECTED_HW_VERSION}) {
            TestWarning "Hardware version mismatch, expected = ".$rparam->{EXPECTED_HW_VERSION}." actual = ".$rparam->{ACTUAL_HW_VERSION};
            $passed = 0;
         }
      }
      else {
         TestInfo "Expected hardware version not specified, expected to be ".WS65_HW_VERSION;
         if ($rparam->{ACTUAL_HW_VERSION} != WS65_HW_VERSION) {
            TestWarning "Actual hardware version = ".$rparam->{ACTUAL_HW_VERSION};
            $passed = 0;
         }
      }
   }

   return $passed;
}

# $vmHandle, $rparam
sub RetrieveHardwareVersion($$) {
   my $vmHandle = shift;
   my $rparam = shift;
#VIX_PROPERTY_VM_HARDWARE_VERSION                = 112,
   my ($err, $hwVersion) = GetProperties($vmHandle, 112);
   $rparam->{ACTUAL_HW_VERSION_ERROR} = $err;

   if (VIX_OK == $err) {
      $rparam->{ACTUAL_HW_VERSION} = $hwVersion;
      TestInfo "Retreived hardware version sucessfully, hardware version = ".$hwVersion;
      return 1;
   }
   else {
      TestWarning "Unable to retrieve hardware version";
      return 0;
   }
};

sub IsVMPaused($) {
   my $vmHandle = shift;
   my $err = undef;
   my $powerState = undef;
   ($err, $powerState) = GetProperties($vmHandle, VIX_PROPERTY_VM_POWER_STATE);

   if (VIX_OK == $err) {
      TestInfo "Power State is  ".$powerState;
      if($powerState & VIX_POWERSTATE_PAUSED) {
         TestInfo "The VM is paused";
         return 1;
      } else {
         TestWarning "The VM is not paused as expected";
      }
   } else {
      TestWarning "Error upon getting Power State error = ".$err." ".GetErrorText($err);
   }
   return 0;
};

sub IsVMRunning($) {
   my $vmHandle = shift;
   my $err = undef;
   my $powerState = undef;
   ($err, $powerState) = GetProperties($vmHandle, VIX_PROPERTY_VM_POWER_STATE);

   if (VIX_OK == $err) {
      TestInfo "Power State is  ".$powerState;
      if($powerState & VIX_POWERSTATE_POWERED_ON) {
         TestInfo "The VM is running";
         return 1;
      } else {
         TestWarning "The VM is not running as expected";
      }
   } else {
      TestWarning "Error upon getting Power State error = ".$err." ".GetErrorText($err);
   }
   return 0;
};

sub IsVMRegistered($$) {
   my $hostHandle = shift;
   my $vmxPath = shift;
   my @vmList = ();
   my $registeredVMFound = undef;
   my $timeOutInSecs = -1;
   my $foundTheVMRegistered = 0;
   my $searchType = VIX_FIND_REGISTERED_VMS;

   @vmList  = FindItems($hostHandle, $searchType, $timeOutInSecs);

   for(my $vmCount = 0; ($vmCount < scalar @vmList) && (!$foundTheVMRegistered);
       $vmCount++) {
      $registeredVMFound = $vmList[$vmCount];
      if($vmxPath eq $registeredVMFound) {
         $foundTheVMRegistered = 1;
         TestInfo "Found the VM $vmxPath registered";
      }
   }
   return $foundTheVMRegistered;
};

sub IsVMReplaying($) {
   my $vmHandle = shift;
   my $err = undef;
   my $isVMReplaying = undef;
   ($err, $isVMReplaying) = GetProperties($vmHandle, VIX_PROPERTY_VM_IS_REPLAYING);

   if (VIX_OK == $err) {
      if($isVMReplaying) {
         TestInfo "The VM is replaying";
         return 1;
      } else {
         TestWarning "The VM is not replaying as expected";
      }
   } else {
      TestWarning "Error upon gettting if VM is replaying = ".$err." ".GetErrorText($err);
   }
   return 0;
};

sub DeleteAllSnapshots($)
{
   my $vmHandle = shift;
   my %param = undef;
   my $passed = 1;
   my $err = undef;
   my $rootSnapshotHandle = VIX_INVALID_HANDLE;
   my $numSnapshotsRemoved = 0;


   if(VIX_INVALID_HANDLE != $vmHandle) {
      while ($passed) {
         ClearParam \%param;
         $passed =
            perl::foundryqasrc::ManagedVM::GetNumRootSnapshots($vmHandle, \%param);

         if ($passed && $param{ACTUAL_NUMROOTSNAPSHOTS} > 0) {
            ClearParam \%param;
            $passed =
               perl::foundryqasrc::ManagedVM::GetRootSnapshot($vmHandle,
                                                              0,
                                                              \%param);
            if ($passed) {
               $rootSnapshotHandle = $param{ACTUAL_ROOTSNAPSHOT_HANDLE};
               ClearParam \%param;
               $passed =
                  perl::foundryqasrc::ManagedVM::RemoveSnapshot($vmHandle,
                                                                $rootSnapshotHandle,
                                                                DEFAULT_REMOVE_SNAPSHOT_OPTION,
                                                                \%param);
               if ($passed) {
                  $numSnapshotsRemoved = $numSnapshotsRemoved + 1;
               }
            }
         }
         else {
            last;
         }
      }
   }
   TestInfo "Removed $numSnapshotsRemoved snapshot(s)";
   return $passed, $numSnapshotsRemoved;
}

1;