#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Neutron::NeutronLSRTds;

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
use VDNetLib::TestData::TestConstants;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec qw($OneNeutron_TwovSphere_TwoESX_TwoVsm_functional);

# Import Workloads which are very common across all tests
use TDS::NSX::Neutron::CommonWorkloads ':AllConstants';

#
# Begin test cases
#
{
   %Neutron = (
      'DeploySmallSizeLSR' => {
         Component         => "Deployment",
         Category          => "Service Node",
         TestName          => "DeploySmallSizeLSR",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case deploys small size Logical Services Router of Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_TwovSphere_TwoESX_TwoVsm_functional,
         WORKLOADS => {
            Sequence     => [
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
                                ["InitDatastoreOnHost1"],
                                ["InitDatastoreOnHost2"],
                                ["DeploymentContainer1Creation"],
                                ["DeploymentContainer2Creation"],
                                ["LogicalServicesNode"],
                                ["LogicalServicesNodeInterface"],
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchPortCreation"],
                                ["VerifyLogicalServicesNode"],
                                ["VerifyLogicalServicesNodeInterface"],
                            ],
            ExitSequence => [
                                ["DetachLogicalSwitchPort"],
                                ["DeleteLogicalSwitchPort"],
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
                                ["DeleteLogicalServicesNode"],
                                ["DeleteDeploymentContainer1"],
                                ["DeleteDeploymentContainer2"],
                                ["DeleteSegmentRange"],
                                ["DeleteMulticastRange"],
                            ],
            "SegmentRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               segmentidrange => {
                  '[1]' =>  {
                     name      => "seg-1",
                     begin     => "6501",
                     end       => "6600",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "MulticastRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               multicastiprange => {
                  '[1]' =>  {
                     name      => "mcast-1",
                     begin     => "224.0.26.1",
                     end       => "224.0.30.1",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "InitDatastoreOnHost1" => INIT_DATASTORE_1,
            "InitDatastoreOnHost2" => INIT_DATASTORE_2,
            "DeploymentContainer1Creation" => DEPLOYMENT_CONTAINER_1_CREATION,
            "DeploymentContainer2Creation" => DEPLOYMENT_CONTAINER_2_CREATION,
            "LogicalServicesNode" => CREATE_LOGICAL_SERVICES_NODE,
            "VerifyLogicalServicesNode" => {
                Type         => "VM",
                TestVM      => "neutron.[1].logicalservicesnode.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "lsnode-1",
                   "capacity[?]equal_to" => "SMALL",
                   "dns_settings" => {
                      "domain_name[?]equal_to"   => 'node1',
                      "primary_dns[?]equal_to"   =>
                      VDNetLib::TestData::TestConstants::PRIMARY_DNS,,
                      "secondary_dns[?]equal_to" =>
                      VDNetLib::TestData::TestConstants::SECONDARY_DNS,
                   },
                },
            },
            "LogicalServicesNodeInterface" => CREATE_LOGICAL_SERVICES_NODE_INTERFACE,
            "VerifyLogicalServicesNodeInterface" => {
                Type            => "NetAdapter",
                TestAdapter  =>
                "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "intf-1",
                   "interface_number[?]equal_to" => 1,
                   "interface_type[?]equal_to" => "INTERNAL",
                   "interface_options" => {
                      "enable_send_redirects[?]boolean" => 0,
                      "enable_proxy_arp[?]boolean"  => 0,
                   },
                   "address_groups"  => [
                      {
                         "primary_ip_address[?]equal_to" =>
                         VDNetLib::TestData::TestConstants::PRIMARY_IP_ADDRESS,
                         "subnet[?]equal_to"             =>
                         VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                      },
                   ],
                },
            },
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => CREATE_LOGICAL_SWITCH_PORT,
            "DetachLogicalSwitchPort"   => {
               Type         => "Port",
               TestPort   => "neutron.[1].logicalswitch.[1].logicalswitchport.[1]",
               sleepbetweenworkloads => "600",
               reconfigure   => "True",
               attachment => {
                  "type"  => "NoAttachment",
               },
               metadata => {
                  expectedresultcode => "200",
               },
            },
            "DeleteLogicalServicesNode" => DELETE_LOGICAL_SERVICES_NODE,
            "DeleteDeploymentContainer1" => DELETE_DEPLOYMENT_CONTAINER_1,
            "DeleteDeploymentContainer2" => DELETE_DEPLOYMENT_CONTAINER_2,
            "DeleteLogicalSwitchPort" => DELETE_ALL_LOGICAL_SWITCH_PORT,
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
            "DeleteMulticastRange" => DELETE_ALL_MULTICAST_IP_RANGES,
         },
      },
      'DeployMediumSizeLSR' => {
         Component         => "Deployment",
         Category          => "Service Node",
         TestName          => "DeploySmallSizeLSR",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case deploys medium size Logical Services Router of Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_TwovSphere_TwoESX_TwoVsm_functional,
         WORKLOADS => {
            Sequence     => [
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
                                ["InitDatastoreOnHost1"],
                                ["InitDatastoreOnHost2"],
                                ["DeploymentContainer1Creation"],
                                ["DeploymentContainer2Creation"],
                                ["LogicalServicesNode"],
                                ["LogicalServicesNodeInterface"],
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchPortCreation"],
                                ["VerifyLogicalServicesNode"],
                                ["VerifyLogicalServicesNodeInterface"],
                            ],
            ExitSequence => [
                                ["DetachLogicalSwitchPort"],
                                ["DeleteLogicalSwitchPort"],
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
                                ["DeleteLogicalServicesNode"],
                                ["DeleteDeploymentContainer1"],
                                ["DeleteDeploymentContainer2"],
                                ["DeleteSegmentRange"],
                                ["DeleteMulticastRange"],
                            ],
            "SegmentRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               segmentidrange => {
                  '[1]' =>  {
                     name      => "seg-1",
                     begin     => "6601",
                     end       => "6700",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "MulticastRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               multicastiprange => {
                  '[1]' =>  {
                     name      => "mcast-1",
                     begin     => "224.0.31.1",
                     end       => "224.0.35.1",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "InitDatastoreOnHost1" => INIT_DATASTORE_1,
            "InitDatastoreOnHost2" => INIT_DATASTORE_2,
            "DeploymentContainer1Creation" => DEPLOYMENT_CONTAINER_1_CREATION,
            "DeploymentContainer2Creation" => DEPLOYMENT_CONTAINER_2_CREATION,
            "LogicalServicesNode" => {
               Type         => "NSX",
               TestNSX      => "neutron.[1]",
               logicalservicesnode  => {
                  '[1]' =>  {
                     name    => "lsnode-1",
                     capacity   => "MEDIUM",
                     dns_settings     => {
                        "domain_name"   => "node1",
                        "primary_dns[?]equal_to"   =>
                      VDNetLib::TestData::TestConstants::PRIMARY_DNS,,
                      "secondary_dns[?]equal_to" =>
                      VDNetLib::TestData::TestConstants::SECONDARY_DNS,
                     },
                  },
               },
            },
            "VerifyLogicalServicesNode" => {
                Type         => "VM",
                TestVM      => "neutron.[1].logicalservicesnode.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "lsnode-1",
                   "capacity[?]equal_to" => "MEDIUM",
                   "dns_settings" => {
                      "domain_name[?]equal_to"   => 'node1',
                      "primary_dns[?]equal_to"   =>
                      VDNetLib::TestData::TestConstants::PRIMARY_DNS,,
                      "secondary_dns[?]equal_to" =>
                      VDNetLib::TestData::TestConstants::SECONDARY_DNS,
                   },
                },
            },
            "LogicalServicesNodeInterface" => CREATE_LOGICAL_SERVICES_NODE_INTERFACE,
            "VerifyLogicalServicesNodeInterface" => {
                Type            => "NetAdapter",
                TestAdapter  =>
                "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "intf-1",
                   "interface_number[?]equal_to" => 1,
                   "interface_type[?]equal_to" => "INTERNAL",
                   "interface_options" => {
                      "enable_send_redirects[?]boolean" => 0,
                      "enable_proxy_arp[?]boolean"  => 0,
                   },
                   "address_groups"  => [
                      {
                         "primary_ip_address[?]equal_to" =>
                         VDNetLib::TestData::TestConstants::PRIMARY_IP_ADDRESS,
                         "subnet[?]equal_to"             =>
                         VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                      },
                   ],
                },
            },
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => CREATE_LOGICAL_SWITCH_PORT,
            "DetachLogicalSwitchPort"   => {
               Type         => "Port",
               TestPort   => "neutron.[1].logicalswitch.[1].logicalswitchport.[1]",
               sleepbetweenworkloads => "600",
               reconfigure   => "True",
               attachment => {
                  "type"  => "NoAttachment",
               },
               metadata => {
                  expectedresultcode => "200",
               },
            },
            "DeleteLogicalServicesNode" => DELETE_LOGICAL_SERVICES_NODE,
            "DeleteDeploymentContainer1" => DELETE_DEPLOYMENT_CONTAINER_1,
            "DeleteDeploymentContainer2" => DELETE_DEPLOYMENT_CONTAINER_2,
            "DeleteLogicalSwitchPort" => DELETE_ALL_LOGICAL_SWITCH_PORT,
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
            "DeleteMulticastRange" => DELETE_ALL_MULTICAST_IP_RANGES,
         },
      },
      'DeployLargeSizeLSR' => {
         Component         => "Deployment",
         Category          => "Service Node",
         TestName          => "DeployLargeSizeLSR",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case deploys large size Logical Services Router of Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_TwovSphere_TwoESX_TwoVsm_functional,
         WORKLOADS => {
            Sequence     => [
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
                                ["InitDatastoreOnHost1"],
                                ["InitDatastoreOnHost2"],
                                ["DeploymentContainer1Creation"],
                                ["DeploymentContainer2Creation"],
                                ["LogicalServicesNode"],
                                ["LogicalServicesNodeInterface"],
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchPortCreation"],
                                ["VerifyLogicalServicesNode"],
                                ["VerifyLogicalServicesNodeInterface"],
                            ],
            ExitSequence => [
                                ["DetachLogicalSwitchPort"],
                                ["DeleteLogicalSwitchPort"],
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
                                ["DeleteLogicalServicesNode"],
                                ["DeleteDeploymentContainer1"],
                                ["DeleteDeploymentContainer2"],
                                ["DeleteSegmentRange"],
                                ["DeleteMulticastRange"],
                            ],
            "SegmentRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               segmentidrange => {
                  '[1]' =>  {
                     name      => "seg-1",
                     begin     => "6701",
                     end       => "6800",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "MulticastRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               multicastiprange => {
                  '[1]' =>  {
                     name      => "mcast-1",
                     begin     => "224.0.36.1",
                     end       => "224.0.40.1",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "InitDatastoreOnHost1" => INIT_DATASTORE_1,
            "InitDatastoreOnHost2" => INIT_DATASTORE_2,
            "DeploymentContainer1Creation" => DEPLOYMENT_CONTAINER_1_CREATION,
            "DeploymentContainer2Creation" => DEPLOYMENT_CONTAINER_2_CREATION,
            "LogicalServicesNode" => {
               Type         => "NSX",
               TestNSX      => "neutron.[1]",
               logicalservicesnode  => {
                  '[1]' =>  {
                     name    => "lsnode-1",
                     capacity   => "LARGE",
                     dns_settings     => {
                        "domain_name"   => "node1",
                        "primary_dns[?]equal_to"   =>
                      VDNetLib::TestData::TestConstants::PRIMARY_DNS,,
                      "secondary_dns[?]equal_to" =>
                      VDNetLib::TestData::TestConstants::SECONDARY_DNS,
                     },
                  },
               },
            },
            "VerifyLogicalServicesNode" => {
                Type         => "VM",
                TestVM      => "neutron.[1].logicalservicesnode.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "lsnode-1",
                   "capacity[?]equal_to" => "LARGE",
                   "dns_settings" => {
                      "domain_name[?]equal_to"   => 'node1',
                      "primary_dns[?]equal_to"   =>
                      VDNetLib::TestData::TestConstants::PRIMARY_DNS,,
                      "secondary_dns[?]equal_to" =>
                      VDNetLib::TestData::TestConstants::SECONDARY_DNS,
                   },
                },
            },
            "LogicalServicesNodeInterface" => CREATE_LOGICAL_SERVICES_NODE_INTERFACE,
            "VerifyLogicalServicesNodeInterface" => {
                Type            => "NetAdapter",
                TestAdapter  =>
                "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "intf-1",
                   "interface_number[?]equal_to" => 1,
                   "interface_type[?]equal_to" => "INTERNAL",
                   "interface_options" => {
                      "enable_send_redirects[?]boolean" => 0,
                      "enable_proxy_arp[?]boolean"  => 0,
                   },
                   "address_groups"  => [
                      {
                         "primary_ip_address[?]equal_to" =>
                         VDNetLib::TestData::TestConstants::PRIMARY_IP_ADDRESS,
                         "subnet[?]equal_to"             =>
                         VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                      },
                   ],
                },
            },
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => CREATE_LOGICAL_SWITCH_PORT,
            "DetachLogicalSwitchPort"   => {
               Type         => "Port",
               TestPort   => "neutron.[1].logicalswitch.[1].logicalswitchport.[1]",
               sleepbetweenworkloads => "600",
               reconfigure   => "True",
               attachment => {
                  "type"  => "NoAttachment",
               },
               metadata => {
                  expectedresultcode => "200",
               },
            },
            "DeleteLogicalServicesNode" => DELETE_LOGICAL_SERVICES_NODE,
            "DeleteDeploymentContainer1" => DELETE_DEPLOYMENT_CONTAINER_1,
            "DeleteDeploymentContainer2" => DELETE_DEPLOYMENT_CONTAINER_2,
            "DeleteLogicalSwitchPort" => DELETE_ALL_LOGICAL_SWITCH_PORT,
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
            "DeleteMulticastRange" => DELETE_ALL_MULTICAST_IP_RANGES,
         },
      },
      'AttachMultipleInterfacesToLSR' => {
         Component         => "Deployment",
         Category          => "Service Node",
         TestName          => "AttachMultipleInterfacesToLSR",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case attaches multiple interfaces to Logical Services Router of Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_TwovSphere_TwoESX_TwoVsm_functional,
         WORKLOADS => {
            Sequence     => [
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
                                ["InitDatastoreOnHost1"],
                                ["InitDatastoreOnHost2"],
                                ["DeploymentContainer1Creation"],
                                ["DeploymentContainer2Creation"],
                                ["LogicalServicesNode"],
                                ["LogicalServicesNodeInterface"],
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchPortCreation"],
                                ["LogicalServicesNodeInterface2"],
                                ["LogicalSwitchCreation2"],
                                ["LogicalSwitchPortCreation2"],
                                ["VerifyLogicalServicesNode"],
                                ["VerifyLogicalServicesNodeInterface1"],
                                ["VerifyLogicalServicesNodeInterface2"],
                            ],
            ExitSequence => [
                                ["DetachLogicalSwitchPort"],
                                ["DetachLogicalSwitchPort2"],
                                ["DeleteLogicalSwitchPort"],
                                ["DeleteLogicalSwitchPort2"],
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
                                ["DeleteLogicalServicesNode"],
                                ["DeleteDeploymentContainer1"],
                                ["DeleteDeploymentContainer2"],
                                ["DeleteSegmentRange"],
                                ["DeleteMulticastRange"],
                            ],
            "SegmentRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               segmentidrange => {
                  '[1]' =>  {
                     name      => "seg-1",
                     begin     => "6801",
                     end       => "6900",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "MulticastRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               multicastiprange => {
                  '[1]' =>  {
                     name      => "mcast-1",
                     begin     => "224.0.41.1",
                     end       => "224.0.45.1",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "InitDatastoreOnHost1" => INIT_DATASTORE_1,
            "InitDatastoreOnHost2" => INIT_DATASTORE_2,
            "DeploymentContainer1Creation" => DEPLOYMENT_CONTAINER_1_CREATION,
            "DeploymentContainer2Creation" => DEPLOYMENT_CONTAINER_2_CREATION,
            "LogicalServicesNode" => CREATE_LOGICAL_SERVICES_NODE,
            "VerifyLogicalServicesNode" => {
                Type         => "VM",
                TestVM      => "neutron.[1].logicalservicesnode.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "lsnode-1",
                   "capacity[?]equal_to" => "SMALL",
                   "dns_settings" => {
                      "domain_name[?]equal_to"   => 'node1',
                      "primary_dns[?]equal_to"   =>
                      VDNetLib::TestData::TestConstants::PRIMARY_DNS,,
                      "secondary_dns[?]equal_to" =>
                      VDNetLib::TestData::TestConstants::SECONDARY_DNS,
                   },
                },
            },
            "LogicalServicesNodeInterface" => CREATE_LOGICAL_SERVICES_NODE_INTERFACE,
            "VerifyLogicalServicesNodeInterface1" => {
                Type            => "NetAdapter",
                TestAdapter  =>
                "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "intf-1",
                   "interface_number[?]equal_to" => 1,
                   "interface_type[?]equal_to" => "INTERNAL",
                   "interface_options" => {
                      "enable_send_redirects[?]boolean" => 0,
                      "enable_proxy_arp[?]boolean"  => 0,
                   },
                   "address_groups"  => [
                      {
                         "primary_ip_address[?]equal_to" =>
                         VDNetLib::TestData::TestConstants::PRIMARY_IP_ADDRESS,
                         "subnet[?]equal_to"             =>
                         VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
                      },
                   ],
                },
            },
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => CREATE_LOGICAL_SWITCH_PORT,
            "LogicalServicesNodeInterface2" => {
               Type         => "VM",
               TestVM      => "neutron.[1].logicalservicesnode.[1]",
               sleepbetweenworkloads => "600",
               logicalservicesnodeinterface  => {
                  '[2]' =>  {
                     name => "intf-2",
                     interface_number => 2,
                     interface_type => "UPLINK",
                     interface_options => {
                        "enable_send_redirects" => 0,
                        "enable_proxy_arp"  => 0,
                     },
                     address_groups  => [
                        {
                           "primary_ip_address"    => "192.168.2.1",
                           "subnet"                => "24",
                           "secondary_ip_addresses" => [
                                                      "192.168.2.2"
                                                       ],
                        },
                     ],
                  },
               },
            },
            "VerifyLogicalServicesNodeInterface2" => {
                Type            => "NetAdapter",
                TestAdapter  =>
                "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[2]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "intf-2",
                   "interface_number[?]equal_to" => 2,
                   "interface_type[?]equal_to" => "UPLINK",
                   "interface_options" => {
                      "enable_send_redirects[?]boolean" => 0,
                      "enable_proxy_arp[?]boolean"  => 0,
                   },
                   "address_groups"  => [
                      {
                         "primary_ip_address[?]equal_to" => "192.168.2.1",
                         "subnet[?]equal_to"             => "24",
                      },
                   ],
                },
            },
            "LogicalSwitchCreation2" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
               '[2]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "LogicalSwitchPortCreation2" => {
               Type         => "Switch",
               TestSwitch   => "neutron.[1].logicalswitch.[2]",
               sleepbetweenworkloads => "60",
               logicalswitchport    => {
                  '[2]' =>  {
                     name      => "lsp_2",
                     attachment => {
                        "type"  => "PatchAttachment",
                        "peer_id" => "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[2]",
                     },
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "DetachLogicalSwitchPort"   => {
               Type         => "Port",
               TestPort   => "neutron.[1].logicalswitch.[1].logicalswitchport.[1]",
               sleepbetweenworkloads => "60",
               reconfigure   => "True",
               attachment => {
                  "type"  => "NoAttachment",
               },
               metadata => {
                  expectedresultcode => "200",
               },
            },
            "DetachLogicalSwitchPort2"   => {
               Type         => "Port",
               TestPort   => "neutron.[1].logicalswitch.[2].logicalswitchport.[2]",
               reconfigure   => "True",
               attachment => {
                  "type"  => "NoAttachment",
               },
               metadata => {
                  expectedresultcode => "200",
               },
            },
            "DeleteLogicalServicesNode" => DELETE_LOGICAL_SERVICES_NODE,
            "DeleteDeploymentContainer1" => DELETE_DEPLOYMENT_CONTAINER_1,
            "DeleteDeploymentContainer2" => DELETE_DEPLOYMENT_CONTAINER_2,
            "DeleteLogicalSwitchPort" => DELETE_ALL_LOGICAL_SWITCH_PORT,
            "DeleteLogicalSwitchPort2" => {
               Type         => "Switch",
               TestSwitch   => "neutron.[1].logicalswitch.[2]",
               deletelogicalswitchport  => "neutron.[1].logicalswitch.[2].logicalswitchport.[2]",
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
            "DeleteMulticastRange" => DELETE_ALL_MULTICAST_IP_RANGES,
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for NeutronTds
#
# Input:
#       none
#
# Results:
#       An instance/object of SampleTds class
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
   my $self = $class->SUPER::new(\%Neutron);
   return (bless($self, $class));
}

1;

