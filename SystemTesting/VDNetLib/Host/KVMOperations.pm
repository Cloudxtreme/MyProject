package VDNetLib::Host::KVMOperations;

use strict;
use warnings;
use base qw(VDNetLib::Host::HypervisorOperations);

use Data::Dumper;
use Scalar::Util qw(blessed);
use vars qw{$AUTOLOAD};
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              CallMethodWithKWArgs
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                    VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use VDNetLib::NetAdapter::Pnic::PIF;
use VDNetLib::Switch::Bridge::Bridge;
use VDNetLib::Common::Utilities;
use constant VDNET_LOCAL_MOUNTPOINT => "/vdtest";
use constant KVM_RUNTIME_VM_DIR => "/vms/images";
use constant HOST_SETUP_SCRIPT => "vdnet_linux_setup.py";
use constant HYPERVISOR => "kvm";
use constant REMOTE_METHOD_TIMEOUT => 30;
use VDNetLib::VM::KVMOperations;
use constant IGNORE_CORE_DUMP_LIST => [];
use constant checkupRecoveryMethods => [
   {
      'checkupmethod' => 'DetectCoreDump',
      'recoverymethod' => 'CopyCoreDumpFile',
   },
];

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::Host::HostOperations).
#
# Input:
#      hostIP : IP address of the host. hostname is also accepted.
#               (Required)
#      stafObj: an object of VDNetLib::Common::STAFHelper.
#               If not provided, a new object with default options
#               will be created. (optional)
#      vdnetSource: vdnet source code to mount (<server>:/<share>)
#      vmRepository: vdnet vm repository to mount (<server>:/<share>)
#      sharedStorage: shared storage to mount (<server>:/<share>)
#      password: password of os
#
# Results:
#      An object of VDNetLib::Host::HostOperations package.
#
# Side effects:
#      None
#
########################################################################

sub new {
   my $class         = shift;
   my $hostIP        = shift;
   my $stafObj       = shift;
   my $vdnetSource   = shift;
   my $vmRepository  = shift;
   my $sharedStorage = shift;
   my $password      = shift;

   if (not defined $hostIP) {
      $vdLogger->Error("Host IP/name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $self = {
      hostIP => $hostIP,
      # Obtain Staf handle of the process from VDNetLib::Common::STAFHelper module
      stafHelper => $stafObj,
      userid     => "root",
      password   => $password,
      sshPassword => $password,
      vdnetSource => $vdnetSource,
      vmRepository => $vmRepository,
      sharedStorage => $sharedStorage,
      os => undef,
      _pyIdName => 'id_',
      _pyclass => 'vmware.kvm.kvm_facade.KVMFacade',
      _pyVersion => undef,
   };
   bless($self);


   #
   # Create a VDNetLib::Common::STAFHelper object with default if it not
   # provided in the input parameters.
   #
   if (not defined $self->{stafHelper}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::Common::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }
   if($self->{stafHelper}->CheckSTAF($hostIP) eq FAILURE) {
      $vdLogger->Error("STAF is not running on $hostIP\n");
      VDSetLastError("ETAF");
      return FAILURE;
   }
   my $hostType = $self->{stafHelper}->GetOS($self->{hostIP});
   if (not defined $hostType) {
      $vdLogger->Error("Unable to determine the OS type of KVM");
      VDSetLastError("ENODEF");
      return FAILURE;
   }
   $vdLogger->Debug("KVM's OS type is found to be: $hostType");
   $self->{os} = $hostType;
   my $inlinePyObj = $self->GetInlinePyObject();
   return $self;
}


########################################################################
#
# DiscoverPIF --
#     Method to discover physical nics on the KVM host
#
# Input:
#     nicsSpec: Reference to an array of hash with each hash containing following
#     keys:
#               interface : <eth0>
#
# Results:
#     Adapter object array for a successful operation;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub DiscoverPIF
{
   my $self     = shift;
   my $nicsSpec = shift;

   my @arrayOfVNicObjects;

   foreach my $element (@$nicsSpec) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("nicSpec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %args = %$element;
      # Create vdnet vnic object and store it in array of vnicobjects
      $args{controlIP}  = $self->{hostIP};
      $args{hostObj} = $self;
      my $vnicObj = VDNetLib::NetAdapter::Pnic::PIF->new(%args);
      if ($vnicObj eq "FAILURE") {
         $vdLogger->Error("Failed to initialize vnic obj on VM: $self->{vmx}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push @arrayOfVNicObjects, $vnicObj;
   }
   return \@arrayOfVNicObjects;
};


########################################################################
#
# Reboot --
#      Reboot KVM host
#
# Input:
#      None
#
# Results:
#      Returns "SUCCESS", if reboot successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub Reboot {
   my $self = shift;
   my $inlinePyObj = $self->GetInlinePyObject();
   my $result = undef;
   eval {
       $result = CallMethodWithKWArgs($inlinePyObj, 'reboot',
                                       {execution_type => 'cmd'});
   };
   if ($@) {
       $vdLogger->Error("Host Reboot failed for $self->{hostIP}:\nresult: " .
                        "$result \nexception:" . Dumper($@));
       return FAILURE;
   }
   if (FAILURE eq $self->DoFrameworkSetup()) {
      $vdLogger->Error("DoFrameworkSetup failed for $self->{hostIP}");
      return FAILURE;
   }
   $vdLogger->Debug("Host Reboot succeeded for $self->{hostIP}");
   return SUCCESS;
}

########################################################################
#
# CreateLinkedClone
#     Method to create a linked clone of the VM
#
# Input:
#     vmHash: hash containg vm specifications
#     vmIndex: zookeeper index of the VM
#     lockFileName: for locking the folder
#     uniqueID: uniqueID to use in the name of the VM
#     displayName: displayName to be used for the VM
#
# Results:
#     vmOps object in case of successful operation;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################
sub CreateLinkedClone
{
   my $self         = shift;
   my $vmHash       = shift;
   my $vmIndex      = shift;
   my $displayName  = shift;
   my $isLinkedClone = $Inline::Python::Boolean::true;

   return $self->CreateClone($vmHash, $vmIndex, $displayName, $isLinkedClone);
}

########################################################################
#
# CreateFullClone
#     Method to create a full clone of the VM
#
# Input:
#     vmHash: hash containg vm specifications
#     vmIndex: zookeeper index of the VM
#     lockFileName: for locking the folder
#     uniqueID: uniqueID to use in the name of the VM
#     displayName: displayName to be used for the VM
#
# Results:
#     vmOps object in case of successful operation;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################
sub CreateFullClone
{
   my $self         = shift;
   my $vmHash       = shift;
   my $vmIndex      = shift;
   my $displayName  = shift;
   my $isLinkedClone = $Inline::Python::Boolean::false;

   return $self->CreateClone($vmHash, $vmIndex, $displayName, $isLinkedClone);
}

########################################################################
#
# CreateClone
#     Method to create a clone of the VM on KVM
#
# Input:
#     vmHash: hash containg vm specifications
#     vmIndex: zookeeper index of the VM
#     lockFileName: for locking the folder
#     uniqueID: uniqueID to use in the name of the VM
#     displayName: displayName to be used for the VM
#     isLinkedClone: whether clone needs to be of linked or not
#
# Results:
#     vmOps object in case of successful operation;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub CreateClone
{
   my $self         = shift;
   my $vmHash       = shift;
   my $vmIndex      = shift;
   my $displayName  = shift;
   my $isLinkedClone = shift;
   my $command;
   my $result;
   my $vmTemplate = $vmHash->{template};
   my $hostIP     = $self->{hostIP};

   # Find the VM location
   my $dsPath = VDNET_LOCAL_MOUNTPOINT;

   $vdLogger->Info("Creating full clone for VM: $vmIndex,  " .
                   "with displayName $displayName will take few minutes...");
   #
   # $vdnetMountPoint might have spaces and ( ), so escaping them with \
   #
   $dsPath =~ s/ /\\ /;
   $dsPath =~ s/\(/\\(/;
   $dsPath =~ s/\)/\\)/;

   # This should work for both vdtest and dev-nas.
   # We can pick VMs from any VM repo
   # First try picks it from vdtest as we store VMs under folders
   # Second try is for dev-nas, which does not store under folder
   # and has lot of junk thus we should keep maxdepth as 1
   $command = "cd $dsPath; find . -maxdepth 1 -name $vmTemplate";
   $vdLogger->Trace("Finding src VM using command:" . $command);
   $result  = $self->{stafHelper}->STAFSyncProcess($hostIP, $command, "60");
   if ($result->{stdout} !~ /$vmTemplate/) {
      $command = "cd $dsPath; find . -maxdepth 1 -iname $vmTemplate" .  ".img";
      $vdLogger->Trace("Try 2 with command:" . $command);
      $result  = $self->{stafHelper}->STAFSyncProcess($hostIP, $command, "60");
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to find the given VM: $vmTemplate ".
                          "under $dsPath on $hostIP.");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   my $path = $result->{stdout};
   $path =~ s/^\.//; # remove dot only in the beginning not everywhere
   $path =~ s/\n//g;
   if ($path eq "") {
      $vdLogger->Error("Failed to find the given VM: $vmTemplate ".
                       "under $dsPath on $hostIP.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $src = $dsPath . $path;
   $vdLogger->Trace("Source VM is:" . $dsPath . $path);

   # Check if the source VM directory exists on the host
   my $srcDir = $self->{stafHelper}->DirExists($hostIP, $src);
   if ((not defined  $srcDir) || ($srcDir eq FAILURE)) {
      $vdLogger->Error("Failed to get source VM path $src on $hostIP".
                       Dumper($result));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $srcDir = VDNetLib::Common::Utilities::ReadLink($src, $hostIP,
                                                   $self->{stafHelper});

   if ($srcDir eq FAILURE) {
      $vdLogger->Info("Failed to find symlink of $srcDir on $hostIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Trace("Source VM directory is: $srcDir");

   my $runtimeDir = KVM_RUNTIME_VM_DIR;
   # Check if the source VM directory exists on the host
   my $dstDir = $self->{stafHelper}->DirExists($hostIP, $runtimeDir);
   if ($dstDir eq 0) {
      my $command = "mkdir -p " . $runtimeDir;
      $vdLogger->Trace("Running command $command for creating $runtimeDir");
      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
      # Process the result
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $command");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }
   }

   #
   # Get the absolute path to the vmx which would finally be registered
   # and used for running the workloads
   #
   $vmTemplate = $vmTemplate . ".img";
   my $lsCommand = "ls $runtimeDir/" . $vmTemplate;
   $lsCommand = "START SHELL COMMAND " .
              STAF::WrapData($lsCommand) .
              " WAIT RETURNSTDOUT STDERRTOSTDOUT";
   my ($ret, $data) = $self->{stafHelper}->runStafCmd(
        $hostIP, 'PROCESS', $lsCommand);

   if (($ret eq FAILURE) || ($data eq "") || ($data =~ /No such/i)) {
      # Handling both vdtest and dev-nas
      # For vdtest make a symlink of files with *.img under that folder
      # For dev-nas we already have entire path till .img thus use as it is
      if ($srcDir !~ /\.img/) {
         $srcDir = $srcDir . '/*.img';
      }
      my $dstDir = "$runtimeDir/$vmTemplate";
      my $lnCommand = "ln -s $srcDir $dstDir";
      $vdLogger->Trace("Running command $lnCommand to have the first ".
                       "$vmTemplate img in $runtimeDir");
      $result  = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                      $lnCommand);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Warn("Checking if another thread has created a symlink " .
                         "to the $vmTemplate in $runtimeDir");
         ($ret, $data) = $self->{stafHelper}->runStafCmd(
            $hostIP, 'PROCESS', $lsCommand);
         if (($ret eq FAILURE) || ($data eq "") || ($data =~ /No such/i)) {
            $vdLogger->Error("Failed to symlink VM: $vmTemplate ".
                             "from $dsPath to $dstDir on $hostIP using " .
                             "'$lnCommand'.\nstderr: $result->{stderr}");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
   }

   # Create a VMOperations object
   my $vmOpsObj = VDNetLib::VM::KVMOperations->new($self);
   if ($vmOpsObj eq FAILURE) {
      $vdLogger->Error("Failed to create VMOperations object for $displayName ".
                       "on $self->{hostIP}");
      return FAILURE;
   }
   #TODO: Change to hash/pydict
   my $pyVMObj;
   eval {
      my $inlineVMObj = $vmOpsObj->GetInlinePyObject();
      $pyVMObj = CallMethodWithKWArgs($inlineVMObj, 'create',
                                      {template => $vmTemplate,
                                       name => $displayName,
                                       linked_clone => $isLinkedClone});
   };
   if ($@ || $pyVMObj eq FAILURE || not defined $pyVMObj->{name}) {
      $vdLogger->Error("Failed to clone vm on $self->{hostIP} for ".
                       "$displayName" . Dumper($@));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # Store VM's unique name for log collection.
   if (not defined $pyVMObj->{unique_name}) {
      $vdLogger->Error("VM $pyVMObj->{name} does not have a unique name " .
                       "attr defined. Log Colection will fail !");
      VDSetLastError("ENODEF");
      return FAILURE;
   }
   $vdLogger->Info("Created Object for VM $pyVMObj->{name} on host: $self->{hostIP}");
   $vmOpsObj->{vmName} = $displayName;
   $vmOpsObj->{uniqueName} = $pyVMObj->{unique_name};
   $vmOpsObj->{vmx} = $pyVMObj->{image};
   return $vmOpsObj;
}


########################################################################
#
# CheckForPatternInVMX
#     Method to be overridden as its a No-OP for KVM
#
# Input:
#
# Results:
#     string
#
########################################################################


sub CheckForPatternInVMX
{
   return "NOT-IMPLEMENTED-pattern";
}


########################################################################
#
# ReturnVMXPathIfVMExists
#     Method to be overridden as its a No-OP for KVM
#
# Input:
#
# Results:
#     string
#
########################################################################

sub ReturnVMXPathIfVMExists
{
   return FAILURE;
};


########################################################################
#
# GetVMDisplayName
#     Method to be overridden as its a No-OP for KVM
#
# Input:
#
# Results:
#     string
#
########################################################################

sub GetVMDisplayName
{
   my $self      =  shift;
   return "NOT-IMPLEMENTED-VM-";
}



########################################################################
#
# ConfigureFirewall--
#     Method to configure firewall on the given host
#
# Input:
#     sshHost : reference to VDNetLib::Common::SshHost object (Required)
#     action  : enable/disable (Optional, default is enable)
#     ruleset : firewall rules (Optional) #TODO: fix this
#
# Results:
#     SUCCESS, if firewall is configured correctly;
#     FAILURE, in case of any error;
#
# Side effects:
#     May impact access to the host completely or specific ports
#
########################################################################

sub ConfigureFirewall
{
   my $self = shift;
   my $ip = $self->{hostIP};
   my $os = $self->{os};
   my $service;
   my $action = "stop";
   my $result;
   return SUCCESS;

   # Stop the iptables service
   $service = "iptables";
   $result = VDNetLib::Common::Utilities::ConfigureLinuxService($ip,
                           $os, $service, $action, $self->{stafHelper});
   if ($result eq FAILURE) {
      $vdLogger->Debug("Could not disable iptables service on $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Stop the ip6tables service
   $service = "ip6tables";
   $result = VDNetLib::Common::Utilities::ConfigureLinuxService($ip,
                           $os, $service, $action, $self->{stafHelper});
   if ($result eq FAILURE) {
      $vdLogger->Error("Could not disable ip6tables service on $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# CreateDiscoverBridge --
#      This method creates a network/bridge with a given bridge interface
#
# Input:
#      arrayOfSpecs: array of spec for network
#
# Results:
#      Returns array of of vss objects if created successfully
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub CreateDiscoverBridge
{
   my $self     = shift;
   my $nicsSpec = shift;

   my @arrayOfBridgeObjects;

   my $inlineHostObj = $self->GetInlinePyObject();
   foreach my $element (@$nicsSpec) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("nicSpec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %args = %$element;
      # Create vdnet bridge object and store it in array of bridgeobjects
      $args{controlIP}  = $self->{hostIP};
      $args{hostObj} = $self;
      if (defined $element->{name}) {
         $args{name}  = $element->{name};
      } elsif (defined $element->{uplink}) {
         $args{name}  = "br" . $element->{uplink}->{interface};
      } else {
         $vdLogger->Warn("Not sure what bridge to create");
      }
      my $pyBridgeObj;
      my $bridgeObj = VDNetLib::Switch::Bridge::Bridge->new(%args);
      if ($bridgeObj eq "FAILURE") {
         $vdLogger->Error("Failed to initialize bridge obj on host: $self->{hostIP}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # Remove perl objects and unneccessary arguments not required by the
      # python layer.
      delete $args{'hostObj'};
      delete $args{'controlIP'};
      eval {
         my $inlineBridgeObj = $bridgeObj->GetInlinePyObject();
         $pyBridgeObj = CallMethodWithKWArgs(
            $inlineBridgeObj, 'create', \%args);
      };
      if ($@ || not defined $pyBridgeObj->{name}) {
         $vdLogger->Error("Failed to create_bridge on $self->{hostIP} for " .
                          Dumper(%args));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $bridgeObj->{$bridgeObj->{_pyIdName}} = $pyBridgeObj->{name};
      $vdLogger->Info("Created Object for Bridge $pyBridgeObj->{name} on ".
                      "host: $self->{hostIP}");
      push @arrayOfBridgeObjects, $bridgeObj;
   }
   return \@arrayOfBridgeObjects;
};

########################################################################
#
# DeleteBridge--
#     Method to delete bridge components.
#
# Input:
#     arrayOfPerlObjects: reference to array of perl objects on which
#     delete is called
#
# Results:
#     SUCCESS, if bridges are removed successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     Removed bridges cannot be accessed again
#
########################################################################

sub DeleteBridge
{
   my $self             = shift;
   my $arrayOfPerlObjects = shift;
   if (not defined $arrayOfPerlObjects) {
      $vdLogger->Error("No bridges provided for deletion");
      return FAILURE;
   }
   foreach my $perlObj (@$arrayOfPerlObjects) {
      my $pyObj;
      my $result = undef;
      my $packageName = blessed $perlObj;
      $pyObj = $perlObj->GetInlinePyObject();
      if ($pyObj eq "FAILURE") {
         $vdLogger->Error("Failed to get inline python object for " .
                          "$packageName");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $vdLogger->Debug("We got pyObj for bridge object, now executing delete ".
                       "method");
      if (not defined $perlObj->{$perlObj->{_pyIdName}}) {
         $vdLogger->Error("No $perlObj->{_pyIdName} for bridge is set");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      eval {
         $result = CallMethodWithKWArgs($pyObj, 'delete',
                                        {'name' => $perlObj->{$perlObj->{_pyIdName}}});
      };
      if ($@) {
         $vdLogger->Error("Exception thrown while executing bridge delete " .
                          " $packageName:\n". $@);
         return FAILURE;
      }
   }
   return SUCCESS;
}


#########################################################################
#
# GetHostSetupScript
#      Path to the host setup script
#
# Input:
#      None
#
# Results:
#      Returns path
#
# Side effects:
#      None.
#
#########################################################################

sub GetHostSetupScript
{
   return HOST_SETUP_SCRIPT;
}

#########################################################################
#
# InstallTestCerts
#      overridden method
#
# Input:
#      None
#
# Results:
#      SUCCESS
#
# Side effects:
#      None.
#
#########################################################################

sub InstallTestCerts
{
   return SUCCESS;
}


#########################################################################
#
# DoFrameworkSetup
#      Do setup on this host in a specific order
#
# Input:
#      None
#
# Results:
#      SUCCESS
#      FAILURE in case of any error
#
# Side effects:
#      None.
#
#########################################################################

sub DoFrameworkSetup
{
   my $self = shift;
   my $setupSteps = shift;

   if (FAILURE eq $self->ConfigureHostForVDNet()) {
      $vdLogger->Error("ConfigureHostForVDNet failed for $self->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $self->{hostType} = HYPERVISOR . $self->{os};
   my $inlineObj = $self->GetInlinePyObject();
   if (!$inlineObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Calling setup_kvm for $self->{hostIP}");
   eval {
      my $sshInlinePyObj = CreateInlinePythonObject(
         'vmware.common.connections.ssh_connection.SSHConnection',
         $self->{hostIP},
         $self->{userid},
         $self->{password});
      $sshInlinePyObj->create_connection();
      $sshInlinePyObj->enable_passwordless_access();
      $vdLogger->Info("Enabled passwordless access for $self->{hostIP}");
      $sshInlinePyObj->close();
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating inline obj of " .
                       "vmware.common.connections.ssh_connection.SSHConnection:"
                       . $@);
      return FAILURE;
   }
   return SUCCESS;
}

#########################################################################
#
# GetInlinePyObject
#      Returns inline python object that can be used to invoke methods from
#      the python layer.
#
# Input:
#      None
#
# Results:
#      Inline python object.
#      FAILURE in case of any error
#
# Side effects:
#      None.
#
#########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $self->{hostIP},
                                              $self->{userid},
                                              $self->{password},
                                              $self->{_pyVersion});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (not defined $self->{_pyVersion}) {
       # This would store the version related information gathered from the
       # instance (runtime) as its not provided by the deployment path
       $self->{_pyVersion} = $inlinePyObj->get_version();
   }
   return $inlinePyObj;
}


################################################################################
#
# GetAdapterInfo-
#    Gets the information for the specified interface.
#
# Input -
#    NIC name.
#
# Results -
#  Returns a hash containing mac, mtu, ipv4 and netmask info.
#  Returns FAILURE if MTU is get
#
# Side effects -
#  None
#
################################################################################

sub GetAdapterInfo
{
   my $self = shift;
   my %args = @_;
   my $deviceId = $args{deviceId};
   if (not defined $deviceId) {
      $vdLogger->Error("Interface name not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $result =  $self->get_adapter_info({execution_type => 'cmd'});
   my $adapter_info = $result->{'table'};
   foreach my $record (@$adapter_info) {
       if ($record->{'dev'} eq $deviceId) {
           $record->{ipv4} = delete $record->{ip};
           if (not defined $record->{ipv4}) {
               $vdLogger->Warn("IP address for $deviceId interface is not set!");
           }
           return $record;
       }
   }
   VDSetLastError("ENODEF");
   $vdLogger->Error("Failed to get adapter info for $deviceId interface");
   return FAILURE;
}

#######################################################################
#
# ReadComponent--
#     Method to read attributes of the host object.
#
# Input:
#     args: List of arguments that need to be read from the object.
#
# Results:
#     Result hash containing the response.
#
# Side effects:
#     None
#
########################################################################

sub ReadComponent
{
   my $self = shift;
   my $args = shift;
   my $result = {};
   my $resultHash = {
      'status' => undef,
      'response' => undef,
      'error' => undef,
      'reason' => undef,
   };
   my $readableAttributes = {'defaultgateway' => 'GetDefaultGateway'};
   foreach my $key (keys %$args) {
      if (grep {$_ eq $key} (keys %$readableAttributes)) {
         $key = lc($key);
         my $method = $readableAttributes->{$key};
         my $attr = $self->$method();
         if ((defined $attr) and ($attr eq FAILURE)) {
             $vdLogger->Error("Failed to read attribute $key from host");
             $resultHash->{'status'} = FAILURE;
             $resultHash->{'error'} = "Failed to read attribute $key from host";
             return $resultHash;
         }
         $result->{$key} = $attr;
      } else {
         $vdLogger->Error("Following attribute can not be read off of the " .
                          "host object: " . Dumper($key));
         $resultHash->{'status'} = FAILURE;
         $resultHash->{'error'} = "Attempted to read an invalid attribute";
         $resultHash->{'reason'} = "$key can not be read off a host object";
         return $resultHash;
      }
   }
   $resultHash->{'status'} = SUCCESS;
   $resultHash->{'response'} = $result;
   return $resultHash;
}

###############################################################################
#
# GetDefaultGateway --
#     Method to get the default gateway for the host.
#
# Input:
#     None
#
# Results:
#     On Success returns the ip of the default gateway
#     FAILURE otherwise.
#
# Side effects:
#     None
#
################################################################################

sub GetDefaultGateway
{
   my $self = shift;
   my $gatewayCommand = "route -n | grep \"^0.0.0.0\" | awk '{print \$2;}'";
   my $result = $self->{stafHelper}->STAFSyncProcess(
         $self->{hostIP}, $gatewayCommand, undef, undef, 1);
   if ($result eq FAILURE) {
       $vdLogger->Error("Failed to get the default gateway.");
       return FAILURE;
   }
   if ($result->{stdout} eq "") {
       $vdLogger->Warn("No default gateway is set on host");
       return FAILURE;
   }
   my @gateways = split(/\n/, $result->{stdout});
   $vdLogger->Trace("Default gateway(s) on the host:" . Dumper(@gateways));
   if (@gateways > 1) {
       $vdLogger->Warn("Multiple default gateways found on the host, " .
                       "would use only one:" . $gateways[0]);
   }
   return $gateways[0];
}

###############################################################################
#
# ConfigureDefaultGateway--
#     Method to add/delete default gateway on the host.
#
# Input:
#     operation: add/delete
#     gateway: IP address of the gateway. If string 'different' is passed then
#        the a default gateway different than the originally set default
#        gateway is added. If string 'any' is passed then all default gateways
#        will be removed.
#
# Results:
#     SUCCESS on successful addition/deletion of gateway.
#     FAILURE otherwise.
#
# Side effects:
#     None
#
################################################################################

sub ConfigureDefaultGateway
{
   my $self = shift;
   my $args = shift;
   if (not defined $args or ref($args ne 'HASH')) {
      $vdLogger->Error('Invalid arguments received for defaultgateway key, ' .
                       'expected a hash, got: ' . Dumper($args));
      return FAILURE;
   }
   if (not defined $args->{operation} or
       $args->{operation} !~ m/add|delete/i) {
       $vdLogger->Error("Invalid operation specified: " .
                        $args->{operation});
       return FAILURE;
   }
   if (not defined $args->{gateway}) {
       $vdLogger->Error("Gateway to $args->{operation} " .
                        "is not defined");
       return FAILURE;
   }
   my $op = lc($args->{operation});
   my $gateway = $args->{gateway};
   if (lc($gateway) eq 'different') {
      if ($op eq 'delete') {
         $vdLogger->Error('Invalid operation and gateway value: ' .
                          Dumper($args));
         return FAILURE;
      }
      my $existingGateway = $self->GetDefaultGateway();
      if ((not defined $existingGateway) or ($existingGateway eq FAILURE)) {
          $vdLogger->Error("No gateway was found on the host, can not " .
                           "determine the subnet in which the new gateway " .
                           "needs to be configured in.");
          return FAILURE;
      }
      my @octets = split(/\./, $existingGateway);
      my $lastOctet = @octets[scalar(@octets) - 1];
      $lastOctet = (int($lastOctet) + 1) % 255;
      splice(@octets, -1, 1, $lastOctet);
      $gateway = join('.', @octets);
   }
   if (lc($gateway) eq 'any') {
      if ($op eq 'add') {
         $vdLogger->Error('Invalid operation and gateway value: ' .
                          Dumper($args));
         return FAILURE;
      }
      while ((defined $self->GetDefaultGateway()) and
             ($self->GetDefaultGateway() ne FAILURE)) {
          my $gateway = $self->GetDefaultGateway();
          my $remoteMethodArgs = "$op,0.0.0.0,undef,$gateway";
          my $return = ExecuteRemoteMethod(
               $self->{hostIP}, "ConfigureRoute", $remoteMethodArgs,
               REMOTE_METHOD_TIMEOUT);
          if ((not defined $return) or ($return eq FAILURE)) {
              $vdLogger->Error("Failed to delete default gateway $gateway: " .
                               Dumper($return));
             return FAILURE;
          }
      }
      return SUCCESS;
   }
   my $remoteMethodArgs = "$op,0.0.0.0,undef,$gateway";
   my $return = ExecuteRemoteMethod(
        $self->{hostIP}, "ConfigureRoute", $remoteMethodArgs,
        REMOTE_METHOD_TIMEOUT);
   if ((not defined $return) or ($return eq FAILURE)) {
       $vdLogger->Error("Failed to $op default gateway: " . Dumper($return));
       $vdLogger->Error("If adding a gateway, make sure that IP is " .
                        "accessible via an interface on the host");
       return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetKVMLog --
#     Method to get KVM logs (Tech support Bundle)
#
# Input:
#     LogDir : Log directory to which KVM logs have to be copied
#              on master controller.
#
# Results:
#     "SUCCESS", if all the logs get copied to the specific directory
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetKVMLog
{
   my $self = shift;
   my $logDir = shift;
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Destination dir for storing KVM logs not provided");
      VDSetLastError("ENODEF");
      return FAILURE;
   }
   my $componentPyObj = $self->GetInlinePyObject();
   if ($componentPyObj eq FAILURE) {
      $vdLogger->Error("Failed to get inline python object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $args = {execution_type => 'cmd', logdir => $logDir};
   $result = CallMethodWithKWArgs(
           $componentPyObj, 'collect_logs', $args);
   if (not defined $result || $result ne SUCCESS) {
       VDSetLastError("EOPFAILED");
       $vdLogger->Error("Failed to execute python method: collect_logs");
       return FAILURE;
   }
   return $result;
}


#########################################################################
#  GetPidCmd ---
#      This method returns the command that can be used to get the PIDs
#      and process names from the host.
#
# Input:
#      None
#
# Results:
#      Returns the command that can be used to get the PIDs and process
#      names  from the host.
#
# Side effects:
#      None
#########################################################################

sub GetPidCmd
{
    return "ps -ef | awk \'{print \$2, \$8}\'";
}

1;
