#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Neutron::NeutronL3ServicesTds;

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
      'DHCPSanity' => {
         Component         => "DHCP",
         Category          => "Service Node",
         TestName          => "DHCPSanity",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case configures DHCP on Logical Services Router of Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
                                ["InitDatastoreOnHost1"],
                                ["DeploymentContainer1Creation"],
                                ["LogicalServicesNode"],
                                ["LogicalServicesNodeInterface"],
                                ["DHCPConfiguration"],
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchPortCreation"],
                            ],
            ExitSequence => [
                                ["DeleteDHCPConfiguration"],
                                ["DetachLogicalSwitchPort"],
                                ["DeleteLogicalSwitchPort"],
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
                                ["DeleteLogicalServicesNode"],
                                ["DeleteDeploymentContainer1"],
                                ["DeleteSegmentRange"],
                                ["DeleteMulticastRange"],
                            ],
            "SegmentRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               segmentidrange => {
                  '[1]' =>  {
                     name      => "seg-1",
                     begin     => "6001",
                     end       => "6100",
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
                     begin     => "224.0.1.1",
                     end       => "224.0.5.1",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "InitDatastoreOnHost1" => INIT_DATASTORE_1,
            "DeploymentContainer1Creation" => DEPLOYMENT_CONTAINER_1_CREATION,
            "LogicalServicesNode" => CREATE_LOGICAL_SERVICES_NODE,
            "LogicalServicesNodeInterface" => CREATE_LOGICAL_SERVICES_NODE_INTERFACE,
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => CREATE_LOGICAL_SWITCH_PORT,
            "DHCPConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               dhcpservice =>{
                  name => "DHCP-1",
                  enabled => 1,
                  dhcp_options => {
                     "hostname" => "host1",
                     "domain_name"  => "vmware.com",
                     "default_lease_time"  => "1000",
                     "routers" => ["192.168.1.2"],
                  },
                  config_elements  => [
                     {
                        "enabled"    => 1,
                        dhcp_options => {
                           "hostname" => "host1",
                           "domain_name"  => "vmware.com",
                           "default_lease_time"  => "1000",
                           "routers" => ["192.168.1.2"],
                        },
                        "interface_id"    => "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                        "ip_ranges" => [
                           {
                              "range" => "192.168.1.105-192.168.1.120",
                           },
                        ],
                     },
                  ],
               },
            },
            "DeleteDHCPConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               sleepbetweenworkloads => "600",
               dhcpservice    => {
                  name => "DHCP-1",
                  enabled => 0,
                  dhcp_options => {
                     "hostname" => "host1",
                     "domain_name"  => "vmware.com",
                     "default_lease_time"  => "1000",
                     "routers" => ["192.168.1.2"],
                  },
                  config_elements  => [],
               },
            },
            "DetachLogicalSwitchPort"   => DETACH_LOGICAL_SWITCH_PORT,
            "DeleteLogicalServicesNode" => DELETE_LOGICAL_SERVICES_NODE,
            "DeleteDeploymentContainer1" => DELETE_DEPLOYMENT_CONTAINER_1,
            "DeleteLogicalSwitchPort" => DELETE_ALL_LOGICAL_SWITCH_PORT,
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
            "DeleteMulticastRange" => DELETE_ALL_MULTICAST_IP_RANGES,
         },
      },
      'FirewallSanity' => {
         Component         => "Firewall",
         Category          => "Service Node",
         TestName          => "FirewallSanity",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case configures Firewall on Logical Services Router of Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
                                ["InitDatastoreOnHost1"],
                                ["DeploymentContainer1Creation"],
                                ["LogicalServicesNode"],
                                ["LogicalServicesNodeInterface"],
                                ["FirewallConfiguration"],
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchPortCreation"],
                            ],
            ExitSequence => [
                                ["DeleteFirewallConfiguration"],
                                ["DetachLogicalSwitchPort"],
                                ["DeleteLogicalSwitchPort"],
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
                                ["DeleteLogicalServicesNode"],
                                ["DeleteDeploymentContainer1"],
                                ["DeleteSegmentRange"],
                                ["DeleteMulticastRange"],
                            ],
            "SegmentRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               segmentidrange => {
                  '[1]' =>  {
                     name      => "seg-1",
                     begin     => "6101",
                     end       => "6200",
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
                     begin     => "224.0.6.1",
                     end       => "224.0.10.1",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "InitDatastoreOnHost1" => INIT_DATASTORE_1,
            "DeploymentContainer1Creation" => DEPLOYMENT_CONTAINER_1_CREATION,
            "LogicalServicesNode" => CREATE_LOGICAL_SERVICES_NODE,
            "LogicalServicesNodeInterface" => CREATE_LOGICAL_SERVICES_NODE_INTERFACE,
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => CREATE_LOGICAL_SWITCH_PORT,
            "FirewallConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               firewallservice  => {
                  name => "Firewall-1",
                  enabled => 1,
                  logging_enabled => 1,
                  default_policy => "ACCEPT",
                  global_config => {
                       "drop_invalid_traffic"  => 1,
                       "log_invalid_traffic"  => 0,
                       "tcp_allow_outofwindow_packets"  => 0,
                       "tcp_pick_ongoing_conn"  => 0,
                       "tcp_send_resets_for_closed_servicerouter_ports"  => 1,
                       "icmp6_timeout"  => 10,
                       "icmp_timeout"  => 10,
                       "ip_generic_timeout"  => 120,
                       "tcp_timeout_close"  => 30,
                       "tcp_timeout_established"  => 3600,
                       "tcp_timeout_open"  => 30,
                       "udp_timeout"  => 60,
                  },
                  rules  => [
                     {
                         "enabled"    => 1,
                         "rule_type"    => "USER",
                         "action"    => "ACCEPT",
                         "logging_enabled" => 1,
                         "source" => [],
                         "destination" => [],
                         "services" => [],
                     },
                  ],
               },
            },
            "DeleteFirewallConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               sleepbetweenworkloads => "600",
               firewallservice  => {
                  name => "Firewall-1",
                  enabled => 0,
                  logging_enabled => 0,
                  default_policy => "DENY",
                  global_config => {
                       "drop_invalid_traffic"  => 1,
                       "log_invalid_traffic"  => 0,
                       "tcp_allow_outofwindow_packets"  => 0,
                       "tcp_pick_ongoing_conn"  => 0,
                       "tcp_send_resets_for_closed_servicerouter_ports"  => 1,
                       "icmp6_timeout"  => 10,
                       "icmp_timeout"  => 10,
                       "ip_generic_timeout"  => 120,
                       "tcp_timeout_close"  => 30,
                       "tcp_timeout_established"  => 3600,
                       "tcp_timeout_open"  => 30,
                       "udp_timeout"  => 60,
                  },
               },
            },
            "DetachLogicalSwitchPort"   => DETACH_LOGICAL_SWITCH_PORT,
            "DeleteLogicalServicesNode" => DELETE_LOGICAL_SERVICES_NODE,
            "DeleteDeploymentContainer1" => DELETE_DEPLOYMENT_CONTAINER_1,
            "DeleteLogicalSwitchPort" => DELETE_ALL_LOGICAL_SWITCH_PORT,
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
            "DeleteMulticastRange" => DELETE_ALL_MULTICAST_IP_RANGES,
         },
      },
      'LoadBalancerSanity' => {
         Component         => "Load Balancer",
         Category          => "Service Node",
         TestName          => "LoadBalancerSanity",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case configures Load Balancer on Logical Services Router of Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
                                ["InitDatastoreOnHost1"],
                                ["DeploymentContainer1Creation"],
                                ["LogicalServicesNode"],
                                ["LogicalServicesNodeInterface"],
                                ["LoadBalancerConfiguration"],
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchPortCreation"],
                            ],
            ExitSequence => [
                                ["DeleteLoadBalancerConfiguration"],
                                ["DetachLogicalSwitchPort"],
                                ["DeleteLogicalSwitchPort"],
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
                                ["DeleteLogicalServicesNode"],
                                ["DeleteDeploymentContainer1"],
                                ["DeleteSegmentRange"],
                                ["DeleteMulticastRange"],
                            ],
            "SegmentRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               segmentidrange => {
                  '[1]' =>  {
                     name      => "seg-1",
                     begin     => "6201",
                     end       => "6300",
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
                     begin     => "224.0.11.1",
                     end       => "224.0.15.1",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "InitDatastoreOnHost1" => INIT_DATASTORE_1,
            "DeploymentContainer1Creation" => DEPLOYMENT_CONTAINER_1_CREATION,
            "LogicalServicesNode" => CREATE_LOGICAL_SERVICES_NODE,
            "LogicalServicesNodeInterface" => CREATE_LOGICAL_SERVICES_NODE_INTERFACE,
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => CREATE_LOGICAL_SWITCH_PORT,
            "LoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor1",
                        "method" => "POST",
                        "type" => "HTTP"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule1",
                        "script" => "capture request  header Host len 32"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTP",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs1",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "DeleteLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               sleepbetweenworkloads => "600",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 0,
                  "acceleration_enabled" => 0,
                  "monitors" => [],
                  "application_rules" => [],
                  "virtual_servers" => [],
                  "pools" => [],
                  "logging" => {
                    "enable" => 0,
                    "log_level" => "INFO"
                  },
               },
            },
            "DetachLogicalSwitchPort"   => DETACH_LOGICAL_SWITCH_PORT,
            "DeleteLogicalServicesNode" => DELETE_LOGICAL_SERVICES_NODE,
            "DeleteDeploymentContainer1" => DELETE_DEPLOYMENT_CONTAINER_1,
            "DeleteLogicalSwitchPort" => DELETE_ALL_LOGICAL_SWITCH_PORT,
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
            "DeleteMulticastRange" => DELETE_ALL_MULTICAST_IP_RANGES,
         },
      },
      'LoadBalancerFunctional' => {
         Component         => "Load Balancer",
         Category          => "Service Node",
         TestName          => "LoadBalancerFunctional",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case performs functional testing on Load Balancer",
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
                                ["LoadBalancerConfiguration"],
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchPortCreation"],
                                ["UpdateLoadBalancerConfiguration"],
                                ["AddMonitorToLoadBalancerConfiguration"],
                                ["AddApplicationRuleToLoadBalancerConfiguration"],
                                ["AddVirtualServerToLoadBalancerConfiguration"],
                                ["AddPoolToLoadBalancerConfiguration"],
                                ["RemovePoolFromLoadBalancerConfiguration"],
                                ["RemoveVirtualServerFromLoadBalancerConfiguration"],
                                ["RemoveApplicationRuleFromLoadBalancerConfiguration"],
                                ["RemoveMonitorFromLoadBalancerConfiguration"],
                            ],
            ExitSequence => [
                                ["DeleteLoadBalancerConfiguration"],
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
                     begin     => "6301",
                     end       => "6400",
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
                     begin     => "224.0.16.1",
                     end       => "224.0.20.1",
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
            "LogicalServicesNodeInterface" => CREATE_LOGICAL_SERVICES_NODE_INTERFACE,
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => CREATE_LOGICAL_SWITCH_PORT,
            "LoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor1",
                        "method" => "POST",
                        "type" => "HTTP"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule1",
                        "script" => "capture request  header Host len 32"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTP",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs1",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "UpdateLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               sleepbetweenworkloads => "600",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor-1",
                        "method" => "POST",
                        "type" => "HTTPS"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule-1",
                        "script" => "capture request  header Host len 32"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTPS",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs-1",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool-1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "AddMonitorToLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor-1",
                        "method" => "POST",
                        "type" => "HTTPS"
                     },
                     {
                        "monitor_id" => "monitor-2",
                        "lb_sub_component_name" => "Monitor-2",
                        "method" => "PUT",
                        "type" => "HTTP"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule-1",
                        "script" => "capture request  header Host len 32"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTPS",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs-1",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool-1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "AddApplicationRuleToLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor-1",
                        "method" => "POST",
                        "type" => "HTTPS"
                     },
                     {
                        "monitor_id" => "monitor-2",
                        "lb_sub_component_name" => "Monitor-2",
                        "method" => "PUT",
                        "type" => "HTTP"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule-1",
                        "script" => "capture request  header Host len 32"
                     },
                     {
                        "rule_id" => "applicationRule-2",
                        "lb_sub_component_name" => "Rule-2",
                        "script" => "capture request  header Host len 64"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTPS",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs-1",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool-1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "AddVirtualServerToLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor-1",
                        "method" => "POST",
                        "type" => "HTTPS"
                     },
                     {
                        "monitor_id" => "monitor-2",
                        "lb_sub_component_name" => "Monitor-2",
                        "method" => "PUT",
                        "type" => "HTTP"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule-1",
                        "script" => "capture request  header Host len 32"
                     },
                     {
                        "rule_id" => "applicationRule-2",
                        "lb_sub_component_name" => "Rule-2",
                        "script" => "capture request  header Host len 64"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTPS",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs-1",
                        "acceleration_enabled" => 1
                     },
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTP",
                        "ip_address" => "192.168.1.8",
                        "lb_sub_component_name" => "vs-2",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool-1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "AddPoolToLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor-1",
                        "method" => "POST",
                        "type" => "HTTPS"
                     },
                     {
                        "monitor_id" => "monitor-2",
                        "lb_sub_component_name" => "Monitor-2",
                        "method" => "PUT",
                        "type" => "HTTP"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule-1",
                        "script" => "capture request  header Host len 32"
                     },
                     {
                        "rule_id" => "applicationRule-2",
                        "lb_sub_component_name" => "Rule-2",
                        "script" => "capture request  header Host len 64"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTPS",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs-1",
                        "acceleration_enabled" => 1
                     },
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTP",
                        "ip_address" => "192.168.1.8",
                        "lb_sub_component_name" => "vs-2",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool-1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                     {
                        "pool_id" => "pool-2",
                        "monitor_ids" => [
                           "monitor-2"
                        ],
                        "lb_sub_component_name" => "Pool-2",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.11",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-2",
                              "member_id" => "member-2",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "RemovePoolFromLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor-1",
                        "method" => "POST",
                        "type" => "HTTPS"
                     },
                     {
                        "monitor_id" => "monitor-2",
                        "lb_sub_component_name" => "Monitor-2",
                        "method" => "PUT",
                        "type" => "HTTP"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule-1",
                        "script" => "capture request  header Host len 32"
                     },
                     {
                        "rule_id" => "applicationRule-2",
                        "lb_sub_component_name" => "Rule-2",
                        "script" => "capture request  header Host len 64"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTPS",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs-1",
                        "acceleration_enabled" => 1
                     },
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTP",
                        "ip_address" => "192.168.1.8",
                        "lb_sub_component_name" => "vs-2",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool-1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "RemoveVirtualServerFromLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor-1",
                        "method" => "POST",
                        "type" => "HTTPS"
                     },
                     {
                        "monitor_id" => "monitor-2",
                        "lb_sub_component_name" => "Monitor-2",
                        "method" => "PUT",
                        "type" => "HTTP"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule-1",
                        "script" => "capture request  header Host len 32"
                     },
                     {
                        "rule_id" => "applicationRule-2",
                        "lb_sub_component_name" => "Rule-2",
                        "script" => "capture request  header Host len 64"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTPS",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs-1",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool-1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "RemoveApplicationRuleFromLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor-1",
                        "method" => "POST",
                        "type" => "HTTPS"
                     },
                     {
                        "monitor_id" => "monitor-2",
                        "lb_sub_component_name" => "Monitor-2",
                        "method" => "PUT",
                        "type" => "HTTP"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule-1",
                        "script" => "capture request  header Host len 32"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTPS",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs-1",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool-1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "RemoveMonitorFromLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 1,
                  "acceleration_enabled" => 1,
                  "monitors" => [
                     {
                        "monitor_id" => "monitor-1",
                        "lb_sub_component_name" => "Monitor-1",
                        "method" => "POST",
                        "type" => "HTTPS"
                     },
                  ],
                  "application_rules" => [
                     {
                        "rule_id" => "applicationRule-1",
                        "lb_sub_component_name" => "Rule-1",
                        "script" => "capture request  header Host len 32"
                     },
                  ],
                  "virtual_servers" => [
                     {
                        "port" => 8080,
                        "enabled" => 1,
                        "protocol" => "HTTPS",
                        "ip_address" => "192.168.1.9",
                        "lb_sub_component_name" => "vs-1",
                        "acceleration_enabled" => 1
                     },
                  ],
                  "pools" => [
                     {
                        "pool_id" => "pool-1",
                        "monitor_ids" => [
                           "monitor-1"
                        ],
                        "lb_sub_component_name" => "Pool-1",
                        "members" => [
                           {
                              "port" => 80,
                              "monitor_port" => 80,
                              "ip_address" => "192.168.1.10",
                              "weight" => 100,
                              "condition" => "enabled",
                              "lb_sub_component_name" => "Member-1",
                              "member_id" => "member-1",
                              "min_conn" => 0,
                              "max_conn" => 5
                           },
                        ],
                        "algorithm" => "round_robin",
                     },
                  ],
                  "logging" => {
                     "enable" => 1,
                     "log_level" => "INFO"
                  },
               },
            },
            "DeleteLoadBalancerConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               loadbalancerservice  => {
                  "name" => "Load Balancer-1",
                  "enabled" => 0,
                  "acceleration_enabled" => 0,
                  "monitors" => [],
                  "application_rules" => [],
                  "virtual_servers" => [],
                  "pools" => [],
                  "logging" => {
                    "enable" => 0,
                    "log_level" => "INFO"
                  },
               },
            },
            "DetachLogicalSwitchPort"   => DETACH_LOGICAL_SWITCH_PORT,
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
      'DHCPFunctional' => {
         Component         => "Deployment",
         Category          => "Service Node",
         TestName          => "DHCPFunctional",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case performs functional testing on DHCP of Neutron",
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
                                ["DHCPConfiguration"],
                                ["UpdateDHCPConfiguration"],
                                ["AddDHCPConfigElement"],
                                ["DeleteDHCPConfigElement"],
                                ["DeleteDHCPRange"],
                            ],
            ExitSequence => [
                                ["DeleteDHCPConfiguration"],
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
                     begin     => "6401",
                     end       => "6500",
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
                     begin     => "224.0.21.1",
                     end       => "224.0.25.1",
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
            "LogicalServicesNodeInterface" => CREATE_LOGICAL_SERVICES_NODE_INTERFACE,
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
                     interface_type => "INTERNAL",
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
            "DHCPConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               sleepbetweenworkloads => "60",
               dhcpservice =>{
                  name => "DHCP-1",
                  enabled => 1,
                  dhcp_options => {
                     "hostname" => "host1",
                     "domain_name"  => "vmware.com",
                     "default_lease_time"  => "1000",
                     "routers" => ["192.168.1.2"],
                  },
                  config_elements  => [
                     {
                        "enabled"    => 1,
                        dhcp_options => {
                           "hostname" => "host1",
                           "domain_name"  => "vmware.com",
                           "default_lease_time"  => "1000",
                           "routers" => ["192.168.1.2"],
                        },
                        "interface_id"    => "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                        "ip_ranges" => [
                           {
                              "range" => "192.168.1.105-192.168.1.120",
                           },
                        ],
                     },
                  ],
               },
            },
            "UpdateDHCPConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               dhcpservice =>{
                  name => "DHCP-1",
                  enabled => 1,
                  dhcp_options => {
                     "hostname" => "host1",
                     "domain_name"  => "vmware.com",
                     "default_lease_time"  => "1000",
                     "routers" => ["192.168.1.2"],
                  },
                  config_elements  => [
                     {
                        "enabled"    => 1,
                        dhcp_options => {
                           "hostname" => "host1",
                           "domain_name"  => "vmware.com",
                           "default_lease_time"  => "1000",
                           "routers" => ["192.168.1.2"],
                        },
                        "interface_id"    => "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                        "ip_ranges" => [
                           {
                              "range" => "192.168.1.105-192.168.1.120",
                           },
                           {
                              "range" => "192.168.1.121-192.168.1.140",
                           },
                        ],
                     },
                  ],
               },
            },
            "AddDHCPConfigElement" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               dhcpservice =>{
                  name => "DHCP-1",
                  enabled => 1,
                  dhcp_options => {
                     "hostname" => "host1",
                     "domain_name"  => "vmware.com",
                     "default_lease_time"  => "1000",
                     "routers" => ["192.168.1.2"],
                  },
                  config_elements  => [
                     {
                        "enabled"    => 1,
                        dhcp_options => {
                           "hostname" => "host1",
                           "domain_name"  => "vmware.com",
                           "default_lease_time"  => "1000",
                           "routers" => ["192.168.1.2"],
                        },
                        "interface_id"    => "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                        "ip_ranges" => [
                           {
                              "range" => "192.168.1.105-192.168.1.120",
                           },
                           {
                              "range" => "192.168.1.121-192.168.1.140",
                           },
                        ],
                     },
                     {
                        "enabled"    => 1,
                        dhcp_options => {
                           "hostname" => "host1",
                           "domain_name"  => "vmware.com",
                           "default_lease_time"  => "1000",
                           "routers" => ["192.168.2.2"],
                        },
                        "interface_id"    => "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[2]",
                        "ip_ranges" => [
                           {
                              "range" => "192.168.2.105-192.168.2.120",
                           },
                           {
                              "range" => "192.168.2.121-192.168.2.140",
                           },
                        ],
                     },
                  ],
               },
            },
            "DeleteDHCPConfigElement" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               dhcpservice =>{
                  name => "DHCP-1",
                  enabled => 1,
                  dhcp_options => {
                     "hostname" => "host1",
                     "domain_name"  => "vmware.com",
                     "default_lease_time"  => "1000",
                     "routers" => ["192.168.1.2"],
                  },
                  config_elements  => [
                     {
                        "enabled"    => 1,
                        dhcp_options => {
                           "hostname" => "host1",
                           "domain_name"  => "vmware.com",
                           "default_lease_time"  => "1000",
                           "routers" => ["192.168.1.2"],
                        },
                        "interface_id"    => "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                        "ip_ranges" => [
                           {
                              "range" => "192.168.1.105-192.168.1.120",
                           },
                           {
                              "range" => "192.168.1.121-192.168.1.140",
                           },
                        ],
                     },
                  ],
               },
            },
            "DeleteDHCPRange" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               dhcpservice =>{
                  name => "DHCP-1",
                  enabled => 1,
                  dhcp_options => {
                     "hostname" => "host1",
                     "domain_name"  => "vmware.com",
                     "default_lease_time"  => "1000",
                     "routers" => ["192.168.1.2"],
                  },
                  config_elements  => [
                     {
                        "enabled"    => 1,
                        dhcp_options => {
                           "hostname" => "host1",
                           "domain_name"  => "vmware.com",
                           "default_lease_time"  => "1000",
                           "routers" => ["192.168.1.2"],
                        },
                        "interface_id"    => "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
                        "ip_ranges" => [
                           {
                              "range" => "192.168.1.105-192.168.1.120",
                           },
                        ],
                     },
                  ],
               },
            },
            "DeleteDHCPConfiguration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1].logicalservicesnode.[1]",
               dhcpservice    => {
                  name => "DHCP-1",
                  enabled => 0,
                  dhcp_options => {
                     "hostname" => "host1",
                     "domain_name"  => "vmware.com",
                     "default_lease_time"  => "1000",
                     "routers" => ["192.168.1.2"],
                  },
                  config_elements  => [],
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

