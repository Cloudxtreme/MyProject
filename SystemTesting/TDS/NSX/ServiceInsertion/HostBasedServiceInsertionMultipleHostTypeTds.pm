#!/usr/bin/perl
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::ServiceInsertion::HostBasedServiceInsertionMultipleHostTypeTds;

#
# This file contains the structured hash for category, HostBasedServiceInsertionMultipleHostType tests
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
use TDS::NSX::ServiceInsertion::CommonWorkloads ':AllConstants';

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("");

   %HostBasedServiceInsertionMultipleHostType = (
      'ServiceInsertionPreInstall' => {
         Category         => 'vShield',
         Component        => 'Service Insertion',
         Product          => 'VSM',
         QCPath           => '',
         TestName         => "ServiceInsertionPreInstall",
         Summary          => "Script to test host based service insertion " .
                             "by adding, removing host to cluster",
         Procedure        => '1. Deploy host based service insertion ' .
                                'on 2 host, 5.5 and 5.1 ' .
                             '2. Move a new host 5.1 to cluster and '.
                                'attach it to vds ' .
                             '3. Check Service VM is installed '.
                                'on third host ' .
                             '4. Move third host out of the cluster ' .
                             '5. Remove host based service insertion ',
         ExpectedResult   => 'Host based services should be installed ' .
                             'and removed successfully',
         Status           => 'Execution Ready',
         Tags             => 'si',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'abhishekshah',
         Partnerfacing    => 'Y',
         Duration         => '',
         Version          => '2',
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
                  datacenter => {
                     '[1]' => {
                         cluster => {
                           '[1]' => {
                              name => "Controller-Cluster-$$",
                              drs  => 1,
                              host => "host.[1-2]",
                           },
                        },
                        host => "host.[3]",
                     },
                  },
                  vds => {
                     '[1]' => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        version    => "5.1.0",
                     },
                  },
                  dvportgroup => {
                     '[1]' => {
                        vds    => "vc.[1].vds.[1]",
                        dvport => {
                           '[1-12]' => {
                           },
                        },
                     },
                     '[2]' => {
                        vds    => "vc.[1].vds.[1]",
                        dvport => {
                           '[1-12]' => {
                           },
                        },
                     },
                  },
               },
            },
            host => {
               '[1-3]' => {
                  vmnic => {
                     '[1]' => {
                        driver => "any",
                     },
                  },
               },
            },
            vm => {
               '[1-2]' => {
                  host => "host.[1]",
                  vmstate => "poweroff",
               },
               '[3-4]' => {
                  host => "host.[2]",
                  vmstate => "poweroff",
               },
               '[5-6]' => {
                  host => "host.[3]",
                  vmstate => "poweroff",
               },
            },
         },
         'WORKLOADS' => {
            Sequence => [
               ['PoweronVM1toVM6'],
               ['AddvNICsOnVM1AndVM2'],
               ['AddvNICsOnVM3AndVM4'],
               ['GetDatastore'],
               ['PrepCluster'],
               ['CreateServiceManager'],
               ['CreateService'],
               ['CreateVendorTemplate'],
               ['GetServiceInstance'],
               ['CreateVersionedDeploymentSpecFor5.1'],
               ['CreateVersionedDeploymentSpecFor5.5'],
               ['DeployService'],
               ['CheckSVMDeploymentStatus'],
               ['CreateServiceProfile'],
               ['UpdateBinding'],
               ['Ping1'],
               ['MoveHost3ToCluster'],
               ['AddHost3ToVDS'],
               ['CheckSVMDeploymentStatus'],
               ['AddvNICsOnVM5AndVM6'],
               ['MakeSurevNICConnected'],
               ['RemovevNICFromVM5'],
               ['RemovevNICFromVM6'],
               ['RemoveHost3FromCluster1'],
               ['RemoveBinding'],
               ['DeleteServiceCluster'],
               ['DeleteServiceProfile'],
               ['DeleteServiceInstance'],
               ['DeleteVendorTemplate'],
               ['CheckSVMUndeploymentStatus'],
               ['DeleteService'],
               ['DeleteServiceManager'],
            ],
            'PoweronVM1toVM6' => {
               Type    => "VM",
               TestVM  => "vm.[1-6]",
               vmstate => "poweron",
            },
            'AddvNICsOnVM1AndVM2' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
               },
            },
           'AddvNICsOnVM3AndVM4' => {
               Type   => "VM",
               TestVM => "vm.[3],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
               },
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
            'CreateVersionedDeploymentSpecFor5.1' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               versioneddeploymentspec => {
                  '[1]' => {
                     'hostversion' => "5.1.*",
                     'ovfurl' => VDNetLib::TestData::TestConstants::OVF_URL,
                     'vmcienabled' => "true",
                  },
               },
            },
            'CreateVersionedDeploymentSpecFor5.5' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               versioneddeploymentspec => {
                  '[1]' => {
                     'hostversion' => "5.5.*",
                     'ovfurl' => VDNetLib::TestData::TestConstants::OVF_URL,
                     'vmcienabled' => "true",
                  },
               },
            },

            'DeployService' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               clusterdeploymentconfigs => {
                 '[1]' => {
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
                     'description' =>
                        'ABC Company Service Profile Name Description',
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
                  'virtualwires' => '',
                  'excludedvnics' => '',
                  'virtualservers' => '',
                  'distributedvirtualportgroups' =>{
                     'string' => "vc.[1].dvportgroup.[1]",
                  },
               },
            },
            'Ping1' => {
               Type             => "Traffic",
               ToolName         => "ping",
               TestAdapter      => "vm.[1].vnic.[1]",
               SupportAdapter   => "vm.[2].vnic.[1]",
               TestDuration     => "10",
               sleepbetweenworkloads => '120'
            },
            'MoveHost3ToCluster' => {
               Type        => "Cluster",
               TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
               MoveHostsToCluster => "host.[3]",
            },
            'AddHost3ToVDS' => {
               Type        => "Switch",
               TestSwitch  => "vc.[1].vds.[1]",
               configurehosts => "add",
               configureuplinks=> "add",
               host           => "host.[3]",
               vmnicadapter   => "host.[3].vmnic.[1]",
            },
            'AddvNICsOnVM5AndVM6' => {
               Type   => "VM",
               TestVM => "vm.[5],vm.[6]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
               },
            },
            'MakeSurevNICConnected' => {
               Type           => "NetAdapter",
               reconfigure    => "true",
               testadapter    => "vm.[5-6].vnic.[1]",
               connected      => 1,
               startconnected => 1,
            },
            'RemovevNICFromVM5' => {
               Type       => "VM",
               TestVM     => "vm.[5]",
               deletevnic => "vm.[5].vnic.[1]",
            },
            'RemovevNICFromVM6' => {
               Type       => "VM",
               TestVM     => "vm.[6]",
               deletevnic => "vm.[6].vnic.[1]",
            },
            "RemoveHost3FromVDS" => {
               Type        => "Switch",
               TestSwitch  => "vc.[1].vds.[1]",
               configurehosts  => "remove",
               configureuplinks=> "remove",
               host => "host.[3]",
               vmnicadapter   => "host.[3].vmnic.[1]",
            },
            "RemoveHost3FromCluster1" => {
               Type => "Cluster",
               TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
               MoveHostsFromCluster => "host.[3]",
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
               deleteclusterdeploymentconfigs =>
                  "vsm.[1].service.[1].clusterdeploymentconfigs.[1]",
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
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for HostBasedServiceInsertionMultipleHostTypeTds
#
# Input:
#       none
#
# Results:
#       An instance/object of HostBasedServiceInsertionMultipleHostTypeTds class
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
   my $self = $class->SUPER::new(\%HostBasedServiceInsertionMultipleHostType);
   return (bless($self, $class));
}

1;
