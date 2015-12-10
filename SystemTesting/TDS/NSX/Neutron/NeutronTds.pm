#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Neutron::NeutronTds;

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
use TDS::NSX::Neutron::CommonWorkloads ':AllConstants';

my $neutronTestbedSpec = {
};

#
# Begin test cases
#
{
   %Neutron = (
     'NVPRegistration' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "NVPRegistration",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies registration of nvp" .
                              " with neutron.",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            'neutron' => {
               '[1]' => {
               },
            },
            'nvpcontroller' => {
               '[1]' => {
                }
            },
         },
         WORKLOADS => {
            Sequence     => [
                                ["NVPRegistration"],
                            ],
            "NVPRegistration" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               nvpregistration => {
                  '[1]' =>  {
                     ipaddress => "nvpcontroller.[1]",
                     username  => "nvpcontroller.[1]",
                     password  => "nvpcontroller.[1]",
                     cert_thumbprint => "nvpcontroller.[1]",
                     schema    => "/v1/schema/NVPConfigDto",
                  },
               },
            },
         },
      },
      'TZSanity' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "TZSanity",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies creation of " .
                              "transport zone",
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
                                ["TransportZoneVerification"],
                                ["VerifyTZ1"],
                                ["VerifyTZ2"],
                                ["VerifyTZ3"],
                            ],
            ExitSequence => [
                                ["DeleteTransportZone"],
                            ],
            "TransportZoneCreation" => {
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
                  '[2]' =>  {
                     name      => "tz_2",
                     schema    => "/v1/schema/TransportZone",
                     transport_zone_type   => "gre",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_2"
                     },
                  },
                  '[3]' =>  {
                     name      => "tz_3",
                     schema    => "/v1/schema/TransportZone",
                     transport_zone_type   => "gre",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_3"
                     },
                  },
               },
            },
            "VerifyTZ1" => {
               Type     => "TransportZone",
               TestTransportZone  => "neutron.[1].transportzone.[1]",
               verifyendpointattributes => {
                  "name[?]equal_to" => "tz_1",
               },
            },
            "VerifyTZ2" => {
               Type     => "TransportZone",
               TestTransportZone  => "neutron.[1].transportzone.[2]",
               verifyendpointattributes => {
                  "name[?]equal_to" => "tz_2",
               },
            },
            "VerifyTZ3" => {
               Type     => "TransportZone",
               TestTransportZone  => "neutron.[1].transportzone.[3]",
               verifyendpointattributes => {
                  "name[?]equal_to" => "tz_3",
               },
            },
            "TransportZoneVerification" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               checkifnodeexists => ["neutron.[1].transportzone.[1-2]",
                                     "neutron.[1].transportzone.[3]",
                                     "neutron.[1].transportzone.[-1]",
                                    ],
            },
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'TNSanity' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "TNSanity",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies creation of transport node",
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
                                ["TransportNodeCreation"],
                            ],
            ExitSequence => [
                                ["DeleteTransportNode"],
                                ["DeleteTransportZone"],
                            ],
            "TransportZoneCreation" => {
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
            "TransportNodeCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnode => {
                  '[1]' => {
                     name    => "tn_1",
                     schema  => "/v1/schema/TransportNode",
                     admin_status_enabled => 1,
                     integration_bridge_id => "br-int",
                     zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                            "transport_type"    => {
                                "type"              => "gre",
                                "internal_port"     => {
                                    "ip_address"            => "10.24.115.136",
                                },
                            },
                        },
                     ],
                     "credential"  =>  {
                            "type"              =>  "SecurityCertificateCredential",
                            "pem_encoded"       =>  VDNetLib::Common::GlobalConfig::KVM_CERT_1,
                     },
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tn_1"
                     },
                  },
               },
            },
            "DeleteTransportNode" => DELETE_ALL_TRANSPORT_NODE,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'LSSanity' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "LSSanity",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies creation of" .
                              " logical switch.",
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
                                ["VerifyLS"],
                            ],
            ExitSequence => [
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportZone"],
                            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_ls_1",
                     schema    => "/v1/schema/TransportZone",
                     transport_zone_type   => "gre",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_ls_1"
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
                     schema    => "/v1/schema/LogicalSwitch",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "ls_1"
                     },
                  },
               },
            },
            "VerifyLS" => {
               Type     => "Switch",
               TestSwitch  => "neutron.[1].logicalswitch.[1]",
               verifyendpointattributes => {
                  "name[?]equal_to" => "ls_1",
                  transport_zone_binding => [
                        {
                           "transport_zone_id[?]equal_to" => "neutron.[1].transportzone.[1]",
                        },
                     ],
               },
            },
            "DeleteLogicalSwitch" => DELETE_ALL_LOGICAL_SWITCH,
            "DeleteTransportZone" => DELETE_ALL_TRANSPORT_ZONE,
         },
      },
      'LSPSanity' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "LSPSanity",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies creation of" .
                              " logical switch port.",
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
                                ["LogicalSwitchPortCreation"],
                            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_lsp_1",
                     schema    => "/v1/schema/TransportZone",
                     transport_zone_type   => "stt",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_lsp_1"
                     },
                  },
               },
            },
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_2",
                     schema    => "/v1/schema/LogicalSwitch",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
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
            "LogicalSwitchPortCreation" => {
               Type              => "Switch",
               TestSwitch        => "neutron.[1].logicalswitch.[1]",
               logicalswitchport => {
                  '[1]' =>  {
                     name      => "lsp_1",
                     schema    => "/v1/schema/LogicalSwitchPort",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "lsp_1"
                     },
                  },
               },
            },
         },
      },
      'VIFAttachmentSanity' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "VIFAttachmentSanity",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies creation of" .
                              " vif attachment.",
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
                                ["TransportNodeCreation"],
                                ["LogicalSwitchCreation"],
                                ["LogicalSwitchPortCreation"],
                            ],
            ExitSequence => [
                                ["DetachLogicalSwitchPort"],
                                ["DeleteLogicalSwitchPort"],
                                ["DeleteLogicalSwitch"],
                                ["DeleteTransportNode"],
                                ["DeleteTransportZone"],
                            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_vif_1",
                     transport_zone_type   => "stt",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_vif_1"
                     },
                  },
               },
            },
            "TransportNodeCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnode => {
                  '[1]' => {
                     name    => "tn_vif_1",
                     schema  => "/v1/schema/TransportNode",
                     admin_status_enabled => 1,
                     integration_bridge_id => "br-int",
                     zone_end_points => [
                        {
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                            "schema"            => "/v1/schema/TransportZoneEndpoint",
                            "transport_type"    => {
                                "type"              => "stt",
                                "internal_port"     => {
                                    "ip_address"            => "10.24.115.136",
                                },
                            },          },
                     ],
                     "credential"  =>  {
                            "type"              =>  "SecurityCertificateCredential",
                            "pem_encoded"       =>  VDNetLib::Common::GlobalConfig::KVM_CERT_1,
                     },
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tn_vif_1"
                     },
                  },
               },
            },
            "LogicalSwitchCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "ls_3",
                     transport_zone_binding => [
                        {
                           "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        },
                     ],
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "ls_3"
                     },
                  },
               },
            },
            "LogicalSwitchPortCreation" => {
               Type              => "Switch",
               TestSwitch        => "neutron.[1].logicalswitch.[1]",
               logicalswitchport => {
                  '[1]' =>  {
                     name       => "lsp_vif_1",
                     attachment => {
                        "schema"     => "/v1/schema/VifAttachment",
                        "vif_uuid"   => "29e1327b-2ca3-4ee8-a6f8-ce0da7163ad2",
                        "type"       => "VifAttachment",
                     },
                     metadata   => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "lsp_vif_1"
                     },
                  },
               },
            },
            "DetachLogicalSwitchPort" => {
               Type             => "Port",
               TestPort         => "neutron.[1].logicalswitch.[1].logicalswitchport.[1]",
               sleepbetweenworkloads => "60",
               attachment => {
                         "schema" => "/v1/schema/NoAttachment",
                         "type" => "NoAttachment",
               },
            metadata => {
                  expectedresultcode => "200",
                  keyundertest => "schema",
                  expectedvalue => "/v1/schema/NoAttachment"
               },
            },
            "DeleteLogicalSwitchPort" => {
                Type  => "Switch",
                TestSwitch => "neutron.[1].logicalswitch.[1]",
                sleepbetweenworkloads => "60",
                deletelogicalswitchport => "neutron.[1].logicalswitch.[1].logicalswitchport.[1]",
            },
            "DeleteLogicalSwitch" => {
                Type  => "NSX",
                TestNSX => "neutron.[1]",
                sleepbetweenworkloads => "60",
                deletelogicalswitch => "neutron.[1].logicalswitch.[1]",
            },
            "DeleteTransportNode" => {
                Type => "NSX",
                TestNSX => "neutron.[1]",
                sleepbetweenworkloads => "60",
                deletetransportnode => "neutron.[1].transportnode.[1]",
            },
            "DeleteTransportZone" => {
                Type => "NSX",
                TestNSX => "neutron.[1]",
                sleepbetweenworkloads => "60",
                deletetransportzone => "neutron.[1].transportzone.[1]",
            },
         },
      },
      'TZSanityDataset' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "TZSanityDataset",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies behaviour of iterator" .
                              " and constraint database code.",
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
                            ],
            "TransportZoneCreation" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "magic",
                     transport_zone_type   => "vxlan",
                  },
               },
            },
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

