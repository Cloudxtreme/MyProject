###############################################################################
# Copyright (C) 2010 VMware, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# Package VDNetLib::DVFilterSlowpath::DVFilterSlowpath
#
#   This package allows to perform various operations on DVFilterSlowpathAgent
#   through STAF command and retrieve status related to these operations.
#
###############################################################################

package VDNetLib::DVFilterSlowpath::DVFilterSlowpath;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::EsxUtils;
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
use constant SLOWPATH_BIN_NAME => "dvfilter-fw-slow";
use constant PRIVATE_SLOWPATH_SUBNET => "192.168.133.";
use constant SLOWPATH_VMK_IP_HOSTID => "1";
use constant MGMT_VNIC_NAME => "e1000";
use constant SLOWPATH_CTRL_VNIC_NAME => "e1000";
use constant USERSPACE_AGENT_VNIC_NAME => "vmxnet3"; # this is also called data nic
use constant KERNEL_AGENT_VNIC_NAME => "vmxnet";
use constant SLOWPATH_VSS_NAME => "DVFilterSwitch";
use constant SLOWPATH_APP_NAME => "SlowpathAPPPG";
use constant SLOWPATH_VMK_NAME => "SlowpathVMKPG";
use constant ROOT_DIR => "/root/DVFilter";
use constant DEVKIT_FILENAME => "VMware-dvfilter-devkit.zip";

###############################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::DVFilterSlowpath::DVFilterSlowpath).
#
# Input:
#      Testbed  - reference to testbed object
#      SlowpathVM - slowpath VM name
#
# Results:
#      An object of VDNetLib::DVFilterSlowpath::DVFilterSlowpath package.
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
   my $testbed;
   my $slowpath_vm;

   if (not defined $args{parentObj}) {
      $vdLogger->Error("Parent object not provided for DVFilter");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{parentObj} = $args{parentObj};

   $self->{stafHelper} = $self->{parentObj}->{stafhelper};
   $self->{vmOpsObj} = $self->{parentObj};
   $self->{hostIP} = $self->{vmOpsObj}->{host};
   $self->{vmIP} = $self->{vmOpsObj}->{vmIP};
   $self->{hostObj} = $self->{vmOpsObj}->{hostObj};
   $self->{vmxFile} =  $self->{vmOpsObj}->{vmx};
   if (not defined $self->{hostObj}->{vmtree}) {
      $self->{hostObj}->{vmtree} = $self->{hostObj}->GetVMTree();
   }
   $self->{vmTree} = $self->{hostObj}->{vmtree};

   # used to update the vmx file
   # ethernet2 in the slowpath vmx should be vmxnet2
   # ethernet1 should be vmxnet3 and ethernet4 should
   # be e1000 control vnic - PR 682170
   $self->{SLOWPATH2_VMX_VNICS} = ["ethernet2", "ethernet1"];

   # it is also one control vnic in dvfilter slowpath
   # The below vnic should be e1000 connected to DVFilter specific portgroup
   $self->{SLOWPATH1_VMX_VNICS} = ["ethernet4"];

   # TODO:
   #    The script should check the vmx file to get SLOWPATH2_VMX_VNICS
   #    automatically by finding the vnic of vmxnet and vmxnet3 in the vmx file,
   #    and to get SLOWPATH1_VMX_VNICS by finding the vnic of
   #    e1000 in the vmx file, which is not used as management vnic.
   #

   $self->{PRIVATE_SLOWPATH_IP} = PRIVATE_SLOWPATH_SUBNET;
   $self->{SLOWPATH_VMK_IP}     = PRIVATE_SLOWPATH_SUBNET . SLOWPATH_VMK_IP_HOSTID;
   $self->{MANAGE_VNIC} = "";            #e1000
   $self->{SLOWPATH1_VNIC} = "";         #e1000
   $self->{USERSPACE_AGENT_VNIC} = "";   #vmxnet3
   $self->{KERNEL_AGENT_VNIC} = "";      #vmxnet
   $self->{ROOT_DIR}  = ROOT_DIR;
   $self->{DEVKIT_FILENAME} = DEVKIT_FILENAME;
   $self->{SLOWPATH_BIN_NAME} = SLOWPATH_BIN_NAME;

   bless ($self, $class);
   return $self;
}


########################################################################
#
# InitSlowpathVM --
#      This method will do all InitSlowpathVM functions UpdateVnicDriver
#      SetupSlowpathBinaries and UpdateVmxnetDriver.
#
# Input:
#      adapters - Slowpath Agent Adapters
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
   my %args = @_;
   my $vmAdapterObjArr = $args{adapters};
   my $ret;

   if (not defined $vmAdapterObjArr) {
      $vdLogger->Error("Parameters missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Info("InitSlowpathVM: Start to SetupSlowpathBinaries");
   $ret = $self->SetupSlowpathBinaries();
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to SetupSlowpathBinaries");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Start to SetupSlowpathVMEnv....");
   foreach my $vmAdapterObj (@$vmAdapterObjArr) {
      if ($vmAdapterObj->{driver} eq "vmxnet3") {
         $self->{USERSPACE_AGENT_VNIC} = $vmAdapterObj->{interface};
         $ret = $self->UpdateVnicDriver();
         if ($ret eq FAILURE) {
            $vdLogger->Error("Failed to update userspace vnic");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } elsif ($vmAdapterObj->{driver} eq "vmxnet2") {
         $self->{KERNEL_AGENT_VNIC} = $vmAdapterObj->{interface};
         $ret = $self->UpdatevmxnetDriver();
         if ($ret eq FAILURE) {
            $vdLogger->Error("Failed to update kernel vnic");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


########################################################################
#
# StartSlowpathAgent --
#      This method will start SlowpathAgent
#
# Input:
#      Agent type
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub StartSlowpathAgent
{
   my $self = shift;
   my %args = @_;
   my $filter_type = $args{agentname};
   my $agent = $args{startslowpathagent};
   my $vmkip = $args{destination_ip};
   my $adapterObj = $args{adapter};
   my $ret = FAILURE;
   my $command;

   $vdLogger->Info("StartSlowpathVM: Start slowpath agent");

   if (defined $adapterObj) {
      $command = "ifconfig $adapterObj->{interface} up";
      $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command, undef,
                                           undef, 1);
   }
   $command = "DVFILTERLIB_IP_ADDR=$vmkip ";
   if ($agent eq "userspace") {
      $command = $command . "DVFILTERLIB_SHMDEV=/dev/vmxnet_" .
                 $adapterObj->{interface} . "_shm ";
   } elsif ($agent eq "kernel") {
      $command = $command . "DVFILTERLIB_KLIBDEV=/dev/dvfilterklib_vmxnet ";
   }
   #Setting command parameter
   $command = $command .
              "$self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME} -a " .
              "$filter_type -l 9 ";
   if ($agent eq "kernel") {
      $command = $command . "--kerneldev /dev/dvfilter_fw_vmxnet &";
   } else {
      $command = $command . "&";
   }

   my $timestamp = VDNetLib::Common::Utilities::GetTimeStamp();

   $self->{outputFile} = $self->{ROOT_DIR} . "/" . "dvfilter" .
                         "-slowpath1" . $timestamp . "_" . $$ . '.log';

   $vdLogger->Info("StartSlowpathVM: $command");
   $vdLogger->Info("Output file for SlowpathAgent is " .
                   "$self->{outputFile}");

   $ret = $self->{stafHelper}->STAFAsyncProcess($self->{vmIP},
                                          $command,
                                          $self->{outputFile});

   $self->{childHandle} = $ret->{handle};
   # if there is an incorrect configuration, dvfilter-fw-slow will fail
   # so wait for a minute and check for PID.
   # TODO: revisit the sleep time, find if there is alternative to wait
   # and ensure no errors.
   sleep(60);
   $ret = $self->{stafHelper}->GetProcessInfo($self->{vmIP}, $ret->{handle});
   if ($ret->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{pid} = $ret->{pid};

   # if process is still running, check the stdout for any error or failures
   # report error if found.
   # TODO: for now, I have only seen it fail with the below error, but we need
   # add other errors too, if there are any.
   $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($self->{vmIP},
                                                  $self->{outputFile});
   if (not defined $self->{stdout}) {
      $vdLogger->Error("Something went wrong with reading the stdout file ".
                       "of SlowpathAgent. " .
                       "File:$self->{outputFile}".
                       " on $self->{vmIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ((defined $self->{stdout}) &&
      ($self->{stdout} =~ m/Failed to initialize the DVFilter library/i)) {
      $vdLogger->Error("Start SlowpathAgent failed with stdout\n".
                       "stdout: $self->{stdout}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $ret = SUCCESS;
   }

   return $ret;
}


########################################################################
#
# StartSlowpath1Agent --
#      This method will start Slowpath1Agent
#
# Input:
#      filter type
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub StartSlowpath1Agent
{
   my $self = shift;
   my $filter_type = shift;
   my $ret;
   my $command;
   my $testbed = $self->{testBed};
   my $slowpath_vm = $self->{slowpathVM};

   $vdLogger->Info("Start Slowpath1Agent");
   $command = "DVFILTERLIB_IP_ADDR=$self->{SLOWPATH_VMK_IP} ";

   $command = $command .
              "$self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME} -a " .
              "$filter_type -l 9 &";

   my $timestamp = VDNetLib::Common::Utilities::GetTimeStamp();

   $self->{slowpath1outputFile} = $self->{ROOT_DIR} . "/" . "dvfilter" .
                         "-slowpath1" . $timestamp . "_" . $$ . '.log';

   $vdLogger->Info("Output file for Slowpath1Agent is " .
                   "$self->{slowpath1outputFile}");

   $ret = $self->{stafHelper}->STAFAsyncProcess($self->{vmIP},
                                          $command,
                                  $self->{slowpath1outputFile});

   $self->{childHandle} = $ret->{handle};
   # if there is an incorrect configuration, dvfilter-fw-slow will fail
   # so wait for a minute and check for PID.
   # TODO: revisit the sleep time, find if there is alternative to wait
   # and ensure no errors.
   sleep(60);
   $ret = $self->{stafHelper}->GetProcessInfo($self->{vmIP}, $ret->{handle});
   if ($ret->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{pid} = $ret->{pid};

   # if process is still running, check the stdout for any error or failures
   # report error if found.
   # TODO: for now, I have only seen it fail with the below error, but we need
   # add other errors too, if there are any.
   $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($self->{vmIP},
                                        $self->{slowpath1outputFile});
   if (not defined $self->{stdout}) {
      $vdLogger->Error("Something went wrong with reading the stdout file ".
                       "of Slowpath1Agent. " .
                       "File:$self->{slowpath1outputFile}".
                       " on $self->{vmIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
   } elsif ((defined $self->{stdout}) &&
            ($self->{stdout} =~
               m/Failed to initialize the DVFilter library/i)) {
      $vdLogger->Error("Start Slowpath1Agent failed with stdout\n".
                       "stdout: $self->{stdout}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   sleep(1);

   return SUCCESS;
}


########################################################################
#
# CloseSlowpath1Agent --
#      This method will stop Slowpath1Agent
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

sub CloseSlowpath1Agent
{
   my $self = shift;
   return $self->KillSlowpathAgent();
}


########################################################################
#
# StartSlowpath2UserspaceAgent --
#      This method will start Slowpath2.0 Userspace Agent
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

sub StartSlowpath2UserspaceAgent
{
   my $self = shift;
   my $filter_type = shift;
   my $ret;
   my $command;
   my $testbed = $self->{testBed};
   my $slowpath_vm = $self->{slowpathVM};

   if ($self->{USERSPACE_AGENT_VNIC} eq "") {
      $vdLogger->Info("Start to RefreshSlowpathVMEnv....");
      $ret = $self->RefreshSlowpathVMEnv();
      if ($ret eq FAILURE) {
        $vdLogger->Error("Failed to RefreshSlowpathVMEnv");
        return FAILURE;
      }
   }

   $vdLogger->Info("Start Slowpath2UserspaceAgent");
   $command = "DVFILTERLIB_IP_ADDR=$self->{SLOWPATH_VMK_IP} ";
   $command = $command . "DVFILTERLIB_SHMDEV=/dev/vmxnet_" .
                         "$self->{USERSPACE_AGENT_VNIC}" . "_shm ";
   $command = $command .
              "$self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME} -a " .
              "$filter_type -l 8 &";

   my $timestamp = VDNetLib::Common::Utilities::GetTimeStamp();
   $self->{outputFile} = $self->{ROOT_DIR} . "/" . "dvfilter" .
                         $timestamp . "_" . ".$$.log";
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
   # TODO: revisit the sleep time, find if there is alternative to wait
   # and ensure no errors.
   sleep(60);
   $ret = $self->{stafHelper}->GetProcessInfo($self->{vmIP}, $ret->{handle});
   if ($ret->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{pid} = $ret->{pid};
   # if endTimestamp is defined, process has exited, means, there was
   # an error, if so, get the stdout and report error
   # TODO: need to check if the process is completed -- used endTimeStamp
   # as indication for the completed process, but even the process is not
   # completed, GetProcessInfo returns an endTimestamp, so, commenting the
   # below code.
   # if(defined $ret->{endTimestamp}){
   #   $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($self->{vmIP},
   #                                                        $self->{outputFile});
   #   if (not defined $self->{stdout}) {
   #      $vdLogger->Error("Something went wrong with reading the stdout file ".
   #                       "of traffic client. File:$self->{outputFile} on ".
   #                       "$self->{vmIP}");
   #      VDSetLastError("ESTAF");
   #      return FAILURE;
   #   } elsif (defined $self->{stdout}) {
   #      $vdLogger->Error("StartSlowpath1UserspaceAgent failed with stdout\n".
   #                       "stdout: $self->{stdout}");
   #      VDSetLastError("EOPFAILED");
   #      return FAILURE;
   #   }
   #}

   # if process is still running, check the stdout for any error or failures
   # report error if found.
   # TODO: for now, I have only seen it fail with the below error, but we need
   # add other errors too, if there are any.
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
# CloseSlowpath2UserspaceAgent --
#      This method will stop Slowpath2UserspaceAgent
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

sub CloseSlowpath2UserspaceAgent
{
   my $self = shift;
   return $self->KillSlowpathAgent();
}


########################################################################
#
# StartSlowpath2KernelAgent --
#      This method will start Slowpath2KernelAgent
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

sub StartSlowpath2KernelAgent
{
   my $self = shift;
   my $filter_type = shift;
   my $ret;
   my $command;
   my $testbed = $self->{testBed};
   my $slowpath_vm = $self->{slowpathVM};

   $vdLogger->Info("Start Slowpath2KernelAgent");

   $vdLogger->Info("Check Slowpath2 Kernel devices exist");

   if ($self->SlowpathKernelDeviceExists() eq FAILURE) {
      $vdLogger->Error("Failed to update the driver of slowpath kernel vnic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $command = "DVFILTERLIB_IP_ADDR=$self->{SLOWPATH_VMK_IP} ";
   $command = $command . "DVFILTERLIB_KLIBDEV=/dev/dvfilterklib_vmxnet ";
   $command = $command . "$self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME} -a " .
                       "$filter_type -l 8 --kerneldev /dev/dvfilter_fw_vmxnet&";
   # $command = $command . " > /tmp/dvfilter-fw-slow.log &";

   my $timestamp = VDNetLib::Common::Utilities::GetTimeStamp();
   $self->{krnlOutputFile} = "/tmp/" . "dvfilter_" .
                         $timestamp . "_" . "$$" .'.log';
   $vdLogger->Info("Output file for Slowpath2KernelAgent is " .
                   "$self->{krnlOutputFile}");

   $ret = $self->{stafHelper}->STAFAsyncProcess($self->{vmIP},
                                                $command,
                                          $self->{krnlOutputFile});

   if ($ret->{rc} && $ret->{exitCode}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # if the mode is async, save the pid
   $self->{childHandle} = $ret->{handle};
   # if there is an incorrect configuration, dvfilter-fw-slow will fail
   # so wait for a minute and check for PID.
   # TODO: revisit the sleep time, find if there is alternative to wait
   # and ensure no errors.
   sleep(60);
   $ret = $self->{stafHelper}->GetProcessInfo($self->{vmIP}, $ret->{handle});
   if ($ret->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{pid} = $ret->{pid};

   # if process is still running, check the stdout for any error or failures
   # report error if found.
   # TODO: for now, I have only seen it fail with the below error, but we need
   # add other errors too, if there are any.
   $self->{stdout} = $self->{stafHelper}->STAFFSReadFile($self->{vmIP},
                                                      $self->{krnlOutputFile});
   if (not defined $self->{stdout}) {
      $vdLogger->Error("Something went wrong with reading the stdout file ".
                    "of Slowpath2UserSpaceAgent. File:$self->{krnlOutputFile}".
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

   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($ret->{stdout} =~ m/error|fail/gi) {
       $vdLogger->Error("Failed to start slowpathKernelAgent");
       $vdLogger->Error("$ret->{stdout}");
       VDSetLastError("ESTAF");
       return FAILURE;
   }
   sleep(30);
   return SUCCESS;
}


########################################################################
#
# CloseSlowpath2KernelAgent --
#      This method will stop Slowpath2KernelAgent
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

sub CloseSlowpath2KernelAgent
{
   my $self = shift;
   return $self->KillSlowpathAgent();
}


########################################################################
#
# RunFloodAttackSlowpath
#      This method will run FloodAttackSlowpath
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

sub RunFloodAttackSlowpath
{
   my $self = shift;
   my $ret;
   my $command;
   my $slowpath_private_ip;
   my $rexp = '\d+\.\d+\.\d+\.\d+';

   if ($self->{PRIVATE_SLOWPATH_IP} !~ /$rexp/) {
      $ret = $self->RefreshSlowpathVMEnv();
      if ($ret eq FAILURE) {
        $vdLogger->Error("Failed to RefreshSlowpathVMEnv");
        return FAILURE;
      }
   }
   $slowpath_private_ip = $self->{PRIVATE_SLOWPATH_IP};
   $vdLogger->Info("Start to floodping $slowpath_private_ip from $self->{hostIP}");
   $command = "ping -c 100 $slowpath_private_ip &";
   $ret = $self->{stafHelper}->STAFAsyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Start to floodping $slowpath_private_ip from the slowpath VM");
   $command = "ping -f -c 10000 $slowpath_private_ip &";
   $ret = $self->{stafHelper}->STAFAsyncProcess($self->{vmIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Run FloodAttackSlowpath and Wait for 60 secs......");
   sleep(60);
   return SUCCESS;
}


########################################################################
#
# RunStressRestartAgent
#      This method will run StressRestartAgent
#
# Input:
#      DVFilter type
#
# Results:
#     "SUCCESS", if successful,
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RunStressRestartAgent
{
   my $self = shift;
   my %args = @_;
   my $filter_type = $args{agentname};
   my $vmAdapterObjArr = $args{adapters};
   $self->{SLOWPATH_VMK_IP} = $args{destination_ip};
   my $ret;
   my @commands;
   my $command;
   my $command2;

   # The below are script comes as part of SDK
   my $uagent_sh = "uagent.sh";
   my $kagent_sh = "kagent.sh";
   my $vnic_sh = "vnic.sh";
   if ((not defined $filter_type) && (not defined $self->{SLOWPATH_VMK_IP})
      && (not defined $vmAdapterObjArr)) {
         $vdLogger->Error("Parameters missing");
         VDSetLastError("ENOTDEF");
         return FAILURE;
   }

   my $scriptName = undef;
   foreach my $vmAdapterObj (@$vmAdapterObjArr) {
      if ($vmAdapterObj->{driver} eq "vmxnet3") {
         # create userspace agent shell script
         $self->{USERSPACE_AGENT_VNIC} = $vmAdapterObj->{interface};
         $command2 = "DVFILTERLIB_IP_ADDR=$self->{SLOWPATH_VMK_IP} " .
                     "DVFILTERLIB_SHMDEV=/dev/vmxnet_" .
                     $self->{USERSPACE_AGENT_VNIC} . "_shm " .
                     "$self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME} " .
                     "-a $filter_type -l 9 &";
         $scriptName = $uagent_sh;
      } elsif ($vmAdapterObj->{driver} eq "vmxnet2") {
         # create kernel agent shell script
         $self->{KERNEL_AGENT_VNIC} = $vmAdapterObj->{interface};
         $command2 = "DVFILTERLIB_IP_ADDR=$self->{SLOWPATH_VMK_IP} " .
                     "DVFILTERLIB_KLIBDEV=/dev/dvfilterklib_vmxnet " .
                     "$self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME} " .
                     "-a $filter_type -l 9 " .
                     "--kerneldev /dev/dvfilter_fw_vmxnet &";
         $scriptName = $kagent_sh;
      }
      $command = "echo \'i=1\n" .
                 "while [ \$i -lt 2000 ]\ndo\n" .
                 "$command2\nsleep 0.01;killall dvfilter-fw-slow\n" .
                 "let i+=1\ndone\' > $self->{ROOT_DIR}/$scriptName";
      push(@commands, $command);
   }
   # create up/down vnic shell script
   $command = "echo \'i=1\n" .
         "while [ \$i -lt 600 ]\ndo\n" .
         "ifconfig $self->{USERSPACE_AGENT_VNIC} down\n" .
         "ifconfig $self->{KERNEL_AGENT_VNIC} down\n" .
         "ifconfig $self->{USERSPACE_AGENT_VNIC} up\n" .
         "ifconfig $self->{KERNEL_AGENT_VNIC} up\n" .
         "let i+=1\ndone\' > $self->{ROOT_DIR}/$vnic_sh";
   push(@commands, $command);

   #create scripts
   $vdLogger->Info("Creating shell script in vm: $kagent_sh $uagent_sh $vnic_sh");
   foreach $command (@commands) {
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command,
                                                  undef, undef, 1);
      if ($ret eq "FAILURE") {
         $vdLogger->Error("STAF command to $command failed");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   #run scripts
   @commands = ("sleep 2; sh $self->{ROOT_DIR}/$kagent_sh &",
                "sh $self->{ROOT_DIR}/$vnic_sh &",
                "sleep 2; sh $self->{ROOT_DIR}/$uagent_sh &");
   $vdLogger->Info("Executing shell script in vm: "
                   . "$kagent_sh $uagent_sh $vnic_sh");
   foreach $command (@commands) {
      my $timestamp = VDNetLib::Common::Utilities::GetTimeStamp();
      $self->{outputFile} = $self->{ROOT_DIR} . "/" . "dvfilter" .
                            $timestamp . "_" . ".$$.log";
      $vdLogger->Info("Output file for $command is " .
                      "$self->{outputFile}");

      $ret = $self->{stafHelper}->STAFAsyncProcess($self->{vmIP},
                                             $command,
                                             $self->{outputFile});
      if ($ret eq "FAILURE") {
         $vdLogger->Error("STAF command to $command failed");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      sleep(100);
   }

   # give sometime before bringing up the device
   sleep(20);
   $command = "ifconfig $self->{USERSPACE_AGENT_VNIC} up; ifconfig $self->{KERNEL_AGENT_VNIC} up";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command, undef,
                                               undef, 1);

   # noticed it takes some time to create slowpath kernel device /dev/dvfilter*
   # so, given sometime
   sleep(20);

   return SUCCESS;
}


#
#  Below are internal functions, meaning doesn't have keyword
#  to use it as workload
#


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


   $vdLogger->Info("Closing SlowpathAgent $self->{SLOWPATH_BIN_NAME}");
   $command = "killall $self->{SLOWPATH_BIN_NAME}";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command, undef,
                                               undef, 1);
   if ($ret eq FAILURE) {
      $vdLogger->Error("STAF command to $command failed");
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
#      TODO: check if this method can be replaced with NetAdapter
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
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command,
                                                  undef, undef, 1);
      if ($ret->{stdout} =~ /((?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2})/i) {
         $vmxnetMAC = $1;
         $vmxnetMAC =~ s/\s*//;
         $vmxnetMAC =~ s/\\n//;
         $vdLogger->Debug("The MAC address for vmxnet interface is: " .
                          "$vmxnetMAC");
         $restoreEthInterface = 1;
      }
   }
   # TODO: The below 3 steps can be replaced with NetAdapter workload
   #       However, there need to ba flag to store that it has been done
   #       so that other workloads will know
   my @commands = ("rmmod " . DATAVNICNAME,
                   "modprobe vmxnet3 " . VMXNET3DRVPARAMS);
   foreach my $cmd (@commands) {
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $cmd, undef,
                                                  undef, 1);
      if ($ret eq "FAILURE") {
         $vdLogger->Error("STAF command to $cmd failed");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   if ($restoreEthInterface) {
      $command = "ifconfig -a";
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command,
                                                  undef, undef, 1);
      if ($ret->{stdout} =~ /.*(eth\d+).*$vmxnetMAC/i) {
         $self->{USERSPACE_AGENT_VNIC} = $1;
         $vdLogger->Debug("Updating USERSPACE_AGENT_VNIC " .
                       "name to $self->{USERSPACE_AGENT_VNIC}");
      } else {
         return FAILURE;
      }
   }
   $command = "ifconfig $self->{USERSPACE_AGENT_VNIC} up";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command, undef,
                                               undef, 1);
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
# UpdatevmxnetDriver --
#      1. Update dvfilter kernel agent driver from host
#      2. Configure kernel agent nic driver (vmxnet)
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

sub UpdatevmxnetDriver
{
   my $self = shift;
   my ($ret, $vmxnetMAC, $command);
   my $restoreEthInterface = 0;

   if (not defined $self->{SLOWPATH_SDK_NAME}) {
      $vdLogger->Error("SLOWPATH SDK NAME is not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ((not defined $self->{KERNEL_AGENT_VNIC}) ||
       ($self->{KERNEL_AGENT_VNIC} eq "")) {
      $vdLogger->Error("KERNEL_AGENT_VNIC is not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $devkit_dir = "$self->{ROOT_DIR}/$self->{SLOWPATH_SDK_NAME}";

   # for some reason, if VM is rebooted with dvfilterklib_vmxnet initially
   # loaded then the original vmxnet driver claims device but shows as
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
   if ($self->{KERNEL_AGENT_VNIC} !~ /eth/) {
      $vdLogger->Debug("vmxnet interface is showing other than eth: " .
                       "$self->{KERNEL_AGENT_VNIC}");
      $command = "ifconfig $self->{KERNEL_AGENT_VNIC}";
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command,
                                                  undef, undef, 1);
      if ($ret->{stdout} =~ /((?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2})/i) {
         $vmxnetMAC = $1;
         $vmxnetMAC =~ s/\s*//;
         $vmxnetMAC =~ s/\\n//;
         $vdLogger->Debug("The MAC address for vmxnet interface is: " .
                          "$vmxnetMAC");
         $restoreEthInterface = 1;
      }
   }

   my @commands = ("ifconfig $self->{KERNEL_AGENT_VNIC} down",
                  "rmmod vmxnet",
                  "insmod $devkit_dir/klib/dvfilterklib.ko; sleep 1;",
                  "insmod $devkit_dir/klib/vmxnet2/dvfilterklib_vmxnet.ko");
   foreach my $cmd (@commands) {
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $cmd,
                                                  undef, undef, 1);
      if ($ret eq FAILURE) {
         $vdLogger->Error("STAF command to $cmd failed");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   # Do we need to check with lsmod if the driver is loaded by the
   # above command or not?  No error returned by above command is
   # assumed that the driver is loaded successfully
   if ($restoreEthInterface) {
      $command = "ifconfig -a";
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command,
                                                  undef, undef, 1);
      if ($ret->{stdout} =~ /.*(eth\d+).*$vmxnetMAC/i) {
         $self->{KERNEL_AGENT_VNIC} = $1;
         $vdLogger->Debug("Updating KERNEL AGENT VNIC " .
                       "name to $self->{KERNEL_AGENT_VNIC}");
      } else {
         $vdLogger->Debug("Unable to Update KERNEL AGENT VNIC " .
                       "name: ");
         if (defined $ret->{stdout}) {
            $vdLogger->Debug("stdout: $ret->{stdout}");
         }
         if (defined $ret->{stdout}) {
            $vdLogger->Debug("stderr: $ret->{stderr}");
         }
      }
   }

   $command = "ifconfig $self->{KERNEL_AGENT_VNIC} up";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command, undef,
                                               undef, 1);
   if ($ret eq FAILURE) {
      $vdLogger->Error("STAF command to $command failed");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($self->SlowpathKernelDeviceExists() eq FAILURE) {
      $vdLogger->Error("Failed to update the driver of slowpath kernel vnic");
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
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command, undef,
                                               undef, 1);
   $vdLogger->Debug("Executing $command on $self->{vmIP}");
   if ($ret eq FAILURE) {
      $vdLogger->Error("STAF command to $command failed: " .
                       "stdout: $self->{stdout}\nstderr:$self->{stderr}");
      VDSetLastError("ESTAF");
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

   $command = "ls $self->{ROOT_DIR} | grep dvfilter-slowpath-SDK-";
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
           } elsif ($ret->{stdout} =~ m/vmxnet/gi) {
               $self->{KERNEL_AGENT_VNIC} = $dev;
               $vdLogger->Info("Found KERNEL_AGENT_VNIC vnic $dev in the VM $self->{vmIP}");
           } elsif ($ret->{stdout}=~ m/e1000/gi) {
               if ($dev ne $self->{MANAGE_VNIC}) {
                   $self->{SLOWPATH1_VNIC} = $dev;
                   $vdLogger->Info("Found SLOWPATH1_VNIC vnic $dev in the VM $self->{vmIP}");
               }
           }
       }
       $command = "ifconfig $dev up";
       $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
        if ($ret->{rc} != 0) {
            $vdLogger->Error("STAF command to $command failed");
            VDSetLastError("ESTAF");
            return FAILURE;
       }
   }
   if (!$self->{USERSPACE_AGENT_VNIC} || !$self->{KERNEL_AGENT_VNIC} ||
       !$self->{SLOWPATH1_VNIC} || !$self->{MANAGE_VNIC}) {
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
      if (defined($ip) && $ip !~ /192\.168/) {
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
         } elsif ($ret->{stdout} =~ m/vmxnet/gi) {
            $self->{KERNEL_AGENT_VNIC} = $dev;
            $vdLogger->Info("Found KERNEL_AGENT_VNIC vnic $dev in the VM $self->{vmIP}");
         } elsif ($ret->{stdout}=~ m/e1000/gi) {
            if ($dev ne $self->{MANAGE_VNIC}) {
               $self->{SLOWPATH1_VNIC} = $dev;
               $vdLogger->Info("Found SLOWPATH1_VNIC vnic $dev in the VM $self->{vmIP}");
            }
         }
      }
   }
   if (!$self->{USERSPACE_AGENT_VNIC} || !$self->{KERNEL_AGENT_VNIC} ||
       !$self->{SLOWPATH1_VNIC} || !$self->{MANAGE_VNIC}) {
      $vdLogger->Error("Can not find all needed vnic in the VM " .
                       "$self->{vmIP}" . Dumper($self));
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

   # The below check doesn't guarantee the slowpath binaries are built
   # in case compiling slowpath binaries failed in the previous run
   if ($self->NeedUpdateSlowpathBinaries() eq "FALSE") {
       $vdLogger->Info("SlowpathBinaries is latest and needn't update");
       return SUCCESS;
   }
   $vdLogger->Info("Try to upgrade VM tools in slowpath VM....");
   $ret = $self->UpgradeSlowpathVMTools();
   if ($ret eq FAILURE) {
       $vdLogger->Warn("Failed to upgrade vm tools, please install the latest vm tools manually");
   } else {
       $vdLogger->Info("Upgrade vm tools successfully");
   }

   if ($self->{hostObj}->TestEsxSetup() eq FAILURE) {
      $vdLogger->Error("Can not get VMTREE on the ESX build");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # mount all vmtree
   my @commands = ("rm -rf /build/storage60; mkdir -p /bldmnt/storage60",
                   "mount -t nfs build-storage60.eng.vmware.com:/storage60 " .
                   "/bldmnt/storage60",
                   "ln -s /bldmnt/storage60 /build/storage60");
   foreach my $cmd (@commands) {
      $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $cmd, undef,
                                                  undef, 1);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failure execution command on vm");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   my $vmtree = $self->{vmTree};
   @commands = ("rm -rf $self->{ROOT_DIR}; mkdir -p $self->{ROOT_DIR}",
                "cp $vmtree/build/scons/package/devel/linux32/" .
                lc($self->{hostObj}->{buildType}) .
                "/esx/apps/$self->{SLOWPATH_BIN_NAME}/$self->{SLOWPATH_BIN_NAME} " .
                "$self->{ROOT_DIR}",
                "chmod +x $self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME}");
   foreach my $cmd (@commands) {
      $ret =  $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $cmd, undef,
                                                   undef, 1);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failure execution command on vm");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #copy VMware-dvfilter-devkit-5.0.0-354028.zip to VMware-dvfilter-devkit.zip
   # prepare DVFilter slowpath binaries
   my $publishDir = $vmtree;
   $publishDir =~ s/bora$|bora\/$//;
   @commands = ("cp $publishDir" . "publish/VMware-dvfilter-devkit-* ".
                "$self->{ROOT_DIR}/$self->{DEVKIT_FILENAME}",
                "unzip $self->{ROOT_DIR}/$self->{DEVKIT_FILENAME} " .
                "-d $self->{ROOT_DIR}");
   foreach my $cmd (@commands) {
      $ret =  $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $cmd, undef,
                                                   undef, 1);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failure execution command on vm");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   # build the SDK name from build number
   $self->{SLOWPATH_SDK_NAME} = $self->GetSlowpathSDKName();
   if ($self->{SLOWPATH_SDK_NAME} eq FAILURE) {
       $vdLogger->Error("Failed to get SlowpathSDKName");
       VDSetLastError("ESTAF");
       return FAILURE;
   }
   $devkit_dir = "$self->{ROOT_DIR}/$self->{SLOWPATH_SDK_NAME}";
   $vdLogger->Info("Complile kernel library of DVFilter slowpath");
   @commands = ("cd $devkit_dir/klib; $devkit_dir/klib/build.sh",
                "cd $devkit_dir/klib/vmxnet2; $devkit_dir/klib/vmxnet2/build.sh");
   foreach my $cmd (@commands) {
      $ret =  $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $cmd, undef,
                                                   undef, 1);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failure execution command on vm");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   # update $self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME}
   $vdLogger->Info("Complile one new version of dvfilter-fw-slow");
   @commands = ("cd $devkit_dir; make;",
                "cp -f $devkit_dir/bin/dvfilter-fw-slow-debug* " .
                "$self->{ROOT_DIR}/$self->{SLOWPATH_BIN_NAME}");
   foreach my $cmd (@commands) {
      $ret =  $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $cmd,
                                                   undef, undef, 1);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failure execution command on vm");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# NeedUpdateSlowpathBinaries --
#      Based on the host builds, return true if slowpath binaries
#      update is required or FALSE if not required
#      TODO: The build number retrived using any workload load is not
#            stored in the testbed hash because whatever is stored
#            as part of workload is lost unless it is explicity saved
#            using event, it is more seamless if shared memory is used
#            Shared memory relieves the burden of generating event for
#            every piece of data.  Having said, that this particular piece of
#            information can be retrieved during the test bed creation
#            itself
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
   $ret->{stdout} =~ s/\s+$//;
   if ((defined $ret->{stdout}) &&
       ($ret->{stdout} =~ m/.*build-(\d+)/)) {
       $build_num = $1;
       $vdLogger->Info("Host build number is $build_num");
   } else {
       $vdLogger->Error("Can not get host build number");
       return "TRUE";
   }
   # TODO: use FS service from the staf helper
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
   return "TRUE";
}


########################################################################
#
# SetVNICIP --
#      Configure IP address of the vnic inside the VM
#      TODO: NetAdapter workload can be used here, however events has
#            to be used all over to save the state in the parent hash
#            Shared memory might make more sense to save the state
#            seamlessly as opposed to using events
#
# Input:
#      NIC - interface name
#      IP  - IP address to be configured on the interface
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub SetVNICIP
{
    my $self = shift;
    my %args = @_;
    my $nic = $args{NIC};
    my $ip = $args{IP};
    my $netmask = $args{NETMASK};

    my $command;
    my $ret;

    $command = "ifconfig $nic $ip netmask $netmask";
    $ret = $self->{stafHelper}->STAFSyncProcess($self->{vmIP}, $command);
    # if for some reason the above command fails, it will be reflected
    # in the rc code and therefore stdout and stderr nnedn't be verified
    if ($ret->{rc} != 0) {
            $vdLogger->Error("STAF command to $command failed");
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
    return SUCCESS;
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

   # Add one cdrom into slowpath vm for upgrade VMTools
   # TODO: Check if AddFilterToVMX workload can be used here
   push(@vmxlines, "ide0:0.present=TRUE");
   push(@vmxlines, "ide0:0.deviceType=atapi-cdrom");

   # handle SLOWPATH2_VMX_VNICS
   # TODO: AddFilterToVMX workload can be used here

   foreach $eth (@{$self->{SLOWPATH2_VMX_VNICS}}) {
      push(@vmxlines, "$eth.filter0.name=\"dvfilter-faulter\"");
      push(@vmxlines, "$eth.filter0.param0=\"$filter_type\"");
   }

   # changing the portgroup name of vmxnet, vmxnet3, and e1000 to SlowpathAPPG
   foreach $eth (@{$self->{SLOWPATH2_VMX_VNICS}}, @{$self->{SLOWPATH1_VMX_VNICS}}) {
      push(@vmxlines, "$eth.networkName =\"$self->{SLOWPATH_APP}\"");
   }

   $vdLogger->Info("Start to update the vmx file of the slowpath VM");

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
#      TODO: This function can be broken up into 4 different workloads
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
   # TODO: Creation of this vswitch can be done using existing vswitch portgroup
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
   # TODO: Creation of this portgroup can be done using existing vswitch
   #       portgroup
   $command = "esxcfg-vswitch $self->{SLOWPATH_VSS} -A $self->{SLOWPATH_APP}";
   $ret = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to create portgroup failed:" . Dumper($ret));
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
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   # command to create port group: $self->{SLOWPATH_VMK} on
   # vswitch: $self->{SLOWPATH_VSS}
   # Do we need to create a separate port group for connecting vmknic??
   # TODO: Creating and configuring vmknic inteface on a given portgroup can be
   #       done using NetAdapter workload
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
   #
   # Any changes made to network configuration on a esx host using esxcfg-*
   # command does not update/refresh the configuration end to end.
   # So, it is necessary to update the networking configuration manually.
   # For example, adding a portgroup using esxcfg-vswitch command does not
   # get reflected under available network names in any VM.
   #
   # TODO: I am assuming this part is done vmknic NetAdapter, if not
   #       HostRefresh workload is available and can be used
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
   # TODO: this can be either a separate workload within this API or can
   #       be moved to HostOperations
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

1;
