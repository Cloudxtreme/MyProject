#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Neutron::NeutronGroupingObjectsTds;

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
     'IPSetSanity' => {
         Component         => "IPSet",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "IPSet Sanity",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This is sanity test case of IPSet on Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence    => [
               ["IPSetCreation"],
               ["VerifyIPSetAfterCreation"],
               ["IPSetUpdation1"],
               ["VerifyIPSetAfterUpdation1"],
               ["IPSetUpdation2"],
               ["VerifyIPSetAfterUpdation2"],
            ],
            ExitSequence => [
               ["IPSetDeletion"],
            ],
            "IPSetCreation" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                ipset   => {
                    '[1]' => {
                        name    => "IPSet-1",
                        value   => "192.168.0.101",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                    },
                },
            },
            "VerifyIPSetAfterCreation" => {
                Type                     => "GroupingObject",
                Testgroupingobject       => "neutron.[1].ipset.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "IPSet-1",
                   "value[?]equal_to" => "192.168.0.101",
                },
            },
            "IPSetUpdation1" => {
                Type                     => "GroupingObject",
                Testgroupingobject       => "neutron.[1].ipset.[1]",
                updateipset              => "True",
                name                     => "IPSet-1u",
                metadata => {
                   'expectedresultcode' => "200",
                },
            },
            "VerifyIPSetAfterUpdation1" => {
                Type                     => "GroupingObject",
                Testgroupingobject       => "neutron.[1].ipset.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "IPSet-1u",
                   "value[?]equal_to" => "192.168.0.101",
                },
            },
            "IPSetUpdation2" => {
                Type                     => "GroupingObject",
                Testgroupingobject       => "neutron.[1].ipset.[1]",
                updateipset              => "True",
                value                    => "192.168.0.1/24",
                metadata => {
                   'expectedresultcode' => "200",
                },
            },
            "VerifyIPSetAfterUpdation2" => {
                Type                     => "GroupingObject",
                Testgroupingobject       => "neutron.[1].ipset.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "IPSet-1u",
                   "value[?]equal_to" => "192.168.0.1/24",
                },
            },
            "IPSetDeletion" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                deleteipset   => "neutron.[1].ipset.[1]",
            },
         },
      },
      'IPSetMagic' => {
         Component         => "IPSet",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "IPSet Magic",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This test case verifies creation of different
                               values for IPSet",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence    => [["IPSetCreation"],],
            "IPSetCreation" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                ipset   => {
                    '[1]' => {
                        name    => "magic",
                        value   => "magic",
                    },
                },
            },
         },
      },
      'IPPool' => {
         Component         => "IP Pool",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "IPPoolSanity",
         Version           => "2",
         Tags              => "neutron",
         Summary           => "This test case tests IPPool on Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence    => [  ["IPPoolCreation"],
                              ["VerifyIPPoolAfterCreation"],
                              ["IPPoolUpdation"],
                              ["VerifyIPPoolAfterUpdation"],
                              ["IPPoolAllocate"],
                              ["IPPoolDeallocate"],
                           ],
            ExitSequence => [ ["IPPoolDeletion"] ],
            "IPPoolCreation" => CREATE_IPPOOL,
            "VerifyIPPoolAfterCreation" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].ippool.[1]",
                verifyendpointattributes => {
                   "subnets[?]contain_once"  => [
                        {
                            "static_routes[?]contain_once"  => [
                                {
                                    "destination_cidr" => "192.168.10.0/24",
                                    "next_hop"         => '192.168.10.5',
                                 },
                            ],
                            "allocation_ranges[?]contain_once" => [
                                {
                                    "start"   => '192.168.1.2',
                                    "end"     => '192.168.1.6',
                                },
                                {
                                    "start"  => '192.168.1.10',
                                    "end"    => '192.168.1.100'
                                },
                            ],
                            "gateway_ip[?]equal_to"  => '192.168.1.1',
                            "ip_version[?]equal_to"  => 4,
                            "cidr[?]equal_to"        => '192.168.1.0/24',
                        },
                    ],
                },
            },
            "IPPoolUpdation" => {
               Type                    => "GroupingObject",
               TestGroupingObject      => "neutron.[1].ippool.[1]",
               reconfigure             => "true",
               name                 => "TestIPPool-updated-1xx",
               groupingobject_desc  => "TESTING 1 2 3 ...",
               subnets        => [
                        {
                           static_routes  => [
                             {
                               destination_cidr => "192.168.10.0/24",
                               next_hop         => "192.168.10.5"
                             },
                           ],
                           allocation_ranges => [
                             {
                               start   => "192.168.1.2",
                               end     => "192.168.1.9",
                             },
                             {
                                start  => "192.168.1.15",
                                end    => "192.168.1.150"
                             },
                           ],
                           gateway_ip  => "192.168.1.1",
                           ip_version  => 4,
                           cidr        => "192.168.1.0/24",
                        },
                     ],
               metadata => {
                   'expectedresultcode' => "200"
               },
            },
            "VerifyIPPoolAfterUpdation" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].ippool.[1]",
                verifyendpointattributes => {
                   "subnets[?]contain_once"  => [
                        {
                            "static_routes[?]contain_once"  => [
                                {
                                    "destination_cidr" => "192.168.10.0/24",
                                    "next_hop"         => '192.168.10.5',
                                 },
                            ],
                            "allocation_ranges[?]contain_once" => [
                               {
                                  start   => "192.168.1.2",
                                  end     => "192.168.1.9",
                               },
                               {
                                  start  => "192.168.1.15",
                                  end    => "192.168.1.150"
                               },
                            ],
                            "gateway_ip[?]equal_to"  => '192.168.1.1',
                            "ip_version[?]equal_to"  => 4,
                            "cidr[?]equal_to"        => '192.168.1.0/24',
                        },
                    ],
                },
            },
            "IPPoolAllocate" => ALLOCATE_IP_FROM_POOL,
            "IPPoolDeallocate" => DEALLOCATE_IP_FROM_POOL,
            "IPPoolDeletion" => DELETE_IPPOOL,
         },
      },
      'ServiceSanity' => {
         Component         => "Service",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "Service Sanity",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This is sanity test case of Service on Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence    => [
               ["ServiceCreation"],
               ["VerifyServiceAfterCreation"],
               ["ServiceUpdation1"],
               ["VerifyServiceAfterUpdation1"],
               ["ServiceUpdation2"],
               ["VerifyServiceAfterUpdation2"],
            ],
            ExitSequence => [
               ["ServiceDeletion"],
            ],
            "ServiceCreation" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                applicationservice   => {
                    '[1]' => {
                        name    => "Service-1",
                        value   => "1234",
                        source_port   => "5678",
                        application_protocol   => "TCP",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                    },
                },
            },
            "VerifyServiceAfterCreation" => {
                Type                     => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservice.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "Service-1",
                   "value[?]equal_to" => "1234",
                   "application_protocol[?]equal_to" => "TCP",
                   "source_port[?]equal_to" => "5678",
                },
            },
            "ServiceUpdation1" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservice.[1]",
                updateservice              => "True",
                application_protocol       => "UDP",
                metadata => {
                   'expectedresultcode' => "200",
                },
            },
            "VerifyServiceAfterUpdation1" => {
                Type                     => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservice.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "Service-1",
                   "value[?]equal_to" => "1234",
                   "application_protocol[?]equal_to" => "UDP",
                   "source_port[?]equal_to" => "5678",
                },
            },
            "ServiceUpdation2" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservice.[1]",
                updateservice              => "True",
                source_port                => "9876",
                metadata => {
                   'expectedresultcode' => "200",
                },
            },
            "VerifyServiceAfterUpdation2" => {
                Type                     => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservice.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "Service-1",
                   "value[?]equal_to" => "1234",
                   "application_protocol[?]equal_to" => "UDP",
                   "source_port[?]equal_to" => "9876",
                },
            },
            "ServiceDeletion" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                deleteapplicationservice   => "neutron.[1].applicationservice.[1]",
            },
         },
      },
      'ServiceGroupSanity' => {
         Component         => "ServiceGroup",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "ServiceGroup Sanity",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This is sanity test case of ServiceGroup on Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence    => [
               ["ServiceCreation"],
               ["VerifyServiceAfterCreation"],
               ["ServiceGroupCreation"],
               ["VerifyServiceGroupAfterCreation"],
               ["ServiceGroupUpdation1"],
               ["VerifyServiceGroupAfterUpdation1"],
               ["ServiceGroupUpdation2"],
               ["VerifyServiceGroupAfterUpdation2"],
               ["AddMemberToServiceGroup"],
            ],
            ExitSequence => [
               ["DeleteMemberFromServiceGroup"],
               ["ServiceDeletion"],
               ["ServiceGroupDeletion"],
            ],
            "ServiceCreation" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                applicationservice   => {
                    '[1]' => {
                        name    => "Service-1",
                        value   => "1234",
                        source_port   => "5678",
                        application_protocol   => "TCP",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                    },
                },
            },
            "VerifyServiceAfterCreation" => {
                Type                     => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservice.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "Service-1",
                   "value[?]equal_to" => "1234",
                   "application_protocol[?]equal_to" => "TCP",
                   "source_port[?]equal_to" => "5678",
                },
            },
            "ServiceGroupCreation" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                applicationservicegroup   => {
                    '[1]' => {
                        name         => "ServiceGroup-1",
                        groupingobject_desc  => "Service Group Description",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                    },
                },
            },
            "VerifyServiceGroupAfterCreation" => {
                Type                     => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "ServiceGroup-1",
                   "groupingobject_desc[?]equal_to" => "Service Group Description",
                },
            },
            "ServiceGroupUpdation1" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[1]",
                reconfigure                => "True",
                name                       => "ServiceGroup-1u",
                metadata => {
                   'expectedresultcode' => "200",
                },
            },
            "VerifyServiceGroupAfterUpdation1" => {
                Type                     => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "ServiceGroup-1u",
                   "groupingobject_desc[?]equal_to" => "Service Group Description",
                },
            },
            "ServiceGroupUpdation2" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[1]",
                reconfigure                => "True",
                groupingobject_desc        => "Service Group Description Updated",
                metadata => {
                   'expectedresultcode' => "200",
                },
            },
            "VerifyServiceGroupAfterUpdation2" => {
                Type                     => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[1]",
                verifyendpointattributes => {
                   "name[?]equal_to"  => "ServiceGroup-1u",
                   "groupingobject_desc[?]equal_to" => "Service Group Description Updated",
                },
            },
            "AddMemberToServiceGroup" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[1]",
                applicationservicegroupmember         => {
                   "[1]" => {
                       member => "neutron.[1].applicationservice.[1]",
                   },
                },
            },
            "DeleteMemberFromServiceGroup" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[1]",
                deleteapplicationservicegroupmember   =>
                "neutron.[1].applicationservicegroup.[1].applicationservicegroupmember.[1]",
            },
            "ServiceDeletion" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                deleteapplicationservice   => "neutron.[1].applicationservice.[1]",
            },
            "ServiceGroupDeletion" => {
                Type                 => "NSX",
                TestNSX              => "neutron.[1]",
                deleteapplicationservicegroup   => "neutron.[1].applicationservicegroup.[1]",
            },
         },
      },
      'ServiceGroupFunctional' => {
         Component         => "ServiceGroup",
         Category          => "Grouping and Pools Mgmt",
         TestName          => "ServiceGroup Functional",
         Version           => "2",
         Tags              => "neutron,CAT",
         Summary           => "This is functional test case of ServiceGroup on Neutron",
         ExpectedResult    => "PASS",
         TestbedSpec       => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneNeutron_L2L3VSphere_CAT_Setup,
         WORKLOADS => {
            Sequence    => [
               ["ServiceCreation"],
               ["ServiceGroupCreation"],
               ["AddService1ToServiceGroup"],
               ["AddService2ToServiceGroup"],
               ["AddServiceGroup1ToServiceGroup"],
               ["AddServiceGroup2ToServiceGroup"],
            ],
            ExitSequence => [
               ["DeleteMembersFromServiceGroup"],
               ["ServicesDeletion"],
               ["ServiceGroupsDeletion"],
            ],
            "ServiceCreation" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                applicationservice   => {
                    '[1]' => {
                        name    => "Service-1",
                        value   => "1234",
                        source_port   => "5678",
                        application_protocol   => "TCP",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                    },
                    '[2]' => {
                        name    => "Service-2",
                        value   => "1234",
                        source_port   => "5678",
                        application_protocol   => "UDP",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                    },
                },
            },
            "ServiceGroupCreation" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                applicationservicegroup   => {
                    '[1]' => {
                        name         => "ServiceGroup-1",
                        groupingobject_desc  => "Service Group Description-1",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                    },
                    '[2]' => {
                        name         => "ServiceGroup-2",
                        groupingobject_desc  => "Service Group Description-2",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                    },
                    '[3]' => {
                        name         => "CompositeServiceGroup-1",
                        groupingobject_desc  => "Composite Service Group Description",
                        metadata => {
                           'expectedresultcode' => "201",
                        },
                    },
                },
            },
            "AddService1ToServiceGroup" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[3]",
                applicationservicegroupmember         => {
                   "[1]" => {
                       member => "neutron.[1].applicationservice.[1]",
                   },
                },
            },
            "AddService2ToServiceGroup" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[3]",
                applicationservicegroupmember         => {
                   "[2]" => {
                       member => "neutron.[1].applicationservice.[2]",
                   },
                },
            },
            "AddServiceGroup1ToServiceGroup" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[3]",
                applicationservicegroupmember         => {
                   "[3]" => {
                       member => "neutron.[1].applicationservicegroup.[1]",
                   },
                },
            },
            "AddServiceGroup2ToServiceGroup" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[3]",
                applicationservicegroupmember         => {
                   "[4]" => {
                       member => "neutron.[1].applicationservicegroup.[2]",
                   },
                },
            },
            "DeleteMembersFromServiceGroup" => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "neutron.[1].applicationservicegroup.[3]",
                deleteapplicationservicegroupmember   =>
                "neutron.[1].applicationservicegroup.[3].applicationservicegroupmember.[1-4]",
            },
            "ServicesDeletion" => {
                Type          => "NSX",
                TestNSX       => "neutron.[1]",
                deleteapplicationservice   => "neutron.[1].applicationservice.[1-2]",
            },
            "ServiceGroupsDeletion" => {
                Type                 => "NSX",
                TestNSX              => "neutron.[1]",
                deleteapplicationservicegroup   => "neutron.[1].applicationservicegroup.[1-3]",
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

