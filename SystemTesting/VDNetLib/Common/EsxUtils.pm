##########################################################
# Copyright 2010 VMware, Inc.  All rights reserved.
# VMware Confidential
##########################################################

########################################################################
#
# EsxUtils.pm--
#     This package provides subroutines to configure an esx host and
#     query information from it.
#
########################################################################

package VDNetLib::Common::EsxUtils;

use strict;
use warnings;

use Data::Dumper;

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDLog;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sessionSTAFPort);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError VDCleanErrorStack
                                   SUCCESS FAILURE );

use constant PASS => 0;
use constant DEFAULT_TIMEOUT => 180;
use constant VMFS_BLOCK_SIZE => 1048576;


########################################################################
#
# new --
#      This is method to create an instance/object of
#      VDNetLib::Common::EsxUtils class
#
# Input:
#   'vdLogObj'      - An object of VDLog class. If not specified
#                     an object is created implicitly.
#   'stafHelperObj' - An object of STAFHelper class. If not specified
#                     an object is created implicitly.
#
# Results:
#      A VDNetLib::Common::EsxUtils object is returned
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
      stafHelperObj => undef,
   };

   bless ($self, $class);

   if (defined $vdLogObj) {
      $self->{vdLogObj} = $vdLogObj;
   } else {
      $self->{vdLogObj} = VDNetLib::Common::VDLog->new();
   }

   if (defined $stafHelperObj) {
      $self->{stafHelperObj} = $stafHelperObj;
   } else {
      my $stafHelperOpts;
      $stafHelperOpts->{logObj} = $self->{vdLogObj};
      $self->{stafHelperObj} = VDNetLib::Common::STAFHelper->new($stafHelperOpts);
      if (not defined $self->{stafHelperObj}) {
         $self->{vdLogObj}->Error("Unable to create implicit " .
                                  "STAFHelper object");
         return undef;
      }
   }

   bless ($self, $class);
   return $self;
}


########################################################################
#
# ListVMFSPartitions --
#     Gets the list of all VMFS paritions on the specified ESX host.
#
# Input:
#       <host> - IP address/name of the esx host
#
# Results:
#       An array of datastores on the esx host;
#       undef, in case of any error
#
# Side effects:
#       None
#
# Example:
#     @vmfsPartitions =
#           $esxUtilsObj->ListVMFSParitions("myesx.eng.vmware.com");
#
########################################################################

sub ListVMFSPartitions
{
   my $self = shift;
   my $host = shift;

   if (not defined $host) {
      $self->{vdLogObj}->Error("Insufficient parameters");
      VDSetLastError("EINVAID");
      return undef;
   }

   ##
   ## Using STAF FS service to list datastores on esx. On esx, the datastores
   ## are always under the directory /vmfs/volumes
   ##
   my $dirEntries = $self->{stafHelperObj}->STAFFSListDirectory($host,
                                                                "/vmfs/volumes",
                                                                "LONG DETAILS");

   if (not defined $dirEntries) {
      $self->{vdLogObj}->Error("Unable to get directory listing for " .
                               "/vmfs/volumes on $host");
      return undef;
   }

   my @vmfsPartitions = ();
   foreach my $dirEntry (@$dirEntries) {
      if (defined $dirEntry->{linkTarget}) {
         push @vmfsPartitions, $dirEntry->{name};
      }
   }
   return @vmfsPartitions;
}


########################################################################
#
# GetVMFSSpaceAvail --
#     Gets the available size of the given partition on esx host.
#
# Input:
#       <host> - IP address/name of the esx host
#       <vmfsVol> - name of the vmfs volume whose available size has
#                   to be determined
#
# Results:
#       Size of the vmfs volume
#       0 if the partition is an nfs or read-only partition
#       undef in case of any error
#
# Side effects:
#       None
#
# Example:
#     $availSpace =
#           $esxUtilsObj->GetVMFSSpaceAvail("myesx.eng.vmware.com",
#                                           "/vmfs/volumes/storage1");
#
########################################################################

sub GetVMFSSpaceAvail
{
   my $self =  shift;
   my $host = shift;
   my $vmfsVol = shift;

   if ((not defined $host) || (not defined $vmfsVol)) {
      $self->{vdLogObj}->Error("Insufficient parameters");
      VDSetLastError("EINVAID");
      return undef;
   }

   my $cmd = "vmkfstools -P '/vmfs/volumes/$vmfsVol'";
   my $stafResult = $self->{stafHelperObj}->STAFSyncProcess($host,
                                                            $cmd,
                                                            DEFAULT_TIMEOUT);

   if (PASS != $stafResult->{rc}) {
      $self->{vdLogObj}->Error("Failed to $cmd on $host");
      VDSetLastError("ESTAF");
      return undef;
   }

   if (PASS != $stafResult->{exitCode}) {
      $self->{vdLogObj}->Error("$cmd failed on $host, Error: " .
                               $stafResult->{stderr});
      VDSetLastError("EOPFAILED");
      return undef;
   }

   ##
   ## Regex to get the version X from the string
   ## "NFS-X.yy file system spanning Z partitions"
   ##
   if ($stafResult->{stdout} =~ /NFS-([\d.]+) file system/mg) {
      ## Ignore NFS partitions by returning size as 0
      return 0;
   }

   ##
   ## Regex to get the version X from the string
   ## "VMFS-X.yy file system spanning Z partitions"
   ##
   my ($vmfsversion) = $stafResult->{stdout} =~ /VMFS-([\d\.]+) file system/mg;
   if ($vmfsversion && $vmfsversion < 3) {
      $self->{vdLogObj}->Error("VMFS Version is $vmfsversion. This file system " .
                               "is readonly");
      return 0;
   }

   ##
   ## Regex to read the numbers X,Y from the string
   ## "Capacity <size1> (<num1> file blocks * <num2>), X (Y blocks) avail"
   ##

   if ($stafResult->{stdout} =~ /(\d+)\), \d+ \((\d+) blocks\) avail/mg) {
      $self->{vdLogObj}->Debug("Space available: $1 blocks, $2");
      return ($1*$2/VMFS_BLOCK_SIZE);
   } else {
      $self->{vdLogObj}->Error("Unable to retrieve info about vmfs volume $vmfsVol");
      VDSetLastError("EOPFAILED");
      return undef;
   }
}


########################################################################
#
# GetMaxVMFSPartition --
#       Method to find vmfs partition on esx with largest space
#       available
#
# Input:
#       <host> - IP address/name of the esx host (Required).
#
# Results:
#       Datastore name (vmfs partition only) on esx with largest space
#       available;
#       undef in case of any error
#
# Side effects:
#       None
#
# Example:
#     @largest =
#        $esxUtilsObj->GetMaxVMFSPartition("myesx.eng.vmware.com");
#
#######################################################################

sub GetMaxVMFSPartition
{
   my $self = shift;
   my $host = shift;

   if (not defined $host) {
      $self->{vdLogObj}->Error("Insufficient parameters");
      VDSetLastError("EINVAID");
      return undef;
   }

   ##
   ## Get the list of vmfs partitions available on the host. This method will
   ## return both vmfs and nfs partitions.
   ##
   my @volumes = $self->ListVMFSPartitions($host);

   if (not defined $volumes[0]) {
      $self->{vdLogObj}->Error("Failed to get list of vmfs partitions on " .
                               $host);
      VDSetLastError("EOPFAILED");
      return undef;
   }

   my $largest = undef;
   my $maxSize = 0;

   foreach my $volume (@volumes) {
      ## Get the size of each partition.
      my $size = $self->GetVMFSSpaceAvail($host, $volume);

      if (not defined $size) {
         $self->{vdLogObj}->Error("Failed to get vmfs space");
         VDSetLastError("EOPFAILED");
         return undef;
      }
      if ($size != 0) {
         $self->{vdLogObj}->Debug("Volume: $volume has $size MB free space.");
      }

      ## Find the vmfs partition with largest size
      if ($size > $maxSize) {
         $largest = $volume;
         $maxSize = $size;
      }

   }

   ## Throw error if no vmfs partition is found
   if (not defined $largest) {
      $self->{vdLogObj}->Error("Could not find any vmfs partition on $host");
      VDSetLastError("ENOTDEF");
      return undef;
   }

   $self->{vdLogObj}->Info("Picking $largest which has $maxSize MB free space");
   return $largest;
}

###############################################################################
#
# GetFreePNics --
#      This method get free pNIC from specified ESX host.
#
# Input:
#      stafhelper       - a STAFHelper object.
#      host             - ESX host IP adderss.
#      Driver name      - pnic driver name
#      speed            - speed in units g or m, default is m (optional)
#
#
# Results:
#      Returns "@freepnic", the array of all the free pnics
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub GetFreePNics
{
   my $self         = shift; # mandatory
   my $host         = shift; # mandatory
   my $driver       = shift; # if not defined, get all free nics
   my $speed        = shift;
   my $refallnics;
   my @freepnics;
   my @tmp;
   my @allnics;
   my $refused;
   my @used;
   my $pickSameDriver = 0;

   if ((defined $driver) && ($driver =~ /same/)){
      #
      # This means user wants to pick vmnic of same driver type
      # Thus we pick all free pNICs and then check which ones have
      # same driver type.
      # Setting the flag and reseting driver type to pick all free
      # pNICs first.
      $pickSameDriver = 1;
      $driver = undef;
   }
   $refallnics = $self->GetAllPNics($host,$driver,$speed);
   # Need to differ FAILURE from empty array
   if (ref $refallnics ne 'ARRAY') {
      $self->{vdLogObj}->Error("Extract all pnics return failure");
      return "FAILURE";
   }
   
   @allnics = @$refallnics;
   # Get used pnics from ESX host
   $refused = $self->GetUsedPNics($host);
   # Need to differ FAILURE from empty array
   if (ref $refused ne 'ARRAY') {
      $self->{vdLogObj}->Error("Extract used pnics return failure");
      return "FAILURE";
   }
   @used = @$refused;
   for my $node ( @allnics ){
      if ( ! grep(/^$node$/,@used)){
         push(@freepnics, $node);
         $self->{vdLogObj}->Debug("$node is free nic");
      }
   }

   if ($pickSameDriver == 0) {
      return \@freepnics;
   } else {
      #
      # If the user wants to pick pnics of the same type(same driver and speed)
      # then we call this routine which find similar pnics from the given
      # array.
      #
      my $ret = $self->ExtractSimilarFreePNics(\@tmp, \@freepnics);
      if ((not defined $ret) || ($ret eq FAILURE)) {
         $self->{vdLogObj}->Error("Extract Similar FreePNics returned failure");
         VDSetLastError("EFAIL");
         return "FAILURE";
      }
      # User of API expects ref to an array as output.
      # thus if ExtractSimilarFreePNics return 0 pnics then we return
      # anonymous array.
      if (ref($ret) =~ /ARRAY/i) {
         return $ret;
      } else {
         $self->{vdLogObj}->Error("No similar free pnics found");
         return [];
      }
   }
}

###############################################################################
#
# GetAllPNics --
#      This method get all pNIC with special drivers or speed from specified ESX host.
#
# Input:
#      stafhelper       - a STAFHelper object.
#      host             - ESX host IP adderss.
#      Driver name      - pnic driver name
#      speed            - speed in units g or m, default is m (optional)
#
#
# Results:
#      Returns "@allpnic", the array of all the pnics
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub GetAllPNics
{
   my $self         = shift; # mandatory
   my $host         = shift; # mandatory
   my $driver       = shift; # if not defined, get all free nics
   my $speed        = shift;
   my @esxclistdout;
   my $command;
   my $res;
   my $data;
   my @tmp;
   my $node;
   my @allnics;

   if (not defined $host) {
      $self->{vdLogObj}->Error("ESX host not provided");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }
   #
   # Check if a vmnic with specific speed should be selected
   #
   if (defined $speed) {
      if ($speed =~ /(.*)G$|(.*)Gbps$/i) {
         $speed = $1 * 1000;
      } elsif ($speed =~ /(.*)M$|(.*)Mbps$/i) {
         $speed = $1;
      }
      $self->{vdLogObj}->Debug("Looking for vmnics with speed $speed" .
                               "Mbps on $host");
   }

   # Get all the pnics from ESX host
   $command = "esxcli network nic list|grep -i vmnic|grep -i up";

   $res = $self->{stafHelperObj}->STAFSyncProcess($host,$command,"180");
   $data = $res->{stdout};
   if ($res->{rc} != 0) {
      $self->{vdLogObj}->Error("Failed to execute $command on $host");
      $self->{vdLogObj}->Debug("Error:" . Dumper($res));
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }
   @tmp = split(/(\n+)/, $data);
   for $node (@tmp){
      #
      # stdout of "esxcli network nic list" looks like :
      # vmnic0  0000:005:00.0  bnx2    Up      100  Full    00:18:8b:38:3b:ab \
      # 1500  Broadcom Corporation Broadcom NetXtreme II BCM5708 1000Base-T
      #
      # Split the line based on space and store them in an array
      #
      my @vmnicInfo = split(/\s+/,$node);
      if ($node =~ /^(vmnic\d+).*/){
         my $tempNic = $1;
         if (defined $driver && $driver =~ /\w+/ ){
            # 3rd element in esxcli output is speed
            if ($vmnicInfo[2] ne $driver) {
               next;
            }
         }

         if (defined $speed) {
            # 5th element in esxcli output is speed
            if ($vmnicInfo[4] ne $speed) {
               next;
            }
         }
         push(@allnics,$tempNic);
         $self->{vdLogObj}->Debug("$tempNic is on the $host");
      }
   }
   return \@allnics;
}

###############################################################################
#
# GetUsedPNics --
#      This method get used pNIC from specified ESX host.
#
# Input:
#      host             - ESX host IP adderss.
#
# Results:
#      Returns "@usedpnics", the array of all the used pnics
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub GetUsedPNics
{
   my $self         = shift; # mandatory
   my $host         = shift; # mandatory
   my $command;
   my $res;
   my $data;
   my @tmp;
   my $node;
   my @usedpnics;
   
   if (not defined $host) {
      $self->{vdLogObj}->Error("ESX host not provided");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }
   # Get used pnics from ESX host
   $command = "esxcfg-vswitch -l"; # PR610910
   $res = $self->{stafHelperObj}->STAFSyncProcess($host,$command,"10");
   if ($res->{rc} != 0) {
      $self->{vdLogObj}->Error("Failed to execute $command on $host");
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }
   @tmp = split(/(\s+)/, $res->{stdout});
   for $node (@tmp){
      while ( $node =~ m/(vmnic\d+)/g ){
         my $added = grep (/^$1$/,@usedpnics);
         if ($added == 0 ){
            push ( @usedpnics, $1);
            $self->{vdLogObj}->Debug("$1 is used nic");
         }
      }
   }
   return \@usedpnics;
}
###############################################################################
#
# ExtractSimilarFreePNics --
#      This method get free pNIC of the same driver type and same speed
#      from the given array.
#
# Input:
#      esxclistdout     - ESX cli stdout of the esx host(mandatory)
#      free pnics       - array of free pnics(mandatory)
#
# Results:
#      Returns "@freepnic", the array of all similar free pnics
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub ExtractSimilarFreePNics
{
   my $self             = shift; # mandatory
   my $esxclistdoutref  = shift;
   my $freepnicsref     = shift;

   if ((not defined $esxclistdoutref) || (not defined $freepnicsref)) {
      $self->{vdLogObj}->Error("Missing input in ExtractSimilarFreePNics()");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }

   my @esxclistdout = @$esxclistdoutref;
   my @freepnics = @$freepnicsref;

   # Pick out which free Pnics have same driver type and speed.
   my $hashOfSimilarPnics;

   # Typical i j loop for finding out matching entries.
   for(my $i=0; $i <= scalar(@esxclistdout) -1; $i++) {
      my @similarFreePnic;
      # Flag to say if vmnics matched or not
      my $match = 0;
      # Split the line based on space and store them in an array
      my @vmnicInfo = split(/\s+/,$esxclistdout[$i]);
      # If the node in @tmp array is not free then move on to next node
      if ((not defined $vmnicInfo[0]) ||
         ((defined $vmnicInfo[0]) && (!grep(/^$vmnicInfo[0]$/,@freepnics)))){
         next;
      }
      #
      # If the node is already matched with other nodes and stored
      # in the array then we can skip that node
      #
      my $alreadyMatched = 0;
      foreach my $key (keys %$hashOfSimilarPnics) {
      # return reference to an array containing matching vmnics
         my @matchedArray = @{$hashOfSimilarPnics->{$key}};
         if(grep(/^$vmnicInfo[0]$/,@matchedArray)) {
            $alreadyMatched = 1;
         }
      }

      if($alreadyMatched == 1) {
         next;
      }


      for (my $j=$i+1; $j <= scalar(@esxclistdout); $j++) {
         if (not defined $esxclistdout[$j]) {
            next;
         }
         my @sameVmnicInfo = split(/\s+/,$esxclistdout[$j]);
         #
         # We compare if drivername and speed are same for both vmnic
         # if they are then we save that matching vmnic. we save the vmnic
         # being matched at the end.
         #
         if ((not defined $vmnicInfo[2]) || (not defined $sameVmnicInfo[2])) {
            next;
         }
         if (($vmnicInfo[2] eq $sameVmnicInfo[2]) &&
             ($vmnicInfo[4] eq $sameVmnicInfo[4])) {
            push(@similarFreePnic,$sameVmnicInfo[0]);
            $match = 1;
            $self->{vdLogObj}->Debug("Driver and speed matched for ".
                                     "$vmnicInfo[0] and $sameVmnicInfo[0]");
         }
      }
      if ($match == 1) {
         push(@similarFreePnic,$vmnicInfo[0]);
         # We calculate the size of array which gives the number
         # of vmnics which have matched with each other.
         # There might be 2 bnx2 with 1 G speed
         # There might be 3 ixgb with 1 G speed. we need to give
         # user 3 ixgbs in this case. Thus we calculate the size
         # of array and store it in hash. We sort the hash and
         # return the maximum number of matching vmnics to user.
         my $size = scalar(@similarFreePnic);
         $hashOfSimilarPnics->{$size} = \@similarFreePnic;
      }
   }

   #
   # We sort the hash according to key which has the highest
   # number of matching vmnics and return that to user so that
   # he can use all the matching vmnics.
   #
   foreach (sort { $b <=> $a } keys %$hashOfSimilarPnics) {
      # return reference to an array containing matching vmnics
      return $hashOfSimilarPnics->{$_};
   }

}


###############################################################################
#
# GetFreePNicsDetails --
#      This method gets the details of free pNICs from specified ESX host.
#
# Input:
#      stafhelper       - a STAFHelper object.
#      host             - ESX host IP adderss.
#
#
# Results:
#      Returns "\@freepnic", reference to an array of references, where each
#                            reference points to an array consisting of  the
#                            free PNic details (name, driver, speed).
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub GetFreePNicsDetails
{
   my $self             = shift; # mandatory
   my $host             = shift; # mandatory
   my @freepnics;
   my $command;
   my $res;
   my $data;
   my @tmp;
   my $node;
   my @allnicsDetail;
   my @used;

   if (not defined $host) {
      $self->{vdLogObj}->Error("ESX host not provided");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }

   # Get all the pnics from ESX host
   $command = "esxcli network nic list|grep -i vmnic|grep -i up | grep -v -i down";

   $res = $self->{stafHelperObj}->STAFSyncProcess($host, $command, "180");
   $data = $res->{stdout};
   if (($res->{rc} != 0) || ($res->{exitCode} != 0)) {
      $self->{vdLogObj}->Error("Failed to execute $command on $host");
      $self->{vdLogObj}->Debug("Error:" . Dumper($res));
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }
   @tmp = split(/(\n+)/, $data);
   for $node (@tmp){
      #
      # stdout of "esxcli network nic list" looks like :
      # Name    PCI Device    Driver  Admin Status  Link Status  Speed  Duplex ...
      # ------  ------------  ------  ------------  -----------  -----  ------ ...
      # vmnic0  0000:01:00.0  tg3     Up            Up            1000  Full   ...
      # vmnic1  0000:01:00.1  tg3     Up            Up            1000  Full   ...
      #
      # Split the line based on space and store them in an array
      #
      my @vmnicInfo = split(/\s+/, $node);
      if ($node =~ /^(vmnic\d+).*/){
         my @tmpArray;
         $tmpArray[0] = $1;
         $tmpArray[1] = $vmnicInfo[2];
         $tmpArray[2] = $vmnicInfo[5];
         push(@allnicsDetail,\@tmpArray);

         $self->{vdLogObj}->Debug("$tmpArray[0] is on the $host");
      }
   }
   # Get used pnics from ESX host
   $command = "esxcfg-vswitch -l";
   $res = $self->{stafHelperObj}->STAFSyncProcess($host, $command, "10");
   $data = $res->{stdout};
   $self->{vdLogObj}->Debug("Command \"esxcfg-vswitch -l\" returns " .
                            Dumper($res));
   if ($res->{rc} != 0) {
      $self->{vdLogObj}->Error("Failed to execute $command on $host");
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }
   @tmp = split(/(\s+)/, $data);
   for $node (@tmp){
      while ( $node =~ m/(vmnic\d+)/g ){
         my $added = grep (/^$1$/,@used);
         if ($added == 0 ){
            push ( @used, $1);
            $self->{vdLogObj}->Debug("$1 is used nic");
         }
      }
   }

   for $node (@allnicsDetail){
      if (!grep(/^$node->[0]$/,@used)){
         push(@freepnics, $node);
         $self->{vdLogObj}->Debug("$node->[0] is free nic");
      }
   }
   return \@freepnics;
}


########################################################################
#
# MountDatastore--
#      Method to mount nfs servers as datastores on the given esx host.
#
# Input:
#      host            : esx host name or ip address (Required)
#      mountServer     : name or ip of the nfs server (Required)
#      sharePoint      : absolute path to the shared folder (Required)
#      localMountPoint : datastore name to be assigned to this share
#                        (Required)
#      readOnly        : boolean to indicate whether to mount the
#                        share as aread-only file system or not
#                        (Optional, default is 0)
#
# Results:
#      datastore name, if the given network share is mounted
#                      successfully;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub MountDatastore
{
   my $self             = shift;
   my $host             = shift;
   my $mountServer      = shift;
   my $sharePoint       = shift;
   my $localMountPoint  = shift;
   my $readOnly         = shift;

   if ((not defined $host) || (not defined $mountServer) ||
      (not defined $sharePoint) || (not defined $localMountPoint)) {
      $self->{vdLogObj}->Error("MountDatastore: One or more parameters missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

    my $result = $self->FindDatastore($host,
                                  $mountServer,
                                  $sharePoint,
                                  $localMountPoint);
   if ($result eq FAILURE) {
      goto ADDDATASTORE;
   } else {
      return $result;
   }

ADDDATASTORE:
   # Remove old entries point to different sharepoints
   # before addition is done
   $result = $self->RemoveDatastore($host, $localMountPoint);

   my $timeout = 20;
   while ($timeout > 0) {
      # Mount the new mount point using fresh server and
      # share point
      $result = $self->AddDatastore($host,
                                    $mountServer,
                                    $sharePoint,
                                    $localMountPoint,
                                    $readOnly);
      if ($result eq FAILURE) {
         $self->{vdLogObj}->Debug("AddDatastore failed to Mount
                                   $localMountPoint on $host");
         # Add/Remove of datastore is taking time to showup in the
         # updated list. Without this sleep, FindDatastore() might
         # return FAILURE.
         sleep 5;
      } else {
         last;
      }
      $timeout -= 5;
   }
   $result = $self->FindDatastore($host,
                                  $mountServer,
                                  $sharePoint,
                                  $localMountPoint);
   if ($result eq FAILURE) {
      $self->{vdLogObj}->Debug("Mount point is $localMountPoint on $host");
      return $localMountPoint;
   } else {
      $self->{vdLogObj}->Debug("Mount point should be $result on $host");
      return $result;
   }
}


########################################################################
#
# FindDatastore--
#      Method to find nfs servers as datastores on the given esx host.
#
# Input:
#      host            : esx host name or ip address (Required)
#      mountServer     : name or ip of the nfs server (Required)
#      sharePoint      : absolute path to the shared folder (Required)
#      localMountPoint : datastore name to be assigned to this share
#                        (Required)
#
# Results:
#      datastore name, if the given network share is mounted
#                      successfully;
#      "FAILURE", if nothing is found or in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub FindDatastore
{
   my $self             = shift;
   my $host             = shift;
   my $mountServer      = shift;
   my $sharePoint       = shift;
   my $localMountPoint  = shift;

   my $serverWithNoDomain = $mountServer;
   #
   # remove any extension in server name, for example remove
   # ".eng.vmware.com" from prme-bheemboy.eng.vmware.com
   #
   $serverWithNoDomain =~ s/\..*//g;

   $self->{vdLogObj}->Debug("Dumping result of esxcli storage nfs list on host $host");
   my $command = "esxcli storage nfs list | grep " . $mountServer;

   my $result = $self->{stafHelperObj}->STAFSyncProcess($host,
                                                        $command);
   if ($result->{rc} != 0) {
      $self->{vdLogObj}->Error("STAF command $command failed");
      $self->{vdLogObj}->Debug("Error:" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $self->{vdLogObj}->Debug("Result:" . Dumper($result));
   my @datastoreList = split('\n', $result->{stdout});

   # Step1: Check Server is mounted
   # if no return FAILURE else
   # move forward
   if (scalar(@datastoreList) <= 0) {
      $self->{vdLogObj}->Debug("Server $mountServer not found, proceed to add");
      return FAILURE;
   }

   # Step2: Check if share point is correct
   # if no return FAILURE else
   # move forward
   my $existingMountPoint;
   my @datastoreInfo = ();
   foreach my $item (@datastoreList) {
      @datastoreInfo = split(/\s+/, $item);
      if (($datastoreInfo[2] ne $sharePoint) || ($datastoreInfo[1] !~ /$mountServer/) ||
          ($datastoreInfo[3] !~ /true/i) || ($datastoreInfo[4] !~ /true/i)) {
         @datastoreInfo = ();
         next;
      }
   }

   if (scalar(@datastoreInfo) <1) {
      $self->{vdLogObj}->Debug("Share point $mountServer:$sharePoint not found, proceed to add");
      return FAILURE;
   } else {
      $existingMountPoint = $datastoreInfo[0];
   }

   # Step3: Check if mount points match
   # if no return the mount point discovered
   # else return FAILURE
   if ($existingMountPoint eq $localMountPoint) {
      $self->{vdLogObj}->Debug("Mountpoint $mountServer:$sharePoint already " .
                               "mapped to $localMountPoint");
      return FAILURE;
   } else {
      $self->{vdLogObj}->Debug("Mountpoint $mountServer:$sharePoint is not " .
                               "mapped to $localMountPoint, instead it is " .
                               "mapped to $existingMountPoint. Therefore we " .
                               "will use $existingMountPoint as our mount point");
     return $existingMountPoint;
   }
}


########################################################################
#
# AddDatastore--
#      Method to mount nfs servers as datastores on the given esx host.
#
# Input:
#      host            : esx host name or ip address (Required)
#      mountServer     : name or ip of the nfs server (Required)
#      sharePoint      : absolute path to the shared folder (Required)
#      localMountPoint : datastore name to be assigned to this share
#                        (Required)
#      readOnly        : boolean to indicate whether to mount the
#                        share as aread-only file system or not
#                        (Optional, default is 0)
#
# Results:
#      SUCCESS, if addition of datastore was successfull
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub AddDatastore
{
   my $self            = shift;
   my $host            = shift;
   my $mountServer     = shift;
   my $sharePoint      = shift;
   my $localMountPoint = shift;
   my $readOnly        = shift;

   # check if readOnly flag is defined, otherwise default to 0
   $readOnly = (defined $readOnly) ? $readOnly : 0;
   my $command = "esxcli storage nfs add -v  $localMountPoint" .
                 " -H $mountServer -s $sharePoint ";
   if ($readOnly) {
      $command = $command . " -r";
   }

   $self->{vdLogObj}->Debug("STAF command is $command ");
   my $result = $self->{stafHelperObj}->STAFSyncProcess($host,
                                                     $command);
   if ($result->{rc} != 0) {
      $self->{vdLogObj}->Error("STAF command $command failed");
      $self->{vdLogObj}->Debug("Error:" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($result->{exitCode} != 0){
      $self->{vdLogObj}->Debug("Command $command failed:" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{vdLogObj}->Debug("Result of AddDatastore for $localMountPoint:" .
                            Dumper($result));
   return SUCCESS;
}


########################################################################
#
# RemoveDatastore--
#      Method to unmount nfs servers as datastores on the given esx host.
#
# Input:
#      host               : esx host name or ip address (Required)
#      existingMountPoint : datastore name that needs to be removed
#
# Results:
#      SUCCESS if deletion was successfull
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub RemoveDatastore
{
   my $self               = shift;
   my $host               = shift;
   my $existingMountPoint = shift;

   my $command = "esxcli storage nfs remove -v \"$existingMountPoint\"";
   $self->{vdLogObj}->Debug("Command= $command");
   my $result = $self->{stafHelperObj}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
       $self->{vdLogObj}->Debug("Failed to remove on $existingMountPoint on $host");
       $self->{vdLogObj}->Debug("Error: " . Dumper($result));
       VDSetLastError("EOPFAILED");
       return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# RefreshDatastore--
#      Method to refresh the datastore so that it is available via
#      hostd/ui.
#
# Input:
#      datastore       : Name of the datastore.(Required)
#      host            : esx host name or ip address (Required)
#
#
# Results:
#      "SUCCESS", if refreshing datastore fails for some reason.
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub RefreshDatastore
{
   my $self = shift;
   my $datastore = shift;
   my $host = shift;
   my $command;
   my $result;

   if ((not defined $datastore) || (not defined $host)) {
      $self->{vdLogObj}->Error("Name of the datastore not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "vim-cmd /hostsvc/datastore/refresh $datastore";
   $result = $self->{stafHelperObj}->STAFSyncProcess($host,
                                                     $command);

   if ($result->{rc} != 0) {
      $self->{vdLogObj}->Error("STAF command $command failed");
      $self->{vdLogObj}->Debug("Error:" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{exitCode} != 0){
      $self->{vdLogObj}->Debug("Command $command failed:" . Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetNetSchedulerTree --
#     Routine to get information about all the nodes including
#     infrastructure traffic types like FT, NFS etc. from the
#     network scheduler.
#     NOTE: this routine should be executed locally on the ESX host
#     or using ExecuteRemoteMethod() in Utilities.pm
#
# Input:
#     vmnic: vmnic interface name (mandatory)
#
# Results:
#     The final result is reference to hash of hashes.
#     First level keys are:
#     infrastructure: to collect all infrastructure nodes
#                     like FT, NFS, etc
#     vm            : to collect all VM vnic ports
#     Value of each node is also a hash with
#     following keys:
#     shares     : shares value configured on the scheduler
#     reservation: reservation value configured on the scheduler
#     limit      : limits value configured on the scheduler
#     entitlement: this value will be set to undef in this routine
#
#
# Side effects:
#     None
#
########################################################################

sub GetNetSchedulerTree
{
   my $vmnic    = shift;
   my $linkCap  = "750"; #TODO: compute link cap automatically

   if (not defined $vmnic) {
      $vdLogger->Error("vmnic name not provided to compute schedTree");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $prefix = "/vmkModules/netsched/hclk/devs/$vmnic/qleaves";
   my $result = `vsish -pe ls /vmkModules/netsched/hclk/devs/$vmnic/qleaves`;
   my @temp = split(/\n/, $result);
   # create a schedTree to store SLR value configured for all the nodes
   my $schedTree = {};
   my $cmd;

   foreach my $item (@temp) {
      $item =~ s/\s+|netsched\.pools\.|\///g;
      my ($type, $node) = split(/\./, $item);
      $cmd =  "vsish -pe get " . $prefix . "/netsched\.pools\." . "$type\." .
              "$node/" . "info";
      my $reservation = `$cmd`;
      $type = ($type =~ /persist/) ? "infrastructure" : $type;
      $reservation = VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                                   RESULT => $reservation);
      $schedTree->{$type}{$node}{reservation} = $reservation->{reservation};
      $schedTree->{$type}{$node}{shares} = $reservation->{shares};
      $schedTree->{$type}{$node}{limit} = $reservation->{limit};
   }
   $cmd = "vsish -pe get /vmkModules/netsched/hclk/devs/" . $vmnic .
          "/qparents/netsched.pools.persist.vm/info";
   my $vmInfo = `$cmd`;
   $vmInfo = VDNetLib::Common::Utilities::ProcessVSISHOutput(RESULT => $vmInfo);
   if (ref($vmInfo) eq "HASH") {
      $schedTree->{"infrastructure"}{vm}{reservation} = $vmInfo->{reservation};
      $schedTree->{"infrastructure"}{vm}{shares} = $vmInfo->{shares};
      $schedTree->{"infrastructure"}{vm}{limit} = $vmInfo->{limit};
   }
   return $schedTree;
}


########################################################################
#
# ComputeEntitlement --
#     Method to compute bandwidth entitlement for the
#     given level (infrastructure/vm) on vmnic
#
# Input:
#     schedTree : reference to schedTree hash (computed using
#                 GetNetSchedulerTree() routine)
#     level     : "infrastructure" or "vm"
#     levelBandwidthReserved: total bandwidth user reserved for this
#                             level
#
#
# Results:
#     updated schedTree hash, if entitlement is computed successfully; or
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ComputeEntitlement
{
   my $schedTree              = shift;
   my $level                  = shift;
   my $levelBandwidthReserved = shift;
   my $totalBWRequired = 0;
   my $totalShareableBW = 0;
   my $totalShares = 0;

   if ((not defined $schedTree) || (not defined $level) &&
      (not defined $levelBandwidthReserved)) {
      $vdLogger->Error("One or more parameters name not provided to " .
                       "compute entitlement");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   #
   # There are 2 buckets: totalBWRequired and extraBandwidth
   # which can be shared among various node
   #

   #
   # First, compute the total reserved bandwidth based
   # on user configuration
   #
   my $schedulerLevel = $schedTree->{$level};
   foreach my $port (keys %$schedulerLevel) {
      $totalBWRequired += $schedTree->{$level}{$port}{reservation};
      $totalShares += $schedTree->{$level}{$port}{shares};
   }
   #
   # Now, get the free bandwidth that can be shared
   #
   $totalShareableBW = $levelBandwidthReserved - $totalBWRequired;

   my $residueBW = 0;

   #
   # Compute the extra bandwidth obtained using the shares
   #
   foreach my $port (keys %$schedulerLevel) {
      my $share = $schedTree->{$level}{$port}{shares};
	   my $extraBWFromShares = ($share/$totalShares) * $totalShareableBW;
	   my $totalPortBandwidth = $schedTree->{$level}{$port}{reservation} +
                               $extraBWFromShares;
      my $portLimit = $schedTree->{$level}{$port}{limit};
	   if (($portLimit > 0) && ($portLimit < $totalPortBandwidth)) {
		   $residueBW += $totalPortBandwidth - $portLimit;
         $totalShares -= $schedTree->{$level}{$port}{shares};
	   }
	   $schedTree->{$level}{$port}{entitlement} = $totalPortBandwidth;
   }

   #
   # Now, if the total bandwidth entitled is greater than
   # the limit, move the residue/free bandwidth to the free pool
   # again and apply shares for all other nodes
   #
   foreach my $port (keys %$schedulerLevel) {
      my $share = $schedTree->{$level}{$port}{shares};
      my $portLimit = $schedTree->{$level}{$port}{limit};
      my $totalPortBandwidth = $schedTree->{$level}{$port}{entitlement};
      if ($portLimit < $schedTree->{$level}{$port}{entitlement}) {
         my $extraBWFromShares = ($share/$totalShares) * $residueBW;
         $totalPortBandwidth += $extraBWFromShares;
      }
      $schedTree->{$level}{$port}{prevbytes} = 0; # set initial byte count
      $schedTree->{$level}{$port}{entitlement} = $totalPortBandwidth;
   }
   return $schedTree;
}


########################################################################
#
# GetPortEntitlement --
#     Routine to compute entitlement for ALL nodes on a vmnic as seen
#     by the scheduler (it includes both infrastructure and vm levels)
#
# Input:
#     vmnic   : vmnic interface name  (required)
#     linkCap : total link capacity of the vmnic (required)
#
# Results:
#     updated 'schedTree' hash with 'entitlement' key value set; or
#     FAILURE, in case of any error
#
# Side effects:
#
########################################################################

sub GetPortEntitlement
{
   my $vmnic   = shift;
   my $linkCap = shift || "750";
   my $schedTree = GetNetSchedulerTree($vmnic);

   if ($schedTree eq FAILURE) {
      $vdLogger->Error("Failed to get schedTree hash for $vmnic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Compute the entitlement for infrastructure traffic (FT, NFS, VM etc.)
   if (FAILURE eq ComputeEntitlement($schedTree, "infrastructure", $linkCap)) {
      $vdLogger->Error("Failed to get compute entitlement for " .
                       "infrastucture level nodes on $vmnic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $vmLevelBandwidthEntitled =
      $schedTree->{'infrastructure'}{'vm'}{entitlement};
   $vdLogger->Debug("Bandwidth entitled for VM : $vmLevelBandwidthEntitled");

   # Now, compute the entitlement for each vnic placed on vmnic
   if (FAILURE eq ComputeEntitlement($schedTree,
                                     "vm",
                                     $vmLevelBandwidthEntitled)) {
      $vdLogger->Error("Failed to get compute entitlement for " .
                       "vm level nodes on $vmnic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $schedTree;
}


########################################################################
#
# GetPortEntitlementStatus --
#     Routine to get port entitlement status i.e whether bandwidth
#     entitled for all the nodes on vmnic is met or not.
#     Verification is done based on throughput calculated per
#     node and it's entitled bandwidth.
#     This routine works under the assumption that IO session is
#     active on the vmnic while executing this routine.
#
# Input:
#     vmnic       : vmnic interface name (Required)
#     iterations  : number of iterations to compute throughput
#                   and verify entitlement (optional, default is
#                   2)
#     interval    : sleep time in secs between each iteration (optional,
#                   default is 10)
#
# Results:
#     reference to hash of hash with first level keys as nodes
#     on the vmnic and second level key is
#     'status' : reference to array with each element having value as
#                either 'NOT OK' or 'OK' to indicate entitlement status.
#                The size of this array is equal to the 'iterations'
#                value provided by user
#
# Side effects:
#     None
#
########################################################################

sub GetPortEntitlementStatus
{
   my $vmnic      = shift;
   my $iterations = shift;
   my $interval   = shift;
   my $linkCap    = "750"; # TODO compute this value automatically;

   $iterations = (defined $iterations) ? int($iterations) : 2;
   $interval   = (defined $interval) ? int($interval) : 10;
   my $schedTree = GetPortEntitlement($vmnic, $linkCap);
   if ($schedTree eq FAILURE) {
      $vdLogger->Error("Failed to compute port entitlement for $vmnic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $prevTime = 0; # set timer to zero
   my $returnHash;
   for (my $iteration = 0; $iteration < 6; $iteration++) {
      my $elapsedTime = time() - $prevTime;
      $prevTime = time();
      my $schedulerLevel = $schedTree->{"vm"};
      my $status;

      foreach my $port (keys %$schedulerLevel) {
         my $tput = CalculateSchedulerThroughput($port,
                                                 'vm',
                                                 $elapsedTime,
                                                 $schedTree,
                                                 $vmnic);
         my $entitlement = int($schedulerLevel->{$port}{entitlement});
         $status = ($tput < $entitlement) ? "NOT OK" : "OK";
         $returnHash->{$port}{status}->[$iteration] = $status;
      }
      $schedulerLevel = $schedTree->{infrastructure};
      foreach my $port (keys %$schedulerLevel) {
         if ($port eq "vm") {
            next;
         }
         my $tput = CalculateSchedulerThroughput($port,
                                                 'infrastructure',
                                                 $elapsedTime,
                                                 $schedTree,
                                                 $vmnic);
         my $entitlement = int($schedulerLevel->{$port}{entitlement});
         $status = ($tput < $entitlement) ? "NOT OK" : "OK";
         $returnHash->{$port}{status}->[$iteration] = $status;
      }
      sleep $interval;
   }
   return $returnHash;
}


########################################################################
#
# CalculateSchedulerThroughput --
#     Routine to compute throughput of the given port on the network
#     scheduler
#
# Input:
#     port        : port id (vnic port id or ft/nfs/iscsi/ha)
#     level       : scheduler level (infrastructure/vm)
#     elapsedTime : time elapsed between since last time throughput
#                   computed
#     schedTree   : reference to 'schedTree' hash
#     vmnic       : vmnic interface name
#
#
# Results:
#     throughput value for the given port
#
# Side effects:
#     None
#
########################################################################

sub CalculateSchedulerThroughput
{
   my $port        = shift;
   my $level       = shift;
   my $elapsedTime = shift;
   my $schedTree   = shift;
   my $vmnic       = shift;

   my $prefix = "/vmkModules/netsched/hclk/devs/$vmnic/qleaves";
   my $node = ($level =~ /infrastructure/i)? "persist" : $level;
   my $cmd =  "vsish -pe get " . $prefix . "/netsched\.pools\." .
              "$node\." . "$port/" . "info";
   my $output = `$cmd`;
   my $tempHash = VDNetLib::Common::Utilities::ProcessVSISHOutput(RESULT => $output);
   my $diff = $tempHash->{bytesOut} - $schedTree->{$level}{$port}{prevbytes};
   $schedTree->{$level}{$port}{prevbytes} =  $tempHash->{bytesOut};
   my $status;
   my $tput = ($diff * (8/(1000 * 1000)))/$elapsedTime;
   return $tput;
}
1;
