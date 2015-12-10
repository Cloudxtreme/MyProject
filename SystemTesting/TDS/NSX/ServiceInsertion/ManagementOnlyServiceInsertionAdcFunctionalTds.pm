#!/usr/bin/perl
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::ServiceInsertion::ManagementOnlyServiceInsertionAdcFunctionalTds;

#
# This file contains the structured hash for category, ManagementOnlyServiceInsertionAdcFunctional tests
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

   %ManagementOnlyServiceInsertionAdcFunctional = (
      'LoadBalancerServiceInsertion' => {
         Category         => 'vShield',
         Component        => 'Service Insertion',
         TestName         => "LoadBalancerServiceInsertion",
         Version          => "2" ,
         Tags             => "si",
         Summary          => "Managament based service insertion scripts",
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
                         '[1-24]' => {
                          },
                        },
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-8]' => {
                          },
                        },
                     },
                     '[3]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-8]' => {
                          },
                        },
                     },
                     '[4]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-8]' => {
                          },
                        },
                     },
                     '[5]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport   => {
                         '[1-8]' => {
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
            },
         },
         'WORKLOADS' => {
            Sequence => [
               ['GetDatastore'],
               ['PrepCluster'],
               ['CreateServiceManager'],
               ['CreateService'],
               ['CreateServiceInstanceTemplate'],
               ['CreateVendorTemplate'],
               ['CreateVersionedDeploymentSpec'],
#               ['CreateServiceInstance'], # use this when
#                                            creating user service
#                                            instance is allowed for
#                                            edge
               ['DeployGatewayServicesEdge'],
               ['ConfigureLoadBalancer'],
               ['GetServiceInstance'],
               ['CreateServiceInstanceRuntimeInfo'],
#               ['InstallServiceInstanceRuntimeFromEdge'], # Use this runtime
#                                                            when install from
#                                                            edge is allowed
               ['CreateServiceProfile'],
               ['InstallServiceInstanceRuntime'],
            ],
            ExitSequence => [
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
                        'description' => "ABC Company Service Description",
                        'servicemanager' => {
                           'objectid' => "vsm.[1].servicemanager.[1]",
                        },
                        'implementations' => [
                        {
                           'type' => 'L3_BOUNDARY',
                        }
                        ],
                        'transports' => [
                        {
                           'type' => 'NONE',
                        },
                        ],
                        'functionalities' => [
                        {
                           'type' => 'ADC',
                        },
                        ],
                        'state' => "INSTALLED",
                        'status' => "IN_SERVICE",
                        'precedence' => "0",
                        'internalservice' => "false",
                        'vendortemplates' => '',
                        'usedby' => '',
                    },
               },
            },
            'CreateServiceInstanceTemplate' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               serviceinstancetemplate => {
                  '[1]' => {
                     'name' => "ABC Company Service Instance Template",
                     'description' => 'ABC Company Service Instance Template Description',
                     'instancetemplateid' => 'gold-service-1',
                     'requiredinstanceattributes' => [
                     {
                        'key' => 'lb_bandwidth',
                        'value' => '200Mbps',
                        'name' => 'Reserved Load balancing bandwidth',
                     },
                     {
                        'key' => 'ssl-cert-location',
                        'value' => 'http://mytenant/cert/location',
                        'name' => 'Location of the tenant',
                     },
                     ],
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
                        'key' => 'owa-hostname',
                        'name' => 'Name 1',
                        'value' => 'owa.myhost.com',
                     },
                     ],
                     'typedattributes' => [
                     {
                        'key' => 'SSL_CERT',
                        'type' => 'PEM_CERT',
                        'value' => '-----BEGIN CERTIFICATE-----MIIGkTCCBXmgAw'.
                        'IBAgITcwAAME9Wh1jtuuotigAAAAAwTzANBgkqhkiG9w0BAQUFAD'.
                        'BNMRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGR'.
                        'YFRjVOZXQxHzAdBgNVBAMTFkY1IEludGVybmFsIElzc3VpbmcgQ0'.
                        'EwHhcNMTQwMTI0MjEwNzMxWhcNMTYwMTI0MjEwNzMxWjCBnjELMA'.
                        'kGA1UEBhMCVVMxCzAJBgNVBAgTAldBMRAwDgYDVQQHEwdTZWF0dG'.
                        'xlMRowGAYDVQQKExFGNSBOZXR3b3JrcywgSW5jLjELMAkGA1UECx'.
                        'MCUEQxKDAmBgNVBAMTH2tpbGxlci1odHRwLWFwcC5wZHNlYS5mNW'.
                        '5ldC5jb20xHTAbBgkqhkiG9w0BCQEWDmwuc2lsZXJAZjUuY29tMI'.
                        'IBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvF3/jI2a8g'.
                        '9I+h5Dhj69FCyOB7O931hjtoMPOs/GcCfpkN1S4X3QZDlpHAG6sP'.
                        '5ZaQ7+RZG8pCbGovqm2r0yzKtV5GrUd8INLX76gp83vVjY9fTBlh'.
                        'WY8Cq5wGeUjZX/kkjwdG3c4KbDsNGNBU7DyVJx/4/iD2Y5UMD3a9'.
                        'ghvrKENmxsqjoqSgnmlqoPSIO/o7I7ziFPwuBzaWK9MbMvDre42v'.
                        'lNaJnIixQwrXPdKiKbrLvZAhRIK5PmJUxvQXtHhfJDwKXDHcjVBZ'.
                        'NDf+dG0ASlj1w8Na/Jh2vdtHO73grT3C71CTR9aQCNIgjlBu9nHE'.
                        'zY/5mxwYGwJwzgIBDY0wIDAQABo4IDFjCCAxIwHQYDVR0OBBYEFI'.
                        'KC2Jb/20+G0QOsUgvzLpBzQUmvMB8GA1UdIwQYMBaAFPzPFQQvpP'.
                        'Zuw1mmBax1Jd9YEFp1MIIBHgYDVR0fBIIBFTCCAREwggENoIIBCa'.
                        'CCAQWGgcRsZGFwOi8vL0NOPUY1JTIwSW50ZXJuYWwlMjBJc3N1aW'.
                        '5nJTIwQ0EsQ049U0VBU1VCQ0EwMSxDTj1DRFAsQ049UHVibGljJT'.
                        'IwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndX'.
                        'JhdGlvbixEQz1GNU5ldCxEQz1jb20/Y2VydGlmaWNhdGVSZXZvY2'.
                        'F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dG'.
                        'lvblBvaW50hjxodHRwOi8vRjVDZXJ0LkY1bmV0LmNvbS9QS0kvRj'.
                        'UlMjBJbnRlcm5hbCUyMElzc3VpbmclMjBDQS5jcmwwggEtBggrBg'.
                        'EFBQcBAQSCAR8wggEbMIG5BggrBgEFBQcwAoaBrGxkYXA6Ly8vQ0'.
                        '49RjUlMjBJbnRlcm5hbCUyMElzc3VpbmclMjBDQSxDTj1BSUEsQ0'.
                        '49UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ0'.
                        '49Q29uZmlndXJhdGlvbixEQz1GNU5ldCxEQz1jb20/Y0FDZXJ0aW'.
                        'ZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdX'.
                        'Rob3JpdHkwXQYIKwYBBQUHMAKGUWh0dHA6Ly9GNUNlcnQuRjVOZX'.
                        'QuY29tL1BLSS9TRUFTVUJDQTAxLkY1TmV0LmNvbV9GNSUyMEludG'.
                        'VybmFsJTIwSXNzdWluZyUyMENBLmNydDALBgNVHQ8EBAMCBaAwPg'.
                        'YJKwYBBAGCNxUHBDEwLwYnKwYBBAGCNxUIhtTiR4HUkyGCmZEDhr'.
                        'uFeYGTvDKBWYS7piSGp79MAgFkAgEEMBMGA1UdJQQMMAoGCCsGAQ'.
                        'UFBwMBMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwEwDQYJKo'.
                        'ZIhvcNAQEFBQADggEBAMNVBvvKRA915hf5Uzl0mREEKVjzMAzhRJ'.
                        'rFmGz5RMlY5LhrVOkp9zR11W2Ttvj3hWSbNDWwzlSWK0k74ltK3N'.
                        'QX41fb4hX8QBjxTRClmpTjGDYKgtnpDc+TgzP3ozm+GIH+K5hKQw'.
                        'PgbDUbo7f8JqBUqC6sB2TmPA0hUi5C6CCLVNILERVBRgB3OuO4uO'.
                        '0mX3ucmcYYIIPkxl3AIXwSRUmLFtPUmMpcEb0ChDnhUDpT8AHl9S'.
                        'Bv7kxXlOPhq6v6jL7l3f+q7KtIZpqu3yH8U6w8IYa7YN0hv5626G'.
                        'frfMHd9eDdfQ/8RJvY4D5OhK9wVWtXR7JqS3VOeLUU9LS2fwM=--'.
                                                     '---END CERTIFICATE-----',
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
                        'key' => 'pool_key',
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
                        'key' => 'list_key',
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
                            'key' => 'pool_key',
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
                            'key' => 'list_key',
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
            'CreateVersionedDeploymentSpec' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               versioneddeploymentspec => {
                  '[1]' => {
                     'hostversion' => "5.5.*",
                     'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL_FOR_LOAD_BALANCER,
                     'vmcienabled' => "true",
                  },
               },
            },
            'CreateServiceInstance' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               serviceinstance => {
                  '[1]' => {
                     'name' => "ABC Company Service Instance",
                     'description' => 'ABC Company Service Instance Description',
                     'service' => {
                        'objectid' => "vsm.[1].service.[1]",
                     },
                     'config' => {
                        'implementation' => {
                           'hostbaseddeployment' => 'false',
                           'type' => 'L3_BOUNDARY',
                           'requiredprofileattributes' => [
                           {
                              'key' => 'Key 1',
                              'name' => 'Name 1',
                           },
                           ],
                           'requiredserviceattributes' => [
                           {
                              'key' => 'Key 1',
                              'name' => 'Name 1',
                           },
                           ],
                        },
                        'implementationattributes' => [
                        {
                           'key' => 'Key 1',
                           'name' => 'Name 1',
                        },
                        ],
                        'transport' => {
                           'type' => 'NONE',
                           'transportattributes' => [
                           {
                              'key' => 'Key 1',
                              'name' => 'Name 1',
                           },
                           ],
                        },
                        'transportattributes' => [
                        {
                           'key' => 'Key 1',
                           'name' => 'Name 1',
                        },
                        ],
                        'serviceinstanceattributes' => [
                        {
                           'key' => "tenantID",
                           'value' => "orgvdc-1",
                        },
                        {
                           'key' => "dataStore",
                           'value' => "datastore-1",
                        },
                        {
                           'key' => "resourcePool",
                           'value' => "resourcePool-1",
                        },
                        {
                           'key' => "VMFolder",
                           'value' => "vmfolder-1",
                        },
                        {
                           'key' => "vCenterUUID",
                           'value' => "uuid-1",
                        },
                        ],
                        'instancetemplateattributes' => [
                        {
                           'key' => "lb_bandwidth",
                           'name' => "Reserved Load balancing bandwidth",
                           'value' => "200Mbps",
                        },
                          {
                             'key' => "ssl-cert-location",
                             'name' => "Location of tenant certificate",
                             'value' => "http://mytenant/cert/location",
                          },
                          ],
                          'instancetemplatetypedattributes' => [
                          {
                             'key' => "lb_bandwidth",
                             'name' => "Reserved Load balancing bandwidth",
                             'value' => "200Mbps",
                             'type'=> "STRING",
                          },
                          {
                             'key' => "ssl-cert-location",
                             'name' => "Location of tenant certificate",
                             'value' => "http://mytenant/cert/location",
                             'type'=> "STRING",
                          },
                          ],
                       },
                    },
               },
            },
            'DeployGatewayServicesEdge' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               gateway => {
                   '[1]' => {
                      'name' => 'Edge-1001',
                      'resourcepool' => 'vc.[1].datacenter.[1].cluster.[1]',
                      'datacenter' => 'vc.[1].datacenter.[1]',
                      'host' => 'host.[1]',
                      'portgroup' => 'vc.[1].dvportgroup.[1]',
                      'primaryaddress' => '10.10.1.10',
                      'subnetmask' => '255.255.255.0',
                   }
               },
            },
            'ConfigureLoadBalancer' => {
               Type       => 'Gateway',
               TestGateway    => "vsm.[1].gateway.[1]",
               loadbalancerconfig => {
                  '[1]' => {
                     'enabled' => 'true',
                     'accelerationenabled' => 'true',
                     'enableserviceinsertion' => 'true',
                     'globalserviceinstance' => {
                        'serviceid' => "vsm.[1].service.[1]",
                        'instancetemplateuniqueid' => "vsm.[1].service.[1].serviceinstancetemplate.[1]",
                        'runtimenicinfoarray' => [
                        {
                           'index' => "0",
                           'label' => "vnic1",
                           'network' => {
                              'objectid' => 'vc.[1].dvportgroup.[1]',
                              'objecttypename' => 'DistributedVirtualPortgroup',
                           },
                        },
                       ],
                     },
                     'pool' => {
                        'name' => 'My_ip_pool',
                        'memberarray' => [
                        {
                          'name' => "member1",
                          'ipaddress' => "172.24.2.1",
                          'port' => "80",
                          'monitorport' => '80',
                        },
                        {
                          'name' => "member2",
                          'ipaddress' => "172.24.2.2",
                          'port' => "80",
                          'monitorport' => '80',
                        },
                        ],
                     },
                   }
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
            'CreateServiceInstanceRuntimeInfo' => {
               Type       => 'Service',
               TestService    => "vsm.[1].serviceinstance.[1]",
                serviceinstanceruntimeinfo => {
                 '[1]' => {
                    'versioneddeploymentspecid' => "vsm.[1].service.[1].versioneddeploymentspec.[1]",
                    'deloymentscope' => {
                       'clusters' =>
                       {
                          'clustermorid' =>
                          [
                             "vc.[1].datacenter.[1].cluster.[1]",
                          ],
                       },
                       'datanetworks' =>
                       {
                          'dvpgmorid' =>
                          [
                             "vc.[1].dvportgroup.[1]",
                          ],
                       },
                       'datastore' => "host.[1].datastore.[1]",
                       'nics' => [
                       {
                          'index' => "0",
                          'label' => "vnic1",
                          'network' => {
                             'objectid' => 'vc.[1].dvportgroup.[1]',
                             'objecttypename' => 'DistributedVirtualPortgroup',
                          },
                       },
                       ],
                    },
                 },
               },
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
                     'vendortypedattributes' => [
                     {
                        'key' => 'owa-hostname',
                        'name' => 'owa host name',
                        'value' => 'owa.myhost.com',
                        'type' => 'STRING',
                     },
                     ],
                     'vendortables' => [
                     {
                        'header' => [
                        {
                           'key' => "owa-hostname",
                           'type' => "STRING",
                           'value' => "owa.myhost.com",
                           'name' => "owa host name",
                        },
                        {
                           'key' => "test",
                           'type' => "STRING",
                           'value' => "Test",
                           'name' => "owa host name",
                        },
                        ],
                       'rows' => [
                       {
                          'typedattributes' => [
                          {
                             'key' => "owa-hostname",
                             'type' => "STRING",
                             'value' => "owa.myhost.com",
                             'name' => "owa host name",
                          },
                          ],
                       },
                       ],
                     },
                     ],
                     'vendorsections' => [
                     {
                        'name' => "Vendor Section Name",
                        'typedattributes' => [
                        {
                           'key' => "owa-hostname",
                           'type' => "STRING",
                           'value' => "owa.myhost.com",
                           'name' => "owa host name",
                        },
                        ],
                        'typedattributetables' => [
                        {
                           'name' => 'Vendor Section Attributes Table',
                           'description' => "members of ip pool",
                           'header' => [
                           {
                              'key' => "owa-hostname",
                              'type' => "STRING",
                              'value' => "owa.myhost.com",
                              'name' => "owa host name",
                           },
                           {
                              'key' => "test",
                              'type' => "STRING",
                              'value' => "Test",
                              'name' => "owa host name",
                           },
                           ],
                           'rows' => [
                           {
                              'typedattributes'=>[
                              {
                                 'key' => "owa-hostname",
                                 'type' => "STRING",
                                 'value' => "owa.myhost.com",
                                 'name' => "owa host name",
                              },
                              ],
                           },
                           ],
                        },
                        ],
                     },
                     ],
                    },
               },
            },
            'InstallServiceInstanceRuntime' => {
               Type        => 'Service',
               TestService => "vsm.[1].serviceinstance.[1].serviceinstanceruntimeinfo.[1]",
               reconfigure => "true",
               operation   => "install",
            },
            'InstallServiceInstanceRuntimeFromEdge' => {
               Type        => 'Gateway',
               TestGateway => "vsm.[1].gateway.[1]",
               serviceinstanceruntimefromedge => {
                  '[1]' => {
                  },
               }
            },
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for ManagementOnlyServiceInsertionAdcFunctionalTds
#
# Input:
#       none
#
# Results:
#       An instance/object of ManagementOnlyServiceInsertionAdcFunctionalTds class
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
   my $self = $class->SUPER::new(\%ManagementOnlyServiceInsertionAdcFunctional);
   return (bless($self, $class));
}

1;
