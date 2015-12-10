#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::FPT::SRIOVNextBe2NetTds;

#
# This file contains the structured hash for category, SRIOV.Next tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   %SRIOVNextBe2Net = (
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
                           ports => "2",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
                           },
                        },
                        '[2]' => {
                           driver => "be2net",
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
               Sequence => [['PoweronVM'],['SetPGUplink1'],['SetPGUplink2'],
                            ['Traffic_VM'],['SetVST'],['Traffic_VM'],
                            ['SetVGT'],['SetTrunk'],['Traffic_VM'],],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
                           },
                        },
                        '[2]' => {
                           driver => "be2net",
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
               Sequence => [['PoweronVM'],['SetPGUplink1'],['SetPGUplink2'],
                            ['Traffic_VM'],['SetVST'],['Traffic_VM'],
                            ['SetVGT'],['SetTrunk'],['Traffic_VM'],],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
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
               "SetVGT" => {
                  Type          => "NetAdapter",
                  TestAdapter   => "vm.[1].pcipassthru.[1],vm.[2].vnic.[1]," .
                                   "vm.[3].vnic.[1]",
                  vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
               },
               "SetTrunk" => {
                  Type          => "PortGroup",
                  TestPortgroup => "host.[1].portgroup.[1-2]",
                  vlan          => "4095",
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
                           ports => "2",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronVM'],['Traffic_VM'],],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronVM'],['Traffic_VM'],],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[1-2].vnic.[1]",
                  TestDuration   => "20",
               },
            },
      },

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
                        '[1-2]' => {
                           vds   => "vc.[1].vds.[1]",
                           ports => "2",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
                        '[1]'   => {
                           vmnic     => "host.[1].vmnic.[2]",
                           driver    => "sriov",
                           portgroup => "vc.[1].dvportgroup.[1]",
                        },
                        '[2]'   => {
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "vc.[1].dvportgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['pingTraffic1'],['pingTraffic2'],
                            ['SetVLAN1'],['SetVLAN2'],['pingTraffic1'],
                            ['pingTrafficNeg']],
               IgnoreFailure => "1",
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
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
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[2]",
               },
               "pingTrafficNeg" => {# sriov nic in different vlan
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[2]",
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
                  TestPortgroup => "vc.[1].dvportgroup.[2]",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronVM'],['Traffic_VM'],['SetMAC'],
                            ['Traffic_VM']],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1],",
                  TestDuration   => "20",
               },
               "SetMAC" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1]",
                  setmacaddr  => "00:50:56:33:44:51",
               },
            },
      },

      'BootOptions' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "BootOptions",
            Version   => "2",
            Tags      => "MN.Next,reboot",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronVM'],['Traffic_VM'],['RebootHost'],
                            ['PoweronAllVM'],['Traffic_VM']],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "PoweronAllVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
                           },
                        },
                        '[2]' => {
                           driver => "be2net",
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
               Sequence => [['PoweronVM'],['Traffic_VM'],['RebootVM'],
                            ['Traffic_VM'],],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].vnic.[1]",
                  TestDuration   => "20",
               },
               "RebootVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweroff,poweron",
               },
            },
      },

      'EnableDisableSRIOV' => {
          Component => "Infrastructure",
          Category  => "vdnet",
          TestName  => "EnableDisableSRIOV",
          Version   => "2",
          Tags      => "MN.Next",
          Summary   => "Enable/Disable SR-IOV with different max_vfs",
          TestbedSpec   => {
              host => {
                  '[1]' => {
                      vmnic => {
                          '[1-2]' => {
                              driver      => "be2net",
                          },
                      },
                  },
              },
          },

          WORKLOADS => {
             Sequence => [['ValidMaxVfs1'], ['ValidMaxVfs2'],['ValidMaxVfs3'],
                          ['InvalidMaxVfs1'], ['DisableSRIOV'],],
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
                maxvfs   => "16",
             },
             InvalidMaxVfs1 => {
                Type     => "Host",
                TestHost => "host.[1]",
                sriov    => "enable",
                vmnicadapter   => "host.[1].vmnic.[1];;host.[1].vmnic.[2]",
                maxvfs   => "-1",
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
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1-2]' => {
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
                        '[2]' => {
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
               Sequence => [['PoweronVM'],['Traffic_VM'],
                            ['Traffic_Multicast'],['Traffic_Broadcast'],],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
                  TestAdapter    => "vm.[1].pcipassthru.[1-2]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
                  TestDuration   => "20",
               },
               "Traffic_Multicast" => {
                  Type           => "Traffic",
                  RoutingScheme  => "Multicast",
                  TestAdapter    => "vm.[1].pcipassthru.[1-2]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
               },
               "Traffic_Broadcast" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  SleepBetweenCombos => "20",
                  NoofInbound    => "2",
                  RoutingScheme  => "broadcast,flood",
                  NoofOutbound   => "2",
                  TestAdapter    => "vm.[1].pcipassthru.[1-2]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
               },
            },
      },

      'VMKToVF' => {
            Component => "Networking",
            Category  => "Passthrough",
            TestName  => "VMKToVF",
            Version   => "2",
            Tags      => "MN.Next",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronVM'],['Traffic_VMK'],],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "Traffic_VMK" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronAllVM'],['Traffic_VM'],
                            ['DisableEnableVnic'], ['Traffic_VM'],
                            ['RebootVM'],['Traffic_VM'],['KillVM'],
                            ['PoweronVM'],['Traffic_VM'],],
               "IgnoreFailure" => "1",
               "PoweronAllVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
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
                           ports => "2",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronVM'],['pingTraffic'],['DisablePort'],
                            ['pingTrafficNeg'],['EnablePort'],['pingTraffic']],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronVM'],['Traffic_VM'],['SuspendVM'],
                            ['CreateSnapshot'],['Traffic_VM']],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
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
                           vmnicadapter     => "host.[1].vmnic.[1]",
                           configureuplinks => "add",
                        },
                     },
                     portgroup => {
                        '[1-2]' => {
                           vss  => "host.[1].vss.[1]",
                        },
                     },
                     vmnic => {
                        '[1]' => {
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
                           vmnic     => "host.[1].vmnic.[1]",
                           driver    => "sriov",
                           portgroup => "host.[1].portgroup.[2]",
                        },
                     },
                  },
               },
            },

            WORKLOADS => {
               Sequence => [['PoweronVM'],['pingTraffic'],['SetVLANPG'],
                            ['SetVnicVlan1'],['pingTrafficNeg'],
                            ['SetVnicVlan2'],['pingTraffic'],
                            ['RestoreVLAN'],['pingTraffic']],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1],vm.[2]",
                  vmstate => "poweron",
               },
               "SetVLANPG" => {
                  Type          => "PortGroup",
                  TestPortgroup => "host.[1].portgroup.[1-2]",
                  vlan          => "4095",
               },
               "SetVnicVlan1" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1]",
                  VLAN        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
               },
               "SetVnicVlan2" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[2].pcipassthru.[1]",
                  VLAN        => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
               },
               "RestoreVLAN" => {
                  Type        => "NetAdapter",
                  TestAdapter => "vm.[1].pcipassthru.[1],vm.[2].pcipassthru.[1]",
                  VLAN        => "0",
               },
               "pingTraffic" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
                  SupportAdapter => "vm.[2].pcipassthru.[1]",
               },
               "pingTrafficNeg" => {
                  Type           => "Traffic",
                  ToolName       => "ping",
                  TestAdapter    => "vm.[1].pcipassthru.[1]",
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronVM'],['pingTraffic'],['PoweroffVM'],
                            ['EnableStress'],['PoweronVMNeg'],['DisableStress'],
                            ['PoweronVM'],['pingTraffic']],
               "PoweronVM" => {
                  Type          => "VM",
                  TestVM        => "vm.[1]",
                  vmstate       => "poweron",
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
                  },
               },
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
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
                           },
                        },
                     },
                  },
                  '[2]' => {
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
                           driver => "be2net",
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
                           portgroup => "host.[1].portgroup.[2]",
                        },
                     },
                  },
                  '[2]' => {
                     host => "host.[2]",
                     datastoreType => 'shared',
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
               Sequence => [['PoweronVM'],['EnableVmotion1'],['EnableVmotion2'],
                            ['Traffic_VM'],['VmotionNeg'],
                            ['VmotionPos', 'pingTraffic'],['Traffic_VM']],
               "VMPreConfig" => {
                  Type      => "VM",
                  TestVM    => "vm.[1],vm.[2]",
                  operation => 'configurevmotion'
               },
               "EnableVmotion1" => {
                  Type             => "NetAdapter",
                  TestAdapter      => "host.[1].vmknic.[1]",
                  configurevmotion => "ENABLE",
                  ipv4             => "192.168.100.1",
               },
               "EnableVmotion2" => {
                  Type             => "NetAdapter",
                  TestAdapter      => "host.[2].vmknic.[1]",
                  configurevmotion => "ENABLE",
                  ipv4             => "192.168.100.2",
               },
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
               },
               "Traffic_VM" => {
                  Type           => "Traffic",
                  ToolName       => "netperf",
                  L3Protocol     => "ipv4,ipv6",
                  L4Protocol     => "tcp,udp",
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
                           ports => "2",
                        },
                     },
                  },
               },
               host => {
                  '[1]' => {
                     vmnic => {
                        '[1]' => {
                           driver => "be2net",
                           passthrough => {
                              type   => "sriov",
                              maxvfs => "16",
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
               Sequence => [['PoweronVM'],['pingTraffic'],['BlockPG'],
                            ['pingTrafficNeg'],['UnblockPG'],['pingTraffic']],
               "PoweronVM" => {
                  Type    => "VM",
                  TestVM  => "vm.[1]",
                  vmstate => "poweron",
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
    my $self = $class->SUPER::new( \%SRIOVNextBe2Net );
    return ( bless( $self, $class ) );
}

1;

