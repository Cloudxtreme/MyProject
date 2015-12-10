#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Common::PreCheckIn;

@ISA = qw(TDS::Main::VDNetMainTds);
#
# This file contains the structured hash for category, Sample tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

# Test constants 
use constant TRAFFIC_TESTDURATION => "30";
use constant STRESS_ITERATIONS => "1";

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';

#
# Begin test cases
#
{
%PreCheckIn = (
   'NVPPreCheckIn' => {
      Product          => "NSX",
      Category         => "OVS on ESX",
      Component        => "unknown",
      TestName         => "NVPPreCheckIn",
      Version          => "2" ,
      Tags             => "precheckin",
      Summary          => "This is the precheck-in test case for NVP-NVS ",
      TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::nvpStandardTopology01,
      'WORKLOADS' => {
         'Sequence' => [
            ['SetController'],
            ['AddUplinkOnHost1', 'AddUplinkOnHost2'],
            ['EditUplinkOnHost1','EditUplinkOnHost2'],
            ['EnableVMotion1'],
            ['EnableVMotion2'],
            ['ConfigureVMForvMotion'],
            ['CreateTZ'],
            ['CreateTN1'],
            ['CreateTN2'],
            ['CreateLS'],
            ['CreateLP1'],
            ['CreateLP2'],
            ['Traffic'],
            ['Host1ToHost2Vmotion'],
            ['Traffic'],
            ['Host2ToHost1Vmotion'],
            ['Traffic'],
         ],
         ExitSequence => [
           ['RemoveUplinkIPOnHost1', 'RemoveUplinkIPOnHost2'],
           ['RemoveUplinkOnHost1', 'RemoveUplinkOnHost2'],
           ['Host2ToHost1Vmotion'],
           ['CleanupNVP'],
         ],
        'Traffic' => {
            Type           => "Traffic",
            ToolName       => "netperf",
            L3Protocol     => "ipv4",
            TestAdapter    => "vm.[2].vnic.[1]",
            SupportAdapter => "vm.[1].vnic.[1]",
            NoofOutbound      => "1",
            NoofInbound       => "1",
            TestDuration   => "10",
        },
         'ConfigureVMForvMotion' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'operation' => 'configurevmotion'
         },
         'EnableVMotion1' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'host.[1].vmknic.[1]',
            'configurevmotion' => 'ENABLE',
         },
         'EnableVMotion2' => {
            'Type' => 'NetAdapter',
            'TestAdapter' => 'host.[2].vmknic.[1]',
            'configurevmotion' => 'ENABLE',
         },
         'Host1ToHost2Vmotion' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'priority' => 'high',
            'vmotion' => 'oneway',
            'dsthost' => 'host.[2]',
         },
         'Host2ToHost1Vmotion' => {
            'Type' => 'VM',
            'TestVM' => 'vm.[1]',
            'priority' => 'high',
            'vmotion' => 'oneway',
            'dsthost' => 'host.[1]',
         },
         'RemoveUplinkIPOnHost1' => {
            Type        => "Switch",
            TestSwitch  => "host.[1].ovs.[1]",
            vmnicadapter => "host.[1].vmnic.[1]",
            configureuplinks => "edit",
            ipv4address => "none",
         },
         'RemoveUplinkIPOnHost2' => {
            Type        => "Switch",
            TestSwitch  => "host.[2].ovs.[1]",
            vmnicadapter => "host.[2].vmnic.[1]",
            configureuplinks => "edit",
            ipv4address => "none",
         },
         'RemoveUplinkOnHost1' => {
            Type        => "Switch",
            TestSwitch  => "host.[1].ovs.[1]",
            vmnicadapter => "host.[1].vmnic.[1]",
            configureuplinks => "remove",
         },
         'RemoveUplinkOnHost2' => {
            Type        => "Switch",
            TestSwitch  => "host.[2].ovs.[1]",
            vmnicadapter => "host.[2].vmnic.[1]",
            configureuplinks => "remove",
         },
         'AddUplinkOnHost1' => {
            Type        => "Switch",
            TestSwitch  => "host.[1].ovs.[1]",
            vmnicadapter => "host.[1].vmnic.[1]",
            configureuplinks => "add",
         },
         'AddUplinkOnHost2' => {
            Type        => "Switch",
            TestSwitch  => "host.[2].ovs.[1]",
            vmnicadapter => "host.[2].vmnic.[1]",
            configureuplinks => "add",
         },
         'EditUplinkOnHost1' => {
            Type        => "Switch",
            TestSwitch  => "host.[1].ovs.[1]",
            vmnicadapter => "host.[1].vmnic.[1]",
            configureuplinks => "edit",
            ipv4address => "dhcp",
         },
         'EditUplinkOnHost2' => {
            Type        => "Switch",
            TestSwitch  => "host.[2].ovs.[1]",
            vmnicadapter => "host.[2].vmnic.[1]",
            configureuplinks => "edit",
            ipv4address => "dhcp",
         },
         SetController => {
            Type  =>"Switch",
            TestSwitch => "host.[1-2].ovs.[1]",
            ConfigureController => "set",
            controller => "nvpcontroller.[1]"
         },
         "CreateTZ" => {
            Type          => "NSX",
            TestNSX       => "nvpcontroller.[1]",
            transportzone => {
               '[1]' =>  {
                  name      => "tz_1",
                  transport_zone_type   => "stt",
                  metadata => {
                     expectedresultcode => "201",
                     keyundertest => "display_name",
                     expectedvalue => "tz_1"
                  },
               },
            },
         },
         "CreateTN1" => {
            Type          => "NSX",
            TestNSX       => "nvpcontroller.[1]",
            'sleepbetweencombos' => '10',
            transportnode  => {
               '[1]' => {
                  name => "Host1",
                  credential  =>  {
                     mgmtaddress   => "host.[1]",
                     type          => "MgmtAddrCredential",
                  },
                  transport_connectors  => [
                     {
                        transport_zone_uuid => "nvpcontroller.[1].transportzone.[1]",
                        ip_address => "host.[1].vmnic.[1]",
                        type => "STTConnector",
                     },
                  ],
                  integration_bridge_id  => "br-int",
               },
            },
         },
         "CreateTN2" => {
            Type          => "NSX",
            TestNSX       => "nvpcontroller.[1]",
            transportnode  => {
               '[2]' => {
                  name => "Host2",
                  credential  =>  {
                     mgmtaddress  => "host.[2]",
                     type         => "MgmtAddrCredential",
                  },
                  transport_connectors  => [
                     {
                        transport_zone_uuid => "nvpcontroller.[1].transportzone.[1]",
                        ip_address => "host.[2].vmnic.[1]",
                        type => "STTConnector",
                     },
                  ],
                  integration_bridge_id  => "br-int",
               },
            },
         },
         "CreateLS" => {
            Type          => "NSX",
            TestNSX       => "nvpcontroller.[1]",
            logicalswitch  => {
               '[1]' => {
                  transportzones => [
                     {
                        'zone_uuid' => "nvpcontroller.[1].transportzone.[1]",
                        'transport_type' => 'stt',
                     },
                  ],
                  replicationmode => "source",
                  name      => "ls_1",
                  metadata => {
                     expectedresultcode => "201",
                     keyundertest => "display_name",
                     expectedvalue => "ls_1"
                  },
               }
            },
         },
         "CreateLP1"  => {
            Type  => "Switch",
            TestSwitch  => "nvpcontroller.[1].logicalswitch.[1]",
            logicalport => {
               '[1]' => {
                  name  => "lp_1",
                  metadata => {
                     expectedresultcode => "201",
                     keyundertest => "display_name",
                     expectedvalue => "lp_1"
                  },
                   attachment  => {
                      type  => 'VifAttachment',
                      vifuuid => "vm.[1].vnic.[1]",
                   },
               },
            },
         },
         "CreateLP2"  => {
            Type  => "Switch",
            TestSwitch  => "nvpcontroller.[1].logicalswitch.[1]",
            logicalport => {
               '[1]' => {
                  name  => "lp_2",
                  metadata => {
                     expectedresultcode => "201",
                     keyundertest => "display_name",
                     expectedvalue => "lp_2"
                  },
                   attachment  => {
                      type  => 'VifAttachment',
                      vifuuid => "vm.[2].vnic.[1]",
                   },
               },
            },
         },
         "CleanupNVP"  => {
            Type  => "NSX",
            TestNSX  => "nvpcontroller.[1]",
            deletetransportzone => "nvpcontroller.[1].transportzone.[1]",
            deletetransportnode => "nvpcontroller.[1].transportnode.[1-2]",
            deletelogicalswitch  => "nvpcontroller.[1].logicalswitch.[1]"
         },
      },
   },
   'VSMPreCheckIn' => {
      Category         => 'NSX',
      Component        => 'network vDR',
      TestName         => "VSMPreCheckIn",
      Version          => "2" ,
      Tags             => "RunOnCAT",
      Summary          => "This is the vdr datapath sanity testcase ",
      TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_FourDVPG_ThreeHost_ThreeVM,
      'WORKLOADS' => {
         Sequence => [
                      ['SetSegmentIDRange'],
                      ['SetMulticastRange'],
                      ['DeployFirstController'],
                      ['Install_Configure_ClusterSJC'],
                      ['CreateNetworkScope'],
                      ['CreateVirtualWires'],

                      ########   Same Host   ########
                      # VXLAN test - VMs on same vWire
                      ['AddvNICsOnVMs'],
                      ['PoweronVM1','PoweronVM2'],
                      ['MakeSurevNICConnected'],
                      ['SetVXLANIPVM1','SetVXLANIPVM2SamevWire'],
                      ['PingTest'],
                      ['NetperfTestIgnorethroughput'],

                      ['DeployEdge'],
                      ['CreateVXLANLIF1'],
                      ['CreateVXLANLIF2'],
                      ['CreateVLANLIF3'],
                      ['CreateVLANLIF4'],
                      ['BridgevWire3ToVLAN21'],

                      # VDR test - VXLAN to VXLAN rotuing
                      ['PlaceVM1OnvWire1','PlaceVM2OnvWire2'],
                      ['SetVXLANIPVM1','SetVXLANIPVM2'],
                      ['AddVXLANRouteVM1','AddVXLANRouteVM2'],
                      ['PingTest'],
                      ['NetperfTestIgnorethroughput'],

                      # VDR test - VLAN to VLAN rotuing
                      ['PlaceVM1OnVLAN16','PlaceVM2OnVLAN17'],
                      ['SetVLANIPVM1','SetVLANIPVM2'],
                      ['AddVLANRouteVM1','AddVLANRouteVM2'],
                      ['PingTest'],
                      ['NetperfTestIgnorethroughput'],

                      # VDR test - VXLAN to VLAN rotuing
                      ['PlaceVM1OnvWire1','PlaceVM2OnVLAN17'],
                      ['SetVXLANIPVM1','SetVLANIPVM2'],
                      ['AddVXLANRouteVM1','AddVLANRouteVM2'],
                      ['PingTest'],
                      ['NetperfTestIgnorethroughput'],

                      # VDR test - VLAN to VXLAN rotuing
                      ['PlaceVM2OnvWire2','PlaceVM1OnVLAN16'],
                      ['SetVLANIPVM1','SetVXLANIPVM2'],
                      ['AddVLANRouteVM1','AddVXLANRouteVM2'],
                      ['PingTest'],
                      ['NetperfTestIgnorethroughput'],

                      # VDR test - Briding
                      ['PlaceVM1OnvWire3','PlaceVM2OnVLAN21'],
                      ['SetVXLANBridgeIPVM1','SetVLANBridgeIPVM2'],
                      ['PingTest'],
                      ['NetperfTestIgnorethroughput'],

                      ########   Different Host   ########
                      ['PoweronVM3'],
                      # VXLAN test - VMs on same vWire
                      ['PlaceVM1OnvWire1','PlaceVM3OnvWire1'],
                      ['SetVXLANIPVM1','SetVXLANIPVM3SamevWire'],
                      ['PingTestDifferentHost'],
                      ['NetperfTestDifferentHostIgnoreThroughput'],

                      # VDR test - VXLAN to VXLAN rotuing
                      ['PlaceVM1OnvWire1','PlaceVM3OnvWire2'],
                      ['SetVXLANIPVM1','SetVXLANIPVM3'],
                      ['AddVXLANRouteVM1','AddVXLANRouteVM3'],
                      ['PingTestDifferentHost'],
                      ['NetperfTestDifferentHostIgnoreThroughput'],

                      # VDR test - VLAN to VLAN rotuing
                      ['PlaceVM1OnVLAN16','PlaceVM3OnVLAN17'],
                      ['SetVLANIPVM1','SetVLANIPVM3'],
                      ['AddVLANRouteVM1','AddVLANRouteVM3'],
                      ['PingTestDifferentHost'],
                      ['NetperfTestDifferentHostIgnoreThroughput'],

                      # VDR test - VXLAN to VLAN rotuing
                      ['PlaceVM1OnvWire1','PlaceVM3OnVLAN17'],
                      ['SetVXLANIPVM1','SetVLANIPVM3'],
                      ['AddVXLANRouteVM1','AddVLANRouteVM3'],
                      ['PingTestDifferentHost'],
                      ['NetperfTestDifferentHostIgnoreThroughput'],

                      # VDR test - VLAN to VXLAN rotuing
                      ['PlaceVM3OnvWire2','PlaceVM1OnVLAN16'],
                      ['SetVLANIPVM1','SetVXLANIPVM3'],
                      ['AddVLANRouteVM1','AddVXLANRouteVM3'],
                      ['PingTestDifferentHost'],
                      ['NetperfTestDifferentHostIgnoreThroughput'],

                      # VDR test - Briding
                      ['PlaceVM1OnvWire3'],
                      ['PlaceVM3OnVLAN21'],
                      ['SetVXLANBridgeIPVM1','SetVLANBridgeIPVM3'],
                      ['PingTestDifferentHost'],
                      ['NetperfTestDifferentHostIgnoreThroughput'],
                     ],
         'SetSegmentIDRange' => SET_SEGMENTID_RANGE,
         'SetMulticastRange' => SET_MULTICAST_RANGE,
         "DeployFirstController" => DEPLOY_FIRSTCONTROLLER,
         'DeleteController' => DELETE_ALL_CONTROLLERS,
         'DeleteNetworkScope' => DELETE_ALL_NETWORKSCOPES,
         'Install_Configure_ClusterSJC' => INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC_VDS1,
         'PlaceVM1OnvWire1' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
         },
         'PlaceVM2OnvWire2' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[2].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
         },
         'PlaceVM3OnvWire2' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
         },
         'PlaceVM3OnvWire1' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
         },
         'PlaceVM1OnvWire3' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[3]",
         },
         'PlaceVM3OnvWire3' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[3]",
         },
         'PlaceVM1OnVLAN16' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[2]",
         },
         'PlaceVM2OnVLAN17' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[2].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[3]",
         },
         'PlaceVM3OnVLAN17' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[3]",
         },
         'PlaceVM2OnVLAN21' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[2].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[4]",
         },
         'PlaceVM3OnVLAN21' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[4]",
         },
         'PlaceVMsOnMgmtdvPG' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1-3].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[1]",
         },
         "DeployEdge"   => {
            Type    => "NSX",
            TestNSX => "vsm.[1]",
            vse => {
               '[1]' => {
                  name          => "Edge-$$",
                  resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                  datacenter    => "vc.[1].datacenter.[1]",
                  host          => "host.[2]", # To pick datastore
                  portgroup     => "vc.[1].dvportgroup.[1]",
               },
            },
         },
         "DeleteEdges" => DELETE_ALL_EDGES,
         'CreateVXLANLIF1' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[1]'   => {
                  name        => "lif-vwire1-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.31.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF2' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[2]'   => {
                  name        => "lif-vwire2-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.32.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVLANLIF3' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[3]'   => {
                  name        => "lif-16-$$",
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.16.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVLANLIF4' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[4]'   => {
                  name        => "lif-17-$$",
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.17.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'BridgevWire3ToVLAN21' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            bridge => {
               '[1]'   => {
                  name        => "bridge-1-$$",
                  virtualwire => "vsm.[1].networkscope.[1].virtualwire.[3]",
                  portgroup   => "vc.[1].dvportgroup.[4]",
               },
            },
         },
         "SetVLANIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "SetVLANIPVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "SetVLANIPVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "AddVLANRouteVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.17.0.0,172.31.0.0,172.32.0.0",
            gateway    => "172.16.1.1",
         },
         "AddVLANRouteVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.16.0.0,172.31.0.0,172.32.0.0",
            gateway    => "172.17.1.1",
         },
         "AddVLANRouteVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.16.0.0,172.31.0.0,172.32.0.0",
            gateway    => "172.17.1.1",
         },
         "SetVXLANIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => '172.31.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => '172.32.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM3SamevWire" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => '172.31.1.15',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM2SamevWire" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => '172.31.1.6',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => '172.32.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANBridgeIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => '172.21.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVLANBridgeIPVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "SetVLANBridgeIPVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "AddVXLANRouteVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.32.0.0,172.16.0.0,172.17.0.0",
            gateway    => "172.31.1.1",
         },
         "AddVXLANRouteVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.31.0.0,172.16.0.0,172.17.0.0",
            gateway    => "172.32.1.1",
         },
         "AddVXLANRouteVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.31.0.0,172.16.0.0,172.17.0.0",
            gateway    => "172.32.1.1",
         },
         "SamevWireNetperfTestDifferentHost" => {
            Type           => "Traffic",
            maxtimeout     => "128000",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[3].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound   => 1,
            l3protocol    => "ipv4,ipv6",
            l4protocol    => "tcp,udp",
            TestDuration   => "60",
            # Test might run on vESX also
            MinExpResult   => "1",
         },
         "PingTestDifferentHost" => {
            Type           => "Traffic",
            maxtimeout     => "128000",
            ToolName       => "Ping",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[3].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            TestDuration   => "120",
         },
         "PingTest" => {
            Type           => "Traffic",
            maxtimeout     => "128000",
            ToolName       => "Ping",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            TestDuration   => "60",
         },
         "NetperfTestIgnorethroughput" => {
            Type           => "Traffic",
            ToolName       => "netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1]",
            NoofOutbound   => 1,
            TestDuration   => "60",
            ExpectedResult => "ignore",
         },
         "NetperfTestDifferentHostIgnoreThroughput" => {
            Type           => "Traffic",
            ToolName       => "Ping",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[3].vnic.[1]",
            NoofOutbound   => 1,
            TestDuration   => "120",
            # Test might run on vESX also
            ExpectedResult => "ignore",
         },
         'PoweronVM1' => {
            Type    => "VM",
            TestVM  => "vm.[1]",
            vmstate => "poweron",
         },
         'PoweronVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweron",
         },
         'PoweronVM3' => {
            Type    => "VM",
            TestVM  => "vm.[3]",
            vmstate => "poweron",
         },
         'PoweroffVM1' => {
            Type    => "VM",
            TestVM  => "vm.[1]",
            vmstate => "poweroff",
         },
         'PoweroffVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweroff",
         },
         'PoweroffVM3' => {
            Type    => "VM",
            TestVM  => "vm.[3]",
            vmstate => "poweroff",
         },
         'PoweroffVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweroff",
         },
         'AddvNICsOnVMs' => {
            Type   => "VM",
            TestVM => "vm.[1],vm.[2],vm.[3]",
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
         'MakeSurevNICConnected' => {
            Type           => "NetAdapter",
            reconfigure    => "true",
            testadapter    => "vm.[1-2].vnic.[1]",
            connected      => 1,
            startconnected => 1,
         },
         'RemovevNICFromVM1' => {
            Type       => "VM",
            TestVM     => "vm.[1]",
            deletevnic => "vm.[1].vnic.[1]",
         },
         'RemovevNICFromVM2' => {
            Type       => "VM",
            TestVM     => "vm.[2]",
            deletevnic => "vm.[2].vnic.[1]",
         },
         'RemovevNICFromVM3' => {
            Type       => "VM",
            TestVM     => "vm.[3]",
            deletevnic => "vm.[3].vnic.[1]",
         },
         'PlaceVM2OnMgmtdvpg' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[2].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[1]",
         },
         'CreateNetworkScope' => CREATE_NETWORKSCOPE_ClusterSJC,
         'CreateVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            VirtualWire       => {
               "[1]" => {
                  name               => "AutoGenerate",
                  tenantid           => "1",
               },
               "[2]" => {
                  name               => "AutoGenerate",
                  tenantid           => "2",
               },
               "[3]" => {
                  name               => "AutoGenerate",
                  tenantid           => "3",
               },
            },
         },
         'GetVirtualWireID' => {
            Type            => "Switch",
            FindType            => "Switch",
            testvirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
         },
         'DeleteVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-3]",
         },
         'UnconfigureVXLAN' => {
            Type             => 'Cluster',
            testcluster      => "vsm.[1].vdncluster.[1]",
            vxlan            => "unconfigure",
         },
      },
   },
);
}


########################################################################
#
# new --
#       This is the constructor for PreCheckInTds
#
# Input:
#       none
#
# Results:
#       An instance/object of PreCheckInTds class
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
   my $self = $class->SUPER::new(\%PreCheckInTds);
   return (bless($self, $class));
}

1;

