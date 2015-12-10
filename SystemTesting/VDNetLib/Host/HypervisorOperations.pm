package VDNetLib::Host::HypervisorOperations;

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::SshHost;
use constant TRUE    => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE   => VDNetLib::Common::GlobalConfig::FALSE;
use constant VMFS_BASE_PATH => "/vmfs/volumes/";
use constant VDNET_SHARED_MOUNTPOINT => "vdnetSharedStorage";
use constant CORE_DUMP => "coredump";
use constant VSAN_LOCAL_MOUNTPOINT => "vsanDatastore";

use base 'VDNetLib::Root::Root';
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              Boolean
                                              ConfigureLogger);
use constant CORE_DUMP_DIRS => ['/var/core/', '/var/cores/', '/var/log/core/'];


########################################################################
#
# ConfigureHostForVDNet--
#     Method to configure host for vdnet
#
# Input:
#     vdnetSource: vdnet source code to mount (<server>:/<share>)
#     vmRepository: vdnet vm repository to mount (<server>:/<share>)
#     sharedStorage: shared storage to mount (<server>:/<share>)
#
# Results:
#     SUCCESS, if the host is configured successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureHostForVDNet
{
   my $self          = shift;
   my $vdnetSource   = shift || $self->{vdnetSource};
   my $vmRepository  = shift || $self->{vmRepository};
   my $sharedStorage = shift || $self->{sharedStorage};
   #
   # Check if host is already prepared/setup, if not proceed.
   #
   if (!$self->CheckIfHostSetupRequired($$)) {
      $vdLogger->Info("STAF is installed on $self->{hostIP}");
   } else {
      my $result = $self->SSHPreProcess();
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $pwd = $self->{password};
      $pwd =~ s/\\//g; # ssh doesn't like escape \
      $self->{sshPassword} = $pwd;
      if (VDNetLib::Common::Utilities::CreateSSHSession($self->{hostIP},
          "root", $self->{sshPassword}) eq FAILURE) {
         $vdLogger->Error("Failed to establish a SSH session with " .
                          $self->{hostIP});
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $sshHost = $sshSession->{$self->{hostIP}};
      $vdLogger->Info("Disabling firewall on $self->{hostIP}");
      if (FAILURE eq $self->ConfigureFirewall($sshHost, "disable")) {
         $vdLogger->Error("Failed to configure firewall on $self->{hostIP}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      #
      # Copy the ESX setup script to the host and run the script
      # using SSH
      #
      my $setupScript = $self->GetHostSetupScript();
      $vdLogger->Info("Running host setup script $setupScript on $self->{hostIP}");
      my $srcScript = "$FindBin::Bin/../scripts/" . $setupScript;
      my $dstScript = "/tmp/" . $setupScript;
      my ($rc, $out) = $sshHost->ScpToCommand($srcScript, $dstScript);
      if ($rc ne "0") {
         $vdLogger->Error("Failed to copy " . $setupScript . " file " .
                          " to $self->{hostIP}");
         $vdLogger->Debug("ERROR:$rc " . Dumper($out));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # Find the local ip to be used for RPC and to update /etc/hosts
      # on the host
      my $ipList = VDNetLib::Common::Utilities::GetAllLocalIPAddresses();

      my @remoteIPOctets = split('\.', $self->{hostIP});
      my $launcherIP;
      foreach my $entry (@$ipList) {
         my @launcherIPOctets = split('\.', $entry);
         if ($remoteIPOctets[0] eq $launcherIPOctets[0]) {
            $launcherIP = $entry;
            last;
         }
      }
      my $command = "python $dstScript " .
         "--vdnet $vdnetSource " .
         "--vmrepository $vmRepository " .
         "--sharedstorage $sharedStorage " .
         "--launcher $launcherIP";
      my $toolchainMirror = $ENV{VDNET_TOOLCHAIN_MIRROR};
      if (defined $toolchainMirror) {
         $command = $command . " --toolchain $toolchainMirror";
      }
      my $stafMirror = $ENV{VDNET_STAF_MIRROR};
      if (defined $stafMirror) {
         $command = $command . " --staf $stafMirror";
      }
      $vdLogger->Trace("Running setup command on $self->{hostIP}: $command");
      ($rc, $out) = $sshHost->SshCommand($command, 600);
      $vdLogger->Trace("output of vdnet_linux_setup on host $self->{hostIP} " . Dumper($out));
      # TODO: decide location to dump the output
      my $stdout = join("", @$out);
      if ($rc ne "0") {
         $vdLogger->Error("Failed to setup host $self->{hostIP} for vdnet");
         $vdLogger->Debug("ERROR: $rc " . Dumper($stdout));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      if ($self->{stafHelper}->WaitForSTAF($self->{hostIP}) eq FAILURE) {
         $vdLogger->Error("Wait for STAF on $self->{hostIP} failed");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      # Determine the host OS
      $self->{os}  =  $self->GetOS();
      if (not defined $self->{os}) {
         VDSetLastError("EOSNOTSUP");
         return FAILURE;
      }
      # Determine the host Arch
      $self->{arch}  =  $self->GetArchitecture();
      if (not defined $self->{arch}) {
         $vdLogger->Error("Unknown arch, not supported");
         VDSetLastError("EOSNOTSUP");
         return FAILURE;
      }

      if (FAILURE eq $self->InstallTestCerts($sshHost, "disable")) {
         $vdLogger->Error("Failed to install test-certs on $self->{hostIP}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


#########################################################################
#
# SSHPreProcess
#      Stuff to do as a pre-req to start ssh on the host
#
# Input:
#      None
#
# Results:
#      Returns SUCCESS
#      Returns FAILURE
#
# Side effects:
#      None.
#
#########################################################################

sub SSHPreProcess
{
   return SUCCESS;
}

########################################################################
#
#  CheckIfHostSetupRequired --
#      This method will check host setup required or not
#
# Input:
#      seedOfFileName : a tring that contained in file name
#
# Results:
#      Return  TRUE if required, FALSE if not
#
# Side effects:
#      None
#
########################################################################

sub CheckIfHostSetupRequired
{
  my $self = shift;
  my $seedOfFileName = shift;
  my $cmd;
  my $result;

  # if file does not exist, return TRUE
  $cmd = "ls /tmp/vdnet-" . $seedOfFileName;
  $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
  if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Debug("STAF command $cmd failed on host " . $self->{hostIP} .
                      Dumper($result));
     return TRUE;
  }
  if (($result->{stdout} eq "") || ($result->{stdout} =~ /No such/i)) {
     return TRUE;
  }
  $vdLogger->Debug("$cmd returns success on host " . $self->{hostIP});
  return FALSE;
}

###############################################################################
#
# CreateVM -
#       This method configures the given VM to be used by vdNet. If required
#	this method powers on the VM and also initiates the tool upgrade.
#
# Input:
#       vmHash  - VM testbed spec hash
#       vmIndex - VM Component Index ( e.g : for vm.[1] component index is 1
#                                            for dhcpserver.[2] component index is 2)
#
# Results:
#       vmObj (VMOperations Class Object), in case of SUCCESS.
#       FAILURE, Otherwise.
#
# Side effects:
#       None
#
###############################################################################

sub CreateVM
{
   my $self		= shift;
   my $vmHash		= shift;
   $vmHash		= $$vmHash;
   my $vmIndex		= shift;
   my $component	= shift;
   my $result;
   my $ret;
   my $changeName   = 0;
   my $initialState = "on";

   my $hostIP	  = $self->{hostIP};

   my $vmIP       = $vmHash->{ip};
   my $vmxName    = $vmHash->{vmx};
   my $vmName	  = $vmHash->{vmName};
   my $vmTemplate = $vmHash->{template};
   my $ovfUrl     = $vmHash->{ovfurl};
   my $lockFileName;
   my $uniqueID;
   my $vmObj;

   if (defined $vmIP) {
      #
      # If IP address of the VM is given, then just find the vmx file
      # for the given VM.
      #
      # The previous test might have initialized to some value, which need to
      # be carried forever
      #

      $vmxName = $self->GetVMX($vmIP);
      if ($vmxName eq FAILURE) {
	 $vdLogger->Error("Failed to get vmx path for $vmIP");
	 VDSetLastError(VDGetLastError());
	 return FAILURE;
      }
   } elsif (defined $vmxName) {
      if (VDNetLib::Common::Utilities::IsPath($vmxName) eq FAILURE) {
	 $vdLogger->Error("Given vmx name is invalid: $vmxName");
	 VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } elsif (defined $vmName) {
      $vmxName = $self->ReturnVMXPathIfVMExists($vmName);
      if ($vmxName eq FAILURE) {
         $vdLogger->Error("Failed to get vmx path for $vmName. Please check".
			  " if there is an existing vm: $vmName on $hostIP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

   } elsif ((defined $vmTemplate) || (defined $ovfUrl)) {
      $changeName     = 1;
      my $dataStoreType = (defined $vmHash->{datastoreType}) ?
                           $vmHash->{datastoreType} : 'local';
      my $displayName;
      if (defined $ovfUrl) {
         if ($ovfUrl !~ /\//) {
            $vdLogger->Error("No absolute path given for ovf url");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         my @temp = split("\/", $ovfUrl);
         my $name = $temp[-1];
         $name =~ s/\.ovf$//g;
         $displayName = "$name" . "-" . $dataStoreType;
      } else {
         $displayName = $vmTemplate  . "-" . $dataStoreType;
      }
      if (defined $component) {
         $displayName = $component . "_" . $displayName;
      }
      $displayName = VDNetLib::Common::Utilities::GenerateName($displayName,
                                                               $vmIndex);
      # When ReturnVMXPathIfVMExists() return failure, it
      # means that no matching vm was found for given generated
      # vm name. A new vm is created in CreateLinkedClone(), and
      # UUID is attached to the to generated vm name, which is
      # kept for reuse. In the next iteration of TestSession,
      # since this vm that can be reused, has a UUID appended to
      # the vm name, we try to compare the generated
      # name (minus UUID) and compare with the vm name to be
      # reused. If the generated name is part of the vm name,
      # ReturnVMXPathIfVMExists() returns the complete path
      # of the actual vm with UUID that needs to be reused.
      $vmxName = $self->ReturnVMXPathIfVMExists($displayName);
      if ($vmxName ne FAILURE) {
         $vdLogger->Info("Re-using VM $displayName");
      } else {
         my $installType = $vmHash->{installtype};
         $installType = (defined $installType) ? $installType : "legacyclone";
         if (lc($installType) eq "legacyclone") {
            $vmObj = $self->CreateLinkedClone($vmHash,
                                              $vmIndex,
                                              $displayName, $component);
         } elsif($installType =~ /^fullclone$/i) {
            $vmObj = $self->CreateFullClone($vmHash,
                                            $vmIndex,
                                            $displayName);
         } elsif(lc($installType) eq "ovfdeploy") {
            $vmObj = $self->DeployOVF($vmHash,
                                      $vmIndex,
                                      $displayName);
         }
         if ($vmObj ne FAILURE) {
            $vmxName = $vmObj->{vmx};
         }
      }
      if ((not defined $vmxName) || ($vmxName eq FAILURE)) {
         $vdLogger->Error("Failed to setup Linked Clone.Please check if there ".
			  "exists a vm: $vmTemplate on the given VM Repository");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $initialState = "template";
   } else {
      $vdLogger->Error("Neither of VM IP, Name, vmx or Template Name provided");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Below code snippet is to make sure runtimeDir is set with following cases:
   # 1. vmIP defined
   # 2. vmxName defined
   # 3. vmName defined
   # 4. reuse VM
   # Or the runtimeDir will be left unused in case of running a tester with more
   # then one test cases which future results in running out of disk space in host
   if (not defined $self->{runtimeDir}) {
      $vmxName =~ m|(^.*)/VM-.*/.*vmx|;
      if (defined $1) {
         $vdLogger->Debug('No runtime vm dir found so setting the vm dir to '. $1 .
                          ' based on previous test case');
         $self->{runtimeDir} = $1;
      } else {
         $vdLogger->Warn('Failed to get runtimeDir');
      }
   }
   $ret = $self->CheckForPatternInVMX($vmxName,
                                      "^displayName",
                                      $self->{stafHelper},
                                      $self->{hostType});
   if ((not defined $ret) || ($ret eq FAILURE)) {
      $vdLogger->Error("STAF error while retrieving display name of " .
                       "$vmxName, on $hostIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($ret eq "") {
      $vdLogger->Error("Display name is empty for $vmxName, on $hostIP");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $ret =~ s/\s*//g;
   $ret =~ s/\n//g;
   # On ESX its displayName and on WS its displayname.
   $ret =~ s/displayName=//ig;
   $ret =~ s/\"//g;

   my $vmDisplayName = $ret;

   if (not defined $vmObj) {
      $vmObj = VDNetLib::VM::VMOperations->new($self,
                                               $vmxName,
                                               $vmDisplayName, $component);
      if (FAILURE eq $vmObj) {
         $vdLogger->Error("Failed to create VMOperations object for VM: ".
		                    "$vmIndex");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vmObj->{displayName} = $vmDisplayName;
   }
   $vdLogger->Info("Registered VM name for $vmObj->{vmx} is $vmObj->{'vmName'}");

   #
   # Tools upgrade or vmotion does not require/need cd-rom, so removing it
   #
   $result = $vmObj->VMOpsDeviceAttachState("CD\/DVD drive");
   if ((not defined $result) || ($result  eq FAILURE)) {
      $vdLogger->Warn("Not able to get state of any CDROM on this VM");
   }

   if($result ne 0) {
      # If result is non-zero, it means CDROM is attached to this VM.
      my $cdromTask = "remove";
      $result = $vmObj->VMOpsAddRemoveVirtualDevice("cdrom", $cdromTask);
      if($result eq FAILURE){
         $vdLogger->Warn("Not able to $cdromTask virtual CDROM to this VM");
      }
   }
   if (defined $vmObj->{_pyIdName}) {
       $vmObj->{$vmObj->{_pyIdName}} = $vmObj->{vmName};
   } else {
       $vdLogger->Warn('_pyIdName attribute is not defined for the the VM');
   }
   #
   # Delete parameters than cannot be understood by ConfigureComponent()
   #
   delete $vmHash->{'vmName'};
   delete $vmHash->{'host'};
   delete $vmHash->{'template'};
   delete $vmHash->{'type'};
   delete $vmHash->{'datastoreType'};
   delete $vmHash->{'ip'};
   delete $vmHash->{'tools'};
   delete $vmHash->{'installtype'};
   delete $vmHash->{'prefixDir'};
   $vmObj->RemoveVirtualAdapters(); # delete existing test adapters
   if (exists $vmHash->{'build'}) {
      $vdLogger->Debug("build: $vmHash->{'build'}");
      $vmObj->SetEsxBuild($vmHash->{'build'});
   }

   if (exists $vmHash->{'build'}) {
     delete $vmHash->{'build'};
   }
   $vmObj->{changeName} = $changeName;
   return $vmObj, $initialState, $vmIP;
}


########################################################################
#
# GetVMRuntimeDir --
#     Method to get runtime directory for vm deployment
#
# Input:
#     datastoreType: type of the datastore
#     vmIndex: index for the vm
#     prefixDir: any prefix dir to use
#     vmType: type of vm. could be vm or dhcpserver or powercli
#
# Results:
#     absolute path to a directory, if successful;
#     FAILURE, otherwise.
#
# Side effects:
#
########################################################################

sub GetVMRuntimeDir
{
   my $self          = shift;
   my $datastoreType = shift;
   my $vmIndex	      = shift;
   my $prefixDir     = shift;
   my $vmType = shift || 'VM';
   my $command;
   my $result;
   my $ret;

   my $hostIP     = $self->{hostIP};


   #
   # Creating runtime directory
   #
   # Try to create a directory with default dir name "vdtest".
   # If that directory exists, then try to delete it,
   # if delete operation fails (usually because vm is still powered on
   # and being used by someother session), then create new directory
   # vdtest.0.
   # Keep trying the operation mentioned about by incrementing the count
   # until a runtime directory is created.
   #
   my $dirNameDecided = 0;

   # The VMs are deployed with multi-threading, each thread has its own ID. If using
   # $$, one directory will be created for each VM. We replace it with current process
   # group ID to reduce direcory number.
   my $defaultDir = "vdtest-" . getpgrp(0); # create a dir name with process group id
   my $runtimeDir = $defaultDir;
   my $count      = 0;
   my $filesystemType;
   my $data;

   #
   # Check if sharedStorage is defined at the command line, if yes, then use
   # the sharedstorage to deploy linked clone VMs. This is only on
   # esx5x-stable branch, on main branch, sharedstorage will used only on
   # need basis i.e when a test case explicitly has a requirement to use
   # sharedstorage under Parameters hash.
   #
   if (defined $datastoreType) {
      if ($datastoreType  =~ /shared/i) {
         $prefixDir = VMFS_BASE_PATH . VDNET_SHARED_MOUNTPOINT;
         $vdLogger->Info("Using shared storage $prefixDir to deploy VM".
                         " on $hostIP");
      } elsif ($datastoreType  =~ /vsan/i) {
         $prefixDir = VMFS_BASE_PATH . VSAN_LOCAL_MOUNTPOINT;
         $vdLogger->Info("Using vsan storage $prefixDir to deploy VM".
                         " on $hostIP");
      } else {
         $vdLogger->Error("Unsupported datastoreType passed " . $datastoreType);
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   if (not defined $prefixDir) {
      #
      # If not prefix directory is specified, this block finds a vmfs
      # partition which has the largest space on the given host
      #
      $vdLogger->Debug("Prefix directory to create runtime directory not provided");
      $vdLogger->Trace("Finding a vmfs datastore with largest space available");
      $prefixDir = $self->{stafHelper}->GetCommonVmfsPartition($hostIP);
      if (($prefixDir eq FAILURE) || (not defined $prefixDir)) {
         $vdLogger->Error("Failed to get the datastore on $hostIP");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      # Append the datastore name with /vmfs/volumes
      $prefixDir = VMFS_BASE_PATH . "$prefixDir";
   }

   $prefixDir =~ s/\/$|\\$//; # Trailing slashes in the path are removed
   $filesystemType = VDNetLib::Common::Utilities::GetFileSystemTypeFromVIM(
                                                     $hostIP,
                                                     $prefixDir,
                                                     $self->{userid},
                                                     $self->{sshPassword});

   if ((not defined $filesystemType) || ($filesystemType eq FAILURE)) {
      $vdLogger->Error("Failed to get the file system type on ".
                       "$hostIP for prefix directory $prefixDir");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if (defined $self->{runtimeDir}) {
      $runtimeDir = $self->{runtimeDir};
      $dirNameDecided = 1;
   } else {
      $runtimeDir = $prefixDir . "/" . $runtimeDir;
   }

   while (!$dirNameDecided) {
      if ($filesystemType =~ /vsan/i) {
         # Write your own DirExists as staf's will not work with vsan
         # hard coding for now. Filed bug # 875234 to fix it later.
         $ret = 0;
      } else {
         $ret = $self->{stafHelper}->DirExists($hostIP,
                                               $runtimeDir);
         if ($ret eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
      if ($ret == 1) {
         # directory exists, so deleting it
         $vdLogger->Debug("Runtime directory $runtimeDir exists");

         #
         # Now that the runtime directory exists, it is important to do some
         # check before deleting and re-using the directory name.
         # Check if any vmx process is running that uses vmx file from
         # the runtime directory. Execute "ps -c" command and grep for
         # vmx path that include runtime directort.
         #
         # First, get the absolute vmx path.
         # Example, absolute path of
         # /vmfs/volumes/datastore1/vdtest0 is
         # /vmfs/volumes/4c609bdc-46e83530-9a8e-001e4f439d6f/vdtest0
         #
         # The reason to find this path is that ps -c output reports
         # absolute path.
         #
         my $absPath = VDNetLib::Common::Utilities::GetActualVMFSPath($hostIP,
                                                               $runtimeDir);
         if ($absPath eq FAILURE) {
            $vdLogger->Error("Failed to get absolute value of $runtimeDir");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         #
         # Executing command one the end host to find the list of process
         # running.
         #
         $command = "start shell command ps -c | grep \"'$absPath\/'\" wait " .
                       "returnstdout stderrtostdout";
         ($ret, $data) = $self->{stafHelper}->runStafCmd($hostIP,
                                                         'PROCESS',
                                                         $command);

         if ($ret eq FAILURE) {
            $vdLogger->Error("Failed to execute staf command: $command ".
                             "to find info on $hostIP");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         #
         # ps -c | grep $absPath will include many details including
         # one process for grep command. So, look for only the
         # /bin/vmx process
         #
         if ($data =~ /\/bin\/vmx\S* .* $absPath/) {
            $vdLogger->Debug("Files under $runtimeDir in use");
            $dirNameDecided = 0;
         } else {
            $dirNameDecided = 1;
         }
         if (!$dirNameDecided) {
            $runtimeDir = $prefixDir . "/" . $defaultDir . $count;
            $vdLogger->Debug("Trying to create runtime directory with new " .
                             "directory name $runtimeDir");
            $count++;
            next;
         }
      } else {
         # Decided the directory name to create
         $dirNameDecided = 1;
      }
   }

   if (defined $datastoreType && $datastoreType  =~ /shared/i) {
      # The runtimeDir is kept for cleanup, the calling method is
      # Testbedv2::CleanupTestbedHosts. Though we don't keep it for shared
      # storage because we may be at the risk of deleting runtimeDir created
      # by other testers also using the shared storage, that will let us be
      # in deep trouble.
      $vdLogger->Debug("Skipping the save of runtimeDir for VM using shared"
                        . " storage");
   } else {
      $self->{runtimeDir}=$runtimeDir;
   }
   # append hostIP to keep it unique on shared storage PR1401341
   $runtimeDir = $runtimeDir . "/" . uc $vmType . "-" . $vmIndex .
                 "-" . $hostIP;
   $vdLogger->Debug("Creating runtime directory $runtimeDir on $hostIP");

   $result = VDNetLib::Common::Utilities::CreateDirectory($hostIP,
                                                        $runtimeDir,
                                                        $filesystemType);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to create $runtimeDir on $hostIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $runtimeDir;
}


########################################################################
#
# GetOS --
#     Method to get os of host
#
# Input:
#     None
#
# Results:
#     os in case of SUCCESS
#     FAILURE, otherwise.
#
# Side effects:
#     None
#
########################################################################

sub GetOS
{
   my $self = shift;
   my $osType = $self->{stafHelper}->GetOS($self->{hostIP});
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $self->{hostIP}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $osType;
}


########################################################################
#
# GetArchitecture --
#     Method to get arch of os of host
#
# Input:
#     None
#
# Results:
#     os in case of SUCCESS
#     FAILURE, otherwise.
#
# Side effects:
#     None
#
########################################################################

sub GetArchitecture
{
   my $self = shift;
   my $osArch = $self->{stafHelper}->GetOSArch($self->{hostIP});
   if (not defined $osArch) {
      $vdLogger->Error("Unable to get OS Arch of $self->{hostIP}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $osArch;
}


####################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
##     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
#######################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj;
   eval {
      # FIXME(gjayavelu): standardize ip, username, password across
      # the library
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $self->{hostIP},
                                              $self->{userid},
                                              $self->{sshPassword});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (exists $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   return $inlinePyObj;
}

################################################################################
#
# CopyFile
#     Copy one file from one host to another host
#
# Input:
#     spec: test spec including:
#           { source_file_name: XX, <--- source file path in source host
#             dest_host: YY,             <--- destination host obj
#             dest_file_name: ZZ         <--- destination file path which to copy to
#           }
#
# Results:
#     SUCCESS, if the operation is SUCCESS
#     FAILURE, in case of any errors
#
# Side effects:
#     None
#
################################################################################

sub CopyFile
{
   my $self = shift;
   my $args = shift;
   my $srcPath = $args->{source_file_name};
   my $destHostObj = $args->{dest_host};
   my $destPath = $args->{dest_file_name};

   my $destIP = $destHostObj->{hostIP};
   $vdLogger->Info("Trying to transfer file from $self->{hostIP} : $srcPath
                     to $destIP: $destPath");
   my $result = $self->{stafHelper}->STAFFSCopyFile($srcPath,
                                                    $destPath,
                                                    $self->{hostIP},
                                                    $destIP);
   if ($result ne 0) {
      $vdLogger->Error("Unable to transfer file from the host $self->{hostIP}
                        to $destIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# HealthCheckupAndRecovery
#      This method will check the health status of inventory, if not healthy,
#      then try to recover it.
#
# Input:
#      None.
#
# Results:
#      TRUE: inventory status is good
#      FALSE: inventory status is bad, and we recover it successfully
#      FAILURE: recovery failed in any error
#
# Side effects:
#      None.
#
###############################################################################

sub HealthCheckupAndRecovery
{
   my $self = shift;
   my $result = VDNetLib::Workloads::Utilities::HealthCheckupAndRecovery(
                $self, $self->checkupRecoveryMethods);
   my $resultMessage = ($result eq TRUE)? "healthy" :
      (($result eq FALSE)? "not healthy but we recovered it" : "failed to recover");
   if ($result eq TRUE) {
      $vdLogger->Debug("Host health check and recovery returns \"$resultMessage\"");
   } else {
      $vdLogger->Error("Host health check and recovery returns \"$resultMessage\"");
   }
   return $result;
}


########################################################################
#
# GetCoreDumpPaths -
#     Method to fetch the path of core files.
#
# Input:
#     srcDirs: source directory on host (optional). This is absolute path.
#
# Results:
#     Array reference containing paths to core dump files.
#     FAILURE, in case of any other error
#
# Side effects:
#     None
#
########################################################################

sub GetCoreDumpPaths
{
   my $self   = shift;
   my $srcDirs = shift || $self->CORE_DUMP_DIRS;
   my $host = $self->{hostIP};
   my $ret;
   #  1428550: List of ignored dump files prefix
   my @ignoreList = @{$self->IGNORE_CORE_DUMP_LIST};
   if (not defined $srcDirs) {
      $vdLogger->Error("File directory invalid to check for coredump");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (ref($srcDirs) ne 'ARRAY') {
       $vdLogger->Error("srcDirs must be specified as an ARRAY ref, got: " .
                        Dumper($srcDirs));
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   my @foundCoreDumps;
   foreach my $srcDir (@$srcDirs) {
       my $cmd = "ls $srcDir";
       $ret = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
       $vdLogger->Debug("On host $host $cmd returns " . Dumper($ret));
       # Process the result
       if (($ret->{rc} ne 0) || ($ret->{exitCode} ne 0)) {
          $vdLogger->Info("No dump file got generated on host $host in dir: " .
                          "$srcDir");
          next;
       } elsif ($ret->{stdout} eq "") {
          $vdLogger->Info("No dump file got generated on host $host in dir: " .
                          "$srcDir");
          next;
       }
       my @foundDumps = split(/\r*\n/, $ret->{stdout});
       foreach my $foundDump (@foundDumps) {
          $foundDump =~ /([^\.]*)/;
          if (!(grep(/^$1$/, @ignoreList))) {
             push(@foundCoreDumps, "$srcDir$foundDump");
          }
       }
   }
   return \@foundCoreDumps;
}

########################################################################
#
# DetectCoreDump -
#     Method to detect the core files.
#
# Input:
#     srcDirs: source directory on host (optional). This is absolute path.
#
# Results:
#     TRUE if no core dump detected, FALSE otherwise.
#     FAILURE, in case of any other error
#
# Side effects:
#     None
#
########################################################################

sub DetectCoreDump
{
   my $self = shift;
   my $srcDirs = shift;
   my $foundCoreDumps = $self->GetCoreDumpPaths($srcDirs);
   if ($foundCoreDumps eq FAILURE) {
      $vdLogger->Error("Failed to retireve core dumps list from " .
                       "$self->{hostIP}");
   }
   if (scalar(@$foundCoreDumps)) {
      $vdLogger->Warn("Dump files found on host $self->{hostIP} are:\n" .
                      Dumper($foundCoreDumps));
      return FALSE;
   }
   return TRUE;
}


###############################################################################
#
# CopyCoreDumpFile
#      This method will check if there is core dump file under one directory,
#      If yes, copy them to directory on MC
#
# Input:
#      srcDir : source directory on host (optional). This is absolute path.
#               After copy, the files under srcDir will be deleted
#      dstDir : destination directory name on MC (mandatory) This is not absolute
#               path, just directory name under vdnet log directory
#
# Results:
#      TRUE: hostd is running
#      SUCCESS: file copy successful
#      FAILURE: in case any error
#
# Side effects:
#      None.
#
###############################################################################

sub CopyCoreDumpFile
{
   my $self   = shift;
   my $srcDirs = shift || $self->CORE_DUMP_DIRS;
   my $dstDir = shift;
   my $host = $self->{hostIP};
   my $ret;

   if (not defined $srcDirs) {
      $vdLogger->Error("File directory invalid to copy core dump");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (ref($srcDirs) ne 'ARRAY') {
       $vdLogger->Error("srcDirs must be specified as an ARRAY ref, got: " .
                        Dumper($srcDirs));
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   if (not defined $dstDir) {
      $dstDir = $self->CORE_DUMP . "/" . $host;
   }

   # Check if there is a dump file.
   if ($self->DetectCoreDump($srcDirs) eq TRUE) {
      return SUCCESS;
   }
   $vdLogger->Error("On $host, detected core dump");
   if (VDNetLib::Common::Utilities::CreateSSHSession($host,
       "root", $self->{sshPassword}) eq FAILURE) {
      $vdLogger->Error("Create ssh session failed to host $host");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $logFileName = $vdLogger->GetLogFileName();
   my $logFilePath = substr($logFileName, 0, rindex($logFileName, '/'));
   my $dumpDir = "$logFilePath/" . $dstDir . "/";
   `mkdir -p $dumpDir` if (!(-e "$dumpDir"));

   foreach my $srcDir (@$srcDirs) {
       my $dirFound = VDNetLib::Common::Utilities::DirExists(dir => $srcDir,
          remoteIP => $host, stafHelper => $self->{stafHelper});
       if ($dirFound eq TRUE) {
           my $dirContents = VDNetLib::Common::Utilities::ListDirectory(dir => $srcDir,
              remoteIP => $host, stafHelper => $self->{stafHelper});
           if ((not defined $dirContents) || ($dirContents eq FAILURE)) {
                $vdLogger->Error("Failed to retireve the contents of " .
                                 "$srcDir on $host");
                VDSetLastError("EOPFAILED");
                return FAILURE;
           }
           if (scalar(@$dirContents)) {
              $vdLogger->Debug("Copying core dump files on host $host from source ".
                               "directory : $srcDir to destination directory : $dumpDir");
              my $result = VDNetLib::Common::Utilities::CopyDirectory(srcDir => $srcDir,
                   dstDir => $dumpDir, srcIP => $host, stafHelper => $self->{stafHelper});
              if ($result eq FAILURE) {
                 $vdLogger->Error("Failed to copy core directory: $srcDir on " .
                                  "host $host to local directory $dumpDir");
                 VDSetLastError("ESTAF");
                 return FAILURE;
              }
           }
       } elsif ($dirFound eq FALSE) {
         $vdLogger->Debug("Core dump directory $srcDir not found on $host, " .
                          "skipping copying of that dir ...");
       } else {
         $vdLogger->Debug("Failed to check existence of $srcDir on $host");
         VDSetLastError("EOPFAILED");
         return FAILURE;
       }
       my $cmd = "rm -rf $srcDir/*";
       $ret = $self->{stafHelper}->STAFSyncProcess($host, $cmd, undef, undef, 1);
       if ($ret eq FAILURE) {
          $vdLogger->Error("Failed to remove $srcDir contents from $host");
          VDSetLastError("EOPFAILED");
          return FAILURE;
       }
   }
   $ret = system ("chmod -R ugo+r $dumpDir");
   if ($ret != 0) {
      $vdLogger->Error("Changing file mode failed on $dumpDir on launcher");
      return FAILURE;
   }
   return SUCCESS;
}

1;
