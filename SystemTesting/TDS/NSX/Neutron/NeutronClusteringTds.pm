#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Neutron::NeutronClusteringTds;

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
use VDNetLib::TestData::TestbedSpecs::TestbedSpec qw($TwoNeutron_Clustering_functional);

# Import Workloads which are very common across all tests
use TDS::NSX::Neutron::CommonWorkloads ':AllConstants';

#
# Begin test cases
#
{
   %Neutron = (
      'NeutronBackup' => {
         Component         => "NSXAPI",
         Category          => "Node Management",
         TestName          => "NeutronBackup",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case adds one neutron node to Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoNeutron_Clustering_functional,
         WORKLOADS => {
            Sequence     => [
                                ["TZCreate"],
                                ["ChangeToReadOnlyMode"],
                                ["TakeNeutronSnaphot"],
                                ["ChangeToReadWriteMode"],
                                ["TZDelete"],
                                ["ChangeToReadOnlyMode"],
                                ["RestoreNeutronFromSnapshot"],
                                ["ChangeToReadWriteMode"],
                                ["TZUpdate"],
                            ],
            ExitSequence => [
                                ["ChangeToReadWriteMode"],
                                ["TZDelete"],
                            ],
            "ChangeToReadOnlyMode" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               operatingmode => {
                  edit_mode    =>  "readonly"
               }
            },
            "TZCreate" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_1",
                     schema    => "/v1/schema/TransportZone",
                     transport_zone_type   => "gre",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_1"
                     },
                  },
               },
            },
            "TakeNeutronSnaphot" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               export        => {
                  file => "/tmp/vdnet/config-snapshot",
               },
            },
            "TZDelete" => DELETE_ALL_TRANSPORT_ZONE,
            "RestoreNeutronFromSnapshot" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               import        => {
                  file => "/tmp/vdnet/config-snapshot",
               },
            },
            "TZUpdate" => {
               Type          => "TransportZone",
               TestTransportZone       => "neutron.[1].transportzone.[1]",
               reconfigure             => "True",
               name                    => "tz_1u",
            },
            "ChangeToReadWriteMode" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               operatingmode => {
                  edit_mode    =>  "readwrite"
               }
            },
         }
      },
      'AddNeutronNodeToCluster' => {
         Component         => "NSXAPI",
         Category          => "Node Management",
         TestName          => "AddNeutronNodeToCluster",
         Version           => "2",
         Tags              => "nsx, neutron",
         Summary           => "This test case adds one neutron node to Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::TwoNeutron_Clustering_functional,
         WORKLOADS => {
            Sequence     => [
                               ["TransportZoneCreation"],
                               ["LogicalSwitchCreation"],
                               ["LogicalSwitchPortCreation"],
                               ["NeutronAddNode"],
                               ["DeleteLogicalSwitchPort"],
                               ["TransportZoneCreationOnNeutron2"],
                               ["LogicalSwitchCreationOnNeutron2"],
                               ["LogicalSwitchPortCreationOnNeutron2"],
                            ],
            ExitSequence => [
                               ["DeleteLogicalSwitchPort2"],
                               ["DeleteLogicalSwitch"],
                               ["DeleteTransportZone"],
                               ["RemovePeer"],
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
                        keyundertest => "display_name",
                        expectedvalue => "tz_ls_1"
                     },
                  },
                  '[2]' =>  {
                     name      => "tz_ls_2",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_ls_1"
                     },
                  },
               },
            },
            "LogicalSwitchCreation" => CREATE_LOGICAL_SWITCH,
            "LogicalSwitchPortCreation" => {
               Type         => "Switch",
               TestSwitch   => "neutron.[1].logicalswitch.[1]",
               logicalswitchport    => {
                  '[1]' =>  {
                     name      => "lsp_1",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "lsp_1"
                     },
                  },
               },
            },
            "NeutronAddNode" => ADD_NEUTRON_PEER,
            "DeleteLogicalSwitchPort" => {
               Type         => "Switch",
               TestSwitch   => "neutron.[2].logicalswitch.[1]",
               deletelogicalswitchport  => "neutron.[2].logicalswitch.[1].logicalswitchport.[1]",
            },
            "TransportZoneCreationOnNeutron2" => {
               Type          => "NSX",
               TestNSX       => "neutron.[2]",
               transportzone => {
                  '[3]' =>  {
                     name      => "tz_ls_3",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_ls_3"
                     },
                  },
                  '[4]' =>  {
                     name      => "tz_ls_4",
                     transport_zone_type   => "vxlan",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_ls_4"
                     },
                  },
               },
            },
            "LogicalSwitchCreationOnNeutron2" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[2]' =>  {
                     name      => "ls_2",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[2].transportzone.[2]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "ls_2"
                     },
                  },
               },
            },
            "LogicalSwitchPortCreationOnNeutron2" => {
               Type         => "Switch",
               TestSwitch   => "neutron.[2].logicalswitch.[2]",
               logicalswitchport    => {
                  '[1]' =>  {
                     name      => "lsp_1",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "lsp_1"
                     },
                  },
               },
            },
            "DeleteLogicalSwitchPort2" => {
               Type         => "Switch",
               TestSwitch   => "neutron.[1].logicalswitch.[2]",
               deletelogicalswitchport  => "neutron.[1].logicalswitch.[2].logicalswitchport.[1]",
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
            "RemovePeer" => DELETE_NEUTRON_PEER,
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

