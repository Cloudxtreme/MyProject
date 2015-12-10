#!/usr/bin/perl
###########################################################################
# Copyright (C) 2013 VMWare, Inc.
#  All Rights Reserved
###########################################################################
package TDS::NSX::Networking::VXLAN::MACLearningTds;

#
#
#
# This file contains the structured hash for MAC Learning.
# The following lines explain the keys of the internal
# hash in general.
#
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
@ISA = qw(TDS::Main::VDNetMainTds);

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VXLAN::TestbedSpec ':AllConstants';

{
   %MACFilter = (
      'MACFilterWithVXLAN'   => {
         TestName         => 'MACLearningFilterWithVXLAN',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         Summary          => 'Verify that enabling mac filter works with VXLAN',
         Procedure        => '1. Create 1 VXLAN networks with guest tagging enabled'.
                             '2. Enable guest vlan tagging for the vxlan'.
                             '3. Enable MAC Learning for the vwire created'.
                             '4. Connect VM to the vxlan network and configured vlans'.
                             '5. Make sure that filter is enabled for vm ports'.
                             '6. Migrate VM to the destination host'.
                             '7. After migration traffic should work',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'hchilkot',
         Partnerfacing    => 'N',
         Version          => '2',
         TestbedSpec      => MAC_FILTER_TESTBEDSPEC,
         WORKLOADS        => {
            Sequence => [
                         ['CreateVWires'],
                         ['AddVNIC1'],
                         ['AddVNIC2'],
                         ['EnableMACLearning'],
                         ['PowerOnVM1'],
                         ['PowerOnVM2'],
                         ['VerifyNetworkFeatures'],
                         ['AddVLANVM1'],
                         ['AddVLANVM2'],
                         ['Traffic1'],
                         ['vmotion1'],
                         ['Traffic1'],
                         ['vmotion2']
                         ],
            ExitSequence => [
                             ['PowerOffVM'],['DeleteVNIC1'],['DeleteVNIC2'],
                             ['DeleteVirtualWires']
                            ],

            'CreateVWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenrate",
                     tenantid => "AutoGenerate",
                     controlplanemode => "MULTICAST_MODE",
                     guestvlanallowed => "true",
                  },
               },
            },
            'EnableMACLearning' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vsm.[1].networkscope.[1].virtualwire.[1]",
               networkfeatures => {
                  macLearning => "enable",
               },
            },
            'VerifyNetworkFeatures' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Features enabled' => "MAC learning",
                  },
               ],
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
            },
            'AddVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVLANVM1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'vlaninterface' => {
                  '[1]' => {
                     'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
                  },
               },
            },
            'AddVLANVM2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'vlaninterface' => {
                  '[1]' => {
                     'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_D,
                  },
               },
            },
            'Traffic1' => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1].vlaninterface.[1]",
               SupportAdapter => "vm.[3].vnic.[1].vlaninterface.[1]",
               TestDuration   => "120",
            },

            'vmotion1' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmotion => "oneway",
               dsthost => "host.[3]",
            },
            'vmotion2' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmotion => "oneway",
               dsthost => "host.[2]",
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               deletevnic => "vm.[3].vnic.[1]",
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },

            'PowerOffVM' => {
               Type => "VM",
               TestVM => "vm.[1],vm.[3]",
               vmstate => "poweroff",
            },
         },
      },
      'MACFilterWithdvportgroup'   => {
         TestName         => 'MACFilterWithdvportgroup',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         Summary          => 'Verify that mac filter works with dvportgroup',
         Procedure        => '1. Create 1 dvportgroup with guest tagging enabled'.
                             '2. Enable guest vlan tagging for the dvportgroup'.
                             '3. Enable MAC Learning for the dvporgroup'.
                             '4. Connect VM to the vxlan network and configured vlans'.
                             '5. Make sure that filter is enabled for vm ports'.
                             '6. Migrate VM to the destination host'.
                             '7. After migration traffic should work',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'hchilkot',
         Partnerfacing    => 'N',
         Version          => '2',
         TestbedSpec      => MAC_FILTER_TESTBEDSPEC,
         WORKLOADS        => {
            Sequence => [['AddVNIC1'],['AddVNIC3'],
                         ['EnableMACLearning'],['PowerOnVM1'],
                         ['PowerOnVM3'],['VerifyNetworkFeatures1'],
                         ['VerifyNetworkFeatures3'],['AddVLANVM1'],
                         ['AddVLANVM3'],['Traffic1'],['vmotion1'],
                         ['Traffic1'],['vmotion2'],['Traffic1']],
            ExitSequence => [['PowerOffVM'],
                             ['DeleteVNIC1'],['DeleteVNIC3']],

            'EnableMACLearning' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vc.[1].dvportgroup.[4]",
               networkfeatures => {
                  macLearning => "enable",
               },
            },
            'VerifyNetworkFeatures1' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Features enabled' => "MAC learning",
                  },
               ],
            },
            'VerifyNetworkFeatures3' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[3].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Features enabled' => "MAC learning",
                  },
               ],
            },
            'AddVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[4]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[4]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVLANVM1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'vlaninterface' => {
                  '[1]' => {
                     'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
                  },
               },
            },
            'AddVLANVM3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'vlaninterface' => {
                  '[1]' => {
                     'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
                  },
               },
            },
            'Traffic1' => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1].vlaninterface.[1]",
               SupportAdapter => "vm.[3].vnic.[1].vlaninterface.[1]",
               TestDuration   => "10",
            },

            'vmotion1' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmotion => "oneway",
               dsthost => "host.[3]",
            },
            'vmotion2' => {
               Type => "VM",
               TestVM => "vm.[1]",
               vmotion => "oneway",
               dsthost => "host.[2]",
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               deletevnic => "vm.[3].vnic.[1]",
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
             'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOffVM' => {
               Type => "VM",
               TestVM => "vm.[1],vm.[3]",
               vmstate => "poweroff",
            },
         },
      },
      'EnableDisableMACFilter'   => {
         TestName         => 'EnableDisableMACFilter',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         Summary          => 'Verify that enable/disable mac filter works',
         Procedure        => '1. Create 1 VXLAN networks with guest tagging enabled'.
                             '2. Enable guest vlan tagging for the vxlan'.
                             '3. Enable MAC Learning for the vwire created'.
                             '4. Connect VM to the vxlan network and configured vlans'.
                             '5. Make sure that filter is enabled for vm ports'.
                             '6. Disable MAC filter',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'hchilkot',
         Partnerfacing    => 'N',
         Version          => '2',
         TestbedSpec      => MAC_FILTER_TESTBEDSPEC,
         WORKLOADS        => {
            Sequence => [['CreateVWires'],['EnableMACLearning'],
                         ['AddVNIC1'],['AddVNIC3'],['PowerOnVM1'],
                         ['PowerOnVM3'],['AddVLANVM1'],['AddVLANVM3'],
                         ['Traffic1'],['VerifyNetworkFeature1'],
                         ['DisableMACLearning'],['VerifyNetworkFeature2'],
                         ['Traffic1']],
            ExitSequence => [['PowerOffVM'],['DeleteVNIC1'],['DeleteVNIC3'],
                             ['DeleteVirtualWires']],

            'CreateVWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenrate",
                     tenantid => "AutoGenerate",
                     controlplanemode => "HYBRID_MODE",
                     guestvlanallowed => "true",
                  },
               },
            },
            'EnableMACLearning' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vsm.[1].networkscope.[1].virtualwire.[1]",
               networkfeatures => {
                  macLearning => "enable",
               },
            },
            'DisableMACLearning' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vsm.[1].networkscope.[1].virtualwire.[1]",
               networkfeatures => {
                  macLearning => "disable",
               },
            },
            'VerifyNetworkFeature1' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Features enabled' => "MAC learning",
                  },
               ],
            },
            'VerifyNetworkFeature2' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1].vnic.[1]",
               'networkfeaturestatus[?]not_contains' => [
                  {
                    'Features enabled' => "MAC learning",
                  },
               ],
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
            },
            'AddVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVLANVM1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'vlaninterface' => {
                  '[1]' => {
                     'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
                  },
               },
            },
            'AddVLANVM3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'vlaninterface' => {
                  '[1]' => {
                     'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
                  },
               },
            },
            'Traffic1' => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1].vlaninterface.[1]",
               SupportAdapter => "vm.[3].vnic.[1].vlaninterface.[1]",
               TestDuration   => "120",
            },
           'AddVLANVM1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'vlaninterface' => {
                  '[1]' => {
                     'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
                  },
               },
            },
            'AddVLANVM3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'vlaninterface' => {
                  '[1]' => {
                     'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
                  },
               },
            },
            'Traffic1' => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1].vlaninterface.[1]",
               SupportAdapter => "vm.[3].vnic.[1].vlaninterface.[1]",
               TestDuration   => "120",
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               deletevnic => "vm.[3].vnic.[1]",
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
             'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOffVM' => {
               Type => "VM",
               TestVM => "vm.[1],vm.[3]",
               vmstate => "poweroff",
            },
         },
      },
      'EnableMACFilterAndIPDiscovery'   => {
         TestName         => 'EnableMACFilterAndIPDiscovery',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         Summary          => 'Verify that enabling ip discovery and mac filter works',
         Procedure        => '1. Create 1 VXLAN networks and dvpg with guest tagging enabled'.
                             '2. Enable guest vlan tagging for the vxlan'.
                             '3. Enable MAC Learning and ip disovery for vwire and dvpg'.
                             '4. Connect VM to the vxlan network and configured vlans'.
                             '5. Make sure that filter is enabled for vm ports',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'hchilkot',
         Partnerfacing    => 'N',
         Version          => '2',
         TestbedSpec      => MAC_FILTER_TESTBEDSPEC,
         WORKLOADS        => {
            Sequence => [['CreateVWires'],['AddVNIC1'],['AddVNIC2'],
                         ['EnableMACIPDiscoveryDVPG'],
                         ['EnableMACIPDiscoveryVwire'],
                         ['PowerOnVM1'],['PowerOnVM2'],
                         ['VerifyNetworkFeatures']],
            ExitSequence => [['PowerOffVM'],['DeleteVNIC1'],
                             ['DeleteVNIC2'],['DeleteVirtualWires']],

            'CreateVWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenrate",
                     tenantid => "AutoGenerate",
                     controlplanemode => "MULTICAST_MODE",
                     guestvlanallowed => "true",
                  },
               },
            },
            'EnableMACIPDiscoveryVwire' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vsm.[1].networkscope.[1].virtualwire.[1]",
               networkfeatures => {
                  macLearning => "enable",
                  ipDiscovery => "enable",
               },
            },
             'EnableMACIPDiscoveryDVPG' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vc.[1].dvportgroup.[4]",
               networkfeatures => {
                  macLearning => "enable",
                  ipDiscovery => "enable",
               },
            },
            'VerifyNetworkFeatures' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1-2].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Features enabled' => "IP Discovery,MAC learning",
                  },
               ],
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
            },
            'AddVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[4]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
             'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOffVM' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vmstate => "poweroff",
            },
         },
      },
      'MACExpiryTimeoutWithVXLAN'   => {
         TestName         => 'MACExpiryTimeoutWithVXLAN',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         Summary          => 'Verify enabling mac filter sets correct value of mac'.
                             ' expiry timeout',
         Procedure        => '1. Create 1 VXLAN networks with guest tagging enabled'.
                             '2. Enable guest vlan tagging for the vxlan'.
                             '3. Enable MAC Learning for the vwire created'.
                             '4. Connect VM to the vxlan network and configured vlans'.
                             '5. Make sure that filter is enabled for vm ports'.
                             '6. Check the mac expiry timeout value for the vm ports',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'hchilkot',
         Partnerfacing    => 'N',
         Version          => '2',
         TestbedSpec      => MAC_FILTER_TESTBEDSPEC,
         WORKLOADS        => {
            Sequence => [['CreateVWires'],['AddVNIC1'],['AddVNIC2'],
                         ['AddVNIC3'],['AddVNIC4'],['PowerOnVM1'],
                         ['PowerOnVM2'],['PowerOnVM2'],['PowerOnVM3'],
                         ['PowerOnVM4'],['EnableMACLearning1'],
                         ['EnableMACLearning2'],
                         ['VerifyNetworkFeatures'],['ExpiryTimeout']
                         ],
            ExitSequence => [['PowerOffVM'],['DeleteVNIC1'],['DeleteVNIC2'],
                             ['DeleteVNIC3'],['DeleteVNIC4'],['DeleteVirtualWires']],

            'CreateVWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1-2]" => {
                     name     => "AutoGenrate",
                     tenantid => "AutoGenerate",
                     controlplanemode => "MULTICAST_MODE",
                     guestvlanallowed => "true",
                  },
               },
            },
            'EnableMACLearning1' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vsm.[1].networkscope.[1].virtualwire.[1]",
               networkfeatures => {
                  macLearning => "enable",
               },
            },
            'EnableMACLearning2' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vsm.[1].networkscope.[1].virtualwire.[2]",
               networkfeatures => {
                  macLearning => "enable",
               },
            },

            'VerifyNetworkFeatures' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1-4].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Features enabled' => "MAC learning",
                  },
               ],
            },
            'ExpiryTimeout' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1-4].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Mac ageout time' => "180 seconds",
                  },
               ],
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-2]",
            },
            'AddVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'DeleteVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               deletevnic => "vm.[3].vnic.[1]",
            },
            'DeleteVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               deletevnic => "vm.[4].vnic.[1]",
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM' => {
               Type => "VM",
               TestVM => "vm.[1-4]",
               vmstate => "poweroff",
            },
         },
      },
      'MACExpiryTimeoutWithDVPortgroup'   => {
         TestName         => 'MACExpiryTimeoutWithDVPortgroup',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         Summary          => 'Verify the mac expiry timeout with dvportgroup',
         Procedure        => '1. Create dvportgroup with guest tagging enabled'.
                             '2. Enable MAC Learning for the vwire created'.
                             '3. Connect VM to the vxlan network and configured vlans'.
                             '4. Make sure that filter is enabled for vm ports'.
                             '5. Check the mac expiry timeout value for the vm ports',

         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'hchilkot',
         Partnerfacing    => 'N',
         Version          => '2',
         TestbedSpec      => MAC_FILTER_TESTBEDSPEC,
         WORKLOADS        => {
            Sequence => [['AddVNIC1'],['AddVNIC2'],
                         ['AddVNIC3'],['AddVNIC4'],['PowerOnVM1'],
                         ['PowerOnVM2'],['PowerOnVM2'],['PowerOnVM3'],
                         ['PowerOnVM4'],['EnableMACLearning1'],['EnableMACLearning2'],
                         ['VerifyNetworkFeatures'],['ExpiryTimeout']
                         ],
            ExitSequence => [['PowerOffVM'],['DeleteVNIC1'],['DeleteVNIC2'],
                             ['DeleteVNIC3'],['DeleteVNIC4']],

            'EnableMACLearning1' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vc.[1].dvportgroup.[4]",
               networkfeatures => {
                  macLearning => "enable",
               },
            },
            'EnableMACLearning2' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vc.[1].dvportgroup.[5]",
               networkfeatures => {
                  macLearning => "enable",
               },
            },

            'VerifyNetworkFeatures' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1-4].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Features enabled' => "MAC learning",
                  },
               ],
            },
            'ExpiryTimeout' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1-4].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Mac ageout time' => "180 seconds",
                  },
               ],
            },
            'AddVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[4]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[5]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[4]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[5]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'DeleteVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               deletevnic => "vm.[3].vnic.[1]",
            },
            'DeleteVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               deletevnic => "vm.[4].vnic.[1]",
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM' => {
               Type => "VM",
               TestVM => "vm.[1-4]",
               vmstate => "poweroff",
            },
         },
      },
      'EnableDisableIPDiscovery'   => {
         TestName         => 'EnableDisableIPDiscovery',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         Summary          => 'Verify enabling disabling ip discovery',
         Procedure        => '1. Create 1 VXLAN networks'.
                             '2. Enable ip discovery for the vwire created'.
                             '3. Make sure that vm ports has ip discovery enabled'.
                             '4. disabling ip discovery should show the status on host',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'hchilkot',
         Partnerfacing    => 'N',
         Version          => '2',
         TestbedSpec      => MAC_FILTER_TESTBEDSPEC,
         WORKLOADS        => {
            Sequence => [['CreateVWires'],['AddVNIC1'],['AddVNIC2'],
                         ['PowerOnVM1'],['PowerOnVM2'],
                         ['EnableIPDiscovery1'],['EnableIPDiscovery2'],
                         ['VerifyNetworkFeatures1'],['DisableIPDiscovery1'],
                         ['DisableIPDiscovery2'],['VerifyNetworkFeatures2'],
                         ['EnableMACIPDiscovery1'],['EnableMACIPDiscovery2'],
                         ['VerifyNetworkFeatures3']],
            ExitSequence => [['PowerOffVM'],['DeleteVNIC1'],['DeleteVNIC2'],
                             ['DeleteVirtualWires']],

            'CreateVWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenrate",
                     tenantid => "AutoGenerate",
                     controlplanemode => "MULTICAST_MODE",
                  },
               },
            },
            'EnableIPDiscovery1' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vsm.[1].networkscope.[1].virtualwire.[1]",
               networkfeatures => {
                  ipDiscovery => "enable",
               },
            },
            'EnableIPDiscovery2' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vc.[1].dvportgroup.[3]",
               networkfeatures => {
                  ipDiscovery => "enable",
               },
            },
            'VerifyNetworkFeatures1' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1-2].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Features enabled' => "IP Discovery",
                  },
               ],
            },
            'EnableMACIPDiscovery1' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vsm.[1].networkscope.[1].virtualwire.[1]",
               networkfeatures => {
                  ipDiscovery => "enable",
                  macLearning => "enable",
               },
            },
            'EnableMACIPDiscovery2' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vc.[1].dvportgroup.[3]",
               networkfeatures => {
                  ipDiscovery => "enable",
                  macLearning => "enable",
               },
            },
            'VerifyNetworkFeatures3' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1-2].vnic.[1]",
               'networkfeaturestatus[?]contains' => [
                  {
                    'Features enabled' => "IP Discovery,MAC learning",
                  },
               ],
            },
            'DisableIPDiscovery1' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vsm.[1].networkscope.[1].virtualwire.[1]",
               networkfeatures => {
                  ipDiscovery => "disable",
               },
            },
            'DisableIPDiscovery2' => {
               Type => "NSX",
               TestNSX => "vsm.[1]",
               portgroup => "vc.[1].dvportgroup.[3]",
               networkfeatures => {
                  ipDiscovery => "disable",
               },
            },
            'VerifyNetworkFeatures2' => {
               'Type' => "NetAdapter",
               'TestAdapter' => "vm.[1-2].vnic.[1]",
               'networkfeaturestatus[?]not_contains' => [
                  {
                    'Features enabled' => "IP Discovery",
                  },
               ],
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
            },
            'AddVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'AddVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[3]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
             'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOffVM' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vmstate => "poweroff",
            },
         },
      },
   );
}

##########################################################################
# new --
#       This is the constructor for MAC Filter TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of MAC Filter class
#
# Side effects:
#       None
#
#########################################################################

sub new
{
   my ($proto) = @_;
   #
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   #
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%MACFilter);
   return (bless($self, $class));
}

1;
