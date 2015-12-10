###############################################################################
#  Copyright (C) 2009 VMware, Inc.                                            #
#  All Rights Reserved                                                        #
###############################################################################

package VDNetLib::VM::VMOperations;
use strict;
use warnings;

# Load modules
use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/VIX";
use Getopt::Long;
use Text::ParseWords;
use Data::Dumper;
use Scalar::Util qw(blessed reftype);

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession $STAF_DEFAULT_PORT);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);
# For doing hosted operations remotely
use VDNetLib::Common::RemoteAgent_Storage;
use VDNetLib::TestData::TestConstants;
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJavaClass);
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use VDNetLib::TestData::TestConstants;
# Default parameters to use as application doesn't provide these parameters.
use constant MY_APIVERSION => -1;
use constant MY_USERNAME   => "root";
use constant MY_PASSWORD   => "ca\$hc0w";
use constant MY_PORT       => 902;

use constant VMFS_BASE_PATH => "/vmfs/volumes/";
use constant VMWARE_TOOLS_BASE_PATH => "/usr/lib/vmware/";
use constant VMWARE_TOOLS_DIR => "/productLocker/vmtools/";
use constant GUESTIP_SLEEPTIME => 5;
use constant GUEST_BOOTTIME => 60;

use XML::Simple;

# Required for WaitForVDNet method
use constant WIN_SCRIPTS_PATH => 'M:\scripts';
use constant LINUX_SCRIPTS_PATH => '/automation/scripts';

use constant VAR_LOG_MESSAGES => "/var/log/messages";
use constant GUEST_LOG_DIR => "/var/log";
use constant TMP_VMTOOLS_DIR => "/tmp/vmtools";
# powershell exe
use constant POWER_SCRIPT_EXE =>
   'c:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe';
use constant TASKLIST_EXE =>
   'c:\Windows\system32\tasklist.exe | find /N "powershell"';
eval "require VDNetLib::DHCPServer::DHCPServer";
if($@) { print("Cannot load DHCPserver module"); }
eval "require VDNetLib::TORGateway::TORGateway";
if($@) { print("Cannot load TORGateway module"); }
eval "require VDNetLib::Router::LinuxRouter";
if($@) { print("Cannot load Linux Router module"); }

# Variables used by specific functions
my %param;
my $hostsReadyForToolUpgrade = [];

########################################################################
# new --
#
# Constructor which takes care of object creation depending on the hostType
# key in param hash.
# If hostType is esx it invokes ESXVMOperations and HostedVMOperations if its
# linux or windows
# It also takes care of invoking remote agent which is used for executing
# Hosted VMOperations remotely
#
# Input:
#       vmx          vmxpath of the vm
#       host Type    esx or windows or linux
#       host IP      IP address of the remote machine
#       VM's IP      (Optional parameter) IP address of VM
#
# Results:
#       child Object of appropriate type.
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my $proto	   = shift;
   my $class	   = ref($proto) || $proto;
   my $self	      = {};
   my $hostObj	   = shift;
   my $vmx	      = shift;
   my $displayName = shift;
   my $vmType      = shift || "vm";
   ## Revisit above line
   $vdLogger->Debug("TODO (Aditya) : 1363965");
   my $useVIX	   = shift || 0;
   my $useVC	   = shift;

   my $param   = {};
   $param->{'vmx'}	   = $vmx;
   $param->{'host'}	   = $hostObj->{hostIP};
   $param->{'hostType'}	   = $hostObj->{hostType} || "vmkernel"; #TODOver2
   $param->{'hostObj'}	   = $hostObj;
   $param->{'displayName'} = $displayName;


   # The following line can be uncommented for debugging purpose.
   # It Prints the param hash containing lot of information. It
   # also has some of the testbed object's information.
   #$vdLogger->Info("Dumping param in Vmoperations: ". Dumper($param));

   if (not defined $param->{'vmx'}) {
      $vdLogger->Error("New on VMOperations called with hash without key ".
                     "VMXPATH. Exiting...");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $param->{'hostType'}) {
      $vdLogger->Error("New on VMOperations called with hash without key ".
                     "hostype. Exiting...");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $param->{'host'}) {
      $vdLogger->Error("New on VMOperations called with hash without key ".
                     "host. Exiting...");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my %def_attrs = (

      # Setting default values. They can be overridden by child classes.
      # They are required by TestBase.pm of foundary qa src.
      _apiVersion => MY_APIVERSION,
      _port       => MY_PORT,
      _username   => MY_USERNAME,
      _password   => MY_PASSWORD,

   # Reading values from testbed Object passed by VdNet and setting it to
   # VMOperations class package.
      _productType => undef,
      _host        => undef,
      _vmxPath     => undef,
      _vmIP        => undef,
   );
   $def_attrs{'_host'}     = $param->{host};
   $def_attrs{'_vmxPath'}  = $param->{vmx};
   $def_attrs{'vmx'}  = $param->{vmx}; # duplicate to be compatible with child
                                         # classes
   $def_attrs{'_vmIP'}        = $param->{ip};
   $def_attrs{'_hostType'}    = $param->{hostType};
   $def_attrs{'_hostObj'}     = $param->{hostObj};
   $def_attrs{'_displayName'} = $param->{displayName};

   if (defined $useVC) {
      $def_attrs{'_vc'}       = $useVC->{vcaddr};
      $def_attrs{'_vcUser'}   = $useVC->{'user'};
      $def_attrs{'_vcPasswd'} = $useVC->{'passwd'};
      $def_attrs{'_useVC'}    = 1;
   }
   $def_attrs{'hostObj'} = $param->{hostObj};
   if ((defined $vmType) && ($vmType =~ /appliance/i)) {
      $def_attrs{'vmType'} = $vmType;
   }

   my @args;
   @args = ( \%def_attrs );
   my $childObjType;
   if ( lc( $param->{hostType} ) =~ /esx|vmkernel/i ) {
      if ($useVIX) {
         $vdLogger->Debug("Using VIX API: ESXVMOperations.pm for VM Ops");
         # Using VIX APIs
         $childObjType = "VDNetLib::VM::ESXVMOperations";
      } else {
         # Using STAF SDK
         $vdLogger->Debug("Using STAF SDK: ESXSTAFVMOperations.pm for VM Ops");
         # check the version of staf sdk installed
         my $version = VDNetLib::Common::GlobalConfig::DEFAULTSTAFSDKBRANCH;
         if ($version =~ /vc4x-testware/i) {
            $vdLogger->Debug("Using staf sdk vc4x-testware");
            $childObjType = "VDNetLib::VM::ESXSTAF4xVMOperations";
         } else {
            $vdLogger->Debug("Using staf sdk vc5x-testware");
            $childObjType = "VDNetLib::VM::ESXSTAFVMOperations";
         }
      }
      $def_attrs{'_productType'} = "esx";
   } elsif ( lc( $param->{hostType} ) eq "esx35" ) {
      $childObjType = "VDNetLib::VM::ESX35VMOperations";
      $def_attrs{'_productType'} = "esx";
   } elsif ( lc( $param->{host} ) eq "localhost"
      || lc( $param->{host} ) eq "127.0.0.1" ) {
      $def_attrs{'_productType'} = "workstation";
      $childObjType = "VDNetLib::VM::HostedVMOperations";
   } elsif ( $param->{hostType}  =~ /(darwin|mac)/i ) {
      $def_attrs{'_productType'} = "fusion";
      $childObjType = "VDNetLib::VM::HostedVMRunOperations";
   } elsif ( $param->{hostType} =~ /(^linux$|win)/i ) {
      $def_attrs{'_productType'} = "ws";
      $childObjType = "VDNetLib::VM::HostedVMRunOperations";
   } elsif ( $param->{hostType} =~ /kvm/i ) {
      $def_attrs{'_productType'} = "kvm";
      $childObjType = "VDNetLib::VM::KVMOperations";
   } else {
      $childObjType = "VDNetLib::Common::RemoteAgent_Storage";
      my $remoteIp      = $param->{host};
      my $copyOfTestbed = $param;
      $copyOfTestbed->{'host'} = "localhost";
      $def_attrs{'_productType'} = "workstation";
      my $ref_def_attrs = \%def_attrs;

      @args = ( remoteIp => $remoteIp, pkgArgs => [$copyOfTestbed] );
   }
   if ( defined $childObjType ) {
      # Load the required module dynamically
      eval "require $childObjType";
      if ($@) {
         $vdLogger->Error("unable to load module $childObjType:$@");
         VDSetLastError("EOPFAILED");
         return "FAIL";
      }
         $self = $childObjType->new(@args);
      if ($self eq FAILURE) {
         $vdLogger->Error("Failed to create $childObjType");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      foreach my $key ( keys %def_attrs ) {
         $self->{$key} = $def_attrs{$key} if not $self->{$key};
      }
        bless $self, $childObjType;
   } else {
      $vdLogger->Error("Not able to create child object from ".
                       "VMOperations parent. ");
      VDSetLastError("EFAILED");
        bless $self, $class;
   }

   $self->{stafHandle} = $self->{stafHelper};

   # Flag to indicate if this VM is powered on by vdNet or not.
   $self->{initialState}   = "on"; # This could be on/off/template
   $self->{changeName}	   = 0;

   #
   # lockFileName and uniqueID stores the access information related
   # to the lock file created for the linked clone VM's.
   #
   $self->{lockFileName}   = undef;
   $self->{uniqueID}	   = undef;

# TODO: delete these lines if $self->{stafHandle} = undef is not requred.
#   if ( ( $self->{stafHandle} = new VDNetLib::Common::STAFHelper() ) eq FAILURE ) {
#      $vdLogger->Error("Is Staf Running on localhost? Staf Handle not ".
#                       "created");
#      VDSetLastError("ESTAF");
#      return FAILURE;
#   }
   if($vmType =~ /dhcpserver/i) {
      $self = VDNetLib::DHCPServer::DHCPServer->new($self, $hostObj, $vmx);
   } elsif($vmType =~ /torgateway/i) {
      $self = VDNetLib::TORGateway::TORGateway->new($self, $hostObj, $vmx);
   } elsif($vmType =~ /linuxrouter/i) {
      $self = VDNetLib::Router::LinuxRouter->new($self, $hostObj, $vmx);
   }
   return $self;
 }


########################################################################
#
# VMOpsUpgradeTools --
#     Method to upgrade the tools inside the VM. It check if the VM
#     has a CDROM attached to it. If not then it attaches it before
#     trying to upgrade tools.
#     Works for both staf 4x and staf 5x.
#
# Input:
#     None (since vmx is already defined as class attribute)
#
# Results:
#     "SUCCESS", if the tools is successfully upgraded
#     "FAILURE", in case of any error.
#
# Side effects:
#     The tools upgrade can fail due to various reasons not captured
#     in automation yet. vmware.log can help a log in debugging for
#     tool upgrade failure issues.
#
########################################################################

sub VMOpsUpgradeTools
{
   my $self = shift;

   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $vmxPath = $self->{'_vmxPath'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   my $osType = $self->{stafHelper}->GetOS($self->{vmIP});
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $self->{vmIP}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   $vdLogger->Info("Upgrading VMware Tools in $vmName. Might take time ...");

   my $cmd;
   $cmd = "UPGRADETOOLS ANCHOR $anchor VM $vmName WAITFORTOOLS";

   #
   # If the OS is linux and kernel is greater than 2.6.32-rc5 then it
   # will have inbox vmxnet3 driver. That is why we pass installeroptions
   # to clobber inboxed vmxnet3 driver and replace it with vmxnet3
   # from this vmware tools package.
   #
   if ($osType =~ /lin/i) {
      $cmd = $cmd . " INSTALLEROPTIONS --clobber-kernel-modules=vmxnet3";
   }

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   #
   # Under heavily loaded systems or basic nimbus/nested VM configurations,
   # tools upgrade hits timeout while waiting for vmware tools service to
   # restart after upgrade. RC 7078 is thrown in such cases, ignoring that
   # failure until alternative solutions suggested in PR738761 is implemented.
   #
   if (($stafResult->{rc} != $STAF::kOk) &&
       ($stafResult->{rc} != 7078)) {
      $vdLogger->Error("Unable to upgrade VMware Tools in $vmName on ".
                       "$esxHost" . Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# VMOpsUnmountToolsInstaller--
#     Method to cancel/unmount VMware tools installer
#
# Input:
#     None
#
# Results:
#     SUCCESS, if VMware tools upgrade is cancelled successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     This will cancel tools upgrade.
#
########################################################################

sub VMOpsUnmountToolsInstaller
{
   my $self = shift;

   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   $vdLogger->Info("Unmounting tools installer in $vmName");

   my $cmd;
   $cmd = "UNMOUNTTOOLSINSTALLER ANCHOR $anchor VM $vmName";

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if ($stafResult->{rc} != $STAF::kOk) {
      $vdLogger->Error("Unable to unmount tools installer in $vmName on ".
                       "$esxHost" . Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# VMOpsAddRemoveVirtualDevice --
#     Method to attach or remove a virtual device to/from a powered off VM.
#     Supported devices by this method are 'FLOPPY DRIVE' or
#    'CD/DVD DRIVE' or 'Serial port' or 'Parallel port'
#     Works on both STAF 4x and STAF 5x.
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

   if((not defined $task) || (not defined $deviceType)) {
      $vdLogger->Error("deviceName or task misssing in ".
                       "VMOpsAddRemoveVirtualDevice");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Checking for supported values
   if($task !~ /(add|remove)/i ||
      $deviceType !~ /(floppy|serial|parallel|^cd)/i ) {
      $vdLogger->Error("Unsupported Device:$deviceType or Task:$task");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   # Check if CD ROM is connected. If not then
   # Check the state of the VM. If running then power it down.
   my $result = $self->VMOpsGetPowerState();
   if ($result eq "FAILURE" || $result->{rc} != $STAF::kOk) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $initPowerState = $result->{result};

   # Check the state of the VM. If running then power it down.
   if ($result->{result} !~ /poweredoff/i) {
      $vdLogger->Info("Powering off VM $vmName to $task Virtual CDROM");
      $result =  $self->VMOpsPowerOff();
     if ($result eq FAILURE) {
        $vdLogger->Error("Failed to power off VM $vmName");
        VDSetLastError(VDGetLastError());
        return FAILURE;
     }
   }

   my $cmd;
   $cmd = "ADD" if $task =~ /add/i;
   $cmd = "RM"  if $task =~ /remove/i;

   # Supported devices by this method are
   # 'FLOPPY DRIVE' or 'CD/DVD DRIVE' or 'Serial port' or 'Parallel port'
   $cmd = $cmd . "VIRTUALFLOPPYDRIVE" if $deviceType =~ /floppy/i;
   $cmd = $cmd . "VIRTUALCDROM"       if $deviceType =~ /^cd/i;
   $cmd = $cmd . "SERIALPORT"         if $deviceType =~ /serial/i;
   $cmd = $cmd . "PARALLELPORT"       if $deviceType =~ /parallel/i;

   $cmd = $cmd . " ANCHOR $anchor VM $vmName";

   if((defined $deviceName) && ($task =~ /remove/i) &&
      ($deviceType !~ /^cd/i)){
      # For remove operation:
      # There is an interesting distinction between removing cdrom device
      # and other types of devices. When a CD/DVD drive 1 is removed the
      # CD DVD drive 2 is renamed to 1, thus one can make consecutive
      # calls to this method for removing cdrom without passing name of
      # device. This is related to some master slave concept in CDROM.
      # Thus we dont pass the name of CD ROM and let the remove call
      # take care of master slaves.
      # But for other devices if one do not pass the name of device
      # it will remove device 1 but subsequent calls won't remove
      # 2, 3 ... device unless one passes the name of device as well.
      if($deviceName !~ /(floppy drive|serial port|parallel port)/i ) {
         $vdLogger->Error("Unsupported DeviceName:$deviceName");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $cmd = $cmd . " DEVICENAME \"$deviceName\"";
   }

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if ($stafResult->{rc} == 7054) {
      $vdLogger->Error("Either device does not exists or ".
                       "device Name is incorrect/missing");
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to $task $deviceType to power off $vmName");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   # We bring the VM back in the same state as it was before
   # after adding/removing the virtual CDROM.
   if ($initPowerState =~ /poweredon/i) {
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
      $vdLogger->Info("Didnt add $deviceType to $vmName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   } elsif ($devStatus ne 0 && $task =~ /remove/i) {
      # A VM might have more than one devices of that type
      $vdLogger->Info("Removed one ".uc($deviceType)." but still more ".
                      uc($deviceType). " devices are attached to $vmName");
      return SUCCESS;
   } elsif ($devStatus ne 0 && $task =~ /add/i) {
        $vdLogger->Info("'$devStatus' added successfully on $vmName ");
        return SUCCESS;
   } elsif ($devStatus eq 0 && $task =~ /remove/i) {
        $vdLogger->Info("All $deviceType devices removed successfully ".
                        "from $vmName ");
        return SUCCESS;
   }

   VDSetLastError(VDGetLastError());
   return FAILURE;
}


########################################################################
#
# WaitForVDNet--
#      Method to wait until the guest is vdnet ready.
#      Work on both staf 4x and staf 5x
#
# Input:
#      None
#
# Results:
#      SUCCESS, if the guest is ready to execute vdnet scripts;
#      FAILURE, in case of any error
#
# Side effects:
#      None
#
########################################################################

sub WaitForVDNet
{
   # TODO - move this to parent class when it is cleaned up.
   my $self = shift;
   my $managementPortgroup = shift;
   # for PR 1116968, change timeout from 300 to 600
   my $timeout = 600;
   my $command;
   my $lscommand;

   my $vmx = $self->{'vmx'};
   my $host = $self->{'_host'}; # Now this can work also for hosted
   my $ip = VDNetLib::Common::Utilities::GetGuestControlIP($self, undef, undef,
                                                           $managementPortgroup);
   if ($ip eq FAILURE) {
      $vdLogger->Error("Failed to get ip address of $vmx");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $self->{'vmIP'} = $ip;

   my $result = $self->{stafHelper}->WaitForSTAF($self->{'vmIP'});
   if ($result eq FAILURE) {
      $vdLogger->Error("STAF wait failed for $vmx on $host");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($osType =~ /win/i) {
      $lscommand = 'DIR ' . WIN_SCRIPTS_PATH . '\remoteAgent.pl';
   } else {
      $lscommand = 'ls ' . LINUX_SCRIPTS_PATH . '/remoteAgent.pl';
   }

   my $startTime = time();
   my $stafTimeout = 120;
   while ($timeout && $startTime + $timeout > time()) {
        #Modify this code for PR1399014
        #For the vm that "/automation" already mounted donnot "umount&mount".
        #For the vm that "/automation" havenot mountd ,lsComand will fail once
        #and then after doing "umount&mount" $lsComand will excute successfully.
        $result = $self->{stafHelper}->STAFSyncProcess($ip, $lscommand, $stafTimeout);
        if ($result->{rc} == 0 && $result->{exitCode} == 0) {
           return SUCCESS;
        }
        # After we check vm mount /automation fail ,we should mount it again.
        # Some template also mounted hard disk ."unmount -a " will unmount these
        # disk and it won't sucess .So change these code to just unmount /automation.
        if ($osType !~ /win/i) {
         $command = 'umount /automation; mount /automation';
         $command = 'umount -a; mount -a';
         $result = $self->{stafHelper}->STAFSyncProcess($ip, $command);
         if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
            $vdLogger->Debug("Failed to reset mount points on $ip");
            $vdLogger->Debug(Dumper($result));
            # User can run this command mannualy and expecte following output for
            # further debugging . We  have delete  this part of vdnet as it takes
            # ~20 minutes sometimes of some guest os.
            # check PR1339933 for details.
            # $command = 'ps -eaf | grep -ri automation';
            # $result = $self->{stafHelper}->STAFSyncProcess($ip, $command);
            # $vdLogger->Debug("$command on $ip gives " . $result->{stdout});
            }
       }
       sleep 10;
   }

   $vdLogger->Error("Timed out waiting for vdnet to be ready on " .
                    $self->{'vmIP'} . " " . Dumper($result));
   VDSetLastError("ETIMEDOUT");
   return FAILURE;
}



#############################################################################
#
# GetDeviceLabelFromMac --
#      Method to get device label of an adapter from the given mac address.
#      Label is the name/string in the format "Network adapter <x>".
#      Works on both staf 4x and staf 5x.
#
# Input:
#      macAddress: mac address of the adapter
#
# Results:
#      device label of the given adapter (a scalar string)
#
# Side effects:
#      None
#
#############################################################################

sub GetDeviceLabelFromMac
{
   my $self = shift;
   my $macAddress = shift;

   my $nicsInfo = $self->GetAdaptersInfo();

   if ($nicsInfo eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $device = undef;
   foreach my $adapter (@$nicsInfo) {
      if ($adapter->{'mac address'} =~ /$macAddress/i) {
         $device = $adapter->{'label'};
      }
   }
   return $device;
}


#############################################################################
#
# DisconnectVMStafAnchor --
#     Disonnects the anchor from the esx host to which it is connected.
#     Note: This is an internal function. Using it outside of this package
#           is not recommended.
#     Works on both staf 4x and staf 5x.
#
# Input:
#     anchor : staf anchor (Optional, default is $self->{stafVMAnchor}
#
# Results:
#     "SUCCESS", if anchor is disconnected;
#     "FAILURE", in case of any error
#
# Side effects:
#     Other methods will not work in this object if this method is called.
#
#############################################################################

sub DisconnectVMStafAnchor
{
   my $self = shift;
   my $anchor = shift || $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;

   if (not defined $anchor) {
      return SUCCESS;
   }

   $vdLogger->Info("Disconnecting STAF VM anchor $anchor");
   # Disconnect the anchor from the host.
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local",
                                       "DISCONNECT ANCHOR $anchor");
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error ("Failed to disconnect anchor $anchor.");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}



#############################################################################
#
# VMOpsConnectvNICCable --
#     Method to connect a virtual network adapter (equivalent of checking
#     the "connected" box in VI client).
#     Works on both staf 4x and staf 5x.
#
# Input:
#     macAddress: mac address of the adapter to be connected # Required
#
# Results:
#     "SUCCESS", if the adapter is connected successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsConnectvNICCable
{
   my $self       = shift;
   my $macAddress = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName  = $self->{'vmName'};
   my $anchor  = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   if (not defined $macAddress) {
      $vdLogger->Error("MAC address of the device to be connected not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $device = $self->GetDeviceLabelFromMac($macAddress);


   # Get information about all the network adapters of the VM

   # Throw error if there is no match for the given mac address
   if (not defined $device) {
      $vdLogger->Error("Unable to find the adapter label for $macAddress");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Execute the STAF command to connect the given device
   my $cmd = "CONNECTVIRTUALNIC ANCHOR $anchor VM \"$vmName\" VIRTUALNIC_NAME \"$device\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest information of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $self->VMOpsCheckDeviceStatus($device, "true");
}


#############################################################################
#
# VMOpsDisconnectvNICCable --
#     Method to disconnect a virtual network adapter (equivalent of clearing
#     the "connected" box in VI client).
#     Works on both staf 4x and staf 5x.
#
# Input:
#     macAddress: mac address of the adapter to be disconnected # Required
#
# Results:
#     "SUCCESS", if the adapter is disconnected successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsDisconnectvNICCable
{
   my $self       = shift;
   my $macAddress = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName  = $self->{'vmName'};
   my $anchor  = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   if (not defined $macAddress) {
      $vdLogger->Error("MAC address of the device to be disconnected " .
                       "not provided");
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

   # Execute the STAF command to connect the given device
   my $cmd = "DISCONNECTVIRTUALNIC ANCHOR $anchor VM \"$vmName\" VIRTUALNIC_NAME \"$device\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest information of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $self->VMOpsCheckDeviceStatus($device, "false");
}

#############################################################################
#
# VMOpsCheckDeviceStatus --
#     Method to check whether the connection status of a virtual network
#     adapter in a VM is the same as the specified status or not.
#
# Input:
#     deviceName     : name of the adapter ("Network adapter #")
#                      # Required
#     expectedStatus : the expected connection status (true/false)
#
# Results:
#     "SUCCESS", if the adapter is the status matches
#     "FAILURE", in case of any error or status does not match
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsCheckDeviceStatus
{
   my $self       = shift;
   my $device     = shift;
   my $expectedStatus = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName  = $self->{'vmName'};
   my $anchor  = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   my $cmd = "DEVCONNECTSTATE ANCHOR $anchor VM \"$vmName\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest device information of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $alldevices = $stafResult->{result};
   foreach my $VMDevice (@$alldevices) {
      if ($VMDevice->{"Device Name"} =~ /$device/) {
         if ($VMDevice->{State} =~ /$expectedStatus/i) {
            $vdLogger->Info("Device connection status is \"$expectedStatus\" as expected");
         } else {
            $vdLogger->Info("Device connection status is \"$expectedStatus\"");
            return FAILURE;
         }
         last;
      }
   }

   return SUCCESS;
}



#############################################################################
#
# VMOpsHotAddvNIC --
#     Method to add (hot/cold) a virtual network adapter in a VM.
#     Works on both staf 4x and staf 5x.
#
# Input:
#     deviceName: name of the adapter (e1000/e1000e/vmxnet2/vmxnet3/vlance)
#                 # Required
#     portgroup : name of the portgroup to which this adapter should be
#                 connected # Required
#
# Results:
#     "SUCCESS", if the adapter is added successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsHotAddvNIC
{
   my $self       = shift;
   my $deviceName = shift;
   my $portgroup  = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   if (not defined $deviceName || not defined $portgroup) {
      $vdLogger->Error("Device name and/or portgroup not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Execute STAF command to hot add virtual network adapter
   my $cmd = "ADDVIRTUALNIC ANCHOR $anchor VM \"$vmName\" PGNAME \"$portgroup\" " .
             "ADAPTERTYPE $deviceName";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to hot add $deviceName with PG $portgroup " .
                       " on $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsVMotion --
#     Migrates a VM from one host to another.
#     Works on both staf 4x and staf 5x.
#
# Input:
#     vcServer -  The name/addr of the virtual center server managing the
#                 source and destination hosts of the VM to be migrated.
#     vmName   -  The name of the VM (as it appears in the invetory) which
#                 is to be migrated.
#     dstHost  -  The host to which the VM is to be migrated.
#
# Result:
#     "SUCCESS", if VMotion succeeded;
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
#############################################################################

sub VMOpsVMotion
{
   my $self = shift;
   my $vcServer = shift;
   my $dstHost = shift;
   my $vmName = $self->{'vmName'};
   my $vcAnchor;
   my $stafResult = undef;
   my $result;

   # Check if the params are defined.
   if ((not defined $vcServer) || (not defined $vmName) ||
       (not defined $dstHost)) {
      $vdLogger->Error("Insufficient parameters");
      VDSetLastError("ENOTDEF");
      return $result;
   }

   $vcAnchor = VDNetLib::Common::Utilities::GetSTAFAnchor($vcServer,
                                                           "vm",
                                                           "administrator");
   if (not defined $vcAnchor) {
      $vdLogger->Error("Unable to establish connection to $vcServer");
      VDSetLastError("ESTAF");
      return $result;
   }

   # Perform vmotion of VM from the current host to $dstHost.
   my $cmd = "VMOTION VMS \"$vmName\" ANCHOR $vcAnchor DSTHOST $dstHost PRIORITY NORMAL";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   $result = $stafResult->{rc};
   if (0 != $result) {
      $vdLogger->Error("Migrating $vmName to $dstHost failed with RC: " .
                             $result);
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}



#############################################################################
#
# VMOpsConfigureVMotion --
#     Prepares a VM for VMotion. i.e. Removes the devices that prevent
#     vmotion to another host.
#
# Input:
#     none.
#
# Result:
#     "SUCCESS", if configuration is successful.
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
#############################################################################

sub VMOpsConfigureVMotion
{
   my $self = shift;

   my @deviceList = qw(cdrom floppy serialport parallelport);
   my ($devName, $task, $result);

   # We need to remove all the devices mentioned in the array as a
   # pre-requsite for vmotion.
   # We poll the VM if the device of that type is attached or not
   # If it is attached we remove it and poll again. If there are
   # multiple devices of this type we keep on removing them untill
   # VM says there are no such devices.

   foreach my $deviceType (@deviceList) {
      $devName = $self->VMOpsDeviceAttachState($deviceType);
      if (($devName  eq FAILURE) || (not defined $devName)) {
         $vdLogger->Error("Not able to get attach state of device:$deviceType on ".
                          "this VM");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      while($devName ne 0) {
         # If result is non-zero, it means device is attached to this VM,
         # removing it.
         $task = "remove";
         $result = $self->VMOpsAddRemoveVirtualDevice($deviceType,
                                                      $task,
                                                      $devName);
         if($result eq FAILURE){
            $vdLogger->Error("Not able to $task virtual $devName from this VM");
            VDSetLastError("ESTAF");
            return FAILURE;
         }
         $vdLogger->Debug("Removed $devName from $self->{'vmName'}");

         # Making sure if all devices of this type are removed.
         $devName = $self->VMOpsDeviceAttachState($deviceType);
         if (($devName  eq FAILURE) || (not defined $devName)) {
            $vdLogger->Error("Not able to get attach state of ".
                             "device:$devName from this VM");
            VDSetLastError("EFAILED");
            return FAILURE;

         }
      }
   }

   return SUCCESS;

}


#######################################################################
#
# CreateDVFilterComponent --
#     Method to create components/managed objects/entities and verify
#     components .
#
# Input:
#     componentName: name of the component to be created
#     arrayofSpec : reference to array of hash
#
# Results:
#     Reference to array  of component objects, if successful;
#     TBD, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub CreateDVFilterComponent
{
   my $self               = shift;
   my $componentName      = shift;
   my $arrayOfSpec        = shift;
   my $className          = shift;
   my $args               = shift;
   my @arrayOfPyObj;

   if ((not defined $className) || (not defined $componentName)) {
      $vdLogger->Error("Either class name or component not given");
      $vdLogger->Debug("Class name:$className, component: $componentName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # Step1: Load the Component Perl Class
   eval "require $className";
   if ($@) {
      $vdLogger->Error("Failed to load $className $@");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   foreach my $element (@$arrayOfSpec) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("$componentName spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # Step2: Create instance the Component Perl Class
      my $componentPerlObj = $className->new('parentObj' => $self);
      if ((not defined $componentPerlObj)) {
         $vdLogger->Error("Failed to get componentObj");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Step3: Store each perl object in the array
      push @arrayOfPyObj, $componentPerlObj;
   }
   # Step4: Send the array of objects back
   return \@arrayOfPyObj;
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
   my $logDir = shift;
   my $esxHost = $self->{esxHost};
   my $vmx = $self->{vmx};
   my $stafHelper = $self->{stafHelper};
   my $message = VAR_LOG_MESSAGES;
   my $guestLogDir = GUEST_LOG_DIR;
   my $dmesg = "/root/ifconfig_route_and_dmesg.log";
   my $osType;
   my $ip;
   my $command;
   my $result;
   my $localIP;

   if (not defined $logDir) {
      $vdLogger->Error("Log Direcotry is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $self->{vmIP}) {
      $ip = $self->GetGuestControlIP();
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get the ip address of the VM");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } else {
      $ip = $self->{vmIP};
   }
   if (not defined $ip) {
      $vdLogger->Error("IP address of the vm not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Find the OS type
   $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of the master controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($osType =~ /linux/i) {
      $result = $stafHelper->STAFFSCopyFile($message,
                                            $logDir,
                                            $ip,
                                            $localIP);
      if ($result ne 0) {
         $vdLogger->Error("Failed to copy $message to log directory".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      # Clear out the existing contents of the file if file exists
      $command  = "ifconfig > $guestLogDir/ifconfig.log ; route > $guestLogDir/route.log ; ".
                  "ps -ef > $guestLogDir/process.log ; dmesg > $guestLogDir/dmesg.log";
      $result = $stafHelper->STAFSyncProcess($ip, $command);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get the DMESG".Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if (VDNetLib::Common::Utilities::CreateSSHSession($ip,
          $self->GetUsername(), $self->GetPassword()) eq FAILURE) {
         $vdLogger->Error("Create ssh session failed for VM $ip");
         VDSetLastError("ESESSION");
         return FAILURE;
      }
      # Replace STAFFSCopyDirectory with VDNetLib::Common::Utilities::CopyDirectory
      # since log collection hangs at this function
      $result = VDNetLib::Common::Utilities::CopyDirectory(srcDir => $guestLogDir,
             dstDir => $logDir, srcIP => $ip, stafHelper => $stafHelper);

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to copy $guestLogDir to log directory");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Debug("Successfully copy logs under $guestLogDir to $logDir " .
                       "from $ip");

   } else {
      $vdLogger->Trace("GetGuestLogs() not supported for $osType yet");
   }
   return SUCCESS;
}


#############################################################################
#
# GetVMwareLogs --
#     Method which copies the vmware.log files for the vms to log directory.
#
# Input:
#     LogDir : Log directory to which guest logs have to copied.
#
# Results:
#     "SUCCESS", if all the logs get copied to the specific directory
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#
#############################################################################

sub GetVMwareLogs
{
   my $self = shift;
   my $logDir = shift;
   my $esxHost = $self->{esxHost};
   my $vmx = $self->{vmx};
   my $stafHelper = $self->{stafHelper};
   my $result;
   my $localIP;
   my $vmwareLog;
   my $directory;

   if (not defined $logDir) {
      $vdLogger->Error("Log Directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # get the directory name where vmx resides.
   $directory = VDNetLib::Common::Utilities::GetVMDirectory($vmx);
   if ($directory eq FAILURE) {
      $vdLogger->Error("Failed to get the directory name of VM");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vmwareLog = $directory . '/' . 'vmware.log';
   $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of the master controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # If the datastore name has spaces and brackets like
   # datastore\ \(1\), we should strip the escape characters
   # since this string has it's value in single quotes otherwise
   # the copy call fails.
   #

   $vmwareLog =~ s/\\//g;
   $result = $stafHelper->STAFFSCopyFile($vmwareLog,
                                         $logDir,
                                         $esxHost,
                                         $localIP);
   if ($result ne 0) {
      $vdLogger->Error("Failed to copy $vmwareLog to log directory");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}



#############################################################################
#
# GetVarLogs --
#     Method which copies the guest logs to the specific log directory.
#
# Input:
#     LogDir : Log directory to which var/log/messages have to copied.
#
# Results:
#     "SUCCESS", if all the logs get copied to the specific directory
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
# Note: This functions works collects mainly linux logs.
#
#############################################################################

sub GetVarLogs
{
   my $self = shift;
   my $logDir = shift;
   my $esxHost = $self->{esxHost};
   my $vmx = $self->{vmx};
   my $stafHelper = $self->{stafHelper};
   my $message = "/var/log/messages";
   my $osType;
   my $ip;
   my $command;
   my $result;
   my $localIP;

   if (not defined $logDir) {
      $vdLogger->Error("Log Direcotry is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $self->{vmIP}) {
      $ip = $self->GetGuestControlIP();
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get the ip address of the VM");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } else {
      $ip = $self->{vmIP};
   }

   # Find the OS type
   $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of the master controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($osType =~ /linux/i) {
      $result = $stafHelper->STAFFSCopyFile($message,
                                            $logDir,
                                            $ip,
                                            $localIP);
      if ($result ne 0) {
         $vdLogger->Error("Failed to copy $message to log directory");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $vdLogger->Trace("GetVarLogs() not supported for $osType yet");
   }
   return SUCCESS;
}


#############################################################################
#
# GetDmesgLogs --
#     Method which copies the guest logs to the specific log directory.
#
# Input:
#     LogDir : Log directory to which dmesg logs have to copied.
#
# Results:
#     "SUCCESS", if all the logs get copied to the specific directory
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
# Note: This functions works collects mainly linux logs.
#
#############################################################################

sub GetDmesgLogs
{
   my $self = shift;
   my $logDir = shift;
   my $esxHost = $self->{esxHost};
   my $vmx = $self->{vmx};
   my $stafHelper = $self->{stafHelper};
   my $dmesg = "/root/dmesg.log";
   my $osType;
   my $ip;
   my $command;
   my $result;
   my $localIP;

   if (not defined $logDir) {
      $vdLogger->Error("Log Direcotry is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $self->{vmIP}) {
      $ip = $self->GetGuestControlIP();
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get the ip address of the VM");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } else {
      $ip = $self->{vmIP};
   }

   # Find the OS type
   $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of the master controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($osType =~ /linux/i) {
      $command  = "dmesg > $dmesg";
      $result = $stafHelper->STAFSyncProcess($ip, $command);
      if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) ) {
         $vdLogger->Error("Failed to get the DMESG");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $result = $stafHelper->STAFFSCopyFile($dmesg,
                                            $logDir,
                                            $ip,
                                            $localIP);
      if ($result ne 0) {
         $vdLogger->Error("Failed to copy $dmesg to log directory");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $vdLogger->Trace("GetDmesgLogs() not supported for $osType yet");
   }
   return SUCCESS;
}


#############################################################################
#
# SetNetdumpConfig --
#   Method to Set the Configurations on Netdump Server.
#
# Input:
#   operation: "config"
#   os       : "linux/win"
#   key      : this accepts the different parametrs to set the netdump.
#   value    : value to be set to the above mentioned key.
#
# Results:
#     "SUCCESS", if the configuration is set properly to the Netdumper.
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub SetNetdumpConfig
{
    #Input Parameters
    my ($os, $operation, $key, $value) = @_;
    #Operational Variables
    my $flag_2008  = 0;
    my $flag_2003  = 0;
    my $configdir  = "";
    my $configfile = "";
    my $tempdir = "";
    my $originallogsdir = "";
    my $originaldatadir = "";
    my $corepath  = "/var/core/netdumps";
    my $tempcorepath = "/var/core/";
    my $logsfile  = "/var/log/vmware/netdumper/netdumper.log";
    my $templogsfile  = "/var/log/vmware/netdumper.log";
    my $templogsdir  = "/var/log/vmware";
    if (defined $value) {
        chomp ($value);
    }
    if ($os =~ /win/i) {
	my $os = GetWindowsType();
	if ($os =~ /win2k8/i) {
	    $flag_2008 = 1;
	}
	elsif ($os =~ /win2k3/i) {
	    $flag_2003 = 1;
	}
	else {
            $vdLogger->Error("Failed to Get WIndows Type");
	    return FAILURE;
	}
        if($flag_2008 == 1){
            $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_5;
            if ( -e $configfile ) {
               $configdir  = VDNetLib::TestData::TestConstants::CONFIG_DIR_5;
               $tempdir    = VDNetLib::TestData::TestConstants::TEMP_DIR_5;
               $originallogsdir = VDNetLib::TestData::TestConstants::ORIGINAL_LOGS_DIR_5;
               $originaldatadir = VDNetLib::TestData::TestConstants::ORIGINAL_DATA_DIR_5;
            } else {
               $configdir  = VDNetLib::TestData::TestConstants::CONFIG_DIR_6;
               $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_6;
               $tempdir  =  VDNetLib::TestData::TestConstants::TEMP_DIR_6;
               $originallogsdir = VDNetLib::TestData::TestConstants::ORIGINAL_LOGS_DIR_6;
               $originaldatadir = VDNetLib::TestData::TestConstants::ORIGINAL_DATA_DIR_6;
            }
        }
        if($flag_2003 == 1){
            $configdir  =  VDNetLib::TestData::TestConstants::CONFIG_DIR_W2K3;
            $configfile =  VDNetLib::TestData::TestConstants::CONFIG_FILE_W2K3;
            $tempdir  = VDNetLib::TestData::TestConstants::TEMP_DIR_W2K3;
            $originallogsdir = VDNetLib::TestData::TestConstants::ORIGINAL_LOGS_DIR_W2K3;
            $originaldatadir = VDNetLib::TestData::TestConstants::ORIGINAL_DATA_DIR_W2K3;
        }
    }
    elsif ($os =~ /lin/i) {
        $configdir = "/etc/sysconfig/";
        my $netdump_config_file = "netdumper";
        $configfile = "$configdir". "$netdump_config_file";
    }

    if ($os =~ m/win/i) {
        my $tempfile = "$configdir". "temp.xml";
        system("copy \"$configfile\" \"$tempfile\"");
        my $xml = new XML::Simple;
        my $config = $xml->XMLin($tempfile, KeyAttr => [], ForceArray => 1);
        if ($key eq "installpath") {
            $config->{'defaultInstallPath'}[0] = "$value";
        }
        elsif  ($key eq "corepath") {
            if ($value eq "changepath") {
                $value = "$tempdir";
            }
            elsif ($value eq "revertpath") {
                $value = "$originaldatadir";
            }
            $config->{'defaultDataPath'}[0] = "$value";
        }
        elsif  ($key eq "logpath") {
            if ($value eq "changepath") {
                $value = "$tempdir";
            }
            elsif ($value eq "revertpath") {
                $value = "$originallogsdir";
            }
            $config->{'defaultLogPath'}[0] = "$value";
        }
	elsif  ($key eq "configpath") {
            $config->{'defaultConfigPath'}[0] = "$value";
        }
        elsif  ($key eq "serviceip") {
            $config->{'serviceAddress'}[0] = "$value";
        }
        elsif  ($key eq "port") {
            $config->{'defaultValues'}[0]->{'port'}[0] = "$value";
        }
        elsif  ($key eq "maxsize") {
            $config->{'defaultValues'}[0]->{'maxSize'}[0] = "$value";
        }
        elsif  ($key eq "level") {
            $config->{'debug'}[0]->{'level'}[0] = "$value";
        }
        else {
            $vdLogger->Error("Invalid Arguments for Modifying".
			     " the Netdump config");
	    return FAILURE;
        }
        system("copy \"$tempfile\" \"$configfile\"");
        my $xmlout = XMLout($config, RootName=>'config');
	if (not defined open(FH, ">$configfile")) {
	    $vdLogger->Error("Unable to open file $configfile:"
                       ."$!");
	    VDSetLastError("EOPFAILED");
	    return FAILURE;
	}
        print FH $xmlout;
        close FH;
        return SUCCESS;
    }
    elsif ($os =~ m/linux/i) {
        if (($key eq "port") || ($key eq "corepath") ||
            ($key eq "logpath") || ($key eq "maxsize") || ($key eq "level") ) {
	    $vdLogger->Info("Modifying the $key with value $value");
        }
        else {
            $vdLogger->Error("Invalid Arguments for Modifying".
			     " the Netdump config");
	    return FAILURE;
        }
        my $tempfile = "/tmp/netdump.temp";
        system ("echo \"\" > $tempfile");
        open (TEMP_FILE, ">$tempfile");
	if (not defined open(NETDUMPER_FILE, "<$configfile")) {
	    $vdLogger->Error("Unable to open file $configfile:"
                       ."$!");
	    VDSetLastError("EOPFAILED");
	    return FAILURE;
	}
        while (<NETDUMPER_FILE>) {
            if (($key eq "port") && ($_ =~ m/^NETDUMPER_PORT(.*)/)) {
                print TEMP_FILE "NETDUMPER_PORT=$value\n";
            }
            elsif (($key eq "corepath") && ($_ =~ m/^NETDUMPER_DIR=(.*)/)) {
                if ($value eq "changepath") {
                   $value = "$tempcorepath";
                }
                elsif ($value eq "revertpath") {
                    $value = "$corepath";
                }
                print TEMP_FILE "NETDUMPER_DIR=\"$value\"\n";
	    }
            elsif (($key eq "logpath") &&
                   ($_ =~ m/^NETDUMPER_LOG_FILE(.*)/)) {
                if ($value eq "changepath") {
                    $value = "$templogsfile";
                    system ("chmod -R a+w $templogsdir");
                }
                elsif ($value eq "revertpath") {
                    $value = "$logsfile";
                }
                print TEMP_FILE "NETDUMPER_LOG_FILE=\"$value\"\n";
            }
            elsif (($key eq "maxsize") &&
                   ($_ =~ m/^NETDUMPER_DIR_MAX_GB(.*)/)) {
               print TEMP_FILE "NETDUMPER_DIR_MAX_GB=$value \# gigabytes\n";
            }
            else {
                print TEMP_FILE $_;
            }
        }
        close (NETDUMPER_FILE);
        close (TEMP_FILE);
        my $ret = system ("cp -f $tempfile $configfile");
        if ($ret != 0) {
	    $vdLogger->Error("copying the modified netdump".
				" configuration failed");
	    return FAILURE;
        }
        system ("rm -f $tempfile");
        return SUCCESS;
    }
}


#############################################################################
#
# CheckNetdumpStatus --
#   Check the Netdump Status on the Netdump Server.
#
# Input:
#   operation: "config"
#   os       : "linux/win"
#   key      : Netdump Client IP from where the netdump is initiated.
#
# Results:
#     "SUCCESS", if the network coredump is successful.
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub CheckNetdumpStatus
{
    #Input Parameters
    my ($os, $operation, $Clientip) = @_;

    #Operational Variables
    my $flag_2008  = 0;
    my $flag_2003  = 0;
    my $configfile = "";
    my $configPath = "";

    if ($os =~ /win/i) {
        #command to get Window Server OS Type
	my $os = GetWindowsType();
	if ($os =~ /win2k8/i) {
	    $flag_2008 = 1;
	}
	elsif ($os =~ /win2k8/i) {
	    $flag_2003 = 1;
	}
	else {
	    $vdLogger->Error("Failed to Get Windows Type");
	    return FAILURE;
	}
        if($flag_2008 == 1){
            $configPath = VDNetLib::TestData::TestConstants::CONFIG_DIR_5;
            if (-d $configPath) {
               $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_5;
            } else {
               $configPath = VDNetLib::TestData::TestConstants::CONFIG_DIR_6;
               if (-d $configPath) {
                  $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_6;
               }
            }
        }
        if($flag_2003 == 1){
            $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_W2K3;
        }
    }
    elsif ($os =~ /lin/i) {
        $configfile = "/etc/sysconfig/". "netdumper";
    }
    my $success = 0;
    my $netdumpLogFile    = "";
    my $netdumpConfigFile = "";
    my $netdumpDataPath   = "";
    my $cmd;

    if ($os =~ m/win/i) {
        my $xml = new XML::Simple;
        my $config = $xml->XMLin($configfile,
				 KeyAttr => [], ForceArray => 1);
        my $netdumpLogPath = "$config->{'defaultLogPath'}[0]";
        $netdumpLogFile = "$netdumpLogPath". "\\". "netdumper.log";
        $netdumpDataPath = "$config->{'defaultDataPath'}[0]";
    }
    elsif ($os =~ m/linux/i) {
        # Check the Log file path from the Netdumper config file
	if (not defined open(CONFFILE, "<$configfile")) {
	    $vdLogger->Error("Unable to open file $configfile:"
                       ."$!");
	    VDSetLastError("EOPFAILED");
	    return FAILURE;
	}
        while (<CONFFILE>) {
            if ($_ =~ m/^NETDUMPER_LOG_FILE=(.*)/i) {
                $netdumpLogFile = $1;
            }
        }
        close (CONFFILE);
        $netdumpLogFile =~ s/\"//g;
    }
    if ($os =~ /lin/i) {
       $cmd = 'find /var/core/netdumps -type f -name "*' . $Clientip . '*"';
       if( -d "/var/core/netdumps" ) {
          my $ret = `$cmd`;
          if ($ret =~ /$Clientip/i) {
             $vdLogger->Debug("Linux core dump file: $ret");
             $success = 1;
          }
       }
    }
    elsif ($os =~ /win/i) {
       $cmd = 'dir /s /b $configPath | find  "$Clientip" ';
       if ( -d $configPath) {
          my $ret = `$cmd`;
          if ($ret =~ /$Clientip/i) {
             $vdLogger->Debug("Windows core dump file: $ret");
             $success = 1;
          }
       }
    }
    if ($success == 1) {
       return SUCCESS;
    }
    else {
       $vdLogger->Error("Dump Status Checking Failed !!!");
       my $result = `$cmd`;
       $vdLogger->Error("Content of core dump directory: $result");
       return FAILURE;
    }
}


#############################################################################
#
# VerifyNetdumpConfig --
#   Method to Verify the Configurations on Netdump Server.
#
# Input:
#   operation: "config"
#   os       : "linux/win"
#   key      : this accepts the parametrs to verify the netdumper.
#   value    : Value to be verified to the above mentioned key.
#
# Results:
#     "SUCCESS", if the verification is carried out successfully.
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VerifyNetdumpConfig
{
    #Input Parameters
    my ($os, $operation, $key, $value) = @_;
    #Operational Variables
    my $flag_2008  = 0;
    my $flag_2003  = 0;
    my $configfile = "";
    my $tempdir = "";
    my $originallogsdir = "";
    my $originaldatadir = "";
    my $corepath  = "/var/core/netdumps";
    my $tempcorepath = "/var/core/";
    my $logsfile  = "/var/log/vmware/netdumper/netdumper.log";
    my $templogsfile  = "/var/log/vmware/netdumper.log";
    my $configdir = "";
    if (defined $value) {
        chomp ($value);
    }

    if ($os =~ /win/i) {
        #command to get Window Server OS Type
	my $os = GetWindowsType();
	if ($os =~ /win2k8/i) {
	    $flag_2008 = 1;
	}
	elsif ($os =~ /win2k8/i) {
	    $flag_2003 = 1;
	}
	else {
	    $vdLogger->Error("Failed to get Type of Windows!!!");
	    return FAILURE;
	}
        if($flag_2008 == 1){
            $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_5;
            if ( -e $configfile ) {
               $configdir  = VDNetLib::TestData::TestConstants::CONFIG_DIR_5;
               $tempdir    = VDNetLib::TestData::TestConstants::TEMP_DIR_5;
               $originallogsdir = VDNetLib::TestData::TestConstants::ORIGINAL_LOGS_DIR_5;
               $originaldatadir = VDNetLib::TestData::TestConstants::ORIGINAL_DATA_DIR_5;
            } else {
               $configdir  = VDNetLib::TestData::TestConstants::CONFIG_DIR_6;
               $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_6;
               $tempdir  =  VDNetLib::TestData::TestConstants::TEMP_DIR_6;
               $originallogsdir = VDNetLib::TestData::TestConstants::ORIGINAL_LOGS_DIR_6;
               $originaldatadir = VDNetLib::TestData::TestConstants::ORIGINAL_DATA_DIR_6;
            }
        }
        if($flag_2003 == 1){
            $configdir  =  VDNetLib::TestData::TestConstants::CONFIG_DIR_W2K3;
            $configfile =  VDNetLib::TestData::TestConstants::CONFIG_FILE_W2K3;
            $tempdir  = VDNetLib::TestData::TestConstants::TEMP_DIR_W2K3;
            $originallogsdir = VDNetLib::TestData::TestConstants::ORIGINAL_LOGS_DIR_W2K3;
            $originaldatadir = VDNetLib::TestData::TestConstants::ORIGINAL_DATA_DIR_W2K3;
        }
    }
    elsif ($os =~ /lin/i) {
        $configfile = "/etc/sysconfig/". "netdumper";
    }
    if ($os =~ m/win/i) {
        my $valueForVerification = "";
        my $xml = new XML::Simple;
        my $config = $xml->XMLin($configfile,
			KeyAttr => [], ForceArray => 1);
        if ($key eq "installpath") {
            $valueForVerification = $config->{'defaultInstallPath'}[0];
        }
        elsif  ($key eq "corepath") {
            if ($value eq "temppath") {
                $value = "$tempdir";
            }
            elsif ($value eq "originalpath") {
                $value = "$originaldatadir";
            }
            $valueForVerification = $config->{'defaultDataPath'}[0];
        }
        elsif  ($key eq "logpath") {
            if ($value eq "temppath") {
                $value = "$tempdir";
            }
            elsif ($value eq "originalpath") {
                $value = "$originallogsdir";
            }
            $valueForVerification = $config->{'defaultLogPath'}[0];
        }
        elsif  ($key eq "configpath") {
            $valueForVerification = $config->{'defaultConfigPath'}[0];
        }
        elsif  ($key eq "serviceip") {
            $valueForVerification = $config->{'serviceAddress'}[0];
        }
        elsif  ($key eq "port") {
            $valueForVerification =
                    $config->{'defaultValues'}[0]->{'port'}[0];
        }
        elsif  ($key eq "maxsize") {
            $valueForVerification =
                    $config->{'defaultValues'}[0]->{'maxSize'}[0];
        }
        elsif  ($key eq "level") {
            $valueForVerification = $config->{'debug'}[0]->{'level'}[0];
        }
        else {
	    $vdLogger->Error("Invalid Arguments for Modifying".
				" the Netdump config!!!");
	    return FAILURE;
        }
        chomp ($valueForVerification);
        $valueForVerification =~ s/\"//g;
        $value =~ s/\"//g;
        if  ($key eq "configpath" || $key eq "logpath") {
            if ($valueForVerification =~ m/\\$/) {
               chop ($valueForVerification);
            }
            if ($value =~ m/\\$/) {
                chop ($value);
            }
        }
        if ($valueForVerification ne $value) {
	    $vdLogger->Error("Netdump Server configuration".
				" verification Failed!!!");
	    return FAILURE;
        }
        return SUCCESS;
    }
    elsif ($os =~ m/linux/i) {
        if (($key eq "port") || ($key eq "corepath") ||
           ($key eq "logpath") || ($key eq "maxsize")) {
	    $vdLogger->Info("Verifying the $key with value $value");
        }
        else {
	    $vdLogger->Error("Invalid Arguments for Verifying".
				" the Netdump config !!!");
	    return FAILURE;
        }
	if (not defined open(NETDUMPER_FILE, "<$configfile")) {
	    $vdLogger->Error("Unable to open file $configfile:"
                       ."$!");
	    VDSetLastError("EOPFAILED");
	    return FAILURE;
        }
        my $valueForVerification = "";
        while (<NETDUMPER_FILE>) {
            if (($key eq "port") && ($_ =~ m/^NETDUMPER_PORT=(.*)/)) {
                $valueForVerification = $1;
                last;
            }
            elsif (($key eq "corepath") && ($_ =~ m/^NETDUMPER_DIR=(.*)/)) {
                if ($value eq "temppath") {
                    $value = "$tempcorepath";
                }
                elsif ($value eq "originalpath") {
                    $value = "$corepath";
                }
                $valueForVerification = $1;
                last;
            }
            elsif (($key eq "logpath") &&
                   ($_ =~ m/^NETDUMPER_LOG_FILE=(.*)/) ) {
                if ($value eq "temppath") {
                    $value = "$templogsfile";
                }
                elsif ($value eq "originalpath") {
                    $value = "$logsfile";
                }
                $valueForVerification = $1;
                last;
            }
            elsif (($key eq "maxsize") &&
                   ($_ =~ m/^NETDUMPER_DIR_MAX_GB=(.*)/)) {
                $valueForVerification = $1;
                last;
            }
        }
        close (NETDUMPER_FILE);
        chomp ($valueForVerification);
        $valueForVerification =~ s/\"//g;
        if ($valueForVerification eq $value) {
	    $vdLogger->Info("Netdumper configuration verification Successful");
	    return SUCCESS;
        }
        else {
	    $vdLogger->Error("Netdump Server configuration".
				" verification Failed !!!");
	    return FAILURE;
        }
    }
}


#############################################################################
#
# CleanNetdumpLogs --
#   Method to Clean the Netdump Server Logs.
#
# Input:
#   operation: "config"
#   os       : "linux/win"
#   key      : this accepts the different parametrs to set the netdump.
#   value    : Value to be set to the above mentioned key.
#
# Results:
#     "SUCCESS", if netdumper logs are cleaned successfully.
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub CleanNetdumpLogs
{
    #Input Parameters
    my ($os, $operation) = @_;
    #Operational Variables
    my $flag_2008  = 0;
    my $flag_2003  = 0;
    my $configfile = "";
    my $configdir  = "";

    if ($os =~ /win/i) {
        #command to get Window Server OS Type
	my $os = GetWindowsType();
	if ($os =~ /win2k8/i) {
	    $flag_2008 = 1;
	}
	elsif ($os =~ /win2k8/i) {
	    $flag_2003 = 1;
	}
	else {
	    $vdLogger->Error("Failed to get Type of Windows!!!");
	    return FAILURE;
	}
        if($flag_2008 == 1){
            $configdir = VDNetLib::TestData::TestConstants::CONFIG_DIR_5;
            if (-d $configdir) {
               $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_5;
            } else {
               $configdir = VDNetLib::TestData::TestConstants::CONFIG_DIR_6;
               if (-d $configdir) {
                  $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_6;
               }
            }
        }
        if($flag_2003 == 1){
            $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_W2K3;
        }
    }
    elsif ($os =~ /lin/i) {
        $configfile = "/etc/sysconfig/". "netdumper";
    }
    if ($os =~ m/win/i) {
        my $xml = new XML::Simple;
        my $config = $xml->XMLin($configfile,
				KeyAttr => [], ForceArray => 1);
        my $netdumpLogPath = "$config->{'defaultLogPath'}[0]";
        my $netdumpLogFile = "$netdumpLogPath". "\\". "netdumper.log";
        $netdumpLogFile = "\"". "$netdumpLogFile". "\"";
        my $ret = system ("echo \"\" > $netdumpLogFile");
	$vdLogger->Debug("Return val of CleanNetdumpLogs:".Dumper($ret));
        if ($ret != 0) {
	    $vdLogger->Error("Cleaning the netdumper log file failed!!!");
	    return FAILURE;
        }
	$vdLogger->Info("Cleaning netdumper log file Successful");
	return SUCCESS;
    }
    elsif ($os =~ m/linux/i) {
        my $netdumpLogFile = "";
        #Check the Log file path from the Netdumper config file
        if (not defined open(CONFFILE, "<$configfile")) {
           $vdLogger->Error("Unable to open file $configfile:"
                            ."$!");
           VDSetLastError("EOPFAILED");
           return FAILURE;
        }
        while (<CONFFILE>) {
           if ($_ =~ m/^NETDUMPER_LOG_FILE=(.*)/ ) {
              $netdumpLogFile = $1;
           }
        }
        close (CONFFILE);
        my $ret = system("echo \"\" > $netdumpLogFile");
        if ($ret != 0) {
           $vdLogger->Error("Cleaning the netdumper log file failed!!!");
           return FAILURE;
        }
        $ret = system("rm -rf /var/core/netdumps/*");
        if ($ret != 0) {
           $vdLogger->Error("Cleaning the files under /var/core/netdumps failed!!!");
           return FAILURE;
        }
        $vdLogger->Info("Cleaning netdumper log file Successful");
	return SUCCESS;
    }
}


#############################################################################
#
# InstallNetdumpServer --
#   Method to Install the Netdump Server.
#
# Input:
#   operation: "config"
#   os       : "linux/win"
#   key      : this accepts the options of installation.
#		upgrade/install/uninstall
#
# Results:
#     "SUCCESS", if the installation is done properly.
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub InstallNetdumpServer
{
    #Input Parameters
    my ($os, $operation, $netdumpUpgrade) = @_;
    chomp ($netdumpUpgrade);
    #Operational Variables
    my $flag_2008  = 0;
    my $flag_2003  = 0;
    my $configfile = "";

    if ($os =~ /win/i) {
        #command to get Window Server OS Type
	my $os = GetWindowsType();
	if ($os =~ /win2k8/i) {
	    $flag_2008 = 1;
	}
	elsif ($os =~ /win2k8/i) {
	    $flag_2003 = 1;
	}
	else {
	    $vdLogger->Error("Failed to Get Type of Windows!!!");
	    return FAILURE;
	}
    }
    elsif ($os =~ /lin/i) {
        $configfile = "/etc/sysconfig/". "netdumper";
    }
    #This code part is skeleton of the netdump server installation
    if ($os =~ m/win/i) {
        #Install/Upgrade Netdump Server
        if ($netdumpUpgrade eq "upgrade") {
        }
        #Do not Upgrade Netdump Server
        elsif ($netdumpUpgrade eq "noupgrade") {
        }
        #Uninstall Netdump Server
        elsif ($netdumpUpgrade eq "uninstall") {
        }
        #Install Netdump Server
        elsif ($netdumpUpgrade eq "install") {
        }
    }
    elsif ($os =~ m/linux/) {
        #Install/Upgrade Netdump Server
        if ($netdumpUpgrade eq "upgrade") {
        }
        #Do not Upgrade Netdump Server
        elsif ($netdumpUpgrade eq "noupgrade") {
        }
        #Uninstall Netdump Server
        elsif ($netdumpUpgrade eq "uninstall") {
        }
        #Install Netdump Server
        elsif ($netdumpUpgrade eq "install") {
        }
    }
    return SUCCESS;
}


#############################################################################
#
# SetReadWritePermissions --
#   Method to Set the Permissions on Log/Core path on the Server.
#
# Input:
#   operation: "config"
#   os       : "linux/win"
#   directory : type of operation on directory.
#   value    : readonly/readwrite
#
# Results:
#     "SUCCESS", if the permissions are properly set.
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub SetReadWritePermissions
{
    #Input Parameters
    my ($os, $operation, $directory, $value) = @_;
    chomp ($directory);
    #Operational Variables
    my $flag_2008  = 0;
    my $flag_2003  = 0;
    my $configfile = "";
    my $configdir  = "";

    if ($os =~ /win/i) {
        #command to get Window Server OS Type
	my $os = GetWindowsType();
	if ($os =~ /win2k8/i) {
	    $flag_2008 = 1;
	}
	elsif ($os =~ /win2k8/i) {
	    $flag_2003 = 1;
	}
	else {
	    $vdLogger->Error("Failed to Get Type of Windows!!!");
	    return FAILURE;
	}
        if($flag_2008 == 1){
            $configdir = VDNetLib::TestData::TestConstants::CONFIG_DIR_5;
            if (-d $configdir) {
               $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_5;
            } else {
               $configdir = VDNetLib::TestData::TestConstants::CONFIG_DIR_6;
               if (-d $configdir) {
                  $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_6;
               }
            }
        }
        if($flag_2003 == 1){
            $configfile = VDNetLib::TestData::TestConstants::CONFIG_FILE_W2K3;
        }
    }
    elsif ($os =~ /lin/i) {
        $configfile = "/etc/sysconfig/". "netdumper";
    }
    if ($os =~ m/win/i) {
        my $xml = new XML::Simple;
        my $config = $xml->XMLin($configfile,
				KeyAttr => [], ForceArray => 1);
        my $netdumpDirPath = "";
        if ($directory =~ m/logpath/i) {
            $netdumpDirPath = "$config->{'defaultLogPath'}[0]";
	    $netdumpDirPath = "$netdumpDirPath". "netdumper.log";
        }
        elsif ($directory =~ m/corepath/i) {
            $netdumpDirPath = "$config->{'defaultDataPath'}[0]";
        }
        my $ret = "";
        if ($value =~ m/readonly/i) {
            $ret = system ("attrib +R \"$netdumpDirPath\"");
        }
        if ($value =~ m/readwrite/i) {
            $ret = system ("attrib -R \"$netdumpDirPath\"");
        }
        if ($ret != 0) {
	    $vdLogger->Error("Setting Readonly/ReadWrite failed!!!");
	    return FAILURE;
        }
	$vdLogger->Info("Setting Readonly/ReadWrite Successful");
	return SUCCESS;
    }
    elsif ($os =~ m/linux/i) {
        my $netdumpDirPath = "";
	if (not defined open(CONFFILE, "<$configfile")) {
	    $vdLogger->Error("Unable to open file $configfile:"
                       ."$!");
	    VDSetLastError("EOPFAILED");
	    return FAILURE;
        }
        while (<CONFFILE>) {
            if (($directory =~ m/logpath/i) &&
                ($_ =~ m/^NETDUMPER_LOG_FILE=(.*)/)) {
                $netdumpDirPath = "$1";
            }
            elsif (($directory =~ m/corepath/i) &&
                   ($_ =~ m/^NETDUMPER_DIR=(.*)/)) {
                $netdumpDirPath = "$1";
            }
        }
        my $ret = "";
        if ($value =~ m/readonly/i) {
            $ret = system ("chmod -R a-w $netdumpDirPath");
        }
        if ($value =~ m/readwrite/i) {
            $ret = system ("chmod -R a+w $netdumpDirPath");
        }
	if ($ret != 0) {
	    $vdLogger->Error("Setting Readonly/ReadWrite failed!!!");
	    return FAILURE;
        }
	$vdLogger->Info("Setting Readonly/ReadWrite Successful");
	return SUCCESS;
    }
}


#############################################################################
#
# ConfigureService --
#   Method to Configure i.e stop/start a service on Win/Linux.
#
# Input:
#   operation: "config"
#   os       : "linux/win"
#   key      : serivce name.
#   value    : start/stop.
#
# Results:
#     "SUCCESS", if service is configured properly.
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub ConfigureService
{
    #Input Parameters
    my ($os, $operation, $service, $action) = @_;
    my $initFile;

    $vdLogger->Debug("ConfigureService Input Values:$service,$action");
    if ($os =~ m/linux/i) {
        my  $suseFirewall = '/sbin/SuSEfirewall2';
        if ( ($service =~ /firewall/i) && (-e $suseFirewall ) ){
           $service = "SuSEfirewall2";
           $initFile = "/sbin/" . "$service";
        } else {
        # other linux
	   $service = "iptables";
           $initFile = "/etc/init.d/" . "$service";
        }
        chomp ($initFile);
        if (-e $initFile) {
            my $command = "$initFile ". " $action";
            $vdLogger->Debug("Linux $service command = $command");
            my $ret = system ("$command");
            $vdLogger->Debug("Linux Service return value: $ret");
            if ($ret != 0) {
	        $vdLogger->Error("Configuring $service $action failed!!!");
	        return FAILURE;
            }
        }
        else {
	    $vdLogger->Error("The $service doesn't exist !!!");
        }
    }
    if ($os =~ m/win/i) {
        if ($action =~ /stop/i) {
           $action = "disable";
        } elsif ($action =~ /start/i) {
           $action = "enable";
        }
        my $command = "netsh firewall set opmode  $action";
        $vdLogger->Debug("Windows $service command = $command");
        my $ret = system ("$command");
            $vdLogger->Debug("Win Service return value: $ret");
        if ($ret != 0) {
	    $vdLogger->Error("Configuring $service $action failed!!!");
	    return FAILURE;
        }
    }
    $vdLogger->Info("Configure $service $action Successful");
    return SUCCESS;
}


#############################################################################
#
# GetWindowsType --
#   Method to get the Type of Windows.
#
# Input:
#   None
#
# Results:
#     "SUCCESS", if proper type is returned.
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetWindowsType
{
    #command to get Window Server OS Type
    my $flag_2008 = 0;
    my $flag_2003 = 0;
    my $cmd=`systeminfo|findstr \"OS Name\"`;
    foreach (split("\n",$cmd)){
        if($_=~/^OS Name(.*)(\d\d\d\d)/){
            my $ver=$2;
            if($ver=~/2008/){
                $flag_2008 = 1;
            }
            if($ver=~/2003/){
                $flag_2003 = 1;
            }
            last;
        }
    }
    if ($flag_2008 == 1) {
	return "WIN2k8";
    }
    elsif ($flag_2003 == 1) {
	return "WIN2k3";
    }
    else {
	$vdLogger->Error("Failed to Get Type of Windows !!!");
	return FAILURE;
    }
}


########################################################################
#
# SendKeystrokes--
#     Method to send keystrokes to guest console using pyVigor.
#     Invokes sendKeystrokes.py script
#     (Works only from MN.next builds)
#
# Input:
#     None
#
# Results:
#     SUCCESS, if keystrokes are sent successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SendKeystrokes
{
   my $self = shift;

   my $command = "python $FindBin::Bin/../scripts/sendKeystrokes.py " .
                 $self->{vmx};
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{_host}, $command);
   if ($result->{rc} == 0 && $result->{exitCode} == 0) {
      $vdLogger->Error("Failed to execute sendKeystrokes command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetWorldID --
#     Method to get world id for the VM
#
# Input:
#     None
#
# Results:
#     vm world id, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetWorldID
{
   my $self = shift;
   my $hostObj  = $self->{'hostObj'};

   my $command = 'esxcli network vm list | grep -i ' .
                 quotemeta($self->{'displayName'});

   my $result = $self->{stafHelper}->STAFSyncProcess($hostObj->{'hostIP'},
                                                     $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to execute command $command");
      $vdLogger->Debug("Error:" . Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($result->{stdout} =~ /(\d+)\s/) {
      return $1;
   } else {
      $vdLogger->Error("Failed to find world id of $self->{'displayName'}");
      $vdLogger->Debug("Error: " . Dumper($result));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetNetworkPortsInfo --
#     Method to get information about the network ports on the VM
#
# Input:
#     None
#
# Results:
#     Reference to a hash of hash with following keys:
#     {
#        <macX> => {
#           'Port ID'         => <>,
#           'vSwitch'         => <>,
#           'Portgroup'       => <>,
#           'DVPort ID'       => <>,
#           'MAC Address'     => <>,
#           'IP Address'      => <>,
#           'Team Uplink'     => <>,
#           'Uplink Port ID'  => <>,
#           'Active Filters'  => <>
#        },
#        <macY> => {
#        },
#     }   ;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetNetworkPortsInfo
{
   my $self = shift;
   my $hostObj  = $self->{'hostObj'};
   my $worldId = $self->GetWorldID();
   if ($worldId eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $command = 'esxcli network vm port list -w ' . $worldId;
   my $result = $self->{stafHelper}->STAFSyncProcess($hostObj->{'hostIP'},
                                                     $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to execute command $command");
      $vdLogger->Debug("Error:" . Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $data = $result->{stdout};
   my @temp = split(/\n\n/, $data);

   my $portInfoHash = {};
   foreach my $portInfo (@temp) {
      my $mac = undef;
         if ($portInfo =~ /MAC Address:\s(.*)/i) {
            $mac = $1;
         }
         if (not defined $mac) {
            next;
         }
      my @portDetails = split(/\n/, $portInfo);
      foreach my $item (@portDetails) {
         my ($key, $value) = split(/:\s/, $item);
         $key =~ s/^\s+//;
         $portInfoHash->{$mac}{$key} = $value;
      }
   }
   return $portInfoHash;
}

########################################################################
#
# InitializeVnicInterface --
#      Initilize the vnic with interface, controlIP and driver name
#
# Input:
#      vnicObjects - array of vnic objects
#
# Results:
#     SUCCESS, when the controlip, interface and driver have been set
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub InitializeVnicInterface
{
   my $self     = shift;
   my $vnicObjects = shift;
   my $managementPortgroup = shift;
   my $result   = undef;
   my $currentMAC;

   my @newObjects;
   foreach my $vnicObj (@$vnicObjects) {
      if (not defined $vnicObj->{'interface'}) {
         push(@newObjects, $vnicObj);
      }
   }

   # nothind to update
   return SUCCESS if (!scalar(@newObjects));

   $vdLogger->Info("Initializing Vnic ");
   # Initialize/Create the Netadapter Objects.
   my $hash = {};
   if ((not defined $self->{vmIP}) && (not defined $self->{'nestedesx'})) {
      $vdLogger->Info("The waitforvndedt ......");
  #    my $result = $self->WaitForVDNet($managementPortgroup);
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to set the vmIP");
         VDSetLastError("ETIMEDOUT");
         return FAILURE;
      }
   }
   $vdLogger->Info("Before get guestip");
   # This fixing for PR 1304957
   my $ip = $self->GetGuestControlIP();
   $self->{vmIP} = $ip;

   $hash->{controlIP} = $self->{vmIP};
   $hash->{vmOpsObj} = $self;

   my @guestAdapters;
   $guestAdapters[0] = FAILURE;
   $vdLogger->Info("Before retry");
   #
   # After hot add, it takes time for the interface to enable inside the
   # guest. Retrying again to handle any delay in hot add. If it takes anything
   # more than this, it could be filed as a bug.
   #
   my $retry = 2;
   while (($guestAdapters[0] eq FAILURE) && ($retry)) {
      $vdLogger->Debug("Discovering adapters on $self->{vmIP}, " .
                       "$retry attempts left");
      $vdLogger->Info("The nestedesx ----------- $hash->{vmOpsObj}->{'nestedesx'}");
      if ((defined ($hash->{vmOpsObj}->{'nestedesx'})) && ($hash->{vmOpsObj}->{'nestedesx'}->{'os'} eq 'VMkernel')) {
         @guestAdapters = VDNetLib::NetAdapter::Vnic::Vnic::GetAllNestedEsxAdapters($hash,
                                                                        "all");
         sleep(10) if ($guestAdapters[0] eq FAILURE);
         $retry--;
      } else {
         @guestAdapters = VDNetLib::NetAdapter::Vnic::Vnic::GetAllAdapters($hash,
                                                                        "all");
         sleep(10) if ($guestAdapters[0] eq FAILURE);
         $retry--;
      }
   }
   if ($guestAdapters[0] eq FAILURE) {
      $vdLogger->Error("Virtual adapter discovery failed on $self->{vmIP}");
      $vdLogger->Debug("Discovered Adapters:\n" . Dumper(\@guestAdapters));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $length = scalar @newObjects;
   $vdLogger->Info("The length of newofbject is $length");
   foreach my $vnicObj (@newObjects) {
      $vdLogger->Info("The vnicObj is : $vnicObj");
      my $inlineVnic = $vnicObj->GetInlineVirtualAdapter();
      if ($vnicObj->{'deviceLabel'} =~ "PCI device") {
         # FPT device doesn't have MAC address
         # get MAC address mapping from PCI ID in vmx
         $currentMAC = $self->GetMACFromPCI($vnicObj->{'pciId'});
         # For main PCI passthrough device, there is no MAC in vmx, get the MAC
         # from physical interface
         if (!$currentMAC) {
            $vdLogger->Debug("Get the mac address $vnicObj->{pfMAC} from the passthrough device.");
            $currentMAC = $vnicObj->{pfMAC};
         }
      } elsif (defined $vnicObj->{macAddress}) {
         $currentMAC =  $vnicObj->{macAddress};
      } else {
         $currentMAC = $inlineVnic->GetMACAddress();
      }
      if (!$currentMAC) {
         $vdLogger->Error("Failed to get current mac address");
         VDSetLastError("EINLINE");
         return FAILURE;
      } else {
         $vdLogger->Debug("Current macAddress is: " . $currentMAC);
      }
      $vdLogger->Debug("Current MAC address is $currentMAC");
      foreach my $adapter (@guestAdapters) {
#         if ((defined ($hash->{vmOpsObj}->{'nestedesx'})) && ($hash->{vmOpsObj}->{'nestedesx'}->{'os'} eq 'VMkernel')) {
 #           if ($adapter->{interface} =~ /vmnic1/i) {
 #                          $vdLogger->Debug("Mapping vmnicfrom $vnicObj->{'deviceLabel'} to $adapter->{interface}");
 #           $vnicObj->SetInterface($adapter->{'interface'});
 #           $vnicObj->SetControlIP($adapter->{controlIP});
 #           $vnicObj->SetMACAddress($adapter->{'macAddress'});
 #           $vnicObj->GetDriverName();
 #           }
 #        } else {
         print "adatpers $adapter, mac $currentMAC";
        # while(my($k,$v)=each(%$adapter)){print"$k--->$v\n";}
         if ($currentMAC =~ /$adapter->{'macAddress'}/i) {
            $vdLogger->Debug("Mapping $vnicObj->{'deviceLabel'} to $adapter->{interface}");
            $vnicObj->SetInterface($adapter->{'interface'});
            $vnicObj->SetControlIP($adapter->{controlIP});
            $vnicObj->SetMACAddress($currentMAC);
            $vnicObj->GetDriverName();
         
            # PR 1393058: EnableDHCP() on newly added vnic
       #     $result = $vnicObj->SetIPv4("dhcp",
       #               VDNetLib::Common::GlobalConfig::DEFAULT_NETMASK);
            if ($result eq FAILURE) {
               $vdLogger->Error("SetIPv4 as dhcp failed in $adapter->{controlIP} " .
                                "$adapter->{interface}:" . Dumper($result));
            }
         }
  #       }
      }
      if (not defined $vnicObj->{interface}) {
         $vdLogger->Error("Failed to find mapping for $currentMAC on " .
                           $self->{vmIP});
         $vdLogger->Info("Adapters list from VM " . Dumper(@guestAdapters));
         VDSetLastError("EOPFAILED");
         #return FAILURE;
      }
   }
   $vdLogger->Debug("Successfully completed the initialization of vnic");
   while(my($k,$v)=each(%$self)){print"vmboj++++++++++++++++++++++_______________+$k--->$v\n";}
   my $hostobject = $self->{hostObj};
   while(my($l,$n)=each(%$hostobject)){print"esxboj_______________+$l--->$n\n";}
   my $util = $hostobject->{esxutil};
#   while(my($l,$n)=each(%$util)){print"util_______________+$l--->$n\n";}
   if ((defined ($hash->{vmOpsObj}->{'nestedesx'})) && ($hash->{vmOpsObj}->{'nestedesx'}->{'os'} eq 'VMkernel')) {
      
   }
   return SUCCESS;
}


########################################################################
#
# InitializeManagementAdapter --
#     Method to get the new ip of conrtol adapter
#
# Input:
#     vnicObj -- control adapter object
#
# Results:
#     ip, successfully get the new ip;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub InitializeManagementAdapter
{
   my $self = shift;
   my $vnicObj = shift;

   if (not defined $vnicObj) {
      $vdLogger->Error("The object of control adapter in not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $ip = FAILURE;
   my $retryTime = 3;
   my $inlineVnic = $vnicObj->GetInlineVirtualAdapter();
   if (not defined $inlineVnic) {
      $vdLogger->Error("Failed to get inline object for conrtoal adapter");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   while (($retryTime > 0) && ($ip eq FAILURE)) {
      my $mac = $inlineVnic->GetMACAddress();
      $vdLogger->Debug("Mac for $self->{vmName} control adapter is :"
                       . Dumper($mac));
      $ip = $self->GetGuestControlIP($mac);
   }
   if ($ip eq FAILURE) {
      $vdLogger->Error("Failed to get the new generated ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $ip;
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
   my $pciId        = undef;
   $vdLogger->Info("The adapter args: $self, $adaptersSpec, $type, $pciId");
   

   my @arrayOfVNicObjects;
   my $hostObj = $self->{'hostObj'};
   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj) {
      $vdLogger->Error("Failed to get inline java object for VM");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   my $parameters = $self->ProcessVirtualAdapterSpec($adaptersSpec);
   $vdLogger->Info("The parameters are: $parameters");
   foreach my $p (@$parameters) {
      $vdLogger->Info("The param is $p");
   }
   my $vnicObjArr = $inlineVMObj->AddVirtualAdapters($parameters, $type, $self);
   if (!$vnicObjArr) {
      $vdLogger->Error("Failed to add ethernet adapters");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   for (my $i = 0; $i< scalar(@$adaptersSpec); $i++) {
     my $spec = $adaptersSpec->[$i];
     while(my($k,$v)=each(%$spec)){$vdLogger->Info("The adapterspec: $k--->$v");}
     my %args;
      # Create vdnet vnic object and store it in array of vnicobjects
      $args{intType}  = "vnic";
      $args{vmOpsObj} = $self;
      $args{pgObj}    = $adaptersSpec->[$i]->{'portgroup'};
      $args{deviceLabel} = $vnicObjArr->[$i]->{'deviceLabel'};
      my $vnicObj = VDNetLib::NetAdapter::Vnic::Vnic->new(%args);
      if ($vnicObj eq "FAILURE") {
         $vdLogger->Error("Failed to initialize vnic obj on VM: $self->{vmx}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      #Pass on the pci id and mac address for mapping
      #between vnic and ethx in InitializeVnicInterface
      if ($parameters->[$i]->{'id'}) {
         $pciId = $hostObj->ConvertPCIIdToDecimal($parameters->[$i]->{'id'});
         if ((defined $pciId) && ($pciId ne FAILURE)){
            $vdLogger->Debug("Pass on the PCI ID $pciId in decimal to vnic");
            $vnicObj->{'pciId'} = $pciId;
         }
      }
      if ($adaptersSpec->[$i]->{'vmnic'}->{'macAddress'}) {
         $vdLogger->Debug("Pass on the MAC address of the physical interface
                           $adaptersSpec->[$i]->{'vmnic'}->{'macAddress'} to vnic");
         $vnicObj->{'pfMAC'} = $adaptersSpec->[$i]->{'vmnic'}->{'macAddress'};
      }
      push @arrayOfVNicObjects, $vnicObj;
   }
   return \@arrayOfVNicObjects;
};


########################################################################
#
# ProcessVirtualAdapterSpec --
#     Method to process virtual adapter spec from user.
#     Converts case and maps vdnet core objects to inline java objects
#
# Input:
#     Reference to an array of hash (refer to AddEthernetAdapters())
#
# Results:
#     Reference to an array of hash
#
# Side effects:
#     None
#
########################################################################

sub ProcessVirtualAdapterSpec
{
   my $self         = shift;
   my $adaptersSpec = shift;
   my $parameters = [];
   my $hostObj = $self->{'hostObj'};
   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj) {
      $vdLogger->Error("Failed to get inline java object for VM");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   for (my $index = 0; $index < scalar(@{$adaptersSpec}); $index++) {
      my $spec = $adaptersSpec->[$index];
      while(my($k,$v)=each(%$spec)){$vdLogger->Info("The adapterp: $k--->$v");}
      $parameters->[$index]->{driver} = $spec->{'driver'};
      if (defined $spec->{'portgroup'}) {
         my $inlinePG = $spec->{'portgroup'}->GetInlinePortgroupObject();
         $parameters->[$index]->{'portgroup'} = $inlinePG;
      }
      if (defined $spec->{'network'}) {
         my $inlinePG = VDNetLib::InlineJava::Portgroup::Portgroup->new(
                                                'name' => $spec->{'network'});
         $inlinePG->{type} = "standard";
         $parameters->[$index]->{'portgroup'} = $inlinePG;
      }
      if (defined $spec->{'vmnic'}) {
         if ($self->SetPCIInfo($spec,$parameters->[$index]) ne SUCCESS) {
            $vdLogger->Error("Failed to set PCI information");
            return FAILURE;
         }
      }
      $parameters->[$index]->{'connected'} = $spec->{'connected'};
      $parameters->[$index]->{'startConnected'} = $spec->{'startconnected'};
      $parameters->[$index]->{'allowGuestControl'} =
         $spec->{'allowguestcontrol'};
      $parameters->[$index]->{'reservation'} = $spec->{'reservation'};
      $parameters->[$index]->{'limit'} = $spec->{'limit'};
      $parameters->[$index]->{'sharesLevel'} = $spec->{'shareslevel'};
      $parameters->[$index]->{'shares'} = $spec->{'shares'};
      $parameters->[$index]->{'macaddress'} = $spec->{'macaddress'};
      $parameters->[$index]->{'virtualfunction'} = $spec->{'virtualfunction'};
   }
   return $parameters;
};


########################################################################
#
# SetPCIInfo --
#     Method to set PCI deviceId,deviceName,vendorId,SystemId.
#     Used by ProcessVirtualAdapterSpec.
#
# Input:
#     spec - Reference to the adapter specification
#     parameter - Reference to the parameter to be filled in
#
# Results:
#     SUCCESS
#     FAILURE, in case of any error;
#
# Side effects:
#     The fields of the parameter are filled in
#
########################################################################

sub SetPCIInfo
{
   my $self = shift;
   my $spec = shift;
   my $parameter = shift;
   my $bdfInHex;
   my $pciInfo;
   my $pciId;

   if ((not defined $spec) || (not defined $parameter)) {
      $vdLogger->Error("Parameters not passed in");
      return FAILURE;
   }
   my $hostObj = $self->{'hostObj'};
   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj) {
      $vdLogger->Error("Failed to get inline java object for VM");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   if (defined $spec->{'virtualfunction'}) {
      #For sub PCI device,get bdf id from "esxcli network sriovnic vf list"
      $bdfInHex = $self->GetBDFForVf($spec->{'vmnic'},$spec->{'virtualfunction'});
      if ($bdfInHex eq FAILURE) {
         $vdLogger->Error("Unable to get a VF $spec->{'virtualfunction'}");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      } else {
         $pciInfo = $spec->{'vmnic'}->GetPCIInfo($bdfInHex);
      }
   } else {
     $pciInfo = $spec->{'vmnic'}->GetPCIInfo();
   }
   if ($pciInfo eq FAILURE) {
         $vdLogger->Error("Failed to get PCI info");
         VDSetLastError("EOPFAILED");
         return FAILURE;
   }
   $parameter->{'deviceName'} = $pciInfo->{'name'};
   my @id = split(/:/, $pciInfo->{'vendorDevId'});
   $parameter->{'deviceId'} = $id[1];
   $parameter->{'vendorId'} = $id[0];
   $vdLogger->Debug("BDF is $pciInfo->{'bdf'}");
   $pciId = $hostObj->ConvertBDFtoPCIId($pciInfo->{'bdf'});
   if ((defined $pciId) && ($pciId ne FAILURE))  {
      $vdLogger->Debug("Set the PCI ID to $pciId");
      $parameter->{'id'} = $pciId;
   } else {
      $vdLogger->ERROR("Can't get the PCI ID");
      return FAILURE;
   }
   if ((defined $spec->{'virtualfunction'}) || ($spec->{'driver'} eq 'sriov')) {
      $vdLogger->Debug("The systemId for vf/sriov device is BYPASS");
      $parameter->{'systemId'} = 'BYPASS';
   } else {
      #For FPT device
      $vdLogger->Debug("For FPT device,get the systemId from PCI ID $pciId");
      my $systemId = $inlineVMObj->GetSystemId($pciId);
      if ($systemId) {
         $parameter->{'systemId'} = $systemId;
      } else {
         $vdLogger->ERROR("Unable to get systemId");
         return FAILURE;
      }
   }
   return SUCCESS;
};


########################################################################
#
# GetBDFForVf --
#     Method to get BDF for PCI virtual interface.
#     Used by SetPCIInfo.
#
# Input:
#     Reference to the physical interface
#     The PCI virtual interface number
#
# Results:
#     return bdf id in hex format
#     FAILURE, in case of any error;
#
# Side effects:
#     The fields of the parameter are filled in
#
########################################################################

sub GetBDFForVf
{
   my $self = shift;
   my $vmnic = shift;
   my $virtualfunction = shift;
   my $pciId;
   my $bdfInHex;

   my $bdfInDecimal = $self->GetAvailableVirtualFunction($vmnic,
                                                         $virtualfunction);
   if ($bdfInDecimal eq FAILURE) {
      $vdLogger->Error("Unable to get a free VF");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $vdLogger->Debug("Get a available vf $virtualfunction,
                              bdf is $bdfInDecimal");
      if ($bdfInDecimal =~ /(\d+):(\d+)\.(\d)/) {
         #save the bdfInHex to be used in GetPCIInfo
         $bdfInHex = sprintf("%02x:%02x.%x",$1,$2,$3);
         $vdLogger->Debug("Convert the bdf to hex $bdfInHex");
      } else {
         $vdLogger->Error("Failed convert the bdf from decimal to hex");
         VDSetLastError("EOPFAILED");
         return FAILURE;
     }
  }
  return $bdfInHex;
}

########################################################################
#
# GetInlineVMObject --
#     Method to get inline VM Object
#
# Input:
#     None
#
# Results:
#     Blessed reference to VDNetLib::InlineJava::VM
#
# Side effects:
#     None
#
########################################################################

sub GetInlineVMObject
{
   my $self = shift;
   return VDNetLib::InlineJava::VM->new('host' => $self->{'host'},
                                        'vmName' => $self->{'vmName'},
                                        'user'   => $self->{'user'},
                                        'password' => $self->{'password'},
                                      );
}


########################################################################
#
# RemoveVirtualAdapters --
#     Method to remove virtual adapters
#
# Input:
#     adapters: reference to VDNetLib::NetAdapter::Vnic
#     (optional, if not specified all test adapters will be deleted)
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
   my $self     = shift;
   my $adapters = shift;
   my $type     = shift;
   my $includeControlAdapter = shift;

   my @adaptersSpec;
   if (defined $adapters) {
      foreach my $vnicObj (@$adapters) {
         my $inlineVnic = $vnicObj->GetInlineVirtualAdapter();
         my $spec = $inlineVnic->GetEthernetCardSpecFromLabel();
         if (!$spec) {
            $vdLogger->Error("Failed to find spec for label " .
                             $inlineVnic->{deviceLable});
            VDSetLastError("EINLINE");
            return FAILURE;
         }
         push(@adaptersSpec, $spec);
      }
   }
   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj) {
      $vdLogger->Error("Inline VM object creation returned failure");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (!$inlineVMObj->RemoveVirtualAdapters(\@adaptersSpec, $type,
                                            $includeControlAdapter)) {
      $vdLogger->Error("Failed to remove adapters");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
};


########################################################################
#
# PerformToolsUpgrade --
#       Method to check the version of tools and upgrade tools based on
#       preference given by user. By default tools iso corresponding to
#       that of host build is used. Users can also provide their own ISO
#       Tools server is mounted, symlinks are created and Upgrade tools
#       command is fired in staf sdk to achieve this.
#
# Input:
#       tools, VMtool version or default;
#
# Results:
#       returns SUCCESS if tools upgrade is launched successfully
#       returns FAILURE, if failed.
#
# Side effects:
#       Yes. Saw toolsVersionStatus = <unset> on some VMs. But not able
#       to reproduce it while testing. Upgrade can fail for multiple
#       reasons
#
########################################################################

sub PerformToolsUpgrade
{
   my $self = shift;
   my $tools = shift || "default";
   #
   # For this machine first check the tools version.
   #
   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj) {
      $vdLogger->Error("Failed to get inline java object for VM");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   my $toolsInfo = $inlineVMObj->GetToolsInfo($self->{'vmName'});
   if (!$toolsInfo) {
      $vdLogger->Error("Failed to get VMTool info for $self->{'vmName'}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   my $ver = VDNetLib::Common::Utilities::VMwareToolsVIMCMDVersion(
                               $toolsInfo->{'toolsVersion'});
   $vdLogger->Info("Current VMtools version in $self->{'vmIP'} is $ver");
   if ($toolsInfo->{'toolsRunningStatus'} =~ /guestToolsCurrent/i) {
      $vdLogger->Info("VMTool version of $self->{'vmName'} is the latest, no " .
                      "need to upgrade again.");
      return SUCCESS;
   }

   my $isoName = $self->GetToolsImageName();
   if ($isoName eq FAILURE) {
      $vdLogger->Error("Failed to get VMTool iso name for $self->{os}");
      VDSetLastError("ENOTSUP");
#      return FAILURE;
   }

   if (!$inlineVMObj->UpgradeTools()) {
      $vdLogger->Error("Can not Upgrade vmtools");
      VDSetLastError("EINLINE");
#      return FAILURE;
   }
   $vdLogger->Info("Upgrade tools Successfully");

   $toolsInfo = $inlineVMObj->GetToolsInfo($self->{'vmName'});
   if (!$toolsInfo) {
      $vdLogger->Error("Failed to get VMTool info for $self->{'vmName'}");
      VDSetLastError("EINLINE");
 #     return FAILURE;
   }

   $ver = VDNetLib::Common::Utilities::VMwareToolsVIMCMDVersion(
                                         $toolsInfo->{'toolsVersion'});
   $vdLogger->Info("After upgrade, VMtools version in $self->{'vmIP'}" .
                   " is $ver");
   if ($toolsInfo->{'toolsRunningStatus'} =~ /guestToolsCurrent/i) {
      $vdLogger->Info("VMTool upgrade for $self->{'vmName'} was successfully " .
                      "completed.");
      return SUCCESS;
   }

   $vdLogger->Error("Failed to upgrade VMTools for VM $self->{'vmName'}.");
   VDSetLastError(VDGetLastError());
  # return FAILURE;
}


########################################################################
#
# PerformToolsUpgradeLegacy --
#       Method to check the version of tools and upgrade tools based on
#       preference given by user. By default tools iso corresponding to
#       that of host build is used. Users can also provide their own ISO
#       Tools server is mounted, symlinks are created and Upgrade tools
#       command is fired in staf sdk to achieve this.
#
# Input:
#       tools, VMtool version or default;
#
# Results:
#       returns SUCCESS if tools upgrade is launched successfully
#       returns FAILURE, if failed.
#
# Side effects:
#       Yes. Saw toolsVersionStatus = <unset> on some VMs. But not able
#       to reproduce it while testing. Upgrade can fail for multiple
#       reasons
#
########################################################################

sub PerformToolsUpgradeLegacy
{
   my $self = shift;
   my $tools = shift || "default";
   my $hostObj = $self->{'hostObj'};

   #
   # For this machine first check the tools version.
   #
   my $result = $self->VMOpsGetToolsStatus();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get VMware Tools Status");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # If user gives path to iso in <tools> option then
   # perform upgrade with it irrespective of current tools status/version.
   # If upgrade is with default build then no need to upgrade if GetToolsStatus
   # says 'guestToolsCurrent'.
   # If GetToolsStatus says 1 = 'ToolsNeedUpgrade' then of course
   # upgrade tools.

   if ($result == 0) {
      # Tools is already uptodate as given by VMOpsGetToolsStatus()
      $self->{toolsUpgrade}{uptodate} = 1;
      return SUCCESS;
   }

   $result = $self->{stafHelper}->DirExists($hostObj->{hostIP},
                                            "/productLocker/vmtools");
   if (($tools eq "default") && ($result == 1)) {
      $vdLogger->Info("Found and using local VMTool ISO for VMTool upgrade");
   } else {
      $vdLogger->Info("Preparing to use version $tools for VMTools upgrade");
      if ($self->SetupToolsUpgrade($tools) eq "FAILURE") {
         $vdLogger->Error("Failed to configure host $hostObj->{hostIP} for" .
                          " vmtools upgrade");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   # VM staf service command UPGRADETOOLS is a blocking call. Thus what we do is
   # generate the staf cmd for upgrading tools and wrap it into another
   # async staf command and launch it.
   my $vmName = $self->{'vmName'};
   my $vmStafAnchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $command = "UPGRADETOOLS ANCHOR $vmStafAnchor VM $vmName WAITFORTOOLS";

   #
   # If the OS is linux and kernel is greater than 2.6.32-rc5 then it
   # will have inbox vmxnet3 driver. That is why we pass installeroptions
   # to clobber inboxed vmxnet3 driver and replace it with vmxnet3
   # from this vmware tools package.
   #
   if ($self->{'os'} =~ /linux/i) {
      $command = $command . " INSTALLEROPTIONS --clobber-kernel-modules=vmxnet3";
   }

   # Get the name of the file which will contain staf upgrade async launch
   # information.
   $vdLogger->{logFileName} =~ /(.*)\/testcase.log/;
   my $toolsStatus = $1;
   if ($toolsStatus =~ /\/$/) {
      $toolsStatus = $toolsStatus . $vmName;
   } else {
      $toolsStatus = $toolsStatus . "/" . $vmName;
   }
   $toolsStatus = $toolsStatus . "-vmware-tools-upgrade-staf.log";
   $self->{toolsUpgrade}{file} = $toolsStatus;

   # Launch the staf async process which is a wrapper for
   # STAF local vm UPGRADETOOLS ANCHOR.... command
   $command = "STAF local VM " . $command;
   open FILE, ">" ,$toolsStatus;
   print FILE "$command\n\n";
   close FILE;
   $vdLogger->Info("Upgrading VMware Tools on $vmName.");
   $result = $self->{stafHelper}->STAFAsyncProcess("local",
                                                      $command,
                                                      $toolsStatus);
   if ($result->{rc} && $result->{exitCode}) {
      $vdLogger->Error("Unalbe to launch local command:".
                       $command);
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Store the handle and pid of the wrapper staf command.
   $self->{toolsUpgrade}{handle} = $result->{handle};
   $result = $self->{stafHelper}->GetProcessInfo("local", $result->{handle});
   if ($result->{rc}) {
      if(defined $result->{endTimestamp}) {
         $vdLogger->Error("Unalbe to start Tools Upgrade on $vmName");
      }
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{toolsUpgrade}{pid} = $result->{pid};
   return SUCCESS;
}


########################################################################
#
# SetupToolsUpgrade --
#       Method to mount given location for vmtools upgrade
#
# Input:
#       $testbed, reference to testbed object;
#
# Results:
#       returns SUCCESS if given location successfully mounted;
#       returns FAILURE, if failed.
#
# Side effects:
#
########################################################################

sub SetupToolsUpgrade
{
   my $self = shift;
   my $tools = shift;

   my $hostObj = $self->{'hostObj'};
   my ($toolsServer, $toolsShare, $toolsPath, $result);
   my $esxHostIp = $hostObj->{'hostIP'};

   # If <tools> is specified under vm options then
   # irrespective of skipsetup flag we do tools upgrade.
   # <tools> is usually specified to perform a custom *.iso tools upgrade
   # One can point to sandbox tools build which hash isoimages
   # If <tools> is not specified and skipsetup is false then
   # upgrade of tools will be done with default host build number.

   my $isHostReadyForToolUpgrade = grep (/$esxHostIp/, @$hostsReadyForToolUpgrade);
   if ( $isHostReadyForToolUpgrade != 0 )  {
      return SUCCESS;
   }

   my $toolsBuild = $self->{tools};
   if (defined $toolsBuild) {
      #
      # we will perform upgrade with the custom iso in <tools>
      # Extract the custom iso location given by user.
      my $buildInfo;
      if ($toolsBuild =~ /:/) {
         ($toolsServer,$toolsShare) = split(/:/, $self->{tools});
      } elsif ($toolsBuild =~ /\d+/) {
         $buildInfo =
            VDNetLib::Common::FindBuildInfo::GetBuildInfo($toolsBuild);
         if ($buildInfo eq FAILURE) {
            $vdLogger->Error("Failed to find build information of " .
                             $toolsBuild);
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         my $buildTree = $buildInfo->{'buildtree'};
         my @temp = split(/\//, $buildTree);
         $toolsServer = "build-" . $temp[2];
         $toolsShare = $buildTree;
         $toolsShare =~ s/$temp[1]\///;
         $toolsShare = $toolsShare . '/publish';
      }
      if ((not defined $toolsServer) || (not defined $toolsShare)) {
         $vdLogger->Error("ToolServer and/or ToolShare not defined");
         $vdLogger->Debug("BuildInfo:" . Dumper($buildInfo));
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      #
      # For isoimages, use either from VMTREE or user defined images depending
      # upon what is given at command line
      # Mounting the Tool Server on esx for iso images to be available on it.
      #
      # if users provided custom build for tools at command line, then mount
      # that server and share
      #
      $vdLogger->Info("Mounting " . $toolsServer . ":" . $toolsShare .
                      " as vmware-tools on $esxHostIp");
      $result = $hostObj->{esxutil}->MountDatastore($esxHostIp,
                                                    $toolsServer,
                                                    $toolsShare,
                                                    "vmware-tools");
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to mount");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $toolsPath = VMFS_BASE_PATH . "$result";
   }

   #
   # VMTREE is needed in any case, so getting that for the given host
   #
   my $toolBuild = "default";
   if ($tools =~ /(ob|sb)-(\d+)/i) {
      $toolBuild = $2;
   }

   my $vmtree = $hostObj->GetVMTree($toolBuild);
   if ($vmtree eq FAILURE) {
      $vdLogger->Error("Failed to get VMTREE on $esxHostIp:");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (not defined $toolsPath) {
      # for most sandbox/official builds, we look here
      $toolsPath = $vmtree . "/../publish/pxe";
      $result = $self->{stafHelper}->DirExists($esxHostIp,
                                               $toolsPath);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } elsif (!$result) {
         #for developer builds, it might be here
         $toolsPath = $vmtree . "/build/esx/" . $hostObj->{buildType} .
                              "/pxe";
         $result = $self->{stafHelper}->DirExists($esxHostIp,
                                                  $toolsPath);
         if ($result eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         if (!$result) {
            $vdLogger->Error("Failed to find PXE deliverables in VMTREE");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }

      $toolsPath = VDNetLib::Common::Utilities::ReadLink($toolsPath,
                                                         $esxHostIp,
                                                         $self->{stafHelper});
      if ($toolsPath eq FAILURE) {
         $vdLogger->Info("Failed to find link to VMtools");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      #
      # Create symlinks so that Guest looks into this folder for picking up
      # tools iso images
      # First find the UUID of vmware-tools storage, then use this UUID for
      # creating symlinks
      #
      $toolsPath = VDNetLib::Common::Utilities::ReadLink($toolsPath,
                                                         $esxHostIp,
                                                         $self->{stafHelper});
      if ($toolsPath eq FAILURE) {
         $vdLogger->Info("Failed to find UUID of vmware-tools storage");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   chomp($toolsPath);
   $vdLogger->Debug("VMTools ISO image path: $toolsPath");

   #
   # Depending on the guest OS, the regex pattern of iso filename is
   # is generated and searched under the toolspath
   #
   my (@lines, $line, $isoFile);
   $isoFile = "";
   my $guestOS =$self->{os};
   if ($guestOS =~ /lin/i) {
      $isoFile = "linux";
   } elsif ($guestOS =~ /^win/i) {
      $isoFile = "windows";
   } elsif ($guestOS =~ /darwin|mac/i) {
      $isoFile = "darwin";
   } elsif ($guestOS =~ /bsd/i) {
      $isoFile = "freebsd";
   } else {
      $vdLogger->Error("Unsupported guest type: $guestOS");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   #
   # Finding the folder on this storage which contains iso images
   #
   # The iso file pattern is *<guestType>*.iso, which will return both
   # linux.iso and  VMware-tools-linux-X.X.X-XXXXXX.iso
   #
   my $command = "find $toolsPath -iname \"*.iso\" -maxdepth 5";
   $result  = $self->{stafHelper}->STAFSyncProcess($esxHostIp, $command);
   if (($result->{rc} != 0)) {
      $vdLogger->Error("Failed to execute $command on $esxHostIp:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if($result->{stdout} !~ /\.iso/i) {
      $vdLogger->Warn("Wrong Symlink? build backedup to tape?");
      $vdLogger->Error("ISO files missing for tools upgrade. Command:".
                       "$command Host:$esxHostIp Result:". Dumper($result));
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   my ($sourceFile, $symlinkName, $dstDir);
   my $isoPath;
   my $fullISOFileName;
   @lines = split('\n',$result->{stdout});
   foreach $line (@lines) {
      if ($line =~ /visor/i) {
         next;
      }

      if($line =~ /(.*)\/(.*$isoFile.*\.iso)/i) {
         my $sourceDir = $1;
         my $isoImage = $2;

         my $destVMToolDir = TMP_VMTOOLS_DIR . "\/" . $toolBuild;
         my $newline = $destVMToolDir . "\/" . $isoImage;
         # Create TMP_VMTOOLS_DIR to download ISO images;
         my $isToolReady = $self->{stafHelper}->IsFile($esxHostIp, $newline);
         if ((!$isToolReady) || ($toolBuild =~ /default/i)) {
             if ($self->{stafHelper}->STAFFSCreateDir($destVMToolDir,
                                                      $esxHostIp)) {
                $vdLogger->Error("Failed to create $destVMToolDir");
                 VDSetLastError(VDGetLastError());
                 return FAILURE;
             }

             # Download ISO isoimage from NFS share;
             if ($self->{stafHelper}->STAFFSCopyFile($line,
                                                     $newline,
                                                     $esxHostIp,
                                                     $esxHostIp) eq FAILURE) {
                $vdLogger->Error("Failed to download ISO image $line to local".
                                 " datastore.");
                VDSetLastError(VDGetLastError());
                return FAILURE;
             }
         }

         # Copy downloaded ISO images to parent directory;
         if ($self->{stafHelper}->STAFFSCopyFile($newline,
                                                 TMP_VMTOOLS_DIR,
                                                 $esxHostIp,
                                                 $esxHostIp) eq FAILURE) {
            $vdLogger->Error("Failed to copy ISO images to parent directory.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $newline = TMP_VMTOOLS_DIR . "\/" . $isoImage;
         $newline =~ /(.*)\/(.*)\.iso/i;
         my $tempISOFile = $2;
         if ($tempISOFile eq "$isoFile") {
            #
            # If the iso images available in the current directory match the
            # expected iso image, say, linux.iso or windows.iso,
            # symlink the entire directory (this is current setting of
            # /usr/lib/vmware/isoimages/ which is a symlink to a directory
            # that contains all iso images for tools).
            #
            $sourceFile = $1;
            $symlinkName = 'isoimages';
            $dstDir = VMWARE_TOOLS_BASE_PATH;
         } elsif ($tempISOFile =~ /$isoFile.*/) {
            #
            # Assume this is official or sandbox tools build (not esx build)
            # and symlink to the file specifically. For example,
            # VMware-tools-linux-8.9.0-XXXXX.iso --> linux.iso
            #
            $sourceFile = $line;
            $symlinkName = $isoFile . '.iso';
            $dstDir = VMWARE_TOOLS_BASE_PATH . 'isoimages';
         }
         last;
      }
   }

   if (not defined $sourceFile) {
      $vdLogger->Error("Failed to find VMware Tools files for upgrading. ".
                       "ISO:$isoFile");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Creating Symlink for isoimages
   #
   if ($sourceFile =~ /\.iso$/) {
      if ((not defined $dstDir) || ($dstDir eq '/')) {
         $vdLogger->Error("Attempting to remove something under root system");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      # Remove the old symlink before creating new one.
      $command = "rm -rf '$dstDir'; rm -rf '/productLocker'; " .
                 "mkdir -p '$dstDir'";
      $result = $self->{stafHelper}->STAFSyncProcess($esxHostIp, $command);
      if ($result->{rc} && $result->{exitCode}) {
         $vdLogger->Warn("Staf error while removing symlink on $esxHostIp:".
                         $result->{result});
      }
   }
   $isoFile =~ s/\n//g; # remove any new line character
   $vdLogger->Info("Using VMware Tools ISO image from:". $sourceFile);
   $result = VDNetLib::Common::Utilities::UpdateSymlink($esxHostIp,
                                                     $sourceFile,
                                                     $dstDir,
                                                     $symlinkName,
                                                     $self->{stafHelper});
   if ($result eq FAILURE) {
       $vdLogger->Error("Failed to get guest information in ".
                        "PerformToolsUpgrade");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   #
   # In addition to updating files under /usr/lib/vmware,
   # /productLocker should also be pointing to the tools images
   #
   my @temp = split(/\//, $sourceFile);
   pop(@temp);
   $sourceFile = join("\/", @temp);
   $result = VDNetLib::Common::Utilities::UpdateSymlink($esxHostIp,
                                                        $sourceFile,
                                                        "/",
                                                        "productLocker",
                                                        $self->{stafHelper});
   if ($result eq FAILURE) {
       $vdLogger->Error("Failed to update /productLocker file");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   #
   # In addition to iso images, create symlinks for .sig files.
   # Signature check is skipped for obj builds but required for other build
   # types
   #
   if ($sourceFile =~ /\.iso$/) {
      $sourceFile = $sourceFile . '.sig';
      $symlinkName = $isoFile . '.iso.sig';
      $result = VDNetLib::Common::Utilities::UpdateSymlink($esxHostIp,
                                                        $sourceFile,
                                                        $dstDir,
                                                        $symlinkName,
                                                        $self->{stafHelper});
      if ($result eq FAILURE) {
          $vdLogger->Error("Failed to update /productLocker file");
          VDSetLastError(VDGetLastError());
          return FAILURE;
      }
   }

   push @$hostsReadyForToolUpgrade, $esxHostIp;
   return SUCCESS;
}


########################################################################
#
# WaitForToolsUpgrade --
#       Method to wait on tool's upgrade async process to finish on a
#       given machine
#
# Input:
#       $testbed, reference to testbed object;
#
# Results:
#       returns SUCCESS if tools versions is uptodate
#       returns FAILURE, if failed.
#
# Side effects:
#       none.
#
########################################################################

sub WaitForToolsUpgrade
{
   my $self = shift;

   my $toolsUpgradeInfo = $self->{toolsUpgrade};
   if (not defined $toolsUpgradeInfo) {
      $vdLogger->Error("VMware Tools Upgrade STAFAsyncProcess info is missing");
      VDSetLastError("EFAILED");
      return FAILURE;
   } elsif ($toolsUpgradeInfo->{uptodate}) {
      delete $self->{toolsUpgrade};
      return SUCCESS;
   }

   my $processLog = $toolsUpgradeInfo->{file};
   my $processHandle = $toolsUpgradeInfo->{handle};
   if ((not defined $processHandle) || (not defined $processLog)) {
      $vdLogger->Error("VMware Tools Upgrade STAFAsyncProcess handle ".
                       "or stdout File is missing" . Dumper($toolsUpgradeInfo));
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   # Get all the informatiion about that process. Wait and keep Reading till
   # the process gets endtimestamp
   my $result;
   $vdLogger->Info("Waiting for VMware Tools Upgrade to finish on $self->{vmIP}...");
   # On a Windows VM it should take a maximum of 30 min to upgrade
   # in a worst case scenario, thus keeping 30 min as default wait time.
   my $startTime = time();
   my $timeout = 30 * 60; # converting it to sec.
   do {
      sleep(1);
      $timeout--;
      `grep -ri Response $processLog`;
   } while($timeout > 0 && $? != 0);

   if ($timeout == 0) {
       $vdLogger->Error("Hit Timeout=30 min for VMware Tools STAF Async".
                        " call to finish. Log:". $processLog);
       $result = $self->{stafHelper}->GetProcessInfo("local", $processHandle);
       $vdLogger->Error("VMware Tools Upgrade STAFAsyncProcess Info:".
			                      Dumper($result));
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   #
   # Immediately after tools installation finishes, the VM's file-system
   # gets frozen for 3-4 seconds. Hence if any STAF command is issued to
   # the VM in that state it would return the failure. Below function is
   # to make sure we proceed after the vm resumes normally.
   #
   if ($self->{stafHelper}->WaitForSTAF($self->{vmIP}) eq FAILURE) {
      $vdLogger->Error("STAF not running on $self->{vmIP}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # We noticed that if immediately after VMOpsUpgradeTools() we
   # called VMOpsGetToolsStatus() it was returning tools
   # version as 0.0.0 because tools service was not stable yet.
   # Even waiting on staf didnt fix the purpose. So workaround is to
   # do 'vmware-toolbox-cmd --version' on it. It will return only after
   # tools service stabilizes.
   #
   if ($self->{os} =~ /linux/i) {
      # Because vmxnet3 is an inboxed driver, even after upgrading tools with
      # --clobber it will not load the vmxnet3 module on its own. Thus we do
      # it explicitly.
      my $command = "vmware-toolbox-cmd --version; ".
		    "modprobe -r vmxnet3; modprobe vmxnet3";
      $result = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $command on $self->{vmIP}:"
                          . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Trace("tools version returned by guest:" . $result->{stdout});
   } elsif ($self->{os} =~ /^win/i) {
      my $command = '%ProgramFiles%\VMware\VMware Tools\VMwareToolboxCmd.exe"' .
                    ' --version';
      $result = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $command on $self->{vmIP}:"
                          . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Trace("tools version returned by guest:" . $result->{stdout});
   }

   #
   # Checking the status of VMware tools after upgrading.
   # It takes a some time for the tools status to reflect the correct value
   # after the tools upgrade. Giving few secs before bailing out.
   #

   $startTime = time();
   $timeout = GUEST_BOOTTIME;
   while ($timeout && $startTime + $timeout > time()) {
      $result = $self->VMOpsGetToolsStatus();
      if ((!$result) && ($result ne FAILURE)) {
         # Cleanup the var and log file before exiting from the method
         `rm -rf $processLog`;
         delete $self->{toolsUpgrade};
         return SUCCESS;
      } else {
         sleep GUESTIP_SLEEPTIME;
      }
   }
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


########################################################################
#
# UpdateVMExtraConfig --
#     Method to update all extra configurations of VMX
#
# Input:
#     extraConfig: reference to hash with keys as config option and
#                  values
#
# Results:
#     SUCCESS, if vmx updated with given config options;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub UpdateVMExtraConfig
{
   my $self        = shift;
   my $extraConfig = shift;
   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj->UpdateVMExtraConfig($extraConfig)) {
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# UpdateVCUUID --
#     Method to update VCUUID of VM
#
# Input:
#     vcUUID: RFC 4122 based UUID
#
# Results:
#     SUCCESS, if UUID updated successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub UpdateVCUUID
{
   my $self    = shift;
   my $vcUUID  = shift;
   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj->UpdateVCUUID($vcUUID)) {
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;

}


########################################################################
#
# UpgradeVM --
#     Method to upgrade VM to given version
#
# Input:
#     version: version number
#
# Results:
#     SUCCESS, if the VM version is upgraded successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub UpgradeVM
{
   my $self    = shift;
   my $version = shift;
   #
   # Using host anchor always irrespective of whether host is added to
   # VC or not. This is workaround for PR1023135
   #
   my $inlineVMObj = VDNetLib::InlineJava::VM->new(
                                 'host'     => $self->{hostObj}{hostIP},
                                 'vmName'   => $self->{vmName},
                                 'user'     => $self->{hostObj}{userid},
                                 'password' => $self->{hostObj}{sshPassword});
   if (!$inlineVMObj->UpgradeVM($version)) {
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
};


###############################################################################
#
# VMotion --
#      This method will vmotion this vm to destination ESX host.
#
# Input:
#      vmotion type         -  whether vmotion is a roundtrip or oneway vmotion
#      DstHostObj           -  Destination Host object refrence
#      Priority             -  Default is high (optional)
#      StayTime             -  if do a round trip vmotion, vm will stay at the
#                              destination esx host for a while.
#
# Results:
#      Returns "SUCCESS", if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub VMotion
{
   my $self       = shift;
   my %args       = @_;
   my $type       = $args{vmotion};
   my $dsthostObj = $args{dsthost};
   my $priority   = $args{priority};
   my $staytime   = $args{staytime};
   my $anchor     = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $result;

   if ($type =~ /storage/i) {
      # Covers both 'storage' and 'hostandstorage' together, vmotion scenarios
      return $self->VMotionVIMAPI(%args);
   }
   my $inlineVMObj = $self->GetInlineVMObject();
   if (defined $inlineVMObj && defined $type && $type =~ /xvmotion/i) {
      return $inlineVMObj->Xvmotion(%args);
   }

   my $srchostObj = $self->{'hostObj'};
   my $proxy      = $srchostObj->{vcObj}{proxy};

   $dsthostObj = $dsthostObj->[0];
   if (not defined $dsthostObj) {
      $vdLogger->Error("vMotion destination host object not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $type) {
      $type     = "roundtrip";
   }
   if (not defined $priority) {
      $priority = "high";
   }
   if (not defined $staytime) {
      $staytime = 0;
   }
   my $vmname = $self->{'displayName'};

   if (not defined $vmname){
      $vdLogger->Error("vMotion failed : can't get VM display name");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $result = $self->VMOpsConfigureVMotion();
   if ($result ne SUCCESS) {
      $vdLogger->Error("Not able to configure $vmname for VMotion");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $srchostip = $srchostObj->{hostIP};
   my $dsthostip = $dsthostObj->{hostIP};
   $vdLogger->Debug("vMotion: $vmname to $dsthostip");
   my $command = " VMOTION \"$vmname\" ANCHOR $anchor DSTHOST ".
                 "$dsthostip PRIORITY $priority";
   $vdLogger->Debug("Run command : $command");
   $result = $self->{stafHelper}->STAFSubmitVMCommand($proxy, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to vMotion failed:" .Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("vMotion : $vmname has been moved to $dsthostip... ");
   if ($type =~ /roundtrip/i) {
      $vdLogger->Info("$vmname stay at $dsthostip for $staytime seconds... ");
      sleep $staytime;
      #
      # Do a round trip vMotion in case data
      #inconsistent in $srchostip and $dsthostip
      #
      $command = " VMOTION \"$vmname\" ANCHOR  $anchor DSTHOST ".
                 "$srchostip PRIORITY $priority";
      $vdLogger->Debug("Run command : $command");
      $result = $self->{stafHelper}->STAFSubmitVMCommand($proxy, $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("STAF command to vMotion failed:" .Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Info("Roundtrip vMotion : $vmname has been moved back to $srchostip... ");
   } else {
      $vdLogger->Info("One way vMotion : $vmname will stay at $dsthostip... ");
   }

   return SUCCESS;
}


###############################################################################
#
# ReserveMemory --
#      This method will reserve memory for a VM
#
# Input:
#      size         -  size of memory to be reserverd
#
# Results:
#      Returns "SUCCESS", if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      vmx get changed
#
###############################################################################

sub ReserveMemory
{
   my $self   = shift;
   my $size   = shift || 'max';
   my $vmName = $self->{'vmName'};
   my $pin;

   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj) {
      $vdLogger->Error("Failed to get inline java object for VM");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   my $memSize;
   my $hostObj  = $self->{'hostObj'};
   my $ret = VDNetLib::Common::Utilities::CheckForPatternInVMX(
                                             $hostObj->{hostIP},
                                             $self->{'vmx'},
                                             "^mem");
   if ((not defined $ret) or ($ret eq FAILURE)) {
      $vdLogger->Error("STAF error while retrieving memsize of " .
                        "$vmName, on $hostObj->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($ret =~ /memsize\s*=\s*"(\d+?)"/i) {
      $memSize = $1;
   } else {
      $vdLogger->Error("Failed to get memsize for VM $vmName");
      $vdLogger->Debug("Error: " . Dumper($ret));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   #Fix PR1043820, sched.mem.min has been removed,
   #use resourceConfig.mem.reservation instead
   if ($size =~ /max/i || $size eq "$memSize") {
      $size = $memSize;
      $pin = 1;
   } else {
      $pin = 0;
   }
   $vdLogger->Debug("Reserve memory $size, the reservation is locked to max $pin");
   if (!$inlineVMObj->UpdateMemReservation($size,$pin)) {
      $vdLogger->Error("Failed to reserve mem for VM $vmName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ApplyImageProfile --
#      Apply ESXi Image profile to esx host
#
# Input:
#      esxibuild: esx build number
#      vc:  VC object
#      host: Host Object
#
# Results:
#      Returns "SUCCESS", if ApplyImage success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub ApplyImageProfile {

   my $self      =  shift;
   my %args      = @_;
   my $image     = $args{applyimage};
   my $vcObj     = $args{vc};
   my $hostObj   = $args{host};

   $vdLogger->Debug("Enter ApplyImage");

   my $targetHost = $hostObj->{hostIP};

   my $vcvaBuild = $vcObj->GetVCBuild();
   $vdLogger->Debug("vcvaBuild: $vcvaBuild");

   if ($vcvaBuild eq FAILURE) {
       $vdLogger->Error("Failed to get vc build information");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   my $user    = $vcObj->{user};
   my $passwd  = $vcObj->{passwd};
   my $vcvaIP  = $vcObj->{vcaddr};

   my $esxiBuild = $self->{build};
   $vdLogger->Debug("esxBuild: $esxiBuild");

   my $powercliIP = $self->{vmIP};

   my $stafHelper   = $self->{stafHelper};
   my $imageProfile;
   my $result;

   if ( not defined $vcvaIP || not defined $powercliIP ) {
      $vdLogger->Error("vcva IP: $vcvaIP or PowerCLI IP: ".
	                  "$powercliIP not defined" );
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ( not defined $vcvaBuild ) {
      $vdLogger->Error("vcva build $vcvaBuild not defined" );
      DSetLastError("EINVALID");
      return FAILURE;
   }
   if ( not defined $stafHelper ) {
      $vdLogger->Error("STAFHelper object not provided by the caller");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $build;
   if (not defined $esxiBuild) {
      $build = VDNetLib::Common::FindBuildInfo::FindMatchingESXFromCloudbuild($vcvaBuild);
      if ($build eq FAILURE ) {
        $vdLogger->Error("Failed to find Matching ESXi build $build");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
      $build = $esxiBuild;
   }
   my $url;
   if ($build =~ m/sb-|bora-/) {
       $url = VDNetLib::Common::GlobalConfig::BUILDWEB .  $build . '/publish/CUR-depot/ESXi/index.xml';
   } else {
      $vdLogger->Debug("ESXi Server Build: $build.");
       my $buildInfo =
          VDNetLib::Common::FindBuildInfo::getOfficialBuildInfo($build);
      if ((! defined $buildInfo->{'buildtree'}) or
         ($buildInfo->{'buildtree'} eq "")) {
         # sandbox build
         $url = VDNetLib::Common::GlobalConfig::BUILDWEB . 'sb-' .  $build . '/publish/CUR-depot/ESXi/index.xml';
      } else {
         # offcial build
         $url = VDNetLib::Common::GlobalConfig::BUILDWEB . 'bora-' . $build . '/publish/CUR-depot/ESXi/index.xml';
      }
   }
   $vdLogger->Debug("url: $url");

   if (not defined $imageProfile) {
      #$imageProfile = "*-$build-standard*";
      $build =~ s/sb-|bora-//g;
      $imageProfile = "*-$build-standard";
   }

   # Run the ApplyProfile script at PowerCLI VM
   # retry up to 2 times
   my $count=0;
   while ($count < 2) {
      my $command = POWER_SCRIPT_EXE . ' c:\\ApplyProfile.ps1 ' .
          "-Server $vcvaIP" . ' ' .
          "-User $user" . ' ' .
          "-Password $passwd" . ' ' .
          "-Depot $url" . ' ' .
          "-Imgtype $imageProfile" . ' ' .
          "-targethost $targetHost";

      $vdLogger->Debug("Apply Profile Rule: $command");

      $result = $stafHelper->STAFSyncProcess($powercliIP, $command, 1800);

      # Process the result
      if (($result->{rc} == 0) && ( $result->{exitCode} == 0)) {
         $vdLogger->Debug("Retry count = ".$count);
         $vdLogger->Debug("result->{rc}=".$result->{rc});
         $vdLogger->Debug("result->{exitCode}=".$result->{exitCode});
         $vdLogger->Debug(Dumper($result));
         return SUCCESS;
      } else {
         $count++;
         $vdLogger->Debug("Retry count = ".$count);
      }
      $command = TASKLIST_EXE;
      my $counter = 0;
      my $retry =  5;
      while (1) {
         $result = $stafHelper->STAFSyncProcess($powercliIP, $command);
         if ( $result->{stdout} =~ m/powershell/i ) {
           $vdLogger->Debug("Check for PowerShell");
           $vdLogger->Debug(Dumper($result));
           sleep(60);
         } else {
            $vdLogger->Debug("PowerShell command finished");
            last;
         }
         $counter++;
         if ($counter > $retry ) {
           $vdLogger->Debug("PowerShell command timeout");
           $vdLogger->Debug(Dumper($result));
         }
      }
   }
   return FAILURE;
}


########################################################################
#
# DeployProfileRule --
#      Deploy ESX Image profile rule
#
# Input:
#      arrayOfObj:  either datacenter or cluster object
#
# Results:
#      Returns "SUCCESS", if reboot successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub DeployProfileRule {

   my $self      = shift;
   my $arrayOfObj       = shift;
   my $vcObj;
   my $dcObj;
   my $ruleName;
   my $inventory;
   my $folder;
   my $cluster;
   my $imageProfile;
   my $stafHelper =  $self->{stafHelper};

   $vdLogger->Debug("Datacenter or Cluster Object " . Dumper($arrayOfObj) );

   if (not defined $arrayOfObj) {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   foreach my $obj (@$arrayOfObj) {
     my $reftype = blessed $obj;
     if ( $reftype =~ /Cluster/i ) {
       $cluster = $obj->{clusterName};
       $dcObj = $obj->{dcObj};
       $folder = $dcObj->{foldername};
       $vcObj = $dcObj->{vcObj};
       $inventory = $dcObj->{datacentername};
       last;
     } elsif ( $reftype =~ /Datacenter/i ) {
       $folder = $obj->{foldername};
       $inventory = $obj->{datacentername};
       $vcObj = $obj->{vcObj};
       last;
     } else {
       $vdLogger->Error("Invalid Object " . Dumper($obj) );
       VDSetLastError(VDGetLastError());
       return FAILURE;
     }
   }

   my $user    = $vcObj->{user};
   my $passwd  = $vcObj->{passwd};
   my $vcvaIP  = $vcObj->{vcaddr};
   $vdLogger->Debug("vcvaIP $vcvaIP");

   my $esxiBuild = $self->{build};
   $vdLogger->Debug("esxBuild: $esxiBuild");
   my $powercliIP = $self->{vmIP};

   if ( not defined $vcvaIP || not defined $powercliIP ) {
      $vdLogger->Error("vcva IP: $vcvaIP or PowerCLI IP: ".
	                  "$powercliIP not defined" );
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ( not defined $stafHelper ) {
      $vdLogger->Error("STAFHelper object not provided by the caller");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $build;
   # if We can't get esxBuild, then get vcvaBuild and from vcvaBuild find the matching
   # esxBuildr. Return Failure if we can't get vcvaBuild or can't find matching ESX
   # build.
   if (not defined $esxiBuild) {
      my $vcvaBuild = $vcObj->GetVCBuild();
      $vdLogger->Debug("vcvaBuild: $vcvaBuild");

      if ($vcvaBuild eq FAILURE) {
          $vdLogger->Error("Failed to get vc build information");
          VDSetLastError(VDGetLastError());
          return FAILURE;
      }

      $build = VDNetLib::Common::FindBuildInfo::FindMatchingESXFromCloudbuild($vcvaBuild);
      if ($build eq FAILURE ) {
        $vdLogger->Error("Failed to find Matching ESXi build $build");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
      $build = $esxiBuild;
   }
   my $url;
   if ($build =~ m/sb-|bora-/) {
       $url = VDNetLib::Common::GlobalConfig::BUILDWEB .  $build .
                                       '/publish/CUR-depot/ESXi/index.xml';
   } else {
      $vdLogger->Debug("ESXi Server Build: $build.");
       my $buildInfo =
          VDNetLib::Common::FindBuildInfo::getOfficialBuildInfo($build);
      if ((! defined $buildInfo->{'buildtree'}) or
         ($buildInfo->{'buildtree'} eq "")) {
         # sandbox build
         $url = VDNetLib::Common::GlobalConfig::BUILDWEB . 'sb-' .  $build .
                                       '/publish/CUR-depot/ESXi/index.xml';
      } else {
         # offcial build
         $url = VDNetLib::Common::GlobalConfig::BUILDWEB . 'bora-' . $build .
                                       '/publish/CUR-depot/ESXi/index.xml';
      }
   }
   $vdLogger->Debug("url: $url");

   if (not defined $imageProfile) {
      #$imageProfile = "*-$build-standard*";
      $build =~ s/sb-|bora-//g;
      $imageProfile = "*-$build-standard*";
   }
   if (not defined $ruleName) {
      $ruleName = "Profile-Rule";
   }

   # Run the ProfileRule scripts at PowerCLI VM
   # retry up to 2 times
   my $count=0;
   while ($count < 2) {
      my $command = POWER_SCRIPT_EXE . ' c:\\DeployProfileRule.ps1 ' .
          "-Server $vcvaIP" . ' ' .
          "-User root" . ' ' .
          "-Password vmware" . ' ' .
          "-Depot $url" . ' ' .
          "-Imgtype $imageProfile". ' ' .
          "-Rulename $ruleName" . ' ' ;

      if ($folder) {
         $command = $command . " -Folder $folder";
      }
      if ($inventory) {
         $command = $command . " -Inventory $inventory";
      }
      if ($cluster) {
         $command = $command . " -Cluster $cluster";
      }
      $vdLogger->Debug("Deploy Profile Rule: $command");

      my $result = $stafHelper->STAFSyncProcess($powercliIP, $command, 1800);

      # Process the result
      if (($result->{rc} == 0) && ( $result->{exitCode} == 0) &&
          ($result->{stdout} =~ m/PASS: Successfully added rule/i)) {
         $vdLogger->Debug("Retry count = $count");
         $vdLogger->Debug("result->{rc}=".$result->{rc});
         $vdLogger->Debug("result->{exitCode}=".$result->{exitCode});
         $vdLogger->Debug(Dumper($result));
         return SUCCESS;
      } else {
         $vdLogger->Debug("Retry result->{rc}=".$result->{rc});
         $vdLogger->Debug("Retry result->{exitCode}=".$result->{exitCode});
         $count++;
         $vdLogger->Debug("Retry count = $count");
      }
      $command = TASKLIST_EXE;
      my $counter = 0;
      my $retry =  5;
      while (1) {
         $result = $stafHelper->STAFSyncProcess($powercliIP, $command);
         if ( $result->{stdout} =~ m/powershell/i ) {
           $vdLogger->Debug("Check for Powershell");
           $vdLogger->Debug(Dumper($result));
           sleep(60);
         } else {
            $vdLogger->Debug(" PowerShell command finished");
            last;
         }
         $counter++;
         if ($counter > $retry ) {
           $vdLogger->Debug("PowerShell command timeout");
           $vdLogger->Debug(Dumper($result));
         }
      }
   }
   return FAILURE;
}


##############################################################################
#
# SetEsxBuild
#  set esx build number
#
#  Input:
#       esxbuild: esx build
#
#  Output:
#
#  Side effects:
#       none
#
##############################################################################

sub SetEsxBuild
{
   my $self      =  shift;
   my $esxbuild  =  shift;

   $self->{build} = $esxbuild;
   return SUCCESS;
}


########################################################################
#
# GetToolsImageName --
#       Method to determine the ISO name according to $self->{os};
#
# Input:
#       None
#
# Results:
#       returns the vmtool iso name;
#
# Side effects:
#       none.
#
########################################################################

sub GetToolsImageName
{
   my $self = shift;
   my $isoName;

   if ($self->{os} =~ /lin/i) {
      $isoName = "linux";
   } elsif ($self->{os} =~ /^win/i) {
      $isoName = "windows";
   } elsif ($self->{os} =~ /darwin|mac/i) {
      $isoName = "darwin";
   } elsif ($self->{os} =~ /bsd/i) {
      $isoName = "freebsd";
   } else {
      $vdLogger->Error("Unsupported guest type: $self->{os}");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   return $isoName;
}


########################################################################
#
# GetVmwareToolsImage --
#       Method to get ISO image URL if it's not in local storage
#
# Input:
#       None
#
# Results:
#       returns the URIImage;
#
# Side effects:
#       none.
#
########################################################################

sub GetVmwareToolsImage
{
   my $self = shift;
   my ($esxiBuild, $URIImage);

   if ((exists $self->{'build'}) && (defined $self->{'build'}) &&
      ($self->{'build'} ne '')) {
      $esxiBuild = $self->{'build'};
   } else {
      $esxiBuild = $self->{'hostObj'}{'build'};
   }

   my $isoName = $self->GetToolsImageName();
   if ($isoName eq FAILURE) {
      $vdLogger->Error("Failed to get VMTool iso name for $self->{os}");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   $self->{'hostObj'}{'branch'} =~ /(\d+)/i;
   my $branchInfo = (join ".", split //, $1) . ".0";

   if ($esxiBuild =~ m/sb-|bora-/) {
       $URIImage = VDNetLib::Common::GlobalConfig::BUILDWEB .  $esxiBuild .
                       "/publish/pxe/packages/$branchInfo/vmtools/$isoName.iso";
   } else {
       my $buildInfo =
          VDNetLib::Common::FindBuildInfo::getOfficialBuildInfo($esxiBuild);
      if ((! defined $buildInfo->{'buildtree'}) or
         ($buildInfo->{'buildtree'} eq "")) {
         # sandbox build
         $URIImage = VDNetLib::Common::GlobalConfig::BUILDWEB . 'sb-' .  $esxiBuild .
                       "/publish/pxe/packages/$branchInfo/vmtools/$isoName.iso";
      } else {
         # offcial build
         $URIImage = VDNetLib::Common::GlobalConfig::BUILDWEB . 'bora-' . $esxiBuild .
                       "/publish/pxe/packages/$branchInfo/vmtools/$isoName.iso";
      }
   }
   $vdLogger->Debug("URIImage found for ESX build $esxiBuild: $URIImage");
   return $URIImage;
}


########################################################################
#
# InitVxlanControllerVM --
#     Method to create VXLAN Controller VM object to make it support power
#     on/off/reset and so on
#
# Input:
#     hostObj : Host object reference
#
# Results:
#     return appliance vm perl object;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub InitVxlanControllerVM
{
   my $self = shift;
   my $hostObj = shift;

   # call Python lib to get appliance VM IP address
   my $inlinePythonObj = $self->GetInlinePyObject();
   my $applianceIp = $inlinePythonObj->get_ip();
   if ((not defined $applianceIp) or ($applianceIp eq FAILURE)) {
      $vdLogger->Error("Fetch appliance VM ip address failed ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Appliance VM IP address: $applianceIp");

   my $applianceMac = VDNetLib::Common::Utilities::RetryMethod({
                      'obj'    => $hostObj,
                      'method' => 'GetVmMac',
                      'param1' => $applianceIp,
                      'timeout' => 120,
                      'sleep' => 20,
                      });
   if ((not defined $applianceMac) or ($applianceMac eq FAILURE)) {
      $vdLogger->Error("Fetch appliance VM mac address failed ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Appliance VM MAC address: $applianceMac");

   my $vmxName = $hostObj->GetVMXFile($applianceMac);
   if ((not defined $vmxName) or ($vmxName eq FAILURE)) {
      $vdLogger->Error("Fetch appliance VM vmxname failed ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Appliance VM vmxName: $vmxName");

   my $vmDisplayName = $hostObj->GetVMDisplayName(vmxname => $vmxName);
   if ((not defined $vmDisplayName) or ($vmDisplayName eq FAILURE)) {
      $vdLogger->Error("Fetch appliance VM display name failed ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Appliance VM display name: $vmDisplayName");

   my $result = $self->InitApplianceVM($hostObj, $applianceIp, $vmxName, $vmDisplayName);
   if (FAILURE eq $result) {
      $vdLogger->Error("Failed to init vm operation for Vxlan controller");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# InitNSXApplianceVM --
#     Method to create NSX appliance VM object to make it support power
#     on/off/reset and so on, like nsxmanager and nsxcontroller
#
# Input:
#     hostObj : Host object reference
#     vmIP: appliance vm ip
#     vmInstance: vm instance name, like
#           mqing-vdnet-nsxcontroller-ob-2148051-1-rtqa3-mqing
#
# Results:
#     return appliance vm perl object;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub InitNSXApplianceVM
{
   my $self = shift;
   my $hostObj = shift;
   my $applianceIp = shift;
   my $vmDisplayName = shift;
   my $vmType = shift;

   my $vmxName = $hostObj->GetVMXFileByDisplayName($vmDisplayName);
   $vdLogger->Debug("Appliance VM vmxName: $vmxName");

   my $result = $self->InitApplianceVM($hostObj, $applianceIp, $vmxName, $vmDisplayName,$vmType);
   if ('FAILURE' eq $result) {
      $vdLogger->Error("Failed to init vm operation for nsx appliance");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# InitApplianceVM --
#     Method to create new vm object,merge vm object attribute with
#     appliance object
#
# Input:
#     hostObj : Host object reference
#     vmIP: appliance vm ip
#     vmxName: vmx name
#     vmDisplayName: vm display name
#
# Results:
#     return appliance vm perl object;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub InitApplianceVM
{
   my $self = shift;
   my $hostObj = shift;
   my $applianceIp = shift;
   my $vmxName = shift;
   my $vmDisplayName = shift;
   my $vmType = shift;

   my $vmObj = VDNetLib::VM::VMOperations->new($hostObj,
                                               $vmxName,
                                               $vmDisplayName,
                                               $vmType);
   if (FAILURE eq $vmObj) {
      $vdLogger->Error("Failed to create VMOperations object for VM: ".
                            "$vmDisplayName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   foreach my $item (keys %$vmObj) {
      # appliance VM username and password maybe override while new VMOperation
      # make special handles while new VM object
      if (($item ne "password") && ($item ne "user")) {
         $self->{$item} = $vmObj->{$item};
      }
   }
   if (defined $hostObj->{vcObj}) {
      $self->{useVC} = 1;
      # fetch vc ip address, username, password
      $self->{vc} = $vmObj->{host};
      $self->{vcPasswd} = $vmObj->{password};
      $self->{vcUser} = $vmObj->{user};
   }
   $self->{vmIP} = $applianceIp;
   $self->{waitForStaf} = 0;
   return $self;
}


#############################################################################
#
# SetMulticastVersion --
#     Method which forces Linux kernel to perform multicast operation with
#     specified multicast protocol (ipv4 for IGMP1/IGMP2/IGMP3, and ipv6 for
#     MLD1/MLD2).
#
# Input:
#     protocol : multicast protocol name, igmp/mld
#     version : version number
#               for igmp, valid value may be 0, 1, 2, 3 (0 - default)
#               for mld,  valid value may be 0, 1, 2 (0 - default)
#
# Results:
#     "SUCCESS", if multicast version is set successfully
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub SetMulticastVersion
{
   my $self          = shift;
   my $protocol      = shift;
   my $version       = shift;
   my $stafHelper    = $self->{stafHelper};
   my $ipv4Multicast = VDNetLib::TestData::TestConstants::IGMP_VERSION;
   my $ipv6Multicast = VDNetLib::TestData::TestConstants::MLD_VERSION;
   my $command;
   my $result;

   if ($self->{os} !~ /linux/i) {
      $vdLogger->Error("SetMulticastVersion() not supported ".
                     "for $self->{osType} yet");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if((not defined $protocol) || (not defined $version)) {
      $vdLogger->Error("mulicast protocol or version are not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (lc($protocol) eq "igmp") {
      $command = "echo \"$version\" > $ipv4Multicast";
   } elsif (lc($protocol) eq "mld") {
      $command = "echo \"$version\" > $ipv6Multicast";
   } else {
      $vdLogger->Error("muticast protocol ($protocol) is not valid.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $vdLogger->Debug("command to force multicast version is ($command)");
   $result = $stafHelper->STAFSyncProcess($self->{vmIP}, $command);
   if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) ) {
      $vdLogger->Error("Failed to set the multicast version");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Info("Successfully set multicast version ".
                   "$protocol$version on vm $self->{vmIP}");
   return SUCCESS;
}


########################################################################
#
# Reconfigure --
#     Method to reconfigure VM. Even though there are several individual
#     methods available to change specific settings, this can be an entry
#     point method for entire VM reconfiguration.
#
# Input:
#     $spec: Reference to a hash containing following structure:
#            'instanceuuid': instace UUID
#
# Results:
#     SUCCESS, if the VM is reconfigured successfully;
#     FAILURE, otherwise.
#
# Side effects:
#     None
#
########################################################################

sub Reconfigure
{
   my $self = shift;
   my $spec = shift;
   my $result;
   if (exists $spec->{instanceuuid}) {
      my $uuid = $spec->{instanceuuid};
      $vdLogger->Info("Updating UUID:$uuid");
      if (FAILURE eq $self->UpdateVCUUID($uuid)) {
         $vdLogger->Error("Failed to update VM UUID $uuid");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# SetupVM --
#     Method to setup VM which includes getting ip address,
#     initializing vnic objects, tools upgrade etc
#
# Input:
#      vdNetMountElements : A reference of the hash containing vdNetSrc and vdNetShare
# Results:
#     SUCCESS, if the VM is setup successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetupVM
{
   my $self = shift;
   my $vdNetMountElements = shift;
   my $managementPortgroup = shift;
   my $vdNetSrc = ${$vdNetMountElements}{vdNetSrc};
   my $vdNetShare = ${$vdNetMountElements}{vdNetShare};
   my $controlMAC = $self->GetGuestControlMAC($managementPortgroup);
   if (not defined $controlMAC) {
      $vdLogger->Error("Unable to find the control adapter's mac address " .
                       "on VM: $self->{vmName}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $vmIP = $self->{'vmIP'};
   my $vmxName = $self->{'vmx'};
   my $hostIP	  = $self->{hostObj}{hostIP};
   # If IP is not provided then find the IP address of the VM
   if (not defined $vmIP || (defined $vmIP && $vmIP !~ /\.\d+/i)) {
      $vmIP = $self->GetGuestControlIP($controlMAC);
      if ($vmIP eq FAILURE) {
         # Reboot as workaround
         # Bug #1386762
         $vdLogger->Warn("Unable to get VM: $self->{vmName}, IP address" .
                         "Trying again after rebooting VM");
         my $result =  $self->VMOpsReset();
         if ($result eq FAILURE) {
            $vdLogger->Error("Failed to reset VM $self->{vmName}");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vmIP = $self->GetGuestControlIP($controlMAC);
         if ($vmIP eq FAILURE) {
            $vdLogger->Error("Failed to get VM: $self->{vmName}, IP address");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
   }
   $self->{vmIP} = $vmIP;
   $vdLogger->Info("VM: $self->{vmName}, IP address: $self->{vmIP}");

   my $result = $self->InstallPackagesInGuest();
   if ($result  eq FAILURE ) {
      $vdLogger->Debug("InstallPackagesInGuest failed on $self->{vmIP} ");
   }


   if ((defined $self->{waitForStaf}) && ($self->{waitForStaf} == 0)) {
      $vdLogger->Info("vm waitForStaf option equals 0, no need to wait staf");
      return SUCCESS;
   }
   $vdLogger->Info("Waiting for STAF on $self->{vmIP}...");
   $result = $self->{stafHelper}->WaitForSTAF($self->{vmIP});
   if ($result  eq FAILURE ) {
      $vdLogger->Error( "WaitForSTAF failed on $self->{vmIP} ");
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }
   $vdLogger->Info("STAF is up and running fine on $self->{vmIP}");

   if ($self->{changeName} == VDNetLib::Common::GlobalConfig::TRUE) {
      my $vmOS = $self->{stafHelper}->GetOS($vmIP);
      if (not defined $vmOS) {
	 $vdLogger->Error("Unable to find the guest OS type of $vmIP");
	 VDSetLastError("ESTAF");
	 return FAILURE;
      }

      if ($vmOS !~ /win/i) {
         $vdLogger->Debug("$vmIP: Change hostname not required for $vmOS");
         if (not defined $sshSession->{$vmIP}) {
            my  $sshHost = VDNetLib::Common::SshHost->new(
                              $vmIP,
                              "root",
                              $self->GetPassword(),
                              );
            unless ($sshHost) {
               $vdLogger->Error("Failed to establish a SSH session with " .
                                $vmIP);
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }
            $sshSession->{$vmIP} = $sshHost;
            if (VDNetLib::Common::Utilities::SavePIDToWatchdog(
                $sshHost->GetPID()) eq FAILURE) {
               $vdLogger->Error("Failed to save SSH process ID to watch dog");
            }
         }
      } else {
         my $newCompName = VDNetLib::Common::Utilities::GetTimeStamp();
         $newCompName =~ s/.*-//g;
         #
         # New computer name will be in the format "Win-<hourminsec>".
         # hour, min, sec will be in 2 digits
         #
         $newCompName = "Win-" . $newCompName;
         my $newIP = VDNetLib::Common::Utilities::ChangeHostname(
                                             host       => $hostIP,
                                             vmObj      => $self,
                                             winIP      => $vmIP,
                                             compName   => $newCompName,
                                             macAddress => $controlMAC,
                                             stafHelper => $self->{stafHelper});
         if ($newIP eq FAILURE) {
            $vdLogger->Error("Failed to change hostname");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vmIP		= $newIP;
         $self->{vmIP} = $vmIP;
      }

      $result = $self->{stafHelper}->WaitForSTAF($vmIP);
      if ($result eq FAILURE) {
	 $vdLogger->Error("STAF not running on $vmIP");
	 VDSetLastError("ESTAF");
	 return FAILURE;
      }
   }
   $self->{changeName} = VDNetLib::Common::GlobalConfig::FALSE;

   my ($os, $arch) = $self->GetOSAndArch($vmIP);
   if ($os eq FAILURE) {
      $vdLogger->Error("Failed to get os and arch type for VM: $self->{vmIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Adding OS/Arch atributes to VM Object
   $self->SetOS($os);
   $self->SetArch($arch);

   #
   # Not throwing error intentionally, since this is a best effort approach
   # to improve performance
   #
   $vdLogger->Debug("Update hosts lookup table: " .
                     VDNetLib::Common::Utilities::UpdateLauncherHostEntry(
							   $self->{vmIP},
                                                           $self->{os},
                                                           $self->{stafHelper}));

   my $folder     = ($self->{os} =~ /win/i) ? "M:" : "/automation";
   if ( not defined $vdNetSrc ) {
        $vdNetSrc = VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_SERVER ;
        $vdNetShare = VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_DIR;
      }
   my $isSMBMount = $self->IsSMBMounted($self->{vmIP},
                                        $self->{os},
                                        $vdNetSrc,
                                        $vdNetShare,
                                        $folder);
   if ($isSMBMount eq FAILURE) {
      $vdLogger->Error("Unable to check if SMB $vdNetSrc:$vdNetShare/$folder".
                       " is mounted or not on VM $self->{vmIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($isSMBMount == VDNetLib::Common::GlobalConfig::FALSE) {
      # cleanup any mount points on $folder before mounting vdNetSrc
      $vdLogger->Debug("Cleanup existing mount point $folder on ".
                       "VM $self->{vmIP}");
      if ($self->DeleteMountPoint($self->{vmIP},
                                  $self->{os},
                                  $folder) eq FAILURE) {
         $vdLogger->Error("Cleaning up existing mount point $folder failed ".
                          "on VM $self->{vmIP}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $vdLogger->Debug("Mounting SMB share $vdNetSrc:$vdNetShare/$folder ".
                       "on VM $self->{vmIP}");
      if ($self->MountVDAuto($self->{vmIP},
                             $self->{os},
                             $vdNetSrc,
                             $vdNetShare,
                             $folder) eq FAILURE) {
         $vdLogger->Error("Unable to Mount SMB share ".
                          "$vdNetSrc:$vdNetShare/$folder on ".
                          "VM $self->{vmIP}");
         VDSetLastError("EMOUNT");
         return FAILURE;
      }
   }

   # Check VM setup for vdnet

   $result = $self->CheckVMSetup($vdNetMountElements);
   if ($result eq FAILURE) {
      $vdLogger->Error("Some setup in VM $vmIP is not in line with vdNet request.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
# MountVDAuto --
#       Mounts automation SMB share on the given IP address
#
# Input:
#	ip    - IP Address of host/vm, where SMB share needs to be mounted
#	os    - OS Type of host/vm
#	SMBIP - SMB Share's IP Address
#	share - SMB Share's directory location
#	folder- Mountpoint location on host/vm
#
# Results:
#       Returns SUCCESS if SMB share is mounted successfully else
#       FAILURE
#
# Side effects:
#       none
#
########################################################################

sub MountVDAuto
{
   my $self   = shift;
   my $ip     = shift;
   my $os     = shift;
   my $SMBIP  = shift;
   my $share  = shift;
   my $folder = shift;
   my $folderName = $share;
   my ($command, $result, $data, $toolChainDir);
   $toolChainDir = VDNetLib::Common::GlobalConfig::DEFAULT_TOOLCHAIN_MOUNTPOINT;

   my $toolchainMirror = $ENV{VDNET_TOOLCHAIN_MIRROR};
   my ($toolchainServer, $toolchainShare);
   if (defined $toolchainMirror) {
      ($toolchainServer, $toolchainShare) = split(":", $toolchainMirror);
   } else {
      $toolchainServer = VDNetLib::Common::GlobalConfig::DEFAULT_TOOLCHAIN_SERVER;
      $toolchainShare  = VDNetLib::Common::GlobalConfig::DEFAULT_TOOLCHAIN_SHARE;
   }

   if (($os !~ /win/i) && ($os !~ /vmkernel/i)) {
      # create automation directory if it doesn't exist using STAF
      # FS service
      ($result, $data) = $self->{stafHelper}->runStafCmd($ip, "fs",
                                         "create directory $folder");
      if ($result eq FAILURE) {
         $vdLogger->Error("creating automation directory on $ip failed");
         $vdLogger->Error("$data") if (defined $data);
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if (defined $sshSession->{$ip}) {
         my $sshHost = $sshSession->{$ip};
         my ($rc, $out) = $sshHost->SshCommand("mkdir -p $toolChainDir");
         if ($rc ne "0") {
            $vdLogger->Warn("Failed to create directory $toolChainDir on $ip");
            $vdLogger->Debug("Return code = $rc " . Dumper($out));
         }
      }
   }
   $folderName = $share;
   if (($os =~ /lin/i) || ($os =~ /esx/i)) {
      $command = "mount -o nolock $SMBIP:$share $folder";
      my $toolchainMount = "mount  -o nolock " .
         $toolchainServer . ":" .
         $toolchainShare . " " .
         $toolChainDir;
      $command .= ";$toolchainMount";
   } elsif ($os =~ /freebsd/i) {
      # -o nolock option is not supported in freebsd PR 1086136
      $command = "mount $SMBIP:$share $folder";
   } elsif ($os =~ /win/i) {
      $folderName =~ s/\//\\/g;
      if ($SMBIP =~ /scm-trees/i) {
         $command = "net use $folder \\\\$SMBIP" . $folderName . " " .
                    VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_PWD .
                    " /USER:vmwarem\\" .
                    VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_USR .
                    " /persistent:yes /Y";
      } else {
         $command = "net use $folder \\\\$SMBIP" . $folderName .
                    " /persistent:yes /Y";
      }
   } else {
      goto CheckMount;
   }

   $command = "START SHELL COMMAND " . STAF::WrapData($command) .
              " WAIT RETURNSTDOUT STDERRTOSTDOUT";
   ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                      "process",
                                                      $command);
   $vdLogger->Debug("command $command");
   $vdLogger->Debug("data $data");
   if ( $result ne SUCCESS ) {
      $vdLogger->Error("Mounting SMB share failed: $command $data");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ( defined $data && (($data =~ /System error 1326 has occurred/i) ||
                         ($data =~ /error/i)) ) {
      $vdLogger->Error("run smbpasswd -a on the smb share machine: $data");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
CheckMount:
   if (VDNetLib::Common::GlobalConfig::FALSE ==
         $self->IsSMBMounted($ip, $os, $SMBIP, $share, $folder)) {
      VDSetLastError("EMOUNT");
      return FAILURE;
   } else {
      return SUCCESS;
   }
}


########################################################################
#
# CheckVMSetup --
#       Checks VM for setup required to run vdNet
#
#       Check and setup the following:
#          if it is windows OS:
#             a) disable firewall
#             b) enable autologon
#             c) disable event tracker
#             d) install winpcap, if it is not installed
#
#  Input:
#       vdNetMountElements : Reference of hash contaning vdNetSrc and vdNetShare
#
#  Results:
#       Checks the setup and sets it up if necessary and possible
#
#  Side effects:
#       Required mountpoints gets created on Guest VMs;
#       Required service's status get chagned;
#       Required tools get installed.
#
########################################################################

sub CheckVMSetup
{
   my $self    = shift;
   my $vdNetMountElements   = shift;
   my $result;
   my $vdNetSrc = ${$vdNetMountElements}{vdNetSrc};
   my $vdNetShare = ${$vdNetMountElements}{vdNetShare};
   my $vmIP = $self->{vmIP};
   $vdLogger->Info("Checking setup for VM: $vmIP ...");

   if (($self->{os} =~ /win/i) &&
      ($self->CopySetupFilesToWinGuest() eq FAILURE)) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Debug("Check if SMB share is mounted on VM $vmIP");
   my $folder     = ($self->{os} =~ /win/i) ? "M:" : "/automation";
   my $isSMBMount = $self->IsSMBMounted($vmIP,
                                        $self->{os},
                                        $vdNetSrc,
                                        $vdNetShare,
                                        $folder);
   if ($isSMBMount eq FAILURE) {
      $vdLogger->Error("Unable to check if SMB is mounted or not ".
                       "on VM $vmIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($isSMBMount == VDNetLib::Common::GlobalConfig::FALSE) {
      # cleanup any mount points on $folder before mounting vdNetSrc
      $vdLogger->Debug("Cleanup existing mount point on VM $vmIP");
      if ($self->DeleteMountPoint($vmIP,
                                  $self->{os},
                                  $folder) eq FAILURE) {
         $vdLogger->Error("Cleaning up existing mount points failed ".
                          "on VM $vmIP");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $vdLogger->Info("Mounting SMB share on VM $vmIP");
      if ($self->MountVDAuto($vmIP,
                             $self->{os},
                             $vdNetSrc,
                             $vdNetShare,
                             $folder) eq FAILURE) {
         $vdLogger->Error("Unable to Mount SMB share on VM $vmIP");
         VDSetLastError("EMOUNT");
       return FAILURE;
      }
   }

   $self->SetMount($vdNetSrc, $vdNetShare);
   if ($self->{os} =~ /lin/i) {
      if ($self->LinVDNetSetup($vmIP, $self->{os}) eq FAILURE ) {
         $vdLogger->Warn("Disabling Firewall failed on VM $vmIP");
      }
   } elsif ($self->{os} =~ /win/i ) {
      my $ret = $self->WinVDNetSetup($vmIP, $self->{os});
      if ($ret eq FAILURE ) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      if ($ret =~ /rebootrequired/) {
         $vdLogger->Info("Restarting the VM");
         if ($self->RestartVM($vmIP, $self->{os}) eq FAILURE ) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         #
         # copying setup.log file is to avoid rebooting the VM if it is already
         # setup, so it is best effort, if the file is not copied, we do not
         # check for error here.
         #
         `echo "Setup Completed" > /tmp/setup.log`;
         my $srcFile = "/tmp/setup.log";
         my $command = "COPY FILE $srcFile TODIRECTORY C:\\vmqa ".
                       "TOMACHINE $vmIP\@$STAF_DEFAULT_PORT";
         $self->{stafHelper}->runStafCmd('local', "FS", $command);
      }
   }

   return SUCCESS;
}


########################################################################
#
# DeleteMountPoint --
#       Deletes given mount point on the remote machine
#
# Input:
#       ip     - remote machines IP address
#       os     - remote machine's OS type
#       folder - folder that needs to be deleted
#
# Results:
#       Returns SUCCESS if SMB share /automation is mounted on the
#       given IP address else FAILURE
#
# Side effects:
#       For windows, if the M: driver is in not OK state then it will
#       delete the M:.  Similarly, for linux, it any thing else is
#       mounted on the /automatin directory, it will unmount it.
#
########################################################################

sub DeleteMountPoint
{
   my $self   = shift;
   my $ip     = shift; # where you want to mount
   my $os     = shift; # os type of the remote machine
   my $folder = shift; # mount point name on the remote machine
   my ($command, $result, $data);

   if ((not defined $ip) || (not defined $os) || (not defined $folder)) {
      $vdLogger->Error("DeleteMountPoint: One or more parms passed are undefined");
      VDSetLastError("ENINVALID");
      return FAILURE;
   }

   if ($os =~ /win/i) {
         $command = "start shell command net use /delete /y $folder wait " .
                    "returnstdout stderrtostdout";
   } elsif (($os =~ /linux|freebsd/i) || ($os =~ /esx/i)) {
         $command = "start shell command umount -lf $folder wait " .
                    "returnstdout stderrtostdout";
   } elsif ($os =~ /vmkernel|esxi/i) {
         # esxi doesn't take absolute path name of the folder where
         # it is mounted and hence remove the '/' again this works
         # only if the folder is at root level
         my $fol = $folder;
         $fol =~ s/\///;
         $command = "start shell command esxcfg-nas -d " .
                    "$fol wait returnstdout stderrtostdout";
   }

   $vdLogger->Debug("Deleting mount point $folder on $ip");
   ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                      "process",
                                                      $command);
   if ( $result ne SUCCESS ) {
      $vdLogger->Error("Deleting mount point $folder failed: $data");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Command $command\ndata $data");
   return SUCCESS;
}


########################################################################
#
# IsSMBMounted --
#       Checks if a given share on given server is mounted on the
#       remote machine
#
# Input:
#       ip	 - Remote machine's IP address
#       os	 - Remote machine's OS type
#       serverIP - Server IP address
#       share	 - Mount/Share name on server
#       folder	 - folder name on remote machine where it has to be mounted
#
# Results:
#       Returns TRUE if share is mounted on a given folder on
#       remote machine else FALSE.  FAILURE for any other errors
#
# Side effects:
#       none
#
########################################################################

sub IsSMBMounted
{
   my $self	= shift;
   my $ip	= shift; # where you want to mount
   my $os	= shift; # os type of the remote machine
   my $serverIP	= shift; # mount server IP address
   my $share	= shift;
   my $folder	= shift;

   my ($command, $result, $data);

   if (($os =~ /lin/i) ||($os =~ /esx/i) || ($os =~ /FreeBSD/i)) {
      # this should take care of both nfs and cifs mount
      $command = "mount | grep \"$serverIP:$share on $folder \"";
   } elsif ($os =~ /win/i) {
      $command = "net use $folder";
   } elsif ($os =~ /vmkernel|esxi/i) {
      $folder =~ s/^\///;
      $command = "esxcfg-nas -l | grep \"$folder is $share from\"";
   }

   $command = "START SHELL COMMAND " . STAF::WrapData($command) .
              " WAIT RETURNSTDOUT STDERRTOSTDOUT";
   ($result, $data) = $self->{stafHelper}->runStafCmd($ip, "process", $command);
   $vdLogger->Debug("IsSMBMounted data: $data");
   if ( $result ne SUCCESS ) {
      $vdLogger->Error("$command failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($os =~ /win/i) {
      # remove / in case if full path of the share is given
      $share =~ s/^\///;
      $share =~ s/\//\\/g;
      $share = quotemeta($share);
      # Please check PR1473280 to get detail information
      # Add the code to make "scm-trees" and "scm-trees.eng.vmware.com"
      #  match each other.
      if ($serverIP =~ "scm-trees"){
         $serverIP = "scm-trees";
      }
      if ((defined $data) &&
          ($data =~ /$serverIP/) &&
          ($data =~ /$share/) &&
          ($data =~ /Status\s+OK/i) ) {
         $vdLogger->Debug("Share $share from $serverIP is mounted on $folder");
         return VDNetLib::Common::GlobalConfig::TRUE;
      } else {
         $vdLogger->Debug("Share $share from $serverIP is NOT mounted on $folder");
         return VDNetLib::Common::GlobalConfig::FALSE;
      }
   }

   if ((defined $data) && ($data =~ /$serverIP/i)) {
      $vdLogger->Debug("Share $share from $serverIP is mounted on $folder");
      return VDNetLib::Common::GlobalConfig::TRUE;
   } else {
      $vdLogger->Debug("Share $share from $serverIP is NOT mounted on $folder");
      return VDNetLib::Common::GlobalConfig::FALSE;
   }
}


########################################################################
#
# GetOSAndArch --
#      This method fills the 'os' and 'arch' for the given host or
#      guest.
#
# Input:
#      ip: IP Address of the target system to fetch the details
#	   (Mandatory)
#
# Results:
#      Two values are returned (OS and Arch), in case of SUCCESS
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetOSAndArch
{
   my $self = shift;
   my $ip   = shift;

   # Get OS type
   my $os = $self->{stafHelper}->GetOS($ip);
   if ($os eq FAILURE ) {
      $vdLogger->Error("Failed to get os information of $ip");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Update the arch detail as well
   my $arch = $self->{stafHelper}->Arch($ip);
   if ($arch eq FAILURE) {
      $vdLogger->Error("Failed to get arch type of $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $arch =~ s/\n//g; # remove any new line character
   $vdLogger->Debug("IP: $ip has, Arch type: $arch and OS type: $os");

   return ($os, $arch);
}


########################################################################
#
# SetMount --
#       Adds a start up script in windows startup directory to mount SMB
#       share from master controller
#
# Input:
#	src   - vdNet SMB Share's IP Address
#	share - vdNet SMB Share's directory location
#
# Results:
#       Returns SUCCESS if the mount.bat script is placed successfully
#       else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub SetMount
{
   my $self  = shift;
   my $src   = shift;
   my $share = shift;

   my $ip    = $self->{vmIP};
   my $os    = $self->{os};
   my ($host, $vmx, $command, $cmdOut);
   my ($result, $data);

   if ( $os =~ /lin/i ) {
      my $mountEntry = "$src\:$share /automation nfs ro ";
      # check if /etc/fstab has entry else add to it
      $command = "start shell command cat /etc/fstab wait " .
                 "returnstdout stderrtostdout";
      ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
							 "process", $command);
      if ($result eq FAILURE) {
         $vdLogger->Error("Couldn't get the /etc/fstab contents on VM $ip");
	 VDSetLastError("EFAIL");
	 return FAILURE;
      }

      if (defined $data) {
         # check if src Server and share is mounted on automation
         if ($data =~ /$src:$share \/automation/i ) {
            $vdLogger->Debug("/etc/fstab has entry: $data");
            return SUCCESS;
         } elsif ($data =~ /\s\/automation\s/) {
            $vdLogger->Debug("Editing /etc/fstab with $mountEntry");
            $mountEntry =~ s/\//\\\//g; # escape all slashes "/"
            $command = "perl -p -i -e " .
                       "\"s/.*\\\/automation.*/$mountEntry/g\" /etc/fstab";
         } else {
         # add an entry to /etc/fstab
         #
         $vdLogger->Debug("Adding $mountEntry in /etc/fstab");
         $command = "echo $mountEntry >> /etc/fstab";
         }
      }
      $command = "START SHELL COMMAND " . STAF::WrapData($command) .
                 " WAIT RETURNSTDOUT STDERRTOSTDOUT";

      $vdLogger->Debug("SetMount Command:$command");
      ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                             "process", $command);

      $vdLogger->Debug("SetMount:$data");
      if ($result eq FAILURE || $data ne "") {
         $vdLogger->Error("Couldn't get the /etc/fstab contents on VM $ip");
         return FAILURE;
	 VDSetLastError("EFAIL");
	 return FAILURE;
      }
      return SUCCESS;
   }

   if ($os !~ /win/i ) {
      # it is a noop for OSes other than windows after this point
      return SUCCESS;
   }

   $host = $self->{esxhost};
   $vmx  = $self->{vmx};

   # modern windows has the following as startup directory
   my $startupDir = "C:\\ProgramData\\Microsoft\\Windows\\" .
                    "Start Menu\\Programs\\Startup\\";

   #
   # If the given startupDir does not exists on the given machine, then use
   # the alternate startupDir.
   #
   $command = "GET ENTRY $startupDir TYPE";
   ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                      "FS",
                                                      $command);
   if ($result eq "FAILURE") {
      # pre-vista windows has the following as startup directory
      $startupDir = "C:\\Documents and Settings\\Administrator\\" .
                    "Start Menu\\Programs\\Startup\\";
      #
      # If the given startupDir does not exists on the given machine, then use
      # the alternate startupDir.
      #
      $command = "GET ENTRY $startupDir TYPE";
      ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                         "FS",
                                                         $command);
      if ($result eq "FAILURE") {
         # windows8 has the following as startup directory
         $startupDir = "C:\\Users\\Administrator\\AppData\\Roaming\\Microsoft\\Windows\\" .
                       "Start Menu\\Programs\\Startup\\";
       }
   }

   my $tempDir = $share;
   $tempDir =~ s/\//\\/g; # convert / to \ for windows
   my $mntCmd;
   if ($src =~ /scm-trees/i) {
      $mntCmd = 'net use M: \\\\' . $src . $tempDir  . ' ' .
                VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_PWD .
                ' /USER:vmwarem\\'.
                VDNetLib::Common::GlobalConfig::DEFAULT_VDNET_SRC_USR .
                ' /persistent:yes /Y';
   } else {
      $mntCmd = 'net use M: \\\\' . $src . $tempDir .
                ' /persistent:yes /Y';
   }
   my $srcFile = "/tmp/mount.bat";
   if(!open(MYFILE, ">$srcFile")) {
      $vdLogger->Error("Opening file $srcFile failed: $!");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   print MYFILE "$mntCmd\n";
   $vdLogger->Debug("Wrote ". $srcFile. " with command: $mntCmd on windows");
   close(MYFILE);
   $command = "COPY FILE $srcFile TODIRECTORY $startupDir TOMACHINE $ip\@$STAF_DEFAULT_PORT";
   ($result, $data) = $self->{stafHelper}->runStafCmd('local',
                                                      "FS",
                                                      $command);
   $vdLogger->Debug("command: $command");
   if ($result eq FAILURE) {
      $vdLogger->Error("command $command failed on $vmx, $ip");
      $vdLogger->Error("Error:$data") if (defined $data);
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
# CopySetupFilesToWinGuest --
#       Copy files required to perform setup automation to C:\vmqa
#       directory on windows.
#
# Input:
#       vmObj	- VM Object
#
# Results:
#       copies files to the guest - only supported for windows VM on
#       esx/hosted
#
# Side effects:
#       none
#
########################################################################

sub CopySetupFilesToWinGuest
{
   my $self	= shift;
   #my $vmObj	= shift;

   my $hostObj	= $self->{hostObj};
   my $host	= $hostObj->{hostIP};
   my $hostType = $hostObj->{hostType};
   my $vmx	= $self->{vmx};
   my $os	= $self->{os};
   my $ip	= $self->{vmIP};

   my $gc = new VDNetLib::Common::GlobalConfig;

   my ($cmdOut, $command, $ret);
   my ($hostInfo, $guestUser);

   my $setupDir = $gc->GetSetupDir($os);
   $command = "create directory $setupDir";
   # Using FS service create C:\vmqa directory on windows VM
   # FS service returns success if the given directory already exists
   my ($result, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                         "fs",
                                                         $command);
   if ($result ne SUCCESS) {
      $vdLogger->Error("Unable to create $setupDir on $ip");
      $vdLogger->Error("cmdOut $cmdOut ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   foreach my $file (@{VDNetLib::Common::GlobalConfig::winSetupFiles}) {
      # This assumes all the files are in test code path
      # If that assumption changes then this for loop has to
      # be changed.
      my $srcDir = $gc->TestCasePath(VDNetLib::Common::GlobalConfig::OS_LINUX);
      my $srcFile = $srcDir . "$file";
      my $dstFile = $setupDir . $file;

      $vdLogger->Info("Copying $srcFile to $dstFile");
      $command = "COPY FILE $srcFile TOFILE $dstFile TOMACHINE $ip\@$STAF_DEFAULT_PORT";

      ($result, $data) = $self->{stafHelper}->runStafCmd($host,
                                                         "fs",
                                                         $command);
      $vdLogger->Debug("command: $command");

      if ($result eq FAILURE) {
         $vdLogger->Error("command $command failed on\n\t$vmx, $ip");
         $vdLogger->Error("cmd output $data ");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } # end of the for loop to copy all setup files
   return SUCCESS;

}


########################################################################
#
# LinVDNetSetup --
#       Linux based VDNet Setup.
#       1) Stops iptables and ip6tables services if they are running.
#
# Input:
#       ip  - Remote machine's IP address
#       os  - Remote machine's OS type
#
# Results:
#       SUCCESS - in case services are stopped.
#       FAILURE - in case of error.
#
# Side effects:
#       none
#
########################################################################

sub LinVDNetSetup
{
   my $self = shift;
   my $ip = shift; # machine on which firewall should be disabled.
   my $os = shift;
   my $service;
   my $action = "stop";
   my $result;

   # This method is only applicable on linux
   if ($os !~ /lin/i){
      VDSetLastError("EINVALID");
      $vdLogger->Error("This method is only applicable on Linux");
      return FAILURE;
   }
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
# WinVDNetSetup --
#       Check windows VM setup and setup if necessary
#
# Input:
#       ip    - Remote machine's IP address
#       os    - Remote machine's OS type
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#       rebootrequired - in case the machine should be rebooted as
#       part of completion of setup.
#
# Side effects:
#       none
#
########################################################################

sub WinVDNetSetup
{
   my $self  = shift;
   my $ip    = shift;
   my $os    = shift;

   my $macInfo;
   my ($host, $vmx, $command, $cmdOut);
   my $restart = 0;

   if ($os !~ /win/i ) {
      # return SUCCESS if it the machine is not windows
      return SUCCESS;
   }

   $macInfo->{ip} = $ip;
   $macInfo->{os} = $os;

   # Make it dynamic loading module, it will save memory when the test
   # case is just linux based and VDAutomationSetup would not be
   # loaded in memory.
   my $module = "VDNetLib::Common::VDAutomationSetup";
   eval "require $module";
   if ($@) {
      $vdLogger->Error("Failed to load package $module $@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Keep new (method) of child as light as possible for better performance.
   my $setup = $module->new($macInfo);
   if ($setup eq FAILURE) {
      $vdLogger->Error("Failed to create obj of package $module");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{setup} = $setup;

   # TODO: create a data structure where you have list of methods to call
   # and just iterate through it in this method

   # check if event tracker is disabled, if not disable
   my $eventTrackerStatus = $setup->IsEventTrackerDisabled();
   if ($eventTrackerStatus eq FAILURE) {
      $vdLogger->Error("Checking event tracker status failed on $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($eventTrackerStatus eq VDNetLib::Common::GlobalConfig::FALSE) {
      if ($setup->SetEventTracker("disable") eq FAILURE) {
         $vdLogger->Error("Disabling event tracker status failed on $ip");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $restart = 1;
   }
   # check if autologin is enabled, if not enable
   my $autoLogonStatus = $setup->IsAutoLogonEnabled();

   if ($autoLogonStatus eq FAILURE) {
      $vdLogger->Error("Checking auto logon status failed on $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($autoLogonStatus eq VDNetLib::Common::GlobalConfig::FALSE) {
      if ($setup->SetAutoLogon("enable") eq FAILURE) {
         $vdLogger->Error("Enabling auto logon failed on $ip");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $restart = 1;
   }
   # install winpcap
   if ($setup->InstallWinPcap() eq FAILURE) {
      $vdLogger->Error("Installing winpcap failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($setup->ConfigFullDump() eq FAILURE) {
      $vdLogger->Error("Configuring full dump failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # disable found new hardware wizard
   if ($setup->CopyDisableFoundNewHardwareWizard() eq FAILURE) {
      $vdLogger->Error("Copying files to disable found new HW wizard failed ".
		       "on $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # disable driver signing off
   if ($setup->DisableDriverSigningWizard() eq FAILURE) {
      $vdLogger->Error("Disabling Driver sign-off failed on $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
#   my ($result, $data) = $self->{stafHelper}->runStafCmd(
#                                           $ip,
#                                           "FS",
#                                           "GET FILE C:\\vmqa\\setup.log");
#   if ($data =~ /does not exist/i) {
#      $restart = 1;
#   }
   # enable plain text passwd - tested and requires reboot
   my $plainTestPasswordStatus = $setup->IsPlaintextPasswordEnabled();

   if ($plainTestPasswordStatus eq FAILURE) {
      $vdLogger->Error("Checking plain text passwd status failed on $ip");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($plainTestPasswordStatus eq VDNetLib::Common::GlobalConfig::FALSE) {
      if ($setup->SetPlaintextPassword("enable") eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $restart = 1;
   }
   if (!$restart) {
      return SUCCESS;
   } else {
      return "rebootrequired";
   }
}


########################################################################
#
# RestartVM --
#       Restarts wndows VM using shutdown /r command
#
# Input:
#       ip  - Remote machine's IP address
#       os  - Remote machine's OS type
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#
# Side effects:
#       VM will be rebooted
#
########################################################################

sub RestartVM
{
   my $self = shift;
   my $ip   = shift;
   my $os   = shift;
   my $cmd;

   if ($os =~ /win/i) {
      $cmd = 'shutdown /f /r /t 0';
   } elsif ($os =~ /linux/i) {
      $cmd = 'shutdown -r -y 0';
   }

   my $command	    = "start shell command $cmd async";
   my ($ret, $data) = $self->{stafHelper}->runStafCmd($ip,
                                                      'PROCESS',
                                                      $command);
   if ($ret eq FAILURE) {
      $vdLogger->Error("Staf error executing shutdown command on $ip\n$command $data");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # make sure the system shuts down
   sleep(VDNetLib::Common::GlobalConfig::TRANSIENT_TIME);
   # now wait for the STAF to come up
   $vdLogger->Info("Waiting for the the STAF to come up on $ip");

   if ($self->{stafHelper}->WaitForSTAF($ip) eq FAILURE) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# GetOS --
#     Method to get os of guest in the VM.
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
   my $osType = $self->{stafHelper}->GetOS($self->{vmIP});
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $self->{vmIP}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $osType;
}


########################################################################
#
# GetArchitecture --
#     Method to get arch of os of guest in the VM.
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
   my $osArch = $self->{stafHelper}->GetOSArch($self->{vmIP});
   if (not defined $osArch) {
      $vdLogger->Error("Unable to get OS Arch of VM $self->{vmIP}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $osArch;
}


########################################################################
#
# GetUsername--
#     Method to get username of guest in the VM.
#
# Input:
#     None
#
# Results:
#     username in case of SUCCESS
#     FAILURE, otherwise.
#
# Side effects:
#     None
#
########################################################################

sub GetUsername
{
   return MY_USERNAME;
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
# GetControlIP --
#     Method to get IP of guest in the VM.
#
# Input:
#     None
#
# Results:
#     ip in case of SUCCESS
#     FAILURE, otherwise.
#
# Side effects:
#     None
#
########################################################################

sub GetControlIP
{
   my $self = shift;
   return $self->{vmIP};
}


###############################################################################
#
# VMotionVIMAPI --
#      This method will vmotion this vm to destination datastore/host
#
# Input:
#      datastore - Destination Datastore on the same Host
#
# Results:
#      Returns "SUCCESS", if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub VMotionVIMAPI
{
   my $self         = shift;
   my %args         = @_;
   my $dsthostObj   = $args{dsthost};
   my $datastoreObj = $args{datastore};
   my $inlinedsthostObj = undef;
   my $inlinedatastoreObj = undef;

   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj) {
      $vdLogger->Error("Failed to get inline java object for VM");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   if (defined $dsthostObj) {
      $dsthostObj = $dsthostObj->[0];
      $inlinedsthostObj = $dsthostObj->GetInlineHostObject();
      if (defined $inlinedsthostObj) {
         $vdLogger->Info("Migrating VM:$self->{vmName} to $inlinedsthostObj->{hostIP} ...");
      } else {
         $vdLogger->Error("Failed to get inline java object for host");
         VDSetLastError("EINLINE");
         return FAILURE;
      }
   }
   if (defined $datastoreObj) {
      $inlinedatastoreObj = $args{datastore}->GetInlineDatastoreObj();
      if (defined $inlinedatastoreObj) {
         $vdLogger->Info("Changing VM:$self->{vmName}'s datastore to " .
	                 "$inlinedatastoreObj->{datastoreName} ...");
      } else {
         $vdLogger->Error("Failed to get inline java object for datastore");
         VDSetLastError("EINLINE");
         return FAILURE;
      }
   }
   my $result = $inlineVMObj->Vmotion($inlinedatastoreObj, $inlinedsthostObj);
   if (!$result) {
      $vdLogger->Error("Failed to perform storage vmotion");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# QueryAdapters --
#      This method will return a complex data structures about all the
#      adapters in a vm with all the attributes
#
# Input:
#      None
#
# Results:
#      Returns array of mac address of active adapters, if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub QueryAdapters
{
   my $self         = shift;
   my $payload = $self->GetNetworkPortsInfo();
   $vdLogger->Debug("VM: server data" . Dumper($payload));
   my @arrayofAdapterInformation;
   my $mapperHash = {
      'Port ID'         => 'portid',
      'vSwitch'         => 'vswitch',
      'Portgroup'       => 'portgroup',
      'DVPort ID'       => 'dvportid',
      'MAC Address'     => 'macaddress',
      'IP Address'      => 'ipaddress',
      'Team Uplink'     => 'teamuplink',
      'Uplink Port ID'  => 'uplinkportid',
      'Active Filters'  => 'activefilters',
   };
   foreach my $mac (keys %$payload) {
      my $serverData;
      foreach my $key (keys %{$payload->{$mac}}) {
         if (exists $mapperHash->{$key}) {
            $serverData->{$mapperHash->{$key}} = $payload->{$mac}{$key};
         }
      }
      push @arrayofAdapterInformation, $serverData;
   }
   $vdLogger->Debug("Server form with complete values" . Dumper(\@arrayofAdapterInformation));
   my $resultHash = {
      'status'      => "SUCCESS",
      'response'    => \@arrayofAdapterInformation,
      'error'       => undef,
      'reason'      => undef,
   };
   return $resultHash;
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
   my $portgroup = shift ||
        VDNetLib::Common::GlobalConfig::DEFAULT_VM_MANAGEMENT_PORTGROUP;
   my $adaptersInfo = $self->GetAdaptersInfo();
   if ($adaptersInfo eq FAILURE) {
      $vdLogger->Error("Failed to get adapters information on ".
                       "VM: $self->{vmName}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("VM $self->{vmName} Adapters info is " . Dumper($adaptersInfo));
   my $existingAdapters = [];
   @$existingAdapters = @$adaptersInfo;
   #
   # Find mac address of control adapter in the vm.
   #
   my $controlMAC = undef;
   my $controlIP  = undef;
   foreach my $index (0..$#$existingAdapters) {
      my $adapter = $existingAdapters->[$index];
      if ((defined $adapter->{'portgroup'}) &&
          ($adapter->{'portgroup'} =~ /$portgroup/i)) {
         $controlMAC = $adapter->{'mac address'};
         last;
      }
   }
   return $controlMAC;
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
   my $self       = shift;
   my $controlMAC = shift;
   if (defined $self->{'nestedesx'}) {
      my $cmd_vmk = "esxcli network ip interface ipv4 get";
      my $return_vmk = $self->{'stafHelper'}->STAFSyncProcess("10.115.174.217", $cmd_vmk);
      my @vmk_stdout = split(/\r?\n/, $return_vmk->{'stdout'});
      my $index;
      for ($index = 0;$index < scalar(@vmk_stdout); $index++) {
         my $vmk_info_array = $vmk_stdout[$index];
         if($vmk_info_array =~ /vmk0/i) {
            my @vmk_info =  split(/\s+/,$vmk_info_array);
            my $ipv4 = $vmk_info[1];
            return $ipv4;
         }
      }
   }
   return VDNetLib::Common::Utilities::GetGuestControlIP($self,
                                                         $controlMAC);
}

########################################################################
#
# GetGuestControlDevice--
#       Get the control interface of this VM's guest OS
#
# Input:
#       none
#
# Results:
#       Device name if no errors encoutered, else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub GetGuestControlDevice
{
   my $self       = shift;
   my $controlMac = $self->GetGuestControlMAC();
   if (not defined $controlMac) {
      $vdLogger->Error("Failed to get control mac.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $inlinePyObj = $self->GetInlinePyObject();
   my $result = VDNetLib::InlinePython::VDNetInterface::CallMethodWithKWArgs(
      $inlinePyObj, 'get_iface', {mac => $controlMac, execution_type => 'cmd'});
   if ($@ || $result eq FAILURE || not defined $result->{dev}) {
      $vdLogger->Error("Failed to get control device. Reason:" . Dumper($@));
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }
   return $result->{dev};
}

################################################################################
#
# SetOS -
#   Set the os attribute of the virtual machine
#
# Input:
#   os - operating system name (e.g VMkernel or Linux or windows)
#
# Results:
#
# Side effects:
#   None.
#
################################################################################

sub SetOS {
   my $self = shift;
   my $os = shift;
   $self->{os} = $os;
}


################################################################################
#
# SetArch -
#   Set the architecture attribute of the virtual machine
#
# Input:
#   arch - Architecture name (e.g. x86_32 or x86_64)
#
# Results:
#
# Side effects:
#   None.
#
################################################################################

sub SetArch {
   my $self = shift;
   my $arch = shift;
   $self->{arch} = $arch;
}



################################################################################
#
# InstallSTAFInGuest-
#   Method to install staf on guest os. Child classes can implement it.
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
   return SUCCESS;
}

###############################################################################
#
# FaultTolerance --
#      This method will enable/disable fault tolerance for the given VM.
#
# Input:
#      ftoption             -  Enable/disable fault tolerance for the given VM.
#      ftvm                 -  Fault Tolerance for the given VM.
#
#
# Results:
#      Returns "SUCCESS", if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub FaultTolerance
{
   my $self = shift;
   my $ft = shift;

   my $vmname = $self->{'displayName'};
   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj) {
      $vdLogger->Error("Failed to get inline java object for VM");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   if ($ft->{"faulttolerance"} eq "enable"){
      my $secondaryhost = @{$ft->{"secondaryhost"}}[0];
      my $inlineHostobj = $secondaryhost->GetInlineHostObject();
      if (!$inlineHostobj) {
         $vdLogger->Error("Failed to get inline java object for secondary host");
         VDSetLastError("EINLINE");
         return FAILURE;
      }
      my $hostMor = $inlineHostobj->{'hostMOR'};
      my $vmxDatastoreMor = $inlineHostobj->GetDatastore(VDNetLib::TestData::TestConstants::SHAREDSTORAGE);
      my $metaDataDatastoreMor = $inlineHostobj->GetDatastore(VDNetLib::TestData::TestConstants::SHAREDSTORAGE);
      my $vmDiskDatastoreMor = $inlineHostobj->GetDatastore(VDNetLib::TestData::TestConstants::SHAREDSTORAGE);

      my $secondaryvmMor = $inlineVMObj->EnableFaultTolerance('hostMor'=> $hostMor,
                                                     'vmxDatastoreMor' => $vmxDatastoreMor,
                                                     'metaDataDatastoreMor' => $metaDataDatastoreMor,
                                                     'vmDiskDatastoreMor' => $vmDiskDatastoreMor,
                                                      );
   }
   elsif ($ft->{"faulttolerance"} eq "disable"){
       $inlineVMObj->DisableFaultTolerance();
   }
   return SUCCESS;
}


#########################################################################
#
# ReadVnicAttributes --
#     Method to get runtime attributes of the vnic.
#
# Input:
#     None
#
# Results:
#     Return mac address attribute of object
#
# Side effects:
#      None.
#
#########################################################################

sub ReadVnicAttributes
{
   my $self       = shift;
   my $vmname = $self->{'displayName'};
   my $hostObj  = $self->{'hostObj'};

   my $VMProcessHash = $hostObj->GetVMProcessInfo();
   my $payload;
   if (exists $VMProcessHash->{$vmname}) {
      $payload = $VMProcessHash->{$vmname};
   } else {
      $vdLogger->Error("Failed to find vm process info of $vmname" .
                        Dumper(\$VMProcessHash));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $mapperHash = {
      'World ID'        => 'worldid',
      'Process ID'      => 'processid',
      'VMX Cartel ID'   => 'vmxcartelid',
      'UUID'            => 'uuid',
      'Display Name'    => 'displayname',
      'Config File'     => 'configfile',
   };
   my $serverData;
   foreach my $key (keys %$payload) {
      if (exists $mapperHash->{$key}) {
         $serverData->{$mapperHash->{$key}} = $payload->{$key};
      }
   }
   my $resultHash = {
      'status'      => "SUCCESS",
      'response'    => $serverData,
      'error'       => undef,
      'reason'      => undef,
   };
   return $resultHash;
}


#############################################################################
#
# SetIpForward --
#     Method which enable/disable ip forward for Linux
#
# Input:
#     ip_forward : 1/0, enable or disable
#
# Results:
#     "SUCCESS", if ip forward is set successfully
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub SetIpForward
{
   my $self       = shift;
   my $ip_forward = shift;
   my $stafHelper = $self->{stafHelper};
   my $command;
   my $result;

   if ($self->{os} !~ /linux/i) {
      $vdLogger->Error("SetIpForward() not supported ".
                     "for $self->{osType} yet");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $ip_forward) {
      $vdLogger->Error("ip_forward not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (($ip_forward ne "0") && ($ip_forward ne "1")) {
      $vdLogger->Error("value of ip_forward ($ip_forward) is not valid.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $command = "sysctl -w net.ipv4.ip_forward=$ip_forward";
   $vdLogger->Debug("command to set ip forward is ($command)");
   $result = $stafHelper->STAFSyncProcess($self->{vmIP}, $command);
   if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) ) {
      $vdLogger->Error("Failed to set ip forward");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Info("Successfully set ip forward to ".
                   "$ip_forward on vm $self->{vmIP}");
   return SUCCESS;
}


#############################################################################
#
# VMOpsSnapshot --
#     Method to create/revert/delete VM snapshot
#
# Input:
#     operation: create or revert or delete
#     snapname : name of the vm snapshot, can be null
#
# Results:
#     "SUCCESS", if snapshot operation is successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsSnapshot
{
   my $self = shift;
   my $operation = shift;
   my $snapname = shift;

   if (not defined $operation) {
      $vdLogger->Error("Snapshot operation not specified!");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } elsif ($operation =~ /create/i) {
      return $self->VMOpsTakeSnapshot($snapname);
   } elsif ($operation =~ /revert/i) {
      return $self->VMOpsRevertSnapshot($snapname);
   } elsif ($operation =~ /delete/i) {
      return $self->VMOpsDeleteSnapshot($snapname);
   } else {
      $vdLogger->Error("Wrong snapshot operation : $operation");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}

########################################################################
#
# GetDatastoreName --
#     Method to get datastore name where the VM locates.
#
# Input:
#     None
#
# Results:
#     string of the datastore name if success
#     undef, otherwise.
#
# Side effects:
#     None
#
########################################################################

sub GetDatastoreName
{
   my $self = shift;
   my $datastoreName = undef;
   if ($self->{'vmx'} =~ /\/vmfs\/volumes\/(.+?)\//) {
      $datastoreName = $1;
      # remove escape before sending to Java
      $datastoreName =~ s/\\//g;
      $vdLogger->Debug("Datastore name is $datastoreName");
   } else {
      $vdLogger->Error("Datastore name not found in vmx.");
   }
   return $datastoreName;
}

1;
