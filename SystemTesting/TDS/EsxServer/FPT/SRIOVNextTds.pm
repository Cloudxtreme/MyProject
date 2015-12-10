#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::FPT::SRIOVNextTds;

#
# This file contains the structured hash for category, SRIOV.Next tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use TDS::EsxServer::FPT::CommonWorkloads ':AllConstants';

@ISA = qw(TDS::Main::VDNetMainTds);

{
   %SRIOVNext = (
      'MixedModeVds' => {
            Component => "Networking",
            Category  => "Passthrough/SR-IOV",
            TestName  => "MixedModeVds",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Test MixedMode for SR-IOV pNICs and vDS",
            ExpectedResult => "PASS",
            TestbedSpec => {
               vc => {
                  '[1]' => {
                     datacenter => {
                        '[1]' => {
                           host => "host.[1]",
                        },
                     },
                     vds => {
                        '[1]' => {
                           datacenter     => "vc.[1].datacenter.[1]",
                           configurehosts => "add",
                           vmnicadapter   => "host.[1].vmnic.[1];;host.[1].vmnic.[2]",
                           host           => "host.[1]",
                        },
                     },
                     dvportgroup => {
                        '[1-2]' => {
                           vds   => "vc.[1].vds.[1]",
                           ports => "5",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                        '[2]' => {
                           driver => "ixgbe",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "vc.[1].dvportgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "vc.[1].dvportgroup.[1]",
                        },
                     },
                  },
                  '[3]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "vc.[1].dvportgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM1'],['ConfigureIP'],['SetPGUplink1'],['SetPGUplink2'],
                            ['UDPTraffic'],['TCPTraffic'],['SetVST'],['UDPTraffic'],
                            ['TCPTraffic'],['SetVGT'],['SetTrunk'],['UDPTraffic'],['TCPTraffic']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VnicInExitSeq"],
                                 ["DeleteVM3VnicInExitSeq"],['RemoveUplinkFromVds'],['DeleteVds1'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "DeleteVM3VnicInExitSeq" => DELETE_VNIC1_ON_VM3,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "RemoveUplinkFromVds"  => REMOVE_UPLINK_VDS1,
               'DeleteVds1' => DELETE_VDS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM1" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2-3].vnic.[1]",
                  ipv4    => "auto",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],",
                  TestDuration   => "20",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],",
                  TestDuration   => "20",
               },
               "SetPGUplink1" => {
                  Type          => "Switch",
                  TestSwitch    => "vc.[1].vds.[1]",
                  standbynics   => "host.[1].vmnic.[2]",
                  confignicteaming => 'vc.[1].dvportgroup.[1]',
               },
               "SetPGUplink2" => {
                  Type          => "Switch",
                  TestSwitch    => "vc.[1].vds.[1]",
                  standbynics   => "host.[1].vmnic.[1]",
                  confignicteaming => 'vc.[1].dvportgroup.[2]',
               },
               "SetVST" => {
                  Type          => "PortGroup",
                  TestPortgroup => "vc.[1].dvportgroup.[1-2]",
                  vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                  vlantype      => "access",
               },
               "SetVGT" => {
                  Type          => "NetAdapter",
                  TestAdapter   => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]," .
                                   "vm.[3].vnic.[1]",
                  vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
               },
               "SetTrunk" => {
                  Type          => "PortGroup",
                  TestPortgroup => "vc.[1].dvportgroup.[1-2]",
                  vlan          => "[0-4094]",
                  vlantype      => "trunk",
               },
            },
      },
      #To run this test case, enable trunk 18,19 on the pswitch
      'MixedModeVss' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "MixedModeVss",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Test MixedMode for SR-IOV pNICs and vSS",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                        '[2]' => {
                           driver => "ixgbe",
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1-2]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[3]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM1'],['ConfigureIP'],['SetPGUplink1'],['SetPGUplink2'],
                            ['UDPTraffic'],['TCPTraffic'],['SetVST'],['UDPTraffic'],
                            ['TCPTraffic'],['SetVM1VnicVlan'],['SetVM2VnicVlan'],['SetVM3VnicVlan'],['SetTrunk'],['UDPTraffic'],['TCPTraffic']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VnicInExitSeq"],
                                 ["DeleteVM3VnicInExitSeq"],['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "DeleteVM3VnicInExitSeq" => DELETE_VNIC1_ON_VM3,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM1" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2-3].vnic.[1]",
                  ipv4    => "auto",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],",
                  TestDuration   => "20",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],",
                  TestDuration   => "20",
               },
               "SetPGUplink1" => {
                  Type          => "Switch",
                  TestSwitch    => "host.[1].vss.[1]",
                  standbynics   => "host.[1].vmnic.[2]",
                  confignicteaming => 'host.[1].portgroup.[1]',
               },
               "SetPGUplink2" => {
                  Type          => "Switch",
                  TestSwitch    => "host.[1].vss.[1]",
                  standbynics   => "host.[1].vmnic.[1]",
                  confignicteaming => 'host.[1].portgroup.[2]',
               },
               "SetVST" => {
                  Type          => "PortGroup",
                  TestPortgroup => "host.[1].portgroup.[1-2]",
                  vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
               },
               "SetVM1VnicVlan" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1]",
                  vlaninterface => {
                      '[1]' => {
                         ipv4   => 'auto',
                         vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                      },
                   }
               },
               "SetVM2VnicVlan" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[2].vnic.[1]",
                  vlaninterface => {
                      '[1]' => {
                         ipv4   => 'auto',
                         vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                      },
                   }
               },
               "SetVM3VnicVlan" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[3].vnic.[1]",
                  vlaninterface => {
                      '[1]' => {
                         ipv4   => 'auto',
                         vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                      },
                   }
               },
               "RestoreVM1VnicVLAN" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1]",
                  deletevlaninterface       => "vm.[1].pcipassthru.[1].vlaninterface.[1]",
               },
               "RestoreVM2VnicVLAN" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[2].vnic.[1]",
                  deletevlaninterface       => "vm.[2].vnic.[1].vlaninterface.[1]",
               },
               "RestoreVM3VnicVLAN" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[3].vnic.[1]",
                  deletevlaninterface       => "vm.[3].vnic.[1].vlaninterface.[1]",
               },
               "SetTrunk" => {
                  Type          => "PortGroup",
                  TestPortgroup => "host.[1].portgroup.[1-2]",
                  vlan          => "4095",
               },
            },
      },

      'RemoveAddUplink' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "RemoveAddUplink",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Remove the uplink and then add back for SR-IOV pNICs and vSS",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM1'],['ConfigureIP'],
                            ['pingTraffic'],['DeleteUplink'],
                            ['pingTrafficNeg'],['AddUplink'],['pingTraffic']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VnicInExitSeq"],
                                ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM1" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
               "pingTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
               },
               "pingTrafficNeg" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  ExpectedResult => "FAIL",
               },
               'DeleteUplink' => {
                  Type => 'Switch',
                  TestSwitch => 'host.[1].vss.[1]',
                  configureuplinks => 'remove',
                  vmnicadapter => 'host.[1].vmnic.[1]'
               },
               'AddUplink' => {
                  Type => 'Switch',
                  TestSwitch => 'host.[1].vss.[1]',
                  configureuplinks => 'add',
                  vmnicadapter => 'host.[1].vmnic.[1]'
               },
            },
      },

      'VssSwitchVlan' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "VssSwitchVlan",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Test switch vlan for VSS",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                        '[2]' => {
                           driver => "ixgbe",
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[3]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM1'],['ConfigureIP'],
                            ['UDPTraffic'],['TCPTraffic'],['SetVST'],['UDPTraffic'],
                            ['TCPTraffic'],['SetVM1VnicVlan'],['SetVM2VnicVlan'],['SetVM3VnicVlan'],['SetTrunk'],['UDPTraffic'],['TCPTraffic']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VnicInExitSeq"],
                                 ["DeleteVM3VnicInExitSeq"],['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "DeleteVM3VnicInExitSeq" => DELETE_VNIC1_ON_VM3,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM1" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2-3].vnic.[1]",
                  ipv4    => "auto",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],",
                  TestDuration   => "20",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],",
                  TestDuration   => "20",
               },
               "SetVST" => {
                  Type          => "PortGroup",
                  TestPortgroup => "host.[1].portgroup.[1-2]",
                  vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
               },
               "SetTrunk" => {
                  Type          => "PortGroup",
                  TestPortgroup => "host.[1].portgroup.[1-2]",
                  vlan          => "4095",
               },
               "SetVM1VnicVlan" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1]",
                  vlaninterface => {
                      '[1]' => {
                         ipv4   => 'auto',
                         vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                      },
                   }
               },
               "SetVM2VnicVlan" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[2].vnic.[1]",
                  vlaninterface => {
                      '[1]' => {
                         ipv4   => 'auto',
                         vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                      },
                   }
               },
               "SetVM3VnicVlan" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[3].vnic.[1]",
                  vlaninterface => {
                      '[1]' => {
                         ipv4   => 'auto',
                         vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                      },
                   }
               },
               "RestoreVM1VnicVLAN" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1]",
                  deletevlaninterface       => "vm.[1].pcipassthru.[1].vlaninterface.[1]",
               },
               "RestoreVM2VnicVLAN" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[2].vnic.[1]",
                  deletevlaninterface       => "vm.[2].vnic.[1].vlaninterface.[1]",
               },
               "RestoreVM3VnicVLAN" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[3].vnic.[1]",
                  deletevlaninterface       => "vm.[3].vnic.[1].vlaninterface.[1]",
               },
            },
      },

      'VfVdsSamePnic' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "VfVdsSamePnic",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Traffic between VF and vnic through the same pNIC uplink" .
                       " of a VDS",
            ExpectedResult => "PASS",
            TestbedSpec => {
               vc => {
                  '[1]' => {
                     datacenter => {
                        '[1]' => {
                           host => "host.[1]",
                        },
                     },
                     vds => {
                        '[1]' => {
                           datacenter     => "vc.[1].datacenter.[1]",
                           configurehosts => "add",
                           vmnicadapter   => "host.[1].vmnic.[1]",
                           host           => "host.[1]",
                        },
                     },
                     dvportgroup => {
                        '[1-2]' => {
                           vds   => "vc.[1].vds.[1]",
                           ports => "5",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "vc.[1].dvportgroup.[1]",
                        },
                     },
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "vc.[1].dvportgroup.[2]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "vc.[1].dvportgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM1'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VnicInExitSeq"],
                                 ["DeleteVM1VnicInExitSeq"],['RemoveUplinkFromVds'],['DeleteVds1'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "DeleteVM1VnicInExitSeq" => DELETE_VNIC1_ON_VM1,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "RemoveUplinkFromVds"  => REMOVE_UPLINK1_VDS1,
               'DeleteVds1' => DELETE_VDS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM1" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[1-2].vnic.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1-2].vnic.[1],",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1-2].vnic.[1],",
                  TestDuration   => "20",
               },
            },
      },

      'VfVssSamePnic' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "VfVssSamePnic",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Traffic between VF and vnic through the same pNIC uplink" .
                       " of a VSS",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[2]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['UDPTraffic'],['TCPTraffic']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VnicInExitSeq"],
                                 ["DeleteVM1VnicInExitSeq"],['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "DeleteVM1VnicInExitSeq" => DELETE_VNIC1_ON_VM1,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[1-2].vnic.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1-2].vnic.[1]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1-2].vnic.[1]",
                  TestDuration   => "20",
               },
            },
      },
      #To run this test case, enable trunk 18,19 on the pswitch
      'DefaultVLAN' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "DefaultVLAN",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "VLAN configured for VF",
            ExpectedResult => "PASS",
            TestbedSpec => {
               vc => {
                  '[1]' => {
                     datacenter => {
                        '[1]' => {
                           host => "host.[1]",
                        },
                     },
                     vds => {
                        '[1]' => {
                           datacenter     => "vc.[1].datacenter.[1]",
                           configurehosts => "add",
                           vmnicadapter   => "host.[1].vmnic.[1]",
                           host           => "host.[1]",
                        },
                     },
                     dvportgroup => {
                        '[1]' => {
                           vds   => "vc.[1].vds.[1]",
                           ports => "5",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[2]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                     vmnic => {
                        '[1-2]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[2]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]'   => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "vc.[1].dvportgroup.[1]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['pingTraffic1'],
                            ['SetVLAN1'],['pingTraffic1'],['SetVLAN2'],
                            ['pingTrafficNeg']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2PASS1InExitSeq"],
                                ['DeletePG'],['DeleteVss'],['RemoveUplinkFromVds'],['DeleteVds1'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG1,
               "DeleteVss" => DELETE_VSS1,
               "RemoveUplinkFromVds"  => REMOVE_UPLINK1_VDS1,
               'DeleteVds1' => DELETE_VDS1,
               "DisableSRIOV" => DISABLE_SRIOV_HOST1,
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1-2].pcipassthru.[1]",
                  ipv4    => "auto",
               },
               "pingTraffic1" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
               },
               "pingTrafficNeg" => {# sriov nic in different vlan
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
                  ExpectedResult => "FAIL",
               },
               "SetVLAN1" => {
                  Type          => "PortGroup",
                  TestPortgroup => "vc.[1].dvportgroup.[1],".
                                   "host.[1].portgroup.[1]",
                  vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                  vlantype      => "access",
               },
               "SetVLAN2" => {
                  Type          => "PortGroup",
                  TestPortgroup => "vc.[1].dvportgroup.[1]",
                  vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                  vlantype      => "access",
               },
            },
      },

      'StaticMAC' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "StaticMAC",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "Static MAC for a VF",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic => {
                        '[1]'   => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],['SetMAC'],
                            ['UDPTraffic'],['TCPTraffic']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],
                                 ["DeleteVM2VnicInExitSeq"],['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],",
                  TestDuration   => "20",
               },
               "SetMAC" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1]",
                  setmacaddr  =>
                  VDNetLib::TestData::TestConstants::SRIOV_STATIC_MAC_1,
               },
            },
      },

      'BootOptions' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "BootOptions",
            Version   => "2",
            Tags      => "MN.Next,hostreboot",
            Summary => "VF works after rebooting the host",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic => {
                        '[1]'   => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],['RebootHost'],
                            ['PoweronAllVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],
                                 ["DeleteVM2VnicInExitSeq"],['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
               "PoweronAllVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],",
                  TestDuration   => "20",
               },
               "RebootHost" => {
                  Type     => "Host",
                  TestHost => "host.[1]",
                  Reboot   => "yes",
               },
            },
      },

      'VFConfigPersistence' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "VFConfigPersistence",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "VFs of VMs won't get impacted after reboot",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                        '[2]' => {
                           driver => "ixgbe",
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[2]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],['RebootVM'],
                            ['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],["PoweroffAllVMs"],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],
                                 ["DeleteVM2VnicInExitSeq"],['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  TestDuration   => "20",
               },
               "RebootVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweroff,poweron",
                  Iterations => "10",
               },
            },
      },

      'EnableDisableSRIOV' => {
          Component => "Infrastructure",
          Category  => "vdnet",
          TestName  => "EnableDisableSRIOV",
          Version   => "2",
          Tags      => "MN.Next,CAT_P0",
          Summary   => "Enable/Disable SR-IOV with different max_vfs",
          TestbedSpec   => {
              host => {
                  '[1]' => {
                      vmnic => {
                          '[1-2]' => {
                              driver      => "ixgbe",
                          },
                      },
                  },
              },
          },

          WORKLOADS => {
             Sequence => [['ValidMaxVfs1'], ['ValidMaxVfs2'],['ValidMaxVfs3'],
                          ['InvalidMaxVfs1'], ['DisableSRIOV'],],
             ExitSequence => [["DisableSRIOV"],],
             Iterations => "20",
             ValidMaxVfs1 => {
                Type     => "Host",
                TestHost => "host.[1]",
                sriov    => "enable",
                vmnicadapter   => "host.[1].vmnic.[1];;host.[1].vmnic.[2]",
                maxvfs   => "1",
             },
             ValidMaxVfs2 => {
                Type     => "Host",
                TestHost => "host.[1]",
                sriov    => "enable",
                vmnicadapter   => "host.[1].vmnic.[1];;host.[1].vmnic.[2]",
                maxvfs   => "2",
             },
             ValidMaxVfs3 => {
                Type     => "Host",
                TestHost => "host.[1]",
                sriov    => "enable",
                vmnicadapter   => "host.[1].vmnic.[1];;host.[1].vmnic.[2]",
                maxvfs   =>
                VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
             },
             InvalidMaxVfs1 => {
                Type     => "Host",
                TestHost => "host.[1]",
                sriov    => "enable",
                vmnicadapter   => "host.[1].vmnic.[1];;host.[1].vmnic.[2]",
                maxvfs   => "-1",
                ExpectedResult => "FAIL",
             },
             DisableSRIOV => {
                Type     => "Host",
                TestHost => "host.[1]",
                sriov    => "disable",
                vmnicadapter   => "host.[1].vmnic.[1];;host.[1].vmnic.[2]",
             },
          },
      },

      'VFToVF' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "VFToVF",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "Traffic between VF and VF",
            ExpectedResult => "PASS",

            TestbedSpec => {
               vc => {
                  '[1]' => {
                     datacenter => {
                        '[1]' => {
                           host => "host.[1];;host.[2]",
                        },
                     },
                     'dvportgroup' => {
                        '[1]' => {
                           'vds' => 'vc.[1].vds.[1]',
                            ports => "5",
                        },
                     },
                     'vds' => {
                        '[1]' => {
                           'datacenter' => 'vc.[1].datacenter.[1]',
                           'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                           'configurehosts' => 'add',
                           'host' => 'host.[1-2]'
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
                  '[2]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => 'vc.[1].dvportgroup.[1]',
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => 'vc.[1].dvportgroup.[1]',
                        },
                     },
                  },
                  '[3]' => {
                     host => "host.[2]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[2].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => 'vc.[1].dvportgroup.[1]',
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],
                            ['Traffic_Multicast'],['Traffic_Broadcast'],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2PASS1InExitSeq"],["DeleteVM3PASS1InExitSeq"],
                                ['RemoveUplinkFromVds'],['DeleteVds'],['DisableSRIOVHost1'],['DisableSRIOVHost2']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM2,
               "DeleteVM3PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM3,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "RemoveUplinkFromVds" => REMOVE_UPLINK_ALLHOST_VDS1,
               "DeleteVds" => DELETE_VDS1,
               "DisableSRIOVHost1" => DISABLE_SRIOV_VMNIC1_HOST1,
               "DisableSRIOVHost2" => DISABLE_SRIOV_VMNIC1_HOST2,
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2],vm.[3]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1-3].pcipassthru.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1],vm.[3].pcipassthru.[1]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1],vm.[3].pcipassthru.[1]",
                  TestDuration   => "20",
               },
               "Traffic_Multicast" => {
                  Type           => "Traffic",
                  RoutingScheme  => "Multicast",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1],vm.[3].pcipassthru.[1]",
               },
               "Traffic_Broadcast" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  SleepBetweenCombos => "20",
                  NoofInbound    => "2",
                  RoutingScheme  => "broadcast,flood",
                  NoofOutbound   => "2",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1],vm.[3].pcipassthru.[1]",
               },
            },
      },

      'VMKToVF' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "VMKToVF",
            Version   => "2",
            Tags      => "MN.Next,CAT_P0",
            Summary => "Traffic between VMK interface and VF",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                     vmknic => {
                        '[1]' => {
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic_VMK'],['TCPTraffic_VMK'],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],['RemoveVmknic'],
                                ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               'RemoveVmknic' => REMOVE_HOST1_VMKNIC,
               "PoweronVM" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],host.[1].vmknic.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic_VMK" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "host.[1].vmknic.[1]",
                  SupportAdapter => "vm.[1].pcipassthru.[1]",
                  TestDuration   => "20",
               },
               "UDPTraffic_VMK" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "host.[1].vmknic.[1]",
                  SupportAdapter => "vm.[1].pcipassthru.[1]",
                  TestDuration   => "20",
               },
            },
      },

      'ResetVF' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "ResetVF",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "Traffice work after rebooting/killing a VM",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronAllVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],
                            ['DisableEnableVnic'], ['UDPTraffic'],['TCPTraffic'],
                            ['RebootVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],['KillVM'],
                            ['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2PASS1InExitSeq"],
                                ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronAllVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1-2].pcipassthru.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
                  TestDuration   => "20",
               },
               "DisableEnableVnic" => {
                  Type         => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1]",
                  DeviceStatus => "DOWN,UP",
                  Iterations   => "10",
               },
               "RebootVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweroff,poweron",
               },
               "KillVM" => {
                  Type      => "VM",
                  TestVM    => "vm.[1]",
                  Operation => "killvm",
               },
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
            },
      },

      'DisconnectVF' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "DisconnectVF",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "Disconnect pSwitch port of a VF uplink",
            ExpectedResult => "PASS",
            TestbedSpec => {
               vc => {
                  '[1]' => {
                     datacenter => {
                        '[1]' => {
                           host => "host.[1]",
                        },
                     },
                     vds => {
                        '[1]' => {
                           datacenter     => "vc.[1].datacenter.[1]",
                           configurehosts => "add",
                           vmnicadapter   => "host.[1].vmnic.[1]",
                           host           => "host.[1]",
                        },
                     },
                     dvportgroup => {
                        '[1-2]' => {
                           vds   => "vc.[1].vds.[1]",
                           ports => "5",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                     pswitchport => {
                        '[1]' => {
                           vmnic => "host.[1].vmnic.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "vc.[1].dvportgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "vc.[1].dvportgroup.[2]",
                        },
                     },
                  },
               },
               pswitch => {
                  '[-1]' => {},
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['pingTraffic'],['DisablePort'],
                            ['pingTrafficNeg'],['EnablePort'],['pingTraffic']],
               ExitSequence => [['EnablePort'],["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VNIC1InExitSeq"],
                                ['RemoveUplinkFromVds'],['DeleteVds1'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VNIC1InExitSeq" => DELETE_VNIC1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "RemoveUplinkFromVds"  => REMOVE_UPLINK1_VDS1,
               'DeleteVds1' => DELETE_VDS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
               "pingTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
               },
               "pingTrafficNeg" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  ExpectedResult => "FAIL",
               },
               "DisablePort" => {
                  Type         => "Port",
                  TestPort     => "host.[1].pswitchport.[1]",
                  portstatus   => "disable",
               },
               "EnablePort" => {
                  Type         => "Port",
                  TestPort     => "host.[1].pswitchport.[1]",
                  portstatus   => "enable",
               },
            },
      },

      'VMOPs' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "VMOPs",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "VM operations: create snapshot, suspend",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic => {
                        '[1]' => {
                           driver    => "vmxnet3",
                           portgroup => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],['SuspendVM'],
                            ['CreateSnapshot'],['UDPTraffic'],['TCPTraffic'],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VnicInExitSeq"],
                                ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  TestDuration   => "20",
               },
               "SuspendVM" => {
                  Type           => "VM",
                  TestVM         => "vm.[1]",
                  vmstate        => "suspend",
                  ExpectedResult => "FAIL",
               },
               "CreateSnapshot" => {
                  Type           => "VM",
                  TestVM         => "vm.[1]",
                  Operation      => "createsnap",
                  SnapshotName   => "sriovNeg",
                  ExpectedResult => "FAIL",
               }
            },
      },
      #To run this test, enable trunk 18 on pswitch
      'GuestVLAN' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "GuestVLAN",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "GuestVLAN",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1-2]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss  => "host.[1].vss.[1]",
                        },
                     },
                     vmnic => {
                        '[1-2]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[2]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],["ConfigureIP"],['pingTraffic1'],['SetVLANPG'],
                            ['SetVnicVlan1'],['pingTrafficNeg'],
                            ['SetVnicVlan2'],['pingTraffic2'],
                            ['RestoreVLAN1'],['RestoreVLAN2'],["ConfigureIP"],['pingTraffic1']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2PASS1InExitSeq"],
                                ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_HOST1,
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1-2].pcipassthru.[1]",
                  ipv4    => "auto",
               },
               "SetVLANPG" => {
                  Type          => "PortGroup",
                  TestPortgroup => "host.[1].portgroup.[1-2]",
                  vlan          => "4095",
               },
               "SetVnicVlan1" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1]",
                  vlaninterface => {
                      '[1]' => {
                         ipv4   => 'auto',
                         vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                      },
                   }
               },
               "SetVnicVlan2" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[2].pcipassthru.[1]",
                  vlaninterface => {
                      '[1]' => {
                         ipv4   => 'auto',
                         vlanid => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
                      },
                   }
               },
               "RestoreVLAN1" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1]",
                  deletevlaninterface       => "vm.[1].pcipassthru.[1].vlaninterface.[1]",
               },
               "RestoreVLAN2" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[2].pcipassthru.[1]",
                  deletevlaninterface       => "vm.[2].pcipassthru.[1].vlaninterface.[1]",
               },
               "pingTraffic1" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
               },
               "pingTraffic2" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1].vlaninterface.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1].vlaninterface.[1]",
               },
               "pingTrafficNeg" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1].vlaninterface.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
                  ExpectedResult => "FAIL",
               },
            },
      },

      'StressOptions' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "StressOptions",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "StressOptions",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic => {
                        '[1]' => {
                           driver    => "vmxnet3",
                           portgroup => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['pingTraffic'],['PoweroffVM'],
                            ['EnableStress'],['PoweronVMNeg'],['DisableStress'],
                            ['PoweronVM'],['pingTraffic']],
               ExitSequence => [['DisableStress'],["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VNIC1InExitSeq"],
                                ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VNIC1InExitSeq" => DELETE_VNIC1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => {
                  Type          => "VM",
                  TestVM        => "vm.[1]",
                  vmstate       => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
               "PoweroffVM" => {
                  Type          => "VM",
                  TestVM        => "vm.[1]",
                  vmstate       => "poweroff",
               },
               "PoweronVMNeg" => {
                  Type           => "VM",
                  TestVM         => "vm.[1]",
                  vmstate        => "poweron",
                  ExpectedResult => "FAIL",
               },
               "EnableStress" => {
                  Type          => "Host",
                  TestHost      => "host.[1]",
                  StressOptions => "NetPTSetupIntrProxyFailure=1",
                  Stress        => "Enable",
               },
               "DisableStress" => {
                  Type          => "Host",
                  TestHost      => "host.[1]",
                  StressOptions => "NetPTSetupIntrProxyFailure=1",
                  Stress        => "Disable",
               },
               "pingTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
               },
            },
      },

      'vMotion' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "vMotion",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "Traffic before/after vMotion",
            ExpectedResult => "PASS",
            TestbedSpec => {
               vc => {
                  '[1]' => {
                     datacenter => {
                        '[1]' => {
                           host => "host.[1];;host.[2]",
                        },
                     },
                     'dvportgroup' => {
                        '[1]' => {
                           'vds' => 'vc.[1].vds.[1]',
                            ports => "5",
                        },
                     },
                     'vds' => {
                        '[1]' => {
                           'datacenter' => 'vc.[1].datacenter.[1]',
                           'vmnicadapter' => 'host.[1-2].vmnic.[1]',
                           'configurehosts' => 'add',
                           'host' => 'host.[1-2]'
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmknic => {
                        '[1]' => {
                           portgroup => "vc.[1].dvportgroup.[1]",
                        },
                     },
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
                  '[2]' => {
                     vmknic => {
                        '[1]' => {
                           portgroup => "vc.[1].dvportgroup.[1]",
                        },
                     },
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     datastoreType => 'shared',
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => 'vc.[1].dvportgroup.[1]',
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[2]",
                     datastoreType => 'shared',
                     vnic => {
                        '[1]' => {
                           driver    => "vmxnet3",
                           portgroup => 'vc.[1].dvportgroup.[1]',
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['EnableVmotion1'],['EnableVmotion2'],
                            ['UDPTraffic'],['TCPTraffic'],['VmotionNeg'],
                            ['VmotionPos', 'pingTraffic'],['UDPTraffic'],['TCPTraffic'],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2NIC1InExitSeq"],
                                ['RemoveHost1Vmknic'],['RemoveHost2Vmknic'],['RemoveUplinkFromVds'],['DeleteVds1'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2NIC1InExitSeq" => DELETE_VNIC1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG1,
               "DeleteVss" => DELETE_VSS1,
               "RemoveUplinkFromVds"  => REMOVE_UPLINK_VDS1,
               'RemoveHost1Vmknic' => REMOVE_HOST1_VMKNIC,
               'RemoveHost2Vmknic' => REMOVE_HOST2_VMKNIC,
               'DeleteVds1' => DELETE_VDS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,

               "VMPreConfig" => {
                  Type      => "VM",
                  TestVM    => "vm.[1],vm.[2]",
                  operation => 'configurevmotion'
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
               "EnableVmotion1" => {
                  Type             => "NetAdapter",
                  TestAdapter      => "host.[1].vmknic.[1]",
                  configurevmotion => "ENABLE",
                  ipv4             => "auto",
               },
               "EnableVmotion2" => {
                  Type             => "NetAdapter",
                  TestAdapter      => "host.[2].vmknic.[1]",
                  configurevmotion => "ENABLE",
                  ipv4             => "auto",
               },
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  TestDuration   => "20",
               },
               "pingTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  TestDuration   => "180",
               },
               'VmotionNeg' => {
                  Type => 'VM',
                  TestVM => 'vm.[1]',
                  priority => 'high',
                  vmotion => 'roundtrip',
                  sleepbetweenworkloads => '30',
                  dsthost => 'host.[2]',
                  staytime => '60',
                  ExpectedResult => "FAIL",
               },
               'VmotionPos' => {
                  Type => 'VM',
                  TestVM => 'vm.[2]',
                  priority => 'high',
                  vmotion => 'roundtrip',
                  sleepbetweenworkloads => '30',
                  dsthost => 'host.[1]',
                  staytime => '60',
               },
            },
      },

      'DisablePortsVdsVF' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "DisablePortsVdsVF",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Traffic between a VF and a vnic after disabling the".
                       " portgroup the VF attached to.",
            ExpectedResult => "PASS",
            TestbedSpec => {
               vc => {
                  '[1]' => {
                     datacenter => {
                        '[1]' => {
                           host => "host.[1]",
                        },
                     },
                     vds => {
                        '[1]' => {
                           datacenter     => "vc.[1].datacenter.[1]",
                           configurehosts => "add",
                           vmnicadapter   => "host.[1].vmnic.[1]",
                           host           => "host.[1]",
                        },
                     },
                     dvportgroup => {
                        '[1-2]' => {
                           vds   => "vc.[1].vds.[1]",
                           ports => "5",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "vc.[1].dvportgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "vc.[1].dvportgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['pingTraffic'],['BlockPG'],
                            ['pingTrafficNeg'],['UnblockPG'],['pingTraffic']],
               ExitSequence => [['UnblockPG'],["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2VnicInExitSeq"],
                                ['RemoveUplinkFromVds'],['DeleteVds1'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "RemoveUplinkFromVds"  => REMOVE_UPLINK1_VDS1,
               'DeleteVds1' => DELETE_VDS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => POWERON_VM1,
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
               "BlockPG" => {
                  Type       => 'Switch',
                  TestSwitch => 'vc.[1].vds.[1]',
                  portgroup  => 'vc.[1].dvportgroup.[1]',
                  blockport  => 'vm.[1].pcipassthru.[1]',
               },
               "UnblockPG" => {
                  Type        => 'Switch',
                  TestSwitch  => 'vc.[1].vds.[1]',
                  portgroup   => 'vc.[1].dvportgroup.[1]',
                  unblockport => 'vm.[1].pcipassthru.[1]',
               },
               "pingTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],",
               },
               "pingTrafficNeg" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],",
                  ExpectedResult => "FAIL",
               },
            },
      },
      'FptVfVdsSameVM' => {
            Component => "Networking",
            Product   => 'ESX',
            QCPath    => 'OP\Networking-FVT\SRIOVNext',
            Summary   => "Traffic between SRIOV VF and FPT vnic" .
                       " through the same VM on a VDS",
            ExpectedResult => 'The traffic should be able to pass',
            Status    => 'Execution Ready',
            Category  => "Passthrough",
            TestName  => "FptVfVdsSameVM",
            Version   => "2",
            Tags      => "sanity,automated,sriov,CAT_P0,hostreboot",
            AutomationLevel  => 'Manual',
            FullyAutomatable => 'Y',
            TestcaseLevel    => 'Functional',
            TestcaseType     => 'Functional',
            Priority         => 'P1',
            Developer        => 'Shawntu',
            Partnerfacing    => 'N',
            Duration         => '',
            Testbed          => '',
            Version          => '2',
            AutomationStatus => 'Automated',
            TestbedSpec => {
               vc => {
                  '[1]' => {
                     datacenter => {
                        '[1]' => {
                           host => "host.[1]",
                        },
                     },
                     vds => {
                        '[1]' => {
                           datacenter     => "vc.[1].datacenter.[1]",
                           configurehosts => "add",
                           vmnicadapter   => "host.[1].vmnic.[1]",
                           host           => "host.[1]",
                        },
                     },
                     dvportgroup => {
                        '[1]' => {
                           vds   => "vc.[1].vds.[1]",
                           ports => "5",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                        '[2]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type => "fpt"
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "vc.[1].dvportgroup.[1]",
                        },
                        '[2]' => {
                           vmnic     => "host.[1].vmnic.[2]",
                           driver    => "fpt",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM1PASS2InExitSeq"],
                                ['RemoveUplinkFromVds'],['DeleteVds1'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM1PASS2InExitSeq" => DELETE_PASSTHROUGH2_ON_VM1,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "RemoveUplinkFromVds"  => REMOVE_UPLINK1_VDS1,
               'DeleteVds1' => DELETE_VDS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => POWERON_VM1,
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1-2]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1].pcipassthru.[2]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1].pcipassthru.[2]",
                  TestDuration   => "20",
               },
            },
      },

      'FptVfVssSameVM' => {
            Component => "Networking",
            Product   => 'ESX',
            QCPath    => 'OP\Networking-FVT\SRIOVNext',
            Summary   => "Traffic between SRIOV VF and FPT vnic" .
                       " through the same VM on a VSS",
            ExpectedResult => 'The traffic should be able to pass',
            Status    => 'Execution Ready',
            Category  => "Passthrough",
            TestName  => "FptVfVssSameVM",
            Version   => "2",
            Tags      => "sanity,automated,sriov,hostreboot",
            AutomationLevel  => 'Manual',
            FullyAutomatable => 'Y',
            TestcaseLevel    => 'Functional',
            TestcaseType     => 'Functional',
            Priority         => 'P1',
            Developer        => 'Shawntu',
            Partnerfacing    => 'N',
            Duration         => '',
            Testbed          => '',
            Version          => '2',
            AutomationStatus => 'Automated',
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                        '[2]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type => "fpt"
                           },
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                        '[2]' => {
                           vmnic     => "host.[1].vmnic.[2]",
                           driver    => "fpt",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic']],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM1PASS2InExitSeq"],
                                ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM1PASS2InExitSeq" => DELETE_PASSTHROUGH2_ON_VM1,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG1,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1-2]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1].pcipassthru.[2]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1].pcipassthru.[2]",
                  TestDuration   => "20",
               },
            },
      },

      'ConfigMaxVfsVM' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "ConfigMaxVfsVM",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "Configure 6 vfs on two VMs and send traffic",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1-2]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1-2]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1-3]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                        '[4-6]' => {
                           vmnic     => "host.[1].vmnic.[2]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1-6]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },
            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIPVM1'],['ConfigureIPVM2'],['UDPTraffic'],['TCPTraffic']
                            ],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASSInExitSeq"],["DeleteVM2PASSInExitSeq"],
                                 ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASSInExitSeq" => DELETE_PASSTHROUGH_ALL_ON_VM1,
               "DeleteVM2PASSInExitSeq" => DELETE_PASSTHROUGH_ALL_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_HOST1,
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "ConfigureIPVM1" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1-6]",
                  ipv4    => "auto",
               },
               "ConfigureIPVM2" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[2].pcipassthru.[1-6]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1-6]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[2].pcipassthru.[1]",
                  SupportAdapter => "vm.[1].pcipassthru.[1-6]",
                  TestDuration   => "20",
               },
            },
        },

      'TSO' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "TSO",
            Version   => "2",
            Tags      => "MN.Next",
            Summary => "Traffic after disable/enable TSO",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1-2]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                                VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1-2]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[2]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['EnableTSO'],['TSOTraffic'],
                            ['DisableTSO'],['TSOTraffic']],
               ExitSequence => [['DisableTSO'],["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2PASS1InExitSeq"],
                                ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG1,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "EnableTSO" => {
                  Type         => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1]",
                  TSOIPV4      => "Enable",
               },
               "DisableTSO" => {
                  Type         => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1]",
                  TSOIPV4      => "Disable",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1-2].pcipassthru.[1]",
                  ipv4    => "auto",
               },
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "TSOTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  localsendsocketsize => '64512',
                  sendmessagesize => '14000',
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
                  TestDuration   => "20",
               },
            },
        },
      'ConfigVMStaticMACVlanPersistence' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "ConfigVMStaticMACVlanPersistence",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Configure the VM with static mac sriov vnic" .
                       " and reboot the VM",
            ExpectedResult => "PASS",
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1-2]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1-2]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                           macaddress =>
                           VDNetLib::TestData::TestConstants::SRIOV_STATIC_MAC_1,
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[2]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[2]",
                           macaddress =>
                           VDNetLib::TestData::TestConstants::SRIOV_STATIC_MAC_2,
                        },
                     },
                  },
               },
            },
         WORKLOADS => {
            Sequence => [
                        ["PoweronAllVM"],
                        ["ConfigureIP"],
                        ['TCPTraffic'],
                        ['UDPTraffic'],
                        ["RebootVM1"],
                        ["ConfigureIP"],
                        ['TCPTraffic'],
                        ['UDPTraffic'],
                        ],
            ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2PASS1InExitSeq"],
                              ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
            "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
            "DeleteVM2PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM2,
            "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
            "DeletePG" => DELETE_HOST1_PG,
            "DeleteVss" => DELETE_VSS1,
            "DisableSRIOV" => DISABLE_SRIOV_HOST1,
            "PoweronAllVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
            },
            "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1-2].pcipassthru.[1]",
                  ipv4    => "auto",
            },
            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "iperf",
               TestAdapter               => "vm.[1].pcipassthru.[1]",
               SupportAdapter            => "vm.[2].pcipassthru.[1]",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "tcp",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               TestDuration              => "20",
               Verification              => "VerificationPos",
            },
            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "iperf",
               TestAdapter               => "vm.[1].pcipassthru.[1]",
               SupportAdapter            => "vm.[2].pcipassthru.[1]",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "udp",
               udpbandwidth   => "10000M",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               TestDuration              => "20",
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
            "RebootVM1" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweroff,poweron",
            },
         },
      },
      'LACP' => {
            Product           => 'ESX',
            Category          => 'Passthrough',
            Component         => 'Networking',
            TestName          => "LACP",
            Priority          => 'P2',
            Version           => '2' ,
            Summary           => "Test LACP feature with SRIOV enabled
                                pNICs",
            ExpectedResult    => "PASS",
            AutomationStatus  => "Automated",
            Duration     => "time in seconds",
            TestbedSpec       => {
                vc    => {
                    '[1]'   => {
                        datacenter => {
                            '[1]' => {
                                host  => "host.[1]",
                            },
                        },
                        vds        => {
                            '[1]'   => {
                                datacenter => "vc.[1].datacenter.[1]",
                                configurehosts => "add",
                                host  => "host.[1]",
                                'lag' => {
                                    '[1]' => {
                                    },
                                },
                            },
                        },
                        dvportgroup  => {
                            '[1]' => {
                                vds    => "vc.[1].vds.[1]",
                                ports  => "10",
                            },
                        },
                    },
                },
                host  => {
                    '[1]'   => {
                        vmnic  => {
                            '[1-2]' => {
                                driver => "ixgbe",
                                passthrough => {
                                type   => "sriov",
                                maxvfs =>
                                VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                                },
                            },
                        },
                        pswitchport => {
                            '[1]'     => {
                                vmnic => "host.[1].vmnic.[1]",
                            },
                            '[2]'     => {
                                vmnic => "host.[1].vmnic.[2]",
                            },
                        },
                    },
                },
                vm => {
                  '[1]' => {
                        host => "host.[1]",
                        reservememory => "max",
                        vmstate => "poweroff",
                        pcipassthru => {
                            '[1]' => {
                                vmnic     => "host.[1].vmnic.[1]",
                                driver    => "sriov",
                                portgroup => "vc.[1].dvportgroup.[1]",
                            },
                        },
                    },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                            driver     => "vmxnet3",
                            portgroup  => "vc.[1].dvportgroup.[1]",
                            },
                        },
                    },
                },
                pswitch => {
                    '[-1]' => {
                    },
                },
            },
            WORKLOADS => {
                Sequence     => [['PoweronVM'],['ConfigureIP'],["AddUplinkToLag"],["ConfigureChannelGroup"],
                                 ["SetActiveUplink"],["CheckUplinkState"],
                             ["ChangeLBPolicy"],["UDPTraffic"],["TCPTraffic"],
                             ["DownLink"],["UDPTraffic"],["TCPTraffic"],],
                ExitSequence => [["UpLink"],
                                 ["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM1VnicInExitSeq"],
                                 ["RemovePortsFromChannelGroup"],["DeleteChannelGroup"],
                                 ['DeleteVds1'],['DisableSRIOV'],
                                 ],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM1VnicInExitSeq" => DELETE_VNIC1_ON_VM1,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "RemoveUplinkFromVds"  => REMOVE_UPLINK_VDS1,
               'DeleteVds1' => DELETE_VDS1,
               "DisableSRIOV" => DISABLE_SRIOV_HOST1,
               "PoweronVM" => {
                    Type    => "VM",
                    TestVM  => "vm.[1]",
                    vmstate => "poweron",
                },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]",
                  ipv4    => "auto",
               },
                "AddUplinkToLag" => {
                    Type            => "LACP",
                    TestLag         => "vc.[1].vds.[1].lag.[1]",
                    configuplinktolag => "add",
                    vmnicadapter    => "host.[1].vmnic.[1-2]",
                },
                "ConfigureChannelGroup" => {
                    Type            => "Port",
                    TestPort        => "host.[1].pswitchport.[1-2]",
                    configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
                    Mode            => "Active",
                },
                "SetActiveUplink" => {
                    Type         => "PortGroup",
                    TestPortgroup => "vc.[1].dvportgroup.[1]",
                    failoverorder => "vc.[1].vds.[1].lag.[1]",
                    failovertype  => "active",
                },
                "CheckUplinkState" => {
                    Type            => "LACP",
                    TestLag         => "vc.[1].vds.[1].lag.[1]",
                    checkuplinkstate => "Bundled",
                    vmnicadapter    => "host.[1].vmnic.[1-2]",
                },
                "ChangeLBPolicy" => {
                    Type            => "LACP",
                    TestLag         => "vc.[1].vds.[1].lag.[1]",
                    lagoperation    => "edit",
                    lagloadbalancing => "srcDestMac",
                },
                "UDPTraffic" => {
                    Type           => "Traffic",
                    ToolName       => "iperf",
                    L3Protocol     => "ipv4,ipv6",
                    L4Protocol     => "udp",
                    udpbandwidth   => "10000M",
                    TestAdapter    => "vm.[1].pcipassthru.[1]",
                    SupportAdapter => "vm.[2].vnic.[1],",
                    TestDuration   => "20",
                },
                "TCPTraffic" => {
                    Type           => "Traffic",
                    ToolName       => "iperf",
                    L3Protocol     => "ipv4,ipv6",
                    L4Protocol     => "tcp",
                    TestAdapter    => "vm.[1].pcipassthru.[1]",
                    SupportAdapter => "vm.[2].vnic.[1],",
                    TestDuration   => "20",
                },
                "DownLink" => {
                    Type            => "NetAdapter",
                    TestAdapter     => "host.[1].vmnic.[2]",
                    devicestatus    => "down",
                },
                "UpLink" => {
                    Type            => "NetAdapter",
                    TestAdapter     => "host.[1].vmnic.[2]",
                    devicestatus    => "up",
                },
                "RemovePortsFromChannelGroup" => {
                    Type            => "Port",
                    TestPort        => "host.[1].pswitchport.[1-2]",
                    configurechannelgroup => "no",
                },
                "DeleteChannelGroup" => {
                    Type                 => "Switch",
                    TestSwitch           => "pswitch.[-1]",
                    removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A
                },
            },
        },
         'VssSriovSameVM' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "VssSriovSameVM",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Traffic between VF with sub PCI and vnic through " .
                       "the same pNIC uplink of a VSS",
            ExpectedResult   => "PASS",
            AutomationLevel  => 'Automated',
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "fpt",
                           virtualfunction => "1",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                     vnic  => {
                        '[1]' => {
                           driver     => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     vnic  => {
                        '[1]' => {
                           driver    => "vmxnet3",
                           portgroup  => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASSInExitSeq"],["DeleteVM1VnicInExitSeq"],
                                 ["DeleteVM2VnicInExitSeq"],['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASSInExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2VnicInExitSeq" => DELETE_VNIC1_ON_VM2,
               "DeleteVM1VnicInExitSeq" => DELETE_VNIC1_ON_VM1,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1].pcipassthru.[1],vm.[1-2].vnic.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1-2].vnic.[1]",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1-2].vnic.[1]",
                  TestDuration   => "20",
               },
                "PoweroffVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweroff",
               },
            },
        },
        'InterOpPFVF' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "InterOpPFVF",
            Version   => "2",
            Tags      => "vSphere2013",
            Summary => "Traffic between two VMs one VM is configured VF with sub PCI" .
                       "the other VM is configured with PF with FPF",
            ExpectedResult   => "PASS",
            AutomationLevel  => 'Automated',
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                        '[2]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "fpt",
                           },
                        },
                     },
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "fpt",
                           virtualfunction => "1",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[2]",
                           driver    => "fpt",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2PASS1InExitSeq"],
                               ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG1,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1-2].pcipassthru.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                 Type                      => "Traffic",
                 ToolName                  => "iperf",
                 TestAdapter               => "vm.[1].pcipassthru.[1]",
                 SupportAdapter            => "vm.[2].pcipassthru.[1]",
                 L3Protocol                => "ipv4,ipv6",
                 L4Protocol                => "tcp",
                 NoofInbound               => "1",
                 NoofOutbound              => "1",
                 TestDuration              => "60",
               },
               "UDPTraffic" => {
                 Type                      => "Traffic",
                 ToolName                  => "iperf",
                 TestAdapter               => "vm.[1].pcipassthru.[1]",
                 SupportAdapter            => "vm.[2].pcipassthru.[1]",
                 L3Protocol                => "ipv4,ipv6",
                 udpbandwidth   => "10000M",
                 L4Protocol                => "udp",
                 NoofInbound               => "1",
                 NoofOutbound              => "1",
                 TestDuration              => "60",
               },
                "PoweroffVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweroff",
               },
            },
        },
        'End2EndPersistence' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "End2EndPersistence",
            Version   => "2",
            Tags      => "MN.Next,reboot,hostreboot",
            Summary => "Two VMs, one configured VF with sub PCI,".
                       "the other configured VF with SRIOV,works after rebooting the host",
            ExpectedResult   => "PASS",
            AutomationLevel  => 'Automated',
            TestbedSpec => {
               host => {
                  '[1]' => {
                     vss => {
                        '[1]' => {
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1]' => {
                           vss => "host.[1].vss.[1]",
                        },
                     },
                     vmnic => {
                        '[1]' => {
                           driver => "ixgbe",
                           passthrough => {
                              type   => "sriov",
                              maxvfs =>
                              VDNetLib::TestData::TestConstants::DEFAULT_IXGBE_MAXVFS,
                           },
                        },
                     },
                  },
               },
               vm => {
                  '[1]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]'   => {
                           vmnic      => "host.[1].vmnic.[1]",
                           driver     => "fpt",
                           virtualfunction => "any",
                           portgroup  => "host.[1].portgroup.[1]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[1]",
                     reservememory => "max",
                     vmstate => "poweroff",
                     pcipassthru => {
                        '[1]' => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[1]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM1'],['PoweronVM2'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],['RebootHost'],
                            ['PoweronVM1'],['PoweronVM2'],['ConfigureIP'],['UDPTraffic'],['TCPTraffic'],],
               ExitSequence => [["PoweroffAllVMs"],["DeleteVM1PASS1InExitSeq"],["DeleteVM2PASS1InExitSeq"],
                               ['DeletePG'],['DeleteVss'],['DisableSRIOV']],
               "DeleteVM1PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM1,
               "DeleteVM2PASS1InExitSeq" => DELETE_PASSTHROUGH1_ON_VM2,
               "PoweroffAllVMs"  => POWEROFF_ALL_VMS,
               "DeletePG" => DELETE_HOST1_PG1,
               "DeleteVss" => DELETE_VSS1,
               "DisableSRIOV" => DISABLE_SRIOV_VMNIC1_HOST1,
               "PoweronVM1" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "PoweronVM2" => {
                  Type    => "VM",
                  TestVM  => "vm.[2]",
                  vmstate => "poweron",
               },
               "ConfigureIP" => {
                  Type    => "NetAdapter",
                  TestAdapter  => "vm.[1-2].pcipassthru.[1]",
                  ipv4    => "auto",
               },
               "TCPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1],",
                  TestDuration   => "20",
               },
               "UDPTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "iperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "udp",
                  udpbandwidth   => "10000M",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1],",
                  TestDuration   => "20",
               },
               "RebootHost" => {
                  Type     => "Host",
                  TestHost => "host.[1]",
                  Reboot   => "yes",
               },
               "PoweroffVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweroff",
               },
            },
        },
   ),
}

##########################################################################
# new --
#       This is the constructor for SRIOVNextTds
#
# Input:
#       none
#
# Results:
#       An instance/object of SRIOVNextTds class
#
# Side effects:
#       None
#
########################################################################

sub new {
    my ($proto) = @_;

    # Below way of getting class name is to allow new class as well as
    # $class->new.  In new class, proto itself is class, and $class->new,
    # ref($class) return the class
    my $class = ref($proto) || $proto;
    my $self = $class->SUPER::new( \%SRIOVNext );
    return ( bless( $self, $class ) );
}

1;

