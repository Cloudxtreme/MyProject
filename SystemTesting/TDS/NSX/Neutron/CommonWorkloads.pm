#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::Neutron::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use VDNetLib::TestData::TestConstants;

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'VSM_REGISTRATION',
   'INIT_DATASTORE_1',
   'INIT_DATASTORE_2',
   'DEPLOYMENT_CONTAINER_1_CREATION',
   'DEPLOYMENT_CONTAINER_2_CREATION',
   'CREATE_IPPOOL',
   'ALLOCATE_IP_FROM_POOL',
   'CREATE_IPSET',
   'CREATE_SEGMENT_ID_RANGE',
   'CREATE_MULTICAST_IP_RANGE',
   'CREATE_LOGICAL_SERVICES_NODE',
   'CREATE_LOGICAL_SERVICES_NODE_INTERFACE',
   'CREATE_TRANSPORT_ZONE',
   'CREATE_TRANSPORT_CLUSTER',
   'CREATE_LOGICAL_SWITCH',
   'CREATE_LOGICAL_SWITCH_PORT',
   'CREATE_LOGICAL_SWITCH_PORT_WITH_VIF_ATTACH',
   'DELETE_IPPOOL',
   'DEALLOCATE_IP_FROM_POOL',
   'DELETE_ALL_SEGMENT_ID_RANGES',
   'DELETE_ALL_MULTICAST_IP_RANGES',
   'ADD_NEUTRON_PEER',
   'DETACH_LOGICAL_SWITCH_PORT',
   'DELETE_LOGICAL_SERVICES_NODE',
   'DELETE_DEPLOYMENT_CONTAINER_1',
   'DELETE_DEPLOYMENT_CONTAINER_2',
   'DELETE_ALL_LOGICAL_SWITCH_PORT',
   'DELETE_ALL_LOGICAL_SWITCH',
   'DELETE_ALL_TRANSPORT_CLUSTER',
   'DELETE_ALL_TRANSPORT_ZONE',
   'DELETE_ALL_TRANSPORT_NODE',
   'DELETE_NEUTRON_PEER',
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

use constant VSM_REGISTRATION => {
   Type          => "NSX",
   TestNSX       => "neutron.[1]",
   vsmregistration => {
      '[1]' =>  {
         name      => "vsm-1",
         ipaddress => "vsm.[1]",
         username  => "vsm.[1]",
         password  => "vsm.[1]",
         cert_thumbprint => "vsm.[1]",
      },
   },
};
use constant INIT_DATASTORE_1 => {
   Type         => "Host",
   TestHost => "host.[1]",
   datastore => {
      '[1]' => {
         name => "datastore1",
      },
   },
};

use constant INIT_DATASTORE_2 => {
   Type         => "Host",
   TestHost => "host.[2]",
   datastore => {
      '[1]' => {
         name => "datastore1",
      },
   },
};

use constant DEPLOYMENT_CONTAINER_1_CREATION => {
   Type          => "NSX",
   TestNSX       => "vsm.[1]",
   deploymentcontainer => {
      '[1]' =>  {
         name      => "nsx-dc",
         hypervisortype   => "vsphere",
         containerattributes    => [
            {
               "key" => "computeResource",
               "cluster_id" => "vc.[1].datacenter.[1].cluster.[1]",
            },
            {
               "key" => "storageResource",
               "datastoreid" => "host.[1].datastore.[1]",
            },
         ],
      },
   },
};

use constant DEPLOYMENT_CONTAINER_2_CREATION => {
   Type          => "NSX",
   TestNSX       => "vsm.[2]",
   deploymentcontainer => {
      '[1]' =>  {
         name      => "nsx-dc",
         hypervisortype   => "vsphere",
         containerattributes    => [
            {
               "key" => "computeResource",
               "cluster_id" => "vc.[2].datacenter.[1].cluster.[1]",
            },
            {
               "key" => "storageResource",
               "datastoreid" => "host.[2].datastore.[1]",
            },
         ],
      },
   },
};
use constant CREATE_IPPOOL => {
   Type      => "NSX",
   TestNSX   => "neutron.[1]",
   ippool   => {
      '[1]' => {
         name     => "TestIPPool-1-$$",
         subnets  => [
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
                   end     => "192.168.1.6",
                 },
                 {
                    start  => "192.168.1.10",
                    end    => "192.168.1.100"
                 },
               ],
               gateway_ip  => "192.168.1.1",
               ip_version  => 4,
               cidr        => "192.168.1.0/24",
            },
         ],
         metadata => {
           'expectedresultcode' => "201"
         },
      },
   },
};
use constant DELETE_IPPOOL => {
   Type           => "NSX",
   TestNSX        => "neutron.[1]",
   deleteippool   => "neutron.[1].ippool.[1]"
};
use constant ALLOCATE_IP_FROM_POOL => {
   Type                    => "GroupingObject",
   TestGroupingObject      => "neutron.[1].ippool.[1]",
   allocateip    => {
     '[1]'  => {
       schema  => '/v1/schema/PoolAllocatedResource',
     },
   },
};
use constant DEALLOCATE_IP_FROM_POOL => {
   Type                 => "GroupingObject",
   TestGroupingObject   => "neutron.[1].ippool.[1]",
   deleteallocateip      => "neutron.[1].ippool.[1].allocateip.[1]",
};
use constant CREATE_IPSET => {
    Type          => "NSX",
    TestNSX       => "neutron.[1]",
    ipset   => {
        '[1]' => {
            name    => "IPSet-1",
            value   => "192.168.0.101",
            metadata => {
            },
        },
    },
};
use constant CREATE_SEGMENT_ID_RANGE => {
   Type          => "NSX",
   TestNSX       => "neutron.[1]",
   segmentidrange => {
      '[1]' =>  {
         name      => "seg-1",
         begin     => "12001",
         end       => "18000",
         metadata => {
            'expectedresultcode' => "201",
         },
      },
   },
};

use constant CREATE_MULTICAST_IP_RANGE => {
   Type          => "NSX",
   TestNSX       => "neutron.[1]",
   multicastiprange => {
      '[1]' =>  {
         name      => "mcast-1",
         begin     => "224.1.0.1",
         end       => "224.5.0.1",
         metadata => {
            'expectedresultcode' => "201",
         },
      },
   },
};

use constant CREATE_LOGICAL_SERVICES_NODE => {
   Type         => "NSX",
   TestNSX      => "neutron.[1]",
   logicalservicesnode  => {
      '[1]' =>  {
         name    => "lsnode-1",
         capacity   => "SMALL",
         dns_settings     => {
            "domain_name"   => "node1",
            "primary_dns"   => "10.112.0.1",
            "secondary_dns" => "10.112.0.2",
         },
      },
   },
};

use constant CREATE_LOGICAL_SERVICES_NODE_INTERFACE => {
   Type         => "VM",
   TestVM      => "neutron.[1].logicalservicesnode.[1]",
   logicalservicesnodeinterface  => {
      '[1]' =>  {
         name => "intf-1",
         interface_number => 1,
         interface_type => "INTERNAL",
         interface_options => {
            "enable_send_redirects" => 0,
            "enable_proxy_arp"  => 0,
         },
         address_groups  => [
            {
               "primary_ip_address"    => VDNetLib::TestData::TestConstants::PRIMARY_IP_ADDRESS,
               "subnet"                => VDNetLib::TestData::TestConstants::DEFAULT_PREFIXLEN,
               "secondary_ip_addresses" => [
                                              VDNetLib::TestData::TestConstants::SECONDARY_IP_ADDRESS_1
                                           ],
            },
         ],
      },
   },
};

use constant CREATE_TRANSPORT_ZONE => {
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
   },
};

use constant CREATE_TRANSPORT_CLUSTER => {
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
         ],
         metadata => {
            expectedresultcode => "201",
         },
      },
   },
};

use constant CREATE_LOGICAL_SWITCH => {
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
};

use constant CREATE_LOGICAL_SWITCH_PORT => {
   Type         => "Switch",
   TestSwitch   => "neutron.[1].logicalswitch.[1]",
   sleepbetweenworkloads => "60",
   logicalswitchport    => {
      '[1]' =>  {
         name      => "lsp_1",
         attachment => {
            "type"  => "PatchAttachment",
            "peer_id" => "neutron.[1].logicalservicesnode.[1].logicalservicesnodeinterface.[1]",
         },
         metadata => {
            expectedresultcode => "201",
         },
      },
   },
};

use constant CREATE_LOGICAL_SWITCH_PORT_WITH_VIF_ATTACH => {
   Type         => "Switch",
   TestSwitch   => "neutron.[1].logicalswitch.[1]",
   logicalswitchport    => {
      '[1]' =>  {
         name      => "lsp_1",
         attachment => {
            "type"  => "VifAttachment",
            "vif_uuid" => "vm.[1].vnic.[1]",
            "host" => "esx",
         },
         metadata => {
            expectedresultcode => "201",
         },
      },
   },
};

use constant DELETE_ALL_SEGMENT_ID_RANGES => {
   Type         => "NSX",
   TestNSX       => "neutron.[1]",
   deletesegmentidrange   => "neutron.[1].segmentidrange.[-1]",
};

use constant DELETE_ALL_MULTICAST_IP_RANGES => {
   Type         => "NSX",
   TestNSX       => "neutron.[1]",
   deletemulticastiprange   => "neutron.[1].multicastiprange.[-1]",
};

use constant ADD_NEUTRON_PEER => {
   Type          => "NSX",
   TestNSX       => "neutron.[1]",
   neutronpeer => {
      '[2]' =>  {
         ipaddress => "neutron.[2]",
         username  => "neutron.[2]",
         password  => "neutron.[2]",
         cert_thumbprint => "neutron.[2]",
      },
      '[3]' =>  {
         ipaddress => "neutron.[3]",
         username  => "neutron.[3]",
         password  => "neutron.[3]",
         cert_thumbprint => "neutron.[3]",
      },
      '[4]' =>  {
         ipaddress => "neutron.[4]",
         username  => "neutron.[4]",
         password  => "neutron.[4]",
         cert_thumbprint => "neutron.[4]",
      },
   },
};

use constant DETACH_LOGICAL_SWITCH_PORT => {
   Type         => "Port",
   TestPort   => "neutron.[1].logicalswitch.[1].logicalswitchport.[1]",
   reconfigure   => "True",
   # Workaround for PR 1097377
   sleepbetweenworkloads => "60",
   attachment => {
      "type"  => "NoAttachment",
   },
   metadata => {
      expectedresultcode => "200",
   },
};

use constant DELETE_LOGICAL_SERVICES_NODE => {
   Type         => "NSX",
   TestNSX       => "neutron.[1]",
   deletelogicalservicesnode    => "neutron.[1].logicalservicesnode.[1]",
};

use constant DELETE_DEPLOYMENT_CONTAINER_1 => {
   Type         => "NSX",
   TestNSX       => "vsm.[1]",
   deletedeploymentcontainer    => "vsm.[1].deploymentcontainer.[1]",
};

use constant DELETE_DEPLOYMENT_CONTAINER_2 => {
   Type         => "NSX",
   TestNSX       => "vsm.[2]",
   deletedeploymentcontainer    => "vsm.[2].deploymentcontainer.[1]",
};

use constant DELETE_ALL_LOGICAL_SWITCH_PORT => {
   Type         => "Switch",
   TestSwitch   => "neutron.[1].logicalswitch.[1]",
   # Workaround for PR 1097377
   sleepbetweenworkloads => "60",
   deletelogicalswitchport  => "neutron.[1].logicalswitch.[1].logicalswitchport.[-1]",
};

use constant DELETE_ALL_LOGICAL_SWITCH => {
   Type         => "NSX",
   TestNSX       => "neutron.[1]",
   # Workaround for PR 1097377
   sleepbetweenworkloads => "60",
   deletelogicalswitch    => "neutron.[1].logicalswitch.[-1]",
};

use constant DELETE_ALL_TRANSPORT_NODE => {
   Type         => "NSX",
   TestNSX       => "neutron.[1]",
   # Workaround for PR 1097377
   sleepbetweenworkloads => "60",
   deletetransportnodecluster    => "neutron.[1].transportnode.[-1]",
};

use constant DELETE_ALL_TRANSPORT_CLUSTER => {
   Type         => "NSX",
   TestNSX       => "neutron.[1]",
   # Workaround for PR 1097377
   sleepbetweenworkloads => "60",
   deletetransportnodecluster    => "neutron.[1].transportnodecluster.[-1]",
};

use constant DELETE_ALL_TRANSPORT_ZONE => {
   Type         => "NSX",
   TestNSX       => "neutron.[1]",
   # Workaround for PR 1097377
   sleepbetweenworkloads => "60",
   deletetransportzone   => "neutron.[1].transportzone.[-1]",
};

use constant DELETE_NEUTRON_PEER => {
   Type         => "NSX",
   TestNSX       => "neutron.[1]",
   deleteneutronpeer   => "neutron.[1].neutronpeer.[2]",
};

1;
