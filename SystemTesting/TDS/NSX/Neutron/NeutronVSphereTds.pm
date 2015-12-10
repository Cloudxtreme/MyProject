#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Neutron::NeutronVSphereTds;

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
use VDNetLib::TestData::TestbedSpecs::TestbedSpec qw($OneNeutron_VSphere_functional);
# Import Workloads which are very common across all tests
use TDS::NSX::Neutron::CommonWorkloads ':AllConstants';

#
# Begin test cases
#
{
   %Neutron = (
      'FunctionalSetupSteps' => {
         Component         => "VSM Registration",
         Category          => "Registration",
         TestName          => "FunctionalSetupSteps",
         Version           => "2",
         Tags              => "neutron",
         Summary           => "This does setup steps required for functional cases",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_functional,
         WORKLOADS => {
            Sequence     => [
                                ["VSMRegistration_1"],
                                ["VSMRegistration_2"],
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
            ],
            "VSMRegistration_1" => VSM_REGISTRATION,
            "VSMRegistration_2" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               vsmregistration => {
                  '[1]' =>  {
                     name      => "vsm-2",
                     ipaddress => "vsm.[2]",
                     username  => "vsm.[2]",
                     password  => "vsm.[2]",
                     cert_thumbprint => "vsm.[2]",
                  },
               },
            },
            "SegmentRangeConfig" => CREATE_SEGMENT_ID_RANGE,
            "MulticastRangeConfig" => CREATE_MULTICAST_IP_RANGE,
         },
      },
      'PoolConfigs' => {
         Component         => "Segment ID Pool",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "PoolConfigs",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test Configures segment and multicast range on Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_functional,
         WORKLOADS => {
            Sequence     => [
                                ["SegmentRangeConfig"],
                                ["MulticastRangeConfig"],
            ],
            "SegmentRangeConfig" => CREATE_SEGMENT_ID_RANGE,
            "MulticastRangeConfig" => CREATE_MULTICAST_IP_RANGE,
            ExitSequence => [
                               ["DeleteSegmentRange"],
                               ["DeleteMulticastRange"],
            ],
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
            "DeleteMulticastRange" => DELETE_ALL_MULTICAST_IP_RANGES,
         },
      },
      'AllRangeOFSegIDs' => {
         Component         => "Segment ID Pool",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "AllRangeOFSegIDs",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test Configures entire segment id range",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_functional,
         WORKLOADS => {
            Sequence     => [
                                ["SegmentRangeConfig"],
            ],
            "SegmentRangeConfig" => {
                  Type          => "NSX",
                  TestNSX       => "neutron.[1]",
                  segmentidrange => {
                     '[1]' =>  {
                        name      => "seg-1",
                        begin     => "1",
                        end       => "16777216",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                     },
                  },
               },
            ExitSequence => [
                               ["DeleteSegmentRange"],
            ],
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
         },
      },
      'CreateOneSegmentIDAndLS' => {
         Component         => "Segment ID Pool",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "CreateOneSegmentIDAndLS",
         AdditionalTestName => "CreateOneSegmentIDAnd2LS",
                               "UpdateSegmentTo2IDs",
                               "ShrinkSegmentRange",
                               "DeleteFreeRange",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case creates/deletes/updates/segment ID pool",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_functional,
         WORKLOADS => {
            Sequence     => [
                ["SegmentRangeConfig"],
                ["TransportZoneCreation"],
                ["TransportClusterCreation"],
                ["LogicalSwitchCreation_1"],
                ["LogicalSwitchCreation_2"],
                ["SegmentRangeUpdate_1"],
                ["LogicalSwitchCreation_3"],
                ["SegmentRangeUpdate_2"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
                                ["DeleteSegmentRange"],
            ],
            "SegmentRangeConfig" => {
                  Type          => "NSX",
                  TestNSX       => "neutron.[1]",
                  segmentidrange => {
                     '[1]' =>  {
                        name      => "seg-1",
                        begin     => "6000",
                        end       => "6000",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                     },
                  },
               },
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation_1" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchCreation_2" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[2]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "400",
                     },
                  },
               },
            },
            "SegmentRangeUpdate_1" => {
               Type                 => "GroupingObject",
               TestGroupingObject   => "neutron.[1].segmentidrange.[1]",
               reconfigure   => "true",
               begin     => "6000",
               end       => "6001",
               metadata => {
                  'expectedresultcode' => "200",
               },
            },
            "LogicalSwitchCreation_3" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               sleepbetweenworkloads => "10",
               logicalswitch => {
                  '[2]' =>  {
                     name      => "ls_1",
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
            "SegmentRangeUpdate_2" => {
               Type                 => "GroupingObject",
               TestGroupingObject   => "neutron.[1].segmentidrange.[1]",
               reconfigure   => "true",
               begin     => "6000",
               end       => "6000",
               metadata => {
                  'expectedresultcode' => "400",
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
         },
      },
      'DeleteAllocatedRange' => {
         Component         => "Segment ID Pool",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "DeleteAllocatedRange",
         AdditionalTestName => "AllocateAllocatedRange","TODO",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case tries to delete allocated segment range",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_functional,
         WORKLOADS => {
            Sequence     => [
                ["SegmentRangeConfig"],
                ["TransportZoneCreation"],
                ["TransportClusterCreation"],
                ["LogicalSwitchCreation"],
                ["DeleteAllocatedSegmentRange"],
                ["AllocateSameSegmentRange"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
                                ["DeleteSegmentRange"],
            ],
            "SegmentRangeConfig" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               segmentidrange => {
                  '[1]' =>  {
                     name      => "seg-1",
                     begin     => "7000",
                     end       => "7000",
                     metadata => {
                        'expectedresultcode' => "201",
                     },
                  },
               },
            },
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "DeleteAllocatedSegmentRange" => {
               Type         => "NSX",
               TestNSX       => "neutron.[1]",
               deletesegmentidrange   => "neutron.[1].segmentidrange.[1]",
            },
            "AllocateSameSegmentRange" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               segmentidrange => {
                  '[2]' =>  {
                     name      => "seg-1",
                     begin     => "7000",
                     end       => "7000",
                     metadata => {
                        'expectedresultcode' => "400",
                     },
                  },
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "DeleteSegmentRange" => DELETE_ALL_SEGMENT_ID_RANGES,
         },
      },
      'TZSanity' => {
         Component         => "TransportZone",
         Category          => "Layer2-vSphere",
         TestName          => "TZSanityVxlan",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case creates vxlan type".
                              "transport zone on Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportZoneUpdation"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportZoneUpdation" => {
                Type          => "TransportZone",
                Testtransportzone     => "neutron.[1].transportzone.[1]",
                reconfigure   => "true",
                name          => "TZ-1u",
                metadata => {
                   'expectedresultcode' => "200",
                },
            },
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'TCSanity' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-vSphere",
         TestName          => "TCSanity",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case creates a Transport Cluster on Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                ["TransportZoneCreation"],
                ["TransportClusterCreation"],
                ["LogicalSwitchCreation"],
                ["LogicalSwitchPortCreation"],
            ],
            ExitSequence => [
                                ["DetachLogicalSwitchPort"],
                                ["DeleteLogicalSwitchPort"],
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => CREATE_LOGICAL_SWITCH_PORT_WITH_VIF_ATTACH,
            "DetachLogicalSwitchPort"   => DETACH_LOGICAL_SWITCH_PORT,
            "DeleteLogicalSwitchPort" => DELETE_ALL_LOGICAL_SWITCH_PORT,
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'CreateLSWithoutSegmentID' => {
         Component         => "Logical Switch",
         Category          => "Layer2-vSphere",
         TestName          => "CreateLSWithoutSegmentID",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case creates LS without segment id config",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_functional,
         WORKLOADS => {
            Sequence     => [
                               ["TransportZoneCreation"],
                               ["TransportClusterCreation"],
                               ["LogicalSwitchCreation"],
            ],
            ExitSequence => [
                               ["DeleteLogicalSwitch"],
                               ["DeleteTransportCluster"],
                               ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "400",
                     },
                  },
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'CreateTNCwith0TZs' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "CreateTNCwith0TZs",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies updation of" .
                              "tnc to carry 0 tzs.",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportClusterCreation"],
            ],
            ExitSequence => [
                                ["DeleteTransportCluster"],
            ],
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
         },
      },
      'UpdateTNCto0TZ' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "UpdateTNCto0TZ",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies updation of" .
                              "tnc to carry 0 tzs.",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["TransportClusterUpdation_1"],
                                ["TransportClusterUpdation_2"],
                            ],
            ExitSequence => [
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                 '[2]' =>  {
                     name      => "tz_ls_2",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[2]"
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterUpdation_1" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[1]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "TransportClusterUpdation_2" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[1]",
               reconfigure   => "True",
               zone_end_points => [
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'UpdateTNCto1TZ' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "UpdateTNCto1TZ",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies updation of" .
                              "tnc to carry 1 tzs.",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["TransportClusterUpdation"],
                            ],
            ExitSequence => [
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterUpdation" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[1]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'DeleteTNCWithMultipleTZs' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "DeleteTNCWithMultipleTZs",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies deletion of" .
                              "tnc with multiple TZs.",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["TransportClusterUpdation"],
                            ],
            ExitSequence => [
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                 '[2]' =>  {
                     name      => "tz_ls_2",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "TransportClusterUpdation" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[1]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[2]"
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'UpdateTNCto2TZs' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "UpdateTNCto2TZs",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies updation of" .
                              "tnc to carry 2 tzs.",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["TransportClusterUpdation"],
                            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                 '[2]' =>  {
                     name      => "tz_ls_2",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "TransportClusterUpdation" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[1]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[2]"
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'UpdateTNCWithDifferentTZsWithLS_Failure' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "UpdateTNCWithDifferentTZsWithLS_Failure",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case verifies updation of" .
                              "tnc to carry different TZ with already configure".
                              "logical switch",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            'neutron' => {
               '[1]' => {
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["TransportClusterUpdation_1"],
                                ["TransportClusterUpdation_2"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                 '[2]' =>  {
                     name      => "tz_ls_2",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterUpdation_1" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[1]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[2]"
                        },
                     ],
               metadata => {
                        expectedresultcode => "400",
               },
            },
            "TransportClusterUpdation_2" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[1]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]"
                        },
                     ],
               metadata => {
                        expectedresultcode => "400",
               },
            },
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'UpdateTNCWithDifferentTZsWithLS_Success' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "UpdateTNCWithDifferentTZsWithLS_Success",
         AdditionalComponent => "Logical Switch",
         AdditionalTestName => "UpdateTNCtoDeleteLS",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies updation of" .
                              "tnc to carry different TZ and logical switch".
                              "deleted",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["TransportClusterUpdation_1"],
                                ["TransportClusterUpdation_2"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                 '[2]' =>  {
                     name      => "tz_ls_2",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[2]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterUpdation_1" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[1]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[2]"
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "TransportClusterUpdation_2" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[2]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]"
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'CreateDelete4Tzs4Clusters' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "CreateDelete4Tzs4Clusters",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case verifies create/delete of" .
                              "tzs and tncs.",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_functional,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1-4]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[2]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[3]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[2]",
                     cluster_id  => "vc.[2].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[4]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[2]",
                     cluster_id  => "vc.[2].datacenter.[1].cluster.[2]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[3]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[4]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'CreateMultipleLSOnOneTNC' => {
         Component         => "Logical Switch",
         Category          => "Layer2-VSphere",
         TestName          => "CreateMultipleLSOnOneTNC",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies multiple ls" .
                              "on one tnc",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation_1"],
                                ["LogicalSwitchCreation"],
                                ["TransportClusterCreation_2"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1-4]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation_1" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[3]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[4]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation_2" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[2]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[2]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'IncorrectClusterID' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "IncorrectClusterID",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies error" .
                              "generated by Neutron for incorrect".
                              "cluster ID",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
            ],
            ExitSequence => [
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "domain-c1",
                     zone_end_points => [
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
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'IncorrectTransportZoneID' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "IncorrectTransportZoneID",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies error" .
                              "generated by Neutron for incorrect".
                              "transport zone ID",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportClusterCreation"],
            ],
            ExitSequence => [
                                ["DeleteTransportCluster"],
            ],
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "tz-4d454f17-1366-4c98-89ab-3d0e5ec50b6b",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "404",
                     },
                  },
               },
            },
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'IncorrectTransportZoneIDWithCorrectIDs' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "IncorrectTransportZoneIDWithCorrectIDs",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies error" .
                              "generated by Neutron for incorrect".
                              "and some correct transport zone ids",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
            ],
            ExitSequence => [
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "tz-4d454f17-1366-4c98-89ab-3d0e5ec50b6b",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "404",
                     },
                  },
               },
            },
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'IncorrectDomainID' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "IncorrectDomainID",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies error" .
                              "generated by Neutron for incorrect".
                              "domain ID",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
            ],
            ExitSequence => [
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "009F27C1-36D1-421B-B8E9-B98134E4895D",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "400",
                     },
                  },
               },
            },
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'ExtendTZOnSameVSM' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "ExtendTZOnSameVSM",
         AdditionalTestName => "ExtendLSAcross2ClustersSameVSM",
         AdditionalComponent => "Logical Switch",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies extending TZ".
                              "to different cluster on same VSM",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["LogicalSwitchCreation"],
                                ["TransportClusterCreation_1"],
                                ["TransportClusterCreation_2"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
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
            "TransportClusterCreation_1" => CREATE_TRANSPORT_CLUSTER,
            "TransportClusterCreation_2" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               sleepbetweenworkloads => "10",
               transportnodecluster => {
                  '[2]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[2]",
                     zone_end_points => [
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
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'ExtendLSSameVSM' => {
         Component         => "Logical Switch",
         Category          => "Layer2-VSphere",
         TestName          => "ExtendLSSameVSM",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies extending LS".
                              "to different cluster on same VSM",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation_1"],
                                ["LogicalSwitchCreation"],
                                ["TransportClusterCreation_2"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "TransportClusterCreation_1" => CREATE_TRANSPORT_CLUSTER,
            "TransportClusterCreation_2" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               sleepbetweenworkloads => "10",
               transportnodecluster => {
                  '[2]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[2]",
                     zone_end_points => [
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
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'ExtendLSDifferentVSM' => {
         Component         => "Logical Switch",
         Category          => "Layer2-VSphere",
         TestName          => "ExtendLSDifferentVSM",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case verifies extending TZ".
                              "to different cluster on different VSM",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation_1"],
                                ["LogicalSwitchCreation"],
                                ["TransportClusterCreation_2"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "TransportClusterCreation_1" => CREATE_TRANSPORT_CLUSTER,
            "TransportClusterCreation_2" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               sleepbetweenworkloads => "10",
               transportnodecluster => {
                  '[2]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[2]",
                     cluster_id  => "vc.[2].datacenter.[1].cluster.[1]",
                     zone_end_points => [
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
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'UpdateLSto0TZ' => {
         Component         => "Logical Switch",
         Category          => "Layer2-VSphere",
         TestName          => "UpdateLSto0TZ",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies error generated " .
                              "for LS with 0 TZs",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchUpdation"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchUpdation" => {
               Type              => "Switch",
               TestSwitch        => "neutron.[1].logicalswitch.[1]",
               reconfigure       => "true",
               sleepbetweenworkloads => "10",
               transport_zone_binding => [
               ],
               metadata => {
                  expectedresultcode => "400",
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'IncorrectTZinLS' => {
         Component         => "Logical Switch",
         Category          => "Layer2-VSphere",
         TestName          => "IncorrectTZinLS",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies error generated of" .
                              "for incorrect TZ in LS",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation" => CREATE_TRANSPORT_CLUSTER,
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "tz-ca48303c-00dc-467a-9634-d81b1d738616",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "404",
                     },
                  },
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'UpdateTNCtoMultipleTzswithLS' => {
         Component         => "Logical Switch",
         Category          => "Layer2-VSphere",
         TestName          => "UpdateTNCtoMultipleTzswithLS",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case verifies updation of" .
                              "tnc to multiple TZs with LS created".
                              "on each TZ",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_functional,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["LogicalSwitchCreation"],
                                ["TransportClusterCreation"],
                                ["TransportClusterUpdation_1"],
                                ["TransportClusterUpdation_2"],
                                ["TransportClusterUpdation_3"],
                                ["TransportClusterUpdation_4"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1-4]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[2]",
                     zone_end_points => [
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[3]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[2]",
                     cluster_id  => "vc.[2].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[4]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[2]",
                     cluster_id  => "vc.[2].datacenter.[1].cluster.[2]",
                     zone_end_points => [
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterUpdation_1" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[1]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "TransportClusterUpdation_2" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[2]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "TransportClusterUpdation_3" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[3]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "TransportClusterUpdation_4" => {
               Type                           => "TransportNode",
               TestTransportNode              => "neutron.[1].transportnodecluster.[4]",
               reconfigure   => "True",
               zone_end_points => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
               metadata => {
                        expectedresultcode => "200",
               },
            },
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[3]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[3]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[4]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[4]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'ExtendTZToAllClusters' => {
         Component         => "Transport Cluster",
         Category          => "Layer2-VSphere",
         TestName          => "ExtendTZToAllClusters",
         AdditionalTestName =>   "ExtendLSAcross2ClustersAcross2VSM",
                                 "DeleteLSAcross2VSMs","CreateDeleteLS",
         AdditionalComponent => "Logical Switch",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "Extend TZ to all clusters",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            'neutron' => {
               '[1]' => {
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["LogicalSwitchCreation"],
                                ["TransportClusterCreation_1"],
                                ["TransportClusterCreation_2-4"],
            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "TransportZoneCreation" => CREATE_TRANSPORT_ZONE,
            "TransportClusterCreation_1" => CREATE_TRANSPORT_CLUSTER,
            "TransportClusterCreation_2-4" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               sleepbetweenworkloads => "10",
               transportnodecluster => {
                  '[2]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[2]",
                     zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[3]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[2]",
                     cluster_id  => "vc.[2].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[4]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[2]",
                     cluster_id  => "vc.[2].datacenter.[1].cluster.[2]",
                     zone_end_points => [
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
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH   ,
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'CreateTwoTzsOnLS' => {
         Component         => "Logical Switch",
         Category          => "Layer2-VSphere",
         TestName          => "CreateTwoTzsOnLS",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies error generated for" .
                              "having LS with 2 TZs",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["LogicalSwitchCreation"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                 '[2]' =>  {
                     name      => "tz_ls_2",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_1",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "400",
                     },
                  },
               },
            },
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportZone"],
            ],
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'UpdateLSWithDifferentTZ' => {
         Component         => "Logical Switch",
         Category          => "Layer2-VSphere",
         TestName          => "UpdateLSWithDifferentTZ",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case verifies updation of" .
                              "LS with different TZ",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            'neutron' => {
               '[1]' => {
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                                ["TransportZoneCreation"],
                                ["TransportClusterCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchUpdation"],
            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_ls_1",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                 '[2]' =>  {
                     name      => "tz_ls_2",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "TransportClusterCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               sleepbetweenworkloads => "10",
               transportnodecluster => {
                  '[1]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[1]",
                     cluster_id  => "vc.[1].datacenter.[1].cluster.[2]",
                     zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
                  '[2]' => {
                     name    => "tn_1",
                     domain_type  => "vsphere",
                     vc_id  => "vc.[2]",
                     cluster_id  => "vc.[2].datacenter.[1].cluster.[1]",
                     zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchUpdation" => {
               Type              => "Switch",
               TestSwitch        => "neutron.[1].logicalswitch.[1]",
               reconfigure       => "true",
               sleepbetweenworkloads => "10",
               transport_zone_binding => [
                  {
                     "transport_zone_id" => "neutron.[1].transportzone.[2]",
                  },
               ],
               metadata => {
                  expectedresultcode => "400",
               },
            },
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportCluster"],
                                ["DeleteTransportZone"],
            ],
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportCluster" => DELETE_ALL_TRANSPORT_CLUSTER,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
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

