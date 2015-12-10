########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::VDCommonSrvs;

########################################################################
# This package contains methods that are common to all the test cases.
# All test cases execution follow uniform path and most of the methods
# are in this package
########################################################################

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";
use VDNetLib::GlobalConfig qw($vdLogger);
use VDNetLib::PacketCapture;
use Data::Dumper;
use VDNetLib::NetAdapter;
use VDNetLib::Netperf;
use VDNetLib::Utilities;
BEGIN {
   eval "use VDNetLib::VMOperations::VMOperations";
}
use VDNetLib::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);


########################################################################
# VdPreProcessing --
#       This is a setup/prelogue/pre-processing for most of the networking
#	testcases
#
# Input:
#       VdPreProcessing(testbed, testcase)
#               The input parameters are
#               testbed object - that has information regarding sut and helper
#                                machines
#               testcase object- reference to a testcase's hash in the tds
#
# Results:
#      An error if any of the setup related task fails
#      0 if all went fine
#
# Side effetcs:
#       Updates testcase object's connection information
#	Updates verification hash with handles that is used by post-processing
#		routine
#
########################################################################

sub VdPreProcessing
{
   my $testbed = shift;
   my $testcase = shift;

   my %netAdapHash = ();
   my @nicList;

   # check if the testbed has the setup required by the testcase
   my $TBSetup = $testbed->GetTestbedType;
   if ( "$testcase->{SETUP}" !~ /$TBSetup/i ) {
       $vdLogger->Error( "Required TESTBED is $testcase->{SETUP} " .
                          "but the current testbed is " .
                          "$TBSetup");
       VDSetLastError("ETESTBED");
       return FAILURE;
   }
   my $SUTOS = $testbed->GetSUTOS;
   my $unSupportedGOS = (defined $testcase->{UnSupportedGOS}) ?
                        $testcase->{UnSupportedGOS} : 
                        $testcase->{UnSupportedPlatforms};
   # TODO: need to check if connection exists first, for portable tools
   # all tests connection, so it is okay
   # The below logic needs a revisit
   if ( (defined $testcase->{UnSupportedDrivers}) &&
        ("$testcase->{UnSupportedDrivers}" =~
               /$testcase->{CONNECTION}{Source}{nic}{DriverName}/i) ) {
      if ((defined $unSupportedGOS) &&
           (($SUTOS =~ /$unSupportedGOS/i) ||
            ($unSupportedGOS =~ /$SUTOS/i)) ) {
          $vdLogger->Info("This testcase is unsupported on $SUTOS,".
                          " on driver ".
                          "$testcase->{CONNECTION}{Source}{nic}{DriverName}");
          VDSetLastError("EOSNOTSUP");
          return "FAIL";
      }
      # assume that it is unsupported on all OSes if the UnSupportedPlatforms is
      # missing
      if (not defined $unSupportedGOS ) {
         $vdLogger->Info("This testcase is unsupported on " .
                         "$testcase->{CONNECTION}{Source}{nic}{DriverName}".
                         " on all GOSes");
         VDSetLastError("ENOTSUP");
         return "FAIL";
      }
   }

   if ( $testcase->{TARGET} eq "CONNECTION" ) {
      # Get the SUT IP
      if ( defined (my $sut_ip = $testbed->GetSUTIP) ) {
         $testcase->{CONNECTION}{Source}{IP} = $sut_ip;
         # debug
         $vdLogger->Info(
                      "SUT IP is $sut_ip and device under test is ".
                      "$testcase->{CONNECTION}{Source}{nic}{DriverName}");
         $netAdapHash{controlIP} = $sut_ip
      } else {
         $vdLogger->Error("SUT IP is not available");
         return FAILURE;
      }

      if ( defined (my $helper_ip = $testbed->GetHelperIP) ) {
         # TODO: extend to deal with multiple helper machines
         $testcase->{CONNECTION}{Destination}{IP} = $helper_ip;
         $vdLogger->Info(
                     "Helper IP is $helper_ip and support adapter is" .
                     " $testcase->{CONNECTION}{Destination}{nic}{DriverName}");
      } else {
          $vdLogger->Error("DESTINATION CONTROL IP is not available");
          return FAILURE;
      }

      InitDefaultNic($testcase);

      # does the discover API updates the connection reference we pass or
      # return the hash that has the source adapter details?
      # fill connection details by calling NetAdapter API
      my $dutRet = fillInConnection($testcase, $testbed, \%netAdapHash);
      if ( $dutRet eq FAILURE ) {
         $vdLogger->Error( "Unable to find DUT");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # check if we need to start any servers for traffic modules
      # TODO: get the list of categories of workloads into an array
      # Go over each module
      foreach my $mod (keys %{$testcase->{WORKLOADS}{TRAFFIC}}) {
         my $trafficType = "IPv4"; # by default it is ipv4
         if ( $mod =~ m/netperf/i ) {
            # If the direction of workload traffic ("inbound"/"outbound") is
            # not specified, then the default direction is outbound ie. system
            # under test will send packets to helper VM
            #
            my ($server, $client);
            $server = 'Destination';
            $client = 'Source';

            if ( exists $testcase->{CONNECTION}{Source}{nic}{IPv6} ) {
               $trafficType = "IPv6";
            }
            # For inbound traffic, run netserver on system under test and
            # netperf on helper VM
            #
            if ( (defined $testcase->{WORKLOADS}{TRAFFIC}{$mod}) &&
                 ($testcase->{WORKLOADS}{TRAFFIC}{$mod} =~ /inbound/i) ) {
               $server = 'Source';
               $client = 'Destination';
            }
            $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{server} =
                VDNetLib::Netperf->new( mode => 'server',
                   targetHost => $testcase->{CONNECTION}{$server}{IP},
                   testIP => $testcase->{CONNECTION}{$server}{nic}{$trafficType},
                   trafficType => $trafficType,
                );
            # if there is a netserver ipv4 is running, then Netperf module
            # tries to use the same object for ipv6, hence stop the
            # server to cleanup ipv4 netserver and start again.
            if (FAILURE eq $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{server}->Start() ) {
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            $vdLogger->Info("$mod server started with process id " .
               $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{server}->{_pid} .
               " on " . $testcase->{CONNECTION}{$server}{IP});

            # TODO: need to find best place to store run-time elements like this
            $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{$mod}{client} =
                VDNetLib::Netperf->new( mode => 'client',
                   targetHost => $testcase->{CONNECTION}{$client}{IP},
                   testIP => $testcase->{CONNECTION}{$client}{nic}{$trafficType},
                   trafficType => $trafficType,
                );
         }
      }
   }
   # TODO: Add handling of INTERFACE type of tests
}

########################################################################
# VdPreTcpdumpSetup --
#       This is a pre-processing for lauching tcpdump at location
#       TDS hash describes
#
# Input:
#       VdPreTcpdumpSetup(testbed, testcase)
#               The input parameters are
#               testbed object - that has information regarding sut and helper
#                                machines
#               testcase object- reference to a testcase's hash in the tds
#
# Results:
#      Return FAILURE if failed to fill in TCPDUMP expression
#      or launch tcpdump/windump with the given tcpdump expression
#
# Side effetcs:
#	Updates verification hash with handles that is used by post-processing
#		routine
#
########################################################################

sub VdPreTcpdumpSetup
{
   my $testbed = shift;
   my $testcase = shift;

   my ($rc, $i, $end, $skipVlan, $where);

   if ( not defined $testcase->{VERIFICATION}{TCPDUMP}{tcpdumpExpr} ) {
      # TODO: return appropriate error
      # later use default tcpdump expression
      $vdLogger->Warn("TCP dump expression is not provided");
      return FAILURE;
   }

   # we can still capture vlan packet even if the setup doesn't have 3rd machine
   # but the tcpdump expression should not have vlan tag
   $skipVlan = 0;
   if ( $testcase->{TestName} =~ m/vlan/i ) {
      if ( $testbed->GetNoOfMachines <= 2 ) {
         $skipVlan = 1;
      } else {
         $where = $testbed->GetHelperIP('helper2');
      }
   }
   if ( $skipVlan ) {
      $vdLogger->Warn("Packet Capture not possible ".
                             "because of no sniffer VM");
      return SUCCESS;
   }
   # Assuming that for a given test case the tcpdump filter stays the
   # same, we do not need to redo the string
   if ( (not defined $testcase->{VERIFICATION}{TCPDUMP}{state}) ||
        ($testcase->{VERIFICATION}{TCPDUMP}{state} ne "RUNNING") ) {
      if ( PrepareTcpdumpExpr($testcase) eq FAILURE ) {
         $vdLogger->Error( "Unable to expand tcpdump expression provided");
         return FAILURE;
      }
   }

   my $tcpdumpExpr = $testcase->{VERIFICATION}{TCPDUMP}{tcpdumpExpr};
   # call initCapture only it wasn't called before
   if ( not defined $testcase->{VERIFICATION}{TCPDUMP}{handle} ) {
      $rc = initCapture();
      if ( $rc < 0 ) {
         $vdLogger->Error( "VdPreTcpdumpSetup: initCapture failed");
         return FAILURE;
      }
   }

   $where = $testcase->{VERIFICATION}{TCPDUMP}{LOC} if not defined($where);
   $vdLogger->Debug("params to startCapture");
   $vdLogger->Debug("IP $testcase->{CONNECTION}{$where}{IP},
                    $testcase->{CONNECTION}{$where}{nicObj}->{interface},
                    filter $tcpdumpExpr");

   # cleanup the old files if any before starting the capture
   $rc = cleanupCapture(0,sourceHost=>$testcase->{CONNECTION}{$where}{IP});
   if ($rc < 0) {
      $vdLogger->Error( "Clean packet capture file failed");
      return FAILURE;
   }
   my $handle = startCapture($testcase->{CONNECTION}{$where}{IP},
                       $testcase->{CONNECTION}{$where}{nicObj}->{interface},
                       filter=>$tcpdumpExpr);

   if ( $handle < 0 ) {
      # Try one more time after cleanup
      # TODO: Do this, only if it fails because of existing pcap file
      $rc = cleanupCapture(0,sourceHost=>$testcase->{CONNECTION}{$where}{IP});
      if ($rc < 0) {
         $vdLogger->Error( "Clean packet capture file failed");
         return FAILURE;
      }
      $handle = startCapture($testcase->{CONNECTION}{$where}{IP},
                       $testcase->{CONNECTION}{$where}{nicObj}->{interface},
                       filter=>$tcpdumpExpr);
   }
   # I guess it is a good idea to save this handle
   $testcase->{VERIFICATION}{TCPDUMP}{handle} = $handle if ($handle >= 0 );
   $vdLogger->Debug("tcpdump pre pro startCapture  $handle");
   if ( $handle < 0 ) {
      $vdLogger->Error( "VdPreTcpdumpSetup: startCapture failed:", $errorString);
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      # TODO: revisit this state logic
      $testcase->{VERIFICATION}{TCPDUMP}{state} = "RUNNING" if ($handle >= 0 );
   }
   return SUCCESS;
}

########################################################################
# VdPostProcessing --
#       Runs the specified test on the captured data and return pass or fail
#
# Input:
#       VdPreTcpdumpSetup(testbed, testcase)
#               The input parameters are
#               testbed object - that has information regarding sut and helper
#                                machines
#               testcase object- reference to a testcase's hash in the tds
#
# Results:
#      Return FAIL if the specified test fails else pass
#
# Side effetcs:
#      None
#
########################################################################

sub VdPostProcessing
{
   my $testcase = shift;
   my ($ret, $length, $rc);

   if ( not defined $testcase->{VERIFICATION}{TCPDUMP}{handle} ) {
      $vdLogger->Info("PacketCapture handle is undefined");
      return "pass";
   }
   # TODO: if this function does not handle other than CONNECTION
   # TARGET then check ne CONNECTION and return FAILURE
   if ( $testcase->{TARGET} eq "CONNECTION" ) {
      $vdLogger->Debug("in post processing ");
      my $handle =  $testcase->{VERIFICATION}{TCPDUMP}{handle};
      # TODO: run staf command to see if the handle still exist
      # TODO: if the packets are captured with right filter string
      # the below filter string will be empty
      my $filterString = "";
      my $destFileName="proto.pcap";
      my $loc = $testcase->{VERIFICATION}{TCPDUMP}{LOC};
      $rc =  runFilter($handle,$filterString,
                            sourceHost=>$testcase->{CONNECTION}{$loc}{IP},
                            destFileName=>$destFileName);
      if ( $rc < 0 ) {
         $vdLogger->Error("runFilter Failed: $errorString");
         VDSetLastError("EFAIL");
         # TODO: return appropriate error code
         return FAILURE;
      }

      my $destDir = "/tmp";
      my $testName = "$testcase->{VERIFICATION}{TCPDUMP}{Macro}";
      my $count_hash;
      ($rc,$count_hash) = runTest(0,$testName,
                                sourceHost=>$testcase->{CONNECTION}{$loc}{IP},
                                sourceFileName=>$destFileName,
                                sourceDir=>undef);
                                #sourceDir=>$destDir);
      $vdLogger->Debug(Dumper($count_hash));
      $testcase->{VERIFICATION}{TCPDUMP}{result} = "pass";
      if ( $rc < 0 ) {
         $vdLogger->Error("runTest failed $errorString");
         $testcase->{VERIFICATION}{TCPDUMP}{result} = "fail";
         # TODO: use VDSetLastError
         return FAILURE;
      }

      # Compute the number of packets captured. Throw warning if the packets
      # captured is less than 50% of the required number of packets to verify
      # that the test passed
      #
      $vdLogger->Info("Number of packets found:$count_hash->{$testName}");
      if ( ( defined $count_hash->{$testName} ) &&
           ( $count_hash->{$testName} > 0 ) ) {
         $testcase->{VERIFICATION}{TCPDUMP}{result} = "pass";
         if ( defined $testcase->{VERIFICATION}{TCPDUMP}{tcpdumpExpr} ) {
            my $expectedCount = VDNetLib::Utilities::GetCountFromPktExpr(
                             $testcase->{VERIFICATION}{TCPDUMP}{tcpdumpExpr});
            if ( ($expectedCount ne FAILURE) &&
                 ($expectedCount =~ /\d+/) ) {
               my $per = ($count_hash->{$testName}/$expectedCount)*100;
               if ( $per <= 50 ) {
                  $vdLogger->Warn("Less than 50 percentage of packets".
                                         " captured. Actual packets captured".
                                         ":$count_hash->{$testName}, ".
                                         " expected count: $expectedCount");
               }
            }
         }
      } elsif ( (ref($count_hash) ne "HASH") ||
                ($count_hash->{$testName} == 0) ) {
         $testcase->{VERIFICATION}{TCPDUMP}{result} = "fail";
         $vdLogger->Error(
               "testName = $testName " .
               "$count_hash->{$testName} " .
               " $testcase->{VERIFICATION}{TCPDUMP}{result}");
      }
      $ret = stopCapture($testcase->{VERIFICATION}{TCPDUMP}{handle});
      # Can the below code done in the main test case routine - revisit
      if ( $ret > 0 ) {
         ($ret, $length) = runTest(
                    $testcase->{VERIFICATION}{TCPDUMP}{handle},
                    "$testcase->{VERIFICATION}{TCPDUMP}{Macro}");
         if ( ($ret >= 0) && ($length > 0) ) {
            # return testID as pass
         }
      }
#else {
#         $vdLogger->Error( "Stop capture failed:$ret,$errorString");
#         return FAILURE;
#      }
      # does the discover API updates the connection reference we pass or
      # return the hash that has the source adapter details?
      # let discover croak, and we will eval it here
      # set the original setting of the nic
      #Utility::setAdapter(\%{$testcase->{CONNECTION}})

   }
}

########################################################################
# fillInConnection --
#       Based on the device under test and support adapter nic driver type
#       gets the nic from NetAdapter class, configures the nic by calling
#       ConfigureNIC method and saves the nic reference in the test case
#       hash
#
# Input:
#       testbed object - that has information regarding sut and helper
#                         machines
#       testcase object- reference to a testcase's hash in the tds
#
# Results:
#        FAILURE if any set/get on the nic fails else SUCCESS
#
# Side effetcs:
#      None
#
########################################################################

sub fillInConnection
{
   my $testcase = shift;
   my $testbed = shift;
   my $net = shift;
   my @nicList = ();
   my ($nic, $ipAddr);
   my @args;
   my $result;
   my $prop;
   my $ret;
   my $n = scalar(@nicList);

   if ((not defined $testcase) ||
      (not defined $testbed) ||
      (not defined $net)) {
      $vdLogger->Error( "fillInConnection: Insufficient paramters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
    $vdLogger->Debug("keys %{$testcase->{CONNECTION}} ");
   foreach my $end ( keys %{$testcase->{CONNECTION}} ) {
      my $vlanObj;
      my $vlanEnabled = 0;
      my $vmxPath;
      my $hostIP;
      my $mac;
      my $pg;
      my $vswitch;
      my $ipv4;

      $vdLogger->Info("Setting NIC attributes of $end connection end");
      if ( (not defined $testcase->{CONNECTION}{$end}{nic}{DriverName}) &&
           ($end =~ /source/i) ) {
         $vdLogger->Error( "fillInConnection: Source DriverName is not set");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      $vdLogger->Debug("adapter type $testcase->{CONNECTION}{$end}{nic}{DriverName}");

      $net->{controlIP} = $testcase->{CONNECTION}{$end}{IP};
      $vdLogger->Debug("control IP $net->{controlIP} ");

      @nicList = VDNetLib::NetAdapter::GetAllAdapters($net,
                       $testcase->{CONNECTION}{$end}{nic}{DriverName});

      if ( $nicList[0] eq FAILURE ) {
         # checkSTAF and try one more time
         $ret = $testbed->{stafHelper}->WaitForSTAF(
                                       $testcase->{CONNECTION}{$end}{IP});
         if ( $ret ne SUCCESS ) {
            $vdLogger->Error( "STAF is not running on ".
                               "$testcase->{CONNECTION}{$end}{IP}");
            VDSetLastError("ESTAF"); #TODO Set last error in WaitForSTAF()
            return FAILURE;
         }
         @nicList = VDNetLib::NetAdapter::GetAllAdapters($net,
                       $testcase->{CONNECTION}{$end}{nic}{DriverName});
      }
      if ( $nicList[0] eq FAILURE ) {
         $vdLogger->Error(
                   "Device: $testcase->{CONNECTION}{$end}{nic}{DriverName}" .
                   " is not available on $testcase->{CONNECTION}{$end}{IP}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $n = scalar(@nicList);
      $vdLogger->Debug("no. of devices - $n");

      # TODO: Make NetAdapter to run reference to hash when filter is provided
      if (!scalar(@nicList)) {
         # TODO return right error code
         # test this code path with unsupported device
         # $vdLogger->Error( "Device Under Test is not available on the SUT");
         $vdLogger->Error(
               "DUT: $testcase->{CONNECTION}{$end}{nic}{DriverName} on" .
               " $testcase->{CONNECTION}{$end}{IP} is not available");
         return FAILURE;
      }

      $nic = VDNetLib::NetAdapter->new(%{$nicList[0]});

      if ($nic eq FAILURE) {
         $vdLogger->Error( "Failed to create NetAdapter object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # store the nic object corresponding to device under test
      $testcase->{CONNECTION}{$end}{nicObj} = $nic;

      # TODO: The way nic properties defined should be the same both in
      # NetAdapter API, set get method on the nic object should be set{attr}
      # is there a way to get list of methods in a class
      # using autoloading in the class help
      my $ret = ConfigureNIC($testcase, $testbed, $end, $nic, 0);
      if ( $ret eq FAILURE ) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if (ref($ret) eq "VDNetLib::NetAdapter") {
         # looks like VLAN is enabled, set vlan and other props
         $vdLogger->Info("VLAN is enabled, creating vlan interface");
         $testcase->{CONNECTION}{$end}{vlanObj} = $ret;
         $ret = ConfigureNIC($testcase, $testbed, $end, $ret,1);
      }
      if ( $ret eq FAILURE ) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $testcase->{CONNECTION}{$end}{nic}{macAddress} = $nic->{macAddress};
      # TODO: validate IP address using IsValidIP, right now
      # it has a bug, 2001:bd6::1 is reported as invalid IP

      if ((not defined $testcase->{CONNECTION}{$end}{portGroup}) &&
          (not defined $testcase->{CONNECTION}{$end}{vSwitch})) {
         $vdLogger->Info("No portgroup/vSwitch configuration made");
         next;
      } else { # Get MAC address, portGroup name, vSwitch name for the adapter

         if ($end =~ /Source/i) {
            $vmxPath = $testbed->{testbed}{SUT}{vmx};
            $hostIP = $testbed->{testbed}{SUT}{host};
         } elsif ($end =~ /Destination/i) {
            $vmxPath = $testbed->{testbed}{helper1}{vmx};
            $hostIP = $testbed->{testbed}{helper1}{host};
         } else {
            $vdLogger->Error( "Invalid endpoint");
            return "FAILURE";
         }

         # Get MAC Address of the network adapter
         $mac = $nic->GetMACAddress();
         if ($mac eq "FAILURE") {
            $vdLogger->Error( "Unable to retrieve MAC address");
            VDSetLastError(VDGetLastError());
            return "FAILURE";
          }
         # Get the portgroup name to which the net adapter is connected
         $vdLogger->Info("host $hostIP vmx $vmxPath mac $mac");
         $pg = $testbed->GetPortGroupName($hostIP, $vmxPath, $mac);

         if ($pg eq "FAILURE") {
            $vdLogger->Error( "Unable to retrieve Portgroup name for $mac");
            VDSetLastError(VDGetLastError());
            return "FAILURE";
         }
         # store the portgroup in test case hash
         $testcase->{CONNECTION}{$end}{portGroup}{Name} = $pg;
         if ( defined $testcase->{CONNECTION}{$end}{portGroup}{Name} ) {
            $testcase->{CONNECTION}{$end}{portGroup}{Name} =~ s/^\s*//;
            $testcase->{CONNECTION}{$end}{portGroup}{Name} =~ s/\s*$//;
         }
         $vdLogger->Info("PortgroupName of $end nic: $pg");

         # Get the vswitch name to which the net adapter/portgroup is
         # connected
         $vswitch = $testbed->GetVswitchName($hostIP, $pg);

         if (not defined $vswitch) {
            $vdLogger->Error( "Unable to retrieve vSwitch name");
            VDSetLastError("ENOTDEF");
            return "FAILURE";
         }
         # store the vswitch name in test case hash
         $testcase->{CONNECTION}{$end}{vSwitch}{Name} = $vswitch;
         $vdLogger->Info("vSwitchName of $end nic: $vswitch");
      }

      # Configure the portgroup here
      my $arg;
      my $command;
      my $data;

      if (defined $testcase->{CONNECTION}{$end}{portGroup}) {
         foreach $prop (keys %{$testcase->{CONNECTION}{$end}{portGroup}}) {
            if ($prop =~ /VLAN/) {
               $arg = $testcase->{CONNECTION}{$end}{portGroup}{VLAN};
               if (not defined $arg) {
                  $vdLogger->Error( "Invalid VLAN id specified");
                  return "FAILURE";
               }
               $command = "start shell command esxcfg-vswitch --vlan=$arg " .
                          "$vswitch -p \"$pg\" wait returnstdout";
               ($ret, $data) = $testbed->{stafHelper}->runStafCmd($hostIP,
                                                                  'process',
                                                                  $command);

               if ($ret ne "SUCCESS") {
                  $vdLogger->Error( "Failed to set vlan id on vswitch");
                  VDSetLastError(VDGetLastError());
                  return "FAILURE";
               } else {
                  $vdLogger->Info("Setting vlan id $arg on portgroup $pg ".
                                      "on vswitch $vswitch is completed");
               }
               # TODO verify whether vlan was actually set
            }
         } # end of portGroup configuration
      } else {
         $vdLogger->Info("No portgroup configuration made");
      }

      if (defined $testcase->{CONNECTION}{$end}{vSwitch}) {
         foreach $prop (keys %{$testcase->{CONNECTION}{$end}{vSwitch}}) {
            if ($prop =~ /MTU/i) {
               $arg = $testcase->{CONNECTION}{$end}{vSwitch}{MTU};
               if (not defined $arg) {
                  $vdLogger->Error( "Invalid MTU value specified");
                  VDSetLastError("EINVALID");
                  return "FAILURE";
               }
               $command = "start shell command esxcfg-vswitch --mtu=$arg " .
                          "$vswitch wait returnstdout";
               ($ret, $data) = $testbed->{stafHelper}->runStafCmd($hostIP,
                                                                  'process',
                                                                  $command);

               if ($ret ne "SUCCESS") {
                  $vdLogger->Error( "Failed to set mtu on vswitch");
                  VDSetLastError(VDGetLastError());
                  return "FAILURE";
               } else {
                  $vdLogger->Info("Setting $vswitch mtu on host, ".
                                      "$hostIP to $arg is completed");
               }
               # TODO verify whether mtu was actually set
            }
         } # end of all properties to configure on vSwitch
      } else { # end of vSwitch Configuration
         $vdLogger->Info("No vswitch configuration made");
      }
   }
   # TODO: the below logic will not work in INTER setup as it could be
   # possible the port group names could be different and still the vnics
   # could talk to each other.  Replace the below logic with ping once the
   # ping module is ready
   if ( ($testbed->{testbed}{SUT}{hostType} !~ /esx/i) ||
        ($testbed->{testbed}{SUT}{hostType} !~ /vmkernel/i) ) {
      return SUCCESS;
   }

   if ( (defined $testcase->{CONNECTION}{Source}{portGroup}{Name} &&
         defined $testcase->{CONNECTION}{Destination}{portGroup}{Name}) &&
         ($testcase->{CONNECTION}{Source}{portGroup}{Name} ne
          $testcase->{CONNECTION}{Destination}{portGroup}{Name}) ) {
      $vdLogger->Error(
                       "source portgroup: " .
                       "$testcase->{CONNECTION}{Source}{portGroup}{Name} " .
                       "and destination portgroup " .
                       "$testcase->{CONNECTION}{Destination}{portGroup}{Name}".
                       " nics are on different portgroups ");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

}

########################################################################
# ConfigureNIC --
#       Configures the nic properties described by test case hash
#
#       1. Go through the nic hash of given end (dut or supp adapter)
#          set the given property.
#       2. IP address setting is done at the end, because most
#          nic properties require unloading and loading the driver, due
#          to which you may loose the IP address
#
# Input:
#       testbed object - that has information regarding sut and helper
#                         machines
#       testcase object- reference to a testcase's hash in the tds
#       end of the connection (source or destination)
#       nic - reference to nic object returned by NetAdapter class
#       isVlan - flag to identify if vlan is enabled
#
# Results:
#        FAILURE if any set/get on the nic fails else SUCCESS
#
# Side effetcs:
#      None
#
########################################################################

sub ConfigureNIC
{
   my $testcase = shift;
   my $testbed = shift;
   my $end = shift;
   my $nic = shift;
   my $isVlan = shift;

   my ($vlanObj, $result, $ip);
   my $vlanEnabled = 0;
   my $trafficType;
   # set all the properties defined in the hash except VLAN
   foreach my $prop (keys %{$testcase->{CONNECTION}{$end}{nic}}) {
      if ( $prop =~ /MAC/ ) {
         $testcase->{CONNECTION}{$end}{nic}{$prop} = $nic->{macAddress};
         next;
      } elsif ($prop =~ /MTU/i) {
         if ( not defined $testcase->{CONNECTION}{$end}{nic}{$prop} ) {
            next;
         }
         $vdLogger->Info("Setting MTU value " .
               "$testcase->{CONNECTION}{$end}{nic}{$prop} on $end adapter");
         $result = $nic->SetMTU($testcase->{CONNECTION}{$end}{nic}{$prop});
         if ($result eq "FAILURE") {
            $vdLogger->Error( "Error setting MTU on $end");
             VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } elsif ( ($prop =~ /VLAN/i) && (!$isVlan) ) {
         # hopefully, nobody sets vlan id 0 in the hash
         if ( $testcase->{CONNECTION}{$end}{nic}{$prop} eq "0" ) {
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         $vlanEnabled = $prop;
         next;
      } elsif ( $prop =~ /tso/i ) {
         my $action = $testcase->{CONNECTION}{$end}{nic}{$prop};
         $action = ($action =~ /Enable/i) ? "Enable" : "Disable";
         $vdLogger->Info("$action TSO on $end");

         $result = $nic->GetOffload('TSOIPv4');
         if ( $result =~ /$action/i) {
            next;
         }
         $result = $nic->SetOffload('TSOIPv4',
                                    $action);
         if  ( $result eq FAILURE ) {
            $vdLogger->Error("SetOffload TSOIPv4,$action failed");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Log("TSO $action successful");

      # cso setting is not supported on vmxnet2
      } elsif ( $prop =~ /cso/i &&
                ($testcase->{CONNECTION}{Source}{nic}{DriverName}
                    !~ /vmxnet2/i) ) {
         $result = $nic->GetOffload('TCPTxChecksumIPv4');
         if ( $result eq $testcase->{CONNECTION}{$end}{nic}{$prop} ) {
            next;
         }
         $result = $nic->SetOffload('TCPTxChecksumIPv4',
                              $testcase->{CONNECTION}{$end}{nic}{$prop});
         if ( $result eq FAILURE ) {
            $vdLogger->Error( "SetOffload(TCPTxChecksumIPv4, ".
                     "$testcase->{CONNECTION}{$end}{nic}{$prop}) failed");
            VDSetLastError(VDGetLastError());
            return $result;
         }
         $vdLogger->Info("Enabled CSO");
      } elsif ( $prop =~ /cso/i &&
                      ($testcase->{CONNECTION}{Source}{nic}{DriverName}
                                          =~ /vmxnet2/i) ) {
            $vdLogger->Info("Turning CSO on/off in vmxnet2 driver is not".
                                " supported and hence skipping setting CSO");
      } elsif ( $prop =~ /wol/i ) {
         my $driverName = $testcase->{CONNECTION}{Source}{nic}{DriverName};
         if ($driverName =~ /vmxnet3/i) {
            $result = $nic->SetWoL($testcase->{CONNECTION}{$end}{nic}{$prop});
            if ( $result eq FAILURE ) {
               $vdLogger->Error( "SetWoL, ".
                               "$testcase->{CONNECTION}{$end}{nic}{$prop} failed");
               VDSetLastError(VDGetLastError());
               return $result;
            }
            $vdLogger->Info("Enabled WoL");
         } elsif ($driverName =~ /e1000/i || $driverName =~ /vmxnet2/) {
            #TODO - Cut/Paste the code from PowerMgmt to edit vmx file here
         }
      }
   }
   # if it is a vlan interface then IP address is already set when
   # setting vlan id, so return here.  However, we are not returning as
   # setting other nic prop like MTU might reset the ipv6 addresss, hence
   # the last property that is set is always a IPv6 address
   #return SUCCESS if ( $isVlan );

   if ( exists $testcase->{CONNECTION}{$end}{nic}{IPv4} &&
        exists  $testcase->{CONNECTION}{$end}{nic}{IPv6} ) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ( exists $testcase->{CONNECTION}{$end}{nic}{IPv4} ) {
      $trafficType = "IPv4";
   } elsif ( exists $testcase->{CONNECTION}{$end}{nic}{IPv6} ) {
      $trafficType = "IPv6";
   } else {
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $method = ($trafficType =~ /IPv6/i) ? "Get".$trafficType."Global":
                           "Get"."IPv4";
   my $netmask = ($trafficType =~ /ipv4/i) ? "255.255.255.0" : "64";
   if ($vlanEnabled =~ /vlan/i) {
      $ip = $nic->$method();
      if ($ip eq "FAILURE") {
         # it is possible there is no IP configured
         $vdLogger->Error("Eithere there is no IP configured or ".
                         "there is an error getting IP from $end");
         VDSetLastError(VDGetLastError());
         #return FAILURE;
      } else {
         # store the base device's IP address and reset to the same during
         # cleanup remove after fixing PR426577
         $testcase->{CONNECTION}{$end}{nic}{baseIP} = $ip;
      }
      # TODO: because SetVLAN always expects ipv4 address, use dummy ip address
      my $ipforVLAN = $testcase->{CONNECTION}{$end}{nic}{$trafficType};
      if ( $trafficType =~ /ipv6/i ) {
         my $random_number = int(rand(100));
         $random_number += 1;
         $ipforVLAN = "192.168."."$random_number";
         $random_number = int(rand(100));
         $random_number += 1;
         $ipforVLAN = $ipforVLAN.".".$random_number;
         $netmask = "255.255.255.0";
         $testcase->{CONNECTION}{$end}{nic}{dummyVLANIPv4} = $ipforVLAN;
      }
      $vlanObj = $nic->SetVLAN($testcase->{CONNECTION}{$end}{nic}{$vlanEnabled},
                               $ipforVLAN,
                               $netmask);
      if ($vlanObj eq FAILURE) {
         $vdLogger->Error("Error setting VLAN Id,".
                           "$testcase->{CONNECTION}{$end}{nic}{$vlanEnabled} ".
                           "on $end");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if ( $trafficType =~ /ipv6/i ) {
         $vdLogger->Info("Configuring VLAN interface's IP address ".
                             "$testcase->{CONNECTION}{$end}{nic}{$trafficType}".
                             " address on $end");
         $result = $vlanObj->SetIPv6('add',
                     $testcase->{CONNECTION}{$end}{nic}{$trafficType},
                     '64');
         if ($result eq FAILURE) {
            $vdLogger->Error( "Error setting IPv6 of VLAN ".
                               "interface");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
      # Update the source/destination adapter's IP address if vlan
      # is enabled
      $result = $vlanObj->$method();
      if ($result eq FAILURE) {
         $vdLogger->Error( "Error retrieving $trafficType of VLAN interface");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("VLAN interface configured successfully on $end nic");
      return $vlanObj;
   } else {
      # set IP address now
      $method = ($trafficType =~ /IPv6/i) ? "Set".$trafficType:
                           "Set"."IPv4";
      $ip = $testcase->{CONNECTION}{$end}{nic}{$trafficType};
      $vdLogger->Info("Configuring $end adapter's IP address to $ip");

      if ( $trafficType =~ /ipv6/i ) {
         $result = $nic->$method("add", $ip, $netmask);
      } else {
         $result = $nic->$method($ip, $netmask);
      }

      if ($result eq FAILURE) {
         $vdLogger->Error( "Error setting $trafficType address, $ip, $netmask");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $vdLogger->Info("Successfully configured $end " .
                                "adapter's IP address to $ip");
      return SUCCESS;
   }
}

########################################################################
# InitDefaultNic --
#        This routine fills the basic attributes like MTU, and IPv4 keys if
#        it is not mentioned in the test case hash
#
# Input:
#        VdPreProcessing(testcase)
#                The input parameters are
#                testcase - reference to a testcase's hash in the tds
# Results:
#       none
#
# Side effetcs:
#        Adds IPv4, MTU attributes in the testcase connection
#
########################################################################

sub InitDefaultNic
{
   my $testcase = shift;
   my ($sourceIP, $destIP);
   # Add validation for Source and Destination IPs
   my $subnet4 = "192.168.0.";
   my $subnet6 = "2001:bd6::";

   if ( not defined $testcase->{CONNECTION}{Source}{IP} ) {
      $sourceIP = "10";
   } else {
      $sourceIP = ( ( $testcase->{CONNECTION}{Source}{IP} =~ /(\d+)$/ ) ?
                       $1 : "10");
   }
   if ( not defined $testcase->{CONNECTION}{Destination}{IP} ) {
      $destIP = "20";
   } else {
      $destIP = ( ( $testcase->{CONNECTION}{Destination}{IP} =~ /(\d+)$/ ) ?
                       $1 : "20");
   }
   $destIP = $destIP + 1 if ( $sourceIP eq $destIP );

   # fill in the NIC attributes
   if ( $testcase->{TARGET} eq "CONNECTION" ) {
      # CONNECTION should only have Source and Destination keys
      foreach my $end (keys %{$testcase->{CONNECTION}}) {
         if ( (!exists($testcase->{CONNECTION}{$end}{nic}{IPv6})) &&
              (!exists($testcase->{CONNECTION}{$end}{nic}{IPv4})) ) {
            $testcase->{CONNECTION}{$end}{nic}{IPv4} = '';
         }
         # Set the source/destination adapter's IPv4 address
         # Currently we use pre-defined IPv4 address for source and destination
         # adapters assuming there will always be one test adapter on each
         # endpoint. This portion of code will make sure that the IPv4 address
         # are always set and recovered from changes made during vlan
         # configuration
         #
         if ( $end =~ /Source/i ) {
            if ( exists $testcase->{CONNECTION}{$end}{nic}{IPv4} ) {
               $testcase->{CONNECTION}{$end}{nic}{IPv4} = "$subnet4".$sourceIP;
            } elsif ( exists $testcase->{CONNECTION}{$end}{nic}{IPv6} ) {
                $testcase->{CONNECTION}{$end}{nic}{IPv6} = "$subnet6".
                                                               $sourceIP;
            }
         } elsif ( $end =~ /Destination/i ) {
            if ( exists $testcase->{CONNECTION}{$end}{nic}{IPv4} ) {
               $testcase->{CONNECTION}{$end}{nic}{IPv4} = "$subnet4".$destIP;
            } elsif ( exists $testcase->{CONNECTION}{$end}{nic}{IPv6} ) {
               $testcase->{CONNECTION}{$end}{nic}{IPv6} = "$subnet6".$destIP;
            }
         } else {
            $vdLogger->Warn("Unknown endpoint $end specified");
         }
         if ( !exists($testcase->{CONNECTION}{$end}{nic}{MTU}) ) {
            $testcase->{CONNECTION}{$end}{nic}{MTU} = "1500";
         }
         $testcase->{CONNECTION}{$end}{nic}{MAC} = "";
      }
   }
}

########################################################################
# NetperfWorkload --
#        This routine fills parameters of tcpdump expression that
#        is mentioned in the test case hash
#
# Input:
#        testcase hash
#
# Results:
#       none
#
# Side effetcs:
#       testcase tcpdumpexpr key value is updated
#
########################################################################

sub NetperfWorkload
{
   my $testbed = shift;
   my $testcase = shift;
   my $count = 1;
   my ($ret,$mode,$nicProp,$tsoStatus,$timeout);
   my ($npClient, $npServer, $trafficType);
   # initialize the testData list with one element that has options
   my @testData = ("");
   my %failedIterations = (
                             netperfFailures => 0,
                             pktCapFailures => 0,
                             # initialize total iterations to 1 to avoid
                             # division by zero exception while calculating
                             # % of failures
                             totalIterations => 1,
                          );

   # TODO: Module should take care of the test data based on the
   # test.  Remove storing test data in the testcase hash once
   # modules store them inside themselves.
   if ( defined $testcase->{DATASET} ) {
      @testData = @{$testcase->{DATASET}};
      $count = scalar(@testData);
   }
   $failedIterations{'totalIterations'} = $count;
   $npClient = $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{netperf}{client};
   $npServer = $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{netperf}{server};

   my $remTestIP = $npServer->GetTestIP();
   my $locTestIP = $npClient->GetTestIP();
   my $serverPort = $npServer->GetTestPort();

   $vdLogger->Info("Running Netperf from $locTestIP to $remTestIP");

   $trafficType = (exists $testcase->{CONNECTION}{Destination}{nic}{IPv6}) ?
                     "IPv6" : "IPv4";
   foreach my $d (@testData) {
      $vdLogger->Info("Launching TCPDUMP for capturing packets");
      if ( defined $testcase->{VERIFICATION}{TCPDUMP} ) {
         if ( VdPreTcpdumpSetup($testbed, $testcase) eq FAILURE ) {
            $vdLogger->Error( "TCPDUMP setup failed");
            return "FAIL";
         }
      }
      $vdLogger->Info("Starting netperf iteration $count with testdata:" .
                          " $d");
      $npClient->ClearTestOptions();
      # -L option is mandatory with IPv6 as IPV6 global address on
      # the control IP might high metric and the packets to 2001:bd6
      # network will get routed via control interface and hence netperf
      # might fail
      #$npClient->PrependTestOptions(
      #            "-H $testcase->{CONNECTION}{Destination}{nic}{$trafficType}".
      #           " -L $testcase->{CONNECTION}{Source}{nic}{$trafficType}");
      $npClient->PrependTestOptions("-H $remTestIP -p $serverPort -L $locTestIP");
      $npClient->AppendTestOptions($d);
      # TODO: there has to be a better way to get how netperf should be
      # executed
      if ( $testcase->{WORKLOADS}{TRAFFIC}{netperf} =~ /nic(.*)/i ) {
         $nicProp = $1;
         $mode = "async";
      } else {
         $nicProp = undef;
         $mode = "";
      }
      if ("FAILURE" eq $npClient->StartClient($mode)) {
         VDSetLastError(VDGetLastError());
         $vdLogger->Error( "NetperfWorkload: Starting netperf client ".
                            "failed");
         return "FAIL";
      }

      if ( ($mode =~ /async/i) && (defined $nicProp) ) {
         if ( ($ret = SetNICProps($testcase, $nicProp)) eq FAILURE ) {
            return "FAIL";
         }
      }
      if ( $d =~ /.* -l (\d+) .*/ ) {
         $timeout = $1 + 60;
      }
      if ( $mode =~ /async/i ) {
         $ret = $npClient->Wait($timeout);
         if ( $ret eq FAILURE ) {
            $npClient->Stop();
         }
      }
      if ( ( $ret =
             VDNetLib::VDCommonSrvs::VdPostProcessing($testcase) ) =~ /fail/i ) {
         # TODO: parse the error code and return whether it is error in
         # product tool or script or setup (if applicable)
         $vdLogger->Error( "TCPDUMP Post Processing failed ");
         $failedIterations{pktCapFailures}++;
      }
      # TODO: Need to implement the right logic based on the traffic tool
      # output and tcpdump output
      # Scenarios to be covered
      # Netperf passes, packet capture failed because of some internal
      # mark the test pass as it is due to the script failure
      # Netperf failed, then irrespective of packet capture mark the test failed
      $ret = "PASS";
      my $netperfRetCode = $npClient->GetResult();
      $vdLogger->Debug("stdout of netperf:" . $npClient->{_stdout});
      my $npThroughput = $npClient->GetNetperfThruput();

      # On windows, changing nic properties restarts the driver and hence
      # netperf could fail, so if is windows, you can ignore it.

      if ( $netperfRetCode ne "0" ) {
         # if it is windows and nicProp is defined then it is possible
         # the netperf sesssion got invalidated as setting any property
         # on windows require restarting the device
         if ( !(($testbed->GetSUTOS =~ /win/i) && (defined $nicProp)) ) {
            $vdLogger->Error(
                      "netperf failed for iteration $count: $netperfRetCode");
            $vdLogger->Debug(
                      "stdout of netperf: $npClient->{_stdout}") if (
                      defined $npClient->{_stdout} );
            $failedIterations{netperfFailures}++;
            $ret = "FAIL";
         }
      } elsif ( $npThroughput eq FAILURE ) {
         $vdLogger->Warn("Netperf->GetNetperfThruput failed");
         $failedIterations{netperfFailures}++;
      } elsif ($npThroughput eq "low") {
         $vdLogger->Warn("Netperf Throughput is either too low" .
                         " or empty");
         $vdLogger->Warn($npClient->{_stdout});
         $failedIterations{netperfFailures}++;
      }
      # TODO: fail the test case if packet capture fails when it becomes
      # robust, till then log a warning and report pass.  This is just to
      # avoid false indication if there is a bug in the automation script
      if ( defined $testcase->{VERIFICATION}{TCPDUMP}{handle} ) {
         if (($ret =~ /PASS/i) &&
              ($testcase->{VERIFICATION}{TCPDUMP}{result} &&
              $testcase->{VERIFICATION}{TCPDUMP}{result} =~ /fail/i)) {
            $vdLogger->Warn("packet capture for iteration " .
                                   "$count failed - problem could be either".
                                   " in automation or product");
            $failedIterations{pktCapFailures}++;
         }
      }
      # TODO: need to find better way to figure out if there is more data
      $count = $count - 1;
   } # end of for loop
   # TODO: need to report the cummulative result here
   if ($failedIterations{netperfFailures}) {
      my $percentage =
         $failedIterations{netperfFailures}/$failedIterations{totalIterations};
      $percentage = $percentage * 100;
      if ($percentage > 50) {
         return "FAIL";
      } else {
         return "PASS";
      }
   } else {
      return "PASS";
   }
}


########################################################################
# NetperfLoadUnload --
#        This routine makes and calls the netperf expression and load
#        unload the Driver on linux machine.
#
# Input:
#        testcase hash, testbed hash
#
# Results:
#       PASS/FAIL
#
# Side effetcs:
#       if the module is not loaded next testcase may fail
#
########################################################################

sub NetperfLoadUnload
{
   my $testbed = shift;
   my $testcase = shift;
   my %netAdapHash = ();
   my $count = 0;
   my ($ret,$mode,$nicProp,$tsoStatus,$timeout);
   my ($npClient, $npServer, $trafficType);

   # initialize the testData list with one element that has options
   my @testData = ("");
   my %failedIterations = (
                             netperfFailures => 0,
                             pktCapFailures => 0,
                             # initialize total iterations to 1 to avoid
                             # division by zero exception while calculating
                             # % of failures
                             totalIterations => 1,
                          );

   if ( $testbed->GetSUTOS =~ /win/i ) {
       $vdLogger->Fail("testcase is not supported on windows");
       return "FAIL";
   }

   # TODO: Module should take care of the test data based on the
   # test.  Remove storing test data in the testcase hash once
   # modules store them inside themselves.
   if ( defined $testcase->{DATASET} ) {
      @testData = @{$testcase->{DATASET}};
      $count = scalar(@testData);
   }
   $failedIterations{'totalIterations'} = $count;

   $npClient = $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{netperf}{client};
   $npServer = $testcase->{RUNTIME}{WORKLOADS}{TRAFFIC}{netperf}{server};

   my $remTestIP = $npServer->GetTestIP();
   my $locTestIP = $npClient->GetTestIP();

   foreach my $d (@testData) {
      $vdLogger->Info("Launching TCPDUMP for capturing packets");
      if ( defined $testcase->{VERIFICATION}{TCPDUMP} ) {
         if ( VdPreTcpdumpSetup($testbed, $testcase) eq FAILURE ) {
            $vdLogger->Error( "TCPDUMP setup failed");
            return "FAIL";
         }
      }
      $vdLogger->Info("Starting netperf iteration $count with testdata:" .
                          " $d");
      $npClient->ClearTestOptions();
      $npClient->PrependTestOptions("-H $remTestIP -L $locTestIP");
      $npClient->AppendTestOptions($d);

      # TODO: there has to be a better way to get how netperf should be
      # executed
      if ( $testcase->{WORKLOADS}{TRAFFIC}{netperf}{nic} =~ /nic(.*)/i ) {
         $nicProp = $1;
         $mode = "async";
      } else {
         $nicProp = undef;
         $mode = "sync";
      }

      $vdLogger->Info("netperf mode is $mode");

      if ("FAILURE" eq $npClient->StartClient($mode)) {
         VDSetLastError(VDGetLastError());
         $vdLogger->Error( "NetperfWorkload: Starting netperf client " .
                            "failed");
         return "FAIL";
      }

      if ( ($mode =~ /async/i) && (defined $nicProp) ) {
         if ( ($ret = SetNICProps($testcase, $nicProp)) eq FAILURE ) {
             return "FAIL";
         }
      }

      if ( $d =~ /.* -l (\d+) .*/ ) {
         $timeout = $1 + 60;
      }

      if ( $mode =~ /async/i ) {

         #
         # Filp/Flop the Test Device
         #

         my $res1 =
             $testcase->{CONNECTION}{Source}{nicObj}->SetDeviceStatus('DOWN');
         if ($res1 eq FAILURE) {
            $vdLogger->Info("FAILED to Disable DUT");
            return "FAIL";
         } else {
            $vdLogger->Info("DUT is Disabled");
         }

         $vdLogger->Info("Enabiling DUT");
         my $res2 =
             $testcase->{CONNECTION}{Source}{nicObj}->SetDeviceStatus('UP');
         if ($res2 eq FAILURE) {
            $vdLogger->Info("FAILED to Enable DUT");
            return "FAIL";
         }

         ###code to Unload/Load the driver##
         my $ip = $testbed->GetSUTIP();
         my $fin;
         my $data;
         my $driver = $testcase->{CONNECTION}{Source}{nic}{DriverName};
         my $command1 = "rmmod $driver";
         my $res3 = "start shell command $command1 wait returnstdout" ;

         ($fin,$data) = $testbed->{stafHelper}->runStafCmd($ip,'process',$res3);
         if ($fin ne "FAILURE"){
            $vdLogger->Info("$driver Driver is unloaded ");
         } else {
            $vdLogger->Info("$driver Driver is Not Unloaded");
            return "FAIL";
         }

         my $command2 = "modprobe $driver";
         my $res5 = "start shell command $command2 wait returnstdout";
         ($fin,$data) = $testbed->{stafHelper}->runStafCmd($ip,'process',$res5);
         if ( $fin ne "FAILURE" ){
            $vdLogger->Info("$driver Driver is loaded ");
         } else {
            $vdLogger->Info("$driver Driver is Not loaded");
            return "FAIL";
         }

         #Refill the source adapter with ip and MTU, even it checks the
         #proper driver loaded or not
         my $dutRet = fillInConnection($testcase, $testbed,\%netAdapHash);
         if ( $dutRet eq FAILURE ) {
            $vdLogger->Info("Unable to find DUT,$dutRet");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         $ret = $npClient->Wait($timeout);
         if ( $ret eq FAILURE ) {
            $npClient->Stop();
         }
      }

      if ( ( $ret = VDNetLib::VDCommonSrvs::VdPostProcessing($testcase) ) =~ /fail/i ) {
         # TODO: parse the error code and return whether it is error in
         # product tool or script or setup (if applicable)
         $vdLogger->Error( "TCPDUMP Post Processing failed ");
         $failedIterations{pktCapFailures}++;
      }

      # TODO: Need to implement the right logic based on the traffic tool
      # output and tcpdump output
      # Scenarios to be covered
      # Netperf passes, packet capture failed because of some internal
      # mark the test pass as it is due to the script failure
      # Netperf failed, then irrespective of packet capture mark the test failed
      $ret = "PASS";
      my $netperfRetCode = $npClient->GetResult();

      $vdLogger->Debug("stdout of netperf:" . $npClient->{_stdout});
      my $npThroughput = $npClient->GetNetperfThruput();
      # On windows, changing nic properties restarts the driver and hence
      # netperf could fail, so if is windows, you can ignore it.
      if ($netperfRetCode ne "0") {
         # if it is windows and nicProp is defined then it is possible
         # the netperf sesssion got invalidated as setting any property
         # on windows require restarting the device
         if (!(($testbed->GetSUTOS =~ /win/i) && (defined $nicProp))) {
            $vdLogger->Error(
                      "netperf failed for iteration $count: $netperfRetCode");
            $vdLogger->Debug("stdout of netperf: $npClient->{_stdout}") 
               if (defined $npClient->{_stdout});
            $failedIterations{netperfFailures}++;
            $ret = "FAIL";
         }
      } elsif ($npThroughput eq FAILURE) {
         $vdLogger->Warn("Netperf->GetNetperfThruput failed");
         $failedIterations{netperfFailures}++;
      } elsif ($npThroughput eq "low") {
         $vdLogger->Warn("Netperf Throughput is either too low" .
                                " or empty\n:Netperf Output:" .
                                " $npClient->{_stdout}");
         $failedIterations{netperfFailures}++;
      }

      # TODO: fail the test case if packet capture fails when it becomes
      # robust, till then log a warning and report pass.  This is just to
      # avoid false indication if there is a bug in the automation script
      if ( defined $testcase->{VERIFICATION}{TCPDUMP}{handle} ) {
         if ( ($ret =~ /PASS/i) &&
              ($testcase->{VERIFICATION}{TCPDUMP}{result} =~ /fail/i) ) {
            $vdLogger->Warn("packet capture for iteration " .
                                   "$count failed - problem could be either".
                                   " in automation or product");
            $failedIterations{pktCapFailures}++;
         }
      }

      # TODO: need to find better way to figure out if there is more data
      $count = $count - 1;
   } # end of for loop

   # TODO: need to report the cummulative result here
   if ( $failedIterations{netperfFailures} > 0 ) {
      return "FAIL";
   } else {
      return "PASS";
   }
}


########################################################################
# PrepareTcpdumpExpr --
#        This routine fills in the runtime variables in the tcpdump
#        expression mentioned in the TDS hash
#        1. VDNetLib::GlobalConfig::TCPDUMP_EXPR has the key words and respective
#           NetAdapter method or other mechanism to get the value for the
#           key.
#        2. Call the method and replace the key in the tcpdump expression
#           from the TDS hash with value returned by the method
#
# Input:
#        testcase hash
#
# Resutls:
#       none
#
# Side effetcs:
#       testcase tcpdumpexpr key value is updated
#
########################################################################

sub PrepareTcpdumpExpr
{
   my $testcase = shift;
   my $end;
   my $tcpdumpExpr = $testcase->{VERIFICATION}{TCPDUMP}{tcpdumpExpr};
   my $gc = new VDNetLib::GlobalConfig;
   while ( my ($pattern, $val) = each %{$gc->TcpDumpExpr} )
   {
      # TODO: ideally keys of TCPDUMPEXPR should be have method names on
      # connection object
      my $direction = $testcase->{WORKLOADS}{TRAFFIC}{netperf};
      if (not defined $direction) {
         $direction = "outbound";
      }
      if ( $pattern =~ /src/ ) {
         $end = "Source";
      } elsif ( $pattern =~ /dst/ ) {
         $end = "Destination";
      }
      if ($direction =~ /inbound/i) {
         if ( $pattern =~ /dst/ ) {
	    $end = "Source";
	 } elsif ( $pattern =~ /src/ ) {
	    $end = "Destination";
	 }
      }

      if ( $tcpdumpExpr =~ m/\%$pattern\%/i ) {
         if ( not defined $end ) {
            $vdLogger->Warn("VDNetLib::VDCommonSrvs:tcpdump pre-processing ".
                                "connection end is undefined, tcpdump might " .
                                "might fail");
            next;
         }
         if ( (exists $testcase->{CONNECTION}{$end}{nic}{$val})  &&
              (defined $testcase->{CONNECTION}{$end}{nic}{$val}) ) {
            $tcpdumpExpr =~
                  s/\%$pattern\%/$testcase->{CONNECTION}{$end}{nic}{$val}/;
         } else {
            $vdLogger->Warn("Unable to form tcpdump expression hence ".
                                "not launching TCPDUMP");
            return FAILURE;
         }
      }
   }

   # save the tcpdumpExpr
   $testcase->{VERIFICATION}{TCPDUMP}{tcpdumpExpr} = $tcpdumpExpr;
   $vdLogger->Info("TCPDUMP EXPR: $tcpdumpExpr");
   return SUCCESS;
}

########################################################################
# SetNICProps --
#       This is used to set any nic properties from while running
#       any traffic workloads like netperf
#       1.  Get the property that needs to be set from the workload
#           hash and call set method of that property on the nic object
#           obtained from NetAdapter.
#
# Input:
#       testcase hash
#       nic property that needs to be set
#
# Results:
#       SUCCESS if set successfully else FAILURE
#
# Side effetcs:
#       none
#
########################################################################

sub SetNICProps
{
   my $testcase = shift;
   my $nicProp = shift;
   my ($nicPropStatus, $ret);

   # TODO: remove this check after the properties are defined at
   # some place
   if ( $nicProp =~ /tso/i ) {
      # TODO, disable TSO while netperf is running
      $nicPropStatus =
                $testcase->{CONNECTION}{Source}{nicObj}->GetOffload(
                                                            'TSOIPv4');
      # Do not return test case fail, just log a message and move on
      if ( $nicPropStatus eq FAILURE ) {
         $vdLogger->Error( "GetOffload(TSOIPv4) failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $nicPropStatus = ( $nicPropStatus =~ /enabled/i ) ? "Disable" : "Enable";
      if ( $nicPropStatus =~ /enable/i ) {
         # we need enable tx checksum and scatter gather for to turn on
         # TSO
         $ret = $testcase->{CONNECTION}{Source}{nicObj}->SetOffload(
                                                        'TCPTxChecksumIPv4',
                                                              $nicPropStatus);
         # dont worry about the error checking here, because it will get
         # caught when TSO enable is called and also this is not required
         # for windows
         #if ( $ret eq FAILURE ) {
         #   $vdLogger->Error( "SetOffload(TCPTxChecksumIPv4, $nicPropStatus)".
         #                      " failed ".
         #                   VDSetLastError(VDGetLastError()));
         #   return $ret;
         #}
         $ret = $testcase->{CONNECTION}{Source}{nicObj}->SetOffload(
                                                        'SG',
                                                         $nicPropStatus);
         #if ( $ret eq FAILURE ) {
         #   $vdLogger->Error( "SetOffload(SG, $nicPropStatus) failed".
         #                   VDSetLastError(VDGetLastError()));
         #   return $ret;
         #}
      }
      $ret = $testcase->{CONNECTION}{Source}{nicObj}->SetOffload('TSOIPv4',
                                                             $nicPropStatus);
      if  ( $ret eq FAILURE ) {
         $vdLogger->Error( "SetOffload(TSOIPv4, $nicPropStatus) failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   if ( $nicProp =~ /cso/i ) {
      # TODO, disable CSO while netperf is running
      $nicPropStatus =
                $testcase->{CONNECTION}{Source}{nicObj}->GetOffload(
                                                          'TCPTxChecksumIPv4');
      # Do not return test case fail, just log a message and move on
      if  ( $nicPropStatus eq FAILURE ) {
         $vdLogger->Error( "GetOffload(TCPTxChecksumIPv4) failed");
         VDSetLastError(VDGetLastError());
         return $nicPropStatus;
      }
      $nicPropStatus = ( $nicPropStatus =~ /enabled/i ) ? "Disable" : "Enable";
      $ret = $testcase->{CONNECTION}{Source}{nicObj}->SetOffload(
                                                        'TCPTxChecksumIPv4',
                                                              $nicPropStatus);
      if ( $ret eq FAILURE ) {
         $vdLogger->Error( "SetOffload(TCPTxChecksumIPv4, $nicPropStatus) ".
                            "failed ");
         VDSetLastError(VDGetLastError());
         return $ret;
      }
   }
}

1;
