#!/usr/bin/perl
########################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::VirtualNetDevices::VirtualNetDevicesTds;


# This file contains the structured hash for POTs vmxnet3 tests.
# The following lines explain the keys of the internal
# Hash in general.


use FindBin;
use lib "$FindBin::Bin/..";
use Data::Dumper;
use TDS::Main::VDNetMainTds;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack );

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("TCPUDPTraffic","PowerOnOff","SuspendResume",
            "DisconnectConnectvNIC","pptp","SnapshotRevertDelete",
            "EnableDisablevNIC","Checksum","JumboFrame",
            "JumboFrameOperations","JumboFramegVLAN",
            "JumboFramesVLAN","EnableDisableTSO",
            "TSOOperations","TSOgVLAN","TSOsVLAN","HotAddvNIC",
            "vSwitchMTU","StressSR","PowerOnOffPing","JFPingSR",
            "MultiTxQueueUDP","MultiTxQueueTCP","MultiTxQueueICMP",
            "DriverReload","MultiqueueTraffic","MultiTxQueueMSIX",
            "MultiQueueINTX","MultiTxQueueIntrusive","IO_RSS",
            "SetMAC","TSOIPV6","IPV6sVLAN","IPV6gVLAN",
            "TSOIPV6Operations","IPV6UDP","ChecksumIPV6",
            "InterruptModes","WOL","VMotion","ChangevNICStateDuringBoot");

   %VirtualNetDevices = (
      'EnableDisablevNIC' => {
         ParentTDSID       => "5.24",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "EnableDisablevNIC",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This tests that traffic works fine after disabling/ ".
                              "enabling the vNIC from inside the VM.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['DisableEnablevNic'],['TRAFFIC_1']],

            "DisableEnablevNic" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               DeviceStatus   => "DOWN,UP",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "20",
            },
         },
      },
      
        'pptp' => {
         ParentTDSID       => "5.24",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "pptp",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This tests that vpn traffic works fine/ ".
                              "with  the vNIC from inside the VM.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['e1000:1'],
            },
            helper1     => {
               vnic        => ['e1000:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['SetIPSUT'],['SetIPhelper'],['TRAFFIC_1']],

            "SetIPSUT" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               IPV4           => "192.168.1.11",
            },
            "SetIPhelper" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "helper1",
               TestAdapter    => "1",
               IPV4           => "192.168.1.5",
            },
           

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "pptp",
            },
         },
      },

      'EnableDisableTSO' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "EnableDisableTSO",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies enabling/disabling ".
                              "TSO feature of vNIC.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['DisableTSO'],['TRAFFIC_1'],
                                  ['EnableTSO'],['TRAFFIC_2']],

            "DisableTSO" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               TSOIPV4        => "Disable",
            },

            "EnableTSO" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               TSOIPV4        => "Enable",
            },

            "TRAFFIC_1" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               BurstType             => "stream",
               SendMessageSize       => "131072",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               Verification          => "PktCap",
               TestDuration          => "60",
            },

            "TRAFFIC_2" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               BurstType             => "stream",
               NoofOutbound          => "3",
               SendMessageSize       => "131072-4096,4096",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               Verification          => "PktCap",
               TestDuration          => "60",
               MaxTimeout            => "21600",
            },
         },
      },

      'TSOOperations' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "TSOOperations",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies TSO functionality ".
                              "before and after Suspend/Resume, Snapshot/ ".
                              "Revert Operations.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['EnableTSO'],
                                  ['TRAFFIC_1'],['SuspendResume'],
                                  ['TRAFFIC_1'],
                                  ['SnapshotRevert'],['TRAFFIC_1'],
                                  ['SnapshotDelete'],['TRAFFIC_1']],
            ExitSequence      => [['SnapshotDelete']],

            "EnableTSO" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               TSOIPV4        => "Enable",
            },

            "TRAFFIC_1" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               BurstType             => "stream",
               SendMessageSize       => "131072",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               Verification          => "PktCap",
               TestDuration          => "60",
            },

            "SuspendResume" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "suspend,resume",
            },

            "SnapshotRevert" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "createsnap,revertsnap",
               SnapshotName   => "tso_srd",
               WaitForVDNet   => "1",
            },

            "SnapshotDelete" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "rmsnap",
               SnapshotName   => "tso_srd",
               WaitForVDNet   => "1",
            },
         },
      },

      'JumboFrameOperations' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "JumboFrameOperations",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies JumboFrame functionality ".
                              "before and after Suspend/Resume, Snapshot/ ".
                              "Revert Operations.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['MTU'],
                                  ['TRAFFIC_1'],['SuspendResume'],
                                  ['TRAFFIC_1'],
                                  ['SnapshotRevert'],['TRAFFIC_1'],
                                  ['SnapshotDelete'],['TRAFFIC_1']],
            ExitSequence      => [['MTUDefault'],['SnapshotDelete']],


            "MTU" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               MTU            => "9000",
            },

            "TRAFFIC_1" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream,rr",
               L4Protocol                => "udp",
               NoofOutbound              => "3",
               NoofInbound               => "3",
               SendMessageSize           => "63488",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "60",
            },

            "SuspendResume" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "suspend,resume",
            },

            "SnapshotRevert" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "createsnap,revertsnap",
               SnapshotName   => "jf_srd",
               WaitForVDNet   => "1",
            },

            "SnapshotDelete" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "rmsnap",
               SnapshotName   => "jf_srd",
               WaitForVDNet   => "1",
            },

            "MTUDefault" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               MTU            => "1500",
            },
         },
      },

      'Checksum' => {
         ParentTDSID       => "3.3",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "Checksum",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies Checksum Offloading ".
                              "and also Checksum Disable functionality.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['CSOEnable'],['TRAFFIC_1'],
                                  ['CSODisable'],['TRAFFIC_1'],
				  ['CSOEnable'],['EnableSG'],['EnableTSO']],

            "CSOEnable" => {
               Type              => "NetAdapter",
               Iterations        => "1",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               TCPTxChecksumIPv4 => "Enable",
               TCPRxChecksumIPv4 => "Enable",
            },

            "CSODisable" => {
               Type              => "NetAdapter",
               Iterations        => "1",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               TCPTxChecksumIPv4 => "Disable",
               TCPRxChecksumIPv4 => "Disable",
            },

            "EnableSG" => {
               Type              => "NetAdapter",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               SG                => "Enable",
            },

            "EnableTSO" => {
               Type              => "NetAdapter",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               TSOIPV4           => "Enable",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               Verification   => "PktCap",
               TestDuration   => "60",
            },
         },
      },

      'WOL' => {
         ParentTDSID       => "5.15",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "WOL",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that WOL works fine.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['ConfigureIP'],['WoLTest']],

            "ConfigureIP"     => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               IPv4           => "AUTO",
            },

            "WoLTest" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               WOL            => "ARP,MAGIC",
            },
         },
      },

      'InterruptModes' => {
         ParentTDSID       => "5.15",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "InterruptModes",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies various interrupt modes.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['IntrModes_1'],['Traffic'],
                                  ['IntrModes_2'],['Traffic'],
                                  ['IntrModes_3'],['Traffic'],
                                  ['IntrModes_4'],['Traffic'],
                                  ['IntrModes_5'],['Traffic'],
                                  ['IntrModes_6'],['Traffic']],
            ExitSequence      => [['SetDefault']],

            "IntrModes_1" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "AUTO-INTX",
            },
            "IntrModes_2" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "AUTO-MSI",
            },
            "IntrModes_3" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "AUTO-MSIX",
            },
            "IntrModes_4" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "ACTIVE-INTX",
            },
            "IntrModes_5" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "ACTIVE-MSI",
            },
            "IntrModes_6" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "ACTIVE-MSIX",
            },
            "Traffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "10",
            },
            "SetDefault" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "AUTO-MSIX",
            },
         },
      },

      'SuspendResume' => {
         ParentTDSID       => "5.5",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "SuspendResume",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Test connectivity after Suspend/Resume",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['SuspendResume'],['TRAFFIC_1']],

            "SuspendResume" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "suspend,resume",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestAdapter    => "SUT:vnic:1",
               SupportAdapter => "helper1:vnic:1",
               TestDuration   => "60",
            },
         },
      },

      'PowerOnOff' => {
         ParentTDSID       => "5.18",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "PowerOnOff",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests connectivity after Power On/Off",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['PowerOnOff'],['TRAFFIC_1']],

            "PowerOnOff" => {
               Type           => "VM",
               Operation      => "poweroff,poweron",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
            },
         },
      },

      'SnapshotRevertDelete' => {
         ParentTDSID       => "5.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "SnapshotRevertDelete",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests connectivity after Snapshot/Revert/Delete",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['SnapshotRevert'],['TRAFFIC_1'],
                                  ['SnapshotDelete']],
            ExitSequence      => [['SnapshotDelete']],

            "SnapshotRevert" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "createsnap,revertsnap,rmsnap",
               SnapshotName   => "srd",
               WaitForVDNet   => "1",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "200",
            },

            "SnapshotDelete" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "rmsnap",
               SnapshotName   => "srd",
               WaitForVDNet   => "1",
            },
         },
      },

      'DisconnectConnectvNIC' => {
         ParentTDSID       => "5.23",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "DisconnectConnectvNIC",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests network connectivity after Cable Disconnect/".
	                      "connect.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['DisconnectConnectvNic'],['TRAFFIC_1']],

            "DisconnectConnectvNic" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1",
               Iterations     => "1",
               Operation      => "DISCONNECTVNIC,CONNECTVNIC",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
            },
         },
      },

      'TCPUDPTraffic' => {
         ParentTDSID       => "7.1",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "LongDuration",
         TestName          => "TCPUDPTraffic",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies TCP/UDP Traffic ".
	                      "stressing both inbound and outbound paths.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['TCPTraffic'],['UDPTraffic']],

            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream,rr",
               NoofInbound               => "3",
               NoofOutbound              => "2",
               SendMessageSize           => "131072-16384,16384",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "60",
               MaxTimeout                => "8100",
            },

            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream,rr",
               L4Protocol                => "udp",
               NoofInbound               => "3",
               NoofOutbound              => "2",
               SendMessageSize           => "63488-8192,15872",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "60",
               ExpectedResult            => "IGNORE", # PR743918
               MaxTimeout                => "8100",
            },
         },
      },

      'JumboFrame' => {
         ParentTDSID       => "7.2",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "JumboFrame",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests Jumbo Frame end-to-end traffic.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Switch_1'],['Switch_2'],
                                  ['MTU9000'],['TRAFFIC_1'],['MTU1500'],
                                  ['Switch_3'],['Switch_4']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "9000",
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "9000",
            },

            "Switch_3" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "1500",
            },

            "Switch_4" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "1500",
            },

            "MTU9000" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "9000",
            },

            "MTU1500" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "1500",
            },

            "TRAFFIC_1" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream,rr",
               L4Protocol                => "udp",
               NoofInbound               => "3",
               NoofOutbound              => "3",
               SendMessageSize           => "63488-8192,15872",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "60",
               MaxTimeout                => "14400",
            },
         },
      },

      'JumboFramegVLAN' => {
         ParentTDSID       => "7.1",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "JumboFramegVLAN",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests JumboFrame with gVLAN ",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Switch_1'],['Switch_2'],
                                  ['NetAdapter_1'],['TRAFFIC_1']],
            ExitSequence      => [['NetAdapter_2'],['Switch_3'],['Switch_4']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "9000",
               VLAN           => "4095",
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "9000",
               VLAN           => "4095",
            },

            "Switch_3" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "1500",
               VLAN           => "0",
            },

            "Switch_4" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "1500",
               VLAN           => "0",
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "9000",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "1500",
               VLAN           => "0",
            },

            "TRAFFIC_1" => {  # TODO - verify the traffic data with packet
                              #  capture
               Type                 => "Traffic",
               ToolName             => "netperf",
               BurstType            => "stream",
               L4Protocol           => "udp",
               NoofInbound          => "2",
               NoofOutbound         => "2",
               SendMessageSize      => "1024,2048,4096,8000",
               ReceiveMessageSize   => "9000",
               LocalSendSocketSize  => "131072",
               RemoteSendSocketSize => "131072",
               #Verification         => "PktCap", # TODO - 3rd VM is need to
                                                  # capture vlan packets
               TestDuration         => "10",
            },
         },
      },

      'JumboFramesVLAN' => {
         ParentTDSID       => "7.1",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "JumboFramesVLAN",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests JumboFrame with Switch VLAN ",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Switch_1'],['Switch_2'],
                                  ['NetAdapter_1'],['TRAFFIC_1'],['NetAdapter_2'],
                                  ['Switch_3'],['Switch_4']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "9000",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "9000",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "9000",
            },

            "TRAFFIC_1" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream,rr",
               L4Protocol                => "udp",
               NoofInbound               => "3",
               NoofOutbound              => "3",
               SendMessageSize           => "63488-8192,15872",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "60",
               MaxTimeout                => "14400",
            },

            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "1500",
            },

            "Switch_3" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "1500",
               VLAN           => "0",
            },

            "Switch_4" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "1500",
               VLAN           => "0",
            },
         },
      },

      'TSOsVLAN' => {
         ParentTDSID       => "7.1",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "TSOsVLAN",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests TSO with Switch VLAN ",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Switch_1'],['Switch_2'],
                                  ['EnableTSO'],['TRAFFIC_1'],
                                  ['Switch_3'],['Switch_4']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "EnableTSO" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TSOIPV4        => "Enable",
            },

            "TRAFFIC_1" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               BurstType             => "stream",
               NoofOutbound          => "3",
               SendMessageSize       => "1024,2048,4096,8192,16384,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               TestDuration          => "30",
            },

            "Switch_3" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => "0",
            },

            "Switch_4" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => "0",
            },
         },
      },

      'TSOgVLAN' => {
         ParentTDSID       => "7.1",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "TSOgVLAN",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests TSO with gVLAN ",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Switch_1'],['Switch_2'],
                                  ['NetAdapter_1'],['NetAdapter_2'],
                                  ['Switch_3'],['Switch_4']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => "4095",
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => "4095",
            },

            "Switch_3" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => "0",
            },

            "Switch_4" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => "0",
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TSOIPV4        => "Enable",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D . "," . VDNetLib::Common::GlobalConfig::VDNET_VLAN_E,
               RunWorkload    => "TRAFFIC_1",
               MaxTimeout     => "21600",
            },

            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               VLAN           => "0",
            },

            "TRAFFIC_1" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               BurstType             => "stream",
               NoofOutbound          => "3",
               SendMessageSize       => "1024,2048,4096,8192,16384,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               TestDuration          => "30",
               MaxTimeout            => "21600",
            },
         },
      },

      'HotAddvNIC' => {
         ParentTDSID       => "5.18",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "HotAddvNIC",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests connectivity after Power On/Off",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['TRAFFIC_1'],
                                  ['HotAdd'],['TRAFFIC_2'],
                                  ['HotRemove'],['TRAFFIC_1']],

            "HotAdd" => {
               Type           => "VM",
               Target         => "SUT",
               Operation      => "hotaddvnic",
               TestAdapter    => "1", # to pick same driver as what is
                                      # defined under parameters hash
               PortgroupName  => "1", # to pick portgroup same as SUT:vnic:1
            },

            "HotRemove" => {
               Type           => "VM",
               Target         => "SUT",
               Operation      => "hotremovevnic",
               TestAdapter    => "2", # to pick the adapter added in HotAdd
                                      # workload
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "20",
               NoOfInbound    => "1",
               NoOfOutbound   => "1",
               TestAdapter    => "SUT:vnic:1",
               SupportAdapter => "helper1:vnic:1",
            },

            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "20",
               NoOfInbound    => "1",
               NoOfOutbound   => "1",
               TestAdapter    => "SUT:vnic:1,SUT:vnic:2",
               SupportAdapter => "helper1:vnic:1",
            },
         },
      },

      'vSwitchMTU' => {
         ParentTDSID       => "7.2",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "vSwitchMTU",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests vSwitch MTU sizes.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Switch_1'],['Switch_2']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "1500-9000,500",
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "1500",
            },
         },
      },

      'StressSR' => {
         ParentTDSID       => "5.5",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Stress",
         TestName          => "StressSR",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Performs multiple Suspend/Resume",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['SuspendResume'],['TRAFFIC_1']],

            "SuspendResume" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "10",
               Operation      => "suspend,resume",
               MaxTimeout     => "5400",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
            },
         },
      },

      'PowerOnOffPing' => {
         ParentTDSID       => "5.18",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "PowerOnOffPing",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests ICMP connectivity after Power On/Off",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Ping'],['PowerOnOff'],['Ping']],

            "PowerOnOff" => {
               Type           => "VM",
               Operation      => "poweroff,poweron",
            },

            "Ping" => {
               Type             => "Traffic",
               ToolName         => "ping",
               NoofInbound      => "3",
               NoofOutbound     => "2",
               PingPktSize      => "3000",
               TestDuration     => "20",
            },
         },
      },

      'JFPingSR' => {
         ParentTDSID       => "5.18",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "JFPingSR",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests JumboFrame ping across Suspend/Resume",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['MTU9000'],['Ping'],['SuspendResume'],
                                  ['Ping'],['MTU1500']],

            "MTU9000" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "9000",
            },

            "SuspendResume" => {
               Type           => "VM",
               Operation      => "suspend,resume",
            },

            "Ping" => {
               Type             => "Traffic",
               ToolName         => "ping",
               PktFragmentation => "no",
               PingPktSize      => "8000",
               TestDuration     => "10",
            },

            "MTU1500" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "1500",
            },
         },
      },

      'MultiTxQueueUDP' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "LongDuration,SMP",
         TestName          => "MultiTxQueueUDP",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Enables/disables Multi Tx Queue ".
                              "and tests UDP Traffic aross multiple ".
                              "queues.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         # Test has to be run with 8 vCPU's pre-configured in the VM since we
         # do not support HotAdd vCPU
         WORKLOADS => {
            Sequence          => [['RSS'],['EnableTxQueue']],
            ExitSequence      => [['DisableTxQueue'],['DisableRSS']],

            "RSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Enable",
            },

            "EnableTxQueue" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1,2,8,4",
               RunWorkload    => "UDPTraffic",
               MaxTimeout     => "8100",
            },

            "DisableTxQueue" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1",
            },

            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream",
               L4Protocol                => "udp",
               NoofOutbound              => "3",
               SendMessageSize           => "63488,8192",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "Stats",
               TestDuration              => "60",
            },

            "DisableRSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Disable",
            },
         },
      },

      'MultiTxQueueTCP' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "LongDuration,SMP",
         TestName          => "MultiTxQueueTCP",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Enables/disables Multi Tx Queue ".
                              "and tests TCP Traffic aross multiple ".
                              "queues.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         # Test has to be run with 8 vCPU's pre-configured in the VM since we
         # do not support HotAdd vCPU
         WORKLOADS => {
            Sequence          => [['RSS'],['EnableTxQueue']],
            ExitSequence      => [['DisableTxQueue'],['DisableRSS']],

            "RSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Enable",
            },

            "EnableTxQueue" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1,2,8,4",
               RunWorkload    => "TCPTraffic",
               MaxTimeout     => "8100",
            },

            "DisableTxQueue" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1",
            },

            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               NoofOutbound              => "4",
               BurstType                 => "stream",
               L4Protocol                => "tcp",
               SendMessageSize           => "131072,8192",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "Stats",
               TestDuration              => "60",
            },

            "DisableRSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Disable",
            },
         },
      },

      'MultiTxQueueICMP' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "LongDuration,SMP",
         TestName          => "MultiTxQueueICMP",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Enables/disables Multi Tx Queue ".
                              "and tests ICMP Traffic aross multiple ".
                              "queues.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         # Test has to be run with 8 vCPU's pre-configured in the VM since we
         # do not support HotAdd vCPU
         WORKLOADS => {
            Sequence          => [['RSS'],['EnableTxQueue']],
            ExitSequence      => [['DisableTxQueue'],['DisableRSS']],

            "RSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Enable",
            },

            "EnableTxQueue" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1,2,8,4",
               RunWorkload    => "ICMPTraffic",
            },

            "DisableTxQueue" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1",
            },

            "ICMPTraffic" => {
               Type           => "Traffic",
               ToolName       => "ping",
               NoofInbound    => "3",
               RoutingScheme  => "unicast",
               NoofOutbound   => "2",
            },

            "DisableRSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Disable",
            },
         },
      },

      'MultiTxQueueMSIX' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "LongDuration,SMP",
         TestName          => "MultiTxQueueMSIX",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Enables/disables Multi Tx Queue ".
                              "and tests TCP Traffic aross multiple ".
                              "queues with MSIx Interrupt.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         # Test has to be run with 8 vCPU's pre-configured in the VM since we
         # do not support HotAdd vCPU
         WORKLOADS => {
            Sequence          => [['RSS'],['MSIX'],['TxQueueTCP'],
                                  ['DisableTxQueue'],['TxQueueUDP']],

            # Default Interrupt is set to AUTO-MSIX so not setting default here.
            ExitSequence      => [['DisableTxQueue'],['DisableRSS']],

            "RSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Enable",
            },

            "MSIX" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "AUTO-MSIX",
            },

            "TxQueueTCP" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1,2,8,4",
               RunWorkload    => "TCPTraffic",
               MaxTimeout     => "16200",
            },

            "TxQueueUDP" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1,2,8,4",
               RunWorkload    => "UDPTraffic",
               MaxTimeout     => "16200",
            },

            "DisableTxQueue" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1",
            },

            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream",
               L4Protocol                => "tcp",
               NoofOutbound              => "4",
               SendMessageSize           => "131072,8192",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "60",
            },

            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream",
               L4Protocol                => "udp",
               NoofOutbound              => "3",
               SendMessageSize           => "63488,8192",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "60",
            },

            "DisableRSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Disable",
            },
         },
      },

      'MultiQueueINTX' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "LongDuration,SMP",
         TestName          => "MultiQueueINTX",
         AutomationStatus  => "automated",
         Priority          => "P1",
         Summary           => "Enables/disables Multi Queue ".
                              "and tests TCP Traffic aross multiple ".
                              "queues with INTx Interrupt. In INTX mode only ".
                              "multi rx queues are supported but not multi rx.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         # Test has to be run with 8 vCPU's pre-configured in the VM since we
         # do not support HotAdd vCPU
         WORKLOADS => {
            Sequence          => [['RSS'],['INTX'],['MultiQueueTCP'],
                                  ['DisableMultiQueues'],['MultiQueueUDP']],

            # Default Interrupt is set to AUTO-MSIX.
            ExitSequence      => [['DisableMultiQueues'],['DisableRSS'],['Default']],

            "RSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Enable",
            },

            "INTX" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "AUTO-INTX",
            },

            "MultiQueueTCP" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1,2,8,4",
               MaxRxQueues    => "1,2,8,4",
               RunWorkload    => "TCPTraffic",
               MaxTimeout     => "16200",
            },

            "MultiQueueUDP" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1,2,8,4",
               MaxRxQueues    => "1,2,8,4",
               RunWorkload    => "UDPTraffic",
               MaxTimeout     => "16200",
            },

            "DisableMultiQueues" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1",
               MaxRxQueues    => "1",
            },

            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream",
               L4Protocol                => "tcp",
               NoofOutbound              => "4",
               SendMessageSize           => "131072,8192",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "60",
            },

            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               BurstType                 => "stream",
               L4Protocol                => "udp",
               NoofOutbound              => "3",
               SendMessageSize           => "63488,8192",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "60",
            },

            "DisableRSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Disable",
            },

            "Default" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               IntrMode       => "AUTO-MSIX",
            },
         },
      },

      'MultiTxQueueIntrusive' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "LongDuration,SMP",
         TestName          => "MultiTxQueueIntrusive",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Enables/disables Multi Tx Queue ".
                              "and simultaneously performs Enable/Disable vNIC, ".
                              "enable/disable TSO & suspend/resume/snapshot/revert ".
                              "operations aross multiple queues.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:2'],
            },
            helper1     => {
               vnic        => ['vmxnet3:2'],
            },
         },

         # Test has to be run with 8 vCPU's pre-configured in the VM since we
         # do not support HotAdd vCPU
         WORKLOADS => {
            Sequence          => [['RSS'],['EnableTxQueue','DisableEnablevNic'],
                                  ['DisableTxQueue'],['EnableTxQueue','DisableEnableTSO'],
                                  ['DisableTxQueue'],['SuspendResume'],['EnableTxQueue'],
                                  ['SnapshotRevert'],['SnapshotDelete']],
            ExitSequence      => [['DisableTxQueue'],['DisableRSS'],['SnapshotDelete']],

            "RSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Enable",
            },

            "EnableTxQueue" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1,2,8,4",
               RunWorkload    => "ICMPTraffic",
            },

            "DisableEnablevNic" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "2",
               DeviceStatus   => "DOWN,UP",
            },

            "DisableEnableTSO" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "2",
               TSOIPV4        => "Disable,Enable",
            },

            "DisableTxQueue" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "1",
            },

            "ICMPTraffic" => {
               Type           => "Traffic",
               ToolName       => "ping",
               NoofInbound    => "3",
               RoutingScheme  => "unicast",
               NoofOutbound   => "2",
            },

            "SuspendResume" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "suspend,resume",
            },

            "SnapshotRevert" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "createsnap,revertsnap",
               SnapshotName   => "tso_srd",
               WaitForVDNet   => "1"
            },

            "SnapshotDelete" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "rmsnap",
               SnapshotName   => "tso_srd",
               WaitForVDNet   => "1"
            },

            "DisableRSS" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "Disable",
            },
         },
      },

      'IO_RSS' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "LongDuration",
         TestName          => "IO_RSS",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Verifies the robustness of RSS IO Path.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:2'],
            },
            helper1     => {
               vnic        => ['vmxnet3:2'],
            },
         },

         # Test has to be run with 4 vCPU's pre-configured on both SUT,helper VM
         # since we do not support HotAdd vCPU.
         WORKLOADS => {
            Sequence          => [['RSS'],['TCPIPV4'],['UDPTraffic'],
                                  ['IPV6'],['ICMP'],['ICMPIGNORE','DisableEnableRSS'],
                                  ['Switch_1'],['Switch_2'],['MTU9000'],
                                  ['UDPTraffic'],['IPV6'],['ICMP'],
                                  ['ICMPIGNORE','DisableEnableRSS'],['MTU1500'],
                                  ['Switch_3'],['Switch_4'],['CSODisable'],
                                  ['TCPIPV4'],['UDPTraffic'],['IPV6'],['ICMP'],
				  ['CSOEnable'],['EnableSG'],
                                  ['Switch_5'],['Switch_6'],['gVLAN'],['gVLANDisable'],
                                  ['TCPIPV4'],['UDPTraffic'],['IPV6'],['ICMP'],
                                  ['ICMPIGNORE','DisableEnableRSS']],

            # Default Interrupt is set to AUTO-MSIX.
            ExitSequence      => [['DisableRSS'],['CSOEnable'],['EnableSG'],['EnableTSO']],

            "RSS" => {
               Type                  => "NetAdapter",
               Iterations            => "1",
               Target                => "SUT",
               TestAdapter           => "1",
               RSS                   => "Enable",
            },

            "DisableEnableRSS" => {
               Type                  => "NetAdapter",
               Iterations            => "30",
               Target                => "SUT",
               TestAdapter           => "2",
               RSS                   => "Disable,Enable",
	       MaxTimeout            => "10800",
            },

            "TCPIPV4" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               L4Protocol            => "tcp",
               BurstType             => "stream",
               NoofOutbound          => "6",
               NoofInbound           => "6",
               SendMessageSize       => "8192",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               TestDuration          => "30",
               Verification          => "Stats",
            },

            "UDPTraffic" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               BurstType             => "stream",
               L4Protocol            => "udp",
               NoofOutbound          => "8",
               NoofInbound           => "8",
               SendMessageSize       => "8192",
               LocalSendSocketSize   => "16384",
               RemoteSendSocketSize  => "16384",
               Verification          => "Stats",
               TestDuration          => "30",
            },

            "IPV6" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               L3Protocol            => "ipv6",
               NoofInbound           => "5",
               NoofOutbound          => "5",
               SendMessageSize       => "16384",
               LocalSendSocketSize   => "65536",
               RemoteSendSocketSize  => "65536",
               #Verification          => "Stats",
               TestDuration          => "30",
            },

            "ICMP" => {
               Type                  => "Traffic",
               ToolName              => "ping",
               RoutingScheme         => "unicast",
               NoofOutbound          => "20",
               NoofInbound           => "20",
               TestDuration          => "60",
            },

            "ICMPIGNORE" => {
               Type                  => "Traffic",
               ToolName              => "ping",
               RoutingScheme         => "unicast",
               NoofOutbound          => "20",
               NoofInbound           => "20",
               TestDuration          => "60",
               ExpectedResult        => "IGNORE",
            },

            "DisableRSS" => {
               Type                  => "NetAdapter",
               Iterations            => "1",
               Target                => "SUT",
               TestAdapter           => "1",
               RSS                   => "Disable",
            },

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "9000",
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "9000",
            },

            "Switch_3" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               MTU            => "1500",
            },

            "Switch_4" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               MTU            => "1500",
            },

            "MTU9000" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "9000",
            },

            "MTU1500" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "1500",
            },

            "CSOEnable" => {
               Type              => "NetAdapter",
               Iterations        => "1",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               TCPTxChecksumIPv4 => "Enable",
               TCPRxChecksumIPv4 => "Enable",
            },

            "CSODisable" => {
               Type              => "NetAdapter",
               Iterations        => "1",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               TCPTxChecksumIPv4 => "Disable",
               TCPRxChecksumIPv4 => "Disable",
            },

            "EnableSG" => {
               Type              => "NetAdapter",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               SG                => "Enable",
            },

            "EnableTSO" => {
               Type              => "NetAdapter",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               TSOIPV4           => "Enable",
            },

            "Switch_5" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => "4095",
            },

            "Switch_6" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => "4095",
            },

            "Switch_7" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => "0",
            },

            "Switch_8" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => "0",
            },

            "gVLAN" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TSOIPV4        => "Enable",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "gVLANDisable" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               VLAN           => "0",
            },
         },
      },

      'DriverReload' => {
           Component         => "Vmxnet3",
           Category          => "Virtual Net Devices",
           TestName          => "DriverReload",
           Tags              => "Functional,WindowsNotSupported",
           Summary           => "Load the driver with the given " .
                                "command line arguments (if any)",
           ExpectedResult    => "PASS",

           Parameters  => {
            Override => 0,
            SUT => {
               vnic        => ['vmxnet3:1'],
               },
            helper1 => {
               vnic        => ['vmxnet3:1'],
               },
            },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['DriverReload_1'],['ConfigureIP'],
				  ['NetperfTraffic'],
				  ['DriverReload_2'],['ConfigureIP'],
				  ['NetperfTraffic'],
				  ['DriverReload_3'],['ConfigureIP'],
				  ['NetperfTraffic'],
				  ['DriverReload_4'],['ConfigureIP'],
				  ['NetperfTraffic'],
				  ['DriverReload_5'],['ConfigureIP'],
				  ['NetperfTraffic'],
				  ['DriverReload_6'],['ConfigureIP'],
				  ['NetperfTraffic'],
				  ['DriverReload_7'],['ConfigureIP'],
				  ['NetperfTraffic']],
            ExitSequence      => [['DriverReload_6']],

            "DriverReload_1" => {
               Type           => "NetAdapter",
               Iterations        => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues     => "1,2,4,8",
            },
            "DriverReload_2" => {
               Type           => "NetAdapter",
               Iterations        => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               RSS            => "num_tqs:2::num_rqs:2::rss_ind_table:0:" .
                                 "1:0:0:0:0:0:0:1:0:0:0:0:0:0:1:0:0:0:0:" .
                                 "0:0:0:0:0:0:0:0:0:0:0:0",
            },
            "DriverReload_3" => {
               Type           => "NetAdapter",
               Iterations        => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               IntrModParams     => "num_tqs:2::num_rqs:2::share_tx_intr:1",
            },
            "DriverReload_4" => {
               Type           => "NetAdapter",
               Iterations        => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               IntrModParams  => "num_tqs:2::num_rqs:2::buddy_intr:1",
            },
            "DriverReload_5" => {
               Type           => "NetAdapter",
               Iterations        => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               IntrModParams  => "num_tqs:2::num_rqs:2::share_tx_intr:1::" .
                                 "buddy_intr:1",
            },
            "DriverReload_6" => {
               Type           => "NetAdapter",
               Iterations        => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               DriverReload     => "null",
            },
            "DriverReload_7" => {
               Type           => "NetAdapter",
               Iterations        => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxRxQueues     => "1,2,4,8",
            },
            "NetperfTraffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               Verification   => "PktCap",
               TestDuration   => "60",
            },
            "ConfigureIP"     => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               IPv4           => "AUTO",
            },
         },
      },

      'MultiqueueTraffic' => {
           Component         => "Vmxnet3",
           Category          => "Virtual Net Devices",
           TestName          => "MultiqueueTraffic",
           Tags              => "Functional,SMP",
           Summary           => "Load the driver with multiple queues and " .
                                "send different types of traffic",
           ExpectedResult    => "PASS",

           Parameters  => {
            Override => 0,
            SUT => {
               vnic        => ['vmxnet3:1'],
               },
            helper1 => {
               vnic        => ['vmxnet3:1'],
               },
            },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['SetTxQueues'],['NetperfTraffic'],
				  ['SetRxQueues'],['NetperfTraffic'],
				  ['PingTraffic']],
            ExitSequence      => [['SetDefaultQueues']],

            "SetTxQueues" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxTxQueues    => "2,4,8",
            },
            "SetRxQueues" => {
               Type           => "NetAdapter",
               Iterations        => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxRxQueues    => "2,4,8",
            },
            "NetperfTraffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp,udp",
               NoofInbound    => "8",
               NoofOutbound   => "8",
               # Verify that the traffic distribution happens properly
               # across multiple queues
               Verification   => "Stats",
               TestDuration   => "100",
            },
            "PingTraffic" => {
               Type           => "Traffic",
               ToolName       => "ping",
               Verification   => "Stats",
               TestDuration   => "100",
            },
            "SetDefaultQueues" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               MaxRxQueues    => "1",
               MaxTxQueues    => "1",
            },
         },
      },

     'SetMAC' => {
           Component         => "Vmxnet3",
           Category          => "Virtual Net Devices",
           TestName          => "SetMAC",
           Tags              => "Functional",
           Summary           => "Set the interface with the given " .
                                "MAC address ",
           ExpectedResult    => "PASS",

           Parameters  => {
            SUT => {
               vnic        => ['vmxnet3:1'],
               },
            helper1 => {
               vnic        => ['vmxnet3:1'],
               },
            },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['SetMAC_1'],['ResetMAC']],
            ExitSequence      => [['ResetMAC']],

            "SetMAC_1" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT",
               TestAdapter    => "1",
               SetMACAddr     => "00:11:22:33:44:55",
            },

            "ResetMAC" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1",
               SetMACAddr     => "reset",
            },
         },
      },

      'TSOIPV6' => {
         ParentTDSID       => "7.1",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         TestName          => "TSOIPV6",
         Summary           => "Set IPv6 address on both SUT and helper and run IPv6 " .
                              "traffic using netperf with TSO enabled ",
         Tags              => "Functional",
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['EnableTSO'],['TRAFFIC_1']],

            "EnableTSO" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TSOIPV4        => "Enable",
            },

            "TRAFFIC_1" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               L3Protocol            => "ipv6",
               SendMessageSize       => "1024,2048,4096,8192,16384,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               TestDuration          => "30",
               MaxTimeout            => "5400",
            },
         },
      },

      'IPV6sVLAN' => {
         ParentTDSID       => "7.1",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "IPV6sVLAN",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests IPV6 with Switch VLAN ",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Switch_1'],['Switch_2'],
                                  ['TRAFFIC_1'],
                                  ['Switch_3'],['Switch_4']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "TRAFFIC_1" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               L3Protocol            => "ipv6",
               SendMessageSize       => "1024,2048,4096,8192,16384,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               TestDuration          => "30",
               MaxTimeout            => "5400",
            },

            "Switch_3" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => "0",
            },

            "Switch_4" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => "0",
            },
         },
      },

      'IPV6gVLAN' => {
         ParentTDSID       => "7.1",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "IPV6gVLAN",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests IPV6 with gVLAN ",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['Switch_1'],['Switch_2'],
                                  ['NetAdapter_1'],['TRAFFIC_1'],['NetAdapter_2'],
                                  ['Switch_3'],['Switch_4']],

            "Switch_1" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => "4095",
            },

            "Switch_2" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => "4095",
            },

            "Switch_3" => {
               Type           => "Switch",
               Target         => "SUT",
               TestAdapter    => "1",
               VLAN           => "0",
            },

            "Switch_4" => {
               Type           => "Switch",
               Target         => "helper1",
               TestAdapter    => "1",
               VLAN           => "0",
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TSOIPV4        => "Enable",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               VLAN           => "0",
            },

             "TRAFFIC_1" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               L3Protocol            => "ipv6",
               SendMessageSize       => "1024,2048,4096,8192,16384,65536",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               TestDuration          => "30",
	           TestAdapter           => "SUT:vnic:1",
               SupportAdapter        => "helper1:vnic:1",
               Verification          => "Verification",
               MaxTimeout            => "5400",
            },
            "Verification" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "helper1:vnic:1",
                  dst.pktcapfilter          => "vlan " . VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                  pktcount         => "1000+",
                  badpkt           => "0",
               },
            },
         },
      },

      'TSOIPV6Operations' => {
         ParentTDSID       => "3.4",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "TSOIPV6Operations",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies IPV6 TSO functionality ".
                              "before and after Suspend/Resume, Snapshot/ ".
                              "Revert Operations.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            Override => 0,
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['EnableTSO'],
                                  ['TRAFFIC_1'],['SuspendResume'],
                                  ['TRAFFIC_1'],
                                  ['SnapshotRevert'],['TRAFFIC_1'],
                                  ['SnapshotDelete'],['TRAFFIC_1']],
            ExitSequence      => [['SnapshotDelete']],

            "EnableTSO" => {
               Type           => "NetAdapter",
               Iterations     => "1",
               Target         => "SUT,helper1",
               TestAdapter    => "1",
               TSOIPV4        => "Enable",
            },

            "TRAFFIC_1" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
	            L3Protocol            => "ipv6",
               SendMessageSize       => "131072",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               Verification          => "PktCap",
               TestDuration          => "60",
            },

            "SuspendResume" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "suspend,resume",
            },

            "SnapshotRevert" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "createsnap,revertsnap",
               SnapshotName   => "tsoipv6_srd",
               WaitForVDNet   => "1",
            },

            "SnapshotDelete" => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "rmsnap",
               SnapshotName   => "tsoipv6_srd",
               WaitForVDNet   => "1",
            },
         },
      },

      'IPV6UDP' => {
         ParentTDSID       => "3.3",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "IPV6UDP",
         Summary           => "Set IPv6 address on both SUT and helper and run IPv6 " .
                              "UDP traffic.",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['TRAFFIC_1']],

            "TRAFFIC_1" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               L3Protocol                => "ipv6",
               L4Protocol                => "udp",
               NoofInbound               => "2",
               NoofOutbound              => "2",
               SendMessageSize           => "1024,2048,4096,8192,16384",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "PktCap",
               TestDuration              => "30",
               MaxTimeout                => "5400",
            },
         },
      },

      'ChecksumIPV6' => {
         ParentTDSID       => "3.3",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "ChecksumIPV6",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies Checksum Offloading ".
                              "and also Checksum Disable functionality for IPV6.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['CSOEnable'],['TRAFFIC_1'],
                                  ['CSODisable'],['TRAFFIC_1'],
				  ['CSOEnable'],['EnableSG'],['EnableTSO']],

            "CSOEnable" => {
               Type              => "NetAdapter",
               Iterations        => "1",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               TCPTxChecksumIPv4 => "Enable",
               TCPRxChecksumIPv4 => "Enable",
            },

            "CSODisable" => {
               Type              => "NetAdapter",
               Iterations        => "1",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               TCPTxChecksumIPv4 => "Disable",
               TCPRxChecksumIPv4 => "Disable",
            },

            "EnableSG" => {
               Type              => "NetAdapter",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               SG                => "Enable",
            },

            "EnableTSO" => {
               Type              => "NetAdapter",
               Target            => "SUT,helper1",
               TestAdapter       => "1",
               TSOIPV4           => "Enable",
            },

            "TRAFFIC_1" => {
               Type                  => "Traffic",
               ToolName              => "netperf",
	       L3Protocol            => "ipv6",
               BurstType             => "stream",
               SendMessageSize       => "131072",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               TestDuration          => "60",
            },
         },
      },

      'VMotion' => {
         ParentTDSID       => "3.3",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Pots",
         TestName          => "VMotion",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test tests VMotion with the specific adapter type.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            VC             => 1,
            SUT            => {
               vnic        => ['vmxnet3:1'],
               vmnic       => ['any:1'],
               vmknic      => ['switch1:1'],
               switch      => ['vss:1'],
               datastoreType  => "shared",
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
               vmnic       => ['any:1'],
               vmknic      => ['switch1:1'],
               switch      => ['vss:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['EnableVMotionSUT'],['EnableVMotionHelper'],
                                  ['Connect'],['CreateDC'],['TRAFFIC_1'],
                                  ['VMotion'],['TRAFFIC_1']],
            ExitSequence      => [['RemoveDC']],

            "EnableVMotionSUT" => {
               Type             => "NetAdapter",
               Target           => "SUT",
               TestAdapter      => "1",
               IntType          => "vmknic",
               VMotion          => "ENABLE",
               ipv4             => "192.168.111.1",
            },

            "EnableVMotionHelper" => {
               Type             => "NetAdapter",
               Target           => "helper1",
               TestAdapter      => "1",
               IntType          => "vmknic",
               VMotion          => "ENABLE",
               ipv4             => "192.168.111.2",
            },

            "Connect" => {
               Type             => "VC",
               OPT              => "connect",
            },

            "CreateDC" => {
               Type             => "VC",
               OPT              => "adddc",
               DCName           => "/vmotiontest",
               Hosts            => "SUT,helper1",
            },

            "TRAFFIC_1" => {
               Type             => "Traffic",
               ToolName         => "netperf",
               TestAdapter      => "SUT:vnic:1",
               SupportAdapter   => "helper1:vnic:1",
               L4protocol       => "tcp,udp",
               TestDuration     => "60",
            },

            "VMotion" => {
               Type           => "VC",
               OPT            => "vMotion",
               VM             => "SUT",
               DstHost        => "helper1",
               Priority       => "high",
               Staytime       => "60",
               RoundTrip      => "yes",
            },

            "RemoveDC" => {
               Type             => "VC",
               OPT              => "removedc",
               DCName           => "/vmotiontest",
            },
         },
      },

      #
      # This test case is implemented to verify PR521009 and
      # 719915
      #
      'ChangevNICStateDuringBoot' => {
         ParentTDSID       => "5.23",
         Component         => "Vmxnet3",
         Category          => "Virtual Net Devices",
         Tags              => "Functional",
         TestName          => "ChangevNICStateDuringBoot",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Tests vNIC link state changes".
	                      "during VM power off/on.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "NA",
            Version        => "NA",
            GOS            => "NA",
            Driver         => "Vmxnet3,Vmxnet2,e1000",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Sequence          => [['PowerOff'],['DisconnectvNic'],
                                  ['PowerOn'],['TRAFFIC_1'],
                                  ['ConnectvNic'],['TRAFFIC_2']],
            ExitSequence      => [['ConnectvNic']],

            "PowerOff" => {
               Type           => "VM",
               Operation      => "poweroff",
            },
            "DisconnectvNic" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1",
               Operation      => "DISCONNECTVNIC",
            },
            "PowerOn" => {
               Type           => "VM",
               Operation      => "poweron",
               WaitForVDNet   => "1"
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "ping",
               TestDuration   => "20",
               NoofInbound    => "1",
               ExpectedResult    => "FAIL",
            },
            "ConnectvNic" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1",
               Operation      => "CONNECTVNIC",
            },
            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "ping",
               TestDuration   => "20",
               NoofInbound    => "1",
               ExpectedResult    => "PASS",
            },
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for Vmxnet3 Portable Tools
#
# Input:
#       none
#
# Results:
#       An instance/object of PotsVmxnet3Tds class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%VirtualNetDevices);
   if ($self eq FAILURE) {
      print "error ". VDGetLastError() ."\n";
      VDSetLastError(VDGetLastError());
   }
   return (bless($self, $class));
}

1;
