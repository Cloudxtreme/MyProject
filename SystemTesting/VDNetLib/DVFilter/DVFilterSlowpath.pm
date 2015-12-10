###############################################################################
# Copyright (C) 2010 VMware, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# Package VDNetLib::DVFilter::DVFilterSlowpath
#
#   This package allows to perform various operations on DVFilter
#   through STAF command and retrieve status related to these operations.
#
###############################################################################

package VDNetLib::DVFilter::DVFilterSlowpath;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::EsxUtils;
use VDNetLib::NetAdapter::NetDiscover;
use VDNetLib::NetAdapter::NetAdapter;
use VDNetLib::NetAdapter::Vnic::Vnic;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;


use constant BLDMOUNTSSPATH => "/build/apps/bin/build_mounts.pl";

use constant VMXNET3DRVPARAMS => "enable_shm=1 " .
                                 "shm_disclaimer=" .
                                 "IReallyWantThisModeIAmAVMwarePartner";
use constant DATAVNICNAME => "vmxnet3";
use constant KERNELDEVITER => "2000";
use constant SLOWPATH_BIN_NAME => "dvfilter-fw-slow-debug";
use constant PRIVATE_SLOWPATH_SUBNET => "192.168.133.";
use constant SLOWPATH_VMK_IP_HOSTID => "1";
use constant MGMT_VNIC_NAME => "e1000";
use constant SLOWPATH_CTRL_VNIC_NAME => "e1000";
use constant USERSPACE_AGENT_VNIC_NAME => "vmxnet3"; # this is also called data nic
use constant SLOWPATH_VSS_NAME => "DVFilterSwitch";
use constant SLOWPATH_APP_NAME => "SlowpathAPPPG";
use constant SLOWPATH_VMK_NAME => "SlowpathVMKPG";
use constant ROOT_DIR => "/tmp/DVFilter";
use constant DEVKIT_FILENAME => "VMware-dvfilter-devkit.zip";

###############################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::DVFilter::DVFilter).
#
# Input:
#      Testbed  - reference to testbed object
#      SlowpathVM - slowpath VM name
#
# Results:
#      An object of VDNetLib::DVFilter::DVFilterSlowpath package.
#
# Side effects:
#      None
#
###############################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self;
   my $staf_input;
   my $testbed;
   my $slowpath_vm;

   # define some variables
   $self->{slowpathVM}      = $args{slowpathvm};
   $self->{hostObj}         = $args{hostobj};
   $self->{vmOpsObj}        = $args{slowpathobj};
   $self->{netadapterObj}   = $args{netadapterobj};


   if (!$args{slowpathvm}) {
      $vdLogger->Error("SlowpathVM not provided");
      VDSetLastError("EINVALID");
      return undef;
   }
   $self->{stafHelper} = $args{stafhelper};
   if (not defined $self->{stafHelper}) {
      my $staf_input;
      $staf_input->{logObj} = $vdLogger;
      $self->{stafHelper} = VDNetLib::Common::STAFHelper->new($staf_input);
      if (!$self->{stafHelper}) {
         $vdLogger->Error("Failed to create STAF object");
         VDSetLastError("ESTAF");
         return undef;
       }
    }

   my $netadapterobj    = $self->{netadapterObj};
   $self->{hostIP}      = $self->{hostObj}{hostIP};
   $self->{vmIP}        = $self->{vmOpsObj}{vmIP};
   $self->{vmxFile}     = $self->{vmOpsObj}{vmx};

   my $adaptercount = scalar (@$netadapterobj);
   for (my $count = 0; $count < $adaptercount; $count++){
       my $mac = $netadapterobj->[$count]->{'macAddress'};
       my $drivername = $netadapterobj->[$count]->{'name'};
       my $ethernet = VDNetLib::Common::Utilities::GetEthUnitNum($self->{hostIP},
                                                                 $self->{vmxFile},
                                                                 $mac,
                                                                 $self->{stafHelper});
       if($drivername =~ m/vmxnet3/i){
           # used to update the vmx file
           # This vnic vmxnet3 is used as the data nic for the
           # slowpath appliance
           $self->{dataNicObj}= $netadapterobj->[$count];
           $self->{SLOWPATH2_VMX_VNICS} = [$ethernet];
        }else {
           # it is also one control vnic in dvfilter slowpath
           # The below vnic should be e1000 connected to DVFilter
           #specific portgroup

           $self->{SLOWPATH1_VMX_VNICS} = [$ethernet];
           $self->{controlNicObj}= $netadapterobj->[$count];
         }
   }#end of forloop
   $self->{PRIVATE_SLOWPATH_IP} = PRIVATE_SLOWPATH_SUBNET;
   $self->{SLOWPATH_VMK_IP}     = PRIVATE_SLOWPATH_SUBNET . SLOWPATH_VMK_IP_HOSTID;
   $self->{MANAGE_VNIC} = "";            #e1000
   $self->{SLOWPATH1_VNIC} = "";         #e1000
   $self->{USERSPACE_AGENT_VNIC} = "";   #vmxnet3
   $self->{SLOWPATH_SDK_NAME} = "";
   $self->{DVFILTER_DEVKIT_NAME} = "";
   $self->{SLOWPATH_VSS} = SLOWPATH_VSS_NAME;
   $self->{SLOWPATH_APP} = SLOWPATH_APP_NAME;
   $self->{SLOWPATH_VMK} = SLOWPATH_VMK_NAME;
   $self->{ROOT_DIR}  = ROOT_DIR;
   $self->{DEVKIT_FILENAME} = DEVKIT_FILENAME;
   $self->{SLOWPATH_BIN_NAME} = SLOWPATH_BIN_NAME;
   $self->{outputFile} = $self->{ROOT_DIR} . "/" . "dvfilter" .
                         "startSlowpath.log";
   bless ($self, $class);
   return $self;
}


########################################################################
#
# InitSlowpathVM --
#      This method will do all InitSlowpathVM functions including
#      CreateSlowpathNetwork, UpdateSlowpathVM, SetupSlowpathBinaries
#      and UpdateVnicDriver.
#
# Input:
#      DVFilter type
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     Depends on the command/script being executed
#
########################################################################

sub InitSlowpathVM
{
   my $self = shift;
   my $filter_type = shift;
   my $ret;
   my $options;
   my $slowpath_vm = $self->{slowpathVM};

   $vdLogger->Info("\nInitSlowpathVM: Start to CreateSlowpathNetwork");
   $ret = $self->CreateSlowpathNetwork();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to create DVFilter slowpath network");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("poweroff the slowpath VM");
   $ret = $self->{vmOpsObj}->VMOpsPowerOff();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to poweroff vm");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("Start to UpdateSlowpathVmxfile");
   $ret = $self->UpdateSlowpathVmxfile($filter_type);
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to update the vmx file");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
  $vdLogger->Info("Start to poweron slowpath VM and wait for some minutes");
   $options->{waitForTools} = 0;
   $options->{waitForSTAF} = 1;
   $ret = $self->{vmOpsObj}->VMOpsPowerOn($options);
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to poweron slowpath VM");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("Start to SetupSlowpathVMEnv....");
   $ret = $self->SetupSlowpathVMEnv();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to SetupSlowpathVMEnv");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
  $vdLogger->Info("\nInitSlowpathVM: Start to SetupSlowpathBinaries");
   $ret = $self->SetupSlowpathBinaries();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to SetupSlowpathBinaries");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("Start to UpdateVnicDriver....");
   $ret = $self->UpdateVnicDriver();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to UpdateVnicDriver");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# StartSlowpath --
#      This method will start Slowpath
#
# Input:
#      filiter type
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub StartSlowpath
{
   my $self = shift;
   my $filter_type = shift;
   my $ret;
   my $command;
   my $slowpath_vm = $self->{slowpathVM};
   my $slowpath_bin_name;

   $vdLogger->Info("Initializing slowpath VM....");
   $ret = $self->InitSlowpathVM($filter_type);
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to Initialize SlowpathVMEnv");
       return FAILURE;
     }

   if ($self->{USERSPACE_AGENT_VNIC} eq "") {
      $vdLogger->Info("Start to RefreshSlowpathVMEnv....");
      $ret = $self->RefreshSlowpathVMEnv();
      if ($ret eq FAILURE) {
        $vdLogger->Error("Failed to RefreshSlowpathVMEnv");
        return FAILURE;
      }
   }

  $slowpath_bin_name = $self->GetSlowpathBin();
  if (not defined $slowpath_bin_name) {
      $vdLogger->Error("Slowpath binary not defined");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
    }

   $vdLogger->Info("Start Slowpath2UserspaceAgent");
   $command = "DVFILTERLIB_IP_ADDR=$self->{SLOWPATH_VMK_IP} ";
   $command = $command . "DVFILTERLIB_SHMDEV=/dev/vmxnet_" .
                         "$self->{USERSPACE_AGENT_VNIC}" . "_shm ";
   $command = $command .
              "$self->{ROOT_DIR}/$slowpath_bin_name -a " .
              "$filter_type -l 10 &";
   $vdLogger->Info("Output file for Slowpath2UserspaceAgent is " .
                   "$self->{outputFile}");

   $ret = $self->{stafHelper}->STAFAsyncProcess($self->{vmIP},
                                          $command,
                                          $self->{outputFile});

   if ($ret->{rc} && $ret->{exitCode}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # if the mode is async, save the pid
   $self->{childHandle} = $ret->{handle};
   # if there is an incorrect configuration, dvfilter-fw-slow will fail
   # so wait for a minute and check for PID.
   sleep(100);
   $ret = $self->{stafHelper}->GetProcessInfo($self->{vmIP}, $ret->{handle});
   if ($ret->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{pid} = $ret->{pid};
   $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($self->{vmIP},
                                                         $self->{outputFile});
   if (not defined $self->{stdout}) {
      $vdLogger->Error("Something went wrong with reading the stdout file ".
                       "of Slowpath2UserSpaceAgent. File:$self->{outputFile}".
                       " on $self->{vmIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ((defined $self->{stdout}) &&
            ($self->{stdout} =~
               m/Failed to initialize the DVFilter library/i)) {
      $vdLogger->Error("StartSlowpath1UserspaceAgent failed with stdout\n".
                       "stdout: $self->{stdout}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;
}

########################################################################
#
# GetSlowpathBin --
#      This method gets the slowpath binary
#
# Input:
#       SlowpathType:Classic/VMCI
#
# Results:
#     returns the binary name of the slowpath
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetSlowpathBin
{
   my $self = shift;
   my $ret;
   my $command;
   my $slowpath_bin_name;

   my $arch = $self->{stafHelper}->GetOSArch($self->{vmIP});

   if ($arch eq "x86_64") {
       $slowpath_bin_name = "dvfilter-fw-slow-debug";
     } else {
       $slowpath_bin_name = "dvfilter-fw-slow-debug-32";
      }
   return $slowpath_bin_name;
}


########################################################################
#
# KillSlowpathAgent --
#      This method kills slowpath kernel agent running inside the slow
#      path VM
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub KillSlowpathAgent
{
   my $self = shift;
   my $ret;
   my $command;
   my $slowpathBin;

  $slowpathBin = $self->GetSlowpathBin();
  if (not defined $slowpathBin) {
      $vdLogger->Error("Slowpath binary not defined");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
    }

   $vdLogger->Info("Closing SlowpathAgent $slowpathBin ");
   $command = "killall $slowpathBin";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed: " .
                       "stdout:$ret->{stdout}\nstderr:$ret->{stderr}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# UpdateVnicDriver --
#      1. update data vnic(vmxnet3) driver with special load params
#      2. Bring up the interface
#      3. Update dvfilter kernel agent driver from host
#      4. Configure kernel agent nic driver (vmxnet)
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub UpdateVnicDriver
{
   my $self = shift;
   my $ret;
   my $command;
   my $devkit_dir;
   my $restoreEthInterface = 0;
   my $vmxnetMAC;

   # Update the vnic driver of UserspaceAgent
   $vdLogger->Info("Update the vnic driver of DVFilter UserspaceAgent");
   # for some reason, if VM is rebooted with dvfilterklib_vmxnet initially
   # loaded then the original vmxnet3 driver claims device but shows as
   # as shown below
   # __tmp836216096 Link encap:Ethernet  HWaddr 00:50:56:A5:06:9A
   #       BROADCAST MULTICAST  MTU:1500  Metric:1
   #       RX packets:0 errors:0 dropped:0 overruns:0 frame:0
   #       TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
   #       collisions:0 txqueuelen:1000
   #       RX bytes:0 (0.0 b)  TX bytes:0 (0.0 b)
   #       Interrupt:75 Base address:0x2040
   # So bring up the interface, load the dvfilterklib_vmxnet and
   # fill up the correct interface name
   if ($self->{USERSPACE_AGENT_VNIC} !~ /eth/) {
      $vdLogger->Debug("vmxnet interface is showing other than eth: " .
                       "$self->{USERSPACE_AGENT_VNIC}");
      $command = "ifconfig $self->{USERSPACE_AGENT_VNIC}";
      $vdLogger->Debug("Executing command $command on $self->{vmIP}");
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
      if ($ret->{rc} != 0) {
         $vdLogger->Error("STAF command to $command failed: ");
         if (defined $ret->{stdout}) {
            $vdLogger->Error("stdout: $ret->{stdout}");
         }
         if (defined $ret->{stderr}) {
            $vdLogger->Error("stderr: $ret->{stderr}");
         }
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($ret->{stdout} =~ /((?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2})/i) {
         $vmxnetMAC = $1;
         $vmxnetMAC =~ s/\s*//;
         $vmxnetMAC =~ s/\\n//;
         $vdLogger->Debug("The MAC address for vmxnet interface is: " .
                          "$vmxnetMAC");
         $restoreEthInterface = 1;
      }
   }
   #unload and load the vmxnet3 driver
   my $result;
   $result = VDNetLib::NetAdapter::Vnic::Vnic::DriverUnload($self->{dataNicObj}) ;
   if ($result eq "FAILURE") {
      $vdLogger->Error("DriverUnload failed for vmxnet3");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $command = "modprobe vmxnet3 " . VMXNET3DRVPARAMS;
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($restoreEthInterface) {
      $command = "ifconfig -a";
      $vdLogger->Debug("Executing command $command on $self->{vmIP}");
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
      if ($ret->{rc} != 0) {
         $vdLogger->Error("STAF command to $command failed: ");
         if (defined $ret->{stdout}) {
            $vdLogger->Error("stdout: $ret->{stdout}");
         }
         if (defined $ret->{stderr}) {
            $vdLogger->Error("stderr: $ret->{stderr}");
         }
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($ret->{stdout} =~ /.*(eth\d+).*$vmxnetMAC/i) {
         $self->{USERSPACE_AGENT_VNIC} = $1;
         $vdLogger->Debug("Updating USERSPACE_AGENT_VNIC " .
                       "name to $self->{USERSPACE_AGENT_VNIC}");
      } else {
         $vdLogger->Debug("Unable to Update USERSPACE AGENT VNIC " .
                       "name: ");
         if (defined $ret->{stdout}) {
            $vdLogger->Debug("stdout: $ret->{stdout}");
         }
         if (defined $ret->{stdout}) {
            $vdLogger->Debug("stderr: $ret->{stderr}");
         }
      }
   }
   $command = "ifconfig $self->{USERSPACE_AGENT_VNIC} up";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($self->SlowpathUserspaceDeviceExists() eq FAILURE) {
      $vdLogger->Error("Failed to update the driver of ".
                       "slowpath userspace vnic");
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   return SUCCESS;
}

########################################################################
#
# SlowpathUserspaceDeviceExists --
#      Checks if the slowpath user space device exists on the slowpath
#      VM
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SlowpathUserspaceDeviceExists
{
   my $self = shift;
   my $ret;
   my $command;
   $command = "ls /dev/vmxnet_*";
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed: " .
                       "stdout: $self->{stdout}\nstderr:$self->{stderr}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{stdout} =~ m/_shm/) {
     $vdLogger->Info("Found Slowpath userspace Device");
     return SUCCESS;
   } else {
     $vdLogger->Info("Can not found Slowpath userspace Device");
     return FAILURE;
   }
}


########################################################################
#
# SlowpathKernelDeviceExists --
#      Checks if the slowpath kernel space device exists on the slowpath
#      VM
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SlowpathKernelDeviceExists
{
   my $self = shift;
   my $ret;
   my $command;

   $command = "ls /dev/dvfilter*";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed: " .
                       "stdout: $self->{stdout}\nstderr:$self->{stderr}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("command failed with non-zero return value" .
                       " $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("command failed with stdout: $ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("command failed with stdout: $ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if ($ret->{stdout} =~ m/_vmxnet/) {
     $vdLogger->Info("Found Slowpath kernel device");
     return SUCCESS;
   } else {
     $vdLogger->Info("Can not found Slowpath kernel device");
     VDSetLastError("EINVALID");
     return FAILURE;
   }
}


########################################################################
#
# GetSlowpathSDKName --
#      Retrieve slow path SDK name
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetSlowpathSDKName
{
   my $self = shift;
   my $ret;
   my $command;

   if ($self->{SLOWPATH_SDK_NAME} ne "") {
      return $self->{SLOWPATH_SDK_NAME};
   }

   $command = "ls $self->{ROOT_DIR} | grep dvfilter-gfp-slowpath-SDK-";
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command: $command failed: " . Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $ret->{stdout} =~ s/^\s+//;  # remove blank
   $ret->{stdout} =~ s/\s+$//;

   if ($ret->{stdout} eq "") {
      $vdLogger->Info("Not found the devkit");
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      $vdLogger->Info("Find the devkit $ret->{stdout}");
      $self->{SLOWPATH_SDK_NAME} = $ret->{stdout};
   }
   return $ret->{stdout};
}


########################################################################
#
# RefreshSlowpathVMEnv --
#      Verifies for right slowpath env and sets up missing pieces if
#      required
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RefreshSlowpathVMEnv
{
   my $self = shift;
   my $ret;
   my $command;
   my @tmp_array;
   my @tmp_array2;
   my $tmp;
   my @ethernet_devs;
   my $dev;
   my $rexp;
   my $ip;
   my $rand_number;

   # command to create a vswitch
   $command = "ifconfig -a | grep Ethernet";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   @tmp_array = split("\n", $ret->{stdout});

   foreach $tmp (@tmp_array) {
      @tmp_array2 = split(/[ \t]/, $tmp);
      $dev = $tmp_array2[0];
      $vdLogger->Info("Find ethernet device $dev in the VM $self->{vmIP}");
      push(@ethernet_devs, $dev);
   }

   $rexp = 'inet\s+addr:(\d+\.\d+\.\d+\.\d+)';
   foreach $dev (@ethernet_devs) {
        $command = "ifconfig $dev";
        $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
        if ($ret->{rc} != 0) {
            $vdLogger->Error("STAF command to $command failed");
            VDSetLastError("ESTAF");
            return FAILURE;
        }
        if ($ret->{stdout} =~ /$rexp/gi) {
            $ip = $1;
        }
        if(defined($ip) && $ip !~ /192\.168/) {
          if ($ip eq $self->{vmIP}) {
             $self->{MANAGE_VNIC} = $dev;
             $vdLogger->Info("Found manage vnic $dev in the VM $self->{vmIP}");
             last;
          }
       }
   }

   foreach $dev (@ethernet_devs) {
       $command = "ethtool -i $dev | grep driver";
       $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
        if ($ret->{rc} != 0) {
            $vdLogger->Error("STAF command to $command failed");
            VDSetLastError("ESTAF");
            return FAILURE;
       }
       if ($ret->{stdout}) {
           if ($ret->{stdout} =~ m/vmxnet3/gi) {
               $self->{USERSPACE_AGENT_VNIC} = $dev;
               $vdLogger->Info("Found USERSPACE_AGENT_VNIC vnic $dev in the VM $self->{vmIP}");
           } elsif ($ret->{stdout}=~ m/e1000/gi) {
               if ($dev ne $self->{MANAGE_VNIC}) {
                   $self->{SLOWPATH1_VNIC} = $dev;
                   $vdLogger->Info("Found SLOWPATH1_VNIC vnic $dev in the VM $self->{vmIP}");
               }
           }
       }
   }
   if (!$self->{USERSPACE_AGENT_VNIC} || !$self->{SLOWPATH1_VNIC} || !$self->{MANAGE_VNIC}) {
       $vdLogger->Error("Can not find all needed vnic in the VM $self->{vmIP}");
       return FAILURE;
   }

   $command = "ifconfig $self->{SLOWPATH1_VNIC}";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
            $vdLogger->Error("STAF command to $command failed");
            VDSetLastError("ESTAF");
            return FAILURE;
   }
   if ($ret->{stdout} =~ /$rexp/gi) {
          $ip = $1;
   }
   $self->{PRIVATE_SLOWPATH_IP} = $ip;

   return SUCCESS;
}


########################################################################
#
# SetupSlowpathVMEnv --
#      Sets up right slowpath env inside the slowpath VM
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetupSlowpathVMEnv
{
   my $self = shift;
   my $ret;
   my $command;
   my @tmp_array;
   my @tmp_array2;
   my $tmp;
   my @ethernet_devs;
   my $dev;
   my $rexp;
   my $ip;
   my $rand_number;

   # command to create a vswitch
   $command = "ifconfig -a | grep Ethernet";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   @tmp_array = split("\n", $ret->{stdout});

   foreach $tmp (@tmp_array) {
      @tmp_array2 = split(/[ \t]/, $tmp);
      $dev = $tmp_array2[0];
      $vdLogger->Info("Find ethernet device $dev in the VM $self->{vmIP}");
      push(@ethernet_devs, $dev);
   }
   $vdLogger->Debug("Ethernet devices found: @ethernet_devs");
   $rexp = 'inet\s+addr:(\d+\.\d+\.\d+\.\d+)';
   foreach $dev (@ethernet_devs) {
        $command = "ifconfig $dev";
        $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
        if ($ret->{rc} != 0) {
            $vdLogger->Error("STAF command to $command failed");
            VDSetLastError("ESTAF");
            return FAILURE;
        }
        if ($ret->{stdout} =~ /$rexp/gi) {
            $ip = $1;
        }
        if(defined($ip) && $ip !~ /192\.168/) {
          if ($ip eq $self->{vmIP}) {
             $self->{MANAGE_VNIC} = $dev;
             $vdLogger->Info("Found manage vnic $dev in the VM $self->{vmIP}");
             last;
          }
       }
   }

   foreach $dev (@ethernet_devs) {
       $command = "ethtool -i $dev | grep driver";
       $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
        if ($ret->{rc} != 0) {
            $vdLogger->Error("STAF command to $command failed");
            VDSetLastError("ESTAF");
            return FAILURE;
       }
       if ($ret->{stdout}) {
           if ($ret->{stdout} =~ m/vmxnet3/gi) {
               $self->{USERSPACE_AGENT_VNIC} = $dev;
               $vdLogger->Info("Found USERSPACE_AGENT_VNIC vnic $dev in the VM $self->{vmIP}");
           } elsif ($ret->{stdout}=~ m/e1000/gi) {
               if ($dev ne $self->{MANAGE_VNIC}) {
                   $self->{SLOWPATH1_VNIC} = $dev;
                   $vdLogger->Info("Found SLOWPATH1_VNIC vnic $dev in the VM $self->{vmIP}");
               }
           }
       }
   }
   if (!$self->{USERSPACE_AGENT_VNIC} ||
       !$self->{SLOWPATH1_VNIC} || !$self->{MANAGE_VNIC}) {
       $vdLogger->Error("Can not find all needed vnic in the VM " .
                        "$self->{vmIP}" . Dumper($self));
       return FAILURE;
   }


   # Set SLOWPATH1_VNIC IP
   $rand_number = int(rand(251)) + 2;
   $self->{PRIVATE_SLOWPATH_IP} = $self->{PRIVATE_SLOWPATH_IP} . $rand_number;
   my $netmask="255.255.255.0";
   my $result=VDNetLib::NetAdapter::Vnic::Vnic::SetIPv4($self->{controlNicObj},
                                                     $self->{PRIVATE_SLOWPATH_IP},
                                                     $netmask) ;
   if ($result eq "FAILURE") {
      $vdLogger->Error("Setting Ip address on slowpath VM failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# SetupSlowpathBinaries --
#      Sets up required slowpath user/kernel space agent binaries path
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SetupSlowpathBinaries
{
   my $self = shift;
   my $ret;
   my $command;
   my $devkit_dir;

   $vdLogger->Info("\nSetupSlowpathBinaries: Start to Setup SlowpathBinaries");
   # The below check doesn't guarantee the slowpath binaries are built
   # in case compiling slowpath binaries failed in the previous run
   if ($self->NeedUpdateSlowpathBinaries() eq "FALSE") {
       $vdLogger->Info("SlowpathBinaries is latest and needn't update");
       return SUCCESS;
   }

   if ($self->{hostObj}->TestEsxSetup() eq FAILURE) {
        $vdLogger->Error("Can not get VMTREE on the ESX build");
        VDSetLastError("ESTAF");
        return FAILURE;
   }

   my $cmd = "ls /build/apps/bin/build_mounts.pl";

   $vdLogger->Info("Executing $cmd");
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{vmIP},
                                                  $cmd);
   # Process the result
   if (($result->{rc} ne 0) || ($result->{exitCode} ne 0)) {
       $command = "mkdir -p /build/apps; mount -t nfs " .
              "build-apps.eng.vmware.com:/apps /build/apps";
       $vdLogger->Debug("Executing command on $command $self->{vmIP}");
       $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
       if ($ret->{rc} != 0) {
        $vdLogger->Error("STAF command to $command failed due to STAF" .
                         "failure: $ret->{rc}");
        VDSetLastError("ESTAF");
        return FAILURE;
        }
       if ($ret->{exitCode} != 0) {
          $vdLogger->Error("$command failed with non-zero return value" .
                       " $ret->{exitCode}");
          if (defined $ret->{stdout}) {
            $vdLogger->Error("$command failed with stdout: $ret->{stdout}");
           }
          if (defined $ret->{stderr}) {
            $vdLogger->Error("$command failed with stdout: $ret->{stderr}");
        }
        VDSetLastError("EFAIL");
        return FAILURE;
       }
    }

   # mount all vmtree
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, BLDMOUNTSSPATH);
   if ($ret->{rc} != 0) {
        $vdLogger->Error("STAF command to $command failed: " .
                         "$ret->{stdout}\n $ret->{stderr}");
        VDSetLastError("ESTAF");
        return FAILURE;
   }
   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("$command failed with non-zero return value" .
                       " $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # clean the directory DVFilter
   if ((not defined $self->{ROOT_DIR}) || ($self->{ROOT_DIR} eq '/')) {
      $vdLogger->Error("Attempting to remove something under root system");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $command = "rm -rf $self->{ROOT_DIR}; mkdir -p $self->{ROOT_DIR}";
   $vdLogger->Debug("Executing command on $command $self->{vmIP}");

   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
        $vdLogger->Error("STAF command to $command failed: " .
                         "$ret->{stdout}\n $ret->{stderr}");
        VDSetLastError("ESTAF");
        return FAILURE;
   }
   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("$command failed with non-zero return value" .
                       " $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   #copy VMware-dvfilter-devkit-5.0.0-354028.zip to VMware-dvfilter-devkit.zip
   my $publishDir = $self->{hostObj}->{vmtree};
   $publishDir =~ s/bora$|bora\/$//;
   $command = "cp $publishDir"."publish/VMware-dvfilter-gfp-devkit-* ".
              "$self->{ROOT_DIR}/";
   $vdLogger->Debug("Executing command on $command $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
        $vdLogger->Error("STAF command to $command failed: " .
                         "$ret->{stdout}\n $ret->{stderr}");
        VDSetLastError("ESTAF");
        return FAILURE;
   }
   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("$command failed with non-zero return value" .
                       " $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Get the DVFILTER DEVKIT name from build number
   $self->GetDVFilterDevkitName();
   if ($self->{DVFILTER_DEVKIT_NAME} eq "") {
       $vdLogger->Error("Failed to get SlowpathSDKName");
       VDSetLastError("ESTAF");
       return FAILURE;
   }
   # prepare DVFilter slowpath binaries
   $command = "unzip -d $self->{ROOT_DIR} " .
              "$self->{ROOT_DIR}/$self->{DVFILTER_DEVKIT_NAME}";

   $vdLogger->Debug("Executing command on $command $self->{vmIP}");

   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed: ".
                       "$ret->{stdout}\n $ret->{stderr}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("$command failed with non-zero return value" .
                       " $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # build the SDK name from build number
   $self->{SLOWPATH_SDK_NAME} = $self->GetSlowpathSDKName();
   if ($self->{SLOWPATH_SDK_NAME} eq "") {
       $vdLogger->Error("Failed to get SlowpathSDKName");
       VDSetLastError("ESTAF");
       return FAILURE;
   }

   $devkit_dir = "$self->{ROOT_DIR}/$self->{SLOWPATH_SDK_NAME}";
   # update $self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME}
   $vdLogger->Info("Complile $devkit_dir");
   $command = "cd $devkit_dir; make;";
   $command = $command . "cp -f $devkit_dir/bin" .
                                    "/dvfilter-* " .
                         "$self->{ROOT_DIR}/ ",
   $vdLogger->Debug("Executing command on $command $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed: " .
                       "$ret->{stdout}\n $ret->{stderr}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("$command failed with non-zero return value" .
                       " $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Info("Complile kernel library of DVFilter slowpath");
   $command = "cd $devkit_dir/klib; $devkit_dir/klib/build.sh;";
   $vdLogger->Debug("Executing command: $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed: " .
                       "$ret->{stdout}\n $ret->{stderr}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("$command failed with non-zero return value" .
                       " $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetDVFilterDevkitName --
#      Retrieve DVfilter  SDK name
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetDVFilterDevkitName
{
   my $self = shift;
   my $ret;
   my $command;

   $command = "ls $self->{ROOT_DIR} | grep VMware-dvfilter-gfp-devkit-";
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command: $command failed: " . Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $ret->{stdout} =~ s/^\s+//;  # remove blank
   $ret->{stdout} =~ s/\s+$//;

   if ($ret->{stdout} eq "") {
      $vdLogger->Info("Not found the devkit");
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      $vdLogger->Info("Find the devkit $ret->{stdout}");
      $self->{DVFILTER_DEVKIT_NAME} = $ret->{stdout};
   }
   return SUCCESS;
}

########################################################################
#
# NeedUpdateSlowpathBinaries --
#      Based on the host builds, return true if slowpath binaries
#      update is required or FALSE if not required
#
# Input:
#      None
#
# Results:
#     "TRUE": needed
#     "FALSE": not needed
#
# Side effects:
#     None
#
########################################################################

sub NeedUpdateSlowpathBinaries
{
   my $self = shift;
   my $ret;
   my $command;
   my $build_num;

   $command = "vmware -v";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return "TRUE";
   }
   if ((defined $ret->{stdout}) &&
       ($ret->{stdout} =~ m/.*build-(\d+)/)) {
       $build_num = $1;
       $vdLogger->Info("Host build number is $build_num");
   } else {
       $vdLogger->Error("Can not get host build number");
       return "TRUE";
   }
   $command = "ls $self->{ROOT_DIR}/$ret->{stdout}/klib/dvfilterklib.ko;" .
              "ls $self->{ROOT_DIR}/$ret->{stdout}/klib/vmxnet2/dvfilterklib_vmxnet.ko";
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ((defined $ret->{stdout}) &&
       ($ret->{stdout} =~ m/No such file/gi)) {
      $vdLogger->Error("either dvfilterklib.ko or dvfilterklib_vmxnet.ko".
                       " is missing: $ret->{stdout}");
      return "FALSE";
   }
   return "TRUE"
}

########################################################################
#
# UpdateSlowpathVmxfile --
#      Slowpath vmx file need to updated for upgrading tools and the
#      slowpath filter
#
# Input:
#      filter type
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub UpdateSlowpathVmxfile
{
   my $self = shift;
   my $filter_type = shift;
   my $ret;
   my @vmxlines;
   my $eth;
   if (not defined $filter_type) {
      $vdLogger->Error("UpdateSlowpathVmxfile: Undefined filter_type passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Debug("UpdateSlowpathVmxfile: Input params: $filter_type");

   # handle SLOWPATH2_VMX_VNICS

   foreach $eth (@{$self->{SLOWPATH2_VMX_VNICS}}) {
      push(@vmxlines, "$eth.filter0.name=\"dvfilter-faulter\"");
      push(@vmxlines, "$eth.filter0.param0=\"$filter_type\"");
   }
    #removing VDS related parameters
   foreach $eth (@{$self->{SLOWPATH2_VMX_VNICS}}, @{$self->{SLOWPATH1_VMX_VNICS}}) {
       push(@vmxlines, "$eth.dvs.switchId =\"\{\{vdnet-erase\}\}\"");
       push(@vmxlines, "$eth.dvs.portI =\"\{\{vdnet-erase\}\}\"");
       push(@vmxlines, "$eth.dvs.portgroupId =\"\{\{vdnet-erase\}\}\"");
       push(@vmxlines, "$eth.dvs.connectionId =\"\{\{vdnet-erase\}\}\"");
   }
   # changing the portgroup name of vmxnet3, and e1000 to SlowpathAPPG
   foreach $eth (@{$self->{SLOWPATH2_VMX_VNICS}}, @{$self->{SLOWPATH1_VMX_VNICS}}) {
      push(@vmxlines, "$eth.networkName =\"$self->{SLOWPATH_APP}\"");
   }

   if (VDNetLib::Common::Utilities::UpdateVMX($self->{hostIP},
                                              \@vmxlines, $self->{vmxFile},
                                              $self->{stafHelper}) eq
                                              FAILURE) {
      $vdLogger->Error("Failed to update the vmx file of the slowpath VM");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# UpgradeSlowpathVMTools --
#      Upgrade tools on slowpath VM corresponding to the host build
#
# Input:
#      None
#
# Results:
#     returns the value returned by VMOpsUpgradeTool of the VM object
#
# Side effects:
#     None
#
########################################################################

sub UpgradeSlowpathVMTools
{
   my $self = shift;
   my $ret;
   $ret = $self->{vmOpsObj}->VMOpsUpgradeTools();
   return $ret;
}


########################################################################
#
# CreateSlowpathNetwork --
#      Creates portgroups if necessary and connects the control vnic
#      to special slow path portgroup (SLOWPATH_VSS) and data nic to
#      to the same portgroup.  Configures IP address to the vmknic
#      that is connected to the special portgroup
#
# Input:
#      None
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub CreateSlowpathNetwork
{
   my $self = shift;
   my $ret;
   my $command;

   $vdLogger->Info("Create or reuse vswitch, portgroup and vmknic " .
                   "for slowpath testing");
   # command to create a vswitch
   $command = "esxcfg-vswitch --add $self->{SLOWPATH_VSS}";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to create vswitch failed:" . Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{exitCode} != 0) {
      if (((defined $ret->{stdout}) &&
           ($ret->{stdout} =~ /already exists/i)) ||
          ((defined $ret->{stderr}) &&
           ($ret->{stderr} =~ /already exists/i))) {
      } else {
         $vdLogger->Error("command failed with non-zero return value" .
                       " $ret->{exitCode}");
         if (defined $ret->{stdout}) {
            $vdLogger->Error("command failed with stdout: $ret->{stdout}");
         }
         if (defined $ret->{stderr}) {
            $vdLogger->Error("command failed with stdout: $ret->{stderr}");
         }
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   # command to add a APP portgroup to the vswitch
   $command = "esxcfg-vswitch $self->{SLOWPATH_VSS} -A $self->{SLOWPATH_APP}";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to create portgroup failed:" . Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # command to create port group: $self->{SLOWPATH_VMK} on
   # vswitch: $self->{SLOWPATH_VSS}
   # Do we need to create a separate port group for connecting vmknic??
    $command = "esxcfg-vswitch $self->{SLOWPATH_VSS} -A $self->{SLOWPATH_VMK}";
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to create one vmknic failed " .
                       "with rc $ret->{rc}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{exitCode} != 0) {
      if (((defined $ret->{stdout}) &&
           ($ret->{stdout} =~ /already exists/i)) ||
          ((defined $ret->{stderr}) &&
           ($ret->{stderr} =~ /already exists/i))) {
         # do nothing
      } else {
         $vdLogger->Error("command failed with non-zero return value" .
                       " $ret->{exitCode}");
         if (defined $ret->{stdout}) {
            $vdLogger->Error("command failed with stdout: $ret->{stdout}");
         }
         if (defined $ret->{stderr}) {
            $vdLogger->Error("command failed with stdout: $ret->{stderr}");
         }
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   $command = "esxcfg-vmknic -a -i $self->{SLOWPATH_VMK_IP} -n 255.255.255.0 " .
              "-p $self->{SLOWPATH_VMK}";
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to create one vmknic failed " .
                       "with rc $ret->{rc}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # if a vmknic already exists from the previous run then change
   # the IP address alone
   if ($ret->{exitCode} != 0) {
      if (((defined $ret->{stdout}) &&
           ($ret->{stdout} =~ /already exists/i)) ||
          ((defined $ret->{stderr}) &&
           ($ret->{stderr} =~ /already exists/i))) {
         if ($self->ChangeVMKIP()) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } else {
         $vdLogger->Error("command failed with non-zero return value" .
                       " $ret->{exitCode}");
         if (defined $ret->{stdout}) {
            $vdLogger->Error("command failed with stdout: $ret->{stdout}");
         }
         if (defined $ret->{stderr}) {
            $vdLogger->Error("command failed with stdout: $ret->{stderr}");
         }
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   $self->{hostObj}->HostNetRefresh();
   #
   # Check the updated network information on the host and verify if the
   # vswitch and portgroup exist in that list
   #
   $self->{hostObj}->UpdatePGHash();
   if (!exists($self->{hostObj}->{switches}{$self->{SLOWPATH_VSS}}) ||
       !exists($self->{hostObj}->{portgroups}{$self->{SLOWPATH_APP}}) ||
       !exists($self->{hostObj}->{portgroups}{$self->{SLOWPATH_VMK}})) {
      $vdLogger->Error("Failed to create SlowpathNetwork");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # command to configure DVFilter subsystem by specifing the IP address
   # of one vmknic
   $command = "esxcfg-advcfg -s $self->{SLOWPATH_VMK_IP} /Net/DVFilterBindIpAddress";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to bind DVFilter with one vmknic failed:" . Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (($ret->{stdout} =~ m/error|fail/gi) ||
       ($ret->{stderr} =~ m/error|fail/gi)) {
       $vdLogger->Error("Failed to bind DVFilter with one vmknic");
       # assuming vdLogger will check for undefined strings and ignore
       $vdLogger->Error("stdout: $ret->{stdout}\nstderr: $ret->{stderr}");
       VDSetLastError("ESTAF");
       return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# ChangeVMKIP --
#      Changes slowpath vmknic's IP address
#
# Input:
#      None
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub ChangeVMKIP
{
   my $self = shift;
   my ($command, $ret);
   $command = "esxcfg-vmknic -i $self->{SLOWPATH_VMK_IP} -n 255.255.255.0 " .
              "-p $self->{SLOWPATH_VMK}";
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to change vmknic IP failed " .
                       "with STAF rc $ret->{rc}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("command failed with non-zero return value" .
                       " $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("command failed with stdout: $ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("command failed with stdout: $ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


########################################################################
#
# StartVMCISlowpath --
#      This method will start slowpath binary ./dvfilter-fw-slow inside
#      VMCI Slowpath VM
#
# Input:
#      filiter type
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub StartVMCISlowpath
{
   my $self = shift;
   my $filter_type = shift;
   my $ret;
   my $command;
   my $slowpath_vm = $self->{slowpathVM};
   my $vmci_slowpath_bin_name;

  $vmci_slowpath_bin_name = $self->GetSlowpathBin();
  if (not defined $vmci_slowpath_bin_name) {
      $vdLogger->Error("Slowpath binary not defined");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
    }

   $vdLogger->Info("Initializing VMCI slowpath VM....");
   $ret = $self->InitVMCISlowpathVM($filter_type);

   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to Initialize SlowpathVMEnv");
        VDSetLastError(VDGetLastError());
       return FAILURE;
     }

   $vdLogger->Info("Start VMCI Slowpath");
   $command = "DVFILTERLIB_VMCI=1 DVFILTERLIB_SHMDEV=/dev/dvfilterk_shm_0  ";
   $command = $command . "$self->{ROOT_DIR}/" . $vmci_slowpath_bin_name .
                                   "  -a " . "$filter_type -l 10 --select &";
   $vdLogger->Info("Output file for Slowpath VMCI is " .
                   "$self->{outputFile}");

   $ret = $self->{stafHelper}->STAFAsyncProcess($self->{vmIP},
                                          $command,
                                          $self->{outputFile});

   if ($ret->{rc} && $ret->{exitCode}) {
      $vdLogger->Error("Dumper($ret)");
      VDSetLastError("ESTAF");
      return FAILURE;
     }

   # if the mode is async, save the pid
   $self->{childHandle} = $ret->{handle};
   # if there is an incorrect configuration, dvfilter-fw-slow will fail
   # so wait for a minute and check for PID.
   my $timeout = 10;
      do {
         sleep(5);
         $timeout--;
         # If endTimeStamp is defined it means the process is already completed
         # if not then we wait for process to be completed.
         $ret = $self->{stafHelper}->GetProcessInfo($self->{vmIP},
                                                             $self->{childHandle});
         if ($ret->{rc}) {
            if (not defined $ret->{endTimestamp}) {
               $vdLogger->Error("endTimeStamp not defined and rc != 0 for ".
                                "$self->{childHandle} on $self->{vmIP}");
               VDSetLastError("ESTAF");
               return FAILURE;
            }
         }
      } while($timeout > 0 && (not defined $ret->{endTimestamp}) != 0);

    if ($timeout == 0) {
        $vdLogger->Debug("Hit Timeout=$timeout min for ".
			    "$self->{childHandle} on $self->{vmIP}. Still trying ".
			                        "to read stdout");
      }
   $self->{pid} = $ret->{pid};
   $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($self->{vmIP},
                                                         $self->{outputFile});
   if ((defined $self->{stdout}) && ($self->{stdout} =~ m/Failed/i)) {
      $vdLogger->Error("Starting VMCI slowpath binary /dvfilter-fw-slow " .
                              " failed with stdout\nstdout: $self->{stdout}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
     }

   return SUCCESS;
}



########################################################################
#
# InitVMCISlowpathVM --
#     This method will do all initializing functions needed to start
#     the slowpath
#
# Input:
#      Filter:filtername that is used in the protected VM
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub InitVMCISlowpathVM
{
   my $self = shift;
   my $filter_type = shift;
   my $ret;

  $vdLogger->Info("\nInitSlowpathVM: Start to EnableVMCI "
                                                ."security on host");
   $ret = $self->EnableVMCISecurityHost();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to create DVFilter slowpath network");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

  $vdLogger->Info("\n SetupVMCIVM:set-up the VMCI  slowpath VM");
   $ret = $self->SetupVMCIVM();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to set-up vmci VM");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
}


########################################################################
#
# EnableVMCISecurityHost --
#      This method adds the security seetings needed in the host
#      to put the VM in VMCI mode
#
# Input:
#      None
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub EnableVMCISecurityHost
{
   my $self = shift;
   my ($command, $ret);
   $command = "export dvfilterVMCIServiceLabel=" .
                              "'dvfilter:SlowPathConnect'";
   $vdLogger->Debug("Executing $command on $self->{hostIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to change vmknic IP failed " .
                       "with STAF rc $ret->{rc}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("command $command failed with non-zero " .
                             "return value $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("command $command failed with stdout: " .
                                                 "$ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("command $command failed with stdout: " .
                                                   "$ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $command = "/sbin/secpolicytools -N dvfilterServiceVM ";
   $vdLogger->Debug("Executing $command on $self->{hostIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to change vmknic IP failed " .
                       "with STAF rc $ret->{rc}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("command $command failed with non-zero " .
                             "return value $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("command $command failed with stdout: " .
                                                 "$ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("command $command failed with stdout: " .
                                                   "$ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $command = "/sbin/secpolicytools -T 'dvfilter\:SlowPathConnect' " .
                                               "-L dvfilterServiceVM";
   $vdLogger->Debug("Executing $command on $self->{hostIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to change vmknic IP failed " .
                       "with STAF rc $ret->{rc}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("command $command failed with non-zero " .
                             "return value $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("command $command failed with stdout: " .
                                                 "$ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("command $command failed with stdout: " .
                                                   "$ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }

}


########################################################################
#
# SetupVMCIVM --
#      This method contains the required functions to use a VM
#       in the VMCI mode
#
# Input:
#      None
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub  SetupVMCIVM
{
   my $self = shift;
   my $ret;

   $vdLogger->Info("Start to poweroff the slowpath VMCI VM");
   $ret = $self->{vmOpsObj}->VMOpsPowerOff();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to poweroff $self->{vmIP}");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   $vdLogger->Info("Start to Unregister the slowpath VMCI VM");
   $ret = $self->{vmOpsObj}->VMOpsUnRegisterVM();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to unregister $self->{vmIP}");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   $vdLogger->Info("Start to poweron the slowpath VMCI VM");
   $ret = $self->StartVMCIVM();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to poweron vm in VMCI mode");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   $vdLogger->Info("Start to register the slowpath VMCI VM");
   $ret = $self->{vmOpsObj}->VMOpsRegisterVM();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to poweroff vm");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   $vdLogger->Info("Verify VM $self->{vmIP} in VMCI mode");
   $ret = $self->VerifyVMCIVM();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to put VM in VMCI mode");
       VDSetLastError(VDGetLastError());
       return FAILURE;
    }

   $vdLogger->Info("\nInitSlowpathVM: Start to SetupSlowpathBinaries");
   $ret = $self->SetupSlowpathBinaries();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to SetupSlowpathBinaries");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   $vdLogger->Info("Set up enviroment for VMCI VM");
   $ret = $self->SetupVMCIVMEnv();
   if ($ret eq FAILURE) {
       $vdLogger->Error("Failed to put VM in VMCI mode");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

}


########################################################################
#
# StartVMCIVM --
#      Poweron's a VM in VMCI mode
#
# Input:
#      None
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub StartVMCIVM
{
   my $self = shift;
   my ($command, $ret);
   my $host = $self->{hostIP};

   my $secDOMVal = $self->SecurityDOMValue();
   $secDOMVal =~ s/\n$//;

   if ($secDOMVal != 14){
       $vdLogger->Error("Not a valid securityDOMValue");
        VDSetLastError("ENOTDEF");
        return FAILURE;
    }

   my $timestamp = VDNetLib::Common::Utilities::GetTimeStamp();
   $self->{setupvmcivmoutputFile} = "/DVFilter" .  "/" .
                                       "VMCIVMpoweron" . "slowpath" .
                                           $timestamp . '.log';
   $command = "/bin/vmx ++swap=false,securitydom="  . $secDOMVal .
                    " -s msg.noOK=true -s msg.autoAnswer=true -x " .
                                               "$self->{vmxFile}"  ;
   $vdLogger->Debug("Output file for VMCI VM is $self->{setupvmcivmoutputFile}");

   $ret = $self->{stafHelper}->STAFAsyncProcess($host,
                                                $command,
                                           $self->{setupvmcivmoutputFile});
   # if the mode is async, save the pid
   $self->{childHandle} = $ret->{handle};
   my $timeout = 20;
      do {
         sleep(5);
         $timeout--;
         # If endTimeStamp is defined it means the process is already completed
         # if not then we wait for process to be completed.
         $ret = $self->{stafHelper}->GetProcessInfo($host, $self->{childHandle});
         if ($ret->{rc}) {
            if (not defined $ret->{endTimestamp}) {
               $vdLogger->Error("endTimeStamp not defined and rc != 0 for ".
                                "$self->{childHandle} on $host");
               VDSetLastError("ESTAF");
               return FAILURE;
            }
         }
      } while($timeout > 0 && (not defined $ret->{endTimestamp}) != 0);

      if ($timeout == 0) {
          $vdLogger->Debug("Hit Timeout=$timeout min for ".
			    "$self->{childHandle} on $host. Still trying ".
			                        "to read stdout");
      }

  $self->{pid} = $ret->{pid};

  $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($host,
                                           $self->{setupvmcivmoutputFile});
    if (not defined $self->{stdout}) {
      $vdLogger->Error("Something went wrong with reading the " .
                       "stdout file of STARTVMCIVM. File: " .
                       "$self->{setupvmcivmoutputFile}on $host");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ((defined $self->{stdout}) &&
            ($self->{stdout} eq " " )&&
                   ($self->{stdout} != m/PowerOn/i )) {
      $vdLogger->Error("$self->{vmIP} power ON failed with stdout\n".
                                            "stdout: $self->{stdout}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

    # Process the result
    if (($ret->{rc}) && ($ret->{exitCode})) {
         $vdLogger->Error("Failed to execute $command");
         VDSetLastError("ESTAF");
         $vdLogger->Debug("Error:" . Dumper($ret));
         return FAILURE;
      }
    #checking if staf is up  on the VM
     if ($self->{stafHelper}->WaitForSTAF($self->{'vmIP'})
                                         eq FAILURE) {
      $vdLogger->Error("STAF not running on $self->{'vmIP'}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

  return SUCCESS;

}


########################################################################
#
# SecurityDOMValue --
#      This method get the securityDOMValue from the host
#
# Input:
#      None
#
# Results:
#     returns numerical value 14 in case of success
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub SecurityDOMValue
{
   my $self = shift;
   my ($command, $ret);

   $command = "/sbin/secpolicytools -D dvfilterServiceVM";
   $vdLogger->Debug("Executing $command on $self->{hostIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to change vmknic IP failed " .
                       "with STAF rc $ret->{rc}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($ret->{exitCode} != 0) {
      $vdLogger->Error("$command failed with non-zero return value" .
                       " $ret->{exitCode}");
      if (defined $ret->{stdout}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stdout}");
      }
      if (defined $ret->{stderr}) {
         $vdLogger->Error("$command failed with stdout: $ret->{stderr}");
      }
      VDSetLastError("EFAIL");
      return FAILURE;
   }
  return $ret->{stdout};
}


########################################################################
#
# VerifyVMCIVM --
#      This method verifies whether the VM is in VMCI mode or not
#
# Input:
#      None
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub VerifyVMCIVM
{
   my $self = shift;
   my $vmName = $self->{vmOpsObj}{vmName};

   my $ret;
   my $command;

   $vdLogger->Info("Verifying VM  $vmName in VMCI mode");
   $command = " ps -Z |grep  vmx";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed: " .
                       "stdout:$ret->{stdout}\nstderr:$ret->{stderr}");
      VDSetLastError("ESTAF");
      return FAILURE;
     }
    if ($ret->{stdout} =~ m/$vmName\s14/){
       return SUCCESS;
     }else {
        $vdLogger->Error("The VM : $self->{vmIP} is not in VMCI mode");
        VDSetLastError("ESTAF");
        return FAILURE;
     }
}


########################################################################
#
# SetupVMCIVMEnv --
#      This method sets the enviroment for running the slowpath
#      binary
#
# Input:
#      None
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub SetupVMCIVMEnv
{
   my $self = shift;
   my $command;
   my $ret;

   # build the SDK name from build number
   $self->{SLOWPATH_SDK_NAME} = $self->GetSlowpathSDKName();
   if ($self->{SLOWPATH_SDK_NAME} eq "") {
       $vdLogger->Error("Failed to get SlowpathSDKName");
       VDSetLastError("ESTAF");
       return FAILURE;
   }
   my $devkit_dir = "$self->{ROOT_DIR}/$self->{SLOWPATH_SDK_NAME}";
   $command = "insmod $devkit_dir/klib/dvfilterklib.ko; sleep 1;" ;
   $vdLogger->Debug("Executing command $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);

   if ($ret->{rc} != 0 || $ret->{exitCode} != 0) {
      $vdLogger->Error("STAF command to $command failed: " .
                       "stdout: $ret->{stdout}\nstderr:$ret->{stderr}");
      VDSetLastError("ESTAF");
      return FAILURE;
     }
   if ($self->SlowpathVMCIDeviceExists() eq FAILURE) {
       VDSetLastError("ESTAF");
       return FAILURE;
      }
}


########################################################################
#
# SlowpathVMCIDeviceExists --
#      Checks if the slowpath device exists on the slowpath
#      VM
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SlowpathVMCIDeviceExists
{
   my $self = shift;
   my $ret;
   my $command;
   $command = "ls /dev/dvfilterk_*";
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF $command failed: " .
                       "stdout: $ret->{stdout}\nstderr:$ret->{stderr}");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{stdout} =~ m/dvfilterk_shm/) {
     $vdLogger->Info("Found Slowpath VMCI Device :$ret->{stdout}");
     return SUCCESS;
   } else {
     $vdLogger->Info("Can not find Slowpath Device /dev/dvfilterk_shm_0");
     return FAILURE;
   }
}


########################################################################
#
# VerifyPuntPackets --
#      Checks traffic is generated in the slowpath VM, when action
#      is PUNT
#
# Input:
#      None
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub VerifyPuntPackets
{
   my $self = shift;
   my $ret;
   my $command;

   $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($self->{vmIP},
                                                         $self->{outputFile});
   my @lines = split(/\n/, $self->{stdout} );
   #Get the last 10 lines in the log file
   my $LogLines =  join("\n", @lines[-10..-1]);
   if (($self->{stdout} eq '')||(defined $self->{stdout}) &&
                                         ($LogLines  !~ /metadatalen/i)) {
      $vdLogger->Error("Failed to punt Packets to the slowpath vm : ($self->{vmIP}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
     }

   return SUCCESS;
}

1;
