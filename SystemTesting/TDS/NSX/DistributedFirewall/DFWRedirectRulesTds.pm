#!/usr/bin/perl
#########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::DistributedFirewall::DFWRedirectRulesTds;

#
# This file contains the structured hash for VSFW layer 3 redirect TDS.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use VDNetLib::TestData::TestConstants;
@ISA = qw(TDS::Main::VDNetMainTds);

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';
use TDS::NSX::ServiceInsertion::CommonWorkloads ':AllConstants';

{
   %DFWRedirectRules = (
     'TestDFWLayer3RedirectAppliedTo'   => {
         TestName         => 'TestDFWLayer3RedirectAppliedTo',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify proper working of applied to field',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost,
         WORKLOADS => {
            Sequence => [
              ['GetDatastore'],
              ['SetSegmentIDRange'],
              ['SetMulticastRange'],
              ['HostPrepAndVTEPCreate'],
              ['CreateServiceManager'],
              ['CreateService'],
              ['CreateVendorTemplate'],
              ['GetServiceInstance'],
              ['CreateVersionedDeploymentSpec'],
              ['DeployService'],
              ['CheckSVMDeploymentStatus'],
              ['GetServiceProfile'],
              ['CheckDVFilter'],
              ['CreateNetworkScope'],
              ['CreateVirtualWires'],
              ['PoweroffVM1VM2'],
              ['AddvNICsOnVM1VM2'],
              ['PoweronVM1VM2'],
              ['MakeSurevNICConnected'],
              ['SetVXLANIPVM1','SetVXLANIPVM2',],
              ['RedirectPingOnVWire'],
              ['ClearDFWPktLog'],
              ['PingTestOverVWire'],
              ['CheckDFWPktLog'],
              ['RedirectPingOnVWire'],
              ['ClearDFWPktLog'],
              ['PingTestOverVWire'],
              ['CheckDFWPktLog'],
              ['CreateApplicationset'],
              ['CreateSecurityGroup'],
              ['Redirect_VM2-VM1_Block_VM1-VM2_ServiceAsAny'],
              ['ClearDFWPktLog'],
              ['TrafficPing_VM1_VM2_redirect'],
              ['CheckDFWPktLog'],
              ['DeleteRule1redirect'],
              ['Redirect_VM2-VM1_Block_VM1-VM2_VariousServices'],
              ['ClearDFWPktLog'],
              ['TrafficPing_VM1_VM2_redirect'],
              ['CheckDFWPktLog'],
              ['ClearDFWPktLog'],
              ['TrafficTCP_VM1_VM2'],
              ['CheckDFWPktLog'],
              ['DeleteRule1redirect'],
              ['Redirect_VM2-VM1_Block_VM1-VM2_VirtualMachine'],
              ['ClearDFWPktLog'],
              ['TrafficPing_VM1_VM2_redirect'],
              ['CheckDFWPktLog'],
              ['DeleteRule1redirect'],
              ['Redirect_VM2-VM1_Block_VM1-VM2_SecurityGroup'],
              ['ClearDFWPktLog'],
              ['TrafficPing_VM1_VM2_redirect'],
              ['CheckDFWPktLog'],
              ['DeleteRule1redirect'],
              ['Redirect_VM2-VM1_Block_VM1-VM2_IPv4'],
              ['ClearDFWPktLog'],
              ['TrafficPing_VM1_VM2_redirect'],
              ['CheckDFWPktLog'],
              ['DeleteRule1redirect'],
              ['Redirect_VM2-VM1_Block_VM1-VM2_IPv6'],
              ['TrafficPing_VM1_VM2_redirect'],
              ['DeleteRule1redirect'],
            ],
            ExitSequence => [
              ['PoweroffVM1VM2'],
              ['RemovevNICFromVM1VM2'],
              ['DeleteVirtualWires'],
              ['DeleteNetworkScopes'],
              ['UnconfigureVXLAN'],
              ['ResetSegmentID'],
              ['ResetMulticast'],
              ['RemoveBinding'],
              ['DeleteServiceCluster'],
              ['DeleteServiceProfile'],
              ['DeleteServiceInstance'],
              ['DeleteVendorTemplate'],
              ['CheckSVMUndeploymentStatus'],
              ['DeleteService'],
              ['DeleteServiceManager'],
              ['RevertToDefaultRules'],
            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            'GetDatastore' => GET_DATASTORE,
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
            'SetSegmentIDRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               segmentidrange => {
                  '[1]' => {
                     name  => "AutoGenerate",
                     begin => "5001",
                     end   => "99000",
                  },
               }
            },
            'SetMulticastRange' => SET_MULTICAST_RANGE,
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
            "SetVXLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '172.32.1.6',
               netmask    => "255.255.0.0",
            },
            'PoweroffVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweroff",
            },
            'RemovevNICFromVM1VM2' => {
               Type       => "VM",
               TestVM     => "vm.[1-2]",
               deletevnic => "vm.[x].vnic.[1]",
            },
            'DeleteVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'DeleteNetworkScopes' => DELETE_ALL_NETWORKSCOPES,
            'UnconfigureVXLAN' => UNCONFIGUREVXLAN_ClusterSJC_VDS1,
            'ResetSegmentID' => RESET_SEGMENTID,
            'ResetMulticast' => RESET_MULTICASTRANGE,
            'CreateServiceManager' => CREATE_SERVICE_MANAGER,
            'RemoveBinding' => REMOVE_BINDING,
            'CheckDVFilter' => CHECK_DVFILTER,
            'CreateService' => CREATE_SERVICE,
            'CreateVendorTemplate' => CREATE_VENDOR_TEMPLATE,
            'GetServiceInstance' => GET_SERVICE_INSTANCE,
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
                                'dvportgroup' => "vc.[1].dvportgroup.[1]",
                             },
                            ],
                        },
                       ],
                     },
               },
            },
            'CheckSVMDeploymentStatus' => CHECK_SVM_DEPLOYMENT_STATUS,
            'GetServiceProfile' => GET_SERVICE_PROFILE,
            'DeleteServiceCluster' => DELETE_SERVICE_CLUSTER,
            'DeleteServiceProfile' => DELETE_SERVICE_PROFILE,
            'DeleteServiceInstance' => DELETE_SERVICE_INSTANCE,
            'DeleteVendorTemplate' => DELETE_VENDOR_TEMPLATE,
            'CheckSVMUndeploymentStatus' => CHECK_SVM_UNDEPLOYMENT_STATUS,
            'DeleteService' => DELETE_SERVICE,
            'DeleteServiceManager' => DELETE_SERVICE_MANAGER,
            "RedirectPingOnVWire" => {
               ExpectedResult	=> "PASS",
               Type			=> "NSX",
               TestNSX		    => "vsm.[1]",
               firewallrule			=> {
                  '[1]' => {
                        layer => "layer3redirect",
                        name    => 'Redirect_Ping_Traffic_OnlyBetween_VM1_VM2',
                        logging_enabled => 'true',
                        action  => 'Redirect',
                        section => 'default',
                        siprofile => {
                                        objectid => 'vsm.[1].serviceprofile.[1]',
                                        name => 'ABC Company Service_ABC Company Vendor Template',   # Temporary Fix to accomodate bug #1288673
                                     },

                        appliedto => [
                                           {
                                              type  => 'VirtualWire',
                                              value => "vsm.[1].networkscope.[1].virtualwire.[1]",
                                           },
                                     ],
                        affected_service => [
                                               {
                                                  protocolname => 'ICMP',
                                               },
                                            ],
                  },
               },
            },
            "PingTestOverVWire" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               NoofInbound    => 1,
               NoofOutbound   => 1,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               NoofOutbound   => 1,
               Expectedresult => "PASS",
            },
            "TrafficTCP_VM1_VM2" => {
               Type           => "Traffic",
               Expectedresult => "PASS",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               PortNumber     => "80",
               NoofOutbound   => "1",
               TestDuration   => "5",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
            "RevertToDefaultRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               firewallrule => {
                  '[-1]' => {}
               }
            },
            'CreateApplicationset' => {
              Type => 'NSX',
               TestNSX => "vsm.[1]",
               applicationservice => {
                  '[1]' => {
                     name    => "appset_1",
                     element => {
                        applicationprotocol  => "TCP",
                        value   => "1024",
                        sourceport  => "1024",
                     },
                     description   => "testing application set 1",
                     inheritanceallowed  => "false",
                  },
                   '[2]' => {
                     name    => "appset_2",
                     element => {
                        applicationprotocol  => "UDP",
                        value   => "24",
                        sourceport  => "44000",
                     },
                     description   => "testing application set 2",
                     inheritanceallowed  => "false",
                  },
                  '[3]' => {
                     name    => "appset_3",
                     element => {
                        applicationprotocol  => "IPV6FRAG",
                     },
                     description   => "testing application set 3",
                     inheritanceallowed  => "false",
                  },
                },
              },
           'CreateSecurityGroup' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               securitygroup => {
                  '[1]' => {
                     'name' => "VM_1_Security_Group",
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
                        'vnic_id' => "vm.[1].vnic.[1]",
                        'objecttypename' => "Vnic",
                     },
                     ],
                  },
                 '[2]' => {
                     'name' => "VM_2_Security_Group",
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
                        'vnic_id' => "vm.[2].vnic.[1]",
                        'objecttypename' => "Vnic",
                     },
                     ],
                  },
                  },
               },
             'Redirect_VM2-VM1_Block_VM1-VM2_ServiceAsAny' => {
               ExpectedResult   => "PASS",
               Type                     => "NSX",
               TestNSX              => "vsm.[1]",
               firewallrule                     => {
                  '[1]' => {
                        layer => "layer3redirect",
                        name    => 'Redirect_VM2-VM1',
                        action  => 'Redirect',
                        section => 'default',
                        logging_enabled => 'true',
                        siprofile => {
                                        objectid => 'vsm.[1].serviceprofile.[1]',
                                        name => 'ABC Company Service_ABC Company Vendor Template',   # Temporary Fix to accomodate bug #1288673
                                     },
                        sources => [
                                     {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value     => "vm.[2]",
                                           },
                                        ],
                        affected_service => [
                                            ],
                        appliedto => [
                                           {
                                              type  => 'VirtualWire',
                                              value => "vsm.[1].networkscope.[1].virtualwire.[1]",
                                           },
                                     ],
                  },
                  '[2]' => {
                        layer => "layer3redirect",
                        name    => 'Block_VM1-VM2',
                        action  => 'deny',
                        section => 'default',
                        logging_enabled => 'true',
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value     => "vm.[2]",
                                           },
                                        ],
                        affected_service => [
                                            ],
                        appliedto => [
                                           {
                                              type  => 'VirtualWire',
                                              value => "vsm.[1].networkscope.[1].virtualwire.[1]",
                                           },
                                     ],
                  },
                },
             },
             'TrafficPing_VM1_VM2_redirect' => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               NoofOutbound   => "2",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "PASS",
            },
            'Redirect_VM2-VM1_Block_VM1-VM2_VariousServices' => {
               ExpectedResult   => "PASS",
               Type                     => "NSX",
               TestNSX              => "vsm.[1]",
               firewallrule                     => {
                  '[1]' => {
                        layer => "layer3redirect",
                        name    => 'Redirect_VM2-VM1',
                        action  => 'Redirect',
                        section => 'default',
                        logging_enabled => 'true',
                        siprofile => {
                                        objectid => 'vsm.[1].serviceprofile.[1]',
                                        name => 'ABC Company Service_ABC Company Vendor Template',   # Temporary Fix to accomodate bug #1288673
                                     },
                        affected_service => [
                                               {
                                                  protocolname => 'ICMP',
                                               },
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '80',
                                               },
                                               {
                                                   type => 'Application',
                                                   value => "vsm.[1].applicationservice.[1]",
                                               },
                                               {
                                                   type => 'Application',
                                                   value => "vsm.[1].applicationservice.[2]",
                                               },
                                               {
                                                   type => 'Application',
                                                   value => "vsm.[1].applicationservice.[3]",
                                               },
                                            ],
                        appliedto => [
                                           {
                                              type  => 'VirtualWire',
                                              value => "vsm.[1].networkscope.[1].virtualwire.[1]",
                                           },
                                     ],
                  },
               },
            },
           'Redirect_VM2-VM1_Block_VM1-VM2_VirtualMachine' => {
               ExpectedResult   => "PASS",
               Type                     => "NSX",
               TestNSX              => "vsm.[1]",
               firewallrule                     => {
                  '[1]' => {
                        layer => "layer3redirect",
                        name    => 'Redirect_VM2-VM1',
                        action  => 'Redirect',
                        section => 'default',
                        logging_enabled => 'true',
                        siprofile => {
                                        objectid => 'vsm.[1].serviceprofile.[1]',
                                        name => 'ABC Company Service_ABC Company Vendor Template',   # Temporary Fix to accomodate bug #1288673
                                     },
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value     => "vm.[2]",
                                           },
                                        ],
                        appliedto => [
                                           {
                                              type  => 'VirtualWire',
                                              value => "vsm.[1].networkscope.[1].virtualwire.[1]",
                                           },
                                     ],
                  },
               },
            },
           'Redirect_VM2-VM1_Block_VM1-VM2_SecurityGroup' => {
               ExpectedResult   => "PASS",
               Type                     => "NSX",
               TestNSX              => "vsm.[1]",
               firewallrule                     => {
                  '[1]' => {
                        layer => "layer3redirect",
                        name    => 'Redirect_VM2-VM1',
                        action  => 'Redirect',
                        section => 'default',
                        logging_enabled => 'true',
                        siprofile => {
                                        objectid => 'vsm.[1].serviceprofile.[1]',
                                        name => 'ABC Company Service_ABC Company Vendor Template',   # Temporary Fix to accomodate bug #1288673
                                     },
                        sources => [
                                      {
                                        type => 'SecurityGroup',
                                        value => "vsm.[1].securitygroup.[1]",
                                      },
                                   ],
                        destinations => [
                                           {
                                             type => 'SecurityGroup',
                                             value => "vsm.[1].securitygroup.[2]",
                                           },
                                        ],
                        appliedto => [
                                           {
                                              type  => 'VirtualWire',
                                              value => "vsm.[1].networkscope.[1].virtualwire.[1]",
                                           },
                                     ],
                  },
               },
            },
           'Redirect_VM2-VM1_Block_VM1-VM2_IPv4' => {
               ExpectedResult   => "PASS",
               Type                     => "NSX",
               TestNSX              => "vsm.[1]",
               firewallrule                     => {
                  '[1]' => {
                        layer => "layer3redirect",
                        name    => 'Redirect_VM2-VM1',
                        action  => 'Redirect',
                        section => 'default',
                        logging_enabled => 'true',
                        siprofile => {
                                        objectid => 'vsm.[1].serviceprofile.[1]',
                                        name => 'ABC Company Service_ABC Company Vendor Template',   # Temporary Fix to accomodate bug #1288673
                                     },
                        sources => [
                                      {
                                          type => 'Ipv4Address',
                                          value => "vm.[1].vnic.[1]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'Ipv4Address',
                                              value => "vm.[2].vnic.[1]",
                                           },
                                        ],
                        appliedto => [
                                           {
                                              type  => 'VirtualWire',
                                              value => "vsm.[1].networkscope.[1].virtualwire.[1]",
                                           },
                                     ],
                  },
               },
            },
           'Redirect_VM2-VM1_Block_VM1-VM2_IPv6' => {
               ExpectedResult   => "PASS",
               Type                     => "NSX",
               TestNSX              => "vsm.[1]",
               firewallrule                     => {
                  '[1]' => {
                        layer => "layer3redirect",
                        name    => 'Redirect_VM2-VM1',
                        action  => 'Redirect',
                        section => 'default',
                        logging_enabled => 'true',
                        siprofile => {
                                        objectid => 'vsm.[1].serviceprofile.[1]',
                                        name => 'ABC Company Service_ABC Company Vendor Template',   # Temporary Fix to accomodate bug #1288673
                                     },
                        sources => [
                                         {
                                            type => 'Ipv6Address',
                                            value     => "vm.[1].vnic.[1]",
                                        },
                                   ],
                        destinations => [
                                           {
                                               type => 'Ipv6Address',
                                               value     => "vm.[2].vnic.[1]",
                                           },
                                        ],
                        appliedto => [
                                           {
                                              type  => 'VirtualWire',
                                              value => "vsm.[1].networkscope.[1].virtualwire.[1]",
                                           },
                                     ],
                  },
               },
            },
           "DeleteRule1redirect" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
         },
      },
     'TestDFWLayer3RedirectFunctional'   => {
          TestName         => 'TestDFWLayer3RedirectFunctional',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that different Traffic types between VM1 and'.
                             ' VM2 is redirected to external firewall device',
         Procedure        => '1. Create New Section'.
                             '2. Add rule to redirect the test ports for traffic'.
                             '3. Add rule to redirect traffic between VM1 and VM2'.
                             '4. Add the rule to not redirect all the traffic'.
                                 ' testing'.
                             '5. Send traffic between the VM1 and VM2 ipaddresses'.
                                 ' in both directions'.
                             '6. Verify the traffic is flowing between VM1 and '.
                                 'VM2 in both directions'.
                             '7. Verify the traffic is not redirected between'.
                                 ' VM3 and VM1'.
                             '8. Verify the traffic is not redirected  between'.
                                 ' VM3 and VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_TwoDVPG_OneHost_OneVmnicForHost,
         WORKLOADS => {
            Sequence => [
              ['GetDatastore'],
              ['PrepCluster'],
              ['CreateServiceManager'],
              ['CreateService'],
              ['CreateVendorTemplate'],
              ['GetServiceInstance'],
              ['CreateVersionedDeploymentSpec'],
              ['DeployService'],
              ['CheckSVMDeploymentStatus'],
              ['GetServiceProfile'],
              ['UpdateBinding'],
              ['CheckDVFilter'],
              ['Redirect_ICMP_VM2-VM1_Block_ICMP_VM1-VM2'],
              ['TrafficPing_VM1_VM2'],
              ['TrafficTCP_VM1_VM2'],
              ['TrafficTCP_VM2_VM1'],
            ],
            ExitSequence => [
              ['RemoveBinding'],
              ['DeleteServiceCluster'],
              ['DeleteServiceProfile'],
              ['DeleteServiceInstance'],
              ['DeleteVendorTemplate'],
              ['CheckSVMUndeploymentStatus'],
              ['DeleteService'],
              ['DeleteServiceManager'],
              ['DeleteRule1redirect'],
              ['RevertToDefaultRules'],
            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            'GetDatastore' => GET_DATASTORE,
            'PrepCluster' => PREP_CLUSTER,
            'CreateServiceManager' => CREATE_SERVICE_MANAGER,
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
            'CheckDVFilter' => CHECK_DVFILTER,
            'CreateService' => CREATE_SERVICE,
            'CreateVendorTemplate' => CREATE_VENDOR_TEMPLATE,
            'GetServiceInstance' => GET_SERVICE_INSTANCE,
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
            'CheckSVMDeploymentStatus' => CHECK_SVM_DEPLOYMENT_STATUS,
            'GetServiceProfile' => GET_SERVICE_PROFILE,
            'DeleteServiceCluster' => DELETE_SERVICE_CLUSTER,
            'DeleteServiceProfile' => DELETE_SERVICE_PROFILE,
            'DeleteServiceInstance' => DELETE_SERVICE_INSTANCE,
            'DeleteVendorTemplate' => DELETE_VENDOR_TEMPLATE,
            'RemoveBinding' => REMOVE_BINDING,
            'CheckSVMUndeploymentStatus' => CHECK_SVM_UNDEPLOYMENT_STATUS,
            'DeleteService' => DELETE_SERVICE,
            'DeleteServiceManager' => DELETE_SERVICE_MANAGER,
            "Redirect_ICMP_VM2-VM1_Block_ICMP_VM1-VM2" => {
               ExpectedResult	=> "PASS",
               Type			=> "NSX",
               TestNSX		    => "vsm.[1]",
               firewallrule			=> {
                  '[1]' => {
                        layer => "layer3redirect",
                        name    => 'Redirect_ICMP_VM2-VM1',
                        action  => 'Redirect',
                        section => 'default',
                        logging_enabled => 'true',
                        siprofile => {
                                        objectid => 'vsm.[1].serviceprofile.[1]',
                                        name => 'ABC Company Service_ABC Company Vendor Template',   # Temporary Fix to accomodate bug #1288673
                                     },
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value	=> "vm.[2]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value	=> "vm.[1]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'ICMP',
                                               },
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '80',
                                               },
                                            ],
                  },
                  '[2]' => {
                        layer => "layer3",
                        name    => 'Block_ICMP_VM1-VM2',
                        action  => 'deny',
                        section => 'default',
                        logging_enabled => 'true',
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value	=> "vm.[1]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value	=> "vm.[2]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'ICMP',
                                               },
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '80',
                                               },
                                            ],
                  },
               },
            },
	    "DeleteRule1redirect" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
            "TrafficPing_VM1_VM2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               NoofOutbound   => "2",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "TrafficTCP_VM1_VM2" => {
               Type           => "Traffic",
               Expectedresult => "FAIL",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               PortNumber     => "80",
               NoofOutbound   => "1",
               TestDuration   => "5",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
            },
            "TrafficTCP_VM2_VM1" => {
               Type           => "Traffic",
               Expectedresult => "PASS",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               PortNumber     => "80",
               NoofOutbound   => "1",
               TestDuration   => "5",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
            },
            "RevertToDefaultRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               firewallrule => {
                  '[-1]' => {}
               }
            },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor
#
# Input:
#       none
#
# Results:
#       An instance/object of VSFW class
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
      my $self = $class->SUPER::new(\%DFWRedirectRules);
      return (bless($self, $class));
}

1;

