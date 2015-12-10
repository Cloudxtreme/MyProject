##########################################################
# Copyright 2010 VMware, Inc.  All rights reserved.
# VMware Confidential
##########################################################

########################################################################
#
# HostedUtils.pm--
#     This package provides subroutines to configure an esx host and
#     query information from it.
#
########################################################################

package VDNetLib::Common::HostedUtils;

use strict;
use warnings;

use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError VDCleanErrorStack
                                   SUCCESS FAILURE );
use Time::Local;

use constant PASS => 0;
use constant DEFAULT_TIMEOUT => 180;
use constant VMFS_BLOCK_SIZE => 1048576;


########################################################################
#
# new --
#      This is method to create an instance/object of
#      VDNetLib::Common::HostedUtils class
#
# Input:
#   'vdLogObj'      - An object of VDLog class. If not specified
#                     an object is created implicitly.
#   'stafHelperObj' - An object of STAFHelper class. If not specified
#                     an object is created implicitly.
#
# Results:
#      A VDNetLib::Common::HostedUtils object is returned
#
# Side effects:
#     None.
#
########################################################################

sub new
{
   my $class = shift;
   my $vdLogObj = shift;
   my $stafHelperObj = shift;
   my $self;

   $self = {
      vdLogObj      => undef,
      stafHelper => undef,
   };

   bless ($self, $class);

   if (defined $vdLogObj) {
      $self->{vdLogObj} = $vdLogObj;
   } else {
      $self->{vdLogObj} = VDNetLib::Common::VDLog->new();
   }

   if (defined $stafHelperObj) {
      $self->{stafHelper} = $stafHelperObj;
   } else {
      my $stafHelperOpts;
      $stafHelperOpts->{logObj} = $self->{vdLogObj};
      $self->{stafHelper} = VDNetLib::Common::STAFHelper->new($stafHelperOpts);
      if (not defined $self->{stafHelper}) {
         $self->{vdLogObj}->Error("Unable to create implicit " .
                                  "STAFHelper object");
         return undef;
      }
   }

   bless ($self, $class);
   return $self;
}

sub MountDatastore
{

return SUCCESS;

}

################################################################################
#  GetLibPath
#      Returns the path where the vmrun binary is stored
#
#  Algorithm:
#      using the search command in windows
#
#  Input:
#      HostIP : IP address of host
#
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       none
#
################################################################################

sub GetLibPath
{
    my $self = shift;
    my $hostIP = shift;

    my $hostType = $self->{stafHelper}->GetOS($hostIP);
    my $command;
    my $result;

    if ($hostType =~ /darwin/i) {
       $command = "sudo find / -name vmrun |grep vmrun";
       $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
       $vdLogger->Info("Executing the command $command");
       if ($result->{rc} != 0 || $result->{stderr} ne ''){
          $vdLogger->Error("Failure to execute $command on $hostIP");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
       my @outputfiles = split("\n", $result->{stdout});
       foreach my $file (@outputfiles) {
          chomp($file);
          if ($file =~ /vmrun/i) {
             $file =~ s/\s/\ /g;
             return $file;
          }
       }
     } elsif ($hostType =~ /win/i) {
       $command = "cd c:\\ & dir /s /b vmware.exe";
       $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
       if ($result->{rc} != 0 || $result->{stderr} ne ''){
          $vdLogger->Error("Failure to execute $command on $hostIP");
          VDSetLastError("EFAIL");
          return FAILURE;
       }
       my @outputfiles = split("\n", $result->{stdout});
       foreach my $file (@outputfiles) {
          chomp($file);
          if ($file =~ /vmware\.exe/i) {
             $file =~ s/vmware\.exe.*\r//g;
             return $file;
          }
       }
    } else {
       return "/usr/bin";
    }
}


################################################################################
#  WinHostedFileCheck
#      Check the required files are present on Windows after installing WS
#
#  Algorithm:
#      using the search command in windows
#
#  Input:
#      hostIP : IP address of host
#
#
#  Output:
#       SUCCESS if pass along with MAC address of vNIC hot added
#       FAILURE if fail
#
#  Side effects:
#       none
#
################################################################################

sub WinHostedFileCheck
{
   my $self = shift;
   my $hostIP = shift;

   my $hostType = $self->{stafHelper}->GetOS($hostIP);
   if ($hostType !~ /win/i) {
      $vdLogger->Error("Host is not Windows specific.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $command = "dir \%SYSTEMROOT\%\\system32\\drivers|findstr /I \"vmnet\"";
   my $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if ($result->{rc} != 0 || $result->{stderr} ne ''){
      $vdLogger->Error("Failure to execute $command on $hostIP");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $drivers = $result->{stdout};
   $command = "dir \%SYSTEMROOT\%\\system32|findstr /I \"v\.\*net\"";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if ($result->{rc} != 0 || $result->{stderr} ne ''){
      $vdLogger->Error("Failure to execute $command on $hostIP");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $system32 = $result->{stdout};
   $command = "dir \%SYSTEMROOT\%\\inf|findstr /I \"oem\"";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if ($result->{rc} != 0 || $result->{stderr} ne ''){
      $vdLogger->Error("Failure to execute $command on $hostIP");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $inf = $result->{stdout};
   my $driversflag = 0;
   my $system32flag = 0;
   my $infflag = 0;
   #
   # Verify that required files are present and modify flag value
   # For each file present we set one bit
   #
   foreach my $var (split("\n", $drivers)){
      if ($var =~ /vmnet\.sys/i){
	 $driversflag |= 0x1;
      } elsif ($var =~ /vmnetbridge\.sys/i){
	 $driversflag |= 0x2;
      } elsif ($var =~ /vmnetadapter\.sys/i){
	 $driversflag |= 0x4;
      } elsif ($var =~ /vmnetuserif\.sys/i){
	 $driversflag |= 0x8;
      }
   }
   foreach my $var (split("\n", $system32)){
      if ($var =~ /vmnetbridge\.dll/i){
	 $system32flag |= 0x1;
      } elsif ($var =~ /vnetlib\.dll|vnetlib64\.dll/i){
         $system32flag |= 0x2;
      } elsif ($var =~ /vnetinst\.dll/i){
         $system32flag |= 0x4;
      }
   }
   foreach my $var (split("\n", $inf)){
      if ($var =~ /oem\d\d\./i){
	 $infflag++;
      }
   }

   if ($driversflag == 0xF && $system32flag == 0x7 && ($infflag/2)%2 == 0) {
      return SUCCESS;
   }
   return FAILURE;
}

1;
