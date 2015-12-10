#!/usr/bin/perl
#########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::DistributedFirewall::DFWVSMUpgradeTestTds;

#
# This file contains hash to test and verify the persistance
# of DFW config on VSM upgrade.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use TDS::NSX::DistributedFirewall::CommonWorkloads ':AllConstants';
use TDS::NSX::ServiceInsertion::CommonWorkloads ':AllConstants';
@ISA = qw(TDS::Main::VDNetMainTds);

{
   %DFWVSMUpgradeTest = (
      'TestDFWUpgradeVSM'   => {
         TestName         => 'TestDFWUpgradeVSM',
         Category         => 'Stateful Firewall',
         Product          => 'vShield',
         Component        => 'DFW',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => ' Configure and verify working of DFW'.
                             ' Before and after upgrade',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_TwoVDS_SixDVPG_FiveHost_OneVmnicForHost,
         WORKLOADS => {
            Sequence => [
               # Workloads for bringing up network connectivity
               ['SetSegmentIDRange'],
               ['SetMulticastRange'],
               ['PrepCluster1AndVTEPCreate',
               'PrepCluster2AndVTEPCreate',
               'PrepCluster3AndVTEPCreate'],
               ['CreateNetworkScope'],
               ['CreateVirtualWires'],
               ['AddvNICsOnVM1VM3'],
               ['AddvNICsOnVM2'],
               ['AddvNICsOnVM4VM5VM6'],
               ['AddvNICsOnVM7'],
               ['AddvNICsOnVM8'],
               ['PoweronVM1',
               'PoweronVM3VM4',
               'PoweronVM5VM6',
               'PoweronVM8'],
               ['PoweronVM2VM7'],
               ['SetVXLANIPVM2'],
               ['SetVXLANIPVM7'],

               # Initial config for DFW
               ['CreateIPset'],
               ['CreateMACset'],
               ['CreateSecurityGroup'],
               ['CreateUserSections'],
               ['ConfigureRulesOnDFW'],

               # Run Traffic to test DFW datapath
               ['TrafficPing_VM1_VM2'],
               ['TrafficPing_VM2_VM1'],
               ['TRAFFIC_HTTP_VM1_VM3'],
               ['TRAFFIC_HTTP_VM1_VM2'],
               ['TRAFFIC_TCP_VM7_VM1'],
               ['TRAFFIC_TCP_VM1_VM7'],
               ['Traffic_ARPPing_VM2_VM7'],
               ['CheckVMkernalLog'],

               # Configure NetX
               ['GetDatastore'],
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
               ['CreateTwoServiceProfile'],
               ['UpdateBindingForProfile1'],
               ['UpdateBindingForProfile2'],
               ['CheckDVFilterHost3'],
               ['CheckDVFilterHost4'],
               ['CheckDVFilterHost5'],
               ['CheckFiltersOnHost3'],
               ['CheckFiltersOnHost4'],
               ['CheckFiltersOnHost5'],

               # Upgrade the NSX Manager
               ['UpgradeNSX'],
               ['UpgradeVDNCluster_1',
               'UpgradeVDNCluster_2',
               'UpgradeVDNCluster_3'],
               ['PoweroffVM1_8'],
               ['RebootHosts'],
               ['PoweronVM1',
               'PoweronVM3VM4',
               'PoweronVM5VM6',
               'PoweronVM8'],
               ['PoweronVM2VM7'],

               # Run Traffic to test DFW datapath
               ['TrafficPing_VM1_VM2'],
               ['TrafficPing_VM2_VM1'],
               ['TRAFFIC_HTTP_VM1_VM3'],
               ['TRAFFIC_HTTP_VM1_VM2'],
               ['TRAFFIC_TCP_VM7_VM1'],
               ['TRAFFIC_TCP_VM1_VM7'],
               ['Traffic_ARPPing_VM2_VM7'],
               ['CheckDFWPktLog'],

               # Cleanup NetX
               ['RemoveBindingForProfile1'],
               ['RemoveBindingForProfile2'],
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
            ],
            ExitSequence => [
               ['RevertToDefaultRules'],
               ['DeleteMACset'],
               ['DeleteIPset'],
               ['DeleteSecurityGroup'],
            ],
            SetSegmentIDRange => SET_SEGMENTID_RANGE,
            SetMulticastRange => SET_MULTICAST_RANGE,
            PrepCluster1AndVTEPCreate => {
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
            PrepCluster2AndVTEPCreate => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[2]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     vibs         => "install",
                     switch       => "vc.[1].vds.[1]",
                  },
               },
               sleepbetweenworkloads => '10',
            },
            PrepCluster3AndVTEPCreate => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[3]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[3]",
                     vibs         => "install",
                     switch       => "vc.[1].vds.[2]",
                  },
               },
               sleepbetweenworkloads => '20',
            },
            CreateNetworkScope => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1",
                     clusters     => "vc.[1].datacenter.[1].cluster.[1-3]",
                  },
               },
            },
            CreateVirtualWires => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name               => "AutoGenerate",
                     tenantid           => "AutoGenerate",
                     controlplanemode => "MULTICAST_MODE",
                  },
                  "[2]" => {
                     name               => "AutoGenerate",
                     tenantid           => "AutoGenerate",
                     controlplanemode => "MULTICAST_MODE",
                  },
               },
            },
            AddvNICsOnVM1VM3 => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[3]",
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
            AddvNICsOnVM2 => {
               Type   => "VM",
               TestVM => "vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
                  '[2]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            AddvNICsOnVM4VM5VM6 => {
               Type   => "VM",
               TestVM => "vm.[4],vm.[5],vm.[6]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
                  '[2]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            AddvNICsOnVM7 => {
               Type   => "VM",
               TestVM => "vm.[7]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[4]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
                  '[2]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },

               },
            },
            AddvNICsOnVM8 => {
               Type   => "VM",
               TestVM => "vm.[8]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[5]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            SetVXLANIPVM2 => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[2]",
               ipv4       => '172.32.1.5',
               netmask    => "255.255.0.0",
            },
            SetVXLANIPVM7 => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[7].vnic.[2]",
               ipv4       => '172.32.1.6',
               netmask    => "255.255.0.0",
            },
            PoweronVM1 => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            PoweronVM3VM4 => {
               Type    => "VM",
               TestVM  => "vm.[3-4]",
               vmstate => "poweron",
            },
            PoweronVM5VM6 => {
               Type    => "VM",
               TestVM  => "vm.[5-6]",
               vmstate => "poweron",
            },
            PoweronVM8 => {
               Type    => "VM",
               TestVM  => "vm.[8]",
               vmstate => "poweron",
            },
            PoweronVM2VM7 => {
               Type    => "VM",
               TestVM  => "vm.[2],vm.[7]",
               vmstate => "poweron",
            },
            PoweroffVM1_8 => {
               Type    => "VM",
               TestVM  => "vm.[1-8]",
               vmstate => "poweroff",
               sleepbetweenworkloads => '300',
               # Sleep for cluster update background processes to finish
            },
            RevertToDefaultRules => REVERT_DEFAULT_RULES,
            UpgradeNSX => {
               Type          => "NSX",
               TestNSX       => "vsm.[1]",
               profile => "update",
               #build => "2107742",
               build => "from_buildweb",
               build_product => "vsmva",
               build_branch => "vshield-trinity-next",
               build_context => "ob",
               build_type => "release",
               name  => "VMware-NSX-Manager-upgrade-bundle-",
            },
            UpgradeVDNCluster_1 => {
               Type             => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[1]",
               sleepbetweenworkloads => '600',
               # Sleep for upgrade background processes to finish
            },
            UpgradeVDNCluster_2 => {
               Type             => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[2]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[2]",
               sleepbetweenworkloads => '600',
               # Sleep for upgrade background processes to finish
            },
            UpgradeVDNCluster_3 => {
               Type             => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[3]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[3]",
               sleepbetweenworkloads => '600',
               # Sleep for upgrade background processes to finish
            },
            RebootHosts => {
		       Type => 'Host',
		       TestHost => 'host.[1-5]',
		       reboot => 'yes',
            },
            CreateUserSections => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               dfwsection      => {
                   '[1]' => {
                       layer => 'layer3',
                       sectionname => 'DFW upgrade test Section_l3',
                   },
                   '[2]' => {
                       layer => 'layer2',
                       sectionname => 'DFW upgrade test Section_l2',
                   },
               },
            },
            ConfigureRulesOnDFW => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                        name    => 'Block Ping VM2-SG_intra_host',
                        action  => 'deny',
                        section => "vsm.[1].dfwsection.[1]",
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[2]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'SecurityGroup',
                                              value => 'vsm.[1].securitygroup.[1]',
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => "ICMP",
                                                  subprotocolname => "echo-request",
                                               },
                                            ],
                  },
                  '[2]' => {
                        name    => 'Allow HTTP VM1-VM3',
                        action  => 'allow',
                        section => "vsm.[1].dfwsection.[1]",
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value  => "vm.[3]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => "TCP",
                                                  destinationport => "80",
                                               },
                                            ],
                  },
                  '[3]' => {
                        name    => 'Block HTTP VM1-SG_inter_host',
                        action  => 'deny',
                        section => "vsm.[1].dfwsection.[1]",
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'SecurityGroup',
                                              value => 'vsm.[1].securitygroup.[2]',
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => "TCP",
                                                  destinationport => "80",
                                               },
                                            ],
                  },
                  '[4]' => {
                        name    => 'Rule with multiple source and destinations',
                        action  => 'deny',
                        section => "vsm.[1].dfwsection.[1]",
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[2]",
                                      },
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[7]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value  => "vm.[2]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value  => "vm.[7]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => "TCP",
                                                  destinationport => "5000",
                                               },
                                            ],
                  },
                  '[5]' => {
                        name    => 'Rule to test big IP set',
                        action  => 'allow',
                        section => "vsm.[1].dfwsection.[1]",
                        sources => [
                                      {
                                         type  => 'IPSet',
                                         value  => "vsm.[1].ipset.[1]",
                                      },
                                   ],
                        affected_service => [
                                               {
                                                  protocolname => "UDP",
                                               },
                                            ],
                  },
                  '[6]' => {
                        name    => 'Allow and log ARP on vWire1',
                        action  => 'allow',
                        section => "vsm.[1].dfwsection.[2]",
                        logging_enabled => "true",
                        destinations => [
                                           {
                                              type  => 'VirtualWire',
                                              value => "vsm.[1].networkscope.[1].virtualwire.[1]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => "ARP",
                                               },
                                            ],
                  },
                  '[7]' => {
                        name    => 'Rule to test big MAC set',
                        action  => 'allow',
                        section => "vsm.[1].dfwsection.[2]",
                        sources => [
                                      {
                                         type  => 'MACSet',
                                         value  => "vsm.[1].macset.[1]",
                                      },
                                   ],
                  },
               },
            },
            # Traffic to test Rule 1
            TrafficPing_VM1_VM2 => {
               Type           => "Traffic",
               ToolName       => "Ping",
               NoofOutbound    => "1",
               connectivitytest => "0",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "PASS",
            },
            TrafficPing_VM2_VM1 => {
               Type           => "Traffic",
               ToolName       => "Ping",
               NoofOutbound    => "1",
               connectivitytest => "0",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
            },
            # Traffic to test Rule 2,3
            TRAFFIC_HTTP_VM1_VM2 => {
               Type           => "Traffic",
               RoutingScheme  => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "80",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               connectivitytest => "0",
            },
            TRAFFIC_HTTP_VM1_VM3 => {
               Type           => "Traffic",
               RoutingScheme  => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "80",
               TestDuration   => "10",
               Expectedresult => "PASS",
               connectivitytest => "0",
            },
            # Traffic to test Rule 4
            TRAFFIC_TCP_VM1_VM7 => {
               Type           => "Traffic",
               RoutingScheme  => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[7].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "5000",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               connectivitytest => "0",
            },
            TRAFFIC_TCP_VM7_VM1 => {
               Type           => "Traffic",
               RoutingScheme  => "iperf",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "5000",
               TestDuration   => "10",
               Expectedresult => "PASS",
               connectivitytest => "0",
            },
            # Traffic to test Rule 6
            Traffic_ARPPing_VM2_VM7 => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter    => "vm.[2].vnic.[2]",
               SupportAdapter => "vm.[7].vnic.[2]",
               Expectedresult => "PASS",
               TestDuration     => "5",
               connectivitytest => "0",
            },
            CheckVMkernalLog  =>  {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "tail -50 /var/log/vmkernel.log",
               expectedString  => "vsip_pkt: L2 match, PASS,",
            },
            CheckDFWPktLog  =>  {
               Type            => "Command",
               TestHost        => "host.[1]",
               Command         => "tail -50 /var/log/dfwpktlogs.log",
               expectedString  => "L2 match PASS .+ ETHTYPE 0806",
            },
            CreateIPset => {
                Type => 'NSX',
                TestNSX => "vsm.[1]",
                ipset   => {
                   '[1]' => {
                      name  => "BigIPSet",
                      value => IP_LIST,
                      description => "IP set with large number of IPs",
                      inheritanceallowed => "true",
                  },
               },
            },
            CreateMACset => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               macset   => {
                  '[1]' => {
                     name     => "BigMACSet",
                     value   => MAC_LIST,
                     description   => "Large number of MAC addresses",
                     inheritanceallowed  => "false",
                  },
               },
            },
            'CreateSecurityGroup' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               securitygroup => {
                  '[1]' => {
                     'name' => "Security_Group_Intra_Host",
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
                 '[2]' => {
                     'name' => "Security_Group_Inter_Host",
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
                     {
                        'vm_id' => "vm.[3]",
                        'objecttypename' => "VirtualMachine",
                     },
                     {
                        'vm_id' => "vm.[7]",
                        'objecttypename' => "VirtualMachine",
                     },
                     ],
                  },
               },
            },
           'GetDatastore' => GET_DATASTORE,
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
           'CreateVendorTemplateService1' => {
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
           'CreateVendorTemplateService2' => {
              Type       => 'Service',
              TestService    => "vsm.[1].service.[2]",
              vendortemplate => {
                 '[1]' => {
                         'name' => "DEF Company Vendor Template",
                         'description' => 'DEF Company Vendor Template Description',
                         'vendorid' => 'DEF Company Vendor Id',
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
                    'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL_RHEL6_32BIT_60SVM,
                    'vmcienabled' => "true",
                 },
              },
           },
           'CreateVersionedDeploymentSpecService2' => {
              Type       => 'Service',
              TestService    => "vsm.[1].service.[2]",
              versioneddeploymentspec => {
                 '[1]' => {
                    'hostversion' => "5.1.*",
                    'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL_RHEL6_32BIT_60SVM,
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
                         'clusterid' => "vc.[1].datacenter.[1].cluster.[2]",
                         'datastore' => "host.[1].datastore.[1]",
                         'services' => [
                          {
                             'serviceinstanceid' => "vsm.[1].serviceinstance.[1]",
                             'dvportgroup' => "vc.[1].dvportgroup.[3]",
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
                            'clusterid' => "vc.[1].datacenter.[1].cluster.[3]",
                            'datastore' => "host.[1].datastore.[1]",
                            'services' => [
                             {
                                'serviceinstanceid' => "vsm.[1].serviceinstance.[2]",
                                'dvportgroup' => "vc.[1].dvportgroup.[6]",
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
              noofretries  => "30",
           },
           'CheckSVMDeploymentStatusService2' => {
              Type       => 'Service',
              TestService    => "vsm.[1].service.[2]",
              verifyendpointattributes => {
                 'progressstatus[?]equal_to' => "SUCCEEDED",
              },
              noofretries  => "30",
           },
           'CreateTwoServiceProfile' => {
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
                 '[2]' => {
                       'name' => 'DEF Company Service Profile Name',
                       'description' => 'DEF Company Service Profile Name Description',
                       'service' =>{
                            'objectid' => "vsm.[1].service.[2]",
                       },
                       'serviceinstance' => {
                            'objectid' => "vsm.[1].serviceinstance.[2]",
                       },
                       'vendortemplateattribute' => {
                            'id' => "vsm.[1].service.[2].vendortemplate.[1]",
                            'name' => "DEF Company Vendor Template",
                            'description' => "DEF Company Vendor Template Description",
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
           'UpdateBindingForProfile1' => {
              Type       => 'ServiceProfile',
              TestServiceProfile    => "vsm.[1].serviceprofile.[1]",
              serviceprofilebinding => {
                 'virtualwires' => {
                    'virtualwireid' => "vsm.[1].networkscope.[1].virtualwire.[2]",
                 },
                 'excludedvnics' => '',
                 'virtualservers' => '',
                 'distributedvirtualportgroups' =>{
                    'string' => "vc.[1].dvportgroup.[2]",
                 },
              },
           },
           'UpdateBindingForProfile2' => {
              Type       => 'ServiceProfile',
              TestServiceProfile    => "vsm.[1].serviceprofile.[2]",
              serviceprofilebinding => {
                'virtualwires' => {
                   'virtualwireid' => "",
                },
                'excludedvnics' => '',
                'virtualservers' => '',
                'distributedvirtualportgroups' =>{
                   'string' => "vc.[1].dvportgroup.[4]", # add dvpg5 too
                },
              },
           },
           'CheckDVFilterHost3' => {
              'Type' => 'Command',
              'command' => 'summarize-dvfilter',
              'testhost' => 'host.[3-5]',
           },
           'CheckDVFilterHost4' => {
              'Type' => 'Command',
              'command' => 'summarize-dvfilter',
              'testhost' => 'host.[4]',
           },
           'CheckDVFilterHost5' => {
              'Type' => 'Command',
              'command' => 'summarize-dvfilter',
              'testhost' => 'host.[5]',
           },
           'CheckFiltersOnHost3' => {
              'Type' => 'Command',
              'command' => 'vsipioctl getfilters',
              'testhost' => 'host.[3]',
           },
           'CheckFiltersOnHost4' => {
              'Type' => 'Command',
              'command' => 'vsipioctl getfilters',
              'testhost' => 'host.[4]',
           },
           'CheckFiltersOnHost5' => {
              'Type' => 'Command',
              'command' => 'vsipioctl getfilters',
              'testhost' => 'host.[5]',
           },
           'RemoveBindingForProfile1' => {
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
           'RemoveBindingForProfile2' => {
              Type       => 'ServiceProfile',
              TestServiceProfile    => "vsm.[1].serviceprofile.[2]",
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
           DeleteMACset => {
              Type => 'NSX',
              TestNSX => "vsm.[1]",
              deletemacset   => "vsm.[1].macset.[1]",
           },
           DeleteIPset => {
              Type => 'NSX',
              TestNSX => "vsm.[1]",
              deleteipset => "vsm.[1].ipset.[1]",
           },
           DeleteSecurityGroup => {
                Type => 'NSX',
                TestNSX => "vsm.[1]",
                deletesecuritygroup => "vsm.[1].securitygroup.[1-2]",
           },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor for DFWVSMUpgradeTest
#
# Input:
#       none
#
# Results:
#       An instance/object of DFWVSMUpgradeTest class
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
      my $self = $class->SUPER::new(\%DFWVSMUpgradeTest);
      return (bless($self, $class));
}

1;
