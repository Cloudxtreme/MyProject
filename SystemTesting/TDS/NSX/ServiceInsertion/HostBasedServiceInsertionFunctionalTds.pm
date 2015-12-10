#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::ServiceInsertion::HostBasedServiceInsertionFunctionalTds;

#
# This file contains the structured hash for category, HostBasedServiceInsertionFunctional tests
# The following lines explain the keys of the internal
# Hash in general.
#

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/..";

use VDNetLib::TestData::TestConstants;
use TDS::Main::VDNetMainTds;

@ISA = qw(TDS::Main::VDNetMainTds);

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("");

   %HostBasedServiceInsertionFunctional = (
      'ServiceInsertionPreInstall' => {
         Category         => 'vShield',
         Component        => 'Service Insertion',
         TestName         => "ServiceInsertionPreInstall",
         Version          => "2" ,
         Tags             => "si",
         Summary          => "Initial setup before running service insertion scripts",
         'TestbedSpec' => {
            'vsm' => {
               '[1]' => {
                  reconfigure => "true",
                  vc          => 'vc.[1]',
                  assignrole  => "enterprise_admin",
               },
            },
            'vc' => {
               '[1]' => {
                  datacenter  => {
                     '[1]'   => {
                         cluster => {
                           '[1]' => {
                              name => "Controller-Cluster-$$",
                              drs  => 1,
                              host => "host.[1]",
                           },
                        },
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-4]' => {
                          },
                        },
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-4]' => {
                          },
                        },
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic  => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        connected => 1,
                        startconnected => 1,
                        allowguestcontrol => 1,
                     },
                  },
                  vmstate         => "poweron",
               },
               '[2]'   => {
                  host  => "host.[1]",
                  vnic => {
                     '[1]'   => {
                        driver     => "vmxnet3",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                        connected => 1,
                        startconnected => 1,
                        allowguestcontrol => 1,
                     },
                  },
                  vmstate         => "poweron",
               },
               '[3-4]'   => {
                  host  => "host.[1]",
                  vmstate         => "poweroff",
               },
            },
         },
         'WORKLOADS' => {
            Sequence => [
                          ['ConnectVSMToVC'], # Remove once PR 1381353 is resolved
                          ['GetDatastore'],
                          ['SetSegmentIDRange'],
                          ['SetMulticastRange'],
                          ['HostPrepAndVTEPCreate'],
                          ['CreateNetworkScope'],
                          ['CreateVirtualWires'],
                          ['AddvNICsOnVM3VM4'],
                          ['PoweronVM3VM4'],
                          ['MakeSurevNICConnected'],
                          ['SetVXLANIPVM3','SetVXLANIPVM4SamevWire'],
                          ['PingTestVM3VM4'],
                          ['CreateServiceManager'],
                          ['CreateService'],
                          ['CreateVendorTemplate'],
                          ['GetServiceInstance'],
                          ['CreateVersionedDeploymentSpec'],
                          ['DeployService'],
                          ['CheckSVMDeploymentStatus'],
                          ['CreateServiceProfile'],
                          ['UpdateBinding'],
                          ['CheckDVFilter'],
                          ['Ping1'],
                          ['RemoveBinding'],
                          ['DeleteServiceCluster'],
                          ['DeleteServiceProfile'],
                          ['DeleteServiceInstance'],
                          ['DeleteVendorTemplate'],
                          ['CheckSVMUndeploymentStatus'],
                          ['DeleteService'],
                          ['DeleteServiceManager'],
                          ['PoweroffVM3VM4'],
                          ['RemovevNICFromVM3to4'],
                          ['DeleteVirtualWires'],
                          ['DeleteNetworkScopes'],
                          ['UnconfigureVXLAN'],
                          ['ResetSegmentID'],
                          ['ResetMulticast'],
                        ],
            'ConnectVSMToVC' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               reconfigure => "true",
               vc => 'vc.[1]',
               assignrole  => "enterprise_admin",
            },
            'GetDatastore' => {
               Type         => "Host",
               TestHost => "host.[1]",
               datastore => {
                  '[1]' => {
                    name => "vdnetSharedStorage",
                  },
               },
            },
            'SetSegmentIDRange' => SET_SEGMENTID_RANGE,
            'SetMulticastRange' => SET_MULTICAST_RANGE,
            'HostPrepAndVTEPCreate' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[1]",
                     vibs         => "install",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => VDNetLib::TestData::TestConstants::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => VDNetLib::TestData::TestConstants::ARRAY_VXLAN_CONFIG_TEAMING_POLICIES,
                  },
               },
            },
            'CreateNetworkScope' => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1-$$",
                     clusters     => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'CreateVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name               => "AutoGenerate",
                     tenantid           => "1",
                  },
               },
            },
            'AddvNICsOnVM3VM4' => {
               Type   => "VM",
               TestVM => "vm.[3],vm.[4]",
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
            'PoweronVM3VM4' => {
               Type    => "VM",
               TestVM  => "vm.[3-4]",
               vmstate => "poweron",
            },
            'MakeSurevNICConnected' => {
               Type           => "NetAdapter",
               reconfigure    => "true",
               testadapter    => "vm.[3-4].vnic.[1]",
               connected      => 1,
               startconnected => 1,
            },
            "SetVXLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '172.32.1.5',
               netmask    => "255.255.0.0",
            },
            "SetVXLANIPVM4SamevWire" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '172.32.1.6',
               netmask    => "255.255.0.0",
            },
            "PingTestVM3VM4" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[4].vnic.[1]",
               NoofOutbound   => 1,
               NoofInbound    => 1,
               TestDuration   => "30",
            },
            'CreateServiceManager' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               servicemanager => {
                   '[1]' => {
                           'name' => "ABC Company Service Manager $$",
                           'description' => "ABC Company Service Manager Desc",
                           'revision' => "4",
                           'objecttypename' => "ServiceManager",
                           'vendorname' => "ABC Vendor Name",
                           'vendorid' => "ABC Vendor ID",
                           'thumbprint' => "",
                           'username' => "",
                           'password' => "",
                           'verifypassword' => "",
                           'url' => "",
                           'resturl' => "",
                           'status' => "IN_SERVICE",
                    },
               },
            },
            'CreateService' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               service => {
                    '[1]' => {
                            'name' => "ABC Company Service",
                            'servicemanager' => {
                               'objectid' => "vsm.[1].servicemanager.[1]",
                            },
                            'implementations' => [
                             {
                                 'type' => 'HOST_BASED_VNIC',
                             }
                            ],
                            'transports' => [
                             {
                                'type' => 'VMCI',
                             },
                            ],
                            'serviceattributes' => [
                               {
                                  'key' => 'agentName',
                                  'name' => 'Agent Name',
                                  'value' => 'My_agent',
                               },
                               {
                                  'key' => 'failOpen',
                                  'name' => 'Fail Open',
                                  'value' => 'true',
                               },
                               {
                                   'key' => 'default-action',
                                   'name' => 'Default Action',
                                   'value' => 'ACTION_ACCEPT',
                               },
                              ],
                            'vendortemplates' => '',
                            'usedby' => '',
                    },
               },
            },
            'CreateVendorTemplate' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               vendortemplate => {
                    '[1]' => {
                            'name' => "ABC Company Vendor Template",
                            'description' => 'ABC Company Vendor Template Description',
                            'vendorid' => 'ABC Company Vendor Id',
                            'vendorattributes' => [
                             {
                                 'key' => 'Key 1',
                                 'name' => 'Value 1',
                                 'value' => 'Name 1',
                             },
                             {
                                 'key' => 'Key 2',
                                 'name' => 'Value 2',
                                 'value' => 'Name 2',
                             },
                            ],
                    },
               },
            },
            'GetServiceInstance' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               serviceinstance => {
                    '[1]' => {
                       'serviceid' => "vsm.[1].service.[1]",
                    },
               },
            },
            'CreateVersionedDeploymentSpec' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               versioneddeploymentspec => {
                    '[1]' => {
                            'hostversion' => "5.5.*",
                            'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL,
                            'vmcienabled' => "true",
                    },
               },
            },
            'DeployService' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               clusterdeploymentconfigs => {
                 '[1]' =>
                     {
                        'clusterdeploymentconfigarray' => [
                        {
                            'clusterid' => "vc.[1].datacenter.[1].cluster.[1]",
                            'datastore' => "host.[1].datastore.[1]",
                            'services' => [
                             {
                                'serviceinstanceid' => "vsm.[1].serviceinstance.[1]",
                                'dvportgroup' => "vc.[1].dvportgroup.[2]",
                             },
                            ],
                        },
                       ],
                     },
               },
            },
            'CheckSVMDeploymentStatus' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               verifyendpointattributes => {
                     'progressstatus[?]equal_to' => "SUCCEEDED",
               },
               noofretries  => "20",
            },
            'CreateServiceProfile' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               serviceprofile => {
                   '[1]' => {
                         'name' => 'ABC Company Service Profile Name',
                         'description' => 'ABC Company Service Profile Name Description',
                         'service' =>{
                              'objectid' => "vsm.[1].service.[1]",
                         },
                         'serviceinstance' => {
                              'objectid' => "vsm.[1].serviceinstance.[1]",
                         },
                         'vendortemplateattribute' => {
                              'id' => "vsm.[1].service.[1].vendortemplate.[1]",
                              'name' => "ABC Company Vendor Template",
                              'description' => "ABC Company Vendor Template Description",
                              'vendorid' => "Vendor-ID",
                         },
                         'profileattributes' =>[
                           {
                                'key' => 'tenantID',
                                'name' => 'Tenant',
                                'value' => 'tenant',
                           },
                           {
                                'key' => 'ssl_encryption_questions__offload_ssl',
                                'name' => 'SSL encryption offload',
                                'value' => 'No',
                           },
                           {
                                'key' => 'basic__addr',
                                'name' => 'Virtual server address',
                                'value' => '80',
                           },
                          ],
                          'vendorattributes' => [
                            {
                                'key' => 'server_pools__create_new_pool',
                                'name' => 'Server pool',
                                'value' => 'Create New Pool',
                            },
                            {
                                'key' => 'optimizations__lan_or_wan',
                                'name' => 'Network Optimization',
                                'value' => 'Lan',
                            },
                           ],
                    },
               },
            },
            'UpdateBinding' => {
               Type       => 'ServiceProfile',
               TestServiceProfile    => "vsm.[1].serviceprofile.[1]",
               serviceprofilebinding => {
                  'virtualwires' => {
                     'virtualwireid' => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  },
                  'excludedvnics' => '',
                  'virtualservers' => '',
                  'distributedvirtualportgroups' =>{
                     'string' => "vc.[1].dvportgroup.[1]",
                  },
               },
            },
            'CheckDVFilter' => {
                'Type' => 'Command',
                'command' => 'summarize-dvfilter',
                'testhost' => 'host.[1]',
            },
            'Ping1' => {
               Type             => "Traffic",
               ToolName         => "ping",
               TestAdapter      => "vm.[1].vnic.[1]",
               SupportAdapter   => "vm.[2].vnic.[1]",
               TestDuration     => "10",
               sleepbetweenworkloads => '120'
            },
            'RemoveBinding' => {
               Type       => 'ServiceProfile',
               TestServiceProfile    => "vsm.[1].serviceprofile.[1]",
               serviceprofilebinding => {
                  'virtualwires' => {
                     'virtualwireid' => "",
                  },
                  'excludedvnics' => '',
                  'virtualservers' => '',
                  'distributedvirtualportgroups' =>{
                     'string' => "",
                  },
               },
            },
            'DeleteServiceCluster' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               deleteclusterdeploymentconfigs => "vsm.[1].service.[1].clusterdeploymentconfigs.[1]",
            },
            'DeleteServiceProfile' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteserviceprofile => "vsm.[1].serviceprofile.[1]",
            },
            'DeleteServiceInstance' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteserviceinstance => "vsm.[1].serviceinstance.[1]",
            },
            'DeleteVendorTemplate' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               deletevendortemplate => "vsm.[1].service.[1].vendortemplate.[1]",
            },
            'CheckSVMUndeploymentStatus' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               verifyendpointattributes => {
                  'progressstatus[?]equal_to' => undef,
               },
               noofretries  => "5",
            },
            'DeleteService' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteservice => "vsm.[1].service.[1]",
            },
            'DeleteServiceManager' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteservicemanager => "vsm.[1].servicemanager.[1]",
            },
            'PoweroffVM3VM4' => {
               Type    => "VM",
               TestVM  => "vm.[3-4]",
               vmstate => "poweroff",
            },
            'RemovevNICFromVM3to4' => {
               Type       => "VM",
               TestVM     => "vm.[3-4]",
               deletevnic => "vm.[x].vnic.[1]",
            },
            'DeleteVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'DeleteNetworkScopes' => DELETE_ALL_NETWORKSCOPES,
            'UnconfigureVXLAN' => {
               Type         => 'Cluster',
               testcluster  => "vsm.[1].vdncluster.[1]",
               vxlan        => "unconfigure",
            },
            'ResetSegmentID' => RESET_SEGMENTID,
            'ResetMulticast' => RESET_MULTICASTRANGE,
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for HostBasedServiceInsertionFunctionalTds
#
# Input:
#       none
#
# Results:
#       An instance/object of HostBasedServiceInsertionFunctionalTds class
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
   my $self = $class->SUPER::new(\%HostBasedServiceInsertionFunctional);
   return (bless($self, $class));
}

1;
