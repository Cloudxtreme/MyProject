#!/usr/bin/perl
########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::UptTds;

#
# This file contains the structured hash for category, Functional tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("MTUChange","ChangeRingParams","SuspendResume","RSSQueues",
            "EnableDisableRSS","EnableDisablevNIC","EnableDisableTSO",
            "EnableDisableChecksum","vNICConfigConcurrentSwitch",
            "WOL","DisconnectConnectvNIC","SnapshotRevertDelete","PowerOnOff",
            "StressOptions","ptAllowed","SimaltaneousSwitchOfvNics",
            "TSOgVLAN","TSOTCP","JumboFrame","JumboFramegVLAN",
            "ESXUptDisable","ESXUptEnable");

   %Upt = (
      'ESXUptDisable' => {
         ParentTDSID       => "2.1",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "ESXUptDisable",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "To verify that host level option to disable ".
                              "UPT in ESX wont crash the system",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00009",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 1,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['HostOperation_2']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               UPT            => "Disable",
            },

            "HostOperation_2" => {
               Type           => "Host",
               Target         => "helper1",
               UPT            => "Disable",
            },
         },
      },

      'ESXUptEnable' => {
         ParentTDSID       => "2.2",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "ESXUptEnable",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "To verify that host level option to enable ".
                              "UPT in ESX wont crash the system",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00009",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 1,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['HostOperation_2']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               UPT            => "Enable",
            },

            "HostOperation_2" => {
               Type           => "Host",
               Target         => "helper1",
               UPT            => "Enable",
            },
         },
      },

      'MTUChange' => {
         ParentTDSID       => "3.1",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "MTUChange",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that changing the MTU of a ".
                              "vNIC triggers a switch from passthru to ".
                              "emulation. Also that, running network traffic ".
                              "before and after the MTU change works fine.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00009",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            # Enable UPT on Host & vNICs, Verify traffic flows through.
            # Run MTU Change Operation for multiple iterations and
            # Traffic in parallel. Again verify Traffic in the end.
            Sequence          => [['HostOperation_1'],['TRAFFIC_1'],
                                  ['MTUChange','TRAFFIC_2'],
                                  ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               UPT            => "Enable",
               vNicUPT        => "Enable",
               TestAdapter    => "1,2,3,4,5",
            },

            "MTUChange" => {
               Type           => "NetAdapter",
               Iterations     => "100",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Verification   => "",
               MTU            => "1500,9000,1500",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
               Passthrough    => "UPT",
            },

            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "300",
            },
         },
      },

      'ChangeRingParams' => {
         ParentTDSID       => "3.2",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "ChangeRingParams",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that changing the ring ".
                              "parameters of a vNIC triggers a switch from ".
                              "passthru to emulation",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            # Enable UPT on Host & vNICs, Verify traffic flows through.
            # Change tx,rx ring size for multiple iterations on multiple
            # adapters and run Traffic in parallel.
            #Again verify Traffic in the end.
            Sequence          => [['HostOperation_1'],['TRAFFIC_1'],
                                  ['ChangeTxRing','TRAFFIC_2'],
                                  ['ChangeRxRing','TRAFFIC_2'],
                                  ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "ChangeTxRing" => {
               Type           => "NetAdapter",
               Iterations     => "100",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               TxRingSize     => "32,64,128,256,512,1024,2048,4096,512", #Default is 512 for Li/Wi
               Passthrough    => "UPT",
            },

            "ChangeRxRing" => {
               Type           => "NetAdapter",
               Iterations     => "100",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Rx1RingSize    => "32,64,128,256,512,1024,2048,4096,512",#Default is 512
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
               Passthrough    => "UPT",
            },

            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "300",
            },
         },
      },

      'EnableDisableRSS' => {
         ParentTDSID       => "3.5",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "EnableDisableRSS",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that enabling/disabling ".
                              "RSS feature of a vNIC on Windows VM triggers ".
                              "a switch from passthru to emulation",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            # Enable UPT on Host & vNICs, Verify traffic flows through.
            # Run RSS Change Operation for multiple iterations,on
            # multiple vNICs and run traffic in parallel.
            # Again verify Traffic in the end.
            Sequence          => [['HostOperation_1'],['TRAFFIC_1'],
                                  ['EnableDisableRSS','TRAFFIC_2'],
                                  ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "EnableDisableRSS" => {
               Type           => "NetAdapter",
               Iterations     => "100",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               RSS            => "Enable,Disable",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "600",
               Passthrough    => "UPT",
            },

            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "300",
            },
         },
      },

      'EnableDisablevNIC' => {
         ParentTDSID       => "5.24",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "EnableDisablevNIC",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that a vNIC switches ".
                              "from passthru to emulation mode & back when ".
                              "adapter is disabled/re-enabled from inside ".
                              "the VM.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['DisableEnablevNic'],
                                  ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "DisableEnablevNic" => {
               Type           => "NetAdapter",
               Iterations     => "100",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               DeviceStatus   => "DOWN,UP",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
               Passthrough    => "UPT",
            },
         },
      },

      'RSSQueues' => {
         ParentTDSID       => "3.6",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "RSSQueues",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that changing the number ".
                              "of RSS  tx queues in a VM connected to PTS ".
                              "vDS will change the vNIC from Passthru to ".
                              "emulation mode and back to Passthru mode.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['TRAFFIC_1'],
                                  ['TxQueues','TRAFFIC_2'],
                                  ['RxQueues','TRAFFIC_2'],
                                  ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "TxQueues" => {
               Type           => "NetAdapter",
               Iterations     => "100",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
                #Default is 1
               set_queues     => {
                  'direction  => "tx",
                  'value      => "1,2,4,8,1",
                },
               Passthrough    => "UPT",
            },

            "RxQueues" => {
               Type           => "NetAdapter",
               Iterations     => "100",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               #Default is 8
               set_queues     => {
                  'direction' => 'rx',
                  'value'     => '1,2,4,8',
                },
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
               Passthrough    => "UPT",
            },

            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "300",
            },
         },
      },

      'EnableDisableTSO' => {
         ParentTDSID       => "3.4",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "EnableDisableTSO",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies  that enabling/disabling ".
                              "TSO feature of a vNIC on Windows VM triggers ".
                              "a switch from passthru to emulation",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['TRAFFIC_1'],
                                  ['DisableEnableTSO','TRAFFIC_1'],
                                  ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "DisableEnableTSO" => {
               Type           => "NetAdapter",
               Iterations     => "100",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4",
               TSOIPV4        => "Disable,Enable",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
               Passthrough    => "UPT",
            },

            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "300",
            },
         },
      },

      'EnableDisableChecksum' => {
         ParentTDSID       => "3.3",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "EnableDisableChecksum",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "NA",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['TRAFFIC_2'],
                                  ['IPV4TxChecksum','TRAFFIC_1'],
				  ['IPV4RxChecksum','TRAFFIC_1'],
				  ['EnableSG'],['EnableTSO'],
                                  ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "IPV4TxChecksum" => {
               Type              => "NetAdapter",
               Iterations        => "100",
               Target            => "SUT",
               TestAdapter       => "1,2,3,4,5",
               TCPTxChecksumIPv4 => "Disable,Enable",
               Passthrough       => "UPT",
            },

            "IPV4RxChecksum" => {
               Type              => "NetAdapter",
               Iterations        => "100",
               Target            => "SUT",
               TestAdapter       => "1,2,3,4,5",
               TCPRxChecksumIPv4 => "Disable,Enable",
               Passthrough       => "UPT",
            },

            "EnableSG" => {
               Type              => "NetAdapter",
               Target            => "SUT",
               TestAdapter       => "1,2,3,4,5",
               SG                => "Enable",
            },

            "EnableTSO" => {
               Type              => "NetAdapter",
               Target            => "SUT",
               TestAdapter       => "1,2,3,4,5",
               TSOIPV4           => "Enable",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "300",
            },

            "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "60",
               Passthrough    => "UPT",
            },
         },
      },

      'WOL' => {
         ParentTDSID       => "5.15",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "WOL",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that a vNIC already in ".
                              "UPT mode switches to emulation when WOL is ".
                              "enabled for the Device and the Guest enters ".
                              "D3(Low power state).",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 1,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['WolMagic']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "WolMagic" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               WOL            => "MAGIC",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },
         },
      },

      'SuspendResume' => {
         ParentTDSID       => "5.5",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "SuspendResume",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that a vNIC switches from ".
	                      "passthru to emulation when VM is suspended",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['SuspendResume'],
	                          ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "SuspendResume" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Iterations     => "2",
               Operation      => "suspend,resume",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },
         },
      },

      'PowerOnOff' => {
         ParentTDSID       => "5.18",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "PowerOnOff",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that a vNIC switches from ".
	                      "passthru to emulation when VM is powered OFF ".
			      "and can again enter UPT after power ON",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['PowerOnOff'],
	                          ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "PowerOnOff" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Iterations     => "2",
               Operation      => "poweroff,poweron",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },
         },
      },

      'SnapshotRevertDelete' => {
         ParentTDSID       => "5.4",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "SnapshotRevertDelete",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies  that a vNIC switches ".
	                      "from passthru to emulation when snapshot is taken",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['SnapshotRevert'],
	                          ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "SnapshotRevert" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Iterations     => "2",
               Operation      => "createsnap,revertsnap,rmsnap",
               SnapshotName   => "testxyz",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "200",
               Passthrough    => "UPT",
            },
         },
      },

      'DisconnectConnectvNIC' => {
         ParentTDSID       => "5.23",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "DisconnectConnectvNIC",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that a vNIC switches ".
	                      "from passthru to emulation mode when the adapter ".
			      "is disconnected/reconnected multiple times from the ".
			      "vSphere Client",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['DisconnectConnectvNic'],
	                          ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "DisconnectConnectvNic" => {
               Type           => "NetAdapter",
               reconfig => 'true',,
               TestAdapter    => "1,2,3,4,5",
               Iterations     => "100",
               connected       => "0,1",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },
         },
      },

      'Reboot' => {
         ParentTDSID       => "5.25",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "Reboot",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "NA",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 1,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['VMOperation_1'],
	                          ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "VMOperation_1" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Iterations     => "2",
               Operation      => "REBOOT",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "200",
               Passthrough    => "UPT",
            },
         },
      },

      'Reset' => {
         ParentTDSID       => "5.19",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "Reset",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies that a vNIC(s) switches ".
	                      "from passthru to emulation when a VM is reset ".
			      "and after the VM boots, all vNIC(s) enter UPT mode",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['VMOperation_1'],
	                          ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "VMOperation_1" => {
               Type           => "VM",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Iterations     => "2",
               Operation      => "RESET",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "200",
               Passthrough    => "UPT",
            },
         },
      },

      'StressOptions' => {
         ParentTDSID       => "4.1",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "StressOptions",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies the robustness of the ".
	                      "switching logic between passthru and emulation ".
			      "when various passthru stress options are enabled",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Iterations        => "n",
            Sequence          => [['HostOperation_1'],['StressOptions'],
	                          ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "StressOptions" => {
               Type           => "Host",
               Target         => "SUT",
               Stress         => "Enable",
               stressoptions  => "%VDNetLib::StressTestData::uptStress",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },
         },
      },

      'ptAllowed' => {
         ParentTDSID       => "5.27",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "ptAllowed",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies the switch in/out of UPT ".
	                      "mode for a VM’s vNIC connected to a PTS vDS ".
			      "port when ptAllowed is set/unset on the VM’s ".
			      "vNIC PTS vDS port and vNIC is reset.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],
	                          ['ptAllowed','RSS'],
                                  ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "ptAllowed" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Iterations     => "1000",
               vNicUPT        => "Disable,Enable",
            },

            "RSS" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Iterations     => "100",
               RSS            => "Enable,Disable",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },
         },
      },

      'vNICConfigConcurrentSwitch' => {
         ParentTDSID       => "4.4",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "vNICConfigConcurrentSwitch",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "Verifies switch logic correctly saves the vNIC ".
	                      "configuration and restores those when different ".
			      "features are enabled. The different features ".
			      "could be different intr mode, different number ".
			      "of multicast filters, vlan filters, rss, ring size",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],
                                 ['ptAllowed','RSS','TxRing','MTU'],
                                 ['UPTVerify'],['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "ptAllowed" => {
               Type           => "Host",
               Iterations     => "500",
               TestAdapter    => "1,2,3,4,5",
               Target         => "SUT",
               vNicUPT        => "Disable,Enable",
            },

            "RSS" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               Iterations     => "100",
               TestAdapter    => "1,5",
               RSS            => "Enable,Disable",
            },

            "TxRing" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               Iterations     => "100",
               TestAdapter    => "2",
               TxRingSize     => "4096,128,512",
            },

            "MTU" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               Iterations     => "100",
               TestAdapter    => "3,4",
               MTU            => "9000,1500",
            },

            "UPTVerify" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4,5",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },
         },
      },

      'SimaltaneousSwitchOfvNics' => {
         ParentTDSID       => "4.2",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "SimaltaneousSwitchOfvNics",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies the robustness of the ".
	                      "switching logic between passthru to emulation ".
			      "when various vNICs in UPT are switched to ".
			      "emulation and the ones in passthru are switched ".
			      "to passthru simultaneously.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00007",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 5,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['ptAllowed','PowerOnOff']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               Iterations     => "1000",
               TestAdapter    => "1,2,3,4,5",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "ptAllowed" => {
               Type           => "Host",
               Iterations     => "1000",
               Target         => "SUT",
               TestAdapter    => "1,2,3,4",
               vNicUPT        => "Disable,Enable",
            },

            "PowerOnOff" => {
               Type           => "Host",
               Iterations     => "5",
               Target         => "SUT",
               TestAdapter    => "5",
               Operation      => "poweroff,poweron",
            },

         },
      },

      'TSOgVLAN' => {
         ParentTDSID       => "7.5",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "TSOgVLAN",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies TSO traffic over a gVLAN ".
	                      "vNIC connected to PTS vDS. The PTS vDS ".
			      "portprofile/portgroup should be configured ".
			      "in UCS Manager to include the VLAN id you ".
			      "will configure in the Guest OS which will be ".
			      "doing the tagging.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 1,
            },
            helper1 => {
               VMX =>  "",
               AdaptersCount => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['gVLANTSO'],
	                          ['TRAFFIC_1'],['NetAdapter_2']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT,helper1",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "gVLANTSO" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TSOIPv4        => "Enable",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },
            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               VLAN           => "0", # setting to default
            }
         },
      },

      'TSOTCP' => {
         ParentTDSID       => "7.1",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "TSOTCP",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies TSO traffic between two ".
	                      "VMs with vNIC(s) in passthru mode",
         Environment       => {
            Platform       => "ESX/ESXi",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 1,
            },
            helper1 => {
               VMX =>  "",
               AdaptersCount => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['TSO'],
	                          ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT,helper1",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "TSO" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               TSOIPv4        => "Enable",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               NoofInbound    => "1",
               RequestSize    => "4000-12000,1000",
               ResponseSize   => "4000,5000,6000",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },
         },
      },

      'JumboFrame' => {
         ParentTDSID       => "7.2",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "JumboFrame",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies Jumbo Frame network traffic ".
	                      "between two VMs with vNIC(s) in passthru mode ".
			      "You will need a PTS vDS portprofile with ".
			      "the MTU set to 9000 through UCS Manager. ",
         Environment       => {
            Platform       => "ESX/ESXi",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 1,
            },
            helper1 => {
               VMX =>  "",
               AdaptersCount => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['NetAdapter_1'],
	                          ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT,helper1",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "9000",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               BurstType      => "stream,rr",
               L4Protocol     => "udp",
               NoofInbound    => "3",
               NoofOutbound   => "2",
               Verification   => "PktCap",
               TestDuration   => "200",
               Passthrough    => "UPT",
            },
         },
      },

      'JumboFramegVLAN' => {
         ParentTDSID       => "7.1",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "JumboFramegVLAN",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "This test verifies Jumbo Frame network traffic ".
	                      "over a gVLAN vNIC connected to PTS vDS. ".
			      "The PTS vDS portprofile/portgroup should be ".
			      "configured in UCS Manager to include the VLAN ".
			      "id you will configure in the Guest OS ".
			      "which will be doing the tagging.",
         Environment       => {
            Platform       => "ESX/ESXi",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 1,
            },
            helper1 => {
               VMX =>  "",
               AdaptersCount => 1,
            },
         },

         WORKLOADS => {
            Sequence          => [['HostOperation_1'],['NetAdapter_1'],
	                          ['TRAFFIC_1'],['NetAdapter_2']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT,helper1",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               MTU            => "9000",
               VLAN           => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "100",
               Passthrough    => "UPT",
            },

            "NetAdapter_2" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               VLAN           => "0", # setting to default
            }
         },
      },

      'ChangeMACAddress' => {
         ParentTDSID       => "6.2",
         Component         => "network NPA/UPT",
         TestSet           => "Upt",
         TestName          => "ChangeMACAddress",
         AutomationStatus  => "automated",
         Priority          => "P0",
         Summary           => "NA",
         Environment       => {
            Platform       => "ESX/ESXi",
            Build          => "00009",
            Version        => "4.1.0",
            GOS            => "NA",
            Driver         => "vmxnet3",
            DriverVersion  => "NA",
            ToolsVersion   => "NA",
            Setup          => "INTER/INTRA",
            NOOFMACHINES   => "2"
         },
         ExpectedResult    => "PASS/FAIL",
         PreConfig => {
            SUT => {
               VMX =>  "",
               AdaptersCount => 1,
               },
               helper1 => {
                  VMX =>  "",
                  AdaptersCount => 1,
               },
            },

         WORKLOADS => {
            Iterations        => "n",
            Sequence          => [['HostOperation_1'],['NetAdapter_1'],
                                 ['TRAFFIC_1']],

            "HostOperation_1" => {
               Type           => "Host",
               Target         => "SUT",
               UPT            => "Enable",
               vNicUPT        => "Enable",
            },

            "NetAdapter_1" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               Iterations     => "1",
               TestAdapter    => "1",
               Verification   => "",
               MACAddress     => "00:00:00:00:00:01",
               Passthrough    => "UPT",
            },

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               TestDuration   => "200",
               Passthrough    => "UPT",
           },
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for UptTds
#
# Input:
#       none
#
# Results:
#       An instance/object of UptTds class
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
   my $self = $class->SUPER::new(\%Upt);
   return (bless($self, $class));
}

1;
