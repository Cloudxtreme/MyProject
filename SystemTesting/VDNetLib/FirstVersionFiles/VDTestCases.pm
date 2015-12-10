########################################################################
# Copyright (C) 2009 VMWare, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VDTestCases;

########################################################################
# This module contains entry point to all test cases in TDS
########################################################################

#########################
# Load required Modules #
#########################
use FindBin;
use lib "$FindBin::Bin/../";
use VDNetLib::VDCommonSrvs;
use strict;
use warnings;
use Data::Dumper;
use VDNetLib::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);
use VDNetLib::PacketCapture;
use VDNetLib::GlobalConfig qw($vdLogger);
use VDNetLib::Utilities;
use File::Basename;

BEGIN {
      eval "use VDNetLib::VMOperations::VMOperations";
}

########################################################################
# DataTrafficController --
#       This can be used as entry point for all tests that has traffic work
#       loads
#
# Input:
#       Testbed object
#       testcase hash
#
# Results:
#      PASS in case of no erorrs
#      FAIL in case of any errors
#
# Side effetcs:
#       none
#
########################################################################

sub DataTrafficController
{
   my $testbed = shift;
   my $testcase = shift;

   my $ret;

   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "Pre-processing routine failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         return $ret;
      }
   }
   # Declare variables
   my ($hostobj, $result);
   my ($VMOpsResult, $i);
   my $count = 0;

   # Get Testbed object reference
   my $tbRef = $testbed->GetTestbed;
   my %tb = %$tbRef;
   my $vmOpsObj = VDNetLib::VMOperations::VMOperations->new(\%{$tb{'SUT'}});

   if ($vmOpsObj eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Collect IP address or host and vms
   my $vmip = $tb{SUT}{ip};
   my $hostip = $tb{SUT}{host};
   my $helperip = $tb{helper1}{ip};
   # Create Host operations object
   $hostobj = VDNetLib::HostOperations->new("$hostip");

   if ($hostobj eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Define Stress option variables
   my $optSize;
   my $valSize;
   my @stressOption;
   my @stressValue;
   # If defined Stress options in TDS hash then proceed for enabling/Disabling stress options.
   if ( defined $testcase->{WORKLOADS}{STRESS} ) {
   # Enable stress options on host
   ## If defined dataset for stress take values from npfunc
    my @testData = @{$testcase->{Stress}};
   $i=0;
   # Assign the stress option & value from npfunc
   foreach my $mod (@testData) {
     my @option = split (/ /, $mod);
     # Get stress parameters from npfunc
     $stressOption[$i] = $option[0];
     $stressValue[$i] = $option[1];
    $i++;
   }

   $optSize = @stressOption;
   $valSize = @stressValue;
   # Verify that Each option got a value
   if ($optSize != $valSize) {
      $vdLogger->Info("Only matched options will be enabled");
   }

   # Enable stress options on host
   for ($i = 0; $i < $optSize;$i++) {
      if (defined $stressOption[$i] and defined $stressValue[$i]) {
          $vdLogger->Info("Setting $stressOption[$i] on host\n");
          $result = $hostobj->HostStress("Enable",
                                         "$stressOption[$i]",
                                         "$stressValue[$i]");
          if ($result eq "FAILURE") {
             $vdLogger->Info("Failed to enable".
                                 " stress option\n");
             $vdLogger->Error("Failed to set the stress option on host");
             VDSetLastError(VDGetLastError());
             return FAILURE;
          }
      } else {
         last;
      }
   }
 }

   # for each module mentioned, start the module, if the scope is per index
   # do the verification procedure for every iteration
   # all the primary keys of $testcase->{MODULES} point to standard modules
   # like VDNetLib::Netperf.pm.
   foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
      # TODO: use Module::Locate to check if a module by name $mod exist
      if ( $mod =~ m/netperf/i ) {
         $ret = VDNetLib::VDCommonSrvs::NetperfWorkload($testbed, $testcase);
      }
   }


   # Unconfig the previous configured stress options.
   if ( defined $testcase->{WORKLOADS}{STRESS} ) {

   # Disable stress options on host
   for ($i = 0; $i < $optSize;$i++) {
      if (defined $stressOption[$i] and defined $stressValue[$i]) {
          $vdLogger->Info("Setting $stressOption[$i] on host\n");
          $result = $hostobj->HostStress("Disable",
                                         "$stressOption[$i]",
                                         "$stressValue[$i]");
          if ($result eq "FAILURE") {
             $vdLogger->Info(" Failed to Disable".
                                 " stress option\n");
             $vdLogger->Error("Failed to Disable the stress option on host");
             VDSetLastError(VDGetLastError());
             return FAILURE;
          }
      } else {
         last;
      }
   }
 }


   return $ret;

}

########################################################################
# LoadUnloadController --
#       This can be used as entry point for all tests that has
#       to load/unload the driver while netperf running
#
# Input:
#       Testbed object
#       testcase hash
#
# Results:
#      PASS in case of no erorrs
#      FAIL in case of any errors
#
# Side effetcs:
#       none
#
########################################################################

sub LoadUnloadController
{
   my $testbed = shift;
   my $testcase = shift;

   my $ret;

   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "pre-processing routine failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         return $ret;
      }
   }

   # for each module mentioned, start the module, if the scope is per index
   # do the verification procedure for every iteration
   # all the primary keys of $testcase->{MODULES} point to standard modules
   # like VDNetLib::Netperf.pm.
   foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
      # TODO: use Module::Locate to check if a module by name $mod exist
      if ( $mod =~ m/netperf/i ) {
         $ret = VDNetLib::VDCommonSrvs::NetperfLoadUnload($testbed, $testcase);
         last;
      }
   }
   return $ret;
}
########################################################################
# TxRxConfigTests --
#        This routine implements Tx and Rx test cases that involves running
#        network traffic between system under test and helper machine after
#        changing one of the following properties:
#        Tx ring size, Tx queues, Rx small/large buffer space, Rx ring size
#        and Rx queues.
#
# Input:
#        vdNet test case hash and testbed hash
#
# Output:
#       "PASS", if the test case is executed successfully
#       "FAIL", in case of any error
#
# Side effects:
#       none
########################################################################

sub TxRxConfigTests
{
   my $testbed = shift;
   my $testcase = shift;

   my $ret;

   # Create the list of supported ring sizes, rx buffer sizes, queues

   my @ringSize = (32,64,128,256,512,1024,2048,4096);
   my @queues = (1,2,4,8);
   my @rxBuffer = (64,128,256,512,1024,1536,2048,3072,4096,8192);
   my ($method, $type, @values);
   my $test = $testcase->{TestName};
   $vdLogger->Info("Running TxRx Test Name:$test");

   if (($testbed->GetSUTOS() =~ /linux/i) &&
       (($test !~ /RxRing1/i) || ($test !~ /TxRing/i))) {
      $vdLogger->Error( "This test - $test not applicable on linux");
      VDSetLastError("EOPNOTSUP");
      return "FAIL";
   }

   if ($testcase->{CONNECTION}{Source}{nic}{DriverName} !~ /vmxnet3/i) {
      $vdLogger->Error(
               "$test test not supported on devices other than vmxnet3");
      VDSetLastError("EOPNOTSUP");
      return "FAIL";
   }

   # Based on the test case name given, select the appropriate method in
   # NetAdapter
   #
   if ($test =~ /TxQueues/i) {
      $method = "SetMaxTxRxQueues";
      $type = "Tx";
      @values = @queues;
   } elsif ($test =~ /RxQueues/i) {
      $method = "SetMaxTxRxQueues";
      $type = "Rx";
      @values = @queues;
   } elsif ($test =~ /SmallRxBuffers/i) {
      $method = "SetRxBuffers";
      $type = "small";
      @values = @rxBuffer;
   } elsif ($test =~ /LargeRxBuffers/i) {
      $method = "SetRxBuffers";
      $type = "large";
      @values = @rxBuffer;
   } elsif ($test =~ /TxRing/i) {
      $method = "SetRingSize";
      $type = "Tx";
      @values = @ringSize;
   } elsif ($test =~ /RxRing1/i) {
      $method = "SetRingSize";
      $type = "Rx1";
      @values = @ringSize;
   } elsif ($test =~ /RxRing2/i) {
      $method = "SetRingSize";
      $type = "Rx2";
      @values = @ringSize;
   } else {
      $vdLogger->Error( "Unknown Tx-Rx test specified");
      VDSetLastError("EINVALID");
      return "FAIL";
   }

   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "pre-processing routine failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         return $ret;
      }
   }

   my $nic;
   foreach my $testValue (@values) {
      $vdLogger->Info("Configuring $test with a value $testValue");
      $nic = $testcase->{CONNECTION}{Source}{nicObj};
      $ret = $nic->$method($type, $testValue);
      if ($ret eq "FAILURE") {
         $vdLogger->Error( "Set $method operation failed");
         VDSetLastError(VDGetLastError());
         return "FAIL";
      }

      # for each module mentioned, start the module, if the scope is per index
      # do the verification procedure for every iteration
      # all the primary keys of $testcase->{MODULES} point to standard modules
      # like VDNetLib::Netperf.pm.
      foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
         # TODO: use Module::Locate to check if a module by name $mod exist
         if ( $mod =~ m/netperf/i ) {
            $ret = VDNetLib::VDCommonSrvs::NetperfWorkload($testbed, $testcase);
         }
         if ($ret !~ /PASS/i) {
            $vdLogger->Error( "Netperf failed");
            VDSetLastError("EOPFAILED");
            return "FAIL";
         }
      }
      if ( defined $testcase->{VERIFICATION}{TCPDUMP} ) {
         if (&VDNetLib::VDCommonSrvs::VdPreTcpdumpSetup($testbed, $testcase) eq
                             FAILURE) {
            $vdLogger->Error( "TCPDUMP setup failed");
            return "FAIL";
         }
      }
   }
   return $ret;
}

#######################################################################
#  InterruptProcessing --
#       This can be used as entry point for all tests involving
#       interrupt mode operations.
#       Following tasks are planned:
#       1. If OS is windows, edit appropriate registry entries
#       2. Get Mac of adapter and eth name of the adapter
#       3. Powering off the VM
#       4. Edit the vmx file for required configuration
#       5. poweron the vm
#       6. Get vsi PortNumber for mac address and verify the
#          vsish status for mask information.
#       7. For linux verify the type of interrupt. for windows
#          there is no proper verification method, so verify
#          vmware.log.
#       8. Power off the VM.
#       9. Normalise the vmx entry.
#      10. power on the vm
#
#      The Automode and Active Mode has following interrupt codes
#      ===================================================
#               AutoMode      ActiveMode
#      ===================================================
#      INTX        1                5
#      MSI         2                6
#      MSI-x       3                7
#      ===================================================
#
# Input:
#       Testbed object
#       testcase hash
#
# Results:
#      PASS in case of no erorrs
#      FAIL in case of any errors
#
# Side effetcs:
#       none
#######################################################################

sub InterruptProcessing
{
   my $testbed = shift;
   my $testcase = shift;
   my $ret = "PASS";
   my ($command, $data, $debug, $data1);
   my @suffixlist = ("vmx","log");


   my $tbRef = $testbed->GetTestbed;
   my %tb = %$tbRef;

   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "pre-processing routine failed");
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      } elsif ( $ret eq "FAIL" ) {
         return $ret;
      }
   }

   #
   # Section for following tasks:
   #     1. If OS is windows, edit appropriate registry entries
   #     2. Get Mac of adapter and eth name of the adapter
   #     3. Powering off the VM
   #     4. Edit the vmx file for required configuration
   #     5. poweron the vm
   #     5. Get vsi PortNumber for mac address and verify the
   #        vsish status for mask information.
   #     6. For linux verify the type of interrupt. for windows
   #        there is no proper verification method, so verify
   #        vmware.log.
   #     7. Power off the VM.
   #     8. Normalise the vmx entry.
   #     9. power on the vm
   #
   # The Automode and Active Mode has following interrupt codes
   #===================================================
   #               AutoMode      ActiveMode
   #===================================================
   #    INTX          1                5
   #    MSI           2                6
   #    MSI-x         3                7
   #===================================================

   if (defined $testcase->{CONNECTION}{Source}{nic}{INTR}) {
       # This Section Covers the interrupt mode configuration
       # and Initial verification

       # Create object of VDNetLib::GlobalConfig
       my $gc = VDNetLib::GlobalConfig->new();

       # Collect test parameters
       my $srcControlIP = $testcase->{CONNECTION}{Source}{IP};
       my $srcTestIP = $testcase->{CONNECTION}{Source}{nic}{IPv4};
       my $srcHostIP = $testbed->{testbed}{SUT}{host};
       my $sutOS = $testbed->GetSUTOS;
       my $vmxfile = VDNetLib::Utilities::GetAbsFileofVMX($tb{SUT}{vmx});
       my $srcMac = $testcase->{CONNECTION}{Source}{nic}{macAddress};
       my $srcvSwitch = $testcase->{CONNECTION}{Source}{vSwitch}{Name};
       my $ethUnit = VDNetLib::Common::Utilities::GetEthUnitNum($srcHostIP,
                                                           $vmxfile,
                                                           $srcMac);

       $vdLogger->Debug("Eth Unit Number is $ethUnit and mac is $srcMac " . 
                        "and vmx file is $vmxfile");

       # Collect the directory name from vmxfile name
       my ($name,$path,$suffix) = fileparse($vmxfile,@suffixlist);
       my $vmwarelog = "$path"."vmware.log";

       # Parameters required for the test
       my $modeValue = $testcase->{CONNECTION}{Source}{nic}{INTR};

       if ($modeValue !~ /AUTO-INTX|AUTO-MSI|AUTO-MSIX/ and
           $modeValue !~ /ACTIVE-INTX|ACTIVE-MSI|ACTIVE-MSIX/) {
          $vdLogger->Error("Invalid Interrupt mode supplied ");
          VDSetLastError("EINVALID");
          return FAILURE;
       }

       $ethUnit =~ /(\d+)$/;
       my $modeNum = $1;
       my $modeString = $gc->GetInterruptString($modeValue);
       $modeString = "$modeString"."$modeNum" if defined $modeNum;
       $modeValue = $gc->GetInterruptMode($modeValue);


       # Set the registry keys if Source adapter os is
       # windows. We can either modify the inf file or
       # do away with registry key settings. But after
       # setting the registry key make sure to power
       # cycle the vm for the keys to take effect.
       if ($sutOS =~ /win/) {
          # query to see if the keys DisableAutoMask, DisableMSI
          # and DisableMSI-x are available, if not add them
          ($ret, $data) = ConfigureIntKey($srcControlIP,
                                          $testbed->{stafHelper},
                                          "query");


          if ($ret eq "FAILURE") {
              $vdLogger->Error("Failed to obtain the registry key information");
              VDSetLastError("EFAIL");
              return FAILURE;
          }

          if (not defined $data) {
             $data = "";
          }

          # Check if DisabelAutoMask registry key exists, if not
          # create/add it
          if ($data !~  /DisableAutoMask/) {
             # Add the registry key - DisableAutoMask
             ($ret, $data1) = ConfigureIntKey($srcControlIP,
                                              $testbed->{stafHelper},
                                              "add",
                                              "DisableAutoMask");

             # Check for errors
             if ($ret eq "FAILURE") {
                $vdLogger->Error("Failed to set the registry key DisableAutoMask");
                VDSetLastError("EFAIL");
                return FAILURE;
             }
          }

          # Check if DisabelMSI registry key exists, if not
          # create/add it
          if ($data !~  /DisableMSI/) {
             # Add the registry key - DisableMSI
             ($ret, $data1) = ConfigureIntKey($srcControlIP,
                                              $testbed->{stafHelper},
                                              "add",
                                              "DisableMSI");
             # Check for errors
             if ($ret eq "FAILURE") {
                $vdLogger->Error("Failed to set the registry key DisableMSI");
                VDSetLastError("EFAIL");
                return FAILURE;
             }
          }

          # Check if DisabelMSI-x registry key exists, if not
          # create/add it
          if ($data !~  /DisableMSI-x/) {
             # Add the registry key - DisableMSI-x
             ($ret, $data1) = ConfigureIntKey($srcControlIP,
                                              $testbed->{stafHelper},
                                              "add",
                                              "DisableMSI-x");
             # Check for errors
             if ($ret eq "FAILURE") {
                $vdLogger->Error("Failed to set the registry key DisableMSI-x");
                VDSetLastError("EFAIL");
                return FAILURE;
             }
          }

          # modeValue less than 4 indicates auto mode and greater than
          # 4 indicates active mode
          if ($modeValue < 4) {
             # DisableAutoMask to be set to 1
             ($ret, $data) = ConfigureIntKey($srcControlIP,
                                             $testbed->{stafHelper},
                                             "unset",
                                             "DisableAutoMask");

          } else {
             # DisableAutoMask to be set to 0
             ($ret, $data) = ConfigureIntKey($srcControlIP,
                                             $testbed->{stafHelper},
                                             "set",
                                             "DisableAutoMask");
          }

          # Check for error in previous command.
          if ($ret eq "FAILURE") {
             $vdLogger->Error("Failed to configure the registry key DisableAutoMask");
             VDSetLastError("EFAIL");
             return FAILURE;
          }

          # If interrupt mode to be set is INTX, set disable MSI
          # and MSI-x registry keys
          if ($modeValue == 1 or $modeValue == 5) {
              # Unet - DisableMSI
              ($ret, $data) = ConfigureIntKey($srcControlIP,
                                              $testbed->{stafHelper},
                                              "unset",
                                              "DisableMSI");

              if ($ret eq "FAILURE") {
                  $vdLogger->Error("Failed to configure the registry key DisableMSI");
                  VDSetLastError("EFAIL");
                  return FAILURE;
              }

              # Unset - DisableMSI-x
              ($ret, $data) = ConfigureIntKey($srcControlIP,
                                              $testbed->{stafHelper},
                                              "unset",
                                              "DisableMSI-x");

              # Check for failures
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key DisableMSI-x");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }
          } elsif ($modeValue == 2 or $modeValue == 6) {
              # If interrupt mode to be set is MSI, set enable MSI
              # and disable MSI-x registry keys

              # set the registry key - DisableMSI
              ($ret, $data) = ConfigureIntKey($srcControlIP,
                                              $testbed->{stafHelper},
                                              "set",
                                              "DisableMSI");

              # Check for erros
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key DisableMSI");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }

              # Unset - DisableMSI-x
              ($ret, $data) = ConfigureIntKey($srcControlIP,
                                              $testbed->{stafHelper},
                                              "unset",
                                              "DisableMSI-x");
              # Check for errors
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key DisableMSI-x");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }

          } elsif ($modeValue == 3 or $modeValue == 7) {
              # If interrupt mode to be set is MSIx, set disable MSI
              # and enable MSI-x registry keys

              # set the registry key - DisableMSI-x
              ($ret, $data) = ConfigureIntKey($srcControlIP,
                                              $testbed->{stafHelper},
                                              "set",
                                              "DisableMSI-x");
              # Check for errors
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key DisableMSI-x");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }

              # Unset - DisableMSI
              ($ret, $data) = ConfigureIntKey($srcControlIP,
                                              $testbed->{stafHelper},
                                              "unset",
                                              "DisableMSI");
              # Check for errors
              if ($ret eq "FAILURE") {
                 $vdLogger->Error("Failed to configure the registry key DisableMSI-x");
                 VDSetLastError("EFAIL");
                 return FAILURE;
              }
          }
       }

       # Create an object of VMOps and power off the VM
       my $vmOpsObj = VDNetLib::VMOperations::VMOperations->new(\%{$tb{SUT}});
       $vdLogger->Info("Powering off the VM");
       if ( $vmOpsObj->VMOpsPowerOff() eq FAILURE ) {
          $vdLogger->Error("VM poweroff returned failed");
          VDSetLastError("EINVALID");
          return "FAIL";
       }

       sleep(15);

       # build a command for deleting an vmx entry
       # The EditFile method defined in VDNetLib::Utilities module
       # takes in few arguments such as task to either add
       # an entry into file, delete an entry from file or
       # modify an entry from file. Also provides task for
       # querying the entry from file. In the following we
       # are deleting an entry named ethernetx.intrMode = "Y"
       # from vmx file for the given mac address. X indicates
       # ethUnit number and Y indicates the interrupt mode.
       my ($line, $arg);
       $line = "$ethUnit"."\."."intrMode"." = ";
       $arg = "$vmxfile"."\*"."'delete'"."\*"."$line";
       $vdLogger->Info("Editing a VMX file for reseting interrupt".
                           " mode if set earlier");

       $ret = VDNetLib::Utilities::ExecuteMethod($srcHostIP,
                                                 "EditFile",
                                                 "'$arg'");

       # Here return value of the above command is not
       # taken care.

       # Build command for an vmx entry
       $line = "$ethUnit"."\."."intrMode"." = \\\"$modeValue\\\"";
       $arg = "$vmxfile"."\*"."'insert'"."\*"."$line";
       $vdLogger->Info("Editing a VMX file for interrupt mode");
       $ret = VDNetLib::Utilities::ExecuteMethod($srcHostIP,
                                                 "EditFile",
                                                 "'$arg'");


       # Power on the VM
       $vdLogger->Info("Powering on the VM");
       if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
          $vdLogger->Error("VM poweron returned failed");
          VDSetLastError("EINVALID");
          return "FAIL";
       }

       # Check for staf to come up
       $vdLogger->Info(
                "Waiting for STAF on $tb{SUT}{ip} to come up");
       $ret = $testbed->{stafHelper}->WaitForSTAF($tb{SUT}{ip});
       if ( $ret ne SUCCESS ) {
           $vdLogger->Info("STAF is not running on $tb{SUT}{ip}");
           return "FAIL";
       }
       $vdLogger->Info("STAF on $tb{SUT}{ip} came up");

       sleep(200);

       # Create an object of hostoperations module to obtain the
       # vsi node number for mac address to verify automode value
       # to verify that interrupt mode is set correctly
       my $hostObj = VDNetLib::HostOperations->new("$srcHostIP");
       my $hash = $hostObj->GetVSINodeStatFromMAC("$srcMac");
       my $vsiNode = $hash->{portnum};

       # Following commands will get the vsi node status for interrupt
       # mode being in auto mode or active mode.The output looks like:
       # intr stats of a vmxnet3 vNIC {
       #    autoMask:1
       #    intr stats:stats of the individual intr {
       #       actions posted:23
       #       actions posted with hint:0
       #       actions avoided:2
       #    }
       # }
       #
       # Here autoMask: 1 indicates that auto mode of interrupt is set
       # Here autoMask: 0 indicates that active mode of interrupt is set
       $command = "vsish -e get".
           " /net/portsets/$srcvSwitch/ports/$vsiNode/vmxnet3/intrSummary";
       $command = "start shell command $command".
                  " wait returnstdout returnstderr";
       ($ret, $data) = $testbed->{stafHelper}->runStafCmd($srcHostIP,
                                                          "Process",
                                                          "$command");

       # check for success or failure of the command
       if ($ret eq "FAILURE" or $data eq "") {
           $vdLogger->Error("Failed to obtain the interrupt mode summary");
           VDSetLastError("EFAIL");
           return FAILURE;
       }

       # First level verification for correct interrupt mode
       $data =~ /autoMask:(\d+)/;
       my $mask = $1;

       # Check for Auto Masking interrupt mode
       if ($modeValue < 4 and $mask eq "1") {
           $vdLogger->Info("Interrupt Mode auto mask is set correctly");
       } elsif ($modeValue > 4 and $mask eq "0") {
           # Check for Active Masking interrupt mode
           $vdLogger->Info("Interrupt Mode active mask is set correctly");
       } else {
           # Check for errors
           $vdLogger->Info("Failed to set correct Interrupt Mode mask");
           VDSetLastError("EFAIL");
           return FAILURE;
       }

       # Verify the results for linux OS
       if ($sutOS =~ /lin/i) {
           # Following commands will get the vsi node status for interrupt
           # mode being in auto mode or active mode.
           $command = "cat /proc/interrupts";
           $command = "start shell command $command".
                    " wait returnstdout returnstderr";
           ($ret, $data) = $testbed->{stafHelper}->runStafCmd($srcControlIP,
                                                              "Process",
                                                              $command);

           if ($data =~ /$modeString/) {
              $vdLogger->Info("Interrupt Mode verified and".
                                  " is set correctly");
              $ret = "PASS";
           } else {
              $vdLogger->Error("Failed to verify the interrupt mode");
              $ret = "FAIL";
           }
       } else {
           # Verify the results for windows OS

           # As there is no exact check in windows for interrupt mode
           # added a check to confirm the interrupt mode setting through
           # vmware.log content. (This check can be adopted to linux vm).
           $line = "$ethUnit"."\.intrMode"." = ";
           $command = "grep 'intrMode' $vmwarelog";
           $command = "start shell command $command".
                    " wait returnstdout returnstderr";

           ($ret, $data) = $testbed->{stafHelper}->runStafCmd($srcHostIP,
                                                              "Process",
                                                              "$command");

           # check for success or failure of the command
           if ($ret eq "FAILURE" or $data !~ "$line") {
              $vdLogger->Error("Failed to obtain interrupt mode info".
                           " from vmware log");
              VDSetLastError("EFAIL");
              return FAILURE;
           }
       }

       # for each module mentioned, start the module, if the scope is per index
       # do the verification procedure for every iteration
       # all the primary keys of $testcase->{MODULES} point to standard modules
       # like VDNetLib::Netperf.pm.
       my $ret1;
       foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
          # TODO: use Module::Locate to check if a module by name $mod exist
          if ( $mod =~ m/netperf/i ) {
             $ret1 = VDNetLib::VDCommonSrvs::NetperfWorkload($testbed, $testcase);
          }

          if ( $mod =~ m/ping/i ) {
             $ret1 = VDNetLib::VDCommonSrvs::PingWorkload($testbed, $testcase);
          }

          if ( $mod =~ m/iperf/i ) {
             $ret1 = VDNetLib::VDCommonSrvs::IperfWorkload($testbed, $testcase);
          }
       }

       # Following Section is not test candition, but normalisation
       # steps. Though test passes, and if normalisation steps fail
       # results are reported as fail. Either these steps need to be
       # carried out without considering their outcome to deciding the
       # success or failure of the test
       $vdLogger->Info("Powering off the VM after verification of".
                           " interrupt mode");
       if ( $vmOpsObj->VMOpsPowerOff() eq FAILURE ) {
          $vdLogger->Error("VM poweroff returned failed");
          VDSetLastError("EINVALID");
          return "FAIL";
       }

       # Build command for deleting entry from vmx as a step
       # for normalisation
       $line = "$ethUnit"."\."."intrMode"." = \\\"$modeValue\\\"";
       $arg = "$vmxfile"."\*"."'delete'"."\*"."$line";
       $vdLogger->Info("Editing a VMX file for reverting interrupt mode");
       $ret = VDNetLib::Utilities::ExecuteMethod($srcHostIP,
                                                 "EditFile",
                                                 "'$arg'");

       # Power on the VM as a step for test normalisation
       $vdLogger->Info("Powering on the VM");
       if ( $vmOpsObj->VMOpsPowerOn() eq FAILURE ) {
          $vdLogger->Error("VM poweron returned failed");
          VDSetLastError("EINVALID");
          return "FAIL";
       }

       # Check for staf to come up
       $vdLogger->Info(
                "Waiting for STAF on $tb{SUT}{ip} to come up");
       $ret = $testbed->{stafHelper}->WaitForSTAF($tb{SUT}{ip});
       if ( $ret ne SUCCESS ) {
           $vdLogger->Info("STAF is not running on $tb{SUT}{ip}");
           return "FAIL";
       }
       $vdLogger->Info("STAF on $tb{SUT}{ip} came up");

       # return Success or failure
       if ($ret =~ /fail/i or $ret1 =~ /fail/i) {
          return "FAIL";
       } else {
          return "PASS";
       }
   } else {
      $vdLogger->Error("No Interrupt mode mentioned in testcase hash");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
}

########################################################################
#  ConfigureIntKey --
#       This method can be used for configuring interrupt mode key for
#       windows.(DisableAutoMask, DisableMSI and DisableMSI-x are the
#       keys.)
#
# Input:
#       IP Address
#       Staf Handle
#       Key name
#       Task (one of set/enable, unset/disable,delete/remove and add)
#
# Results:
#      SUCCESS and data in case of no Success
#      FAILURE in case of any failures
#
# Side effetcs:
#       Modifies the registry setting on windows vm
#
# Note: OS verification is not done, assuming awareness of user
########################################################################

sub ConfigureIntKey
{
   my $ip = shift;
   my $handle = shift;
   my $task = shift;
   my $key = shift;

   my ($command, $res, $data);

   # Check for non empty inputs.
   if ($task eq "" or $handle eq "" or $ip eq "") {
      $vdLogger->Error("Invalid parameter supplied to ConfigureIntKey ");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Check if task is simple query. For query the key
   # is not required. If task is other than query then
   # check if key is one among DisableAutoMask or DisableMSI
   # or DisableMSI-x
   if ($task !~ /query/) {
      if ($key !~ /DisableAutoMask|DisableMSI|DisableMSI-x/i) {
         $vdLogger->Error("Invalid Key name supplied");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   if ($task =~ /set|enable/i) {
      # Edit the registry key - set to 0 (Setting 0 would cause the
      # Disable keys to enable them)
      $command = "reg add \"HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001".
                 "\\Services\\vmxnet3ndis5\\Parameters\" ".
                 "/v $key /t REG_DWORD /d 0x00000000 /f";
   } elsif ($task =~ /unset|disable|add/i) {
      # Edit the registry key - set to 1 (Setting 1 would cause the
      # Disable keys to be in Disabled State)
      $command = "reg add \"HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001".
                 "\\Services\\vmxnet3ndis5\\Parameters\" ".
                 "/v $key /t REG_DWORD /d 0x00000001 /f";
   } elsif ($task =~ /delete|remove/i) {
      # Remove the registry key
      $command = "reg delete \"HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001".
                 "\\Services\\vmxnet3ndis5\\Parameters\" ".
                 "/v $key /f";
   } elsif ($task =~ /query/i) {
      # query the registry keys - DisableAutoMask/DisableMSI/DisableMSI-x
      $command = "reg query \"HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001".
                 "\\Services\\vmxnet3ndis5\\Parameters\"";
   } else {
      $vdLogger->Error("Invalid task mentioned");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Construct the command
   $command = "start shell command $command".
              " wait returnstdout returnstderr";
   ($res, $data) = $handle->runStafCmd($ip,
                                       "Process",
                                       "$command");

   # Check for errors
   if ($res eq "FAILURE") {
      $vdLogger->Error("Failed to configure the registry key DisableAutoMask");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return (SUCCESS, $data);
}
############################################################################
# StressOpsController  --
#   Implements enabling stress options and VM operations as per TDS HASH
#
#       - Power on the SUT if it is not ON
#       - Suspend the VM, Resume the VM.
#       - Wait for the STAF to come up on the SUT
#  - Find DUT
#  - Enable stress options if defined
#  - Run netperf and ensure it works
#
# Input:
#       testbed object and testcase hash
#
# Results:
#  PASS if the test succeeds
#  FAIL if any of the steps in the test case fails
#
# Side effects:
#       none
#
########################################################################
sub StressOpsController
{
   my $testbed = shift;
   my $testcase = shift;
   # Declare variables
   my ($hostobj, $result, $i);
   my $count = 0;
   my ($ret, $VMOpsResult);
   my $tbRef = $testbed->GetTestbed;
   my %tb = %$tbRef;
   my $vmOpsObj = VDNetLib::VMOperations::VMOperations->new(\%{$tb{'SUT'}});
   # Collect IP address or host and vms 
   my $vmip = $tb{SUT}{ip};
   my $hostip = $tb{SUT}{host};
   my $helperip = $tb{helper1}{ip};
   # Create Host operations object
   $hostobj = VDNetLib::HostOperations->new("$hostip");
   # Define Stress option variables
   my ($optSize, $valSize, @stressOption ,@stressValue);

   # If defined Stress options in TDS hash then proceed for enabling/Disabling
   # stress options.
   if ( defined $testcase->{WORKLOADS}{STRESS} ) {
       # Enable stress options on host
       ## If defined dataset for stress take values from npfunc
       my @testData = @{$testcase->{Stress}};
       $i=0;
      
        # Assign the stress option & value from npfunc
       foreach my $mod (@testData) {
         my @option = split ( / /, $mod);
         # Get stress parameters from npfunc
         $stressOption[$i] = $option[0];
         $stressValue[$i] = $option[1];
         $i++;
       }

       $optSize = @stressOption;
       $valSize = @stressValue;
       # Verify that Each option got a value
       if ($optSize != $valSize) {
          $vdLogger->Info("Only matched options will be enabled");
          }

        # Enable stress options on host
        for ($i = 0; $i < $optSize;$i++) {
            if (defined $stressOption[$i] and defined $stressValue[$i]) {
                $vdLogger->Info("Setting $stressOption[$i] on host\n");
                $result = $hostobj->HostStress("Enable",
                                         "$stressOption[$i]",
                                         "$stressValue[$i]");
                if ($result eq "FAILURE") {
                   $vdLogger->Info("Failed to enable".
                                 " stress option\n");
                   $vdLogger->Error("Failed to set the stress option on host");
                    VDSetLastError(VDGetLastError());
                   return FAILURE;
                }
           } else {
              last;
             }
        }
    }
  $VMOpsResult = "PASS";
 if ( $testcase->{WORKLOADS}{STRESS} {operation} =~ /Suspend/i) {
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
      $vdLogger->Info("VMOperation VMOpsResume Failed:\n".VDGetLastError());
      return "FAIL";
    }
    if ( $vmOpsObj->VMOpsResume() ne SUCCESS ) {
      $vdLogger->Error("VMOperation VMOpsResume returned failure");
      VDSetLastError(VDGetLastError());
      $vdLogger->Info("VMOperation VMOpsResume Failed:\n".VDGetLastError());
      return "FAIL";
    }

   sleep(120);
   $vdLogger->Info("Waiting for STAF on $tb{'SUT'}{ip} to come up");
   $ret = $testbed->{stafHelper}->WaitForSTAF($tb{'SUT'}{ip});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Error( "STAF is not running on  $tb{'SUT'}{ip}");
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");
   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      # TODO replace the print with right log function
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "$testcase->{VD_PRE} failed ".
                            VDGetLastError() );
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         return $ret;
      }
   }
 } 
   if ($testcase->{WORKLOADS}{STRESS} {operation} =~ /SRD/i) { 
   # Do Snapshot revert Delete
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
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");
  ret = $testbed->{stafHelper}->WaitForSTAF($tb{'SUT'}{ip});
   if ( $ret ne SUCCESS ) {
      $vdLogger->Error( "STAF is not running on $tb{'SUT'}{ip}");
      return "FAIL";
   }
   $vdLogger->Info("STAF on $tb{'SUT'}{ip} came up");
   # Call the pre-processing routine if it has one
   if ( ref($testcase->{VD_PRE})  eq "CODE" ) {
      # TODO replace the print with right log function
      $ret = $testcase->{VD_PRE}->($testbed, $testcase);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "$testcase->{VD_PRE} failed ".
                            VDGetLastError() );
         return "FAIL";
      } elsif ( $ret eq "FAIL" ) {
         return $ret;
      }
   }
 } 
 ### Start the Traffic  workload
   foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
      # TODO: use Module::Locate to check if a module by name $mod exist
      if ( $mod =~ m/netperf/i ) {
         $ret = VDNetLib::VDCommonSrvs::NetperfWorkload($testbed, $testcase);
      }
   }
   # Unconfig the previous configured stress options.
   if ( defined $testcase->{WORKLOADS}{STRESS} ) {
   # Create Host operations object
   $hostobj = VDNetLib::HostOperations->new("$hostip");

   # Disable stress options on host
   for ($i = 0; $i < $optSize;$i++) {
      if (defined $stressOption[$i] and defined $stressValue[$i]) {
          $vdLogger->Info("UnSetting $stressOption[$i] on host\n");
          $result = $hostobj->HostStress("Disable",
                                         "$stressOption[$i]",
                                         "$stressValue[$i]");
          if ($result eq "FAILURE") {
             $vdLogger->Info(" Failed to Disable".
                                 " stress option\n");
             $vdLogger->Error("Failed to Disable the stress option on host");
             VDSetLastError(VDGetLastError());
             return FAILURE;
          }
      } else {
         last;
      }
   }
 }

   if ($ret eq "FAIL") {
      $vdLogger->Info("SuspendResume: Netperf Failed:\n".VDGetLastError());
      return "FAIL";
   } else {
      return "PASS";
   }
}

1;

