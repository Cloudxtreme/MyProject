########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDS::MultiLAGTds;


use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use VDNetLib::TestData::TestConstants;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   @TESTS = ("AddHosts","MultiLAG","MultiVDS","HybridUplinks","VmknicInDVPG",
             "EditMultipleLAGs","RecreateVDS","LB_SrcDstIP_TCPPort_VLAN",
             "LB_SrcMac","LB_DstMac","LB_SrcDstMac","LB_DstIP_VLAN",
             "LB_SrcIP_VLAN","LB_SrcDstIP_VLAN","LB_DstTCPPort","LB_SrcTCPPort",
             "LB_SrcDstTCPPort","LB_DstIP_TCPPort","LB_SrcIP_TCPPort",
             "LB_SrcDstIP_TCPPort","LB_DstIP_TCPPort_VLAN",
             "LB_SrcIP_TCPPort_VLAN","LB_DstIP","LB_SrcIP","LB_SrcDstIP",
             "LB_VLAN","LB_SrcPortID","VDSMTU","VLAN","LACPVmotion",
             "ActivePassiveCombinations","ActivePassiveFlipTraffic",
             "PeerSwitchDisableShut","TrafficAddRemoveUplinks",
             "StatefullLACP","BasicLACPESXCLI","MaxLAGs","MaxPortsInLAGs",
             "TeamingLayerConfigWarnings","NonLACPpSwtich",
             "TwoLAGDifferentPortChannel","EsxcliStats","FallBackTeaming",
             "ActivePassiveModeStress","LongDurationLAG",
             "UplinkJoinLeaveStress","VDSUpgrade","VDSAndLACPUpgrade",
             "LAGUpDownVOB","PNICConfiguration","LACPImportExportVDSConfig",
             "HealthCheck","MaxStandbyUplinks","KillLACP","FalseUplinkJoinLAG",
             "LagPortFailback");

   %MultiLAG = (
      'AddHosts' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "AddHosts",
         Priority          => 'P0',
         Tags              => "CAT_P0",
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if host can be added before or after lag
                               creation",
         ExpectedResult    => "PASS",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
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
                        ports  => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["SetActiveUplink"],["AddUplinkToLag_1"],
                             ["AddHost"],["AddUplinkToLag_2"],
                             ["RemoveUplink"],[SetActiveUplink_2],
                             ["DeleteLAG"],],
            Duration     => "time in seconds",
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "AddUplinkToLag_1" => {
               Type         => "LACP",
               TestLag      => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter => "host.[1].vmnic.[1-2]",
            },
            "AddHost" => {
               Type         => "Switch",
               TestSwitch   => "vc.[1].vds.[1]",
               configurehosts => "add",
               host         => "host.[2]",
            },
            "AddUplinkToLag_2" => {
               Type         => "LACP",
               TestLag      => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter => "host.[2].vmnic.[1-2]",
            },
            "RemoveUplink"  => {
               Type         => "LACP",
               TestLag      => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag   => "remove",
               vmnicadapter => "host.[-1].vmnic.[-1]",
            },
            "SetActiveUplink_2" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "uplink[1-4]",
               failovertype  => "active",
            },
            "DeleteLAG" => {
               Type         => "Switch",
               TestSwitch   => "vc.[1].vds.[1]",
               DeleteLag    => "vc.[1].vds.[1].lag.[1]",
            },
         },
      },

      'MultiLAG' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "MultiLAG",
         Priority          => 'P0',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if multiple lags can work well together",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1-2]' => {
                              lagtimeout => "short",
                              hosts => "host.[1-2]",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
               '[2]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["SetActiveUplink_1"],["SetActiveUplink_2"],
                             ["AddUplinkToLag_1"],["AddUplinkToLag_2"],
                             ["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],
                             ["CheckUplinkState_1"],["CheckUplinkState_2"],
                             ["NetAdapter_DHCP"],
                             ["Traffic"],["DisablePorts"],["Traffic"],],
            ExitSequence => [["EnablePorts"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink_1"],["RemoveUplink_2"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "SetActiveUplink_1" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "SetActiveUplink_2" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[2]",
               failoverorder => "vc.[1].vds.[1].lag.[2]",
               failovertype  => "active",
            },
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "AddUplinkToLag_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag   => "add",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "DisablePorts" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "EnablePorts" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink_1"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "RemoveUplink_2"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'MultiVDS' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "MultiVDS",
         Priority          => 'P0',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if multiple VDSes can work well together",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              'lagname' => 'lag-test',
                           },
                        },
                     },
                     '[2]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              'lagname' => 'lag-test',
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
               '[2]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["SetActiveUplink_1"],["SetActiveUplink_2"],
                             ["AddUplinkToLag_1"],["AddUplinkToLag_2"],
                             ["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],
                             ["CheckUplinkState_1"],["CheckUplinkState_2"],
                             ["NetAdapter_DHCP"],
                             ["Traffic"],["DisablePorts"],["Traffic"],],
            ExitSequence => [["EnablePorts"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink_1"],["RemoveUplink_2"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "SetActiveUplink_1" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "SetActiveUplink_2" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[2]",
               failoverorder => "vc.[1].vds.[2].lag.[1]",
               failovertype  => "active",
            },
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "AddUplinkToLag_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "DisablePorts" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "EnablePorts" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "RemoveUplink_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'HybridUplinks' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "HybridUplinks",
         Priority          => 'P0',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if lag and dvuplink can work well together",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        host  => "host.[1-2]",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[3]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddLAG"],["AddUplinkToLag"],
                             ["ConfigureChannelGroup"],["SetActiveUplink"],
                             ["CheckUplinkState"],["NetAdapter_DHCP"],
                             ["Traffic_1"],["Traffic_2"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"],],
            Duration     => "time in seconds",
            "AddLAG" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               lag => {
                  '[1]' => {
                     lagtimeout => "short",
                     hosts      => "host.[1]",
                  },
               },
            },
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[2-3]",
            },
            "ConfigureChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "SetActiveUplink"  => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               failoverorder   => "vc.[1].vds.[1].lag.[1]",
               failovertype    => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[2-3]",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            },
            "RemoveUplink" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[2-3]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic_1" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
            },
            "Traffic_2" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'VmknicInDVPG' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "VmknicInDVPG",
         Priority          => 'P0',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if vmknics can work well with LAG",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1-2]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
               '[2]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddVmk1"],["AddVmk2"],["AddUplinkToLag_1"],
                             ["AddUplinkToLag_2"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink_1"],
                             ["SetActiveUplink_2"],["CheckUplinkState_1"],
                             ["CheckUplinkState_2"],["Traffic"],
                             ["DisablePorts"],["Traffic"],],
            ExitSequence => [["EnablePorts"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink_1"],["RemoveUplink_2"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            'AddVmk1' => {
               Type            => "Host",
               TestHost        => "host.[1]",
               vmknic          => {
                  "[1]" => {
                     portgroup => "vc.[1].dvportgroup.[1]",
                     ipv4      => "auto",
                  },
               },
            },
            'AddVmk2' => {
               Type            => "Host",
               TestHost        => "host.[2]",
               vmknic          => {
                  "[1]" => {
                     portgroup => "vc.[1].dvportgroup.[2]",
                     ipv4      => "auto",
                  },
               },
            },
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "AddUplinkToLag_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink_1" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               failoverorder   => "vc.[1].vds.[1].lag.[1]",
               failovertype    => "active",
            },
            "SetActiveUplink_2" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[2]",
               failoverorder   => "vc.[1].vds.[1].lag.[2]",
               failovertype    => "active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate   => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               checkuplinkstate   => "Bundled",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "DisablePorts" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "EnablePorts" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "RemoveUplink_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "Iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "host.[1].vmknic.[1]",
               SupportAdapter  => "host.[2].vmknic.[1]",
               TestDuration    => "10",
               Verification    => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[1].vmknic.[1]",
                  pktcount           => "300+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },

      'EditMultipleLAGs' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "EditMultipleLAGs",
         Priority          => 'P0',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if we can create/edit/delete multiple LAGs",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
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
                              lagname    => "lag-1",
                              lagmode    => "active",
                              lagports   => "10",
                              lagloadbalancing => "srcMac",
                              lagtimeout => "long",
                              hosts      => "host.[1]",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag_1"],["ConfigureChannelGroup"],
                             ["SetActiveUplink_1"],["CheckUplinkState_1"],
                             ["AddLAG"],["RemoveUplink_1"],["AddUplinkToLag_2"],
                             ["SetActiveUplink_2"],["CheckUplinkState_2"],
                             ["EditLAG_1"],["EditLAG_2"],
                             ["DeleteLAG"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink_2"],["DeleteChannelGroup"],],
            Duration     => "time in seconds",
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "ConfigureChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "SetActiveUplink_1" => {
               Type         => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               failoverorder   => "vc.[1].vds.[1].lag.[1]",
               failovertype    => "active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "AddLAG" => {
               Type         => "Switch",
               TestSwitch   => "vc.[1].vds.[1]",
               'lag' => {
                  '[2]' => {
                     lagname    => "lag-2",
                     lagmode    => "passive",
                     lagports   => "15",
                     lagloadbalancing => "destMac",
                     lagtimeout => "short",
                     hosts      => "host.[1]",
                  },
               },
            },
            "AddUplinkToLag_2" => {
               Type         => "LACP",
               TestLag      => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag   => "add",
               vmnicadapter => "host.[1].vmnic.[-1]",
            },
            "SetActiveUplink_2" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[2]",
               failovertype  => "active",
            },
            "EditLAG_1" => {
               Type         => "LACP",
               TestLag      => "vc.[1].vds.[1].lag.[1]",
               lagoperation => "edit",
               lagname      => "lag-3",
               lagmode      => "passive",
               lagports     => "5",
               lagloadbalancing => "srcIpTcpUdpPortVlan",
               lagtimeout   => "short",
               hosts        => "host.[1]",
            },
            "EditLAG_2" => {
               Type         => "LACP",
               TestLag      => "vc.[1].vds.[1].lag.[2]",
               lagoperation => "edit",
               lagmode      => "active",
               lagports     => "10",
               lagloadbalancing => "srcPortId",
               lagtimeout   => "long",
               hosts        => "host.[1]",
            },
            "DeleteLAG" => {
               Type         => "Switch",
               TestSwitch   => "vc.[1].vds.[1]",
               DeleteLag    => "vc.[1].vds.[1].lag.[1]",
            },
            "RemoveUplink_1"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "RemoveUplink_2"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            },
         },
      },

      'RecreateVDS' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "RecreateVDS",
         Priority          => 'P0',
         Tags              => "CAT_P0,physicalonly",
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if LAG properties can be cleared after".
                              "deleting VDS",
         ExpectedResult    => "PASS",
         AutomationStatus  => "Automated",
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
                        name       => "vds-test",
                        configurehosts => "add",
                        host  => "host.[1]",
                        'lag' => {
                           '[1]' => {
                              lagname => "lag-test",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]' => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                        name    => "dvpg-test",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup"],
                             ["SetActiveUplink"],["CheckUplinkState_1"],
                             ["RemoveHostFromVDS"],
                             ["DeleteVDS"],["ReCreateVDS"],
                             ["CheckExistingLAG_1"],["RecreatLAG"],
                             ["CheckExistingLAG_2"],["CheckUplinkState_2"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"],],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "ConfigureChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               failoverorder   => "vc.[1].vds.[1].lag.[1]",
               failovertype    => "active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "RemoveHostFromVDS" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               configurehosts  => "remove",
               host            => "host.[1]",
            },
            "DeleteVDS" => {
               Type            => "VC",
               TestVC          => "vc.[1]",
               deletevds       => "vc.[1].vds.[1]",
            },
            "ReCreateVDS" => {
               Type            => "VC",
               TestVC          => "vc.[1]",
               vds             => {
                  '[1]'        => {
                     datacenter => "vc.[1].datacenter.[1]",
                     name       => "vds-test",
                     configurehosts => "add",
                     host      => "host.[1]",
                  },
               },
            },
            "CheckExistingLAG_1" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get",
               expectedString  => "No running LACP group on the host",
            },
            "RecreatLAG" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               'lag' => {
                  '[1]' => {
                     lagname   => "lag-test",
                  },
               },
            },
            "CheckExistingLAG_2" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get",
               expectedString  => "LAGID",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
               expectedresult  => "FAIL",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type            => "Switch",
               TestSwitch      => "pswitch.[-1]",
               removeportchannel =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
         },
      },

      'LB_SrcDstIP_TCPPort_VLAN' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcDstIP_TCPPort_VLAN",
         Priority          => 'P0',
         Tags              => "CAT_P0,physicalonly",
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src and dst ip,".
                              "TCP/UDP port and VLAN'",
         ExpectedResult    => "PASS",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcDestIpTcpUdpPortVlan",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "destIp",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcMac' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcMac",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src mac'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcMac",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "destMac",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_DstMac' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_DstMac",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'dst mac'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "destMac",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcDestMac",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcDstMac' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcDstMac",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src and dst mac'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcDestMac",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1-2].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "destIpVlan",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_DstIP_VLAN' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_DstIP_VLAN",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'dst ip, vlan'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "destIpVlan",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcIpVlan",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcIP_VLAN' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcIP_VLAN",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src ip, vlan'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcIpVlan",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1-2].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcDestIpVlan",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcDstIP_VLAN' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcDstIP_VLAN",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src and dst ip,".
                              "vlan",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcDestIpVlan",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "destTcpUdpPort",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_DstTCPPort' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_DstTCPPort",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'dst tcp/udp port'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "destTcpUdpPort",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcTcpUdpPort",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcTCPPort' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcTCPPort",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src tcp/udp port",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcTcpUdpPort",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcDestTcpUdpPort",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcDstTCPPort' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcDstTCPPort",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src and dst".
                              "tcp/udp port'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcDestTcpUdpPort",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "destIpTcpUdpPort",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification    => "Verification_1",
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

      'LB_DstIP_TCPPort' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_DstIP_TCPPort",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'dst ip, tcp/udp".
                              "port'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "destIpTcpUdpPort",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcIpTcpUdpPort",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcIP_TCPPort' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcIP_TCPPort",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src ip, tcp/udp".
                              "port'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcIpTcpUdpPort",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcDestIpTcpUdpPort",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcDstIP_TCPPort' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcDstIP_TCPPort",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src and dst ip,".
                              "tcp/udp port",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcDestIpTcpUdpPort",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "destIpTcpUdpPortVlan",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_DstIP_TCPPort_VLAN' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_DstIP_TCPPort_VLAN",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'dst ip, tcp/udp".
                              "port, vlan'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "destIpTcpUdpPortVlan",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcIpTcpUdpPortVlan",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcIP_TCPPort_VLAN' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcIP_TCPPort_VLAN",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src ip, tcp/udp".
                              "port, vlan'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcIpTcpUdpPortVlan",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcDestIpTcpUdpPortVlan",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_DstIP' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_DstIP",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'dst ip'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "destIp",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcIp",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcIP' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcIP",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src ip'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcIp",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcDestIp",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcDstIP' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcDstIP",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src and dst ip",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcDestIp",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcPortId",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_VLAN' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_VLAN",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'vlan'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "vlan",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcPortId",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LB_SrcPortID' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LB_SrcPortID",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAG loadbalancing policy 'src port id'",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing  => "srcPortId",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeLBPolicy","Traffic"],
                             ["DisablePorts_1"],["Traffic"],
                             ["DisablePorts_2"],["Traffic"],],
            ExitSequence => [["EnablePorts_1"],["EnablePorts_2"],
                             ["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLBPolicy" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagloadbalancing => "srcMac",
            },
            "DisablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "DisablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "disable",
            },
            "EnablePorts_1" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "EnablePorts_2" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[2]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'VDSMTU' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "VDSMTU",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if lag works fine with different VDS MTU",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ChangeMTU_1"],["Traffic"],["CheckUplinkState"],
                             ["ChangeMTU_2"],["Traffic"],["CheckUplinkState"]],
            ExitSequence => [["RestoreMTU"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeMTU_1" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               mtu             => "1280",
            },
            "ChangeMTU_2" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               mtu             => "9000",
            },
            "RestoreMTU" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               mtu             => "1500",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'VLAN' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "VLAN",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if lag works fine with VLAN VST & VGT",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                        vlantype => "access",
                        vlan    => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                        vlantype => "trunk",
                        vlan    => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["SetVGT"],["CheckUplinkState"],
                             ["NetAdapter_Auto"],["Traffic_1"],
                             ["DisablePort"],["Traffic_1"],
                             ["ChangeVST"],["Traffic_2"]],
            ExitSequence => [["EnablePort"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[-1]",
               failoverorder   => "vc.[1].vds.[1].lag.[1]",
               failovertype    => "active",
            },
            "SetVGT" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[2].vnic.[1]",
		     vlaninterface   => {
		        '[1]' => {
		          vlanid     => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
		        },
		     },
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "DisablePort" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "ChangeVST" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               vlantype        => "access",
               vlan            => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
            },
            "EnablePort" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
		  "NetAdapter_Auto" => {
		     Type            => "NetAdapter",
		     TestAdapter     => "vm.[1].vnic.[1],vm.[2].vnic.[1].vlaninterface.[1]",
		     ipv4            => "auto",
		  },
            "Traffic_1" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1].vlaninterface.[1]",
               TestDuration    => "10",
               Verification    => "Verification_1",
            },
            "Traffic_2" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1].vlaninterface.[1]",
               TestDuration    => "10",
               expectedresult  => "FAIL",
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

      'LACPVmotion' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LACPVmotion",
         Priority          => 'P1',
         Tags              => "BAT",
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if lag works fine with vmotion",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "4",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
                  vmknic          => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        configurevmotion => "enable",
                        ipv4      => "auto",
                     },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                     '[1]'     => {
                        vmnic => "host.[2].vmnic.[1]",
                     },
                     '[2]'     => {
                        vmnic => "host.[2].vmnic.[2]",
                     },
                     '[3]'     => {
                        vmnic => "host.[2].vmnic.[3]",
                     },
                  },
                  vmknic          => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        configurevmotion => "enable",
                        ipv4      => "auto",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
                  datastoreType    => "shared",
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
                  datastoreType    => "shared",
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],["NetAdapter_DHCP"],
                             ["Traffic","VMotion_1","VMotion_2","DisableEnablePort","EditLAG"]],
            ExitSequence => [["EnablePort"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "VMotion_1" => {
               Type            => "VM",
               TestVM          => "vm.[1]",
               Iterations      => "5",
               vmotion         => "roundtrip",
               dsthost         => "host.[2]",
            },
            "VMotion_2" => {
               Type            => "VM",
               TestVM          => "vm.[2]",
               Iterations      => "7",
               vmotion         => "roundtrip",
               dsthost         => "host.[1]",
            },
            "DisableEnablePort" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               Iterations      => "5",
               portstatus      => "disable,enable",
            },
            "EditLAG" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagmode         => "active",
               lagports        => "10",
               lagloadbalancing => "srcDestIpTcpUdpPort",
               lagtimeout      => "short",
               hosts           => "host.[1]",
            },
            "EnablePort" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "30",
               Verification    => "Verification_1",
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

      'ActivePassiveCombinations' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "ActivePassiveCombinations",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test lag mode combinations",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagmode => "active",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],["NetAdapter_DHCP"],
                             ["Traffic_1","ChangeChannelGroupMode_1"],
                             ["ChangeLAGMode_1"],["Traffic_2"],
                             ["ChangeChannelGroupMode_2"],["Traffic_1"],
                             ["Traffic_1","ChangeLAGMode_2"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLAGMode_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagmode         => "passive",
            },
            "ChangeLAGMode_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagmode         => "active",
            },
            "ChangeChannelGroupMode_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "passive",
            },
            "ChangeChannelGroupMode_2" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "active",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic_1" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
            },
            "Traffic_2" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               expectedresult  => "FAIL",
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

      'ActivePassiveFlipTraffic' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "ActivePassiveFlipTraffic",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test lag mode switching while traffic is running",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagmode => "active",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],["NetAdapter_DHCP"],
                             ["Traffic","ChangeLAGMode"],["CheckUplinkState"],
                             ["Traffic","ChangeChannelGroupMode"],
                             ["CheckUplinkState"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLAGMode" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               Iterations      => "5",
               lagoperation    => "edit",
               lagmode         => "passive,active",
            },
            "ChangeChannelGroupMode" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               Iterations      => "5",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "passive,active",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "30",
               Verification   => "Verification_1",
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

      'PeerSwitchDisableShut' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "PeerSwitchDisableShut",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if LACP works well when pswitch port get".
                              "disabled or removed from channel group",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        lag => {
                           '[1]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],["NetAdapter_DHCP"],
                             ["Traffic","DisableEnablePort","RemoveAddPort","EditLAG"]],
            ExitSequence => [["EnablePort"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
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
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "DisableEnablePort" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1-2]",
               Iterations      => "5",
               portstatus      => "disable,enable",
            },
            "RemoveAddPort" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[1-2]",
               Iterations      => "5",
               configurechannelgroup => "no,".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "EditLAG" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagmode         => "active",
               lagports        => "10",
               lagloadbalancing => "srcDestIpTcpUdpPort",
               lagtimeout      => "short",
               hosts           => "host.[-1]",
            },
            "EnablePort" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "30",
               Verification   => "Verification_1",
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

      'TrafficAddRemoveUplinks' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "TrafficAddRemoveUplinks",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if LACP works well when vmnic get".
                              "added or removed from lag",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        lag => {
                           '[1-2]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
                  vmknic          => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
                  vmknic          => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag_1"],["AddUplinkToLag_2"],
                             ["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],
                             ["SetActiveUplink_1"],["SetActiveUplink_2"],
                             ["CheckUplinkState_1"],["CheckUplinkState_2"],
                             ["NetAdapter_DHCP"],
                             ["Traffic_1","RemoveAddUplink_1"],
                             ["Traffic_2","RemoveAddUplink_2"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink_1"],["RemoveUplink_2"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "AddUplinkToLag_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink_1" => {
               Type          => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "SetActiveUplink_2" => {
               Type          => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[2]",
               failoverorder => "vc.[1].vds.[1].lag.[2]",
               failovertype  => "active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "RemoveAddUplink_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               Iterations      => "5",
               configuplinktolag => "remove,add",
               vmnicadapter    => "host.[1].vmnic.[1-2]",
            },
            "RemoveAddUplink_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               Iterations      => "5",
               configuplinktolag => "remove,add",
               vmnicadapter    => "host.[2].vmnic.[1-2]",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "RemoveUplink_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[2].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic_1" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "30",
               Verification   => "Verification_1",
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
            "Traffic_2" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "host.[1].vmknic.[1]",
               SupportAdapter  => "host.[2].vmknic.[1]",
               TestDuration    => "30",
               Verification    => "Verification_2",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[1].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },

      'StatefullLACP' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "StatefullLACP",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if LACP state is pushed after host reboot",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly,hostreboot",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        lag => {
                           '[1]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState"],["RebootHost"],["PoweronVM"],
                             ["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["Traffic","DisablePort","EditLAG"]],
            ExitSequence => [["EnablePort"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
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
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               sleepbetweenretry => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               noofretries  => "3",
            },
            "RebootHost" => {
               Type            => "Host",
               TestHost        => "host.[-1]",
               reboot          => "yes",
            },
            "PoweronVM" => {
               Type            => "VM",
               TestVM          => "vm.[-1]",
               vmstate         => "poweron",
            },
            "DisablePort" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "disable",
            },
            "EditLAG" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagmode         => "active",
               lagports        => "10",
               lagloadbalancing => "srcDestIpTcpUdpPort",
               lagtimeout      => "short",
               hosts           => "host.[-1]",
            },
            "EnablePort" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[1]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'BasicLACPESXCLI' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "BasicLACPESXCLI",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LACP related esxcli commands",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
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
                        name => "vds-test",
                        host  => "host.[1]",
                        'lag' => {
                           '[1]' => {
                              lagname => "lag-test",
                              lagmode => "active",
                              lagloadbalancing => "srcDestMac",
                           },
                        },
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup"],
                             ["NameSpace_1"],["NameSpace_2"],
                             ["Config_1"],["Config_2"],["Config_3"],
                             ["Stats_1"],["Stats_2"],["Stats_3"],
                             ["Status_1"],["Status_2"],["Status_3"],
                             ["Timeout_1"],["Timeout_2"],["Timeout_3"],
                             ["Timeout_4"],["Timeout_5"],["Timeout_6"],
                             ["SetShortTimeout"],["CheckShortTimeout"],
                             ["SetLongTimeout"],["CheckLongTimeout"],
                             ["CheckUplinkState"],],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"],],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "ConfigureChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "NameSpace_1" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp",
               expectedString  => "Available Namespaces:\\s+config.*stats.*status.*timeout",
            },
            "NameSpace_2" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp set",
               expectedString  => "Error: Unknown command or namespace",
            },
            "Config_1" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp config",
               expectedString  => "Available Commands:\\s+get",
            },
            "Config_2" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp config get",
               expectedString  => "vds-test\\s+lag-test\\s+[0-9]+.*Active.*Src and dst mac",
            },
            "Config_3" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp config set",
               expectedString  => "Error: Unknown command or namespace",
            },
            "Stats_1" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp stats",
               expectedString  => "Available Commands:\\s+get",
            },
            "Stats_2" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp stats get",
               expectedString  => "vds-test\\s+[0-9]+\\s+vmnic",
            },
            "Stats_3" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp stats set",
               expectedString  => "Error: Unknown command or namespace",
            },
            "Status_1" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status",
               expectedString  => "Available Commands:\\s+get",
            },
            "Status_2" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get",
               expectedString  => "DVSwitch: vds-test.*Mode: Active\\s+Nic List",
            },
            "Status_3" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status set",
               expectedString  => "Error: Unknown command or namespace",
            },
            "Timeout_1" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp timeout",
               expectedString  => "Available Commands:\\s+set",
            },
            "Timeout_2" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp timeout set",
               expectedString  => "Error: Missing required parameter.*Cmd options:",
            },
            "Timeout_3" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp timeout set -t -1",
               expectedString  => "Argument type mismatch",
            },
            "Timeout_4" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp timeout set -t 1 -s vds -l -1",
               expectedString  => "No such .*Switch: vds",
            },
            "Timeout_5" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp timeout set -t 1 -s vds-test -l -1",
               expectedString  => "Not found",
            },
            "Timeout_6" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp timeout get",
               expectedString  => "Error: Unknown command or namespace",
            },
            "SetShortTimeout" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagtimeout      => "short",
               hosts           => "host.[1]",
            },
            "CheckShortTimeout" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get",
               expectedString  => "Flags: FA",
            },
            "SetLongTimeout" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagtimeout      => "long",
               hosts           => "host.[1]",
            },
            "CheckLongTimeout" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp status get",
               expectedString  => "Flags: SA",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type            => "Switch",
               TestSwitch      => "pswitch.[-1]",
               removeportchannel =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
         },
      },

      'MaxLAGs' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "MaxLAGs",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if the max number of lags on a vds is 64",
         ExpectedResult    => "PASS",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddLag_1"],["AddLag_2"],],
            Duration     => "time in seconds",
            "AddLag_1" => {
               Type          => "Switch",
               TestSwitch    => "vc.[1].vds.[1]",
               'lag' => {
                  '[1-64]'   => {
                  },
               },
            },
            "AddLag_2" => {
               Type          => "Switch",
               TestSwitch    => "vc.[1].vds.[1]",
               'lag' => {
                  '[65]'     => {
                  },
               },
               expectedresult => "FAIL",
            },
         },
      },

      'MaxPortsInLAGs' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "MaxPortsInLAGs",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test the limit of ports in a LAG on a VDS",
         ExpectedResult    => "PASS",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]'   => {
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddLag_1"],["AddLag_2"],],
            Duration     => "time in seconds",
            "AddLag_1" => {
               Type          => "Switch",
               TestSwitch    => "vc.[1].vds.[1]",
               'lag' => {
                  '[1]'    => {
                     lagports => "32",
                  },
               },
            },
            "AddLag_2" => {
               Type          => "Switch",
               TestSwitch    => "vc.[1].vds.[1]",
               'lag' => {
                  '[2]'      => {
                     lagports => "33",
                  },
               },
               expectedresult => "FAIL",
            },
         },
      },

      'TeamingLayerConfigWarnings' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "TeamingLayerConfigWarnings",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if only one lag can be set as active uplink".
                              "Others should be put in unused uplinks",
         ExpectedResult    => "PASS",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        lag => {
                           '[1-2]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]' => {
                        vds    => "vc.[1].vds.[1]",
                        ports  => "2",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["SetActiveUplink_1"],[SetActiveUplink_2],
                             ["SetActiveUplink_3"],[SetActiveUplink_4],
                             ["SetActiveUplink_5"]],
            Duration     => "time in seconds",
            "SetActiveUplink_1" => {
               Type          => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "uplink[1];;vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
               expectedresult => "FAIL",
            },
            "SetActiveUplink_2" => {
               Type          => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[1-2]",
               failovertype  => "active",
               expectedresult => "FAIL",
            },
            "SetActiveUplink_3" => {
               Type          => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "SetActiveUplink_4" => {
               Type          => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "uplink[1]",
               failovertype  => "standby",
               expectedresult => "FAIL",
            },
            "SetActiveUplink_5" => {
               Type          => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[2]",
               failovertype  => "standby",
               expectedresult => "FAIL",
            },
         },
      },

      'NonLACPpSwtich' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "NonLACPpSwtich",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test negative cases when Pswitch ports are not ".
                              "in channel-group or LACP mode",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["SetActiveUplink"],
                             ["NetAdapter_DHCP"],
                             ["CheckUplinkState_1"],["Traffic"],
                             ["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],
                             ["CheckUplinkState_1"],["Traffic"],
                             ["ConfigureChannelGroup_3"],
                             ["CheckUplinkState_1"],["Traffic"],
                             ["RemovePortsFromChannelGroup"],
                             ["ConfigureChannelGroup_4"],
                             ["ConfigureChannelGroup_5"],
                             ["CheckUplinkState_2"],["Traffic"],],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Stand-alone",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "auto",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "desirable",
            },
            "ConfigureChannelGroup_3" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "on",
            },
            "ConfigureChannelGroup_4" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "active",
            },
            "ConfigureChannelGroup_5" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "active",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "5",
               Verification   => "Verification_1",
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

      'TwoLAGDifferentPortChannel' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "TwoLAGDifferentPortChannel",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if multiple lags can work with a single ".
                              "channel-group of pswitch (negative)",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
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
                     '[2]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1]",
                        'lag' => {
                           '[1]' => {
                           },
                        },
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag_1"],["AddUplinkToLag_2"],
                             ["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],
                             ["CheckUplinkState_1"],["CheckUplinkState_2"],
                             ["ConfigureChannelGroup_3"],
                             ["CheckUplinkState_1"],["ConfigureChannelGroup_4"],
                             ["CheckUplinkState_3"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink_1"],["RemoveUplink_2"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[1-2]",
            },
            "AddUplinkToLag_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[3]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[1-2]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[3]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[1-2]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[3]",
            },
            "ConfigureChannelGroup_3" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[2]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_C,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_4" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[3]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "CheckUplinkState_3" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               checkuplinkstate => "Independent",
               vmnicadapter    => "host.[1].vmnic.[3]",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_C,
            },
            "RemoveUplink_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[1-2]",
            },
            "RemoveUplink_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[3]",
            },
         },
      },

      'EsxcliStats' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "EsxcliStats",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Check LAG stats increasing",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
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
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["Stats_1"],
                             ["ChangeLagMode"],["Stats_2"],
                             ["ConfigureChannelGroup"],["Stats_3"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"],],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[1]",
            },
            "Stats_1" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp stats get",
               expectedString  => "vmnic[0-9]+\\s+0\\s+0\\s+0\\s+1",
            },
            "ChangeLagMode" => {
               Type         => "LACP",
               TestLag      => "vc.[1].vds.[1].lag.[1]",
               lagoperation => "edit",
               lagmode      => "active",
            },
            "Stats_2" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp stats get",
               expectedString  => "vmnic[0-9]+\\s+0\\s+0\\s+0\\s+[2-9]",
            },
            "ConfigureChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "Stats_3" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "esxcli network vswitch dvs vmware lacp stats get",
               expectedString  => "vmnic[0-9]+\\s+0\\s+[1-9]\\s+0\\s+[1-9]",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type            => "Switch",
               TestSwitch      => "pswitch.[-1]",
               removeportchannel =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[1]",
            },
         },
      },

      'FallBackTeaming' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "FallBackTeaming",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if traffic can restore after pswitch ports".
                              " are removed from channel-group",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVDS_OneDVPG_OneLAG_TwoHost_OneVMandThreeVmnicForEachHost,
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["CheckUplinkState_1"],
                             ["RemovePortsFromChannelGroup"],
                             ["CheckUplinkState_2"],
                             ["NetAdapter_DHCP"],["Traffic"],
                             ["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetShortTimeout"],
                             ["RemovePortsFromChannelGroup"],
                             ["CheckUplinkState_3"],["Traffic"]
                             ],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Stand-alone",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => "100", # lag slow timeout
            },
            "CheckUplinkState_3" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Stand-alone",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => "10", # lag fast timeout
            },
            "SetShortTimeout" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               lagoperation    => "edit",
               lagtimeout      => "short",
               hosts           => "host.[-1]",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification    => "Verification_1",
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

      'ActivePassiveModeStress' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "ActivePassiveModeStress",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test 1000 times lag active/passive mode change",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagmode => "active",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["ChangeLAGMode"],["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
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
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ChangeLAGMode" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               Iterations      => "500",
               lagoperation    => "edit",
               lagmode         => "passive,active",
               maxtimeout      => "10800",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification    => "Verification_1",
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

      'LongDurationLAG' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LongDurationLAG",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LAGs long time running",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagmode => "active",
                           },
                        },
                     },
                     '[2]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagloadbalancing => "srcIp",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[3]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
               '[4]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag_1"],["AddUplinkToLag_2"],
                             ["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],
                             ["ConfigureChannelGroup_3"],
                             ["ConfigureChannelGroup_4"],
                             ["SetActiveUplink_1"],["SetActiveUplink_2"],
                             ["CheckUplinkState_1"],["CheckUplinkState_2"],
                             ["NetAdapter_DHCP"],
                             ["Traffic_1","Traffic_2"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink_1"],["RemoveUplink_2"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[1-2]",
            },
            "AddUplinkToLag_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[3]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[1-2]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[3]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_3" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[1-2]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_C,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_4" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[3]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
               Mode            => "Active",
            },
            "SetActiveUplink_1" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "SetActiveUplink_2" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[2]",
               failoverorder => "vc.[1].vds.[2].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[1-2]",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[3]",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_C.",".
                          VDNetLib::Common::GlobalConfig::DEFAULT_CHANNEL_GROUP,
            },
            "RemoveUplink_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[1-2]",
            },
            "RemoveUplink_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[2].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[3]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic_1" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "3600",
               maxtimeout      => "4000",
               Verification    => "Verification_1",
            },
            "Traffic_2" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofInbound     => "1",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               TestDuration    => "3600",
               maxtimeout      => "5000",
               Verification    => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 15000",
                  pktcount         => "14000+",
                  badpkt           => "0",
               },
            },
         },
      },

      'UplinkJoinLeaveStress' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "UplinkJoinLeaveStress",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test 1000 times uplink join/leave a lag",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly,betaonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVDS_OneDVPG_OneLAG_TwoHost_OneVMandThreeVmnicForEachHost,
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["NetAdapter_DHCP"],
                             ["RemoveAddUplink","Traffic"],["CheckUplinkState"],
                            ],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
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
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => "60",
            },
            "RemoveAddUplink" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               Iterations      => "500",
               configuplinktolag => "remove,add",
               vmnicadapter    => "host.[-1].vmnic.[1]",
               maxtimeout      => "25000",
               sleepbetweencombos => "1",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "1000",
               Verification    => "Verification_1",
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

      'VDSUpgrade' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "VDSUpgrade",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test vds5.1 with LACPv1 upgrade to vds5.5",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        version    => "5.1.0",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1-2]",
                     },
                  },
                  dvportgroup  => {
                     '[1]' => {
                        vds    => "vc.[1].vds.[1]",
                        ports  => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
               '[2]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["ConfigIPHashTeaming"],["CreateLAGv1Object"],
                             ["EnableLACPv1"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["CheckUplinkState"],
                             ["UpgradeVDS"],["CheckUplinkState"],
                             ["NetAdapter_DHCP"],["Traffic"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "ConfigIPHashTeaming"  => {
               Type          => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               loadbalancing => "loadbalance_ip",
            },
            "CreateLAGv1Object" => {
               Type         => "Switch",
               TestSwitch   => "vc.[1].vds.[1]",
               'lag' => {
                  '[1]' => {
                     lacpversion => "singlelag",
                  },
               },
            },
            "EnableLACPv1" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].vds.[1].uplinkportgroup.[1]",
               configurelag    => "enable",
               mode            => "active",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "UpgradeVDS" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               upgradevds      => "5.5.0",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                      VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                      VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
         },
      },

      'VDSAndLACPUpgrade' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "VDSAndLACPUpgrade",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test vds5.1 with LACPv1 upgrade to vds5.5 with ".
                              "LACPv2",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        version    => "5.1.0",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1-2]",
                     },
                  },
                  dvportgroup  => {
                     '[1]' => {
                        vds    => "vc.[1].vds.[1]",
                        ports  => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
               '[2]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["ConfigIPHashTeaming"],["CreateLAGv1Object"],
                             ["EnableLACPv1"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["CheckUplinkState_1"],
                             ["UpgradeVDS"],["CreateLAGv2"],
                             ["RemoveUplink"],["SetLAGv2Standby"],
                             ["AddUplinkToLAGv2"],["SetLAGv2Active"],
                             ["CheckUplinkState_2"],
                             ["Traffic"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "ConfigIPHashTeaming"  => {
               Type          => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[1]",
               loadbalancing => "loadbalance_ip",
            },
            "CreateLAGv1Object" => {
               Type         => "Switch",
               TestSwitch   => "vc.[1].vds.[1]",
               'lag' => {
                  '[1]' => {
                     lacpversion => "singlelag",
                  },
               },
            },
            "EnableLACPv1" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].vds.[1].uplinkportgroup.[1]",
               configurelag    => "enable",
               mode            => "active",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "UpgradeVDS" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               upgradevds      => "5.5.0",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               sleepbetweenretry => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               noofretries  => "3",
            },
            "CreateLAGv2" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               'lag' => {
                  '[2]' => {
                     lacpversion => "multiplelag",
                  },
               },
            },
            "RemoveUplink" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               configureuplinks => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "SetLAGv2Standby" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               failoverorder   => "vc.[1].vds.[1].lag.[2]",
               failovertype    => "standby",
            },
            "AddUplinkToLAGv2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "SetLAGv2Active" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               failoverorder   => "vc.[1].vds.[1].lag.[2]",
               failovertype    => "active",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               sleepbetweenretry => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               noofretries  => "3",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                      VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                      VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[2]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
         },
      },

      'LAGUpDownVOB' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LAGUpDownVOB",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Check VOB messages informing lag up & down",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1].x.[x]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1].x.[x]",
                        'lag' => {
                           '[1]' => {
                           },
                        },
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup"],
                             ["RemoveUplink"],["CheckVOBDown"],
                             ["AddUplink"],["CheckVOBUp"],],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "ConfigureChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "RemoveUplink" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "CheckVOBDown" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               host            => "host.[1].x.[x]",
               checkvob        => "down",
            },
            "AddUplink" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[1]",
            },
            "CheckVOBUp" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               host            => "host.[1].x.[x]",
               checkvob        => "up",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1].x.[x]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            },
         },
      },

      'PNICConfiguration' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "PNICConfiguration",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LACP stability with pnic config changes",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
               '[2]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[2].vmnic.[3]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink"],
                             ["ChangeSpeedDuplex1"],["ChangeSpeedDuplex2"],["ChangeSpeedDuplex3"],["ChangeSpeedDuplex4"],
                             ["CheckUplinkState_2"],
                             ["ChangeSpeedDuplexAuto"],["CheckUplinkState_1"],
                             ["NetAdapter_DHCP"],
                             ["Traffic"],["DownUpUplink"],
                             ["CheckUplinkState_1"],["Traffic"],
                             ["DisableEnablePort"],["CheckUplinkState_1"],
                             ["Traffic"]],
            ExitSequence => [["EnablePorts"],["UpUplink"],
                             ["ChangeSpeedDuplexAuto"],["RemoveUplink"],
                             ["RemovePortsFromChannelGroup"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink" => {
               Type         => "PortGroup",
               TestPortgroup => "vc.[1].dvportgroup.[-1]",
               failoverorder => "vc.[1].vds.[1].lag.[1]",
               failovertype  => "active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               sleepbetweenretry => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               noofretries  => "3",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Independent",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               sleepbetweenretry => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
               noofretries  => "3",
            },
            "ChangeSpeedDuplex1" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[-1].vmnic.[-1]",
               intType         => "vmnic",
               configure_link_properties => {
                 speed           => "10",
                 duplex          => "full"
               }
            },
            "ChangeSpeedDuplex2" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[-1].vmnic.[-1]",
               intType         => "vmnic",
               configure_link_properties => {
                 speed           => "10",
                 duplex          => "half"
               }
            },
            "ChangeSpeedDuplex3" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[-1].vmnic.[-1]",
               intType         => "vmnic",
               configure_link_properties => {
                 speed           => "100",
                 duplex          => "full"
               }
            },
            "ChangeSpeedDuplex4" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[-1].vmnic.[-1]",
               intType         => "vmnic",
               configure_link_properties => {
                 speed           => "100",
                 duplex          => "half"
               }
            },
            "ChangeSpeedDuplexAuto" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[-1].vmnic.[-1]",
               intType         => "vmnic",
               configure_link_properties => {
                 autoconfigure => "true"
               }
            },
            "DownUpUplink" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[-1].vmnic.[-1]",
               devicestatus    => "down,up",
            },
            "UpUplink" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[-1].vmnic.[-1]",
               devicestatus    => "up",
            },
            "DisableEnablePort" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               portstatus      => "disable,enable",
            },
            "EnablePorts" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               portstatus      => "enable",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification   => "Verification_1",
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

      'LACPImportExportVDSConfig' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LACPImportExportVDSConfig",
         Priority          => 'P2',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if lag properties can be exported/imported",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagname => "lag-test",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vss    => {
                     '[1]'   => {
                     },
                  },
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  portgroup  => {
                     '[1]' => {
                        vss  => "host.[1].vss.[1]",
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
               '[2]'   => {
                  vss    => {
                     '[1]'   => {
                     },
                  },
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  portgroup  => {
                     '[1]' => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "host.[1].portgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "host.[2].portgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetActiveUplink_1"],
                             ["ExportVDSDVPGConfig"],["RemoveVDS"],
                             ["ImportOrigVDSDVPGConfig"],
                             ["AddDuplicateLAG"],["SetActiveUplink_2"],
                             ["ChangePortgroup_1"],
                             ["ChangePortgroup_2"],
                             ["NetAdapter_DHCP"],
                             ["Traffic"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "SetActiveUplink_1" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               failoverorder   => "vc.[1].vds.[1].lag.[1]",
               failovertype    => "active",
            },
            "ExportVDSDVPGConfig"      => {
               Type            => 'Switch',
               TestSwitch      => 'vc.[1].vds.[1]',
               backuprestore   => 'exportvdsdvpg',
               portgroup       => 'vc.[1].dvportgroup.[1]'
            },
            "RemoveVDS" => {
               Type            => 'VC',
               TestVC          => 'vc.[1]',
               deletevds       => 'vc.[1].vds.[1]',
               skipPostProcess => '1',
            },
		  "ImportOrigVDSDVPGConfig" => {
		     Type            => "Switch",
		     TestSwitch      => "vc.[1].vds.[1]",
		     backuprestore   => "importorigvdsdvpg",
		     portgroup       => "vc.[1].dvportgroup.[1]"
		  },
            "AddDuplicateLAG" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               lag => {
                  '[1]' => {
                     lagname => "lag-test",
                  },
               },
               expectedresult => "FAIL",
            },
            "SetActiveUplink_2" => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               failoverorder   => "uplink[1]",
               failovertype    => "standby",
               expectedresult  => "FAIL",
            },
            "ChangePortgroup_1" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[1].vnic.[1]",
               PortGroup       => "vc.[1].dvportgroup.[1]",
               reconfigure     => "true",
            },
            "ChangePortgroup_2" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[2].vnic.[1]",
               PortGroup       => "vc.[1].dvportgroup.[1]",
               reconfigure     => "true",
            },
            "NetAdapter_DHCP" => {
               Type            => "NetAdapter",
               TestAdapter     => "vm.[-1].vnic.[1]",
               ipv4            => "dhcp",
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
               Verification    => "Verification_1",
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
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
         },
      },

      'HealthCheck' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "HealthCheck",
         Priority          => 'P3',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test LACP interop with vlan/mtu health check",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                           },
                        },
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
               '[2]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[2].vmnic.[2]",
                      },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["GetPortRuningConfig"],["AddUplinkToLag"],
                             ["SetNativeVlan"],["SetMTU"],
                             ["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["SetVLANMTUCheck"],
                             ["CheckMTUHealth"],["SetVLANMTUCheckParam"],
                             ["CheckVLANHealth"],["CheckUplinkState"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],["RemoveUplink"],
                             ["UnsetVLANMTUCheck"],
                             ["DeleteChannelGroup"],["SetPortRuningConfig"]],
            Duration     => "time in seconds",
            "GetPortRuningConfig" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               getportrunningconfiguration => "1",
            },
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "SetNativeVlan" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               setupnativetrunkvlan =>
                          VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
            },
            "SetMTU" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               mtu             => "9000",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
               nativevlan      => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
               nativevlan      => VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
            },
            "SetVLANMTUCheck" => {
               Type                 => "Switch",
               TestSwitch           => "vc.[1].vds.[1]",
               configurehealthcheck => "vlanmtu",
               operation            => "Enable",
               healthcheckinterval  => "1",
            },
            "UnsetVLANMTUCheck" => {
               Type                 => "Switch",
               TestSwitch           => "vc.[1].vds.[1]",
               configurehealthcheck => "vlanmtu",
               operation            => "Disable",
               healthcheckinterval  => "1",
            },
            "CheckMTUHealth" => {
               Type                 => "Host",
               TestHost             => "host.[1]",
               TestSwitch           => "vc.[1].vds.[1]",
               vmnicadapter         => "host.[1].vmnic.[1-2]",
               CheckLocalMTUMatch   => "MATCH",
            },
            "SetVLANMTUCheckParam" => {
               Type                 => "Host",
               TestHost             => "host.[1]",
               TestSwitch           => "vc.[1].vds.[1]",
               ChangeVLANMTUParam   =>
                          VDNetLib::Common::GlobalConfig::VDNET_VLAN_C."to".
                          VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },
            "CheckVLANHealth" => {
               Type                 => "Host",
               TestHost             => "host.[1]",
               TestSwitch           => "vc.[1].vds.[1]",
               vmnicadapter         => "host.[1].vmnic.[1-2]",
               CheckVLANMTUTrunkResult =>
                          VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
               UnTrunk              =>
                          VDNetLib::Common::GlobalConfig::VDNET_VLAN_C,
            },
            "CheckUplinkState" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                      VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                      VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "SetPortRuningConfig" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               setportrunningconfiguration => "1",
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
         },
      },

      'MaxStandbyUplinks' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "MaxStandbyUplinks",
         Priority          => 'P3',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if the max number of standby uplinks in a ".
                              "lag is 8",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
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
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-9]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                      '[4]'     => {
                         vmnic => "host.[1].vmnic.[4]",
                      },
                      '[5]'     => {
                         vmnic => "host.[1].vmnic.[5]",
                      },
                      '[6]'     => {
                         vmnic => "host.[1].vmnic.[6]",
                      },
                      '[7]'     => {
                         vmnic => "host.[1].vmnic.[7]",
                      },
                      '[8]'     => {
                         vmnic => "host.[1].vmnic.[8]",
                      },
                      '[9]'     => {
                         vmnic => "host.[1].vmnic.[9]",
                      },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag_1"],["ConfigureChannelGroup"],
                             ["CheckUplinkState_1"],["AddUplinkToLag_2"],
                             ["CheckUplinkState_2"],["DownUplink"],
                             ["CheckUplinkState_3"],["CheckUplinkState_4"]],
            ExitSequence => [["UpUplink"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[1-8]",
            },
            "ConfigureChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[1-8]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "AddUplinkToLag_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[9]",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Hot-standby",
               vmnicadapter    => "host.[1].vmnic.[9]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "DownUplink" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[1].vmnic.[1]",
               devicestatus    => "down",
            },
            "CheckUplinkState_3" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[2-9]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "CheckUplinkState_4" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Hot-standby",
               vmnicadapter    => "host.[1].vmnic.[1]",
            },
            "UpUplink" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[1].vmnic.[1]",
               devicestatus    => "up",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
         },
      },

      'KillLACP' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "KillLACP",
         Priority          => 'P3',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if lacp module can be unloaded and loaded",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
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
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag"],["ConfigureChannelGroup"],
                             ["StopLACP"],["CheckUplinkState_1"],
                             ["StartLACP"],["CheckUplinkState_2"],
                             ["RemoveUplink"],["DeleteLag"],["StopLACP"],
                             ["UnloadLACPModule"],["LoadLACPModule"]],
            ExitSequence => [["StartLACP"],["RemovePortsFromChannelGroup"],
                             ["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "ConfigureChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "StopLACP" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "/etc/init.d/lacp stop",
               expectedString  => "Terminating watchdog process",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
               expectedresult  => "FAIL",
            },
            "StartLACP" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "/etc/init.d/lacp start",
               expectedString  => "LACP daemon started",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
            "DeleteLag" => {
               Type            => "Switch",
               TestSwitch      => "vc.[1].vds.[1]",
               DeleteLag       => "vc.[1].vds.[1].lag.[1]",
            },
            "UnloadLACPModule" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "vmkload_mod -u lacp",
               expectedString  => "Module lacp successfully unloaded",
            },
            "LoadLACPModule" => {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "vmkload_mod lacp",
               expectedString  => "Module lacp loaded successfully",
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            },
         },
      },

      'FalseUplinkJoinLAG' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "FalseUplinkJoinLAG",
         Priority          => 'P3',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if uplinks with different speed/duplex ".
                              "cannot be bundled in a LAG",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
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
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-3]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[1].vmnic.[1]",
                      },
                      '[2]'     => {
                         vmnic => "host.[1].vmnic.[2]",
                      },
                      '[3]'     => {
                         vmnic => "host.[1].vmnic.[3]",
                      },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag_1"],["ConfigureChannelGroup_1"],
                             ["CheckUplinkState_1"],["ChangeSpeed"],
                             ["ChangeDuplex"],["AddUplinkToLag_2"],
                             ["ConfigureChannelGroup_2"],["CheckUplinkState_2"],
                             ["ChangeSpeedDuplexAuto"],["CheckUplinkState_3"]],
            ExitSequence => [["RemovePortsFromChannelGroup"],
                             ["DeleteChannelGroup"],
                             ["RemoveUplink"],["ChangeSpeedDuplexAuto"]],
            Duration     => "time in seconds",
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "ChangeSpeed" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[1].vmnic.[2]",
               configure_link_properties => {
                 speed           => "100",
                 duplex          => "full"
               }
            },
            "ChangeDuplex" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[1].vmnic.[3]",
               configure_link_properties => {
                 speed           => "100",
                 duplex          => "half"
               }
            },
            "AddUplinkToLag_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[2-3]",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[2-3]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Independent",
               vmnicadapter    => "host.[1].vmnic.[2-3]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "ChangeSpeedDuplexAuto" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[1].vmnic.[-1]",
               intType         => "vmnic",
               configure_link_properties => {
                 autoconfigure => "true"
               }
            },
            "CheckUplinkState_3" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
               sleepbetweenworkloads => "10", # wait for uplink speed and lacp negotiation
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[1].vmnic.[-1]",
            },
         },
      },

      'LagPortFailback' => {
         Product           => 'ESX',
         Category          => 'Networking',
         Component         => 'Teaming/LACP',
         TestName          => "LagPortFailback",
         Priority          => 'P1',
         Version           => '2' ,
         PMT               => '6630',
         Summary           => "Test if failback works well among lag ports " .
                              "see PR 1150410",
         ExpectedResult    => "PASS",
         Tags              => "physicalonly",
         AutomationStatus  => "Automated",
         TestbedSpec       => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1-2]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host  => "host.[1-2]",
                        'lag' => {
                           '[1]' => {
                              lagports => "1",
                           },
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1-2]'   => {
                        driver => "any",
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
               '[2]'   => {
                  vmnic  => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  pswitchport => {
                      '[1]'     => {
                         vmnic => "host.[2].vmnic.[1]",
                      },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
            },
            pswitch => {
               '[1]' => {
                  ip => "XX.XX.XX.XX",
               },
            },
         },
         WORKLOADS => {
            Sequence     => [["AddUplinkToLag_1"],["ConfigureChannelGroup_1"],
                             ["ConfigureChannelGroup_2"],["CheckUplinkState_1"],
                             ["SetActiveUplink"],["AddLagPort"],
                             ["Traffic"],["AddUplinkToLag_2"],
                             ["ConfigureChannelGroup_3"],["CheckUplinkState_2"],
                             ["DownUplink"],["Traffic"]],
            ExitSequence => [["UpUplink"],["RemovePortsFromChannelGroup"],
                             ["RemoveUplink"],["DeleteChannelGroup"]],
            Duration     => "time in seconds",
            "AddUplinkToLag_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[-1].vmnic.[1]",
            },
            "ConfigureChannelGroup_1" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "ConfigureChannelGroup_2" => {
               Type            => "Port",
               TestPort        => "host.[2].pswitchport.[1]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
               Mode            => "Active",
            },
            "CheckUplinkState_1" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[-1].vmnic.[1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "SetActiveUplink"  => {
               Type            => "PortGroup",
               TestPortgroup   => "vc.[1].dvportgroup.[1]",
               failoverorder   => "vc.[1].vds.[1].lag.[1]",
               failovertype    => "active",
            },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "iperf",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               BurstType       => "stream",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestDuration    => "10",
            },
            "AddLagPort" => {
               Type         => "LACP",
               TestLag      => "vc.[1].vds.[1].lag.[1]",
               lagoperation => "edit",
               lagports     => "2",
            },
            "AddUplinkToLag_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter    => "host.[1].vmnic.[2]",
            },
            "ConfigureChannelGroup_3" => {
               Type            => "Port",
               TestPort        => "host.[1].pswitchport.[2]",
               configurechannelgroup =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A,
               Mode            => "Active",
            },
            "CheckUplinkState_2" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[2]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "DownUplink" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[1].vmnic.[1]",
               devicestatus    => "down",
            },
            "UpUplink" => {
               Type            => "NetAdapter",
               TestAdapter     => "host.[1].vmnic.[1]",
               devicestatus    => "up",
            },
            "CheckUplinkState_3" => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               checkuplinkstate => "Bundled",
               vmnicadapter    => "host.[1].vmnic.[-1]",
               sleepbetweenworkloads => VDNetLib::TestData::TestConstants::LACP_SLEEP_STATS,
            },
            "RemovePortsFromChannelGroup" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "DeleteChannelGroup" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    =>
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_A.",".
                          VDNetLib::Common::GlobalConfig::VDNET_CHANNEL_GROUP_B,
            },
            "RemoveUplink"  => {
               Type            => "LACP",
               TestLag         => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter    => "host.[-1].vmnic.[-1]",
            },
         },
      },
   );
}


#######################################################################
#
# new --
#       This is the constructor for VDS.
#
# Input:
#       None.
#
# Results:
#       An instance/object of VDS class.
#
# Side effects:
#       None.
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%MultiLAG);
   return (bless($self, $class));
}


########################### Testing Notes ##############################

   # If an uplink goes into independent state, should it show in NGC/LACP UI as part
   # of lag?

   # When LAG names are long does the LACP UI fit them properly?
   # Same for large no of VLANs values

   # TODO: Confirm this with Tony.
   # 1) Warning should be shown when both LAGs and uplinks are present in the active and standby groups
   # 2) Warning should be shown when more than one LAG is set as active or standby.

   # Do a partial Upgrade. Try to do invalid upgrade. Make Upgrade validation fail


