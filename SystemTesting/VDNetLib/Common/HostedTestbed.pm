##############################################################################
# Copyright (C) 2011 VMWare, Inc.
# All Rights Reserved
##############################################################################
package VDNetLib::Common::HostedTestbed;

#
#  Testbed class creates child obj hostedtestbed for Hosted environment. The
#  obj structure and elements are same as that of parent Testbed.pm
#

# Inherit the parent class.
require Exporter;
use base qw(VDNetLib::Common::Testbed);

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use Data::Dumper;
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   ABORT VDCleanErrorStack );
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_DEFAULT_PORT);
use Carp;

use VDNetLib::Host::HostedHostOperations;
use constant VMFS_BASE_PATH => "/vmfs/volumes/";

########################################################################
#
# new --
#       Constructor for HostedTestbed object
#
# Input:
#       TBD
#
# Results:
#       SUCCESS if no errors encoutered else FAILURE
#       Builds hostedtestbed hash that has sut and helper machine details
#
# Side effects:
#       none
#
########################################################################

sub new
{

   my ($class) = shift;
   my $self = {};
   bless $self, $class;
   return $self;

}


########################################################################
#
# InitializeHost --
#      Overridding method for hosted environment.
#      Method to initialize physical host required for a session.
#      This method creates VDNetLib::Host::WSFusionHostOperations object
#      and stores it in testbed hash. Then, all initialization required
#      on the given host is handled in this method.
#
# Input:
#      machine: SUT or helper<x>, where x is an integer (Required)
#
# Results:
#      "SUCCESS", if the required physical hosts are initialized
#                 successfully;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub InitializeHost
{
   # TODO: Delete the VMNets current not in use and those created by product
   # after installation.

   # TODO: Call CheckSetup() on host

   my $self = shift;
   my $machine = shift;
   my $session = $self->{session};
   my $disableARP = $session->{"disableARP"};

   my $hostIP = $self->{testbed}{$machine}{host};
   my $hostObj = $self->{testbed}{$machine}{hostObj};
   if (not defined $hostObj) {
      # Updating HostOperations object for SUT/helper<x> in testbed
      $hostObj = VDNetLib::Host::HostedHostOperations->new($hostIP,
                                                     $self->{stafHelper});
      if($hostObj eq FAILURE) {
         $vdLogger->Error("Failed to create " .
                          "VDNetLib::Host::HostedHostOperations object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{testbed}{$machine}{hostObj} = $hostObj;
   }

   # Store all portgroup and switch information here
   $hostObj->UpdateVMNetHash();

   #
   # vdNet framework requires "vdtest" portgroup to be available on esx
   # but for hosted there is no concept of portgroup
   #

   # Setup host for vdNet
   # TODO: Call WinVMSetup in case of windows host and call
   # DisableLinuxFirewall() in case of linux host.
   if (($hostObj->{os} =~ /(win)/i) &&
       (!$session->{'skipSetup'})) {
      # Check by getting the setup.log if setup is already performed
      # on this machine. If yes, no need to call setup.
      my $ret = $self->WinVDNetSetup($machine, $hostIP, $hostObj->{os});
      if ($ret eq FAILURE ) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } elsif ($ret =~ /rebootrequired/) {
         $vdLogger->Info("Restarting the host:$hostObj->{hostIP} ".
                         "for VDNET-Setup to take effect");
         if ($hostObj->Reboot() eq FAILURE ) {
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
         my $ip = $self->{testbed}{$machine}{ip};
         my $command = "COPY FILE $srcFile TODIRECTORY C:\\vmqa ".
                       "TOMACHINE $ip\@$STAF_DEFAULT_PORT";
         $self->{stafHelper}->runStafCmd('local', "FS", $command);

         #TODO: Find the IP of the host using GetGuestControlIP.
         # First find the controlMAC of host to find the IP.
      }
   }

   if(!$session->{'skipSetup'}) {
      $vdLogger->Info("Configure host $hostIP for vdnet");
      if ("FAILURE" eq  $hostObj->VDNetESXSetup($session->{'vdNetSrc'},
                                                $session->{'vdNetShare'})) {
         $vdLogger->Error("VDNetSetup failed on host:$hostIP");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      #
      # TODO: Mount appropriate sharedStorage on the hosted platform
      #
      my $sharedStorage = $self->{session}{sharedStorage};

      #
      # If the given value for sharedstorage has :, assume the value is
      # in the format server:/share. Then, mount the server on the host
      # and point the given share to /vmfs/volumes/vdnetSharedStorage.
      #
      my ($sharedStorageServer, $sharedStorageShare) =
         split(/:/,$sharedStorage);
      my $esxUtil = $self->{testbed}{$machine}{hostObj}{hostedutil};

      $vdLogger->Info("Mount " . $sharedStorageServer .
                      " on $sharedStorageShare");
      $self->{testbed}{$machine}{sharedStorage} = $sharedStorage;
   }

   return SUCCESS;
}

sub InitializeVMKNic
{

   my $self = shift;
   my $machine = shift;

   #
   # we call hosted host's adapter as vmknics. Thus we create
   # netadapter objs for them
   #
   if ($self->InitializeAdapters($machine, "vmknic") eq FAILURE) {
      $vdLogger->Error("Failed to initialize virtual adapters inside " .
                 "the guests");
      $self->{logCollector}->CollectLog("NetAdapter");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # TODO: Need to add alias variables as other modules expected a vmknic to have
   # deviceId var, thus we will add those alias variables here.


   return SUCCESS;

}


########################################################################
#
# GetVMX --
#      Returns VMX file as, [Storage] WinXP/WinXP.vmx, given the machine
#      in the testbed.
#     1. Get the MAC address corresponding to the IP address of the
#        machine.
#     3. Grep the MAC found in step1 in each of the vmxFile
#     4. If the MAC is found return the VMX
#     5. If it is not found in any of the VMX files, return
#        undef
#
# Input:
#      Machine name in the testbed
#
# Results:
#      VMX file name relative to its DataStore as mentioned above
#
# Side effects:
#      None
#
########################################################################

sub GetVMX
{
   my $self = shift;
   my $machine = shift;

   my $vmxFile;
   my $mac;
   my $command;

   if ((not defined $self->{testbed}{$machine}{ip}) &&
       (not defined  $self->{testbed}{$machine}{host})) {
      $vdLogger->Error("Required machine details missing ip, host " .
                       "not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # Get MAC address corresponding to the VM IP address
   # The below mechanism to get IP assume STAF working on the VM
   #
   $mac = VDNetLib::Common::Utilities::GetMACFromIP(
                                            $self->{testbed}{$machine}{ip},
                                            $self->{stafHelper});
   $vdLogger->Debug("GetVMX: MAC address returned by GetMACFromIP, $mac");
   if ((not defined $mac) || ($mac eq FAILURE)) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # replace '-' with ':' as it appears in the vmx file
   $mac =~ s/-/:/g;

   if ($self->{testbed}{$machine}{hostType} =~ /(linux|mac)/i) {
      $command = "ps -eaf | grep -ri vmx";
   } elsif ($self->{testbed}{$machine}{hostType} =~ /^win/i) {
      $command = "tasklist | findstr -ri vmx";
   }
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{testbed}{$machine}{host},
                                                        $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $command failed:". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $data = $result->{stdout};

   if ((not defined $data) ) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # sample output of "ps -eaf | grep -ri vmx"
   # root      5621     1  0 15:44 ?        00:00:13 /usr/lib/vmware/bin/vmware-vmx-debug -s
   # vmx.stdio.keep=TRUE -# product=1;name=VMware Workstation;version=8.0.2;buildnumber=576076;
   # licensename=VMware Workstation;licenseversion=8.0+; -@
   # pipe=/tmp/vmware-root/vmxe8835f98b9307393;readyEvent=40
   # /disk2/ovfs/rhel-53-srv-ovf-imported/rhel-53-srv-hw7-32-lsi-1gb-1cpu.vmx
   #
   # sample output of "tasklist | findstr -ri vmx";

   my @psDump = split(/\n/,$data);
   if (scalar(@psDump) > 1) {
      foreach my $vmline (@psDump) {
         $vmline =~ s/\s+/ /g;
         $vmline =~ s/\t|\n|\r//g;

         if ( $vmline =~ /(.*) (.*\.vmx)/ )  {
            $vmxFile = $2;
            $vdLogger->Debug("vmxFile: $vmxFile");
            if (defined $vmxFile) {
               # if MAC address is found then we found vmx, else look
               # into the next vmx file.
               my $eth = VDNetLib::Common::Utilities::GetEthUnitNum(
                         $self->{testbed}{$machine}{host},
                         $vmxFile,
                         $mac);
               if ($eth eq FAILURE) {
                  # ignore the error as it is possible not to find the mac
                  # address in this vmxFile
                  VDCleanErrorStack();
                  next;
               } elsif  ($eth =~ /^ethernet/i) {
                  return $vmxFile;
               }
            }
         }
      }
   }

   VDSetLastError("ENOTDEF");
   return FAILURE;

}


#########################################################################
#
#  GetBuildInformation --
#      Gets Build Information
#
# Input:
#      Host Name or IP and Machine (SUT or HelperX)
#
# Results:
#      Returns "SUCCESS" and store "buildID, ESX Branch and buildType"
#      in testbed hash
#      "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetBuildInformation
{
   return SUCCESS;
}


########################################################################
#
# CleanupVMKNics --
#      This method cleans vmknics created in a test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if the vmknics are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVMKNics
{
   # TODO: See if there is any cleanup required for vmknics(i.e. host
   # adapters) in hosted environment.
   return SUCCESS;
}


########################################################################
#
# CleanupVirtualSwitches --
#      This method cleans virtual switches used in a test case.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if virtual switches are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CleanupVirtualSwitches
{
   # Implement this method to delete the vmnet switch OR call the
   # delete vmnet switch method from here.
   return SUCCESS;
}


########################################################################
#
# GeneratevSwitchName --
#      On ESX we can generate any vswitch name but on Hosted we have
#      to pick from vmnet0 to vmnet9. (linux supports 256 vmnets but
#      windows supports only 10 vmnets)
#      vmnet0 - is analogous to "VM Network" portgroup on esx
#      vmnet1 - is analogous to "vdtest" portgroup on esx.
#      Thus our picking will start from vmnet2 to vmnet9.
#      we also assume that all the default vmnetX which are installed
#      along with product installation are removed. host-Only vmnet
#      and NAT vmnet.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if virtual switches are cleaned successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GeneratevSwitchName
{
   my $self = shift;
   my $switchType = shift;

   #
   # For hosted VMNet0 will always be the control path.
   # Thus VMNet0 is the equivalent of 'VM Network' pg on hosted.
   # On esx we generate a vswitch on the fly but for hosted we need
   # to discover which vSwitch (vmnetX) is free and use that as our
   # vswitch for the entire test session.

   #TODO: Hard coding for now.
   return "vmnet2";
}
1;
