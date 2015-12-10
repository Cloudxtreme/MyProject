#!/usr/bin/perl
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::ServiceInsertion::HostBasedServiceInsertionFunctionalWithVersionGreaterThan61Tds;

#
# This file contains the structured hash for category, HostBasedServiceInsertionFunctionalWithVersionGreaterThan61 tests
# The following testcases are valid for 6.1 vsm or later
# The following lines explain the keys of the internal
# Hash in general.
#

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use lib "$FindBin::Bin/../../..";

use VDNetLib::TestData::TestConstants;
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

@ISA = qw(TDS::Main::VDNetMainTds);

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';
use TDS::NSX::ServiceInsertion::CommonWorkloads ':AllConstants';

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("");

   %HostBasedServiceInsertionFunctionalWithVersionGreaterThan61 = (
      'ServiceInsertionPreInstall' => {
         Category         => 'vShield',
         Component        => 'Service Insertion',
         Product          => 'VSM',
         QCPath           => '',
         Procedure        => '1. Create Service Manager and Service' .
                                'with implementation type as' .
                                'HOST_BASED_VNIC' .
                             '2. Create Vendor Template and '.
                                'Versioned Deployment Spec' .
                             '3. Get default service instance'.
                                'and default service profile'.
                             '4. Deploy service vm'.
                                'and check svm status'.
                             '5. Create Security Group'.
                                'VM1 -- WebSG'.
                                'VM2 -- AppSG'.
                                'VM3 -- DBSG'.
                             '6. Create L3 Redirect rules'.
                                'WebSG <--> AppSG - Redirect'.
                                'AppSG <--> DBSG - Redirect'.
                                'WebSG --> DBSG - Allow'.
                             '7. Create L3 rule'.
                                'DBSG --> WebSG - Deny'.
                             '8. Verify with traffic patterns',
         ExpectedResult   => 'Host based service insertion deployment ',
         Status           => 'Execution Ready',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'abhishekshah',
         Partnerfacing    => 'Y',
         Duration         => '',
         TestName         => "ServiceInsertionPreInstall",
         Version          => "2" ,
         Tags             => "si, 6.1",
         Summary          => "Host based service insertion testcase with rule applied to security group",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_OneHost_OneVmnicForHost_FourVMs,
         'WORKLOADS' => {
            Sequence => [
               ['GetDatastore'],
               ['AddvNICsOnVM1VM2VM3'],
               ['PoweronVM1VM2VM3'],
               ['PrepCluster'],
               ['CreateServiceManager'],
               ['CreateService'],
               ['CreateVendorTemplate'],
               ['GetServiceInstance'],
               ['CreateVersionedDeploymentSpec'],
               ['DeployService'],
               ['CheckSVMDeploymentStatus'],
               ['GetServiceProfile'],
               ['SecurityGroupCreation'],
               ['WebAppDBTrafficPatternRules'],
               ['TrafficTCP_VM1_VM2'],
               ['TrafficTCP_VM2_VM3'],
               ['TrafficTCP_VM1_VM3'],
               ['TrafficTCP_VM3_VM1'],
            ],
            ExitSequence => [
               ['RevertToDefaultRules'],
               ['SecurityGroupDeletion'],
               ['DeleteServiceCluster'],
               ['DeleteServiceProfile'],
               ['DeleteServiceInstance'],
               ['DeleteVendorTemplate'],
               ['CheckSVMUndeploymentStatus'],
               ['DeleteService'],
               ['DeleteServiceManager'],
               ['PoweroffVM1VM2VM3'],
               ['RemovevNICFromVM1to3'],
            ],
            'GetDatastore' => {
               Type         => "Host",
               TestHost => "host.[1]",
               datastore => {
                  '[1]' => {
                     name => "vdnetSharedStorage",
                  },
               },
            },
            'AddvNICsOnVM1VM2VM3' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2],vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM1VM2VM3' => {
               Type    => "VM",
               TestVM  => "vm.[1-3]",
               vmstate => "poweron",
            },

            'PrepCluster' => PREP_CLUSTER,
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
                     'functionalities' => [
                     {
                        'type' => 'IDS_IPS',
                     },
                     {
                        'type' => 'FIREWALL',
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
                     'functionalities' => [
                     {
                        'type' => 'IDS_IPS',
                     },
                     {
                        'type' => 'FIREWALL',
                     },
                     ],
                     'vendorattributes' => [
                     {
                        'key' => 'owa-hostname',
                        'name' => 'Name 1',
                        'value' => 'owa.myhost.com',
                     },
                     ],
                     'typedattributes' => [
                     {
                        'key' => 'SSL_CERT',
                        'type' => 'PEM_CERT',
                        'value' => '-----BEGIN CERTIFICATE----- Sample -----END CERTIFICATE-----',
                        'name' => "SSL certificate",
                     },
                     {
                        'key' => 'SSL_KEY',
                        'type' => 'PEM_KEY',
                        'value' => 'Ssl_key_value_1',
                        'name' => "SSL key",
                     },
                     {
                        'key' => 'SSL_KEY_ENUM',
                        'type' => 'STRING_ENUM',
                        'value' => 'HTTP',
                        'name' => "SSL Key",
                        'supportedvalues' => "HTTP, HTTPS",
                     },
                     ],
                     'typedattributetables' => [
                     {
                        'name' => 'ip_pool',
                        'description' => "members of ip pool",
                        'header' => [
                        {
                           'key' => "Server_ip",
                           'type' => "IP_ADDRESS",
                           'value' => "192.168.1.2",
                           'name' => "Server IP",
                        },
                        {
                           'key' => "Weight_RR",
                           'type' => "STRING",
                           'value' => "",
                           'name' => "Weight of RR",
                        },
                        {
                           'key' => "ratio",
                           'type' => "STRING",
                           'value' => "",
                           'name' => "ratio",
                        },
                        ],
                     },
                     {
                        'name' => 'List',
                        'description' => "Description of the list",
                        'header' => [
                        {
                           'key' => "list",
                           'type' => "STRING",
                           'value' => "list value",
                           'name' => "list description",
                        },
                        ],
                     },
                     ],
                     'vendorsections' => [
                     {
                         'name' => "VendorSection_DB",
                         'description' => "DB Virtual Server",
                         'typedattributetables' => [
                         {
                            'name' => 'ip_pool',
                            'description' => "members of ip pool",
                            'header' => [
                            {
                               'key' => "Server_ip",
                               'type' => "IP_ADDRESS",
                               'value' => "192.168.1.3",
                               'name' => "Server Ip",
                            },
                            {
                               'key' => "Weight_RR",
                               'type' => "STRING",
                               'value' => "",
                               'name' => "Weight of RR",
                            },
                            {
                               'key' => "ratio",
                               'type' => "STRING",
                               'value' => "",
                               'name' => "ratio",
                            },
                            ],
                         },
                         {
                            'name' => 'ip_pool',
                            'description' => "members of ip pool",
                            'header' => [
                            {
                               'key' => "list",
                               'type' => "STRING",
                               'value' => "list",
                               'name' => "list",
                            },
                            ],
                         },
                         ],
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
                     'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL_RHEL6_32BIT_61SVM,
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
            'GetServiceProfile' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               serviceprofile => {
                  '[1]' => {
                     'getserviceprofileflag' => "true",
                     'serviceprofilename' => "ABC Company Service_ABC Company Vendor Template",
                  },
               },
            },
            'SecurityGroupCreation' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               securitygroup => {
                  '[1]' => {
                     'name' => "Web Security Group",
                     'sg_description' => "Web Security Group Description",
                     'objecttypename' => "SecurityGroup",
                     'type' => {
                        'typename' => "SecurityGroup",
                     },
                     'scope' => {
                        'id' => "globalroot-0",
                        'objecttypename' => "GlobalRoot",
                        'name' => "Global",
                     },
                     'member' => [
                     {
                        'vm_id' => "vm.[1]",
                        'objecttypename' => "VirtualMachine",
                     },
                     ],
                  },
                  '[2]' => {
                     'name' => "App Security Group",
                     'sg_description' => "App Security Group Description",
                     'objecttypename' => "SecurityGroup",
                     'type' => {
                        'typename' => "SecurityGroup",
                     },
                     'scope' => {
                        'id' => "globalroot-0",
                        'objecttypename' => "GlobalRoot",
                        'name' => "Global",
                     },
                     'member' => [
                     {
                        'vm_id' => "vm.[2]",
                        'objecttypename' => "VirtualMachine",
                     },
                     ],
                  },
                  '[3]' => {
                     'name' => "DB Security Group",
                     'sg_description' => "DB Security Group Description",
                     'objecttypename' => "SecurityGroup",
                     'type' => {
                        'typename' => "SecurityGroup",
                     },
                     'scope' => {
                        'id' => "globalroot-0",
                        'objecttypename' => "GlobalRoot",
                        'name' => "Global",
                     },
                     'member' => [
                     {
                        'vm_id' => "vm.[3]",
                        'objecttypename' => "VirtualMachine",
                     },
                     ],
                  },
               },
            },
            "WebAppDBTrafficPatternRules" => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                     layer     => "layer3redirect",
                     name      => 'Redirect Traffic between Web and App',
                     action    => 'Redirect',
                     section   => 'default',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
                        # Temporary Fix to accomodate bug #1288673
                        name => 'ABC Company Service_ABC Company Vendor Template',
                     },
                     sources   => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[2]",
                     },
                     ],
                     destinations => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[2]",
                     },
                     ],
                     appliedto => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[2]",
                     },
                     ],
                  },
                  '[2]' => {
                     layer     => "layer3redirect",
                     name      => 'Redirect Traffic between App and DB',
                     action    => 'Redirect',
                     section   => 'default',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
                        # Temporary Fix to accomodate bug #1288673
                        name => 'ABC Company Service_ABC Company Vendor Template',
                     },
                     sources   => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[2]",
                     },
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[3]",
                     },
                     ],
                     destinations => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[2]",
                     },
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[3]",
                     },
                     ],
                     appliedto => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[3]",
                     },
                     ],
                  },
                  '[3]' => {
                     layer     => "layer3redirect",
                     name      => 'Do not redirect Traffic between Web and DB',
                     action    => 'Allow',
                     section   => 'default',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
                        # Temporary Fix to accomodate bug #1288673
                        name => 'ABC Company Service_ABC Company Vendor Template',
                     },
                     sources   => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[3]",
                     },
                     ],
                     destinations => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[3]",
                     },
                     ],
                  },
                  '[4]' => {
                      name    => 'Block traffice from DB to Web',
                      action  => 'deny',
                      layer => 'layer3',
                      sources   => [
                      {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[3]",
                      },
                      ],
                      destinations => [
                      {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                      },
                      ],
                      appliedto => [
                      {
                         type  => 'SecurityGroup',
                         value => "vsm.[1].securitygroup.[3]",
                      },
                      ],
                  },
               },
            },
            "TrafficTCP_VM1_VM2" => {
               Type           => "Traffic",
               Expectedresult => "PASS",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestDuration   => "5",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
            "TrafficTCP_VM2_VM3" => {
               Type           => "Traffic",
               Expectedresult => "PASS",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestDuration   => "5",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
            },
            "TrafficTCP_VM1_VM3" => {
               Type           => "Traffic",
               Expectedresult => "PASS",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               NoofOutbound   => "1",
               TestDuration   => "5",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
            },
            "TrafficTCP_VM3_VM1" => {
               Type           => "Traffic",
               Expectedresult => "FAIL",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               NoofOutbound   => "1",
               TestDuration   => "5",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
            },
            "RevertToDefaultRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               firewallrule => {
                  '[-1]' => {}
               }
            },
            "SecurityGroupDeletion" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletesecuritygroup => "vsm.[1].securitygroup.[1-3]",
            },
            'DeleteServiceCluster' => DELETE_SERVICE_CLUSTER,
            'DeleteServiceProfile' => DELETE_SERVICE_PROFILE,
            'GetDefaultServiceProfile' => GET_SERVICE_PROFILE,
            'DeleteServiceInstance' => DELETE_SERVICE_INSTANCE,
            'DeleteVendorTemplate' => DELETE_VENDOR_TEMPLATE,
            'CheckSVMUndeploymentStatus' => CHECK_SVM_UNDEPLOYMENT_STATUS,
            'DeleteService' => DELETE_SERVICE,
            'DeleteServiceManager' => DELETE_SERVICE_MANAGER,
            'PoweroffVM1VM2VM3' => {
               Type    => "VM",
               TestVM  => "vm.[1-3]",
               vmstate => "poweroff",
            },
            'RemovevNICFromVM1to3' => {
               Type       => "VM",
               TestVM     => "vm.[1-3]",
               deletevnic => "vm.[x].vnic.[1]",
            },
         },
      },
      'BindingToUserGeneratedProfile' => {
         Category         => 'vShield',
         Component        => 'Service Insertion',
         TestName         => "BindingToUserGeneratedProfile",
         Version          => "2" ,
         Tags             => "si, 6.1",
         Summary          => "Script to test host based service insertion " .
                             "not using default service profile " .
                             "on 6.1 vsm and later ",
         Procedure        => '1. Deploy host based service insertion ' .
                             '2. Check Service VM is installed '.
                             '3. Remove host based service insertion ',
         ExpectedResult   => 'Host based services should be installed ' .
                             'and removed successfully',
         Status           => 'Execution Ready',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'abhishekshah',
         Partnerfacing    => 'Y',
         Duration         => '',
         'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_OneHost_OneVmnicForHost_FourVMs,
         'WORKLOADS' => {
            Sequence => [
                          ['GetDatastore'],
                          ['AddvNICsOnVM1VM2'],
                          ['PoweronVM1VM2'],
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
                          ['CreatePuntRule'],
                          ['CheckDVFilter'],
                          ['PingVM1ToVM2'],
                          ['RemoveBinding'],
                          ['DeleteServiceCluster'],
                          ['DeleteServiceProfile'],
                          ['GetDefaultServiceProfile'],
                          ['DeleteServiceProfile'],
                          ['DeleteServiceInstance'],
                          ['DeleteVendorTemplate'],
                          ['CheckSVMUndeploymentStatus'],
                          ['DeleteService'],
                          ['DeleteServiceManager'],
                        ],
            ExitSequence => [
                               ['PoweroffVM1VM2'],
                               ['RemovevNICFromVM1to2'],
                               ['PoweroffVM3VM4'],
                               ['RemovevNICFromVM3to4'],
                               ['DeleteVirtualWires'],
                               ['DeleteNetworkScopes'],
                               ['UnconfigureVXLAN'],
                               ['ResetSegmentID'],
                               ['ResetMulticast'],
                            ],
            'GetDatastore' => GET_DATASTORE,
            'AddvNICsOnVM1VM2' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweron",
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
                     name         => "network-scope-1",
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
            'CreateServiceManager' => CREATE_SERVICE_MANAGER,
            'CreateService' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               service => {
                    '[1]' => {
                            'name' => "ABC Company Service",
                            'servicemanager' => {
                               'objectid' => "vsm.[1].servicemanager.[1]",
                            },
                            'functionalities' => [
                            {
                               'type' => 'IDS_IPS',
                            },
                            ],
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
            'CreateVendorTemplate' => CREATE_VENDOR_TEMPLATE,
            'GetServiceInstance' => GET_SERVICE_INSTANCE,
            'CreateVersionedDeploymentSpec' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               versioneddeploymentspec => {
                    '[1]' => {
                            'hostversion' => "5.5.*",
                            'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL_RHEL6_32BIT_61SVM,
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
            'CheckSVMDeploymentStatus' => CHECK_SVM_DEPLOYMENT_STATUS,
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
           'CreatePuntRule' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                     layer     => "layer3redirect",
                     name      => 'Redirect Traffic between VM1 and VM2',
                     action    => 'Redirect',
                     section   => 'default',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
                        name => 'ABC Company Service Profile Name',
                     },
                     sources   => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[1]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[2]",
                     },
                     ],
                     destinations => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[1]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[2]",
                     },
                     ],
                  },
                  '[2]' => {
                     layer     => "layer3redirect",
                     name      => 'Redirect Traffic between VM3 and VM4',
                     action    => 'Redirect',
                     section   => 'default',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
                        name => 'ABC Company Service Profile Name',
                     },
                     sources   => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[3]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[4]",
                     },
                     ],
                     destinations => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[3]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[4]",
                     },
                     ],
                  },
               },
            },
            'CheckDVFilter' => CHECK_DVFILTER,
            'PingVM1ToVM2' => {
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
            'DeleteServiceCluster' => DELETE_SERVICE_CLUSTER,
            'DeleteServiceProfile' => DELETE_SERVICE_PROFILE,
            'GetDefaultServiceProfile' => GET_SERVICE_PROFILE,
            'DeleteServiceInstance' => DELETE_SERVICE_INSTANCE,
            'DeleteVendorTemplate' => DELETE_VENDOR_TEMPLATE,
            'CheckSVMUndeploymentStatus' => CHECK_SVM_UNDEPLOYMENT_STATUS,
            'DeleteService' => DELETE_SERVICE,
            'DeleteServiceManager' => DELETE_SERVICE_MANAGER,
            'PoweroffVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweroff",
            },
            'RemovevNICFromVM1to2' => {
               Type       => "VM",
               TestVM     => "vm.[1-2]",
               deletevnic => "vm.[x].vnic.[1]",
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
      'BindingToUserGeneratedProfileVsphere6' => {
         Category         => 'vShield',
         Component        => 'Service Insertion',
         TestName         => "BindingToUserGeneratedProfileVsphere6",
         Version          => "2" ,
         Tags             => "si, 6.1.*",
         Summary          => "Script to test host based service insertion " .
                             "not using default service profile " .
                             "on 6.1 vsm and later and vsphere 6 ",
         Procedure        => '1. Deploy host based service insertion ' .
                             '2. Check Service VM is installed '.
                             '3. Remove host based service insertion ',
         ExpectedResult   => 'Host based services should be installed ' .
                             'and removed successfully',
         Status           => 'Execution Ready',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'abhishekshah',
         Partnerfacing    => 'Y',
         Duration         => '',
         'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_OneHost_OneVmnicForHost_FourVMs,
         'WORKLOADS' => {
            Sequence => [
                          ['GetDatastore'],
                          ['PoweronVM1VM2'],
                          ['AddvNICsOnVM1VM2'],
                          ['SetSegmentIDRange'],
                          ['SetMulticastRange'],
                          ['HostPrepAndVTEPCreate'],
                          ['CreateNetworkScope'],
                          ['CreateVirtualWires'],
                          ['PoweronVM3VM4'],
                          ['AddvNICsOnVM3VM4'],
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
                          ['CreatePuntRule'],
                          ['CheckDVFilter'],
                          ['PingVM1ToVM2'],
                          ['RemoveBinding'],
                          ['DeleteServiceCluster'],
                          ['DeleteServiceProfile'],
                          ['GetDefaultServiceProfile'],
                          ['DeleteServiceProfile'],
                          ['DeleteServiceInstance'],
                          ['DeleteVendorTemplate'],
                          ['CheckSVMUndeploymentStatus'],
                          ['DeleteService'],
                          ['DeleteServiceManager'],
                        ],
            ExitSequence => [
                               ['PoweroffVM1VM2'],
                               ['RemovevNICFromVM1to2'],
                               ['PoweroffVM3VM4'],
                               ['RemovevNICFromVM3to4'],
                               ['DeleteVirtualWires'],
                               ['DeleteNetworkScopes'],
                               ['UnconfigureVXLAN'],
                               ['ResetSegmentID'],
                               ['ResetMulticast'],
                            ],
            'GetDatastore' => GET_DATASTORE,
            'AddvNICsOnVM1VM2' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweron",
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
                  },
               },
            },
            'CreateNetworkScope' => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1",
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
            'CreateServiceManager' => CREATE_SERVICE_MANAGER,
            'CreateService' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               service => {
                    '[1]' => {
                            'name' => "ABC Company Service",
                            'servicemanager' => {
                               'objectid' => "vsm.[1].servicemanager.[1]",
                            },
                            'functionalities' => [
                            {
                               'type' => 'IDS_IPS',
                            },
                            ],
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
            'CreateVendorTemplate' => CREATE_VENDOR_TEMPLATE,
            'GetServiceInstance' => GET_SERVICE_INSTANCE,
            'CreateVersionedDeploymentSpec' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               versioneddeploymentspec => {
                    '[1]' => {
                            'hostversion' => "6.0.*",
                            'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL_RHEL6_32BIT_61SVM,
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
            'CheckSVMDeploymentStatus' => CHECK_SVM_DEPLOYMENT_STATUS,
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
           'CreatePuntRule' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                     layer     => "layer3redirect",
                     name      => 'Redirect Traffic between VM1 and VM2',
                     action    => 'Redirect',
                     section   => 'default',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
                        name => 'ABC Company Service Profile Name',
                     },
                     sources   => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[1]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[2]",
                     },
                     ],
                     destinations => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[1]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[2]",
                     },
                     ],
                  },
                  '[2]' => {
                     layer     => "layer3redirect",
                     name      => 'Redirect Traffic between VM3 and VM4',
                     action    => 'Redirect',
                     section   => 'default',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
                        name => 'ABC Company Service Profile Name',
                     },
                     sources   => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[3]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[4]",
                     },
                     ],
                     destinations => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[3]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[4]",
                     },
                     ],
                  },
               },
            },
            'CheckDVFilter' => CHECK_DVFILTER,
            'PingVM1ToVM2' => {
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
            'DeleteServiceCluster' => DELETE_SERVICE_CLUSTER,
            'DeleteServiceProfile' => DELETE_SERVICE_PROFILE,
            'GetDefaultServiceProfile' => GET_SERVICE_PROFILE,
            'DeleteServiceInstance' => DELETE_SERVICE_INSTANCE,
            'DeleteVendorTemplate' => DELETE_VENDOR_TEMPLATE,
            'CheckSVMUndeploymentStatus' => CHECK_SVM_UNDEPLOYMENT_STATUS,
            'DeleteService' => DELETE_SERVICE,
            'DeleteServiceManager' => DELETE_SERVICE_MANAGER,
            'PoweroffVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweroff",
            },
            'RemovevNICFromVM1to2' => {
               Type       => "VM",
               TestVM     => "vm.[1-2]",
               deletevnic => "vm.[x].vnic.[1]",
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
      'CopyPacketToServiceVM' => {
         Category         => 'vShield',
         Component        => 'Service Insertion',
         TestName         => "CopyPacketToServiceVM",
         Version          => "2" ,
         Tags             => "si, 6.2.*",
         Summary          => "Script to test host based service insertion " .
                             "using copy packets to service vm " .
                             "on 6.2 vsm and later and vsphere 6 ",
         Procedure        => '1. Deploy host based service insertion ' .
                             '2. Check Service VM is installed '.
                             '3. Remove host based service insertion ',
         ExpectedResult   => 'Host based services should be installed ' .
                             'and removed successfully',
         Status           => 'Execution Ready',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'abhishekshah',
         Partnerfacing    => 'Y',
         Duration         => '',
         'TestbedSpec' => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_OneHost_OneVmnicForHost_FourVMs,
         'WORKLOADS' => {
            Sequence => [
                          ['GetDatastore'],
                          ['PoweronVM1VM2'],
                          ['AddvNICsOnVM1VM2'],
                          ['SetSegmentIDRange'],
                          ['SetMulticastRange'],
                          ['HostPrepAndVTEPCreate'],
                          ['CreateNetworkScope'],
                          ['CreateVirtualWires'],
                          ['PoweronVM3VM4'],
                          ['AddvNICsOnVM3VM4'],
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
                          ['CreateCopyRule'],
                          ['CheckDVFilter'],
                          ['ClearDFWPktLog'],
                          ['PingVM1ToVM2'],
                          ['CheckDFWPktLogVM1VM2'],
                          ['ClearDFWPktLog'],
                          ['PingTestVM3VM4'],
                          ['CheckDFWPktLogVM3VM4'],
                          ['RemoveBinding'],
                          ['DeleteServiceCluster'],
                          ['DeleteServiceProfile'],
                          ['GetDefaultServiceProfile'],
                          ['DeleteServiceProfile'],
                          ['DeleteServiceInstance'],
                          ['DeleteVendorTemplate'],
                          ['CheckSVMUndeploymentStatus'],
                          ['DeleteService'],
                          ['DeleteServiceManager'],
                        ],
            ExitSequence => [
                               ['PoweroffVM1VM2'],
                               ['RemovevNICFromVM1to2'],
                               ['PoweroffVM3VM4'],
                               ['RemovevNICFromVM3to4'],
                               ['DeleteVirtualWires'],
                               ['DeleteNetworkScopes'],
                               ['UnconfigureVXLAN'],
                               ['ResetSegmentID'],
                               ['ResetMulticast'],
                            ],
            'GetDatastore' => GET_DATASTORE,
            'AddvNICsOnVM1VM2' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweron",
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
                  },
               },
            },
            'CreateNetworkScope' => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1",
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
            'CreateServiceManager' => CREATE_SERVICE_MANAGER,
            'CreateService' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               service => {
                    '[1]' => {
                            'name' => "ABC Company Service",
                            'servicemanager' => {
                               'objectid' => "vsm.[1].servicemanager.[1]",
                            },
                            'functionalities' => [
                            {
                               'type' => 'IDS_IPS',
                            },
                            ],
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
                                   'value' => 'ACTION_COPY',
                               },
                              ],
                            'vendortemplates' => '',
                            'usedby' => '',
                    },
               },
            },
            'CreateVendorTemplate' => CREATE_VENDOR_TEMPLATE,
            'GetServiceInstance' => GET_SERVICE_INSTANCE,
            'CreateVersionedDeploymentSpec' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               versioneddeploymentspec => {
                    '[1]' => {
                            'hostversion' => "6.0.*",
                            #### TODO Replace url once 1435871 has been fixed#####
                            'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL_RHEL6_32BIT_61SVM,
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
            'CheckSVMDeploymentStatus' => CHECK_SVM_DEPLOYMENT_STATUS,
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
           'CreateCopyRule' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                     layer     => "layer3redirect",
                     name      => 'Copy Packets between VM1 and VM2 to Service',
                     action    => 'Redirect',
                     section   => 'default',
                     logging_enabled => 'true',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
                        name => 'ABC Company Service Profile Name',
                     },
                     sources   => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[1]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[2]",
                     },
                     ],
                     destinations => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[1]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[2]",
                     },
                     ],
                  },
                  '[2]' => {
                     layer     => "layer3redirect",
                     name      => 'Copy packets between VM3 and VM4 to Service',
                     action    => 'Redirect',
                     section   => 'default',
                     logging_enabled => 'true',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
                        name => 'ABC Company Service Profile Name',
                     },
                     sources   => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[3]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[4]",
                     },
                     ],
                     destinations => [
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[3]",
                     },
                     {
                        type  => 'VirtualMachine',
                        value => "vm.[4]",
                     },
                     ],
                  },
               },
            },
            'CheckDVFilter' => CHECK_DVFILTER,
            'ClearDFWPktLog'  =>  {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => ">/var/log/dfwpktlogs.log",
            },
            'CheckDFWPktLogVM1VM2'  =>  {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "tail -50 /var/log/dfwpktlogs.log",
               expectedString  => ".+INET match COPY.+PROTO ",
            },
            'CheckDFWPktLogVM3VM4'  =>  {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "tail -50 /var/log/dfwpktlogs.log",
               expectedString  => ".+INET match COPY.+PROTO 1 172.32.1.5->172.32.1.6",
            },

            'PingVM1ToVM2' => {
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
            'DeleteServiceCluster' => DELETE_SERVICE_CLUSTER,
            'DeleteServiceProfile' => DELETE_SERVICE_PROFILE,
            'GetDefaultServiceProfile' => GET_SERVICE_PROFILE,
            'DeleteServiceInstance' => DELETE_SERVICE_INSTANCE,
            'DeleteVendorTemplate' => DELETE_VENDOR_TEMPLATE,
            'CheckSVMUndeploymentStatus' => CHECK_SVM_UNDEPLOYMENT_STATUS,
            'DeleteService' => DELETE_SERVICE,
            'DeleteServiceManager' => DELETE_SERVICE_MANAGER,
            'PoweroffVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweroff",
            },
            'RemovevNICFromVM1to2' => {
               Type       => "VM",
               TestVM     => "vm.[1-2]",
               deletevnic => "vm.[x].vnic.[1]",
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
      'ServiceChaining' => {
         Category         => 'vShield',
         Component        => 'Service Insertion',
         Product          => 'VSM',
         QCPath           => '',
         Procedure        => '1. Create multiple Service Manager and Service' .
                                'with implementation type as' .
                                'HOST_BASED_VNIC' .
                             '2. Create Vendor Template and '.
                                'Versioned Deployment Spec' .
                             '3. Get default service instance'.
                                'and default service profile'.
                             '4. Deploy service vm'.
                                'and check svm status'.
                             '5. ',
         ExpectedResult   => 'Host based service insertion deployment with service chaining',
         Status           => 'Execution Ready',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'abhishekshah',
         Partnerfacing    => 'Y',
         Duration         => '',
         TestName         => "ServiceChaining",
         Version          => "2" ,
         Tags             => "si, 6.1",
         Summary          => "Host based service insertion with service chaining",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_OneHost_OneVmnicForHost_FourVMs,
         'WORKLOADS' => {
            Sequence => [
               ['GetDatastore'],
               ['SetSegmentIDRange'],
               ['SetMulticastRange'],
               ['HostPrepAndVTEPCreate'],
               ['CreateNetworkScope'],
               ['CreateVirtualWires'],
               ['PoweronVM1VM2'],
               ['AddvNICsOnVM1VM2'],
               ['MakeSurevNICConnected'],
               ['SetVXLANIPVM1','SetVXLANIPVM2SamevWire'],
               ['PingTestVM1VM2'],
               ['CreateTwoServiceManager'],
               ['CreateTwoService'],
               ['CreateVendorTemplateService1'],
               ['CreateVendorTemplateService2'],
               ['GetTwoServiceInstance'],
               ['CreateVersionedDeploymentSpecService1'],
               ['CreateVersionedDeploymentSpecService2'],
               ['DeployService1'],
               ['DeployService2'],
               ['CheckSVMDeploymentStatusService1'],
               ['CheckSVMDeploymentStatusService2'],
               ['GetTwoServiceProfile'],
               ['CreateSecurityGroup'],
               ['CreateRules'],
               ['CheckDVFilter'],
               ['CheckFiltersOnHost'],
               ['ClearDFWPktLog'],
               ['PingTestVM1VM2'],
               ['CheckDFWPktLog'],
            ],
            ExitSequence => [
               ['RevertToDefaultRules'],
               ['SecurityGroupDeletion'],
               ['DeleteServiceClusterService1'],
               ['DeleteServiceClusterService2'],
               ['DeleteTwoServiceProfile'],
               ['DeleteTwoServiceInstance'],
               ['DeleteVendorTemplateService1'],
               ['DeleteVendorTemplateService2'],
               ['CheckSVMUndeploymentStatusService1'],
               ['CheckSVMUndeploymentStatusService2'],
               ['DeleteTwoService'],
               ['DeleteTwoServiceManager'],
               ['PoweroffVM1VM2'],
               ['RemovevNICFromVM1to2'],
            ],
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
                  },
               },
            },
            'CreateNetworkScope' => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1",
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
                     tenantid           => "AutoGenerate",
                  },
               },
            },
            'AddvNICsOnVM1VM2' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2]",
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
            'PoweronVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweron",
            },
            'MakeSurevNICConnected' => {
               Type           => "NetAdapter",
               reconfigure    => "true",
               testadapter    => "vm.[1-2].vnic.[1]",
               connected      => 1,
               startconnected => 1,
            },
            "SetVXLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '172.32.1.5',
               netmask    => "255.255.0.0",
            },
            "SetVXLANIPVM2SamevWire" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '172.32.1.6',
               netmask    => "255.255.0.0",
            },
            "PingTestVM1VM2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               NoofOutbound   => 1,
               NoofInbound    => 1,
               Expectedresult => "PASS",
            },
            'CreateTwoServiceManager' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               servicemanager => {
                  '[1]' => {
                     'name' => "ABC Company Service Manager",
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
                  '[2]' => {
                     'name' => "DEF Company Service Manager",
                     'description' => "DEF Company Service Manager Desc",
                     'revision' => "4",
                     'objecttypename' => "ServiceManager",
                     'vendorname' => "DEF Vendor Name",
                     'vendorid' => "DEF Vendor ID",
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
            'CreateTwoService' => {
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
                     'functionalities' => [
                     {
                        'type' => 'IDS_IPS',
                     },
                     {
                        'type' => 'FIREWALL',
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
                  '[2]' => {
                     'name' => "DEF Company Service",
                     'servicemanager' => {
                        'objectid' => "vsm.[1].servicemanager.[2]",
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
                     'functionalities' => [
                     {
                        'type' => 'IDS_IPS',
                     },
                     {
                        'type' => 'FIREWALL',
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
           'CreateVendorTemplateService1' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               vendortemplate => {
                  '[1]' => {
                     'name' => "ABC Company Vendor Template",
                     'description' => 'ABC Company Vendor Template Description',
                     'vendorid' => 'ABC Company Vendor Id',
                     'functionalities' => [
                     {
                        'type' => 'IDS_IPS',
                     },
                     {
                        'type' => 'FIREWALL',
                     },
                     ],
                     'vendorattributes' => [
                     {
                        'key' => 'owa-hostname',
                        'name' => 'Name 1',
                        'value' => 'owa.myhost.com',
                     },
                     ],
                     'typedattributes' => [
                     {
                        'key' => 'SSL_CERT',
                        'type' => 'PEM_CERT',
                        'value' => '-----BEGIN CERTIFICATE----- Sample -----END CERTIFICATE-----',
                        'name' => "SSL certificate",
                     },
                     {
                        'key' => 'SSL_KEY',
                        'type' => 'PEM_KEY',
                        'value' => 'Ssl_key_value_1',
                        'name' => "SSL key",
                     },
                     {
                        'key' => 'SSL_KEY_ENUM',
                        'type' => 'STRING_ENUM',
                        'value' => 'HTTP',
                        'name' => "SSL Key",
                        'supportedvalues' => "HTTP, HTTPS",
                     },
                     ],
                     'typedattributetables' => [
                     {
                        'name' => 'ip_pool',
                        'description' => "members of ip pool",
                        'header' => [
                        {
                           'key' => "Server_ip",
                           'type' => "IP_ADDRESS",
                           'value' => "192.168.1.2",
                           'name' => "Server IP",
                        },
                        {
                           'key' => "Weight_RR",
                           'type' => "STRING",
                           'value' => "",
                           'name' => "Weight of RR",
                        },
                        {
                           'key' => "ratio",
                           'type' => "STRING",
                           'value' => "",
                           'name' => "ratio",
                        },
                        ],
                     },
                     {
                        'name' => 'List',
                        'description' => "Description of the list",
                        'header' => [
                        {
                           'key' => "list",
                           'type' => "STRING",
                           'value' => "list value",
                           'name' => "list description",
                        },
                        ],
                     },
                     ],
                     'vendorsections' => [
                     {
                         'name' => "VendorSection_DB",
                         'description' => "DB Virtual Server",
                         'typedattributetables' => [
                         {
                            'name' => 'ip_pool',
                            'description' => "members of ip pool",
                            'header' => [
                            {
                               'key' => "Server_ip",
                               'type' => "IP_ADDRESS",
                               'value' => "192.168.1.3",
                               'name' => "Server Ip",
                            },
                            {
                               'key' => "Weight_RR",
                               'type' => "STRING",
                               'value' => "",
                               'name' => "Weight of RR",
                            },
                            {
                               'key' => "ratio",
                               'type' => "STRING",
                               'value' => "",
                               'name' => "ratio",
                            },
                            ],
                         },
                         {
                            'name' => 'ip_pool',
                            'description' => "members of ip pool",
                            'header' => [
                            {
                               'key' => "list",
                               'type' => "STRING",
                               'value' => "list",
                               'name' => "list",
                            },
                            ],
                         },
                         ],
                      },
                      ],
                    },
                  },
           },
           'CreateVendorTemplateService2' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[2]",
               vendortemplate => {
                  '[1]' => {
                     'name' => "DEF Company Vendor Template",
                     'description' => 'DEF Company Vendor Template Description',
                     'vendorid' => 'DEF Company Vendor Id',
                     'functionalities' => [
                     {
                        'type' => 'IDS_IPS',
                     },
                     {
                        'type' => 'FIREWALL',
                     },
                     ],
                     'vendorattributes' => [
                     {
                        'key' => 'owa-hostname',
                        'name' => 'Name 1',
                        'value' => 'owa.myhost.com',
                     },
                     ],
                     'typedattributes' => [
                     {
                        'key' => 'SSL_CERT',
                        'type' => 'PEM_CERT',
                        'value' => '-----BEGIN CERTIFICATE----- Sample -----END CERTIFICATE-----',
                        'name' => "SSL certificate",
                     },
                     {
                        'key' => 'SSL_KEY',
                        'type' => 'PEM_KEY',
                        'value' => 'Ssl_key_value_1',
                        'name' => "SSL key",
                     },
                     {
                        'key' => 'SSL_KEY_ENUM',
                        'type' => 'STRING_ENUM',
                        'value' => 'HTTP',
                        'name' => "SSL Key",
                        'supportedvalues' => "HTTP, HTTPS",
                     },
                     ],
                     'typedattributetables' => [
                     {
                        'name' => 'ip_pool',
                        'description' => "members of ip pool",
                        'header' => [
                        {
                           'key' => "Server_ip",
                           'type' => "IP_ADDRESS",
                           'value' => "192.168.1.2",
                           'name' => "Server IP",
                        },
                        {
                           'key' => "Weight_RR",
                           'type' => "STRING",
                           'value' => "",
                           'name' => "Weight of RR",
                        },
                        {
                           'key' => "ratio",
                           'type' => "STRING",
                           'value' => "",
                           'name' => "ratio",
                        },
                        ],
                     },
                     {
                        'name' => 'List',
                        'description' => "Description of the list",
                        'header' => [
                        {
                           'key' => "list",
                           'type' => "STRING",
                           'value' => "list value",
                           'name' => "list description",
                        },
                        ],
                     },
                     ],
                     'vendorsections' => [
                     {
                         'name' => "VendorSection_DB",
                         'description' => "DB Virtual Server",
                         'typedattributetables' => [
                         {
                            'name' => 'ip_pool',
                            'description' => "members of ip pool",
                            'header' => [
                            {
                               'key' => "Server_ip",
                               'type' => "IP_ADDRESS",
                               'value' => "192.168.1.3",
                               'name' => "Server Ip",
                            },
                            {
                               'key' => "Weight_RR",
                               'type' => "STRING",
                               'value' => "",
                               'name' => "Weight of RR",
                            },
                            {
                               'key' => "ratio",
                               'type' => "STRING",
                               'value' => "",
                               'name' => "ratio",
                            },
                            ],
                         },
                         {
                            'name' => 'ip_pool',
                            'description' => "members of ip pool",
                            'header' => [
                            {
                               'key' => "list",
                               'type' => "STRING",
                               'value' => "list",
                               'name' => "list",
                            },
                            ],
                         },
                        ],
                      },
                      ],
                    },
               },
            },
            'GetTwoServiceInstance' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               serviceinstance => {
                  '[1]' => {
                     'serviceid' => "vsm.[1].service.[1]",
                  },
                  '[2]' => {
                     'serviceid' => "vsm.[1].service.[2]",
                  },
               },
            },
            'CreateVersionedDeploymentSpecService1' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               versioneddeploymentspec => {
                  '[1]' => {
                     'hostversion' => "5.5.*",
                     'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL_RHEL6_32BIT_61SVM,
                     'vmcienabled' => "true",
                  },
               },
            },
            'CreateVersionedDeploymentSpecService2' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[2]",
               versioneddeploymentspec => {
                  '[1]' => {
                     'hostversion' => "5.5.*",
                     'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL_RHEL6_32BIT_61SVM,
                     'vmcienabled' => "true",
                  },
               },
            },
            'DeployService1' => {
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
            'DeployService2' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[2]",
               clusterdeploymentconfigs => {
                 '[1]' =>
                     {
                        'clusterdeploymentconfigarray' => [
                        {
                            'clusterid' => "vc.[1].datacenter.[1].cluster.[1]",
                            'datastore' => "host.[1].datastore.[1]",
                            'services' => [
                             {
                                'serviceinstanceid' => "vsm.[1].serviceinstance.[2]",
                                'dvportgroup' => "vc.[1].dvportgroup.[2]",
                             },
                            ],
                        },
                       ],
                     },
               },
            },
            'CheckSVMDeploymentStatusService1' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               verifyendpointattributes => {
                     'progressstatus[?]equal_to' => "SUCCEEDED",
               },
               noofretries  => "20",
            },
            'CheckSVMDeploymentStatusService2' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[2]",
               verifyendpointattributes => {
                     'progressstatus[?]equal_to' => "SUCCEEDED",
               },
               noofretries  => "20",
            },
            'GetTwoServiceProfile' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               serviceprofile => {
                  '[1]' => {
                     'getserviceprofileflag' => "true",
                     'serviceprofilename' => "ABC Company Service_ABC Company Vendor Template",
                  },
                  '[2]' => {
                     'getserviceprofileflag' => "true",
                     'serviceprofilename' => "DEF Company Service_DEF Company Vendor Template",
                  },
               },
            },
            'CreateSecurityGroup' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               securitygroup => {
                  '[1]' => {
                     'name' => "Security Group-1",
                     'sg_description' => "Security Group Description",
                     'objecttypename' => "SecurityGroup",
                     'type' => {
                        'typename' => "SecurityGroup",
                     },
                     'scope' => {
                        'id' => "globalroot-0",
                        'objecttypename' => "GlobalRoot",
                        'name' => "Global",
                     },
                     'member' => [
                     {
                        'vm_id' => "vm.[1]",
                        'objecttypename' => "VirtualMachine",
                     },
                     {
                        'vm_id' => "vm.[2]",
                        'objecttypename' => "VirtualMachine",
                     },
                     ],
                  },
               },
            },
            "CreateRules" => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                     layer     => "layer3redirect",
                     name      => 'Redirect Traffic-1',
                     action    => 'Redirect',
                     section   => 'default',
                     logging_enabled => 'true',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[1]',
			# Temporary Fix to accomodate bug #1288673
                        name => 'ABC Company Service_ABC Company Vendor Template',
                     },
                     sources   => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     ],
                     destinations => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     ],
                     appliedto => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     ],
                  },
                  '[2]' => {
                     layer     => "layer3redirect",
                     name      => 'Redirect Traffic-2',
                     action    => 'Redirect',
                     section   => 'default',
                     logging_enabled => 'true',
                     siprofile => {
                        objectid => 'vsm.[1].serviceprofile.[2]',
                        # Temporary Fix to accomodate bug #1288673
                        name => 'DEF Company Service_DEF Company Vendor Template',
                     },
                     sources   => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     ],
                     destinations => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     ],
                     appliedto => [
                     {
                           type  => 'SecurityGroup',
                           value => "vsm.[1].securitygroup.[1]",
                     },
                     ],
                  },
               },
           },
           'CheckDVFilter' => {
               'Type' => 'Command',
               'command' => 'summarize-dvfilter',
               'testhost' => 'host.[1]',
           },
           'CheckFiltersOnHost' => {
               'Type' => 'Command',
               'command' => 'vsipioctl getfilters',
               'testhost' => 'host.[1]',
           },
           "TrafficTCP_VM1_VM2" => {
               Type           => "Traffic",
               Expectedresult => "PASS",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestDuration   => "5",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
           },
            'ClearDFWPktLog'  =>  {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => ">/var/log/dfwpktlogs.log",
            },
            'CheckDFWPktLog'  =>  {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "tail -50 /var/log/dfwpktlogs.log",
               expectedString  => ".+INET match PUNT.+PROTO 1 172.32.1.5->172.32.1.6",
            },
            "RevertToDefaultRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               firewallrule => {
                  '[-1]' => {}
               }
            },
            "SecurityGroupDeletion" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletesecuritygroup => "vsm.[1].securitygroup.[1]",
            },
            "DeleteServiceClusterService1" => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               deleteclusterdeploymentconfigs => "vsm.[1].service.[1].clusterdeploymentconfigs.[1]",
            },
            "DeleteServiceClusterService2" => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[2]",
               deleteclusterdeploymentconfigs => "vsm.[1].service.[2].clusterdeploymentconfigs.[1]",
            },
            "DeleteTwoServiceProfile" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteserviceprofile => "vsm.[1].serviceprofile.[1-2]",
            },
            "DeleteTwoServiceInstance" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteserviceinstance => "vsm.[1].serviceinstance.[1-2]",
            },
            "DeleteVendorTemplateService1" => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               deletevendortemplate => "vsm.[1].service.[1].vendortemplate.[1]",
            },
            "DeleteVendorTemplateService2" => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[2]",
               deletevendortemplate => "vsm.[1].service.[2].vendortemplate.[1]",
            },
            "CheckSVMUndeploymentStatusService1" => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               verifyendpointattributes => {
                  'progressstatus[?]equal_to' => undef,
               },
               noofretries  => "5",
            },
            "CheckSVMUndeploymentStatusService2" => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[2]",
               verifyendpointattributes => {
                  'progressstatus[?]equal_to' => undef,
               },
               noofretries  => "5",
            },
            "DeleteTwoService" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteservice => "vsm.[1].service.[1-2]",
            },
            "DeleteTwoServiceManager" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteservicemanager => "vsm.[1].servicemanager.[1-2]",
            },
            'PoweroffVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweroff",
            },
            'RemovevNICFromVM1to2' => {
               Type       => "VM",
               TestVM     => "vm.[1-2]",
               deletevnic => "vm.[x].vnic.[1]",
            },
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for HostBasedServiceInsertionFunctionalWithVersionGreaterThan61Tds
#
# Input:
#       none
#
# Results:
#       An instance/object of HostBasedServiceInsertionFunctionalWithVersionGreaterThan61Tds class
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
   my $self = $class->SUPER::new(\%HostBasedServiceInsertionFunctionalWithVersionGreaterThan61);
   return (bless($self, $class));
}

1;
