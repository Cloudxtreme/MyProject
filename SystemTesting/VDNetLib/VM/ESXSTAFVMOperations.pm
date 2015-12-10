#########################################################
# Copyright 2012 VMware, Inc.  All rights reserved.
# VMware Confidential
##########################################################

package VDNetLib::VM::ESXSTAFVMOperations;

#
# ESXSTAFVMOperations.pm --
#     This package provides methods to do VM related operations using the
#     STAF SDK https://wiki.eng.vmware.com/SDKSTAFServices
#

#use strict;
#use warnings;
use Data::Dumper;
use Variable::Alias 'alias';

use base 'VDNetLib::Root::Root';
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::Utilities;
use VDNetLib::NetAdapter::NetAdapter;
use VDNetLib::InlineJava::VM;
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              CallMethodWithKWArgs);

# Inherit the parent class.
use base qw(VDNetLib::VM::VMOperations);

# Define constants
use constant PASS => 0;
use constant DEFAULT_TIMEOUT => 90;
use constant STANDBY_TIMEOUT => 120;
use constant DEFAULT_SLEEP => 5;
use constant VM_POWER_STATE_ON => 136;
use constant VM_POWER_STATE_OFF => 2;
use constant VM_POWER_STATE_SUSPENDED => 32;
use constant VM_ALREADY_EXISTS => 5113;
use constant VM_INVALID_STATE => 7149;
use constant DEFAULT_MAX_RETRIES => 5;
use constant DEFAULT_MAX_STATE => 300;
use constant VM_POWEROFF_RETRIES => 5;
########################################################################
#
# new --
#      Entry point to create an object of this class
#      (VDNetLib::VM::ESXSTAFVMOperations)
#
# Input:
#      A hash with following keys:
#      '_vmxPath' : absolute vmx path of the VM # Required
#      '_host'    : host ip on which the VM is present #Required
#      '_stafHelper' : Object of VDNetLib::Common::STAFHelper # Optional
#                      (a new object will be created if not
#                      provided)
#
# Results:
#      A VDNetLib::VM::ESXSTAFVMOperations object,
#         if successful;
#      FAILURE, in case of any script error
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class   = shift;
   my $options = shift;
   my $self;
   my $result = SUCCESS;
   if ((not defined($options->{_host})) || (not defined($options->{_vmxPath}))) {
      $vdLogger->Error("Host and/or vmx not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{'esxHost'}      = $options->{'_host'};
   $self->{'vmx'}          = $options->{'_vmxPath'};
   $self->{'stafHelper'}   = $options->{'_stafHelper'};
   $self->{'vc'}           = $options->{'_vc'};
   $self->{'vcUser'}       = $options->{'_vcUser'};
   $self->{'vcPasswd'}     = $options->{'_vcPasswd'};
   $self->{'vmIP'}         = $options->{'_vmIP'};
   $self->{'hostObj'}      = $options->{'_hostObj'};
   $self->{'displayName'}  = $options->{'_displayName'};
   $self->{_pyIdName} = 'id_';
   if ((defined $options->{'vmType'}) && ($options->{'vmType'} =~ /appliance/i)) {
      $vdLogger->Debug("Skip to set pyclass for appliance VM");
      $self->{'vmType'} = $options->{'vmType'};
   } else {
      $self->{_pyclass} = "vmware.vsphere.vm.vm_facade." .
                       "VMFacade";
   }
   if (defined $options->{'_useVC'}) {
      $self->{'useVC'} = $options->{'_useVC'};
   } else {
      $self->{'useVC'}  = 0;
   }

   $self->{'vmName'}       = undef;
   $self->{'stafVMAnchor'} = undef;

   bless ($self, $class);
   #
   # Create a VDNetLib::Common::STAFHelper object with default parameters if it not
   # provided in the input parameters.
   #
   if (not defined $self->{stafHelper}) {
      my $args;
      $args->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($args);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::Common::STAFHelper object");
         VDSetLastError("ETAF");
         $result = FAILURE;
      }
      $self->{stafHelper} = $temp;
   }

   #
   # Get the anchor for VM staf services, use vc if defined
   # otherwise get anchor using esx host.
   #
   my $host;
   my $user;
   my $passwd;
   my $stafVMAnchor;

   if (defined $self->{hostObj}{vcObj}) {
      $host	    = $self->{hostObj}{vcObj}{vcaddr};
      $user	    = $self->{hostObj}{vcObj}{user};
      $passwd	    = $self->{hostObj}{vcObj}{passwd};

   } elsif ((defined $self->{vc}) && $self->{'useVC'} eq "1") {
   # This condition is for vdNet Version 1
      $host	    = $self->{vc};
      $user	    = $self->{'vcUser'};
      $passwd	    = $self->{'vcPasswd'};

      $stafVMAnchor = VDNetLib::Common::Utilities::GetSTAFAnchor(
							$self->{stafHelper},
							$host,
							"VM",
							$user,
							$passwd);
      if ($stafVMAnchor eq FAILURE) {
	 $vdLogger->Error("Failed to get STAF VM anchor");
	 VDSetLastError(VDGetLastError());
	 return FAILURE;
      }
      $self->{stafVMAnchor} = $stafVMAnchor;
   } else {
      $host	    = $self->{esxHost};
      $user	    = $self->{hostObj}{userid};
      $passwd	    = $self->{hostObj}{sshPassword};
   }
   $self->{'user'} = $user;
   $self->{'password'} = $passwd;
   $self->{'host'} = $host;

   $vdLogger->Debug("Using $self->{stafVMAnchor} as anchor for vm operations");

   if ($self->VMOpsRegisterVM() eq FAILURE) {
      $vdLogger->Error("Failed to register VM $self->{'vmx'}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Find the registered VM name for the given vmx. This VM name is used for
   # all VM operations using STAF SDK.
   #
   $self->{'vmName'}  = VDNetLib::Common::Utilities::GetRegisteredVMName($self->{esxHost},
                                                                 $self->{vmx},
                                                                 $self->{stafHelper},
                                                                 $self->GetSTAFVMAnchor());
   if ($self->{'vmName'} eq FAILURE) {
      $vdLogger->Error("Failed to get registered vm name for $self->{vmx} on " .
                       $self->{'esxHost'});
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $self;
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
   my $parentInlinePyObj;
   my $MoID = $self->GetVMMoID();
     if ( defined $self->{hostObj}{vcObj}) {
       $parentInlinePyObj = $self->{hostObj}{vcObj}->GetInlinePyObject();
       eval {
          $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $MoID, $parentInlinePyObj,  $self->{'hostObj'}->{hostIP});
        };
     } else {
       $parentInlinePyObj = $self->{hostObj}->GetInlinePyObject();
       eval {
          my $hostIP = undef;
          $inlinePyObj = CreateInlinePythonObject(
            $self->{_pyclass}, $MoID, $parentInlinePyObj, $hostIP, $self->{vmIP},
            VDNetLib::Common::GlobalConfig::DEFAULT_ESX_VM_USER,
            VDNetLib::Common::GlobalConfig::DEFAULT_ESX_VM_PASSWORD);
        };
     }
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   return $inlinePyObj;
}

########################################################################
#
# VMOpsValidateMAC --
#     Method to ensure the newly assigned MAC is as per the alloc shema.
#
# Input:
#     "mac_allocschema" : The possible MAC address schemes i.e. prefix, range, oui.
#     "mac_range"   : This contain values of MAC address information with
#		       '-' seperator.
#
# Results:
#     "SUCCESS", if the assigned mac address is according to policy
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub VMOpsValidateMAC
{
   my $self = shift;
   my $options = shift;
   my $allocschema  = $options->{'mac_allocschema'};
   my $parameters = $options->{'mac_range'};
   my $adapters = $self->GetAdaptersInfo();
   if ($adapters eq FAILURE) {
     $vdLogger->Error("Failed to get MAC address of control adapters.");
     VDSetLastError(VDGetLastError());
     return FAILURE;
   }
   if( not defined $allocschema ||
     ((not defined $parameters) && ($allocschema ne 'oui'))) {
     $vdLogger->Error("Failed Parameters not defined.");
     VDSetLastError("ENOTDEF");
     return FAILURE;
   }

   #get the MAC address of last adapter added
   my $temp = pop(@{$adapters});
   my $macAddr = $temp->{'mac address'};
   $vdLogger->Info("MAC Address Assigend to Adapter is $macAddr.");

   if($allocschema eq 'prefix') {
     my @prefixmac = split('-', $parameters);
     if( $macAddr =~ /^$prefixmac[0]/ ){
     $vdLogger->Info("MAC Address Assigend to Adapter is Correct.");
        return SUCCESS;
     }
   }

   #Validate the mac address of last adapter added
   if($allocschema eq 'range') {
     my @rangemac = split('-', $parameters);
     if(($#rangemac+1)%2) {
       $vdLogger->Error("Failed: Range Addresses are not even.");
       VDSetLastError("EFAIL");
       return FAILURE;
     }
     my @macVal=split(":", $macAddr, 4);
     my $iterator=0;
     while($iterator < ($#rangemac+1)/2) {
       my @begin = split(":", $rangemac[2*$iterator], 4);
       my @end   = split(":", $rangemac[2*$iterator+1], 4);
       if(hex(join("", split(":", $macVal[3]))) >= hex(join("", split(":", $begin[3])))
         && hex(join("", split(":", $macVal[3]))) <= hex(join("", split(":", $end[3])))){
         $vdLogger->Info("MAC Address Assigend to Adapter is Correct.");
         return SUCCESS;
       }
       $iterator++;
    }
   }

   if($allocschema eq 'oui') {
     if( $macAddr =~/^00:50:56/ ) {
       $vdLogger->Info("MAC Address Assigend to Adapter is Correct.");
       return SUCCESS;
     }
   }
   $vdLogger->Error("Assigned MAC Address to adapter is not according to scheme.");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}

########################################################################
#
# VMOpsRegisterVM --
#     Method to register a VM using the given vmx file.
#
# Input:
#     None (since vmx is already defined as class attribute)
#
# Results:
#     "SUCCESS", if the VM is registered successfully;
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub VMOpsRegisterVM
{
   my $self = shift;

   my $esxHost = $self->{'esxHost'};
   my $vmx = $self->{'vmx'};
   my $vmName = $self->{'displayName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   $vmx = VDNetLib::Common::Utilities::GetVMFSRelativePathFromAbsPath($vmx,
                                                                      $esxHost,
                                                                      $self->{stafHelper});
   if ($vmx eq FAILURE) {
      $vdLogger->Error("Unable to get absolute vmx path of $vmx");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # if the vmx file name using the datastore UUID, then convert it to name
   if ($vmx =~ m/\[([0-9a-z]{8}-[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{12})\]\s(.*)/i) {
       my $dataStoreName = VDNetLib::Common::Utilities::GetDataStoreName(
                            $self->{'stafHelper'}, $self->{'esxHost'}, $1);
       $vmx = "[" . $dataStoreName . "] " . $2;
   }

   my $cmd;
   #
   # xxx(hchilkot):
   # PR 1426384- specify vm display name
   # while registering vm with vc 5.5. otherwise
   # registering vm's in parallel fails with duplicate
   # folder error.
   #
   $cmd = "REGISTERVM ANCHOR $anchor HOST $esxHost VM $vmName VMXPATH \"$vmx\"";

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd,
                                                             VM_ALREADY_EXISTS);
   if ($stafResult->{rc} != $STAF::kOk) {
      $vdLogger->Error("Unable to register $vmx on $esxHost");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# VMOpsUnRegisterVM --
#     Method to unregister the VM that is defined the class object.
#
# Input:
#     None (since vmName is already defined as class attribute)
#
# Results:
#     "SUCCESS", if the VM is unregistered successfully;
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub VMOpsUnRegisterVM
{
   my $self = shift;

   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   my $cmd = "UNREGISTERVM ANCHOR $anchor VM \"$vmName\"";

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if ($stafResult->{rc} != $STAF::kOk) {
      $vdLogger->Error("Unable to unregister $vmName on $esxHost");
      VDSetLastError("ESTAF");
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

   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   my $cmd = "GETSTATE ANCHOR $anchor VM \"$vmName\"";

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (not defined $stafResult) {
      $vdLogger->Error("Command $cmd returned undef.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get power state of $vmName" .
                        Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return $stafResult;
}


#############################################################################
#
# VMOpsPowerOn --
#     Power on the specified VM.
#
# Input:
#     options  -  Reference to a hash containing the following keys (Optional).
#                  waitForTools - (0/1) # Optional.
#
# Results:
#     "SUCCESS", if the VM was successfully powered on.
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
#############################################################################

sub VMOpsPowerOn
{
   my $self = shift;
   my $options = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $controlIP = undef;
   my $result;

   # Power on the VM.
   my $cmd = "POWERON ANCHOR $anchor VM \"$vmName\"";
   if ((defined $options->{waitForTools}) &&
      ($options->{waitForTools} == 1)) {
      $cmd = $cmd . " WAITFORTOOLS " . $options->{waitForTools};
   }
   if (defined $options->{controlIP}){
      $controlIP = $options->{controlIP};
   }
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd,
                                                          VM_INVALID_STATE);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to power on $vmName");
      $vdLogger->Debug(Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Get the current state of the VM and verify that the VM is actually powered
   # on.
   $result = $self->VMOpsGetPowerState();
   if ($result->{rc} != $STAF::kOk) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("$vmName entered $result->{result} state");
   if ($result->{result} !~ /poweredon/i) {
      $vdLogger->Error("Mismatch in requested (poweron) and current state " .
                       $result->{result});
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   $vdLogger->Debug("VM poweron with options :".Dumper($options));

#   if ($self->{'nestedesx'}->{'os'} eq 'VMkernel') {
#      my $timeout = 60;
#      my $startTime = time();
#      while ($timeout && $startTime + $timeout > time()) {
#         if (!VDNetLib::Common::Utilities::Ping($self->{'vmIP'})) {
#            $vdLogger->Debug("$self->{'vmIP'} is not rebooted yet");
#            sleep 5;
#         } else {
#            $vdLogger->Debug("$self->{'vmIP'} has been rebooted");
#            last;
#         }
#      }
#
      if (defined $self->{'nestedesx'}) {
        sleep 200;
      }
      if (defined $self->{'nestedesx'} && (FAILURE eq $self->{'nestedesx'}->ConfigureHostForVDNet())) {
         $vdLogger->Error("Host configuration for vdnet on $self->{'nestedesx'}->{hostIP}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
#   }

   if ($options->{waitForSTAF}) {
      my $vmIP = undef;

      if (defined $controlIP) {
         #this branch is for resumed VM which already had IP address.
	 $vmIP = $controlIP;
      } elsif (defined $self->{'vmIP'}) {
         $vmIP = $self->{'vmIP'};
      }

      if (defined $vmIP) {
	 $vdLogger->Info("Waiting for STAF on $vmIP...");
         $result = $self->{stafHelper}->WaitForSTAF($vmIP);
      }
   }

   return $result;
}


#############################################################################
#
# VMOpsPowerOff --
#     Power off the specified VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the VM was successfully powered off;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsPowerOff
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $result;
   my $retryCount = 1;
   # Power off the VM.
   my $cmd = "POWEROFF ANCHOR $anchor VM \"$vmName\"";
   # rc 7149 - invalid state, reason could be VM already powered off
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd,
                                                          VM_INVALID_STATE);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to power off $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Add a retry logic because VM may not run into poweroff timely
   while ($retryCount <= VM_POWEROFF_RETRIES) {
      $vdLogger->Debug("Current number of retries value is $retryCount");
      sleep($retryCount ** 2);
      # Get the current state of the VM and verify that the VM is actually powered
      # off.
      $result = $self->VMOpsGetPowerState();
      if ($result eq FAILURE) {
         $vdLogger->Warn("Unable to get VM power state");
         $retryCount++;
         next;
      }
      $vdLogger->Info("$vmName entered $result->{result} state");
      last if ($result->{result} =~ /poweredoff/i);
      $vdLogger->Debug("Mismatch is requested (poweroff) and current state " .
                       $result->{result});
      $retryCount++;
   }
   if ($retryCount > VM_POWEROFF_RETRIES) {
      $vdLogger->Error("VM can not be powered off after ". --$retryCount . " retries");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VerifyCpuCount --
#     Return the CPU count for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data in pydict format from the invoked Python method get_cpu_count
#     $serverForm   - {
#                       'expected_cpu_count' : actual_cpu_count
#                    }
#
# Side effects:
#     None
#
#############################################################################

sub VerifyCpuCount
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_cpu_count($args);
   return $result;
}

#############################################################################
#
# VerifyNicCount --
#     Return the NIC count for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data in pydict format from the invoked Python method get_nic_count
#     $serverForm   - {
#                       'expected_nic_count' : actual_nic_count
#                    }
#
# Side effects:
#     None
#
#############################################################################

sub VerifyNicCount
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_nic_count($args);
   return $result;
}

#############################################################################
#
# VerifyVirtualDiskCount --
#     Return the Virtual Disk count for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data from the invoked Python method get_virtual_disk_count
#     $serverForm   - {
#                       'expected_virtual_disk_count' : actual_virtual_disk_count
#                    }
# Side effects:
#     None
#
#############################################################################

sub VerifyVirtualDiskCount
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_virtual_disk_count($args);
   return $result;
}

#############################################################################
#
# VerifyMemSize --
#     Return the Memory Size for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data from the invoked Python method get_mem_size
#     $serverForm   - {
#                       'expected_mem_size' : actual_mem_size
#                    }
#
# Side effects:
#     None
#
#############################################################################

sub VerifyMemSize
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_mem_size($args);
   return $result;
}

#############################################################################
#
# VerifyMaxMemUsage --
#     Return the Maximum Memory Usage for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data from the invoked Python method get_max_memory_usage
#     $serverForm   - {
#                       'expected_max_mem_usage' : actual_max_mem_usage
#                    }
#
# Side effects:
#     None
#
#############################################################################

sub VerifyMaxMemUsage
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_max_memory_usage($args);
   return $result;
}

#############################################################################
#
# VerifyMaxCpuUsage --
#     Return the Maximum CPU Usage count for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data from the invoked Python method get_max_cpu_usage
#     $serverForm   - {
#                       'expected_max_cpu_usage' : actual_max_cpu_usage
#                    }
#
# Side effects:
#     None
#
#############################################################################

sub VerifyMaxCpuUsage
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_max_cpu_usage($args);
   return $result;
}

#############################################################################
#
# VerifyDiskSize --
#     Return the Disk Size for the specified disk_index value for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            disk_index - integer value of the virtual disk position
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data from the invoked Python method get_disk_size
#     $serverForm   - {
#                       'expected_disk_size' : actual_disk_size
#                    }
#
# Side effects:
#     None
#
#############################################################################

sub VerifyDiskSize
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_disk_size($args);
   return $result;
}

#############################################################################
#
# VerifyNicType --
#     Return the NIC Type for the specified vnic_index value for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            vnic_index - integer value of the nic position
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data from the invoked Python method get_nic_type
#     $serverForm   - {
#                       'expected_nic_type' : actual_nic_type
#                    }
#
# Side effects:
#     None
#
#############################################################################

sub VerifyNicType
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_nic_type($args);
   return $result;
}

#############################################################################
#
# VMOpsSuspend --
#     Suspend the specified VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the VM was suspended successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsSuspend
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $result;

   # Suspend the VM.
   my $cmd = "SUSPEND ANCHOR $anchor VM \"$vmName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to suspend $vmName");
      $vdLogger->Debug(Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $result = $self->VMOpsGetPowerState();
   if ($result->{rc} != $STAF::kOk) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Get the current state of the VM and verify that the VM is actually powered
   # suspended.
   $vdLogger->Info("$vmName entered $result->{result} state");
   if ($result->{result} !~ /suspended/i) {
      $vdLogger->Error("Mismatch is requested (suspend) and current state " .
                       $result->{result});
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsResume --
#     Method to resume the specified VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the VM was resumed successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsResume
{
   my $self = shift;
   my $options = shift;
   $vdLogger->Debug("VM resume with options :".Dumper($options));
   return $self->VMOpsPowerOn($options);
}


#############################################################################
#
# VMOpsReset --
#     Method to reset the specified VM (not guest shutdown).
#
# Input:
#     options  -  Reference to a hash containing the following keys (Optional).
#
# Results:
#     "SUCCESS", if the VM is reset successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsReset
{
   my $self = shift;
   my $options = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $controlIP = $self->{'vmIP'};
   my $result;

   # reset the VM.
   my $cmd = "RESET ANCHOR $anchor VM \"$vmName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to reset $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Get the current state of the VM and verify that the VM is actually powered
   # on by keep checking for certain timeout period.

   my $result = VDNetLib::Common::Utilities::RetryMethod({
       'obj'    => $self,
       'method' => "VMOpsGetPowerState",
       'timeout' => 60,
       'sleep'  => 5 ,
       'expectedResult' => "$STAF::kOk",
      });
   if ($result eq FAILURE) {
      return FAILURE;
   }

   $vdLogger->Info("$vmName entered $result->{result} state");
   if ($result->{result} !~ /poweredon/i) {
      $vdLogger->Error("Mismatch is requested (poweron) and current state " .
                       $result->{result});
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   if ($options->{waitForSTAF} && defined $controlIP) {
      #this branch is for resumed VM which already had IP address.
      return $self->{stafHelper}->WaitForSTAF($controlIP);
   } elsif ($options->{waitForSTAF}) {
      return $self->{stafHelper}->WaitForSTAF($self->{'vmIP'});
   }

   return SUCCESS;
}

#############################################################################
#
# VMOpsReboot --
#     Method to reboot the specified VM (guest os reboot).
#
# Input:
#     options  -  Reference to a hash containing the following keys (Optional).
#
# Results:
#     "SUCCESS", if the VM is reset successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsReboot
{
   my $self = shift;
   my $options = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $controlIP = $self->{'vmIP'};
   my $result;
   # Reboot the VM.
   my $cmd = "REBOOT ANCHOR $anchor VM \"$vmName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to reboott $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $result = VDNetLib::Common::Utilities::RetryMethod({
       'obj'    => $self,
       'method' => "VMOpsGetPowerState",
       'timeout' => 60,
       'sleep'  => 5 ,
       'expectedResult' => "$STAF::kOk",
      });
   if ($result eq FAILURE) {
      return FAILURE;
   }
   $vdLogger->Info("$vmName entered $result->{result} state");
   if ($result->{result} !~ /poweredon/i) {
      $vdLogger->Error("Mismatch is requested (poweron) and current state " .
                       $result->{result});
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   if (FAILURE eq $self->{'nestedesx'}->ConfigureHostForVDNet()) {
      $vdLogger->Error("Host configuration for vdnet on $self->{'nestedesx'}->{hostIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
   } 

   if ($options->{waitForSTAF} && defined $controlIP) {
      # This branch is for resumed VM which already had IP address.
      return $self->{stafHelper}->WaitForSTAF($controlIP);
   } elsif ($options->{waitForSTAF}) {
      return $self->{stafHelper}->WaitForSTAF($self->{'vmIP'});
   }

   return SUCCESS;
}
#############################################################################
#
# WaitForVMState --
#     Waits until the specified VM is powered off or until a timeout occurs.
#
# Input:
#     state: "poweredon" or "poweredoff" or "suspended" # Required
#     timeout: time to wait in seconds # Optional
#
# Results:
#     "SUCCESS", if the VM enters the given state;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub WaitForVMState
{
   my $self = shift;
   my $state = shift;
   my $timeout = shift || DEFAULT_TIMEOUT;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $powerState = undef;
   my $result;


   my $startTime = time();
   while ((time() - $startTime) <= $timeout) {
      # Get VM's Power state
      $result = $self->VMOpsGetPowerState();
      if ($result->{rc} != $STAF::kOk) {
         $vdLogger->Error("Unable to get state of $vmName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if ($result->{result} =~ /$state/i) {
         return SUCCESS;
      }
      sleep(DEFAULT_SLEEP);
   }
   $vdLogger->Error("Last state of the VM:$result->{result}," .
                  "expected: $state");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


#############################################################################
#
# GetGuestInfo --
#     Method to get the guest information.
#
# Input:
#     None
#
# Results:
#     TODO:  return a hash of all the parameters returned from
#     "GETGUESTINFO" command in STAF SDK
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetGuestInfo
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   my $cmd = "GETGUESTINFO ANCHOR $anchor VM \"$vmName\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest information of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $stafResult->{result};
}


#############################################################################
#
# VMOpsShutdownUsingCLI --
#     Shut down the specified VM using guest CLI.
#
# Input:
#     ip: ip address of the guest # Optional
#     waitForShutdown: 0/1 - to indicate whether to wait for complete
#                      shutdown # Optional
#
# Results:
#     "SUCCESS", if the VM/guest is shutdown without any error;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsShutdownUsingCLI
{
   my $self            = shift;
   my $ip              = shift;
   my $waitForShutdown = shift || 1;
   my $esxHost = $self->{'esxHost'};
   my $vmx    = $self->{'vmx'};
   my $stafResult = undef;
   my $cmd;
   my $result;

   if (not defined $ip) {
      $ip = VDNetLib::Common::Utilities::GetGuestControlIP($self);
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get ip address of $vmx");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   # Find the OS type
   my $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($osType =~ m/Win/i) {
      $cmd = "shutdown /s /f";
   } else {
      $cmd = "shutdown -h -t 1 now";
   }

   $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
   if (PASS != $stafResult->{rc}) {
      $vdLogger->Error("Failed to send $cmd to $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $waitForShutdown && $waitForShutdown == 1) {
      return $self->WaitForVMState("poweredoff");
   }
   return SUCCESS;
}


#############################################################################
#
# VMOpsShutdownUsingSDK --
#     Shut down the specified VM using STAF SDK.
#
# Input:
#     waitForShutdown: 0/1 - to indicate whether to wait for complete
#                      shutdown # Optional
#
# Results:
#     "SUCCESS", if the VM is shutdown without any error;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsShutdownUsingSDK

{
   my $self            = shift;
   my $waitForShutdown = shift || 1;
   my $vmName = $self->{'vmName'};
   my $vmx    = $self->{'vmx'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $cmd;
   my $result;

   # Shutdown the VM.
   $cmd = "SHUTDOWN ANCHOR $anchor VM \"$vmName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to shutdown $vmName.");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $waitForShutdown && $waitForShutdown == 1) {
      return $self->WaitForVMState("poweredoff");
   }
   return SUCCESS;
}


#############################################################################
#
# VMOpsRebootUsingSDK --
#     Reboot the specified VM using STAF SDK.
#
# Input:
#     waitForReboot: 0/1 - to indicate whether to wait for tools to be
#                      initialiized # Optional
#
# Results:
#     "SUCCESS", if the VM is rebooted without any error;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsRebootUsingSDK

{
   my $self            = shift;
   my $waitForReboot   = shift || 1;

   my $vmName = $self->{'vmName'};
   my $vmx    = $self->{'vmx'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $cmd;
   my $result;

   # Reboot the VM.
   $cmd = "REBOOT ANCHOR $anchor VM \"$vmName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to reboot $vmName.");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $timeout = 60;
   my $startTime = time();
   while ($timeout && $startTime + $timeout > time()) {
      if (!VDNetLib::Common::Utilities::Ping($self->{'vmIP'})) {
         $vdLogger->Debug("$self->{'vmIP'} is not rebooted yet");
         sleep 5;
      } else {
         $vdLogger->Debug("$self->{'vmIP'} has been rebooted");
         last;
      }
   }
   # wait for the staf to ensure reboot is complete
   if (defined $waitForReboot && $waitForReboot != 0) {
      $vdLogger->Info("rebooting the VM, $self->{'vmIP'}");

      #
      # if the value given for waitForReboot key is more than 1
      # that signifies that the user wants   to wait explicitly
      # for the given value after reboot.
      #
      if ($waitForReboot > 1) {
	      $vdLogger->Info("Sleeping for $waitForReboot seconds after reboot.");
         sleep($waitForReboot);
      }
      sleep 120;
      if (FAILURE eq $self->{'nestedesx'}->ConfigureHostForVDNet()) {
         $vdLogger->Error("Host configuration for vdnet on $self->{'nestedesx'}->{hostIP}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      return $self->{stafHelper}->WaitForSTAF($self->{'vmIP'});
   }
   return SUCCESS;
}


###############n##############################################################
#
# VMOpsShutdown --
#     Shut down the specified VM.
#
# Input:
#     ip : ip address of the guest # Optional
#     waitForShutdown: 0/1 - to indicate whether to wait for complete
#                      shutdown # Optional
#     method: "cli" to shutdown using command line inside guest
#             "sdk" to use staf sdk to shutdown  (Optional)
#
# Results:
#     "SUCCESS", if the VM enters the given state;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsShutdown
{
   my $self            = shift;
   my $ip              = shift;
   my $waitForShutdown = shift || 1;
   my $method          = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $vmx    = $self->{'vmx'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $cmd;
   my $result;

   if (not defined $method) {

      $result = $self->GetGuestInfo();

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get guest information of $vmName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      #
      # Check whether tools is installed in the given VM.
      # If yes, then use the STAF SDK command to shutdown the VM, that way
      # the "shutdown" option in VI client is tested (assuming users will use
      # that). If tools is not installed, then using the ip address and guest type
      # issue the appropriate shutdown command inside the guest.
      #
      if($result->{'Tools Info'}{'Tools Status'} =~ /toolsNotInstalled/i) {
      # Get VM ip address
      $vdLogger->Info("Tools not installed on $vmName, using CLI to shutdown");
         $method = "cli";
      } else {
         $method = "sdk";
      }
   }

   if ($method =~ /cli/i) {
      $result = $self->VMOpsShutdownUsingCLI($ip, $waitForShutdown);
   } else {
      $result = $self->VMOpsShutdownUsingSDK($waitForShutdown);
   }

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


#############################################################################
#
# VMOpsHibernate --
#     Method to hibernate the guest
#
# Input:
#     ip: ip address of the VM # Optional
#
# Results:
#     "SUCCESS", if the guest enters the hibernate state;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsHibernate
{
   my $self = shift;
   my $ip   = shift;

   my $vmx = $self->{'vmx'};
   my $host = $self->{'esxHost'};
   my $stafResult = undef;
   my $osType = undef;
   my $cmd;
   my $result;
   my $timeout= DEFAULT_MAX_STATE;
   #
   # Check if the ip address is given, otherwise find it using
   # GetGuestControlIP() utility function.
   #
   if (not defined $ip) {
      $vdLogger->Info("Finding IP address of $vmx");
      $ip = VDNetLib::Common::Utilities::GetGuestControlIP($self);
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get ip address of $vmx");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   # Find the OS type
   $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($osType =~ m/Win/i) {
      # Turn on hibernate option
      $cmd = "powercfg /hibernate on";
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $cmd,
                                                         DEFAULT_TIMEOUT);
      if (PASS != $stafResult->{rc} || PASS != $stafResult->{exitCode}) {
         $vdLogger->Error("Failed to enable hibernate option on $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      #
      # The command for hibernating windows is different on Windows XP.
      # So find the windows version and execute the appropriate command
      #
      $cmd = "systeminfo";
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $cmd,
                                                         DEFAULT_TIMEOUT);
      if (PASS != $stafResult->{rc} || PASS != $stafResult->{exitCode}) {
         $vdLogger->Error("Unable to get windows version of $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if($stafResult->{stdout} =~ m/OS Name:.*Windows\s*XP/i) {
         $cmd = "rundll32 powrprof.dll,SetSuspendState";
      } else {
         $cmd = "shutdown /h";
      }

      $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
      if (PASS != $stafResult->{rc}) {
         $vdLogger->Error("Failed to send $cmd to $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } elsif ($osType =~ m/Linux/i) {
      #
      # Check if hibernation is supported.
      # Hibernation is supported if /sys/power/state has 'mem'
      # or 'disk'
      #
      $cmd = "cat /sys/power/state";
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $cmd,
                                                         DEFAULT_TIMEOUT);
      if (PASS != $stafResult->{rc} || PASS != $stafResult->{exitCode}) {
         $vdLogger->Error("Failed to check hiberantion support on $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($stafResult->{stdout} !~ m/disk/i) {
         $vdLogger->Error("Hibernation is not supported on $ip");
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }

      # Send the hibernate command
      # TODO - verify if this command works on all linux flavors
      #Change cmd from pm-hibernate to "disk" because disk cmd support
      #more GOS,PR:1245339
      $cmd = 'sleep 3;echo "disk" > /sys/power/state';
      $vdLogger->Debug("Executing hibernate command: $cmd");
      $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
      if (PASS != $stafResult->{rc}) {
         $vdLogger->Error("Failed to send $cmd to $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Unsupported OS $osType");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   my $startToWaitTime = time;
   while (time < ($startToWaitTime+$timeout)) {
      if ($self->WaitForVMState("poweredoff") eq SUCCESS) {
         return SUCCESS;
      } else {
         $vdLogger->Debug("Waiting to enter poweredoff state");
         sleep(DEFAULT_SLEEP);
      }
   }
   $vdLogger->Error("Failed to enter poweredoff state");
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


#############################################################################
#
# VMOpsStandby --
#     Method to put the guest to standby.
#
# Input:
#     ip: ip address of the VM # Optional
#
# Results:
#     "SUCCESS", if the guest enters the standby state;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsStandby
{
   my $self = shift;
   my $ip = shift;

   my $vmx = $self->{'vmx'};
   my $host = $self->{'esxHost'};
   my $stafResult = undef;
   my $result;
   my $osType = undef;
   my $cmd = "";

   #
   # Check if the ip address is given, otherwise find it using
   # GetGuestControlIP() utility function.
   #
   if (not defined $ip) {
      $vdLogger->Info("Finding IP address of $vmx");
      $ip = VDNetLib::Common::Utilities::GetGuestControlIP($self);
      if ($ip eq FAILURE) {
         $vdLogger->Error("Failed to get ip address of $vmx");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   # Find the OS type
   $osType = $self->{stafHelper}->GetOS($ip);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $ip");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my @path;
   @path = split('/', $vmx);
   $vmx =~ s/$path[$#path]//;
   $cmd = "cd " . $vmx . ";grep -i 'standby sleep state' vmware.log | wc -l";
   $stafResult = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   if ($STAF::kOk != $stafResult->{rc}) {
      $vdLogger->Error("Failed to grep vmware.log file");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $data1 = $stafResult->{stdout};

   if ($osType =~ m/Win/i) {
      #
      # to disable resume password on windows 2003
      # powercfg /GLOBALPOWERFLAG OFF /OPTION RESUMEPASSWORD
      # the above didn't work for Windows 2008
      # C:\Users\Administrator>cmd /c regedit /s screenSaver.reg
      # [HKEY_CURRENT_USER\Cont
      # rol Panel\Desktop] "ScreenSaveIsSecure"=0
      # "ScreenSaveActive"="1"
      # disable hibernation if it is a windows VM
      #
      $cmd = "powercfg /hibernate off";
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $cmd,
                                                         DEFAULT_TIMEOUT);
      if (PASS != $stafResult->{rc} || PASS != $stafResult->{exitCode}) {
         $vdLogger->Error("Failed to enable hibernate option on $ip");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      $vdLogger->Debug("Turned off Hibernation on $ip");
      # TODO: disable asking for passwd on wake up

      $cmd = '%windir%\System32\rundll32.exe powrprof.dll,SetSuspendState';
      $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to put $ip to standby");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } elsif ($osType =~ /lin/i ) {
      #
      # running sleep command before standby because executing just standby
      # command by the linux guest to sleep immediately and staf hangs awaiting
      # result from the process command.
      #
      $cmd = 'sleep 3;echo "standby" > /sys/power/state';
      $vdLogger->Debug("standby command: $cmd ");
      $stafResult = $self->{stafHelper}->STAFAsyncProcess($ip, $cmd);
      if ($STAF::kOk != $stafResult->{rc}) {
         $vdLogger->Error("Failed to put $ip to standby");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   $vdLogger->Info("Guest $ip has been put into standby mode");

   # Checking the vmware.log to verify if the guest entered standby state.
   sleep(STANDBY_TIMEOUT);
   $cmd = "cd " . $vmx . ";grep -i 'standby sleep state' vmware.log | wc -l";
   $stafResult = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   if ($STAF::kOk != $stafResult->{rc}) {
      $vdLogger->Error("Failed to grep vmware.log file");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $data2 = $stafResult->{stdout};
   if ($data2 <= $data1) {
      $vdLogger->Error("Failed to put guest $ip in standby-state");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# GetVMXPID --
#     Method to get the vmx process id corresponding to the VM object.
#     Use command "esxcli vm process list" to list the powered on vm and their PID.
#     For example, bellow is the listed information:
#     1-rhel53-srv-32-local-615-74931408-90b8-4143-9613-d96691d69f64
#        World ID: 39783
#        Process ID: 0
#        VMX Cartel ID: 39782
#        UUID: 56 4d 1e ff 6d 31 77 c7-4a 6b ae d8 39 57 c4 1b
#        Display Name: 1-rhel53-srv-32-local-615-74931408-90b8-4143-9613-d96691d69f64
#        Config File: /vmfs/volumes/50d1c38e-3b7e969d-d4f3-d4ae52e7b058/vdtest-15089/VM-1/rhel-53-srv-hw7-32-lsi-1gb-1cpu.vmx
#     Change this module for PR 1122862#
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the pid is found;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetVMXPID
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};

   # TODO - verify on classic esx
   my $cmd = "esxcli vm process list";
   my $stafResult = $self->{stafHelper}->STAFSyncProcess($esxHost, $cmd);
   $vdLogger->Debug("Command \"$cmd\" on host $esxHost returns " . Dumper($stafResult));
   if ($STAF::kOk != $stafResult->{rc} || ($stafResult->{exitCode} != 0)) {
      $vdLogger->Debug("Command \"$cmd\" on host $esxHost returns " . Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $data = $stafResult->{stdout};
   @data = split('\n\n', $data);
   foreach $vmInfo (@data){
      if ($vmInfo =~ /$vmName/) {
         if ($vmInfo =~ /VMX Cartel ID: (\d+)/){
            return $1;
         }
         $vdLogger->Debug("Can't find VMX Cartel ID for the vm $vmName.");
      }
   }
   $vdLogger->Debug("The target vm $vmName is not powered on." . Dumper($data));
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


#############################################################################
#
# GetVMMoID --
#     Method to get the VM's Managed Object ID.
#
# Input:
#     vmName : VM display/registered name as in the inventory
#
# Results:
#     vmMOID, of the first VM with the vmName (eg: vm-2062);
#     "FAILURE", if VM is not found or in case of any error;
#
# Side effects:
#     None
#
#############################################################################

sub GetVMMoID
{
   my $self   = shift;
   my $vmName = $self->{'vmName'};
   my $vmFolderName = undef;

   my $vmMOID;

   my $inlineVMObj = $self->GetInlineVMObject();
   if (!($vmMOID = $inlineVMObj->GetVMMoID($vmName, $vmFolderName))) {
      $vdLogger->Error("Failed to get the Managed Object ID for the VM:".$vmName);
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object ID for the VM:".$vmName." is MOID:". $vmMOID);
   return $vmMOID;
}


#############################################################################
#
# VMOpsKill --
#     Method to kill the process corresponding to the VM object.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the vmx process is killed successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsKill
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};

   my $retry = DEFAULT_MAX_RETRIES;
   my $count = 0;

   my $pid = $self->GetVMXPID();

   if ($pid eq FAILURE) {
      $vdLogger->Error("Couldn't find process id of VM $vmName on $esxHost");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   while ($count < $retry) {
      my $cmd = "kill -9 $pid";
      my $stafResult = $self->{stafHelper}->STAFSyncProcess($esxHost, $cmd);

      if ($STAF::kOk != $stafResult->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # Get VM's Power state
      my $result = $self->VMOpsGetPowerState();
      if ($result->{rc} != $STAF::kOk) {
         $vdLogger->Error("Unable to get state of $vmName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if ($result->{result} =~ /poweredOff/i) {
         return SUCCESS;
      } else {
         sleep 5;
         VDCleanErrorStack();
      }
      $count++;
   }

   $vdLogger->Error("$pid not killed on $esxHost");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


#############################################################################
#
# VMOpsListSnapshots --
#     Method to list all snapshots in the VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the snapshot list obtained successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsListSnapshots
{
   my $self = shift;
   my $snapName = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;

   # List all snapshots in the VM.
   my $cmd;
   $cmd = "GETSNAPSHOTINFO ANCHOR $anchor VM " .
          "\"$vmName\"";
   if (defined $snapName) {
      $cmd = $cmd . " SNAPNAME $snapName";
   }
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get list of snapshots in $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $stafResult->{result};
}


#############################################################################
#
# VMOpsTakeSnapshot --
#     Method to take snapshot with the given snapshot name.
#
# Input:
#     snapName: name of the snapshot # Required
#
# Results:
#     "SUCCESS", if the snapshot is created successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsTakeSnapshot
{
   my $self     = shift;
   my $snapName = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $result;

   if (not defined $snapName) {
      $vdLogger->Error("Snapshot name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # Create a snapshot of the VM.
   my $cmd;
   $cmd = "CREATESNAP SNAPNAME $snapName ANCHOR $anchor VM \"$vmName\" MEMORY";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to create a snapshot of $vmName " .
                       Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsDeleteSnapshot --
#     Method to delete the given snapshot in the VM.
#
# Input:
#     snapName: name of the snapshot to be deleted # Required
#
# Results:
#     "SUCCESS", if the snapshot is deleted successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsDeleteSnapshot
{
   my $self     = shift;
   my $snapName = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $result;


   if (not defined $snapName) {
      $vdLogger->Error("No snapshot name given to delete");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Delete the given snapshot from the VM.
   my $cmd = "REMOVESNAP ANCHOR $anchor VM \"$vmName\" SNAPNAME \"$snapName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   #
   # RC 7028 is snapshot not found, which is fine if already removed.
   #
   if ((0 != $stafResult->{rc}) && (7028 != $stafResult->{rc})) {
      $vdLogger->Warn("Unable to delete snapshot $snapName on $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $result = $self->VMOpsListSnapshots();
   my $deleted = 1;
   if (ref($result) eq "ARRAY") {
      foreach my $snap(@$result) {
         if ($snap->{'SNAP NAME'} eq $snapName) {
            $deleted = 0;
         }
      }
   } elsif ($result =~ /$snapName/) {
      $deleted = 0;
   }
   if (!$deleted) {
      $vdLogger->Warn("Snapshot name with name \"$snapName\" still exists, " .
                      "may be duplicate names?");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsRevertSnapshot --
#     Method to revert VM to the given snapshot.
#
# Input:
#     snapName: name of the snapshot # Required
#
# Results:
#     "SUCCESS", if the vm is reverted successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsRevertSnapshot
{
   my $self     = shift;
   my $snapName  = shift || undef; # picks current snapshot if not defined
   my $esxHost = $self->{'esxHost'};
   my $vmName  = $self->{'vmName'};
   my $anchor  = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $stafResult = undef;
   my $result;


   # Revert the VM to the given snapshot.
   my $cmd = "REVERTSNAP ANCHOR $anchor VM \"$vmName\" SNAPNAME \"$snapName\"";
   $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to revert $vmName to snapshot $snapName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsHotRemovevNIC --
#     Method to remove (hot/cold) a virtual network adapter from a VM.
#     Works on both staf 4x and staf 5x.
#
# Input:
#     macAddress: mac address of the adapter to be removed # Required
#
# Results:
#     "SUCCESS", if the adapter is removed successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsHotRemovevNIC
{
   my $self       = shift;
   my $macAddress = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName  = $self->{'vmName'};
   my $anchor  = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   if (not defined $macAddress) {
      $vdLogger->Error("MAC address of the device to be removed not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $device = $self->GetDeviceLabelFromMac($macAddress);

   if (not defined $device) {
      $vdLogger->Error("Unable to find the adapter label for $macAddress");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # execute the STAF command to remove the virtual network adapter
   my $cmd = "REMOVEVIRTUALNIC ANCHOR $anchor VM \"$vmName\" " .
             "DEVICELABEL \"$device\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest information of $vmName");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #sleep 2 secs for cleaning the test bed
   $vdLogger->Debug("Sleeping for 2 secs to clean the information of removed".
		    " adapter from test bed.");
   sleep 2;
   return SUCCESS;
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
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $nicsInfo;

   my $cmd = "VMNICINFO ANCHOR $anchor VM \"$vmName\"";
   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to get guest information of $vmName " .
                       Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #
   # Make all hash keys to lower case to match with the output
   # format of GetAdapterInfo() in ESXSTAF4xVMOperations.pm
   #
   foreach my $adapter (@{$stafResult->{result}}) {
      %$adapter = (map { lc $_ => $adapter->{$_}} keys %$adapter);
   }

   return $stafResult->{result};
}


#############################################################################
#
# VMOpsChangePortgroup --
#     Method to change the portgroup of a virtual network adapter.
#
# Input:
#     macAddress: mac address of the adapter to be disconnected # Required
#     portgroup : name of the new portgroup (ensure this portgroup exists)
#                 # Required
#     targetindex: index of the vm targets. If Target is "SUT,helper[1-2]",
#                  then SUT has index 0, helper1 has index 1, helper2 has
#                  index 2    # Optional
#     portgrouptovnicmapping: portgroup and vnic mapping policy.
#                 E.g.Target: SUT,helper[1-4], portgroup: pg1-2.
#                 "1" - SUT->pg1, helper1->pg2, helper2->pg1, helper3->pg2,
#                       helper4->pg1
#                 "2" - SUT->pg1, helper1->pg2, helper2->pg2, helper3->pg2,
#                       helper4->pg2
#                 currently supports 1 or 2, can expand in future. # Optional
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
   my $portgroup  = shift;
   my $usevc = shift;
   my $targetindex = shift;
   my $portgrouptovnicmapping = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $proxy = "local";
   my @pgs;
   my $pg;

   if (defined $usevc and defined $self->{'vc'}){
      my $vcuser = $self->{'vcUser'};
      my $passwd = $self->{'vcPasswd'};
      $anchor = VDNetLib::Common::Utilities::GetSTAFAnchor(
                 $self->{stafHelper},$self->{'vc'},"VM",$vcuser,$passwd);
      $proxy = VDNetLib::Common::GlobalConfig::DEFAULT_STAF_SERVER;
      #$self->{'stafVMAnchor'} = $anchor;
   }
   if ((not defined $macAddress) || (not defined $portgroup)) {
      $vdLogger->Error("MAC address and/or portgroup of the device not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $device = $self->GetDeviceLabelFromMac($macAddress);

   if (not defined $device) {
      $vdLogger->Error("Unable to find the adapter label for $macAddress");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # In case the portgroup name was given as "pg23-100" and the Target vm
   # was given as "SUT,helper[1-N]"
   # Add support for changing a bunch of portgroups in a single workload.
   #

   if ($portgroup =~ m/^([^\-]+[a-zA-Z])(\d+)-(\d+)$/) {
      for (my $i = $2; $ i<= $3; $i++) {
         push(@pgs,$1.$i);
      }
   } else {
      push(@pgs,$portgroup);
   }

   # When this function is called by InitializeVirtualAdapters();
   if (not defined $targetindex) {
      $targetindex = 0;
   }

   if (not defined $portgrouptovnicmapping) {
      $portgrouptovnicmapping = 1;
   }

   #
   # You can add your own vm and portgroup mapping policy here.
   # Now there are two policies:
   # E.g. Target: SUT,helper[1-4], portgroup: pg1-2.
   # policy "1" - SUT->pg1, helper1->pg2, helper2->pg1, helper3->pg2, helper4->pg1
   #
   # policy "2" - SUT->pg1, helper1->pg2, helper2->pg2, helper3->pg2, helper4->pg2
   #

   if ($portgrouptovnicmapping == 1) {
      my $index = $targetindex % scalar(@pgs);
      $pg = $pgs[$index];
   } elsif ($portgrouptovnicmapping == 2) {
      if ($targetindex >= scalar(@pgs)) {
         $pg = $pgs[-1];
      } else {
         $pg = $pgs[$targetindex];
      }
   } else {
      $vdLogger->Error("Mapping policy $portgrouptovnicmapping is not supported");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $cmd = "CHANGEVIRTUALNIC ANCHOR $anchor VM \"$vmName\" " .
             "DEVICELABEL \"$device\" PGNAME \"$pg\"";
   $vdLogger->Debug("Changing portgroup: $cmd");

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand($proxy, $cmd);

   if (0 != $stafResult->{rc}) {
      $vdLogger->Error("Unable to change portgroup for $device on $vmName.".
		       " Error Info: ".  Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


#############################################################################
#
# VMOpsAddPCIPassthru--
#     Method to add PCI device(adapter) to a VM.
#
# Input:
#     Named value parameters:
#     nics : Instance of VDNetLib::NetAdapter::Vmnic::Vmnic that points
#            to a physical NIC (like 'vmnic4') that is already in
#            passthru mode (either SRIOV or FPT) (Required)
#     vfIndex: Specific Virtual Function Index (integer) that needs to
#            be added to the VM.(Optional, if not defined, it is
#            assumed to add FPT device)
#     method: "vmx" or "vim"
#     pciIndex: PCI adapter index to be used in the VM
#     vfVLAN  : default VLAN (Optional)
#     vfMAC   : static mac address (Optional)
#
# Results:
#     "SUCCESS", if the PCI device get Added to the VM
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsAddPCIPassthru
{
   my $self = shift;
   my %args = @_;
   my $nics     = $args{'vmnic'};
   my $vfIndex  = $args{'vfIndex'};
   my $method   = $args{'method'};
   my $pciIndex = $args{'pciIndex'};
   my $vfVLAN   = $args{'vfVLAN'};
   my $vfMAC    = $args{'vfMAC'};

   #
   # Memory reservation must be configured to unlimited for
   # pci passthru to work
   #

   my $command = "EDITMEMRESOURCE ANCHOR $self->{stafVMAnchor} " .
                 "VM $self->{vmName} FULLRESERVATION true";

   my $result = $self->{stafHelper}->STAFSubmitVMCommand("local",
                                                         $command);
   #checking staf result for errors
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to reserve memory on VM: $self->{'vmName'}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $vfIndex) {
      $vdLogger->Info("Passthrough mode is SRIOV");
      return $self->VMOpsAddSRIOVPCIPassthru(vmnic => $nics,
                                        vfIndex => $vfIndex,
                                        method => "vmx",
                                        pciIndex => $pciIndex,
                                        vfVLAN => $vfVLAN,
                                        vfMAC => $vfMAC);
   } else {
      $vdLogger->Info("Passthrough mode is FPT");
      return $self->VMOpsAddFPTPCIPassthru($nics);
   }
}



#############################################################################
#
# VMOpsRemovePCIPassthru --
#     Method to remove PCI device(adapter) from a VM.
#
# Input:
#     nics : Instance of VDNetLib::NetAdapter::Vmnic::Vmnic that points
#            to a physical NIC (like 'vmnic4') that is already in
#            passthru mode
#
# Results:
#     "SUCCESS", if the PCI device is removed from the VM;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsRemovePCIPassthru
{
   my $self = shift;
   my $nics = shift;

   return $self->VMOpsRemoveSRIOVPCIPassthru($nics);
}


#############################################################################
#
# VMOpsAddFPTPCIPassthru --
#     Method to add FPT based passthrough device (VF) to a VM
#
# Input:
#     adapterObj : Instance of VDNetLib::NetAdapter::Vmnic::Vmnic that points
#                  to a physical NIC (like 'vmnic4') that is already configured
#                  to be is passthrough mode (FPT)
#
# Results:
#     "SUCCESS", if the PCI device is removed from the VM;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsAddFPTPCIPassthru
{

   my $self       = shift;
   my $adapterObj = shift;
   my $pciid;

   if (not defined $adapterObj) {
      $vdLogger->Error("Physical adapter object not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Checking the validity of the interface
   my $nic = $adapterObj->{'interface'};
   if ($nic !~ m/vmnic\d+/) {
      $vdLogger->Error("The $nic is not a valid interface name");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Getting the PCI Id of the interface
   $pciid = VDNetLib::Host::HostOperations::GetPassthruNICPCIID($self,
                                                                $self->{'esxHost'},$nic);

   if ($pciid eq ""){
      $vdLogger->Error("Failed to obtain PCIID of the $nic".
                       " on host:$self->{esxHost}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $command="ADDPCIPASSTHRU ANCHOR $self->{stafVMAnchor} ".
      "HOST $self->{esxHost} VM $self->{vmName} ".
      "DEVICEID $pciid";
   my $result = $self->{stafHelper}->STAFSubmitVMCommand("local",
                                                         $command);
   # check staf result for errors
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to Set the $nic in passthrough mode ".
                       "on VM:$self->{'vmName'}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


#############################################################################
#
# VMOpsAddSRIOVPCIPassthru--
#     Method to add SRIOV based passthrough device (VF) to a VM
#
# Input:
#     Named value parameters:
#     nics : Instance of VDNetLib::NetAdapter::Vmnic::Vmnic that points
#            to a physical NIC (like 'vmnic4') that is already in
#            passthru mode (either SRIOV or FPT) (Required)
#     vfIndex: Specific Virtual Function Index (integer) that needs to
#            be added to the VM.(Optional, if not defined, it is
#            assumed to add FPT device)
#     method: "vmx" or "vim"
#     pciIndex: PCI adapter index to be used in the VM
#     vfVLAN  : default VLAN (Optional)
#     vfMAC   : static mac address (Optional)
#
# Results:
#     "SUCCESS", if the PCI device is removed from the VM;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsAddSRIOVPCIPassthru
{
   my $self     = shift;
   my %args = @_;
   my $vmnicObj = $args{'vmnic'};
   my $vfIndex  = $args{'vfIndex'};
   my $method   = $args{'method'};
   my $pciIndex = $args{'pciIndex'};
   my $vfVLAN   = $args{'vfVLAN'};
   my $vfMAC    = $args{'vfMAC'};

   if (not defined $vmnicObj) {
      $vdLogger->Error("NetAdapter object of vmnic not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vfIndex = (defined $vfIndex) ? $vfIndex : 1;

   my $bdfInDecimal = $self->GetAvailableVirtualFunction($vmnicObj, $vfIndex);

   $vdLogger->Info("Adding VF $bdfInDecimal to $self->{vmName}");

   my ($command, $result);
   if ($method eq "vim") {
      #
      # Use this method when SRIOV is enabled at ESX boot time itself
      # TODO: This procedure to enable sriov is not yet clear
      #
      $command= "ADDPCIPASSTHRU ANCHOR $self->{stafVMAnchor} " .
                "HOST $self->{esxHost} VM $self->{vmName} " .
                "DEVICEID $bdfInDecimal";

      $result = $self->{stafHelper}->STAFSubmitVMCommand("local",
                                                         $command);
      #check staf result for errors
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to Set the VF $bdfInDecimal in passthrough " .
                          "mode on VM:$self->{'vmName'}");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      # This method "vmx" configure PCI device using the vmx entries
      # TODO: take PCI device number from user or find automatically
      my $pciAdapter = "pciPassthru" . $pciIndex;
      my $configHash;
      $configHash->{$pciAdapter . '.present'} = "TRUE";
      $configHash->{$pciAdapter . '.deviceId'} = "0";
      $configHash->{$pciAdapter . '.vendorId'} = "0";
      $configHash->{$pciAdapter . '.systemId'} = "BYPASS";
      $configHash->{$pciAdapter . '.id'} = $bdfInDecimal;
      my $vlan;
      if (defined $vfVLAN) {
         $vlan = $pciAdapter . '.defaultVlan = ' . $vfVLAN;
         $configHash->{$pciAdapter . '.defaultVlan'} = $vfVLAN;
      } else {
         $vlan = $pciAdapter . '.defaultVlan = 0';
         $configHash->{$pciAdapter . '.defaultVlan'} = "0";
      }

      my @mac;
      if (defined $vfMAC) {
         @mac = (
                 $pciAdapter . '.MACAddressType = "static"',
                 $pciAdapter . '.macAddress=  ' . $vfMAC
                );
         $configHash->{$pciAdapter . '.MACAddressType'} = "static";
         $configHash->{$pciAdapter . '.macAddress'} = $vfMAC;

      } else {
         @mac = ($pciAdapter . '.MACAddressType = "generated"');
         $configHash->{$pciAdapter . '.MACAddressType'} = "generated";
      }
      $vdLogger->Debug("Adding PCI configuration " . Dumper($configHash));

      $result = $self->UpdateVMExtraConfig($configHash);
      if ($result eq FAILURE) {
         $vdLogger->Info("Failed to UpdateVMX()");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# GetPCIAdapters--
#     Method to get all PCI adapters in the given VM along with the
#     adapter configuration details
#
# Input:
#     None
#
# Results:
#     Reference to a hash of hash with outer hash containing keys
#     that represents PCI index. The value of each pci index is
#     as hash with following key/values:
#     present        = "TRUE" or "FALSE"
#     MACAddressType = "generated" or "static"
#     macAddress     = <mac address>
#     defaultVlan    = <vlan id>
#     id             = <pci id>
#
# Side effects:
#     None
#
########################################################################

sub GetPCIAdapters
{
   my $self = shift;

   my $vmExtraConfig;
   my $pciAdapterHash;
   my $inlineVMObj = $self->GetInlineVMObject();
   if (!($vmExtraConfig = $inlineVMObj->GetVMExtraConfig())) {
      $vdLogger->Error("Failed to get the VMX config");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   foreach my $config (keys %$vmExtraConfig) {
      #
      # Collect and store all information in the format
      # pciPassthru*.*
      #
      if ($config =~ /pciPassthru(\d)\.(.*)/i) {
         $pciAdapterHash->{$1}{$2} = $vmExtraConfig->{$config};
      }
   }
   return $pciAdapterHash;
}

########################################################################
#
# GetMACFromPCI--
#     Method to get MAC address from PCI ID of the passthrough device
#
# Input:
#     PCI ID of the passthrough device
#
# Results:
#     MAC address of the passthrough device
#
# Side effects:
#     None
#
########################################################################

sub GetMACFromPCI
{
   my $self = shift;
   my $pciId = shift;
   my $mac;

   if (not defined $pciId) {
      $vdLogger->Error("PCI ID of the passthrough device not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Debug("PCI ID of the passthrough device is $pciId");
   my $pciAdapterHash = $self->GetPCIAdapters();
   $vdLogger->Debug(Dumper($pciAdapterHash));
   foreach my $pciAdapter (keys %$pciAdapterHash) {
      if ($pciAdapterHash->{$pciAdapter}{'id'} eq $pciId) {
         if ($pciAdapterHash->{$pciAdapter}{'MACAddressType'} eq 'static') {
           $mac = $pciAdapterHash->{$pciAdapter}{'macAddress'};
         } else {
           $mac = $pciAdapterHash->{$pciAdapter}{'generatedMACAddress'};
         }
         if ((defined $mac) && ($mac ne "")) {
            $vdLogger->Debug("The mac address mapping to the $pciId is $mac");
         }
         last;
      }
   }
   return $mac;
}


########################################################################
#
# GetAvailableVirtualFunction--
#     Method to get virtual function ID from the given VF index
#     or find available virtual function on the given phy adapter
#
# Input:
#     vmnicObj : reference to NetAdapter::Vmnic:Vmnic object
#     vfIndex  : specific index ("<integer>") or
#                'any' to get any available VF
#
# Results:
#     Virtual function ID/BDF, if successful;
#     FAILURE in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetAvailableVirtualFunction
{
   my $self     = shift;
   my $vmnicObj = shift;
   my $vfIndex  = shift;

   my $virtualFunctions = $self->{hostObj}->GetVirtualFunctions($vmnicObj->{interface});

   if ($virtualFunctions eq FAILURE) {
      $vdLogger->Error("Failed to get list of Virtual Functions on " .
                       $vmnicObj->{interface});
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ((defined $vfIndex) && ($vfIndex !~ /any/i)) {
      # return BDF value if specific VF index is given
      return $virtualFunctions->{$vfIndex}{'bdf'};
   } else {
      $vdLogger->Debug("Finding available VF on $vmnicObj->{interface}");
      my $pciAdapters = $self->GetPCIAdapters();

      foreach my $vf (keys %$virtualFunctions) {
         my $used = 0;
         if ($virtualFunctions->{$vf}{active} =~ /true/i) {
            next;
         }
         foreach my $pci (keys %$pciAdapters) {
            if (($pciAdapters->{$pci}{present} =~ /true/i) &&
               ($pciAdapters->{$pci}{id} eq $virtualFunctions->{$vf}{bdf})) {
                  $used = 1;
               }
         }
         if (!$used) {
            return $virtualFunctions->{$vf}{bdf};
         }
      }
   }
   $vdLogger->Error("Failed to find any VF on " .
                    "$vmnicObj->{interface}");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


#############################################################################
#
# VMOpsRemovePCIPassthru --
#     Method to remove SRIOV based passthrough device from a VM
#
# Input:
#     nics : Instance of VDNetLib::NetAdapter::Vmnic::Vmnic that points
#            to a physical NIC (like 'vmnic4') that is already in
#            passthru mode (SRIOV)
#
# Results:
#     "SUCCESS", if the PCI device is removed from the VM;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsRemoveSRIOVPCIPassthru
{
   my $self      = shift;
   my $vmnicObj  = shift;
   my $method    = shift || "vmx";

   my $pciID;
   my $result;

   $vdLogger->Info("Removing VF from $self->{vmName}");

   if ($method eq "vim") {
      my $command = "REMOVEPCIPASSTHRU ANCHOR $self->{stafVMAnchor} " .
                    "HOST $self->{esxHost} VM $self->{vmName} " .
                    "DEVICEID $pciID";
      $result = $self->{stafHelper}->STAFSubmitVMCommand("local",
                                                         $command);
      #checking staf result for errors
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to remove the VF($pciID) from passthrough mode ".
                          "on VM:$self->{'vmName'}");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      my $configHash;
      for (my $i=0; $i < 6; $i++) {
         $configHash->{'pciPassthru' . $i . '.present'} = "FALSE";
         $configHash->{'pciPassthru' . $i . '.MACAddressType'} = "generated";
         $configHash->{'pciPassthru' . $i . '.defaultVlan'} = "0";
      }
      $result = $self->UpdateVMExtraConfig($configHash);
      if ($result eq FAILURE) {
         $vdLogger->Info("Failed to UpdateVMX()");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


#############################################################################
#
# VMOpsRemovePCIPassthru --
#     Method to remove FPT based passthrough device from a VM
#
# Input:
#     nics : Instance of VDNetLib::NetAdapter::Vmnic::Vmnic that points
#            to a physical NIC (like 'vmnic4') that is already in
#            passthru mode
#
# Results:
#     "SUCCESS", if the PCI device is removed from the VM;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsRemoveFPTPCIPassthru
{

   my $self = shift;
   my $nics = shift;
   my $pciid;

   my @pnics = @$nics;

   if (!@pnics) {
      $vdLogger->Error("Physical PCI PASSthru NIC is not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   foreach my $adapterObj (@pnics){
      #checking the validity of the interface
      my $nic = $adapterObj->{'interface'};
      if ($nic !~ m/vmnic\d+/) {
         $vdLogger->Error("The $nic  is not a valid interface name");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      #getting the PCI ID of the interface
      $pciid = VDNetLib::Host::HostOperations::GetPassthruNICPCIID($self,
                                                                   $self->{esxHost},$nic);
      #checking if the PCI Id is empty
      if ($pciid eq ""){
         $vdLogger->Error("Failed to obtain PCIID of the $nic".
                          " on host:$self->{esxHost}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }


      my $command = "REMOVEPCIPASSTHRU ANCHOR $self->{stafVMAnchor} " .
                    "HOST $self->{esxHost} VM $self->{vmName} " .
                    "DEVICEID $pciid";
      my $result = $self->{stafHelper}->STAFSubmitVMCommand("local",
                                                            $command);
      #checking staf result for errors
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to Set the $nic in passthrough mode ".
                          "on VM:$self->{'vmName'}");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return SUCCESS;
}


#############################################################################
#
# KillAllPByName --
#     Method to kill all processes in a VM by name provided by user
#
# Input:
#     ProcessName: Name of the process (case insensitive) [Mandatory]
#
# Results:
#     "SUCCESS", if all the processes are removed
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
# Note: This functions works for RHEL as of now.
#
#############################################################################

sub KillAllPByName
{
   my $self = shift;
   my $processName = shift;

   if (not defined $processName) {
      $vdLogger->Error("Process name not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vmx = $self->{'vmx'};
   my $host = $self->{'esxHost'};
   my $stafResult = undef;
   my $cmd;

   #
   # Check IP of the VM
   #
   $vdLogger->Info("Finding IP address of $vmx");
   my $ip = VDNetLib::Common::Utilities::GetGuestControlIP($self);
   if ($ip eq FAILURE) {
      $vdLogger->Error("Failed to get ip address of $vmx");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   #
   # Sending command to check if process is running
   #
   my $checkCommand = "ps -ef | grep -i $processName | grep -v grep";
   $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $checkCommand,
                                                       DEFAULT_TIMEOUT);
   if ($stafResult->{rc} != 0) {
      $vdLogger->Error("Failed to check whether process is running");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my @tmp = split('\n',$stafResult->{stdout});
   my $count = 0;
   #
   # Removing the process
   #
   while (scalar(@tmp) > 0) {
      if ($count == DEFAULT_MAX_RETRIES) {
         $vdLogger->Error("Failed to kill process $processName even after DEFAULT_MAX_RETRIES attempts");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $cmd = "ps -ef | grep -i $processName | grep -v grep |  awk '^{print \$2}' | xargs kill -9";
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $cmd,
                                                      DEFAULT_TIMEOUT);
      if ($stafResult->{rc} != 0) {
         $vdLogger->Error("Failed to kill process $processName");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $stafResult = $self->{stafHelper}->STAFSyncProcess($ip, $checkCommand,
                                                         DEFAULT_TIMEOUT);
      $count++;
      @tmp = split('\n',$stafResult->{stdout});
   }
   $vdLogger->Warn("All $processName processes have been killed in $ip");
   return SUCCESS;
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
   if($device !~ /(floppy|serial|parallel|^cd)/i) {
      $vdLogger->Error("Unsupported Device:$device");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();

   $device = "CD\/DVD drive" if $device =~ /^cd/i;
   $device = "Floppy drive"  if $device =~ /floppy/i;
   $device = "Serial port"   if $device =~ /serial/i;
   $device = "Parallel port" if $device =~ /parallel/i;

   my $cmd;
   $cmd = "GETVMHWDETAILS ANCHOR $anchor VM $vmName ";

   my $stafResult = $self->{stafHelper}->STAFSubmitVMCommand("local", $cmd);
   if ($stafResult->{rc} != $STAF::kOk) {
      $vdLogger->Error("Unable to get vm details for $vmName on $esxHost");
      $vdLogger->Info("Error:". Dumper($stafResult));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # We just see if the device is present in this array
   # We dont care about the connection state of the device at this time.
   my $result = $stafResult->{result};
   my $element = @$result[0];
   foreach my $key (keys %$element) {
      if ($key =~ /$device/i) {
         return $key;
      }
   }

   return 0;
}


########################################################################
#
# VMOpsGetToolsStatus --
#     Check the status, version etc of VMware Tools and suggest if it
#     needs upgrade or not.
#
# Input:
#     none.
#
# Results:
#     1 - if upgrade needed
#     0 - if no upgrade required
#     "FAILURE", in case of any error.
#
# Side effects:
#
#
########################################################################

sub VMOpsGetToolsStatus
{
   my $self = shift;
   my $needUpgrade;

   my $result = $self->GetGuestInfo();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get guest information in ".
                       "GetToolsStatus");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Current logic is - if user gives path to iso in <tools> option then
   # perform upgrade with it irrespective of current tools status/version.
   # If upgrade is with default build then no need to upgrade if Tools Version
   # Status says 'guestToolsCurrent'.
   # If Tools Version Status says 'ToolsNeedUpgrade' then of course
   # upgrade tools.

   if($result->{'Tools Info'}{'Tools Version Status'} =~
                                 /ToolsNotInstalled/i) {
      $vdLogger->Warn("VMware Tools are not installed ".
                      "in $self->{'vmIP'}. Cannot Upgrade!");
      return FAILURE;
   } elsif($result->{'Tools Info'}{'Tools Version Status'} =~
                                 /guestToolsCurrent/i) {
      my $ver = VDNetLib::Common::Utilities::VMwareToolsVIMCMDVersion(
                                  $result->{'Tools Info'}{'Tools Version'});
      $vdLogger->Info("VMware Tools in ".
                      "$self->{'vmIP'} is ".
                      "Updated. Version:$ver");
      $needUpgrade = 0;
   } elsif($result->{'Tools Info'}{'Tools Version Status'} =~
                                   /(ToolsNeedUpgrade)/i) {
      my $ver = VDNetLib::Common::Utilities::VMwareToolsVIMCMDVersion(
                                  $result->{'Tools Info'}{'Tools Version'});
      $vdLogger->Info("VMware Tools in ".
                      "$self->{'vmIP'} is ".
                      "Old. Version:$ver");
      $needUpgrade = 1;
   }

   return $needUpgrade;
}


################################################################################
#
# VMOpsConfigureNetdumpServer
#   Configure the Netdump Server either on windows or linux
#
# Input:
#   serverParam   : Netdump Server Params to be configured for. (Required)
#		    Params are: installpath/configpath/logpath/datapath/
#			corepath/logfile/serviceip/maxsize/debug
#   serverValue   : Netdump Server Value to the serverParam. (Required)
#
# Results:
#   SUCCESS, if the netdump server parameters are configured successfully
#   FAILURE, in case of any error, in setting the Netdump Server Configuration.
#
# Side effects:
#   none
#
################################################################################

sub VMOpsConfigureNetdumpServer
{
    my $self              = shift;
    my $netdumpHash       = shift;
    my $serverParam       = $netdumpHash->{'NetdumpConfig'};
    my $serverValue       = $netdumpHash->{'NetdumpValue'};

    my $vmIP     = $self->{'vmIP'};
    my $osType = $self->{stafHelper}->GetOS($vmIP);
    if (not defined $osType) {
        $vdLogger->Error("Unable to get OS type of $vmIP");
        VDSetLastError("ESTAF");
        return FAILURE;
    }

    my $operation    = "setconfig";
    $osType =~ s/\ //g;
    my $args = "";
    $args = "$osType,". "$operation,".
	       "$serverParam,". "$serverValue";
    my $returnVal = ExecuteRemoteMethod($self->{'vmIP'},
                                        "SetNetdumpConfig",$args);
    $vdLogger->Debug("Return value for NetdumperOperations is: ".
		     Dumper($returnVal));
    if (SUCCESS ne $returnVal){
        $vdLogger->Error("Unable to perform The Netdumper Operations:".
			 " $operation. Return Value:". Dumper ($returnVal));
        VDSetLastError("ESTAF");
        return FAILURE;
    }
    #VMware ESXi Network Dump Collector service restart
    my $action = "restart";
    my $stat = $self->VMOpsNetdumperService($action);
    if (FAILURE eq $stat){
        $vdLogger->Warn("Failed to $action Netdumper service on $vmIP".
			" in max attempts.");
        VDSetLastError("ESTAF");
        return FAILURE;
    }
    return SUCCESS;
}


################################################################################
#
# VMOpsNetdumperService
#   Method to Start and Stop the Netdump server.
#
# Input:
#   action   : Action Needed on Netdump Server stop/start (Required)
#
# Results:
#   SUCCESS, if the netdump service is stoppped/started successfully
#   FAILURE, in case of any error, in starting/stopping the Netdump Server.
#
# Side effects:
#   none
#
################################################################################
sub VMOpsNetdumperService {

    my $self         = shift;
    my $action       = shift || "start";
    my $cmdToStopService  = "";
    my $cmdToStartService = "";
    my $cmdToRestartService  = "";
    my $cmdToCheckService = "";
    my $stafResult;

    my $ip     = $self->{'vmIP'};
    my $osType = $self->{stafHelper}->GetOS($ip);
    if (not defined $osType) {
        $vdLogger->Error("Unable to get OS type of $ip");
        VDSetLastError("ESTAF");
        return FAILURE;
    }

    if ($osType =~ /win/i) {
        $osType = "win";
        $cmdToStopService  = "net stop vmware-network-coredump /y";
        $cmdToStartService = "net start vmware-network-coredump /y";
        $cmdToCheckService = "sc query vmware-network-coredump|find \"STATE\" ";
    }
    elsif ($osType =~ /linux/i) {
        $osType = "linux";
        $cmdToStopService  = "/etc/init.d/vmware-netdumper stop";
        $cmdToStartService = "/etc/init.d/vmware-netdumper start";
        $cmdToRestartService = "/etc/init.d/vmware-netdumper restart";
        $cmdToCheckService = "/etc/init.d/vmware-netdumper status";
    }
    else {
        $vdLogger->Error("Invalid OS Type Specified: $osType");
        return FAILURE;
    }

    my $NETDUMPER_MSG;
    if ($action eq "stop") {
       $vdLogger->Info("Stopping the VMware ESXi Network Coredump Server.");
       $stafResult = $self->{stafHelper}->STAFSyncProcess($ip,
                                                          $cmdToStopService, DEFAULT_TIMEOUT);
       if ($stafResult->{stderr} =~ m/is not running/i) {
          $vdLogger->Warn("Netdump Server on $ip is already $action.");
          return "SUCCESS";
       } elsif (0 != $stafResult->{rc} || 0 != $stafResult->{exitCode}) {
          $vdLogger->Warn("Failed to send $cmdToStopService on $ip.");
          VDSetLastError("ESTAF");
          return FAILURE;
       }
       $NETDUMPER_MSG = "is not running";
    }
    if ($action eq "start") {
        $vdLogger->Info("Starting the VMware ESXi Network Coredump Server.");
        $stafResult = $self->{stafHelper}->STAFSyncProcess($ip,
                $cmdToStartService, DEFAULT_TIMEOUT);
        if ((0 != $stafResult->{rc}) || (0 != $stafResult->{exitCode})) {
            $vdLogger->Error("Failed to send $cmdToStartService on $ip ");
            $vdLogger->Debug("Error:" . Dumper($stafResult));
            return FAILURE;
        }
        $NETDUMPER_MSG = "is running";
    }
    if ($action eq "restart") {
        $vdLogger->Info("Restarting the VMware ESXi Network Coredump Server.");
        if ($osType =~ /win/i) {
            $stafResult = $self->{stafHelper}->STAFSyncProcess($ip,
                    $cmdToStopService, DEFAULT_TIMEOUT);
            $vdLogger->Debug("Output of $cmdToStopService on $ip: ".
                Dumper($stafResult));
            if (0 != $stafResult->{rc} || 0 != $stafResult->{exitCode}) {
                $vdLogger->Error("Failed to send $cmdToStopService on $ip ");
                $vdLogger->Debug("Error:" . Dumper($stafResult));
            }
            sleep (5);
            $stafResult = $self->{stafHelper}->STAFSyncProcess($ip,
                    $cmdToStartService, DEFAULT_TIMEOUT);
            $vdLogger->Debug("Output of $cmdToStartService on $ip: ".
                Dumper($stafResult));
            if (0 != $stafResult->{rc} || 0 != $stafResult->{exitCode}) {
                $vdLogger->Error("Failed to send $cmdToStartService on $ip ");
                $vdLogger->Debug("Error:" . Dumper($stafResult));
                return FAILURE;
            }
        }
        elsif ($osType =~ /linux/i) {
            $stafResult = $self->{stafHelper}->STAFSyncProcess($ip,
                   $cmdToRestartService, DEFAULT_TIMEOUT);
            $vdLogger->Debug("Output of $cmdToRestartService on $ip: ".
                   Dumper($stafResult));
            if (0 != $stafResult->{rc} || 0 != $stafResult->{exitCode}) {
                $vdLogger->Error("Failed to send $cmdToRestartService on $ip ");
                VDSetLastError("ESTAF");
                return FAILURE;
            }
            $NETDUMPER_MSG = "is running";
        }
    }

    # Get service status information
    my $count = 0;
    while($count < 15) {
       sleep(5);
       if ($osType eq "win") {
          $stafResult = $self->{stafHelper}->STAFSyncProcess($ip,
                                                             $cmdToCheckService, DEFAULT_TIMEOUT);
          if ($stafResult->{exitCode} != 0) {
             $vdLogger->Warn("Failed to send/execute $cmdToCheckService on
                             $ip in iteration $count");
          }
          else {
             return SUCCESS;
          }
       } elsif ($osType eq "linux") {
          $stafResult = $self->{stafHelper}->STAFSyncProcess($ip,
                                                             $cmdToCheckService, DEFAULT_TIMEOUT);
          if($stafResult->{stdout} =~ m/(.*)$NETDUMPER_MSG(.*)/i){
             $vdLogger->Info("Service vmware-netdumper".
                             " $action successfully.");
             return SUCCESS;
          }
       }
       $count++;
    }
    if($count >= 15) {
       $vdLogger->Info("Service vmware-netdumper status returns " .
                       Dumper($stafResult));
        return FAILURE;
    }
    return SUCCESS;
}


################################################################################
#
# VMOpsCheckNetdumpStatus
#   Subroutine to check if the network core dump status is successful.
#
# Input:
#   NetdumpClinetIP : Netdump Client IP Address. (Required)
#
# Results:
#   SUCCESS, if the network core dump is successful.
#   FAILURE, in case of any error, in sending the Netdump core dump.
#
# Side effects:
#   none
#
################################################################################

sub VMOpsCheckNetdumpStatus {

    my $self		= shift;
    my $netdumpHash	= shift;
    my $NetdumpClientIP	= $netdumpHash->{'NetdumpClientIP'};
    my $ClientAdapter = $netdumpHash->{'NetdumpClientAdapter'};

    my $vmIP     = $self->{'vmIP'};
    my $osType = $self->{stafHelper}->GetOS($vmIP);
    if (not defined $osType) {
        $vdLogger->Error("Unable to get OS type of $vmIP");
        VDSetLastError("ESTAF");
        return FAILURE;
    }

    my $operation       = "dumpstatus";
    $osType  =~ s/\ //g;
    my $args = "";
    $args    = "$osType,". "$operation,".
	       "$NetdumpClientIP";
    my $returnVal = ExecuteRemoteMethod($self->{'vmIP'},
                                        "CheckNetdumpStatus",$args);
    $vdLogger->Debug("Return value for NetdumperOperations is: ".
		     Dumper($returnVal));
    if (SUCCESS ne $returnVal){
        $vdLogger->Error("Unable to perform The Netdumper Operations:".
			 " $operation. Return Value:". Dumper ($returnVal));
        VDSetLastError("EFAIL");
        return FAILURE;
    }
    return SUCCESS;
}


################################################################################
#
# VMOpsVerifyNetdumpConfig
#   Verify the Netdump Server configuration.
#
# Input:
#   serverParam   :
#	Netdump Server configurations parametred to verify (Required)
#   serverValue   :
#	Netdump Server configuration values of serverParam (Required)
#
# Results:
#   SUCCESS, if the server parameters are verified successfully.
#   FAILURE, in case of any error, in verifying the Configuration.
#
# Side effects:
#   none
#
################################################################################

sub VMOpsVerifyNetdumpConfig {

    my $self              = shift;
    my $netdumpHash       = shift;
    my $serverParam       = $netdumpHash->{'NetdumpConfig'};
    my $serverValue       = $netdumpHash->{'NetdumpValue'};
    my $vmIP    = $self->{'vmIP'};
    my $osType  = $self->{stafHelper}->GetOS($vmIP);
    if (not defined $osType) {
        $vdLogger->Error("Unable to get OS type of $vmIP");
        VDSetLastError("ESTAF");
        return FAILURE;
    }

    my $operation    = "verifyconfig";
    $osType =~ s/\ //g;
    my $args = "";
    $args    = "$osType,". "$operation,".
	       "$serverParam,". "$serverValue";
    my $returnVal = ExecuteRemoteMethod($self->{'vmIP'},
                                        "VerifyNetdumpConfig", $args);
    $vdLogger->Debug("Return value for NetdumperOperations is: ".
		     Dumper($returnVal));
    if (SUCCESS ne $returnVal){
        $vdLogger->Error("Unable to perform The Netdumper Operations:".
			 " $operation. Return Value:". Dumper ($returnVal));
        VDSetLastError("EFAIL");
        return FAILURE;
    }
    return SUCCESS;
}


################################################################################
#
# VMOpsInstallNetdumpServer
#   Start the Netdump Server configuration.
#   Upgrade/Install the Nedtump Server if not already done.
#
# Input:
#   None.
#
# Results:
#   SUCCESS, if the netdump server is installed and started properly.
#   FAILURE, in case of any error, in installing and starting the server.
#
# Side effects:
#   Currently Implementation is done only for Linux VM.
#   Netdump Server Installation on win2k3 & win2k8 will be care in the
#   immediate future. We will only be starting the Netdump Server in the case of
#   windows VM.
#
################################################################################

sub VMOpsInstallNetdumpServer {

    my $self              = shift;
    my $netdumpHash       = shift;
    my $netdumperUpgrade  = $netdumpHash->{'NetdumpInstall'};
    my $vmIP     = $self->{'vmIP'};
    my $osType = $self->{stafHelper}->GetOS($vmIP);
    if (not defined $osType) {
        $vdLogger->Error("Unable to get OS type of $vmIP");
        VDSetLastError("ESTAF");
        return FAILURE;
    }

    my $operation    = "initiateserver";
    $osType =~ s/\ //g;
    my $args = "";
    $args    = "$osType,". "$operation,".
               "$netdumperUpgrade";
    my $returnVal = ExecuteRemoteMethod($self->{'vmIP'},
                                        "InstallNetdumpServer", $args);
    $vdLogger->Debug("Return value for NetdumperOperations is: ".
		     Dumper($returnVal));
    if (SUCCESS ne $returnVal){
        $vdLogger->Error("Unable to perform The Netdumper Operations:".
			 " $operation. Return Value:". Dumper ($returnVal));
        VDSetLastError("EFAIL");
        return FAILURE;
    }
    return SUCCESS;
}


################################################################################
#
# VMOpsCleanNetdumperLogs
#   Cleanup/Nullify the Netdump Server Logs.
#
# Input:
#   None.
#
# Results:
#   SUCCESS, if the netdump server logs are emptied/nullified successfully.
#   FAILURE, in case of any error, in clearing the server logs.
#
# Side effects:
#   Currently Implementation is done only for Linux VM.
#   Netdump Server Installation on win2k3 & win2k8 will be care in the
#   immediate future. We will only be starting the Netdump Server in the case of
#   windows VM.
#
################################################################################

sub VMOpsCleanNetdumperLogs {

    my $self     = shift;
    my $vmIP     = $self->{'vmIP'};
    my $osType   = $self->{stafHelper}->GetOS($vmIP);
    if (not defined $osType) {
        $vdLogger->Error("Unable to get OS type of $vmIP");
        VDSetLastError("ESTAF");
        return FAILURE;
    }

    # Stop Netdumper before cleaning logs
    my $action = "stop";
    my $stat = $self->VMOpsNetdumperService($action);
    if (FAILURE eq $stat){
        $vdLogger->Warn("Failed to $action Netdumper service on $vmIP".
			" in max attempts: $stat");
        VDSetLastError("ESTAF");
    }

    my $operation    = "cleanlogs";
    $osType =~ s/\ //g;
    my $args = "";
    $args    = "$osType,". "$operation";
    my $returnVal = ExecuteRemoteMethod($self->{'vmIP'},
				        "CleanNetdumpLogs", $args);
    $vdLogger->Debug("Return value for NetdumperOperations is: ".
		     Dumper($returnVal));
    if (SUCCESS ne $returnVal){
        $vdLogger->Error("Unable to perform The Netdumper Operations:".
			 " $operation. Return Value:". Dumper ($returnVal));
        VDSetLastError("ESTAF");
        return FAILURE;
    }

    # Start Netdumper after cleaning logs
    $action = "start";
    $stat = $self->VMOpsNetdumperService($action);
    if (FAILURE eq $stat){
        $vdLogger->Warn("Failed to $action Netdumper service on $vmIP".
			" in max attempts: $stat");
        VDSetLastError("ESTAF");
    }
    return SUCCESS;
}


################################################################################
#
# VMOpsSetReadWrite
#    Set Read/Write Properties to the Directory Specified.
#
# Input:
#   directoryproperties: Directory properties to be set as Read/Write (Required)
#   None.
#
# Results:
#   SUCCESS, if the properties are properly set.
#   FAILURE, in case of any error, in setting the properties to the directory.
#
# Side effects:
#    None.
#
################################################################################

sub VMOpsSetReadWrite {

    my $self            = shift;
    my $netdumpHash     = shift;
    my $readWriteDirectory = $netdumpHash->{'logdirectory'};
    my $readWriteOption = $netdumpHash->{'directoryproperties'};
    my $vmIP     = $self->{'vmIP'};
    my $osType   = $self->{stafHelper}->GetOS($vmIP);
    if (not defined $osType) {
        $vdLogger->Error("Unable to get OS type of $vmIP");
        VDSetLastError("EFAIL");
        return FAILURE;
    }

    my $operation    = "setreadwrite";
    $osType =~ s/\ //g;
    my $args = "";
    $args    = "$osType,". "$operation,". "$readWriteDirectory,".
		"$readWriteOption";
    my $returnVal = ExecuteRemoteMethod($self->{'vmIP'},
                                        "SetReadWritePermissions",$args);
    $vdLogger->Debug("Return value for NetdumperOperations is: ".
		     Dumper($returnVal));
    if (SUCCESS ne $returnVal){
        $vdLogger->Error("Unable to perform The Netdumper Operations:".
			 " $operation. Return Value:". Dumper ($returnVal));
        VDSetLastError("EFAIL");
        return FAILURE;
    }
    return SUCCESS;
}


################################################################################
#
# VMOpsConfigureLinuxService
#   Configure Linux Service.
#   Start/Stop the Linux Service. ex: iptables,nfs,etc.
#
# Input:
#   netdumperService: Service to be started/stopped.
#
# Results:
#   SUCCESS, if the linux service is started/stopped properly.
#   FAILURE, in case of any error, in starting/stopping the service.
#
# Side effects:
#   None.
#
################################################################################

sub VMOpsConfigureService {
    my $self = shift;
    my $netdumpHash = shift;
    my $serviceName = $netdumpHash->{'ServiceName'};
    my $serviceAction = $netdumpHash->{'ServiceAction'};

    my $vmIP     = $self->{'vmIP'};
    my $osType = $self->{stafHelper}->GetOS($vmIP);
    if (not defined $osType) {
        $vdLogger->Error("Unable to get OS type of $vmIP");
        VDSetLastError("ESTAF");
        return FAILURE;
    }

    my $operation    = "configureservice";
    $osType =~ s/\ //g;
    my $args = "";
    $args    = "$osType,". "$operation,". "$serviceName,".
		"$serviceAction";
    my $returnVal = ExecuteRemoteMethod($self->{'vmIP'},
                                        "ConfigureService",$args);
    $vdLogger->Debug("Return value for NetdumperOperations is: ".
		     Dumper($returnVal));
    if (SUCCESS ne $returnVal){
        $vdLogger->Error("Unable to perform The Netdumper Operations:".
			 " $operation. Return Value:". Dumper ($returnVal));
        VDSetLastError("ESTAF");
        return FAILURE;
    }
    return SUCCESS;
}


########################################################################
#
# UpdateVMExtraConfig--
#     Method to update VMX configuration
#
# Input:
#     configHash: key/value pair with each entry representing vmx
#                 configuration (Required)
#
# Results:
#     SUCCESS, if VMX configuration is updated successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     VM configuration will be changed
#
########################################################################

sub UpdateVMExtraConfig
{
   my $self       = shift;
   my $configHash = shift;

   if (not defined $configHash) {
      $vdLogger->Error("VM configuration hash not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj->UpdateVMExtraConfig($configHash)) {
      $vdLogger->Error("Failed to update the VMX config");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
# VMOpsConfigureLinuxService
#   Configure Linux Service.
#   Start/Stop the Linux Service. ex: iptables,nfs,etc.
#
# Input:
#   service_name: Service to be started/stopped.
#   action: The operation of the service (start/stop).
#
# Results:
#   SUCCESS, if the linux service is started/stopped properly.
#   FAILURE, in case of any error, in starting/stopping the service.
#
# Side effects:
#   None.
#
################################################################################

sub VMOpsConfigureLinuxService {
   my $self = shift;
   my $service = shift;
   my $action = shift;
   my $result;

   my $vmIP     = $self->{'vmIP'};
   my $osType = $self->{stafHelper}->GetOS($vmIP);
   if (not defined $osType) {
      $vdLogger->Error("Unable to get OS type of $vmIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # This method is only applicable on linux
   if ($osType !~ /lin/i){
      VDSetLastError("EINVALID");
      $vdLogger->Error("This method is only applicable on Linux");
      return FAILURE;
   }

   $result = VDNetLib::Common::Utilities::ConfigureLinuxService($vmIP,
                                                                $osType,
                                                                $service,
                                                                $action,
                                                                $self->{stafHelper});
   if ($result eq FAILURE) {
      $vdLogger->Error("Could not $action $service on $vmIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


#############################################################################
#
# VMOpsMemoryOverCommit --
#     Method to add exccess Memory to a VM.
#
# Input:
#      None.
#
# Results:
#     "SUCCESS", if the memory get updated to vmx file of the VM
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsMemoryOverCommit
{

   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};

   #getting the Memory Info of the Host
   my $memSize = $self->{hostObj}->GetHostMemInfo($esxHost);

   if(! $self->VMOpsMemoryAdd($memSize)) {
      $vdLogger->Error("MemoryOVERCommit:Adding excess memory to  " .
                                                "VM=$vmName has failed");
      VDSetLastError("EFAIL");
       return FAILURE;
     }
    return SUCCESS;
}


#############################################################################
#
# VMOpsMemoryAdd --
#     Method to add required Memory to a VM.
#
# Input:
#      MemorySize:1024
#
# Results:
#     "SUCCESS", if the memory get updated to vmx file of the VM
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsMemoryAdd
{
   my $self = shift;
   my $memSize = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $anchor = $self->{'stafVMAnchor'} || $self->GetSTAFVMAnchor();
   my $vmxFile = $self->{'vmx'} ;
   my $result;

   $result = $self->VMOpsGetPowerState();
   if ($result eq "FAILURE" || $result->{rc} != $STAF::kOk) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Check the state of the VM. If running then power it down.
   if ($result->{result} !~ /poweredoff/i) {
      $vdLogger->Info("Powering off VM $vmName to add Memory");
      $result =  $self->VMOpsPowerOff();
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to power off VM $vmName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
       }
    }

    # prepare the string that needs to be added to the vmxfile
    my @lines = ("memsize = $memSize");
    $vdLogger->Info("MemoryAdd: Adding " . Dumper(@lines) .
                                         " to $vmxFile");
    if (VDNetLib::Common::Utilities::UpdateVMX($esxHost,
                                              \@lines, $vmxFile,
                                              $self->{stafHelper}) eq
                                              FAILURE) {
      $vdLogger->Error("MemoryAdd: UpdateVMX failed");
      VDSetLastError("EFAIL");
      return FAILURE;
     }
   return SUCCESS;
}

################################################################################
#
# UpdateHostObj--
#     Method to update the Host information accosicated with this VM.
#
# Input:
#     hostObj: Host Object or undef.
#
# Results:
#     SUCCESS if hostObj gets updated successfully in the VM,
#     FAILURE if any error occurs.
#
# Side effects:
#     None
#
################################################################################

sub UpdateHostObj
{
   my $self    = shift;
   my $hostObj = shift;

   if (not defined $hostObj) {
      $vdLogger->Error("Empty/Undefined Host Object passed.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{hostObj} = $hostObj;
   return SUCCESS;
}


########################################################################
#
# GetSTAFVMAnchor --
#     Method to get staf VM anchor from the host object
#
# Input:
#     None
#
# Results:
#     staf vm anchor (string)
#
# Side effects:
#     None
#
########################################################################

sub GetSTAFVMAnchor
{
   my $self = shift;

   if (defined $self->{hostObj}{vcObj}) {
      $host         = $self->{hostObj}{vcObj}{vcaddr};
      $user         = $self->{hostObj}{vcObj}{user};
      $passwd       = $self->{hostObj}{vcObj}{passwd};

   } elsif ((defined $self->{vc}) && $self->{'useVC'} eq "1") {
   # This condition is for vdNet Version 1
      $host         = $self->{vc};
      $user         = $self->{'vcUser'};
      $passwd       = $self->{'vcPasswd'};

   } else {
      $host         = $self->{esxHost};
      $user         = $self->{hostObj}{userid};
      $passwd       = $self->{hostObj}{sshPassword};
   }
   $stafVMAnchor = VDNetLib::Common::Utilities::GetSTAFAnchor(
                                                        $self->{stafHelper},
                                                        $host,
                                                        "VM",
                                                        $user,
                                                        $passwd);
   if ($stafVMAnchor eq FAILURE) {
      $vdLogger->Error("Failed to get STAF VM anchor");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $stafVMAnchor;
}


########################################################################
#
# GetInlineVMObject --
#     Method to get an instance of VDNetLib::InlineJava::VM
#
# Input:
#     None
#
# Results:
#     an instance of VDNetLib::InlineJava::VM class
#
# Side effects:
#     None
#
########################################################################

sub GetInlineVMObject
{
   my $self = shift;
   my $inlineVMObj = VDNetLib::InlineJava::VM->new('host' => $self->{'host'},
                                      'vmName' => $self->{'vmName'},
                                      'user'   =>  $self->{'user'},
                                      'password' => $self->{'password'},
                                      );
   if (!$inlineVMObj) {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::VM instance");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlineVMObj;
}


########################################################################
#
# ChangeVMState --
#     Method to poweron/poweroff/suspend/resume specified VM;
#
# Input:
#     vmstate  -  A value of poweron/poweroff/suspend/resume;
#     options  -  Reference to a hash containing the following keys (Optional).
#                 waitForTools - (true/false) # Optional
#                 waitForVDNet - (true/false) # Optional
#                 waitForSTAF  - (true/false) # Optional
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
      'poweron'  => 'VMOpsPowerOn',
      'poweroff' => 'VMOpsPowerOff',
      'suspend'  => 'VMOpsSuspend',
      'resume'   => 'VMOpsResume',
      'reset'    => 'VMOpsReset',
      'reboot'   => 'VMOpsReboot',
      'crash'    => 'VMOpsCrash',
   };

   my $method = $operation->{$vmstate};
   if (defined $method) {
      my $result = $self->$method($options);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to $vmstate $self->{'vmx'}");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$vmstate is not a legal state we can support");
      VDSetLastError("EINVALID");
      return FAILURE;
   };

   if (defined $options) {
      if (defined $options->{'waitForTools'} || defined $options->{'waitForSTAF'} ||
          defined $options->{'waitForVDNet'}) {
         return $options;
      }
   } else {
      return SUCCESS;
   }
}


########################################################################
#
# UpdateSTAFAnchor --
#     Method to change stafVMAnchor attribute to given anchor;
#
# Input:
#     anchor  -  anchor info need to be changed to; (mandatory)
#
# Results:
#     "SUCCESS", if stafVMAnchor gets successfully updated;
#     "FAILURE", in case of any error;
#
# Side effects:
#     None.
#
########################################################################

sub UpdateSTAFAnchor
{
   my $self = shift;
   my $anchor = shift;

   if (not defined $anchor) {
      $vdLogger->Error("Parameter anchor is mandatory for UpdateSTAFAnchor()");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{'stafVMAnchor'} = $anchor;
   return SUCCESS;
}


########################################################################
#
# FindAndUpdate
#     Method to find this VM in given cluster, dc, host etc and update obj
#
# Input:
#     componentObject: HostObj or clusterObj or dcObj
#
# Results:
#     SUCCESS, if the VM is setup successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub FindAndUpdate
{
   my $self = shift;
   my $componentObject = shift;
   my $vmName = $self->{'vmName'};

   my $inlineVMObj = $self->GetInlineVMObject();
   if (!$inlineVMObj->FindVM($componentObject)) {
      $vdLogger->Error("Failed to find VM $vmName in inventory");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;

}


########################################################################
#
# GetHostIP
#     Method to get the host IP on which the VM is sitting
#
# Input:
#
# Results:
#     hostip if SUCCESS,
#     FAILURE if not able to find the host VM is sitting on
#
# Side effects:
#     None
#
########################################################################

sub GetHostIP
{
   my $self = shift;
   my $vmName = $self->{'vmName'};
   my $myHost;

   my $inlineVMObj = $self->GetInlineVMObject();
   $myHost = $inlineVMObj->GetHostIP();
   if (!$myHost) {
      $vdLogger->Error("Failed to find host of VM:" . $vmName);
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $myHost;

}


#############################################################################
#
# VMOpsCrash --
#     Crash the specified VM.
#
# Input:
#     None
#
# Results:
#     "SUCCESS", if the VM was successfully Crashed;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VMOpsCrash
{
   my $self = shift;
   my $esxHost = $self->{'esxHost'};
   my $vmName = $self->{'vmName'};
   my $result = undef;

   my $wincmd = STAF::WrapData("esxcli vm process list|grep -A 1 -x $vmName");
   my $command ="start shell command $wincmd wait returnstdout stderrtostdout";
   my $service = "process";
   ($result, my $data) =
   $self->{stafHelper}->runStafCmd( $esxHost, $service, $command );
   if($result eq FAILURE) {
      $vdLogger->Error("Error processing STAF command: $command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      @result = split(/:/, $data);
   }

   $vdLogger->Info("About to kill process $result[1] ...");
   $wincmd = STAF::WrapData("esxcli vm process kill -t hard -w $result[1]");
   $command ="start shell command $wincmd wait returnstdout stderrtostdout";
   ($result, $data) =
   $self->{stafHelper}->runStafCmd( $esxHost, $service, $command );
   if($result eq FAILURE) {
      $vdLogger->Error("Error processing STAF command: $command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Get the current state of the VM and verify that it is actually powered off
   $result = $self->VMOpsGetPowerState();
   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   } elsif ($result->{result} !~ /poweredoff/i) {
      $vdLogger->Error("Mismatch is requested (poweroff) and current state " .
                       $result->{result});
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}



#############################################################################
#
# VerifyToolsRunningStatus --
#     Return the ToolsRunningStatus for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data in pydict format from the invoked Python method
#     get_tools_running_status
#     $serverForm   - {
#                       'expected_tools_running_status' :
#                                               actual_tools_running_status
#                    }
#
# Side effects:
#     None
#
#############################################################################

sub VerifyToolsRunningStatus
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_tools_running_status($args);
   return $result;
}

#############################################################################
#
# VerifyNicStatus --
#     Return the NIC Status for the specified vnic_index value for the given nsx edge.
#
# Input:
#     $args:
#            execution_type - cli
#            vnic_index - integer value of the nic position
#            vm_ip_address - fetches the NSX EDGE IP from the object hash
#            esx_host_ip - fetches the ESX IP from the object hash
#            esx_username - fetches the ESX Username from the object hash
#            esx_password - fetches the ESX Password from the object hash
#
# Results:
#     returns the server data from the invoked Python method get_nic_status
#     $serverForm   - {
#                       'expected_nic_status' : actual_nic_status
#                    }
#
# Side effects:
#     None
#
#############################################################################

sub VerifyNicStatus
{
   my ($self, $function_name, $args) = @_;
   my $esxHost = $self->{'esxHost'};
   my $hostObj = $self->{'hostObj'};
   my $hostUser = $self->{hostObj}{userid};
   my $hostPassword = $self->{hostObj}{password};
   my $nsxEdgeIp = $self->{'vmIP'};

   $args->{'esx_host_ip'} = $esxHost;
   $args->{'esx_username'} = $hostUser;
   $args->{'esx_password'} = $hostPassword;
   $args->{'vm_ip_address'} = $nsxEdgeIp;

   my $result = $self->get_nic_status($args);
   return $result;
}


1;
