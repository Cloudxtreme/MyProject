#!/usr/bin/perl
#########################################################################
#Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::FPT::SRIOVTds;

#
# This file contains the structured hash for category, SRIOV tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   %SRIOV = (
      'VFToVF'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "VFToVF",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies that VF to VF ".
                             "communication is functional as expected. " .
                             "Verification is done using TCP/UDP traffic " .
                             "with IPv4 and IPv6. ",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 2,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                  },
               },
            },
            helper1 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 2,
                  },
               },
            },
            helper2 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:2",
                     virtualfunction => 1,
                  },
               },
            },
            Rules    => "SUT.host == helper1.host," .
                        "helper2.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [
                        ['ConfigureIP'],
                        ['BroadcastTraffic'],
                        ['MulticastTraffic'],
                        ['PingFlood'],
                        ['TCPTraffic'],
                        ['UDPTraffic']
                        ],

            "ConfigureIP"  => {
               Type           => "NetAdapter",
               TestAdapter    => "SUT:pci:1,helper1:pci:1,helper2:pci:1",
               IPv4           => "AUTO",
            },
            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               MaxTimeout                => "5000",
               TestAdapter               => "SUT:pci:1,helper2:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "tcp",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "1024,2048,4096,8192," .
                                            "16384,32768,64512",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification               => "Verification_1",
               TestDuration              => "60",
            },
            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               MaxTimeout                => "5000",
               TestAdapter               => "SUT:pci:1,helper2:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "UDP",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "1024,2048,4096,8192," .
                                            "16384,32768,64512",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "Verification_1",
               TestDuration              => "20",
            },
            "PingFlood" => {
               Type                      => "Traffic",
               ToolName                  => "ping",
               TestAdapter               => "SUT:pci:1,helper2:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4",
               NoofInbound               => "1",
               RoutingScheme             => "flood",
               TestDuration              => "60",
               connectivitytest          => "0",
            },
            "MulticastTraffic" => {
               Type                => "Traffic",
               ToolName            => "Iperf",
               TestAdapter         => "SUT:pci:1,helper2:pci:1",
               SupportAdapter      => "helper1:pci:1",
               TestDuration        => "60",
               NoofOutbound         => "1",
               NoofInbound         => "1",
               Routingscheme       => "multicast",
            },
            "BroadcastTraffic" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "broadcast",
               TestAdapter    => "SUT:pci:1,helper2:pci:1",
               SupportAdapter => "helper1:pci:1",
               NoofOutbound   => "1",
               TestDuration   => "60",
            },

            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
         },
      },

      'VMKToVF'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "VMKToVF",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies communication " .
                             "between vmkernel to VF using TCP and " .
                             "UDP traffic. 2 vmnics are used, one card " .
                             "is enabled with SRIOV and the other card " .
                             "is used as regular uplink.",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 1,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                  },
               },
            },
            helper1 => {
               switch  => ['vss:1'],
               vmknic  => ['switch1:1'], # TestAdapter 1 on SUT of type vmknic
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 1,
                           speed  => "10G",
                        },
                        ],
            },
            Rules    => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [['TCPTraffic'],
                         ['UDPTraffic']],

            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               MaxTimeout                => "5000",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:vmknic:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "tcp",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "1024,2048,4096,8192," .
                                            "16384,32768,64512",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "Verification_1",
               TestDuration              => "60",
            },
            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               MaxTimeout                => "5000",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:vmknic:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "UDP",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "1024,2048,4096,8192," .
                                            "16384,32768,64512",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "Verification_1",
               TestDuration              => "20",
               Minexpresult              => "IGNORE"
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
         },
      },

      'EnableDisableSRIOV'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "EnableDisableSRIOV",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case enables and disables SRIOV " .
                             "in a loop. ESX is not expected to PSOD" ,
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 2,
                           speed  => "10G",
                        },
                        ],
            },
         },
         WORKLOADS => {
            Sequence => [
                         ['Enable1VF'],
                         ['DisableSRIOV'],
                         ['EnableInvalidVFs'],
                         ['Enable2VFs'],
                         ['DisableSRIOV'],
                         ['Enable100VFs'],
                         ['DisableSRIOV'],
                        ],
            ExitSequence => [['DisableSRIOV']],
            'Iterations' => "20",
            'Enable1VF' => {
               Type => "Host",
               sriov => "enable",
               uplinkname => "SUT:vmnic:1-SUT:vmnic:2", # Iterator kicks-in if
                                                        # comma separated value
                                                        # is given.
               maxvfs   => "1",

            },
            'EnableInvalidVFs' => {
               Type => "Host",
               sriov => "enable",
               uplinkname => "SUT:vmnic:1-SUT:vmnic:2",
               maxvfs   => "-1",
            },

            'Enable2VFs' => {
               Type => "Host",
               sriov => "enable",
               uplinkname => "SUT:vmnic:1-SUT:vmnic:2",
               maxvfs   => "2",

            },
            'Enable100VFs' => {
               Type => "Host",
               sriov => "enable",
               uplinkname => "SUT:vmnic:1-SUT:vmnic:2",
               maxvfs   => "100",

            },
            'DisableSRIOV' => {
               Type => "Host",
               sriov => "disable",
               uplinkname => "SUT:vmnic:1-SUT:vmnic:2",
            },
         },
      },

      'AddVFToVM'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "AddVFToVM",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies that same VF cannot " .
                             "assigned to two PCI devices in VM. Adding PCI " .
                             "device should pass, but powering on VM should " .
                             "fail",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 2,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                  },
               },
            },
            helper1  => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 2,
                  },
               },
            },
            helper2  => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper2:pci:1 pci device
                     passthrudevice => "SUT:vmnic:2",
                     virtualfunction => 1,
                  },
               },
            },
            Rules => "SUT.host == helper1.host," .
                     "helper1.host == helper2.host",
         },
         WORKLOADS => {
            Sequence => [
                        ['PoweroffHelperVM'],
                        ['PingFloodToSUT'],
                        ['AddVFToHelperNeg'],
                        ['PoweronHelperNeg'],
                        ['PoweroffSUTVM'],
                        ['PoweronHelper'],
                        ],

            'PoweroffHelperVM' => {
               Type           => "VM",
               Target         => "helper1",
               Operation      => "poweroff",
            },
            "PingFloodToSUT" => {
               Type                      => "Traffic",
               ToolName                  => "ping",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper2:pci:1",
               L3Protocol                => "ipv4",
               NoofInbound               => "1",
               RoutingScheme             => "flood",
               TestDuration              => "60",
            },
            #
            # This workload "AddVFToHelperNeg" adds a VF same as
            # SUT:pci:1
            # Eventually, powering on a VM with this configuration
            # will fail.
            #
            'AddVFToHelperNeg' => {
               Type       => "VM",
               Target     => "helper1",
               Operation  => "addpcipassthruvm",
               passthroughadapter => "SUT:vmnic:1",
               pciIndex => "1",
               VFIndex => "1", # This is same as VF initialized
                               # for SUT:pci:1
            },
            'PoweronHelperNeg' => {
               Type       => "VM",
               Target     => "helper1",
               Operation  => "poweron",
               ExpectedResult => "FAIL",
               waitforvdnet => 0,
            },
            'PoweroffSUTVM' => {
               Type           => "VM",
               Target         => "SUT",
               Operation      => "poweroff",
            },
            'PoweronHelper' => {
               Type       => "VM",
               Target     => "helper1",
               Operation  => "poweron",
               waitforvdnet => 1,
            },
            "PingFloodToHelper" => {
               Type                      => "Traffic",
               ToolName                  => "ping",
               TestAdapter               => "helper1:pci:1",
               SupportAdapter            => "helper2:pci:1",
               L3Protocol                => "ipv4",
               NoofInbound               => "1",
               RoutingScheme             => "flood",
               TestDuration              => "60",
            },
         },
      },

      'ResetVF' => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "ResetVFVM",
         Tags             => "ixgbe,be2net",
         Summary          => "This test resets VF and VM with VF added a PCI " .
                             "device in a loop. ESX should not PSOD and " .
                             "the VF should be functional after multiple " .
                             "resets" ,
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 1,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                  },
               },
            },
            helper1 => {
               switch  => ['vss:1'],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 2,
                  },
               },
            },
            Rules => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [
                        ['TCPTraffic'],
                        ['ResetVF'],
                        ['TCPTraffic'],
                        ['ResetSUTVM'],
                        ['WaitForVDNet'],
                        ['TCPTraffic'],
                        ['KillVM'],
                        ['PowerOn'],
                        ['TCPTraffic'],
                        ['UDPTraffic'],
                        ],

            'ResetVF'   => {
               Type        => "NetAdapter",
               TestAdapter => "SUT:pci:1",
               Iterations  => "10",
               DeviceStatus=> "DOWN,UP",
            },
            'ResetSUTVM' => {
               Type         => "VM",
               Target       => "SUT",
               Iterations   => "5",
               Operation    => "reset",
               waitforvdnet => 0,
            },
            'WaitForVDNet' => {
               Type       => "VM",
               Target     => "SUT",
               Operation  => "waitforvdnet",
            },
	         'KillVM'       => {
               Type        => "VM",
               Target      => "SUT",
               Iterations  => "1",
               Operation   => "killvm",
            },
	         "PowerOn"      => {
               Type        => "VM",
               Target      => "SUT",
               Operation   => "poweron",
               WaitForVDNet=> "1",
            },
            'TCPTraffic' => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "tcp",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               TestDuration              => "20",
            },
            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "UDP",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               TestDuration              => "20",
            },
         },
      },
      'DisconnectVF' => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "DisconnectVF",
         Tags             => "ixgbe,be2net",
         Summary          => "This test verifies that link status of VF. " .
                             "Link status of VF is changed by disabling port " .
                             "of vmnic on phy switch",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 1,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                  },
               },
            },
            helper1 => {
               switch  => ['vss:1'],
               vmknic  => ['switch1:1'], # TestAdapter 1 on SUT of type
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 1,
                           speed  => "10G",
                        },
                        ],
            },
            Rules    => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [['DisablePort'],
                         ['PingNeg'],
                         ['EnablePort'],
                         ['TCPTrafficPos']],
            ExitSequence => [['EnablePort']],
            'PingNeg' => {
               Type                      => "Traffic",
               ToolName                  => "ping",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:vmknic:1",
               NoofInbound               => "1",
               TestDuration              => "30",
               Verification              => "VerificationNeg",
               ExpectedResult            => "FAIL",
            },
            "VerificationNeg" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "dstvm",
                  pktcapfilter       => "count 15",
                  pktcount           => "0",
               },
            },
            'TCPTrafficPos' => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:vmknic:1",
               L3Protocol                => "ipv4",
               L4Protocol                => "tcp",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "131072",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               TestDuration              => "60",
            },
            'DisablePort' => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               SwitchType => "pswitch",
               VmnicAdapter => "1",
               PortStatus => "disable",
            },
            'EnablePort' => {
               Type => "Switch",
               Target => "SUT",
               TestSwitch => "1",
               SwitchType => "pswitch",
               VmnicAdapter => "1",
               PortStatus => "enable",
            },
         },
      },

      'DefaultVLAN'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "DefaultVLAN",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies default VLAN " .
                             "functionality of VF. ".
                             "VFs with same default VLAN should be able to " .
                             "communicate, but not the ones with different " .
                             "VLAN ",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 2,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                     vlan  => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B,
                  },
               },
            },
            helper1 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:2",
                     virtualfunction => 1,
                     vlan  => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B,
                  },
               },
            },
            helper2 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper2:pci:1
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 2,
                     vlan  => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_A,
                  },
               },
            },
            Rules    => "SUT.host == helper1.host," .
                        "helper2.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [
                        ['TCPTraffic'],
                        ['UDPTraffic'],
                        ['PingNeg'], # different vlan should not work
                        ],

            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "tcp",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               Verification               => "Verification_1",
               TestDuration              => "60",
            },
            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "UDP",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               Verification              => "Verification_1",
               TestDuration              => "60",
            },
            'PingNeg' => {
               Type                      => "Traffic",
               ToolName                  => "ping",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper2:pci:1",
               NoofInbound               => "1",
               TestDuration              => "30",
               connectivitytest          => "0",
               Verification              => "VerificationNeg",
               ExpectedResult            => "FAIL",
            },

            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
            "VerificationNeg" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "dstvm",
                  pktcapfilter       => "count 15",
                  pktcount           => "0",
               },
            },
         },
      },
      'GuestVLAN'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "GuestVLAN",
         Tags             => "ixgbe,be2net,linuxOnly",
         Summary          => "This test case verifies guest vlan (linux) ".
                             "functionality on a VF." .
                             "The expected behavior is that:" .
                             "With defaultVlan 0-4094, gVLAN should fail," .
                             "With defaultVlan above 4094, gVLAN should pass,",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 2,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                     vlan  => "4095",
                  },
               },
            },
            helper1 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 2,
                     vlan  => "4095",
                  },
               },
            },
            Rules    => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [
                        ['GVLANPos'],
                        ['Traffic'],
                        ['PoweroffVMs'],
                        ['ChangeSUTDefaultVLAN'],
                        ['ChangeHelperDefaultVLAN'],
                        ['PoweronVMs'],
                        ['SUTgVLANNeg'],
                        ['RemovegVLAN'],
                        ['PingNeg'],
                        ['Traffic'],
                        ],
            ExitSequence   => [['RemovegVLAN']],

            "Traffic" => {
               Type              => "Traffic",
               ToolName          => "netperf",
               TestAdapter       => "SUT:pci:1",
               SupportAdapter    => "helper1:pci:1",
               L3Protocol        => "ipv4,ipv6",
               L4Protocol        => "tcp,udp",
               NoofInbound       => "1",
               NoofOutbound      => "1",
               Verification      => "Verification_1",
               TestDuration      => "20",
            },
            'PingNeg' => {
               Type              => "Traffic",
               ToolName          => "ping",
               TestAdapter       => "SUT:pci:1",
               SupportAdapter    => "helper1:pci:1",
               TestDuration      => "30",
               connectivitytest  => "0",
               Verification      => "VerificationNeg",
               ExpectedResult    => "FAIL",
            },
            "GVLANPos" => {
               Type        => "NetAdapter",
               Target      => "SUT,helper1",
               inttype     => "pci",
               TestAdapter => "1",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B,
            },
            "SUTgVLANNeg" => {
               Type        => "NetAdapter",
               Target      => "SUT",
               inttype     => "pci",
               TestAdapter => "1",
               vlan        => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B,
               #ExpectedResult=> "FAIL", # ixgbe VF driver does not throw
                                         # error at vconfig. But sending
                                         # traffic via vlan node would still
                                         # fail. Uncomment this, if the
                                         # behavior changes in future version
                                         # of ixgbe driver
                                         #
            },
            'PoweroffVMs' => {
               Type           => "VM",
               Target         => "SUT,helper1",
               Operation      => "poweroff",
            },
            'PoweronVMs' => {
               Type           => "VM",
               Target         => "SUT,helper1",
               Operation      => "poweron",
               waitforvdnet   => 1,
            },
            'ChangeSUTDefaultVLAN' => {
               Type       => "VM",
               Target     => "SUT",
               Operation  => "addpcipassthruvm",
               passthroughadapter => "SUT:vmnic:1",
               VFIndex => "1",
               pciIndex => "1",
               vlan     => "0",
            },
            'ChangeHelperDefaultVLAN' => {
               Type       => "VM",
               Target     => "helper1",
               Operation  => "addpcipassthruvm",
               passthroughadapter => "SUT:vmnic:1",
               VFIndex  => "2",
               pciIndex => "1",
               vlan     => "0",
            },
            "RemovegVLAN" => {
               Type           => "NetAdapter",
               Target         => "SUT,helper1",
               inttype        => "pci",
               TestAdapter    => "1",
               vlan  => "0",
            },

            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
            "VerificationNeg" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "dstvm",
                  pktcapfilter       => "count 15",
                  pktcount           => "0",
               },
            },
         },
      },

      'PCILimit'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "PCILimit",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies the maximum # of VFs ".
                             "that can be registered on a host",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 1,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {             # initializes 1 on SUT & 6 PCI devices
                                         # per helper. max per
                                         # host for ixgbe is 41 but not
                                         # guaranteed depending on free
                                         # interrupt vectors available
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => "any",
                  },
               },
            },
            "helper[1-6]" => {   # initializes 6 helpers
               vm => 1,
               pci => {
                  "[1-6]" => {           # initializes 1-6 pci devices
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => "any",
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                        ['TCPTraffic'],
                        ],

            "TCPTraffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               MaxTimeout     => "5000",
               TestAdapter    => "SUT:pci:1",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               TestDuration   => "20",
            },
         },
      },
      'VMOPs'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "VMOPs",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies operations ".
                             "on a VM that has pci passthru device ",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 1,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                  },
               },
            },
            helper1 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 2,
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence          => [
                                  ['Suspend'],
                                  ['Snapshot'],
                                  ["Hibernate"],
                                  ["Resume"]],
            "Suspend"         => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "suspend",
               ExpectedResult => "FAIL",
            },
            "Snapshot"        => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "createsnap",
               SnapshotName   => "sriovNeg",
               ExpectedResult => "FAIL",
            },
	         "Hibernate"       => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "hibernate",
            },
	         "Resume"          => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "resume",
            },
         },
      },
      'StaticMAC'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "MoveVF",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies static mac ".
                             "configurations on a VF. The expected behavior of " .
                             "brining duplicate mac address is also verified ",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 2,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                     macaddress => "00:50:56:33:44:51",
                  },
               },
            },
            helper1 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 2,
                     macaddress => "00:50:56:33:44:52",
                  },
               },
            },
            helper2 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper2:pci:1
                     passthrudevice => "SUT:vmnic:2",
                     virtualfunction => 1,
                     macaddress => "00:50:56:33:44:53",
                  },
               },
            },
            helper3 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper3:pci:1
                     passthrudevice => "SUT:vmnic:2",
                     virtualfunction => 2,
                     macaddress => "00:50:56:33:44:51", # same as SUT VF's mac
                  },
               },
            },
            Rules    => "SUT.host == helper1.host," .
                        "helper2.host == helper1.host," .
                        "helper3.host == helper2.host",
         },
         WORKLOADS => {
            Sequence => [
                        ["PingSUTNeg"],      # since there is duplicate mac on same
                                             # host, ping should fail
                        ['PowerOffHelper3'], # disable a VF with duplicate mac,
                                             # this step also verifies mac
                                             # cleanup functionality
                        ['TrafficSUTPos'],   # Now, connectivity should be good
                        ['PowerOffHelper1'],
                        ['MoveSUTVFToHelper1'], # create duplicate mac address
                                                # on same port
                        ['PoweronHelper1Neg'],  # powering on helper1 should fail
                        ['PowerOffSUT'],        # power off the first/SUT VM
                        ['PoweronHelper1Pos'],  # Now helper1 VM should power
                                                # on
                        ['TrafficHelper1Pos']   # check basic VF functionality
                        ],
            "PingSUTNeg" => {
               Type                  => "Traffic",
               ToolName              => "ping",
               TestAdapter           => "SUT:pci:1",
               SupportAdapter        => "helper2:pci:1",
               connectivitytest      => "0",
               L3Protocol            => "ipv4",
               NoofInbound           => "1",
               TestDuration          => "20",
               Verification          => "VerificationNeg",
               ExpectedResult        => "FAIL",
            },
            "VerificationNeg" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "dstvm",
                  pktcapfilter       => "count 15",
                  pktcount           => "0",
               },
            },
	         'PowerOffHelper3' => {
               Type               => "VM",
               Target             => "helper3",
               Iterations         => "1",
               Operation          => "poweroff",
            },
            "TrafficSUTPos" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper2:pci:1",
               L3Protocol                => "ipv4",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               TestDuration              => "60",
               Verification              => "VerificationPos",
            },
	         'PowerOffHelper1' => {
               Type               => "VM",
               Target             => "helper1",
               Iterations         => "1",
               Operation          => "poweroff",
            },
            'MoveSUTVFToHelper1' => {
               Type       => "VM",
               Target     => "helper1",
               Operation  => "addpcipassthruvm",
               passthroughadapter => "SUT:vmnic:1",
               VFIndex => "2", # no change in VF pci ID
               pciIndex => "1",
               macaddress => "00:50:56:33:44:51", # same as SUT VF's mac
            },
	         'PoweronHelper1Neg' => {
               Type               => "VM",
               Target             => "helper1",
               Iterations         => "1",
               Operation          => "poweron",
               ExpectedResult     => "FAIL",
            },
	         'PowerOffSUT' => {
               Type               => "VM",
               Target             => "SUT",
               Iterations         => "1",
               Operation          => "poweroff",
            },
	         'PoweronHelper1Pos' => {
               Type               => "VM",
               Target             => "helper1",
               Iterations         => "1",
               Operation          => "poweron",
               waitforvdnet => 1,
            },
	         'PoweronSUT' => {
               Type               => "VM",
               Target             => "SUT",
               Iterations         => "1",
               Operation          => "poweron",
               waitforvdnet => 0,
            },
            'TrafficHelper1Pos' => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "helper1:pci:1",
               SupportAdapter            => "helper2:pci:1",
               L3Protocol                => "ipv4",
               NoofInbound               => "1",
               NoofOutbound               => "1",
               TestDuration              => "60",
               Verification              => "VerificationPos",
            },
            "VerificationPos" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "dstvm",
                  pktcapfilter       => "count 1500",
                  pktcount           => "1400+",
                  badpkt             => "0",
               },
            },
         },
      },
      'VFConfigPersistence'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "VFConfigPersistence",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies that VF's configuration " .
                             "(vlan and mac) is persistence across VM reboots",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 2,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                     vlan  => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B,
                     macaddress => "00:50:56:33:44:51",
                  },
               },
            },
            helper1 => {
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:2", # second port
                     virtualfunction => 2,
                     vlan  => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B,
                     macaddress => "00:50:56:33:44:52",
                  },
               },
            },
            Rules    => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [
                        ['Traffic'],
                        ['ResetSUTVM'],
                        ['Traffic'],
                        ['RebootSUTGuest'],
                        ['Traffic'],
                        ],

            "Traffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4",
               L4Protocol                => "tcp,udp",
               Verification              => "Verification_1",
               TestDuration              => "60",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
            'ResetSUTVM' => {
               Type       => "VM",
               Target     => "SUT",
               Operation  => "reset",
               waitforvdnet => 1,
            },
            'RebootSUTGuest' => {
               Type       => "VM",
               Target     => "SUT",
               Operation  => "reboot",
               waitforvdnet => 1,
            },
         },
      },
      'StressOptions'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "StressOptions",
         Tags             => "ixgbe,be2net",
         Summary          => "This test case verifies stress options " .
                             "implemented for SR-IOV",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               host  => 1,
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 2,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                  },
               },
            },
            helper1 => {
               host  => 1,
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:2", # second port
                     virtualfunction => 2,
                  },
               },
            },
            Rules    => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [
                        ['Traffic'],
                        ['PowerOffSUT'],
                        ['EnableInterruptStress'],
                        ['PoweronSUTNeg'],
                        ['DisableInterruptStress'],
                        ['PoweronSUTPos'],
                        ['PowerOffSUT'],
                        ['EnableDupMACStress'],
                        ['PoweronSUTNeg'],
                        ['DisableDupMACStress'],
                        ['PoweronSUTPos'],
                        ['Traffic'],
                        ],
            ExitSequence => [['DisableInterruptStress'],
                            ['DisableDupMACStress']
                            ],

            "Traffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4",
               L4Protocol                => "tcp,udp",
               Verification              => "Verification_1",
               TestDuration              => "60",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
            'PowerOffSUT' => {
               Type               => "VM",
               Target             => "SUT",
               Iterations         => "1",
               Operation          => "poweroff",
            },
            'PoweronSUTNeg' => {
               Type           => "VM",
               Target         => "SUT",
               Operation      => "poweron",
               ExpectedResult => "FAIL",
               waitforvdnet   => 1,
            },
            'PoweronSUTPos' => {
               Type           => "VM",
               Target         => "SUT",
               Operation      => "poweron",
               waitforvdnet   => 1,
            },
            'EnableInterruptStress' => {
               Type           => "Host",
               Target         => "SUT",
               Stress         => "Enable",
               StressOptions  => "NetPTSetupIntrProxyFailure=1",
            },
            'DisableInterruptStress' => {
               Type           => "Host",
               Target         => "SUT",
               Stress         => "Disable",
               StressOptions  => "NetPTSetupIntrProxyFailure=0",
            },
            'EnableDupMACStress' => {
               Type           => "Host",
               Target         => "SUT",
               Stress         => "Enable",
               StressOptions  => "NetPTConfigMacAndVlan=1",
            },
            'DisableDupMACStress' => {
               Type           => "Host",
               Target         => "SUT",
               Stress         => "Enable",
               StressOptions  => "NetPTConfigMacAndVlan=0",
            },
         },
      },
      'TSO'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "TSO",
         Tags             => "ixgbe,be2net,linuxOnly",
         Summary          => "This test case verifies VF driver " .
                             "functionality with TSO disabled. " .
                             "By default TSO is enabled",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               host  => 1,
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 2,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                  },
               },
            },
            helper1 => {
               host  => 1,
               vm => 1,
               pci => {
                  "[1]" => {           # initializes helper1:pci:1
                     passthrudevice => "SUT:vmnic:2", # second port
                     virtualfunction => 2,
                  },
               },
            },
            Rules    => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [
                        ['Traffic'],
                        ['DisableTSO'],
                        ['Traffic'],
                        ],
            ExitSequence => [['EnableTSO']],

            "DisableTSO" => {
               Type         => "NetAdapter",
               TestAdapter  => "SUT:pci:1",
               TSOIPV4      => "Disable",
            },

            "EnableTSO" => {
               Type         => "NetAdapter",
               TestAdapter  => "SUT:pci:1",
               TSOIPV4      => "Enable",
            },
            "Traffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "tcp",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "1,2048,32768,64512",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               TestDuration              => "60",
            },
         },
      },
      'FPTSRIOVInterop'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "FPTSRIOVInterop",
         Tags             => "ixgbe,be2net,hostreboot",
         Summary          => "This test case verifies the co-existence ".
                             "of FPT and SRIOV enabled nics. " .
                             "Also, verifies FPT & SRIOV configuration " .
                             "persistence after host reboot ",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT   => {
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 1,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               vm => 1,
               pci => {
                  "[1-6]" => {           # initializes 6 pci devices (sriov)
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => "any",
                  },
               },
            },
            helper1   => {
               host        => 1,
               vm          => 1,
               passthrough => 1,
               vmnic       => [
                              {
                                 driver => "ixgbe",
                                 count  => 1,
                                 speed  => "10G",
                              },
                              ],
               pci => {
                  "[1]" => {           # initializes helper1:pci:1 (fpt)
                     passthrudevice => "helper1:vmnic:1",
                  },
               },
            },
            Rules    => "SUT.host == helper1.host",
         },
         WORKLOADS => {
            Sequence => [
                         ['PingFlood'],
                         ['RebootSUTHost'],
                         ['PoweronVMs'],
                         ['TCPTraffic'],
                         ['UDPTraffic'],
                        ],
            "RebootSUTHost" => {
               Type           => "Host",
               Target         => "SUT",
               Iterations     => 2,
               Reboot         => "yes",
            },
            "PoweronVMs" => {
               Type           => "VM",
               Target         => "SUT,helper1",
               Operation      => "poweron",
               waitforvdnet   => 1,
            },
            "PingFlood" => {
               Type                      => "Traffic",
               ToolName                  => "ping",
               TestAdapter               => "SUT:pci:1,SUT:pci:2,SUT:pci:3," .
                                            "SUT:pci:4,SUT:pci:5,SUT:pci:6,",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4",
               NoofInbound               => "1",
               RoutingScheme             => "flood",
               TestDuration              => "60",
               connectivitytest          => "0",
            },
            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               MaxTimeout                => "5000",
               TestAdapter               => "SUT:pci:1,SUT:pci:2,SUT:pci:3," .
                                            "SUT:pci:4,SUT:pci:5,SUT:pci:6,",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "tcp",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "1024,64512",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               TestDuration              => "20",
            },
            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               MaxTimeout                => "5000",
               TestAdapter               => "SUT:pci:1,SUT:pci:2,SUT:pci:3," .
                                            "SUT:pci:4,SUT:pci:5,SUT:pci:6,",
               SupportAdapter            => "helper1:pci:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "UDP",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "1024,64512",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               TestDuration              => "20",
            },
         },
      },
      'VMotion'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "VMotion",
         Tags             => "ixgbe,be2net,vmotion",
         Summary          => "This test case verifies that vmotion " .
                             "doesn't work for VM with pci passthru " .
                             "device and does not affect migrating a VM " .
                             "with no PCI device.",
         ExpectedResult   => "PASS",
         Parameters   => {
            vc        => 1,
            SUT   => {
               vm            => 1,
               datastoreType => "shared",
               vmnic => [
                        {
                           driver => "ixgbe",
                           count  => 1,
                           speed  => "10G",
                           passthrough => {
                              type => "sriov",
                              maxvfs => "max",
                           },
                        },
                        ],
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                     virtualfunction => 1,
                  },
               },
            },
            helper1        => {
               'switch'    => ['vss:1'],
               'vmknic'    => ['switch1:1'],
               'vnic'      => ['vmxnet3:1'],
               'vmnic'     => [
                              {
                                 driver => "any",
                                 count  => 1,
                                 speed  => "10G",
                              },
                              ],
               'datastoreType'  => "shared",
            },
            helper2 => {
               'switch'    => ['vss:1'],
               'vmknic'    => ['switch1:1'],
               'vmnic'     => [
                              {
                                 driver => "any",
                                 count  => 1,
                                 speed  => "10G",
                              },
                              ],
            },
            Rules    => "SUT.host == helper1.host, " .
                        "helper1.host != helper2.host",
         },
         WORKLOADS => {
            Sequence => [
                        ['ConnectVC'],
				            ['CreateDC'],
                        ['ConfigureVMForvMotion'],
                        ['EnableVMotion'],
                        ['vmotionNeg'],
                        ['vmotionPos', 'PingFlood'],
                        ],
            ExitSequence   => [['HotRemove']], # temporary workload
                                               # since not all vnics are
                                               # removed in next test has no
                                               # specification for 'vnic'
            "ConnectVC" => {
               Type           => "VC",
               OPT            => "connect",
            },

            "CreateDC" => {
               Type           => "VC",
               OPT            => "adddc",
               DCName         => "/sriovtest",
               Hosts          => "helper1,helper2",
	            MaxTimeout     => "600",
            },

             "ConfigureVMForvMotion" => {
                Type           => "VM",
                Target         => "SUT,helper1",
                Operation      => "configurevmotion",
             },

            "EnableVMotion" => {
               Type             => "NetAdapter",
               TestAdapter      => "helper1:vmknic:1,helper2:vmknic:1",
               VMotion          => "ENABLE",
               ipv4             => "AUTO",
            },

            "EnableVMotion2" => {
               Type             => "NetAdapter",
               TestAdapter      => "helper2:vmknic:1",
               VMotion          => "ENABLE",
               ipv4             => "AUTO",
            },
            "vmotionNeg"       => {
               Type           => "VC",
               OPT            => "vMotion",
               VM             => "SUT",
               DstHost        => "helper2",
               Priority       => "high",
               Staytime       => "30",
               RoundTrip      => "yes",
               ExpectedResult => "FAIL",
            },
            "vmotionPos"       => {
               Type           => "VC",
               OPT            => "vMotion",
               VM             => "helper1",
               DstHost        => "helper2",
               Priority       => "high",
               Staytime       => "30",
               RoundTrip      => "yes",
               SleepBetweenCombos  => "60",
            },
            HotRemove => {
               Type           => "VM",
               Target         => "helper1",
               Operation      => "hotremovevnic",
               TestAdapter    => "1",
            },
            "PingFlood" => {
               Type              => "Traffic",
               ToolName          => "ping",
               TestAdapter       => "SUT:pci:1",
               SupportAdapter    => "helper1:vnic:1",
               L3Protocol        => "ipv4",
               NoofOutbound      => "1",
               RoutingScheme     => "flood",
               TestDuration      => "180",
               connectivitytest  => "0",
            },
         },
      },
   ),
}


##########################################################################
# new --
#       This is the constructor for SRIOVTds
#
# Input:
#       none
#
# Results:
#       An instance/object of SRIOVTds class
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
      my $self = $class->SUPER::new(\%SRIOV);
      return (bless($self, $class));
}

1;


