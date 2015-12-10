########################################################################
# Copyright (C) 2004 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::BasicSanity;

########################################################################
# This module contains entry point for all test cases in BasicSanity
# category
# Methods in this Module:
#      1. PowerOnOff - entry point for BasicSanity.PowerOnOff test
#      2. SuspendResume - entry point for BasicSanity.SuspendResume test
#      3. SnapshotRevertDelete - entry point for
#                                BasicSanity.SnapshotRevertDelete test
#      4. CableDisconnect - entry point for BasicSanity.CableDisconnect test
#      5. DisableEnable - entry point for BasicSanity.DisableEnable test
#
# Results:
#      PASS = Success
#      FAIL = Failure
#
# Side effects:
#         Depends on the test
#
########################################################################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use VDNetLib::VDCommonSrvs;
BEGIN {
   eval "use VDNetLib::VMOperations::VMOperations"; warn $@ if $@;
}

use VDNetLib::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack);
use Data::Dumper;
use Time::HiRes qw(gettimeofday);
use VDNetLib::GlobalConfig qw( $vdLogger );
use VDNetLib::LocalAgent qw(ExecuteRemoteMethod);
use VDNetLib::NetAdapter;

use constant DEFAULT_SLEEP_TIME => 20;
use constant STANDBY_TIMEOUT => 120;

#######################################################################
# PowerOnOff --
#       Implements Power On/Off test in the BasicSanity category
#
#       - Power off the SUT
#       - Power On the SUT
#       - Wait for the STAF to come up on the SUT
#	- Find DUT
#	- Run netperf and ensure it works
#
# Input:
#       testbed object and testcase hash
#
# Results:
#	PASS if the test succeeds
#	FAIL if any of the steps in the test case fails
#
# Side effects:
#       none
#
########################################################################

sub PowerOnOff
{
   my $testbed = shift;
   my $testcase = shift;

   my ($ret, $VMOpsResult);

   my $tbRef = $testbed->GetTestbed;
   my %tb = %$tbRef;
   my $vmOpsObj = VDNetLib::VMOperations::VMOperations->new(\%{$tb{'SUT'}});
   # TODO: Gagan: Need to do some error checking. Of course!!!
   # Ask kishore about it.

   $VMOpsResult = "PASS";
   # After adding getstate in VMOperations module, need to remove
   # unconditionally powering on
   if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
      $vdLogger->Error("Initial VM Poweron failed");
      VDSetLastError("EINVALID");
      $VMOpsResult = "FAIL";
   }
   if ( $vmOpsObj->VMOpsPowerOff() eq FAILURE ) {
      $vdLogger->Error("VM poweroff returned failed");
      VDSetLastError("EINVALID");
      $VMOpsResult = "FAIL";
   }
   if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
      $vdLogger->Error("VM poweron returned failed");
      VDSetLastError("EINVALID");
      $VMOpsResult = "FAIL";
   }
   sleep(120);
   $vdLogger->Info("Waiting for STAF on $tb{'SUT'}{ip} to come up");
   $ret = $testbed->{stafHelper}->WaitForSTAF($tb{'SUT'}{ip});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Info("STAF is not running on $tb{'SUT'}{ip}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");
   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "$testcase->{VD_PRE} failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
         # TODO: print the above log in the pre-processing routine itself
      } elsif ( $ret eq "FAIL" ) {
         VDSetLastError(VDGetLastError());
         return $ret;
      }
   }
   my $count = 0;
   my @testData = ("");
   foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
      $vdLogger->Info("Running $mod traffic module on " .
                       "$testcase->{CONNECTION}{Source}{IP}");
      # TODO: use Module::Locate to check if a module by name $mod exist
      if ( $mod =~ m/netperf/i ) {
         if ( defined $testcase->{DATASET} ) {
            @testData = @{$testcase->{DATASET}};
            $count = scalar(@{$testcase->{DATASET}});
         }
         foreach my $d (@testData) {
            $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->ClearTestOptions();
            $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->PrependTestOptions("-H $testcase->{CONNECTION}{Destination}{nic}{IPv4}");
            $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->AppendTestOptions($d);
            $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->Start();
            if ( ( $ret =
                 VDNetLib::VDCommonSrvs::VdPostProcessing($testcase) ) =~ /fail/i ) {
               # TODO: parse the error code and return whether it is error in
               # product tool or script or setup (if applicable)
               $vdLogger->Error( "TCPDUMP Post Processing failed \n");
            }
            # TODO: Need to implement the right logic based on the traffic tool
            # output and tcpdump output
            # Scenarios to be covered
            # Netperf passes, packet capture failed because of some internal
            # mark the test pass as it is due to the script failure
            # Netperf failed, then irrespective of packet capture mark the test failed
            $ret = "PASS";
            if ( (my $output = $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->GetResult()) ne "0" ) {
               $vdLogger->Error("netperf failed for iteration $count: $output\n");
               $ret = "FAIL";
            }
            if ( defined $testcase->{VERIFICATION}{TCPDUMP}{handle} ) {
               if ( ($testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->GetResult() eq "0" )
                  && ($testcase->{VERIFICATION}{TCPDUMP}{result} =~ /fail/i) ) {
                  $vdLogger->Info("packet capture for iteration $count failed \n");
                  $ret = "PASS";
               }
               if ( ($testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->GetResult() eq "0")
                  && ($testcase->{VERIFICATION}{TCPDUMP}{result} =~ /pass/i) ) {
                  $ret = "PASS";
               }
            }
            # TODO: need to find better way to figure out if there is more data
            $count = $count - 1;
            if ( $count > 0 ) {
               $ret = VDNetLib::VDCommonSrvs::VdPreTcpdumpSetup($testbed, $testcase);
               # TODO: Need to add proper error codes here
               if ( $ret ne SUCCESS ) {
                  $vdLogger->Error("TCPDUMP pre-processing failed for ".
                                    "$count: $ret\n");
               }
            }
         }
      } # if it is netperf module
   } # end of for all traffic modules
   return $VMOpsResult;
}

#######################################################################
# SuspendResume --
#       Implements Suspend/Resume test in the BasicSanity category
#
#       - Power on the SUT if it is not ON
#       - Suspend the VM, Resume the VM.
#       - Wait for the STAF to come up on the SUT
#	- Find DUT
#	- Run netperf and ensure it works
#
# Input:
#       testbed object and testcase hash
#
# Results:
#	PASS if the test succeeds
#	FAIL if any of the steps in the test case fails
#
# Side effects:
#       none
#
########################################################################

sub SuspendResume
{
   my $testbed = shift;
   my $testcase = shift;

   my ($ret, $VMOpsResult);

   my $tbRef = $testbed->GetTestbed;
   my %tb = %$tbRef;
   my $vmOpsObj = VDNetLib::VMOperations::VMOperations->new(\%{$tb{'SUT'}});

   $VMOpsResult = "PASS";
   if ( $vmOpsObj->VMOpsPowerOn() ne SUCCESS ) {
      $vdLogger->Error("VMOperations returned failure");
      # this error could be ignored as it could fail if the VM
      # is already powered on.  Remove powering on once you have
      # getstate method in vmoperations module, use it to decide
      # whether to power on or not.
      $vdLogger->Info("VMOperation PowerOn Failed:\n".VDGetLastError());
   }
   if ( $vmOpsObj->VMOpsSuspend() ne SUCCESS ) {
      # Print the stack trace right here as vdNet.pl can not
      # distinguish whether the test failed because of product
      # bug or due to bug in automation etc
      $vdLogger->Error("VMOperations VMOpsSuspend returned failure");
      VDSetLastError(VDGetLastError());
      $vdLogger->Info("VMOperation VMOpsResume Failed");
      return "FAIL";
   }
   if ( $vmOpsObj->VMOpsResume() ne SUCCESS ) {
      $vdLogger->Error("VMOperation VMOpsResume returned failure");
      VDSetLastError(VDGetLastError());
      $vdLogger->Info("VMOperation VMOpsResume Failed");
      return "FAIL";
   }

   sleep(120);
   $vdLogger->Info("Waiting for STAF on $tb{'SUT'}{ip} to come up");
   $ret = $testbed->{stafHelper}->WaitForSTAF($tb{'SUT'}{ip});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Error( "STAF is not running on  $tb{'SUT'}{ip}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");
   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error("$testcase->{VD_PRE} failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         VDSetLastError(VDGetLastError());
         return $ret;
      }
   }
   foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
      # TODO: use Module::Locate to check if a module by name $mod exist
      if ( $mod =~ m/netperf/i ) {
         $ret = VDNetLib::VDCommonSrvs::NetperfWorkload($testbed, $testcase);
      }
   }
   if ($ret eq "FAIL") {
      $vdLogger->Info("SuspendResume: Netperf Failed");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   } else {
      return "PASS";
   }
}

#######################################################################
# SnapshotRevertDelete --
#       Implements Snapshot/Revert/Delete test in the BasicSanity
#       category
#
#       - Power on the SUT if it is not ON
#       - Take snapshot, revert to it, and delete the snapshot
#       - Wait for the STAF to come up on the SUT
#	- Find DUT
#	- Run netperf and ensure it works
#
# Input:
#       testbed object and testcase hash
#
# Results:
#	PASS if the test succeeds
#	FAIL if any of the steps in the test case fails
#
# Side effects:
#       none
#
########################################################################

sub SnapshotRevertDelete
{
   my $testbed = shift;
   my $testcase = shift;

   my $ret;


   my $tbRef = $testbed->GetTestbed;
   my %tb = %$tbRef;
   my $vmOpsObj = VDNetLib::VMOperations::VMOperations->new(\%{$tb{'SUT'}});

   if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
      $vdLogger->Info("BasicSanity: VMOpsPowerOn failed\n".
                          VDGetLastError());
   }

   if ( $vmOpsObj->VMOpsTakeSnapshot("bs1") eq FAILURE ) {
      $vdLogger->Info("BasicSanity: VMOpsTakeSnapshot failed\n".
                          VDGetLastError());
      goto FAIL;
   }

   if ( $vmOpsObj->VMOpsRevertSnapshot("bs1") eq FAILURE ) {
      $vdLogger->Info("BasicSanity: VMOpsRevertSnapshot failed".
                          VDGetLastError());
      goto FAIL;
   }

   if ( $vmOpsObj->VMOpsDeleteSnapshot("bs1") eq FAILURE ) {
      $vdLogger->Info("BasicSanity: VMOpsDeleteSnapshot failed".
                          VDGetLastError());
      goto FAIL;
   }

   sleep(120);
   $vdLogger->Info("Waiting for STAF on $tb{'SUT'}{ip} to come up");
   $ret = $testbed->{stafHelper}->WaitForSTAF($tb{'SUT'}{ip});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Error( "STAF is not running on $tb{'SUT'}{ip}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");
   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "$testcase->{VD_PRE} failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         VDSetLastError(VDGetLastError());
         return $ret;
      }
   }
   foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
      # TODO: use Module::Locate to check if a module by name $mod exist
      if ( $mod =~ m/netperf/i ) {
         $ret = VDNetLib::VDCommonSrvs::NetperfWorkload($testbed, $testcase);
      }
   }
   if ( $ret eq "FAIL" ) {
      VDSetLastError(VDGetLastError());
      return "FAIL";
   } else {
      return "PASS";
   }
FAIL:
   if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
      $vdLogger->Info("BasicSanity:SnapshotRevertDelete failed");
      VDSetLastError(VDGetLastError());
   }
   return "FAIL";
}

#######################################################################
# CableDisconnect --
#       Implements Disconnect/Reconnect test in the BasicSanity category
#
#       - Find DUT
#       - Get the test bed object
#	- Power on SUT if it is not powered on - paranoid check
#	- Disconnect the cable
#	- sleep 10 seconds
#	- Reconnect the cable
#	- Run netperf and ensure it works
#
# Input:
#       testbed object and testcase hash
#
# Results:
#	PASS if the test succeeds
#	FAIL if any of the steps in the test case fails
#
# Side effects:
#       none
#
########################################################################

sub CableDisconnect
{
   my $testbed = shift;
   my $testcase = shift;
   my $stafIP = undef;
   my ($ret, $VMOpsResult);

   # Implements 2 test cases mentioned in PR531185

   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "$testcase->{VD_PRE} failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         VDSetLastError(VDGetLastError());
         return $ret;
      }
   }
   my $tbRef = $testbed->GetTestbed;
   my %tb = %$tbRef;
   my $vmOpsObj = VDNetLib::VMOperations::VMOperations->new(\%{$tb{'SUT'}});
   $VMOpsResult = "PASS";

   # Get the NetAdapter object of device under test
   my $nicObj = $testcase->{CONNECTION}{Source}{nicObj};
   if (not defined $nicObj) {
      VDSetLastError("ENOTDEF");
      return "FAIL";
   }
   # Set stafIP if needed for VMOpsDisconnectvNICCable()
   $stafIP = $tb{'SUT'}{ip};

   my $mac = $nicObj->GetMACAddress();

   if ($mac eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   #
   # If the test case is "CableDisconnectBeforeDriverLoaded", then reset the VM
   # and disconnect the cable while powering on. The option $stafIP to
   # VMOpsDisconnectvNICCable() method indicates whether it should wait for
   # staf to be running or not inside the guest.
   #
   if ($testcase->{TestName} eq 'CableDisconnectBeforeDriverLoaded') {
      $vdLogger->Info("Restarting the VM $tb{'SUT'}{ip}");
      if ( $vmOpsObj->VMOpsReset() ne SUCCESS ) {
         $vdLogger->Error("VMOperations returned failure");
         VDSetLastError("EINVALID");
         $VMOpsResult = "FAIL";
      }
      $stafIP = undef;
   }
   $vdLogger->Info("Disconnecting test adapter with mac address:$mac");

   if ($vmOpsObj->VMOpsDisconnectvNICCable($mac,$stafIP) ne SUCCESS) {
      $vdLogger->Error( "VMOperations module returned failure".
                         " while disconnecting the cable");
      # TODO: look into possibility of failures from VMOperations
      # and use the right error code
      VDSetLastError(VDGetLastError());
      $VMOpsResult = "FAIL";
   }
   $vdLogger->Info("Waiting for STAF on $tb{'SUT'}{ip} to come up");
   $ret = $testbed->{stafHelper}->WaitForSTAF($tb{'SUT'}{ip});
   if ($ret ne SUCCESS) {
      $vdLogger->Error( "STAF is not running on $tb{'SUT'}{ip}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");
   sleep(20); # link state change is not immediate
   my $linkState;

   $linkState = $nicObj->GetLinkState();
   if ($linkState eq FAILURE) {
      VDSetLastError(VDGetLastError());
      $VMOpsResult = "FAIL";
   }

   if ($linkState ne "Disconnected") {
      $vdLogger->Error( "Unexpected link state:$linkState");
      VDSetLastError("EINVALID");
      $VMOpsResult = "FAIL";
   }

   #
   # Making sure the device is enabled before connecting the cable.
   # Some adapters in linux (e1000, vmxnet3) do not reflect linkstate change if
   # they are disabled.
   #
   if ($nicObj->SetDeviceStatus("UP") eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("Re-connecting test adapter with mac address:$mac");
   if ( $vmOpsObj->VMOpsConnectvNICCable($mac) ne SUCCESS ) {
      $vdLogger->Error( "VMOperations module returned failure".
                         " while connecting the cable");
      # TODO: look into possibility of failures from VMOperations
      # and use the right error code
      VDSetLastError("EINVALID");
      $VMOpsResult = "FAIL";
   }

   sleep(20); # link state change is not immediate

   $linkState = $nicObj->GetLinkState();
   if ($linkState eq FAILURE) {
      VDSetLastError(VDGetLastError());
      $VMOpsResult = "FAIL";
   }

   if ($linkState ne "Connected") {
      $vdLogger->Error( "Unexpected link state:$linkState");
      VDSetLastError("EINVALID");
      $VMOpsResult = "FAIL";
   }

   #
   # Since SUT can go through power cycle during Disconnect operation,
   # we make sure the test device has the ip address assigned to test
   # connectivity
   #
   my $testDeviceIP = $testcase->{CONNECTION}{Source}{nic}{IPv4};

   if (defined $testDeviceIP) {
      # TODO - define a global variable for test network subnet mask
      my $ret = $nicObj->SetIPv4($testDeviceIP, "255.255.255.0");
      if ($ret eq "FAILURE") {
         VDSetError(VDGetLastError());
         return "FAIL";
      }
   } else {
      $vdLogger->Error("Test device IPv4 address undefined");
      VDSetLastError("ENOTDEF");
      return "FAIL";
   }
   #
   # Test connectivity using Ping
   # The system under test might go through a power cycle, in such case,
   # all the test adapters might be enabled (especially in linux). Any traffic
   # sent from SUT to the helper machine does not guarantee the interface being
   # for testing. Therefore, we ping SUT from helper (inbound traffic to SUT)
   # to ensure the test device is being used for checking connectivity.

   # LIMITATIONS:
   # This is a best effort connectivity test. If proxy arp is enabled on SUT,
   # then the arp request can be received by any adapter. In such cases, this
   # test case will not test the connectivity of the actual test device.
   #

   # TODO - ping command is hardcoded here, replace with Ping.pm methods
   my $command;
   my $data;
   $ret = $testbed->{stafHelper}->GetOS($tb{helper1}{ip});
   if ($ret eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   if ($ret =~ /win/i) {
      $command = "ping -n 10 $testDeviceIP";
   } else {
      $command = "ping -c 10 $testDeviceIP";
   }

   $command = STAF::WrapData($command);
   $command = "START SHELL COMMAND $command WAIT RETURNSTDOUT STDERRTOSTDOUT";

   # Run ping command from helper to SUT machine
   ($ret, $data) = $testbed->{stafHelper}->runStafCmd($tb{helper1}{ip},
                                                      "process",
                                                      $command);
   if ($ret eq FAILURE) {
      $vdLogger->Error( "Ping to $tb{SUT}{ip} failed");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }

   #
   # The output of ping command reports X% (packet) loss
   # The following regex captures that.
   #
   if ($data =~ /(\d+)\%.*loss/i) {
      my $loss = $1;
      # Report error if the packet loss is greater than 50%
      if (defined $loss && $loss > "50") {
         $vdLogger->Warn("More than 50% packet loss");
         VDSetLastError("EHOSTUNREACH");
         return "FAIL";
      }
   } else {
      $vdLogger->Warn("Unexpected output from pinging " .
                             "$testDeviceIP:$data");
   }

   return $VMOpsResult;
}

#######################################################################
# DisableEnable --
#       Implements Disable/Enable test in the BasicSanity category
#
#       - Check the connectivity works on DUT
#	- Disable the interface
#	- Run netperf and ensure it fails
#	- Enable the interface
#	- Run netperf and ensure it works
#
# Input:
#       testbed object and testcase hash
#
# Results:
#	PASS if everything goes fine
#	FAIL if any of the above steps in the algorithm fails
#
# Side effects:
#       none
#
########################################################################

sub DisableEnable
{
   my $testbed = shift;
   my $testcase = shift;
   my $ret;
   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "Pre-Processing failed");
         # TODO: we should return abort, do not know whether vet supports
         VDSetLastError(VDGetLastError());
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         VDSetLastError(VDGetLastError());
         return $ret;
      }
   }

   $vdLogger->Info("Checking the connectivity of DUT");
   foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
      # TODO: use Module::Locate to check if a module by name $mod exist
      if ( $mod =~ m/netperf/i ) {
         $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->ClearTestOptions();
         $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->PrependTestOptions("-H $testcase->{CONNECTION}{Destination}{nic}{IPv4}");

         $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->Start();
         $ret = $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client}->GetResult();
         if ( $ret eq "0" ) {
            $vdLogger->Info("Connectivity of DUT works");
         } else {
            $vdLogger->Info("Connectivity of DUT failed: $ret" .
                                " check setup");
            VDSetLastError(VDGetLastError());
            return "FAIL";
         }
      }
   }
   $vdLogger->Info("Disabiling DUT");
   $ret = $testcase->{CONNECTION}{Source}{nicObj}->SetDeviceStatus('DOWN');
   if ( $ret eq FAILURE ) {
      $vdLogger->Warn("FAILED to Disable DUT");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   sleep(30);
   $vdLogger->Info("Run netperf and ensure connectivity fails");
   $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{netperf}{client}->Start();
   $ret = $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{netperf}{client}->GetResult();
   if ( $ret ne "0" ) {
      $vdLogger->Info("Connectivity of DUT failed as expected");
   }
   $vdLogger->Info("Enabiling DUT");
   $ret = $testcase->{CONNECTION}{Source}{nicObj}->SetDeviceStatus('UP');
   if ( $ret eq FAILURE ) {
      # If enabling device fails, there is nothing to cleanup
      # so, after this test, the device will be left in disabled state
      # in this case.
      $vdLogger->Warn("FAILED to Enable DUT");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   sleep(30);
   $vdLogger->Info("Run netperf and ensure connectivity works");
   $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{netperf}{client}->Start();
   $ret = $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{netperf}{client}->GetResult();
   if ( $ret eq "0" ) {
      $vdLogger->Info("Connectivity of DUT passed");
      return "PASS";
   } else {
      $vdLogger->Info("Connectivity of DUT failed: $ret");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
}


########################################################################
# HotAddvNIC --
#       Hot adds a vNIC using VMOperations provided method
#
#       - Check the connectivity works on DUT
#	- Disable the interface
#	- Run netperf and ensure it fails
#	- Enable the interface
#	- Run netperf and ensure it works
#
# Input:
#       testbed object and testcase hash
#
# Results:
#	PASS if everything goes fine
#	FAIL if any of the above steps in the algorithm fails
#
# Side effects:
#       none
#
########################################################################

sub HotAddvNIC
{
   my $testbed = shift;
   my $testcase = shift;
   my $VMOpsResult;
   my ($ret, $mac);

   my $tbRef = $testbed->GetTestbed;
   my %tb = %$tbRef;
   my $vmOpsObj = VDNetLib::VMOperations::VMOperations->new(\%{$tb{'SUT'}});
   $VMOpsResult = "PASS";

   if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE) {
      $vdLogger->Error("VMOperations returned failure");
      VDSetLastError("EINVALID");
      $VMOpsResult = "FAIL";
   }

   my $dut = $testcase->{CONNECTION}{Source}{nic}{DriverName};
   $testcase->{CONNECTION}{Source}{nicObj} = undef;
   my $pg = $testcase->{CONNECTION}{Source}{PortGroup}{Name};
   $vdLogger->Info("Adding $dut on portgroup, $pg");
   ($ret, $mac) = $vmOpsObj->VMOpsHotAddvNIC($dut, $pg);
   if ( $ret eq FAILURE || not defined $mac ) {
      $vdLogger->Error( "HotADDvNIC VMOP failed:\n".
                           VDGetLastError());
      $VMOpsResult = "FAIL";
   }
   $mac = lc($mac);
   $mac =~ s/^\s*//;
   $mac =~ s/\s*$//;
   sleep(60);
   $vdLogger->Info("Waiting for STAF on $tb{'SUT'}{ip} to come up");
   $ret = $testbed->{stafHelper}->WaitForSTAF($tb{'SUT'}{ip});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Error( "STAF is not running on $tb{'SUT'}{ip}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");
   # TODO: for now GetAllAdapters, and find an entry matching the mac
   # macAddress.
   my %hash = (controlIP => $tb{'SUT'}{ip});
   my $hashref = \%hash;
   my $objItem;

   my @result = VDNetLib::NetAdapter::GetAllAdapters($hashref);

   if ($result[0] eq "FAILURE") {
      $vdLogger->Error( "VDNetLib::NetAdapter::GetAllAdapters failed " .
                          VDGetLastError());
      VDSetLastError("EOPFAILED");
      return "FAIL";
   }
   foreach $objItem (@result) {
      if ( ($mac ne "") && (lc($objItem->{macAddress}) =~ /$mac/) ) {
         $testcase->{CONNECTION}{Source}{nicObj} = 
            VDNetLib::NetAdapter->new(%$objItem);
         last;
      }
   }
   if ( not defined $testcase->{CONNECTION}{Source}{nicObj} ) {
      $vdLogger->Error( "Unable to find the interface that was added by ".
                         "VMOperations HotAdd method: $mac");
      VDSetLastError("EOPFAILED");
      return "FAIL";
   }
   $vdLogger->Info("Hot Added succesfully: $mac");
   $vdLogger->Info("Removing the added vNIC: $mac");
   # cleanup, remove the adapter that was added
   ($ret, $mac) = $vmOpsObj->VMOpsHotRemovevNIC($mac);
   if ( $ret  eq FAILURE ) {
      VDSetLastError("EINVALID");
      $vdLogger->Error( "HotRemove VMOP returned failure");
      return "FAIL";
   }
   # invalidate this object as it is removed
   $testcase->{CONNECTION}{Source}{nicObj} = undef;
   return "PASS";
   # TODO: run netperf to check the connectivity of the vNIC later

}

########################################################################
# PowerMgmt --
#       WoL tests
#       # TODO: there are lots of things to improve in this routine
#       # 1. time calculation logic and move to utilities
#       # 2. move most of code into functions and to respective modules
#
#       - Check SUT's vmx file has right entries
#	- Disable the interface
#	- Run netperf and ensure it fails
#	- Enable the interface
#	- Run netperf and ensure it works
#
# Input:
#       testbed object and testcase hash
#
# Results:
#	PASS if everything goes fine
#	FAIL if any of the above steps in the algorithm fails
#
# Side effects:
#       none
#
########################################################################

sub PowerMgmt
{
   my $testbed = shift;
   my $testcase = shift;

   my ($command, $ret, $data);

   my ($vmxFileDir, $vmxFileName);
   my ($dateOnTheHost);
   my ($month0, $date0, $time0);
   my ($vmwareLog, $month1, $date1, $time1);
   my $vmxFile;
   my $tbRef = $testbed->GetTestbed;
   my %tb = %$tbRef;

   # verify vmx file has support required for WoL, if not add it
   my $vmOpsObj = VDNetLib::VMOperations::VMOperations->new(\%{$tb{'SUT'}});

   $vmxFile = VDNetLib::Utilities::GetAbsFileofVMX($tb{SUT}{vmx});

   if ( (not defined $vmxFile) || ($vmxFile eq FAILURE) ) {
      $vdLogger->Error("vmxFile is not defined for $tb{SUT}{host}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }

   my %hash = (controlIP => $tb{'SUT'}{ip});
   my $hashref = \%hash;
   my $driver = $testcase->{CONNECTION}{Source}{nic}{DriverName};
   my @nicList = VDNetLib::NetAdapter::GetAllAdapters($hashref,
                                                      $driver);

   if ($nicList[0] eq FAILURE) {
      $vdLogger->Error("Failed to find $driver device on $tb{SUT}{ip}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }

   # Get the NetAdapter object of device under test
   my $nicObj = VDNetLib::NetAdapter->new(%{$nicList[0]});
   if ($nicObj eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }

   my $mac = $nicObj->GetMACAddress();
   if ($mac eq "FAILURE") {
      $vdLogger->Error("Failed to get MAC address of $tb{SUT}{ip}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }

   my $ethernetX = VDNetLib::Common::Utilities::GetEthUnitNum($tb{SUT}{host},
                                                         $vmxFile, $mac);
   if ($ethernetX eq FAILURE) {
      $vdLogger->Error("Failed to get ethernetX of $tb{SUT}{ip}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my ($standbyStatus, $wakePktStatus);
   my $pattern = "^chipset.onlineStandby";
   $standbyStatus = VDNetLib::Common::Utilities::CheckForPatternInVMX($tb{SUT}{host},
                                                                 $vmxFile,
                                                                 $pattern);
   $pattern = "^$ethernetX.wakeOnPcktRcv";
   $wakePktStatus = VDNetLib::Common::Utilities::CheckForPatternInVMX($tb{SUT}{host},
                                                                 $vmxFile,
                                                                 $pattern);

   if ((defined $standbyStatus) && ($standbyStatus =~ /true/i) &&
       (defined $wakePktStatus) && ($wakePktStatus =~ /true/i)) {
      goto STARTTEST;
   }

   # power off the VM
   $vdLogger->Info("Bringing $tb{SUT}{ip} down to update vmx file"); 
   if ( $vmOpsObj->VMOpsPowerOff() eq FAILURE ) {
      $vdLogger->Error( "Powering off VM failed");
      $vdLogger->Error(Dumper(\%tb));
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   sleep(30);
      $vdLogger->Info("Adding vmx entry chipset.onlineStandby=True");
      $vdLogger->Info("Adding vmx entry $ethernetX.wakeOnPcktRcv=True");
      my @list = ('chipset.onlineStandby = "TRUE"',
                  $ethernetX . '.wakeOnPcktRcv = "TRUE"');
      $ret = VDNetLib::Common::Utilities::UpdateVMX( $tb{SUT}{host},
                                                \@list,
                                                $vmxFile);
      if ( ($ret eq FAILURE) || (not defined $ret) ) {
         $vdLogger->Info("VDNetLib::Common::Utilities::UpdateVMX() " .
                             "failed while update $data");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      }
   # power on the VM
   if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
      $vdLogger->Error( "Powering on VM failed ");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("Waiting for STAF on $tb{'SUT'}{ip} to come up");
   $ret = $testbed->{stafHelper}->WaitForSTAF($tb{'SUT'}{ip});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Info("STAF is not running on $tb{'SUT'}{ip}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");

STARTTEST:
   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "pre-processing routine failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         VDSetLastError(VDGetLastError());
         return $ret;
      }
   }
   # to disable resume password on windows 2003
   # powercfg /GLOBALPOWERFLAG OFF /OPTION RESUMEPASSWORD
   # the above didn't work for Windows 2008
   # C:\Users\Administrator>cmd /c regedit /s screenSaver.reg
   # [HKEY_CURRENT_USER\Cont
   # rol Panel\Desktop] "ScreenSaveIsSecure"=0
   # "ScreenSaveActive"="1"
   # disable hibernation if it is a windows VM
   my $cmd;
   if ( $tb{SUT}{os} =~ /win/i ) {
      $cmd = " /HIBERNATE OFF";
      $cmd = STAF::WrapData($cmd);
      $command = "start shell command powercfg.exe parms $cmd wait ".
              "returnstdout stderrtostdout";
      ($ret, $data) = $testbed->{stafHelper}->runStafCmd($tb{SUT}{ip},
                                                      "process",
                                                      $command);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "Turning off Hiberation on $tb{SUT}{ip} failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      }
      $vdLogger->Info("Turned off Hibernation on $tb{SUT}{ip}");
   }
   # TODO: disable asking for passwd on wake up

   # put the VM into standby mode - is it a good idea to move to VMOps module
   # Can't use runStafCmd, because it might trigger some pkts to the remote
   # host which might wake up the guest
   if ( $tb{SUT}{os} =~ /win/i ) {
      $cmd = '%windir%\System32\rundll32.exe powrprof.dll,SetSuspendState';
   } elsif ( $tb{SUT}{os} =~ /lin/i ) {
      #
      # running sleep command before standby because executing just standby
      # command by the linux guest to sleep immediately and staf hangs awaiting
      # result from the process command.
      #
      $cmd = 'sleep 3;echo "standby" > /sys/power/state';
   }
   $cmd = STAF::WrapData($cmd);
   $command = "start shell command $cmd async";
   $vdLogger->Debug("command: $command ");
   $ret = $testbed->{stafHelper}->{_handle}->submit($tb{SUT}{ip},
                                                      "process",
                                                      $command);
   if ( ($ret->{rc}) != $STAF::kOk ) {
      $vdLogger->Error( "Failed to put $tb{SUT}{ip} in standby mode");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("Guest - $tb{SUT}{ip} has been put into standby mode");

   #
   # The following block verifies whether the guest entered standby mode by
   # pinging to the control adapter (It is assumed that WoL is disabled in the
   # control adapter). Ping to the control adapter should report 100% loss.
   # This verifies whether the guest really entered standby mode and the control
   # adapter does not wake up the guest by any chance.
   #
   # In detail, we ping the control adapter once in every DEFAULT_SLEEP_TIME
   # secs for about STANDBY_TIMEOUT secs. If the loss reported by ping is less
   # than 100% within STANDBY_TIMEOUT time, then we report error saying unable
   # to put the guest to standby. If ping reports 100% (which confirms guest
   # entered standby mode), then we try to wake up the guest using given method
   #
   my $loss = "0";
   my $timeout = STANDBY_TIMEOUT;
   while ($loss < "100" && $timeout > 0) {
      sleep(DEFAULT_SLEEP_TIME);
      $cmd = `ping -c 10 $tb{SUT}{ip}`;
      if ($cmd =~ /(\d+)\%.*loss/i) {
         $loss = $1;
         # Report error if the packet loss is less than 100%
         # Is 100% too strict?
         $vdLogger->Info("Ping to $tb{SUT}{ip} reports $loss% loss");
      }
      $timeout = $timeout - DEFAULT_SLEEP_TIME;
   }

   if ($timeout <= 0) {
      $vdLogger->Error("Expected ping to fail, guest $tb{SUT}{ip} " .
                       "is not in standby-state");
      $vdLogger->Warn("Make sure wake on lan is not enabled on " .
                      "control adapter");
      VDSetLastError("EOPFAILED");
      return "FAIL";
   }

   # Goto to support machine, delete the arp entry for source machine
   # ping the source and see it wakes up again.
   $command = "start shell command arp -d " .
              $testcase->{CONNECTION}{Source}{nic}{IPv4} .
              " wait returnstdout stderrtostdout";
   $vdLogger->Debug("command $command");
   ($ret, $data) = $testbed->{stafHelper}->runStafCmd(
                                                      $testcase->{CONNECTION}{Destination}{IP},
                                                      "process",
                                                      $command);
   if ( $ret eq FAILURE ) {
      $vdLogger->Error("Deleting ARP entry for ".
                       "$testcase->{CONNECTION}{Source}{nic}{IPv4} on".
                       "$testcase->{CONNECTION}{Destination}{IP} failed");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   if ( $testcase->{TestName} =~ /WakeOnPktRcv/i ) {
      $vdLogger->Info("Waking up the guest using ARP packet");
      if ( $tb{helper1}{os} =~ /lin/i ) {
         $cmd = "ping -c 4";
      } else {
         $cmd = "ping";
      }
      $command = "start shell command $cmd ".
              "$testcase->{CONNECTION}{Source}{nic}{IPv4}".
              " wait returnstdout stderrtostdout";
      $vdLogger->Debug("command $command");
      ($ret, $data) = $testbed->{stafHelper}->runStafCmd(
                                       $testcase->{CONNECTION}{Destination}{IP},
                                       "process",
                                       $command);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "pinging $testcase->{CONNECTION}{Source}{IP} from".
                         "$testcase->{CONNECTION}{Destination}{IP} failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      }
   } elsif ( $testcase->{TestName} =~ /WoLMagicPktRcv/i ) {
      $vdLogger->Info("Waking up the guest using Magic packet");
      my $broadcastAddr = $testcase->{CONNECTION}{Source}{nic}{IPv4};
      $broadcastAddr =~ s/\d+$/255/;
      my $args = $broadcastAddr . "," .
                 $testcase->{CONNECTION}{Source}{nic}{macAddress};
      $ret = VDNetLib::LocalAgent::ExecuteRemoteMethod(
                                   $testcase->{CONNECTION}{Destination}{IP},
                                   "SendMagicPkt",
                                   $args);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "Sending magic packet to ".
                         "$testcase->{CONNECTION}{Source}{nic}{IPv4} from ".
                         "$testcase->{CONNECTION}{Destination}{IP} failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      }
   }
   sleep(20);
   $cmd = `ping -c 10 $tb{SUT}{ip}`;
   if ($cmd =~ /(\d+)\%.*loss/i) {
      my $loss = $1;
      $vdLogger->Info("Ping to $tb{SUT}{ip} reports $loss percentage loss");
      # Report error if the packet loss is greater than 25%
      if (defined $loss && $loss > "25") {
         $vdLogger->Warn("Less than 25\% failure expected from ping command");
         VDSetLastError("EOPFAILED");
         goto FAIL;
      }
   } else {
      $vdLogger->Error("Unexpected output from Ping command:$cmd");
      VDSetLastError("EOPFAILED");
      return "FAIL";
   }

   return "PASS";

FAIL:
   if ($vmOpsObj->VMOpsReset() eq FAILURE) {
      $vdLogger->Error("VM reset returned failure");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("Waiting for STAF to come up");
   $ret = $testbed->{stafHelper}->WaitForSTAF($tb{'SUT'}{ip});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Info("STAF is not running on $tb{'SUT'}{ip}");
      VDSetLastError(VDGetLastError());
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");
   VDSetLastError(VDGetLastError());
   return "FAIL";
}

1;
