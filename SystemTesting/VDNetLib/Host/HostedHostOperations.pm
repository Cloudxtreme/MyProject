########################################################################
# Copyright (C) 2011 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Host::HostedHostOperations;
#
# This package allows to perform various operations on an WS and Fusion host
# and retrieve status related to these operations. An object of this
# class refers to one hosted host.
# HostOperations.pm creates this child obj in case of hosted environment.
#

# Inherit the parent class.
require Exporter;
use base qw(VDNetLib::Host::HostOperations);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;
use VDNetLib::Common::HostedUtils;

our $vmnetCfgCLI = "/automation/bin/x86_32/esx/vmnetCfgCLI";
our $vnetlib = undef; # defined in constructor portion of this class
our $libPath = undef;

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::Host::HostedHostOperations).
#      Child Class of parent HostOperations.pm
#
# Input:
#      TBD
#
# Results:
#      An object of VDNetLib::Host::HostedHostOperations package on
#      SUCCESS
#      FAILURE in case of error
#
# Side effects:
#      None
#
########################################################################

sub new {

   my $class = shift;
   my $hostIP = shift;
   my $stafObj = shift;

   my $self = {
      # IP address of ESX machine
      hostIP => $hostIP,
      # Obtain Staf handle of the process from VDNetLib::Common::STAFHelper module
      stafHelper => $stafObj,
      userid     => "root",
      password   => undef,
      os         => undef,
      arch       => undef,
      hostType   => undef,
      portgroups => undef,
      switches   => undef,
      vmtree     => undef,
      build      => undef,
      buildType  => undef,
      branch     => undef,
      vmklogEOF  => undef,
      vmkloglastEOF => undef,
   };
   bless($self);

   if (not defined $self->{hostIP}) {
      $vdLogger->Error("Host IP/name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

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

   #
   # Not sure if CheckAndInstallSTAF() will work for hosted environment
   # or not. But we can handle it in next release. Thus assuming perl
   # and staf are ready on host of hosted products.
   #
   if (FAILURE eq $self->CheckAndInstallSTAF()) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Determine the host OS
   $self->{os}  =  $self->{stafHelper}->GetOS($self->{hostIP});
   if (not defined $self->{os}) {
      $vdLogger->Error("Unknown os, not supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   #
   # Some of the esx utility functions are available in EsxUtils package,
   # creating an object of the same.
   #
   my $hostedUtilObj = VDNetLib::Common::HostedUtils->new($vdLogger,
                                                    $self->{stafHelper});
   if (not defined $hostedUtilObj) {
      $vdLogger->Error("Failed to create HostedUtils object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $self->{hostedutil} = $hostedUtilObj;
   #
   # Setting the environmet PATH variable in case of Windows
   #
   $libPath = $hostedUtilObj->GetLibPath($hostIP);
   if ($self->{os} =~ /darwin/i) {
      #For testing purpose currently!
      print "libpath is $libPath\n";
   } elsif ($self->{os} =~ /win/i){
      my $command = "setx PATH \"\%PATH\%;$libPath;\"";
      my $res = $self->{stafHelper}->STAFSyncProcess($hostIP,$command);
      if ($res->{rc} != 0 || $res->{stderr} ne ''){
	 $vdLogger->Error("Failed to set environment variable on $hostIP. ".Dumper($res));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $vnetlib = $libPath."vnetlib.exe";
   }
   #
   # Determine the build Information
   #
   ($self->{build},$self->{branch},$self->{buildType}) = $self->GetBuildInfo();

   if (not defined $self->{build} || not defined $self->{branch}
      || not defined $self->{buildType} ) {
      $vdLogger->Error("Unknown build information, not supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   return $self;
}


########################################################################
#
# GetvNicIP --
#     Method to get IP address of the given network adapter on the host.
#
# Input:
#     <mac> - mac address of the network adapter
#     <port> - vsi port (entire path) of the network adapter (optional)
#
# Results:
#     IP address, if success.
#     "FAILURE" in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetvNicIP
{
   my $self = shift;
   my $mac = shift;
   my $port = shift;
   if (not defined $mac) {
      $vdLogger->Error("MAC address not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # TODO; implement it
   return FAILURE;
}
#########################################################################
#
#  GetBuildInfo --
#      Gets Build Information
#
# Input:
#      None
#
# Results:
#      Returns "buildID, ESX Branch and buildType"
#      if there was no error executing the command
#      "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetBuildInfo
{
   my $self = shift;
   my ($cmd, $result);
   #
   # TODO: Build command according to OS i.e. for windows, linux, mac etc.
   # For windows we need to find the way (may be registry) as doing
   # vmware -v pops up a dialog box showing the build info.
   #
   if ($self->{os} =~ /win/i) {
	return ("Winbuild","WinBranch","WinBuildType");
   }
   $cmd = "vmware -v";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $cmd, 20);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $cmd failed:". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (defined $result->{stdout}){
      my ($test, $build) = split(/-/,$result->{stdout});
      chomp($build);
      $self->{build} = $build;

   # only first two digits of the version number is used, for example
   # for MN, it will be ESX50
      $self->{branch} = ($result->{stdout} =~ /.*(\d\.\d|e\.x\.p)..*/) ? $1 : undef;
      if (defined $self->{branch}) {
         $self->{branch} =~ s/\.//g;
         $self->{branch} = 'WS '."$self->{branch}";
      }
   } else {
      $vdLogger->Error("Unable to get branch info");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Debug("Hosted Branch = $self->{branch} Build = $self->{build}");
   $cmd = "vsish -e get /system/version";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $cmd);
   # Process the result
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   if ($result->{stdout} =~ /.*buildType\:(.*)\n.*/){
      my $buildType = $1;
      if ($buildType !~ /beta|obj|release|debug/i) {
         $vdLogger->Warn("Unknown build Type $buildType");
      }
      $vdLogger->Debug("BuildType = $buildType");
      $self->{buildType} = $buildType;
   } else {
      $vdLogger->Debug("Can't find buildType");
      return FAILURE;
   }
   return ($self->{build}, $self->{branch}, $self->{buildType});
}


sub UpdateVMNetHash
{
   my $self = shift;
   my $command;
   my $result;
   my $switch;

   $self->HostNetRefresh();

   $self->{portgroups} = ();
   $self->{switches} = ();

   # VMNet0 is the default vswitch in bridged mode.
   # We will use VMNet0 for control channel.
   # VMNet1 is default host-only at WS installation.
   # we will try and use from VMNet1 onwards till VMNet9 whatever
   # is available.
   #
   # temporary workaround for getting the switch information is reading some
   # last lines from vminst/vnetlib log file
   # TODO: for linux
   if ($self->{os} =~ /win/i){
     $command = "start /wait vnetlib -- status vnet all";
     $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
     if ($result->{rc} != 0){
        $vdLogger->Error("STAF command $command failed on $self->{hostIP}");
        vdSetLastError(VDGetLastError());
        return FAILURE;
     }
     $command = "tail -11 \%TEMP\%\/vminst.log";
     $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
     if ($result->{rc} != 0){
        $vdLogger->Error("STAF command $command failed on $self->{hostIP}");
        vdSetLastError(VDGetLastError());
        return FAILURE;
     }
     my @array = split("\n",$result->{stdout});
     pop(@array);
     foreach my $line (@array){
        $switch = undef;
        if ($line !~ /<failed>/i){
           my @temp = split(" ", $line);
           if ($temp[7] =~ /vmnet\d/i){
              $switch = $temp[7];
           }
        }
        if (defined $switch){
           $self->{switches}{$switch}{numports}       = undef;
           $self->{switches}{$switch}{usedports}      = undef;
           $self->{switches}{$switch}{configuredport} = undef;
           $self->{switches}{$switch}{mtu}            = 1500;
           $self->{switches}{$switch}{name}           = $switch;
           $self->{switches}{$switch}{uplink}         = undef;
           $self->{switches}{$switch}{type}           = "vmnet";
        }
     }
   } else {
      $switch = "vmnet2";
         $self->{switches}{$switch}{numports}       = undef;
         $self->{switches}{$switch}{usedports}      = undef;
         $self->{switches}{$switch}{configuredport} = undef;
         $self->{switches}{$switch}{mtu}            = 1500;
         $self->{switches}{$switch}{name}           = $switch;
         $self->{switches}{$switch}{uplink}         = undef;
         $self->{switches}{$switch}{type}           = "vmnet";
   }
   return SUCCESS;
}

sub HostNetRefresh
{
   my $self = shift;

   my $command = "vmware-networks --stop; vmware-networks --start";

   $vdLogger->Debug("Refreshing network configuration on $self->{hostIP}");
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $command failed:" .
                      Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug($result->{stdout});
   return SUCCESS;
}

sub VDNetESXSetup
{
   # TODO: Implement this method for hosted similar to that of
   # AddvSwitchUplink in other vswitch modules.
   return SUCCESS;

}


################################################################################
#
# CreatevSwitch
#       Create a vmnet switch in VNE using command
#        vmnetlibCfgCLI addadapter vmnet2
#        vnetlib.exe add adapter vmnet2
# Input:
#    $vSwitch : Name of the vSwitch it should be vmnet\d
#
# Output:
#    SUCCESS:
#    FAILURE: in case of any error
#
# Side effect:
#        None
#
################################################################################

sub CreatevSwitch
{
   # TODO: For ESX we can create any vswitch with any name but for hosted
   # we need to cycle throught every vmnet switch and see which one
   # is available.
   my $self          = shift;
   my $vswitch       = shift;# mandatory
   if (not defined $vswitch || $vswitch !~ /vmnet(\d)/i) {
      $vdLogger->Error("vswitch name is not provided or in incorrect format.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Find the updated information about vswitches on the given host
   $self->UpdateVMNetHash();

   # If the switch by the given name '$vswitch' exists return SUCCESS.
   if (exists $self->{switches}{$vswitch}) {
      $vdLogger->Debug("vswitch $vswitch already exists");
      return SUCCESS;
   }

   # command to create a vswitch
   my $command;
   if ($self->{os} =~ /win/i){
      $command = "start /wait vnetlib -- add adapter $vswitch";
   } else {
      $command = "$vmnetCfgCLI addadapter $vswitch";
   }

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0 || $result->{stdout} =~ /error/i) {
      $vdLogger->Error("STAF command to create vswitch failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # Check the updated vswitch information on the host and verify if the
   # new vswitch exists in that list
   #
   $self->UpdateVMNetHash();
   if (not exists $self->{switches}{lc($vswitch)}) {
      $vdLogger->Error("Create $vswitch failed:");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $vdLogger->Debug("Successfully created the vswitch $vswitch");
      return SUCCESS;
   }
}

sub DeletevSwitch
{
   my $self = shift;
   my $vswitch = shift;# mandatory

   if (not defined $vswitch) {
      $vdLogger->Error("vswitch name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Find the updated information about vswitches on the given host
   $self->UpdateVMNetHash();

   #
   # If the given vswitch does not exist, then there is nothing to delete.
   # So returning SUCCESS here.
   #
   if (not exists $self->{switches}{lc($vswitch)}) {
      $vdLogger->Debug("vSwitch $vswitch does not exist");
      return SUCCESS; # why instead of failure? because it causes tests to fail
                      # when both sut and helpers are same and same switches
                      # are created.
                      #
   }

   # before delete we need to stop all the services of vswitch
   if ($self->StopVMNetService("dhcp",$vswitch) eq FAILURE) {
      return FAILURE;
   }
   if ($self->StopVMNetService("bridge",$vswitch) eq FAILURE) {
      return FAILURE;
   }
   if ($self->StopVMNetService("nat",$vswitch) eq FAILURE) {
      return FAILURE;
   }
   if ($self->StopVMNetService("netifup",$vswitch) eq FAILURE) {
      return FAILURE;
   }
   if ($self->StopVMNetService("netdetect",$vswitch) eq FAILURE) {
      return FAILURE;
   }
   # command to delete a vswitch on WS
   my $command;
   if ($self->{os} =~ /win/i){
      $command = "start /wait vnetlib -- remove adapter $vswitch";
   } else {
      $command = "$vmnetCfgCLI deletevnet $vswitch";
   }
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0 || $result->{stdout} =~ /error/i) {
      $vdLogger->Error("STAF command to delete vswitch failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # Update the vswitch list on the given host and verify that the given
   # vswitch is not present in the list.
   #
   $self->UpdateVMNetHash();
   if (exists $self->{switches}{lc($vswitch)}) {
      $vdLogger->Error("Delete $vswitch failed:" . Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $vdLogger->Debug("Successfully deleted the vswitch $vswitch");
      return SUCCESS;
   }
}

sub CreatePortGroup
{
   return SUCCESS;
}


########################################################################
#
# Reboot --
#      Reboot esx host
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

sub Reboot
{
   my $self = shift;
   my $command;
   my $retry = 50;

   #TODO: Change the command based on the host OS type.
   $command  = "reboot" if $self->{os} =~ /lin/i;
   $command  = "shutdown /r now" if $self->{os} =~ /win/i;

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command reboot host failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #Waitting for ESX host rebooting.
   sleep(180);
   my $counter=1;
   while (1) {
      my $result= $self->{stafHelper}->CheckSTAF($self->{hostIP});
      if ( $result eq 0 ) {
         $vdLogger->Info("The host staf running.");
         last;
      }
      $vdLogger->Info("Host reboot,waitting for staf running.");
      sleep(10);
      $counter++;
      if ($counter > $retry) {
         $vdLogger->Error("The host staf is not running.");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   #check if perl and other vdnet related mount points are installed
   if ("FAILURE" eq $self->VDNetESXSetup($self->{vdNetSrc},
                                         $self->{vdNetShare})) {
      $vdLogger->Error("VDNet Setup failed on host:$self->{hostIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Info("The host reboot successfully.");
   $vdLogger->Debug(Dumper($result));
   return SUCCESS;

}

########################################################################
#
# Hibernate --
#      Hibernate Mac host
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

sub Hibernate
{
   my $self = shift;
   my $command;
   my $sleeptime = shift;

   $command  = "pmset sleepnow" if $self->{os} =~ /darwin/i;
   #TODO:find the command for Windonws and Linux
   $command  = "" if $self->{os} =~ /linux/i;
   $command  = "" if $self->{os} =~ /windows/i;

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command hibernate host failed:" .
                    Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   sleep (10);

   #Accept the sleeping time for testing purpose  .
   #sleep($sleeptime);

   $vdLogger->Info("The host hibernate successfully.");
   $vdLogger->Debug(Dumper($result));
}

########################################################################
#
# HogHostCPU --
#      Hog Host CPU by launching process "yes>/dev/null",
#      the number of this process depends on the number of Host CPU.
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

sub HogHostCPU
{
   my $self = shift;
   my $command;
   my $cpunum;
   #TODO: Change the command based on the host OS type.
   #for linux:cat /proc/cpuinfo | grep processor | wc -l
   #for Mac:system_profiler SPHardwareDataType

   my $getcpucmd = "system_profiler SPHardwareDataType|grep Cores" if $self->{os} =~ /darwin/i;
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$getcpucmd,);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $getcpucmd failed:". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $data = $result->{stdout};
   if (not defined $data) {
      $vdLogger->Error("Fail to get the core number of Host!");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($data =~ /.*:\s+(\d+)/) {
      $cpunum = $1;
   }
   $vdLogger->Debug("CPU number is: $cpunum");

   #TODO: Change the command based on the host OS type.
   my $hogcpucmd = "yes>/dev/null" if $self->{os} =~ /darwin/i;
   my $counter = 1;
   my $loopnum = $cpunum*2;
   while ($counter <= $loopnum) {
      $result = $self->{stafHelper}->STAFAsyncProcess($self->{hostIP},$hogcpucmd,'./OUT');
      if (!$result->{rc}) {
         $vdLogger->Info("Hogging the host CPU...");
      }
      if ($result->{rc} != 0) {
         $vdLogger->Error("Fail to run the command:$hogcpucmd" .
                       Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $counter++;
   }

   $vdLogger->Debug(Dumper($result));
   sleep (20);
   return SUCCESS;
}

########################################################################
#
# StopHogCPUProcess --
#      Stop Hog Host CPU Process
#
# Input:
#      Stop the Hog CPU processes with command killall
#
# Results:
#      Returns "SUCCESS", if reboot successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub StopHogCPUProcess
{
   my $self = shift;
   my $command;

   #TODO: Change the command based on the host OS type.
   #for linux:killall yes
   #for Mac : killall yes

   $command = "killall yes" if $self->{os} =~ /darwin/i;
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$command,);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $command failed:". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
}

sub StartVMNetService
{
   my $self = shift;
   my $service = shift;
   my $vmnet = shift;

   if (not defined $service || not defined $vmnet) {
      $vdLogger->Error("Service/vnet name is not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $cmd;
   $cmd = "$vmnetCfgCLI servicestart $service" if ($self->{os} !~ /win/i);
   $cmd = "start /wait vnetlib -- start $service" if ($self->{os} =~ /win/i);
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if (($result->{rc} != 0) ||($result->{stdout} =~ /error/i)) {
      $vdLogger->Error("STAF command to start service $service on vnet $vmnet".
                        "failed: ".Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}

sub StopVMNetService
{
   my $self = shift;
   my $service = shift;
   my $vmnet = shift;

   if (not defined $service || not defined $vmnet) {
      $vdLogger->Error("Service/vnet name is not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $cmd;
   $cmd = "$vmnetCfgCLI servicestop $vmnet $service" if ($self->{os} !~ /win/i);
   $cmd = "start /wait vnetlib -- stop $vmnet $service"
						if ($self->{os} =~ /win/i);
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if (($result->{rc} != 0) ||($result->{stdout} =~ /error/i)) {
      $vdLogger->Error("STAF command to stop service $service on vnet $vmnet".
                        "failed: ".Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}

sub GetVMNetServiceStatus
{
   my $self = shift;
   my $service = shift;
   my $vmnet = shift;

   if (not defined $service || not defined $vmnet) {
      $vdLogger->Error("Service/vnet name is not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $cmd = "$vmnetCfgCLI servicestatus $service";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if (($result->{rc} != 0) ||($result->{stdout} =~ /error/i)) {
      $vdLogger->Error("STAF command to get status of service $service on vnet ".
                        "$vmnet failed: ".Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} =~ / not-running /i) {
      return "Stopped";
   } elsif ($result->{stdout} =~ / running /i) {
      return "Running";
   } else {
      return "Undefined";
   }
}

sub BackupHostNetwork
{
   my $self = shift;
   my $backupFile = shift;

   if (not defined $backupFile) {
      $vdLogger->Error("Backup File name is not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $cmd = "$vmnetCfgCLI exportconfig $backupFile";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if (($result->{rc} != 0) ||
                ($result->{stdout} !~ /Export network config data to/i)) {
      $vdLogger->Error("STAF command to create hosted network backup failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}

sub RestoreHostNetwork
{
   my $self = shift;
   my $backupFile = shift;

   if (not defined $backupFile) {
      $vdLogger->Error("Backup File name is not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $cmd = "$vmnetCfgCLI importconfig $backupFile";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if (($result->{rc} != 0) ||
                ($result->{stdout} !~ /import network config data to/i)) {
      $vdLogger->Error("STAF command to create hosted network backup failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}

1;
