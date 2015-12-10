#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::Networking::VirtualRouting::StressTds;

#
# This file contains the structured hash for VDR Stress cases.
# The following lines explain the keys of the internal
# hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
@ISA = qw(TDS::Main::VDNetMainTds);

# Test constants
use constant TRAFFIC_TESTDURATION => "120";
use constant STRESS_ITERATIONS => "1";

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';

{
   %Stress = (
      'DeployVDREdgeStress' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "DeployVDREdgeStress",
         Tags             => "RunOnCAT,stress",
         Version          => "2" ,
         Summary          => "Stress by deploying & deleting VDR Edges ",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_TwoHost_TwoCluster,
         'WORKLOADS' => {
            Sequence => [
                         ['SetSegmentIDRange'],
                         ['SetMulticastRange'],
                         ['DeployFirstController'],
                         ['ConfigureVXLAN_ClusterSJC'],
                         ['CreateNetworkScope'],
                         ['DeployDeleteEdgeStress'],
                        ],

            'SetSegmentIDRange'    => SET_SEGMENTID_RANGE,
            'SetMulticastRange'    => SET_MULTICAST_RANGE,
            "DeployFirstController"=> DEPLOY_FIRSTCONTROLLER,
            'ConfigureVXLAN_ClusterSJC' => INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC_VDS1,
            'CreateNetworkScope'   => CREATE_NETWORKSCOPE_ClusterSJC,
            "DeployDeleteEdgeStress"   => {
               Type        => "NSX",
               TestNSX     => "vsm.[1]",
               Iterations  => STRESS_ITERATIONS,
               runworkload => "DeleteEdges",
               vse => {
                  '[1]' => {
                     name          => "Edge-$$",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[1]",
                  },
               },
            },
            'DeleteEdges' => DELETE_ALL_EDGES,
         },
      },
      'LIFAddDeleteStress' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "LIFAddDeleteStress",
         Tags             => "RunOnCAT",
         Version          => "2" ,
         Summary          => "Stress by addition and deletion of LIFs",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_TwoHost_TwoCluster,
         'WORKLOADS' => {
            Sequence => [
                         ['SetSegmentIDRange'],
                         ['SetMulticastRange'],
                         ['DeployFirstController'],
                         ['InstallVIBs_And_ConfigureVXLAN'],
                         ['CreateNetworkScope'],
                         ['DeployEdge'],
                         ['CreateVirtualWires'],
                         ['CreateDelete100VXLANLIFStress'],
                        ],

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
                     primaryaddress => "10.10.10.60",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'CreateNetworkScope' => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1-$$",
                     clusters     => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'InstallVIBs_And_ConfigureVXLAN' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     vibs         => "install",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => "19",
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "ETHER_CHANNEL",
                  },
               },
            },
            "DeployFirstController"   => {
               Type       => "NSX",
               TestNSX    => "vsm.[1]",
               vxlancontroller  => {
                  '[1]' => {
                     name         => "AutoGenerate",
                     firstnodeofcluster => "true",
                     ippool       => "vsm.[1].ippool.[1]",
                     resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
                     host         => "host.[1]",
                  },
               },
            },
            'SetSegmentIDRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               # PR 1069737
               sleepbetweenworkloads => "10",
               Segmentidrange => {
                  '[1]' => {
                     name  => "segmentid-range-$$",
                     begin => "10000",
                     end   => "99000",
                  },
               },
            },
            'SetMulticastRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               Multicastiprange => {
                  '[1]' => {
                     name  => "multicastip-range-$$",
                     begin => "239.0.0.100",
                     end   => "239.254.254.254",
                  },
               },
            },
            'CreateVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               maxtimeout        => "128000",
               VirtualWire       => {
                  "[1-10]" => {
                     name               => "AutoGenerate",
                     tenantid           => "AutoGenerate",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[-1]",
            },
            'CreateDelete100VXLANLIFStress' => {
               Type        => "VM",
               TestVM      => "vsm.[1].vse.[1]",
               Iterations  => STRESS_ITERATIONS,
               maxtimeout  => "108000",
               lif => {
                  '[1-10]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[x]",
                     type        => "internal",
                     connected   => 1,
                  },
               },
               runworkload => "DeleteLIFs",
            },
            'DeleteLIFs' => {
               Type      => "VM",
               TestVM    => "vsm.[1].vse.[1]",
               deletelif => "vsm.[1].vse.[1].lif.[-1]",
            },
         },
      },
      'VirtualWireAddDeleteStress' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "VirtualWireAddDeleteStress",
         Tags             => "RunOnCAT",
         Version          => "2" ,
         Summary          => "Stress by adding and deleting Virtual Wires",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_TwoHost_TwoCluster,
         'WORKLOADS' => {
            Sequence => [
                         ['SetSegmentIDRange'],
                         ['SetMulticastRange'],
                         ['DeployFirstController'],
                         ['InstallVIBs_And_ConfigureVXLAN'],
                         ['CreateNetworkScope'],
                         ['CreateDeleteVirtualWireStress'],
                        ],

            'CreateNetworkScope' => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1-$$",
                     clusters     => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'InstallVIBs_And_ConfigureVXLAN' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     vibs         => "install",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => "19",
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "ETHER_CHANNEL",
                  },
               },
            },
            "DeployFirstController"   => {
               Type       => "NSX",
               TestNSX    => "vsm.[1]",
               vxlancontroller  => {
                  '[1]' => {
                     name         => "AutoGenerate",
                     firstnodeofcluster => "true",
                     ippool       => "vsm.[1].ippool.[1]",
                     resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
                     host         => "host.[1]",
                  },
               },
            },
            'SetSegmentIDRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               # PR 1069737
               sleepbetweenworkloads => "10",
               Segmentidrange => {
                  '[1]' => {
                     name  => "segmentid-range-$$",
                     begin => "10000",
                     end   => "99000",
                  },
               },
            },
            'SetMulticastRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               Multicastiprange => {
                  '[1]' => {
                     name  => "multicastip-range-$$",
                     begin => "239.0.0.100",
                     end   => "239.254.254.254",
                  },
               },
            },
            'CreateDeleteVirtualWireStress' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               maxtimeout        => "128000",
               Iterations        => STRESS_ITERATIONS,
               runworkload       => "DeleteVirtualWires",
               VirtualWire       => {
                  "[1-5]" => {
                     name               => "AutoGenerate",
                     tenantid           => "AutoGenerate",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[-1]",
            },
         },
      },
      'ControllerDeploymentStress' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "DeployFirstController",
         Version          => "2" ,
         Tags             => "stress",
         Summary          => "Stress by deploying vxlan controllers",
         'TestbedSpec' => {
            'vsm' => {
               '[1]' => {
                  reconfigure => "true",
                  vc          => 'vc.[1]',
                  assignrole => "enterprise_admin",
                  ippool   => {
                     '[1]' => {
                        name         => "AutoGenerate",
                        gateway      => "x.x.x.x",
                        prefixlength => "xx",
                        ipranges     => ['a.a.a.a-b.b.b.b'],
                     },
                  },
               },
            },
            'host' => {
               '[1]'  => {
               },
            },
            'vc' => {
               '[1]' => {
                  datacenter  => {
                     '[1]'   => {
                        Cluster => {
                           '[1]' => {
                              host => "host.[1]",
                              name => "Controller-Cluster-$$",
                           },
                        },
                     },
                  },
               },
            },
         },
         'WORKLOADS' => {
            Iterations => STRESS_ITERATIONS,
            'Sequence' => [
                           ['DeployController'],
                           ['DeleteController'],
                          ],

            'DeleteIPPool' => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               sleepbetweenworkloads => "10",
               deleteippool => "vsm.[1].ippool.[1]",
            },
            "DeployController"   => {
               Type       => "NSX",
               TestNSX    => "vsm.[1]",
               vxlancontroller  => {
                  '[1]' => {
                     name         => "AutoGenerate",
                     firstnodeofcluster => "true",
                     ippool       => "vsm.[1].ippool.[1]",
                     resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
                     host         => "host.[1]",
                  },
               },
            },
            "DeleteController"   => {
               Type  => "NSX",
               TestNSX  => "vsm.[1]",
               sleepbetweenworkloads => "60",
               deletevxlancontroller => "vsm.[1].vxlancontroller.[1]",
            },
         },
      },
     'VxlanConfigureUnconfigureStress' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "PylibPreCheckin",
         Version          => "2" ,
         Tags             => "stress",
         Summary          => "Stress by VXLAN Configure and Unconfigure",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_FourDVPG_ThreeHost_ThreeVM,
         'WORKLOADS' => {
            Sequence => [
		         # AllTeamingPoliciesWithMoreThan1Uplink-PR1110168
		         # PR1110168 is deferred TrinityFebUpdate release
			 # ['AddUplink2ToHost2andHost3'],
                         ['SetSegmentIDRange'],
                         ['SetMulticastRange'],
                         ['DeployFirstController'],

                         # EtherChannel
                         ['ConfigureVXLAN_Etherchannel'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                         ['AddvNICsOnVMs'],
                         ['PoweronVM1','PoweronVM2','PoweronVM3'],
                         ['MakeSurevNICConnected'],
                         ['DeployEdge'],
                         ['CreateVXLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['CreateVLANLIF3'],
                         ['CreateVLANLIF4'],
                         ['BridgevWire3ToVLAN21'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnvWire1'],
                         ['SetVXLANIPVM1','SetVXLANIPVM3SamevWire'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnvWire2'],
                         ['SetVXLANIPVM1','SetVXLANIPVM3'],
                         ['AddVXLANRouteVM1','AddVXLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnVLAN16','PlaceVM3OnVLAN17'],
                         ['SetVLANIPVM1','SetVLANIPVM3'],
                         ['AddVLANRouteVM1','AddVLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnVLAN17'],
                         ['SetVXLANIPVM1','SetVLANIPVM3'],
                         ['AddVXLANRouteVM1','AddVLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM3OnvWire2','PlaceVM1OnVLAN16'],
                         ['SetVLANIPVM1','SetVXLANIPVM3'],
                         ['AddVLANRouteVM1','AddVXLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire3'],
                         ['PlaceVM3OnVLAN21'],
                         ['SetVXLANBridgeIPVM1','SetVLANBridgeIPVM3'],
                         ['PingTestDifferentHost'],
			 ['RemovevNICFromVM1','RemovevNICFromVM2','RemovevNICFromVM3'],
                         ['DeleteEdges'],
                         ['DeleteVirtualWires'],
                         ['DeleteNetworkScope'],
                         ['UnconfigureVXLAN'],
                         # Failover
                         ['ConfigureVXLAN_Failover'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                         ['AddvNICsOnVMs'],
                         ['PoweronVM1','PoweronVM2','PoweronVM3'],
                         ['MakeSurevNICConnected'],
                         ['DeployEdge'],
                         ['CreateVXLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['CreateVLANLIF3'],
                         ['CreateVLANLIF4'],
                         ['BridgevWire3ToVLAN21'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnvWire1'],
                         ['SetVXLANIPVM1','SetVXLANIPVM3SamevWire'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnvWire2'],
                         ['SetVXLANIPVM1','SetVXLANIPVM3'],
                         ['AddVXLANRouteVM1','AddVXLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnVLAN16','PlaceVM3OnVLAN17'],
                         ['SetVLANIPVM1','SetVLANIPVM3'],
                         ['AddVLANRouteVM1','AddVLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnVLAN17'],
                         ['SetVXLANIPVM1','SetVLANIPVM3'],
                         ['AddVXLANRouteVM1','AddVLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM3OnvWire2','PlaceVM1OnVLAN16'],
                         ['SetVLANIPVM1','SetVXLANIPVM3'],
                         ['AddVLANRouteVM1','AddVXLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire3'],
                         ['PlaceVM3OnVLAN21'],
                         ['SetVXLANBridgeIPVM1','SetVLANBridgeIPVM3'],
                         ['PingTestDifferentHost'],
			 ['RemovevNICFromVM1','RemovevNICFromVM2','RemovevNICFromVM3'],
                         ['DeleteEdges'],
                         ['DeleteVirtualWires'],
                         ['DeleteNetworkScope'],
                         ['UnconfigureVXLAN'],
                         # LoadBalance - srcid
                         ['ConfigureVXLAN_LOADBALANCE_SRCID'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                         ['AddvNICsOnVMs'],
                         ['PoweronVM1','PoweronVM2','PoweronVM3'],
                         ['MakeSurevNICConnected'],
                         ['DeployEdge'],
                         ['CreateVXLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['CreateVLANLIF3'],
                         ['CreateVLANLIF4'],
                         ['BridgevWire3ToVLAN21'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnvWire1'],
                         ['SetVXLANIPVM1','SetVXLANIPVM3SamevWire'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnvWire2'],
                         ['SetVXLANIPVM1','SetVXLANIPVM3'],
                         ['AddVXLANRouteVM1','AddVXLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnVLAN16','PlaceVM3OnVLAN17'],
                         ['SetVLANIPVM1','SetVLANIPVM3'],
                         ['AddVLANRouteVM1','AddVLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnVLAN17'],
                         ['SetVXLANIPVM1','SetVLANIPVM3'],
                         ['AddVXLANRouteVM1','AddVLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM3OnvWire2','PlaceVM1OnVLAN16'],
                         ['SetVLANIPVM1','SetVXLANIPVM3'],
                         ['AddVLANRouteVM1','AddVXLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire3'],
                         ['PlaceVM3OnVLAN21'],
                         ['SetVXLANBridgeIPVM1','SetVLANBridgeIPVM3'],
                         ['PingTestDifferentHost'],
			 ['RemovevNICFromVM1','RemovevNICFromVM2','RemovevNICFromVM3'],
                         ['DeleteEdges'],
                         ['DeleteVirtualWires'],
                         ['DeleteNetworkScope'],
                         ['UnconfigureVXLAN'],
                         # LoadBalance - srcmac
                         ['ConfigureVXLAN_LOADBALANCE_SRCMAC'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                         ['AddvNICsOnVMs'],
                         ['PoweronVM1','PoweronVM2','PoweronVM3'],
                         ['MakeSurevNICConnected'],
                         ['DeployEdge'],
                         ['CreateVXLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['CreateVLANLIF3'],
                         ['CreateVLANLIF4'],
                         ['BridgevWire3ToVLAN21'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnvWire1'],
                         ['SetVXLANIPVM1','SetVXLANIPVM3SamevWire'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnvWire2'],
                         ['SetVXLANIPVM1','SetVXLANIPVM3'],
                         ['AddVXLANRouteVM1','AddVXLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnVLAN16','PlaceVM3OnVLAN17'],
                         ['SetVLANIPVM1','SetVLANIPVM3'],
                         ['AddVLANRouteVM1','AddVLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire1','PlaceVM3OnVLAN17'],
                         ['SetVXLANIPVM1','SetVLANIPVM3'],
                         ['AddVXLANRouteVM1','AddVLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM3OnvWire2','PlaceVM1OnVLAN16'],
                         ['SetVLANIPVM1','SetVXLANIPVM3'],
                         ['AddVLANRouteVM1','AddVXLANRouteVM3'],
                         ['PingTestDifferentHost'],
                         ['PlaceVM1OnvWire3'],
                         ['PlaceVM3OnVLAN21'],
                         ['SetVXLANBridgeIPVM1','SetVLANBridgeIPVM3'],
                         ['PingTestDifferentHost'],
			 ['RemovevNICFromVM1','RemovevNICFromVM2','RemovevNICFromVM3'],
                         ['DeleteEdges'],
                         ['DeleteVirtualWires'],
                         ['DeleteNetworkScope'],
                         ['UnconfigureVXLAN'],
                         ['ConfigureVXLAN_LACP_ACTIVE'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                         ['DeleteVirtualWires'],
                         ['DeleteNetworkScope'],
                         ['UnconfigureVXLAN'],
                         ['ConfigureVXLAN_LACP_PASSIVE'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                         ['DeleteVirtualWires'],
                         ['DeleteNetworkScope'],
                         ['UnconfigureVXLAN'],
                         ['ConfigureVXLAN_LACPV2'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                         ['DeleteVirtualWires'],
                         ['DeleteNetworkScope'],
                         ['UnconfigureVXLAN'],
                         ['ConfigureVXLAN_LOADBALANCE_LOADBASED'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                         # VXLAN test - VMs on same vWire
                         ['AddvNICsOnVMs'],
                         ['PoweronVM1','PoweronVM2','PoweronVM3'],
                         ['MakeSurevNICConnected'],

                         ['DeployEdge'],
                         ['CreateVXLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['CreateVLANLIF3'],
                         ['CreateVLANLIF4'],
                         ['BridgevWire3ToVLAN21'],

                         ########   Different Host   ########
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
            'SetSegmentIDRange'    => SET_SEGMENTID_RANGE,
            'SetMulticastRange'    => SET_MULTICAST_RANGE,
            "DeployFirstController"=> DEPLOY_FIRSTCONTROLLER,
            'CreateNetworkScope'   => CREATE_NETWORKSCOPE_ClusterSJC,
            'CreateVirtualWires'   => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
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
                     primaryaddress => "10.10.10.61",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            'DeleteEdges'          => DELETE_ALL_EDGES,
            "AddUplink2ToHost2andHost3" => {
                Type           => "Switch",
                numuplinkports => "2",
                TestSwitch     => "vc.[1].vds.[1]",
                configureuplinks=> "add",
                host           => "host.[2-3]",
                vmnicadapter   => "host.[2-3].vmnic.[1-2]",
            },
            'ConfigureVXLAN_LACPV2' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "LACP_V2",
                  },
               },
            },
            'ConfigureVXLAN_LACP_ACTIVE' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "LACP_ACTIVE",
                  },
               },
            },
            'ConfigureVXLAN_LOADBALANCE_SRCMAC' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "LOADBALANCE_SRCMAC",
                  },
               },
            },
            'ConfigureVXLAN_LOADBALANCE_SRCID' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "LOADBALANCE_SRCID",
                  },
               },
            },
            'ConfigureVXLAN_LOADBALANCE_LOADBASED' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "LOADBALANCE_LOADBASED",
                  },
               },
            },
            'ConfigureVXLAN_LACP_PASSIVE' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => "19",
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "LACP_PASSIVE",
                  },
               },
            },
            'ConfigureVXLAN_Failover' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => "19",
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "FAILOVER_ORDER",
                  },
               },
            },
            'ConfigureVXLAN_Etherchannel' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "ETHER_CHANNEL",
                  },
               },
            },
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
                     datastoretype => "shared",
                     primaryaddress => "10.10.10.62",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
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
               netmask    => "255.255.0.0",
            },
            "SetVLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => 'dhcp',
               netmask    => "255.255.0.0",
            },
            "SetVLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => 'dhcp',
               netmask    => "255.255.0.0",
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
               netmask    => "255.255.0.0",
            },
            "SetVLANBridgeIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => 'dhcp',
               netmask    => "255.255.0.0",
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
               #ToolName       => "Ping",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               NoofOutbound   => 1,
               NoofInbound   => 1,
               l3protocol    => "ipv4,ipv6",
               l4protocol    => "tcp,udp",
               TestDuration   => TRAFFIC_TESTDURATION,
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
               TestDuration   => TRAFFIC_TESTDURATION,
            },
            "PingTest" => {
               Type           => "Traffic",
               maxtimeout     => "128000",
               ToolName       => "Ping",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               NoofOutbound   => 1,
               NoofInbound    => 1,
               TestDuration   => TRAFFIC_TESTDURATION,
            },
            "NetperfTestIgnorethroughput" => {
               Type           => "Traffic",
               ToolName       => "netperf,iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               NoofOutbound   => 1,
               TestDuration   => TRAFFIC_TESTDURATION,
               ExpectedResult => "ignore",
               ParallelSession=> "yes",
            },
            "NetperfTestDifferentHostIgnoreThroughput" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               NoofOutbound   => 1,
               TestDuration   => TRAFFIC_TESTDURATION,
               # Test might run on vESX also
               ExpectedResult => "ignore",
            },
            'AddVmotionvmknics' => {
               Type         => "Host",
               TestHost     => "host.[2-3]",
               vmknic          => {
                  '[1]' => {
                     portgroup        => "vc.[1].dvportgroup.[1]",
                     configurevmotion => "enable",
                     ipv4             => "dhcp",
                  },
               },
            },
            "vMotionVM2ToHost3"       => {
               Type            => "VM",
               TestVM          => "vm.[2]",
               Iterations      => "1",
               vmotion         => "oneway",
               dsthost         => "host.[3]",
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
            'DeleteNetworkScope'  => {
               Type               => 'NSX',
               TestNSX            => "vsm.[1]",
               deletenetworkscope => "vsm.[1].networkscope.[-1]",
             },
            'DeleteVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[-1]",
            },
            'UnconfigureVXLAN' => {
               Type             => 'Cluster',
               testcluster      => "vsm.[1].vdncluster.[1]",
               vxlan            => "unconfigure",
            },
            'ConfigureVXLAN' => {
               Type         => 'Cluster',
               testcluster  => "vsm.[1].vdncluster.[1]",
               vxlan        => "unconfigure",
               cluster      => "vc.[1].datacenter.[1].cluster.[2]",
               vxlan        => "Configure",
               switch       => "vc.[1].vds.[1]",
               vlan         => "19",
               mtu          => "1600",
               vmkniccount  => "1",
               teaming      => "ETHER_CHANNEL",
            },
         },
      },
   );
}

##########################################################################
# new --
#       This is the constructor for VDR TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of VDR class
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
      my $self = $class->SUPER::new(\%Stress);
      return (bless($self, $class));
}

1;
