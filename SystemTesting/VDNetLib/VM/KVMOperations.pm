########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VM::KVMOperations;

use strict;
use warnings;
use base qw(VDNetLib::VM::VMOperations
            VDNetLib::Root::Root);

use Data::Dumper;
use vars qw{$AUTOLOAD};
use Scalar::Util qw(blessed);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              CallMethodWithKWArgs
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                    VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::Utilities;

use constant MY_USERNAME   => "root";
use constant MY_PASSWORD   => "ca\$hc0w";
use constant VM_LOG_DIR => "/var/log/libvirt/qemu/";
use VDNetLib::NetAdapter::Vnic::VIF;

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VM::KVMOperations
#
# Input:
#     ip : ip address of the kvm
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VM::KVMOperations;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my $hostObj = shift;
   my $self;
   $self->{type}     = "kvm";
   $self->{hostObj}  = $hostObj;
   $self->{stafHelper} = $hostObj->{stafHelper};
   $self->{uniqueName} = undef;
   $self->{_pyIdName} = 'name';
   $self->{_pyclass} = 'vmware.kvm.vm.vm_facade.VMFacade';
   bless $self, $class;
   return $self;
}


#############################################################################
#
# GetGuestLogs --
#     Method which copies the guest logs to the specific log directory.
#
# Input:
#     LogDir : Log directory to which guest logs have to be copied on master
#              controller.
#
# Results:
#     "SUCCESS", if all the logs get copied to the specific directory
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
# Note: Currently this functions collects only linux logs.
#
#############################################################################

sub GetGuestLogs
{
   my $self = shift;
   my $superRet = $self->SUPER::GetGuestLogs(@_);
   my $logDir = shift;
   if (not defined $logDir) {
      $vdLogger->Error("Destination dir for storing VM logs not provided");
      VDSetLastError("ENODEF");
      return FAILURE;
   }
   my $hostObj = $self->{hostObj};
   my $uniqueName = $self->{uniqueName};
   my $stafHelper = $self->{stafHelper};
   my $guestLogBaseDir = VM_LOG_DIR;
   if (not defined $logDir) {
      $vdLogger->Error("Base directory to fetch logs from is not defined");
      VDSetLastError("ENODEF");
      return FAILURE;
   }
   my $vmLogPath = "$guestLogBaseDir/$uniqueName.log";
   my $hostIP = $hostObj->{hostIP};
   if (not defined $hostIP) {
      $vdLogger->Error("IP of Host of VM $uniqueName is not defined, " .
                       "aborting log collection for the VM");
      VDSetLastError("ENODEF");
      return FAILURE;
   }
   if (VDNetLib::Common::Utilities::Ping($hostIP)) {
       $vdLogger->Error("Host ($hostIP) of VM $uniqueName is not reachable, " .
                        "aborting log collection for the VM");
       return FAILURE;
   }
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   if (not defined $localIP || $localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of the master controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $result = $stafHelper->STAFFSCopyFile(
      $vmLogPath, $logDir, $hostIP, $localIP);
   if ($result ne 0) {
      $vdLogger->Error("Failed to copy $vmLogPath to log directory using STAF:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($superRet eq FAILURE) {
      $vdLogger->Error("Failed to collect logs from VM $uniqueName");
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
#     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $hostInlineObj = $self->{hostObj}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
        $hostInlineObj, $self->{vmName},
        VDNetLib::Common::GlobalConfig::DEFAULT_KVM_VM_USER,
        VDNetLib::Common::GlobalConfig::DEFAULT_KVM_VM_PASSWORD,
        $self->{vmIP});
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object of $self->{_pyclass}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}


########################################################################
#
# VMOpsDeviceAttachState
#     Method to be overridden as its a No-OP for KVM
#
# Input:
#
# Results:
#     integer
#
########################################################################

sub VMOpsDeviceAttachState
{
   return 0;
}


########################################################################
#
# AddEthernetAdapters --
#     Method to add virtual ethernet adapters
#
# Input:
#     Reference to an array of hash with each hash containing following
#     keys:
#               driver              : <vmxnet3/e1000>
#               portgroup           : reference to portgroup (vdnet
#                                     core object)
#               connected           : boolean
#               startConnected      : boolean
#               allowGuestControl   : boolean
#               reservation         : integer value in Mbps
#               limit               : integer value in Mbps
#               shareslevel         : normal/low/high/custom
#               shares              : integer between 0-100
#
#
# Results:
#     Adapter object array for a successful operation;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub AddEthernetAdapters
{
   my $self         = shift;
   my $adaptersSpec = shift;
   my $type         = shift;

   my @arrayOfVifObjects;
   my $bridge_label = $adaptersSpec->[0]->{'bridge'}->{'interface'};

   for (my $i = 0; $i< scalar(@$adaptersSpec); $i++) {
      my %args;
      my $bridge_obj = $adaptersSpec->[$i]->{'backing'};
      my $inlineVifObj;
      $args{vmOpsObj} = $self;
      my $vifObj = VDNetLib::NetAdapter::Vnic::VIF->new(%args);
      if ($vifObj eq "FAILURE") {
         $vdLogger->Error("Failed to initialize vif obj on VM: $self->{vmx}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $pyVifObj;
      my $vmInlineObj;
      eval {
         $vmInlineObj = $self->GetInlinePyObject();
         $inlineVifObj = $vifObj->GetInlinePyObject();
         my $pybridge = $bridge_obj->GetInlinePyObject();
         $pyVifObj = CallMethodWithKWArgs($inlineVifObj, 'create',
                                          {backing => $pybridge});
      };
      if ($@ || not defined $pyVifObj->{MAC}) {
         $vdLogger->Error("create failed for $self->{vmName} Reason:" .
                          Dumper($@));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      # Create vdnet vif object and store it in array of vif objects
      if (not defined $pyVifObj->{kvm_device}) {
         $vdLogger->Error("Unable to get the device name of the newly " .
                          "created VIF");
         VDSetLastError("ENODEF");
         return FAILURE;
      }
      my $macSettingResult = undef;
      $macSettingResult = $vifObj->SetMACAddress($pyVifObj->{MAC});
      if (not defined $macSettingResult || $$macSettingResult eq FAILURE) {
         $vdLogger->Error("Unable to store the MAC address of the created " .
                          "VIF");
         return FAILURE;
      }
      $vifObj->{name} = $pyVifObj->{kvm_device};
      $vifObj->{interface} = $pyVifObj->{linux_device};
      $vifObj->{controlIP} = CallMethodWithKWArgs($vmInlineObj, 'get_ip');
      $vifObj->{driver} = 'virtio';
      push @arrayOfVifObjects, $vifObj;
   }
   return \@arrayOfVifObjects;
}


########################################################################
#
# RemoveVirtualAdapters --
#     Method to delete VIF components.
#
# Input:
#     arrayOfPerlObjects: reference to array of perl objects on which
#     delete is called. If none is provided then by default all the test
#     adapters on the VMs are deleted.
#
# Results:
#     SUCCESS, if adapters are removed successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     Adapters removed cannot be accessed again
#
########################################################################

sub RemoveVirtualAdapters
{
   my $self             = shift;
   my $arrayOfPerlObjects = shift;
   # TODO(gaggarwal/salmanm/gjayavelu): Create a utility method for the logic
   # below that checks the input and logs the error when input is not right.
   if (not defined $arrayOfPerlObjects) {
      $vdLogger->Warn("No VIFs provided for deletion, deleting all test " .
                      "vifs on the VM");
      my $packageName = blessed $self;
      my $pyObj = $self->GetInlinePyObject();
      if ($pyObj eq "FAILURE") {
         $vdLogger->Error("Failed to get inline python object for " .
                          "$packageName");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      CallMethodWithKWArgs($pyObj, 'delete_all_test_adapters', {});
      return SUCCESS;
   }
   foreach my $perlObj (@$arrayOfPerlObjects) {
      my $pyObj;
      my $result = undef;
      my $packageName = blessed $perlObj;
      if (not defined $perlObj->{name}) {
         $vdLogger->Error("VifObj->name is not defined for ".
                          Dumper($perlObj));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $pyObj = $perlObj->GetInlinePyObject();
      if ($pyObj eq "FAILURE") {
         $vdLogger->Error("Failed to get inline python object for " .
                          "$packageName");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $vdLogger->Debug("We got pyObj for VIF, now executing delete method");
      eval {
         $result = CallMethodWithKWArgs($pyObj, 'delete', {});
      };
      if ($@) {
         $vdLogger->Error("Exception thrown while executing VIF delete " .
                          " $packageName:\n". $@);
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# ChangeVMState --
#     Method to poweron/poweroff/suspend/resume specified VM;
#
# Input:
#     vmstate  -  A value of poweron/poweroff/suspend/resume;
#     options  -  Reference to a hash containing the following keys (Optional).
#                 waitForTools - (0/1) # Optional.
#
# Results:
#     "SUCCESS", if the VM was successfully powered on.
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub ChangeVMState
{
   my $self = shift;
   my $vmstate = shift;
   my $options = shift;

   my $operation = {
      'poweron'  => 'on',
      'poweroff' => 'off',
      'suspend'  => 'suspend',
      'resume'   => 'resume',
      'reset'    => 'reset',
      'reboot'   => 'reboot',
   };
   my $method = $operation->{$vmstate};
   if (defined $method) {
      my $inlineObj = $self->GetInlinePyObject();
      # Because we don't know the return value of inline layer(qe lib)
      # we cannot check for return SUCCESS or FAILURE. So how do we verify
      # the call.
      # One way is to do a get_power_state but then it prevents negative
      # testing. Something to think about for future.
      eval {
         $inlineObj->$method();
      };
      if ($@) {
         $vdLogger->Error("Failed to $vmstate VM $self->{vmIP}" . Dumper($@));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$vmstate is not a legal state we can support");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   return SUCCESS;
}

########################################################################
#
# VMOpsPowerOff--
#     Method to poweroff specified VM;
#
# Input:
#     vmstate  -  A value of poweron/poweroff/suspend/resume;
#
# Results:
#     "SUCCESS", if the VM was successfully powered off.
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub VMOpsPowerOff
{
    my $self = shift;
    return $self->ChangeVMState('poweroff');
}


########################################################################
#
# VMOpsUnRegisterVM --
#     Method to unregister/destroy the VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the VM is unregistered/deleted successfully;
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub VMOpsUnRegisterVM
{
    my $self = shift;
    my $pyObj = $self->GetInlinePyObject();
    if (not defined $self->{$self->{_pyIdName}}) {
       $vdLogger->Error("VM\'s name is not defined, can not delete the VM");
       return FAILURE;
    }
    eval {
       CallMethodWithKWArgs($pyObj, 'delete', {});
    };
    if ($@) {
        $vdLogger->Error('VM deletion failed with error: ' . Dumper($@));
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

   my $inlineObj = $self->GetInlinePyObject();
   my $result = $inlineObj->get_power_state();
   if (not defined $result) {
      $vdLogger->Error("get_power_state() returned undef.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to power state of $self->{'vmx'}");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $ret;
   $ret->{result} = $result;
   # TODO: Unit testing
   # my $ret->{result} = "poweredon";
   return $ret;
}


########################################################################
#
# GetGuestControlMAC
#       Get the control mac of this VM's guest OS
#
# Input:
#       none
#
# Results:
#       mac if no errors encoutered
#       SUCCESS in case of error
#
# Side effects:
#       VM will be rebooted
#
########################################################################

sub GetGuestControlMAC
{
   my $self = shift;
   my $inlineObj = $self->GetInlinePyObject();
   # Please note: Just as VM Network is hard coded for ESX control Network
   # get_management_mac hard codes breth0 as the control channel
   my $controlMAC = $inlineObj->get_management_mac();
   if ($controlMAC eq FAILURE) {
      $vdLogger->Error("Failed to get controlMAC for $self->{'vmName'}");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $controlMAC;
}


########################################################################
#
# GetWorldID
#     Method to be overridden as its a No-OP for KVM
#
# Input:
#
# Results:
#     string
#
########################################################################

sub GetWorldID
{
   return 'NOT-IMPLEMENTED-WorldID-5';
}


########################################################################
#
# GetGuestControlIP--
#       Get the control IP of this VM's guest OS
#
# Input:
#       none
#
# Results:
#       IP if no errors encoutered
#       SUCCESS in case of error
#
# Side effects:
#       VM will be rebooted
#
########################################################################

sub GetGuestControlIP
{
   my $self = shift;
   # Please note: Just as VM Network is hard coded for ESX control Network
   # get_management_mac hard codes breth0 as the control channel
   my $inlineObj = $self->GetInlinePyObject();
   my $controlIP = FAILURE;
   my $retry = 8;
   while (($controlIP !~ /\d+\.\d+/) && ($retry)) {
      $vdLogger->Info("Getting controlIP for $self->{'vmName'} " .
                       "$retry retry attempts left");
      $controlIP = $inlineObj->get_management_ip();
      sleep(10) if ($controlIP !~ /\d+\.\d+/);
      $retry--;
   }
   if ($controlIP !~ /\d+\.\d+/) {
      $vdLogger->Error("Failed to get controlIP for $self->{'vmName'}");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $controlIP;
}


################################################################################
#
# InstallSTAFInGuest-
#   Method to install staf on guest os.
#
# Input:
#
# Results:
#
# Side effects:
#   None.
#
################################################################################

sub InstallPackagesInGuest
{
   my $self = shift;

   # We dont want to do this after every poweron operation.
   # This should happen on the first poweron only when the vm is created
   # This condition helps to not do the setup again and again
   my $result = $self->{stafHelper}->WaitForSTAF($self->{vmIP}, 30, 0);
   if ($result  eq FAILURE ) {
      $vdLogger->Debug("WaitForSTAF in InstallPackagesInGuest failed. ".
                       "So Installing packages on $self->{vmIP} ");
   } else {
      return SUCCESS;
   }


   # KVM VMs have this password
   my $pwd = $self->GetPassword();
   $pwd =~ s/\\//g; # ssh doesn't like escape \
   $self->{sshPassword} = $pwd;
   if (VDNetLib::Common::Utilities::CreateSSHSession($self->{vmIP},
       "root", $self->{sshPassword}) eq FAILURE) {
      $vdLogger->Error("Failed to establish a SSH session with " .
                       $self->{vmIP});
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Created ssh session with VM: $self->{vmIP}");
   my $sshHost = $sshSession->{$self->{vmIP}};
   #
   # Copy the ESX setup script to the host and run the script
   # using SSH
   #
   my $setupScript = "vdnet_linux_setup.py";
   my $srcScript = "$FindBin::Bin/../scripts/" . $setupScript;
   my $dstScript = "/tmp/" . $setupScript;
   my ($rc, $out) = $sshHost->ScpToCommand($srcScript, $dstScript);
   if ($rc ne "0") {
      $vdLogger->Error("Failed to copy " . $setupScript . " file " .
                       " to $self->{vmIP}");
      $vdLogger->Debug("ERROR:$rc " . Dumper($out));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Find the local ip to be used for RPC and to update /etc/hosts
   # on the host
   my $ipList = VDNetLib::Common::Utilities::GetAllLocalIPAddresses();

   my @remoteIPOctets = split('\.', $self->{vmIP});
   my $launcherIP;
   foreach my $entry (@$ipList) {
      my @launcherIPOctets = split('\.', $entry);
      if ($remoteIPOctets[0] eq $launcherIPOctets[0]) {
         $launcherIP = $entry;
         last;
      }
   }
   my $vdNetSrc = "scm-trees";
   my $vdNetShare = VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_DIR;
   my $command = "python $dstScript " .
#      "--vdnet $vdNetSrc:/$vdNetShare " .
      "--launcher $launcherIP ";
   my $toolchainMirror = $ENV{VDNET_TOOLCHAIN_MIRROR};
   if (defined $toolchainMirror) {
      $command = $command . " --toolchain $toolchainMirror";
   }
   my $stafMirror = $ENV{VDNET_STAF_MIRROR};
   if (defined $stafMirror) {
      $command = $command . " --staf $stafMirror";
   }
   $vdLogger->Info("Running setup script on $self->{vmIP}: $command ...");
   # We are doing mounting and staf installation here which is taking
   # long time on KVM guests
   ($rc, $out) = $sshHost->SshCommand($command, 300);
   $vdLogger->Trace("output of vdnet_linux_setup on host $self->{vmIP} " . Dumper($out));
   # TODO: decide location to dump the output
   my $stdout = join("", @$out);
   if ($rc ne "0") {
      $vdLogger->Debug("Failed to setup host $self->{vmIP} for vdnet");
      $vdLogger->Debug("ERROR: $rc " . Dumper($stdout));
   }

   # Enable passwordless access for Guest OS.
   # This is a nicira qe lib requirement which asks for password during
   # power off poweration
   my $connectioninlinePyObj = CreateInlinePythonObject('connection.Connection',
                                              $self->{vmIP},
                                              MY_USERNAME,
                                              $self->GetPassword(),
                                              "None",
                                              "ssh"
                                              );
   $connectioninlinePyObj->{anchor}->enable_passwordless_access();
   $vdLogger->Info("Enabled passwordless access for $self->{vmIP}");
   return SUCCESS;
}



########################################################################
#
# GetPassword--
#     Method to get password of guest in the VM.
#
# Input:
#     None
#
# Results:
#     password in case of SUCCESS
#     FAILURE, otherwise.
#
# Side effects:
#     None
#
########################################################################

sub GetPassword
{
   return MY_PASSWORD;
}


########################################################################
#
# GetInlineVMObject--
#     Wrapper method for GetInlinePyObject, as parent code calls it
#
# Input:
#     None
#
# Results:
#     password in case of SUCCESS
#     FAILURE, otherwise.
#
# Side effects:
#     None
#
########################################################################

sub GetInlineVMObject
{
   my $self = shift;
   $self->GetInlinePyObject();
}

1;
