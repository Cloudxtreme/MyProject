#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::DistributedFirewall::DistributedFirewallSanityTds;

#
# This file contains the structured hash for VSFW firewall TDS.
# The following lines explain the keys of the internal
# hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use VDNetLib::TestData::TestConstants;
@ISA = qw(TDS::Main::VDNetMainTds);

{
   %DistributedFirewallSanity = (
      'IPSetSanity'   => {
         TestName         => 'IPSet Sanity',
         Category         => 'vShield-REST-APIs',
         Component        => 'Grouping Objects',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Sanity test for Ipset Create/Modify/Delete',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
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
               ['CreateIPset'],
               ['VerifyIPset1'],
               ['VerifyIPset2'],
               ['UpdateIPset3'],
               ['VerifyIPset3'],
            ],
            ExitSequence => [
               ['DeleteIPset'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'PrepCluster' => {
               Type    => 'NSX',
               TestNSX => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'VerifyIPset1' => {
               Type => 'NSX',
               TestNSX => "vsm.[1].ipset.[1]",
               verifyipsetattributes   => {
                  "name[?]equal_to" => "ipset-100",
                  "value[?]equal_to" => ["vm.[1].vnic.[1]"],
                  "description[?]equal_to" => "testing ipset_1",
                  "inheritanceallowed[?]equal_to" => "true",
               },
            },
            'VerifyIPset2' => {
               Type => 'NSX',
               TestNSX => "vsm.[1].ipset.[2]",
               verifyipsetattributes   => {
                  "name[?]equal_to" => "ipset-101",
                  "value[?]equal_to" => ["194.168.0.101/24"],
                  "description[?]equal_to" => "testing ipset_2",
                  "inheritanceallowed[?]equal_to" => "false",
               },
            },
            'CreateIPset' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               ipset   => {
                  '[1]' => {
                     name  => "ipset-100",
                     value => "vm.[1].vnic.[1]",
                     description => "testing ipset_1",
                     inheritanceallowed => "true",
                  },
                  '[2]' => {
                     name  => "ipset-101",
                     value => "194.168.0.101/24",
                     description => "testing ipset_2",
                     inheritanceallowed => "false",
                  },
                  '[3]' => {
                     name  => "ipset-102",
                     value => "192.168.10.101-192.168.10.110,10.1.1.20/24",
                     description => "testing ipset_3",
                  },
               },
            },
            'DeleteIPset' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteipset => "vsm.[1].ipset.[1-3]",
            },
            'UpdateIPset3' => {
               Type => 'GroupingObject',
               Testgroupingobject => "vsm.[1].ipset.[3]",
               reconfigure => "True",
               name => "ipset-name-changed-$$",
            },
            'VerifyIPset3' => {
               Type => 'NSX',
               TestNSX => "vsm.[1].ipset.[3]",
               verifyipsetattributes   => {
                  "name[?]equal_to" => "ipset-name-changed-$$",
                  "value[?]contain_once" => ["192.168.10.101-192.168.10.110","10.1.1.20/24"],
                  "description[?]equal_to" => "testing ipset_3",
                  "inheritanceallowed[?]equal_to" => "false",
               },
            },
         },
      },
      'MACSetSanity'   => {
         TestName         => 'MACSet Sanity',
         Category         => 'vShield-REST-APIs',
         Component        => 'Grouping Objects',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Sanity test for MACset Create/Modify/Delete',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
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
               ['CreateMACset'],
               ['UpdateMACset'],
               ['VerifyMACset1'],
               ['VerifyMACset2'],
            ],
            ExitSequence => [
               ['DeleteMACset'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'PrepCluster' => {
               Type    => 'NSX',
               TestNSX => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
           'CreateMACset' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               macset   => {
                  '[1]' => {
                     name     => "macset-1-$$",
                     value   => "vm.[2].vnic.[1]",
                     description   => "testing macset-1",
                     inheritanceallowed  => "false",
                  },
                  '[2]' => {
                     name     => "macset-2-$$",
                     value   => "00:11:12:13:14:15,01:11:12:13:14:16",
                     description   => "testing macset-2",
                     inheritanceallowed  => "true",
                  },
               },
            },
            'DeleteMACset' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deletemacset   => "vsm.[1].macset.[1-2]",
            },
            'UpdateMACset' => {
               Type => 'GroupingObject',
               Testgroupingobject => "vsm.[1].macset.[1]",
               reconfigure  => "true",
               name => "macset_name_changed_$$",
               value => "aa:bb:cc:dd:ee:ff",
               description => "Updating the macset-1-$$",
               inheritanceallowed => "true",
            },
            'VerifyMACset1' => {
               Type => 'NSX',
               TestNSX => "vsm.[1].macset.[1]",
               verifymacsetattributes   => {
                  "name[?]equal_to" => "macset_name_changed_$$",
                  "value[?]equal_to" => ["aa:bb:cc:dd:ee:ff"],
                  "description[?]equal_to" => "Updating the macset-1-$$",
                  "inheritanceallowed[?]equal_to" => "true",
               },
            },
            'VerifyMACset2' => {
               Type => 'NSX',
               TestNSX => "vsm.[1].macset.[2]",
               verifymacsetattributes   => {
                  "name[?]equal_to" => "macset-2-$$",
                  "value[?]contain_once" => ["00:11:12:13:14:15","01:11:12:13:14:16"],
                  "description[?]equal_to" => "testing macset-2",
                  "inheritanceallowed[?]equal_to" => "true",
               },
            },
         },
      },
      'ServiceGroupSanity'   => {
         TestName         => 'Servicegroup Sanity',
         Category         => 'vShield-REST-APIs',
         Component        => 'Grouping Objects',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Sanity test for ApplicationService, Servicegroup'.
                              'and Servicegroupmember Create/Update/Delete',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
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
               ['CreateApplicationset'],
               ['CreateApplicationGroup'],
               ['AddMemberToApplicationGroup_2'],
               ['AddMemberToApplicationGroup_1'],
               ['UpdateApplicationGroup'],
               ['UpdateApplicationset'],
               ['VerifyApplicationset_1'],
            ],
            ExitSequence => [
               ['DeleteMemberFromApplicationGroup'],
               ['DeleteApplicationGroup'],
               ['DeleteApplicationset'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'PrepCluster' => {
               Type    => 'NSX',
               TestNSX => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'DeleteMemberFromApplicationGroup' => {
                Type                       => "GroupingObject",
                Testgroupingobject         => "vsm.[1].applicationservicegroup.[1]",
                deleteapplicationservicegroupmember   => "vsm.[1].applicationservicegroup.[1].applicationservicegroupmember.[1-3]",
            },
            'AddMemberToApplicationGroup_1' => {
                Type               => "GroupingObject",
                Testgroupingobject => "vsm.[1].applicationservicegroup.[1]",
                applicationservicegroupmember => {
                   "[1]" => {
                       member => "vsm.[1].applicationservice.[1]",
                   },
                   "[2]" => {
                       member => "vsm.[1].applicationservice.[2]",
                   },
                   "[3]" => {
                       member => "vsm.[1].applicationservicegroup.[2]",
                   },
                },
            },
            'AddMemberToApplicationGroup_2' => {
                Type               => "GroupingObject",
                Testgroupingobject => "vsm.[1].applicationservicegroup.[2]",
                applicationservicegroupmember => {
                   "[1]" => {
                       member => "vsm.[1].applicationservice.[3]",
                   },
               },
            },
            'UpdateApplicationGroup' => {
               Type => 'GroupingObject',
               Testgroupingobject => "vsm.[1].applicationservicegroup.[1]",
               reconfigure => "True",
               name => "servicegroup-name-changed-$$",
               description => "servicegroup is getting updated",
               inheritanceallowed => "true",
            },
            'DeleteApplicationGroup' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteapplicationservicegroup => "vsm.[1].applicationservicegroup.[1]",
            },
            'CreateApplicationGroup' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               applicationservicegroup => {
                  '[1]' => {
                     name => "appgrp_1_$$",
                     description => "service group-1 creation",
                     inheritanceallowed  => "false",
                  },
                  '[2]' => {
                     name => "appgrp_2_$$",
                     description => "service group-2 creation",
                     inheritanceallowed  => "false",
                  },
               },
            },
            'CreateApplicationset' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               applicationservice => {
                  '[1]' => {
                     name    => "appset_1_$$",
                     element => {
                        applicationprotocol  => "TCP",
                        value   => "1024,1025-1029",
                        sourceport  => "33000",
                     },
                     description   => "testing application set 1",
                     inheritanceallowed  => "false",
                  },
                  '[2]' => {
                     name    => "appset_2_$$",
                     element => {
                        applicationprotocol  => "UDP",
                        value   => "24,25-29",
                        sourceport  => "44000",
                     },
                     description   => "testing application set 2",
                     inheritanceallowed  => "false",
                  },
                  '[3]' => {
                     name    => "appset_3_$$",
                     element => {
                        applicationprotocol  => "IPV6FRAG",
                     },
                     description   => "testing application set 3",
                     inheritanceallowed  => "false",
                  },
               },
            },
            'UpdateApplicationset' => {
               Type => 'GroupingObject',
               Testgroupingobject => "vsm.[1].applicationservice.[1]",
               reconfigure => "True",
               name => "appset-name-changed_$$",
               element => {
                  value => "20-23",
                  sourceport => "33001",
               },
               description => "Changed the application attributes $$",
               inheritanceallowed => "true",
            },
            'DeleteApplicationset' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteapplicationservice => "vsm.[1].applicationservice.[1-3]",
            },
            'VerifyApplicationset_1' => {
               Type => 'NSX',
               TestNSX => "vsm.[1].applicationservice.[1]",
               verifyapplicationserviceattributes => {
                  "name[?]equal_to" => "appset-name-changed_$$",
                  "element" => {
                     "value[?]equal_to" => "20-23",
                     "sourceport[?]equal_to" => "33001",
                  },
                  "description[?]equal_to" => "Changed the application attributes $$",
                  "inheritanceallowed[?]equal_to" => "true",
               },
            },
         },
      },
      'BlockAllTraffic_AllowPingOnlyBetween_VM1andVM2'   => {
         TestName         => 'BlockAllTraffic_AllowPingOnlyBetween_VM1andVM2',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic is allowed between VM1 and'.
                             ' VM2 and all others are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic'.
                             '3. Add rule to allow ping traffic between VM1 and VM2'.
                             '4. Add rule to allow the the test ports for traffic'.
                                 ' testing'.
                             '5. Send ping traffic between the VM1 and VM2 ipaddresses'.
                                 ' in both directions'.
                             '6. Verify the traffic is flowing between VM1 and '.
                                 'VM2 in both directions'.
                             '7. Verify the TCP traffic does not pass through between'.
                                 ' VM1 and VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Draft',
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
                    ['PrepCluster'],
                    ['CreateUserSection'],
                    ['AllowPing_VM1_VM2_Block_Rest'],
                    ['TrafficPing_VM1_VM2'],
                    ['TrafficTCP_VM1_VM2'],
                    ],
            ExitSequence => [
                            ['DeleteRule1_3'],
                            ['RemoveUserSection'],
                            ['RevertToDefaultRules'],
                            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            'PrepCluster' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            "CreateUserSection" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               dfwsection      => {
                   '[1]' => {
                       layer => 'layer3',
                       sectionname => 'Section1',
                   },
               },
            },
            "RemoveUserSection" => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               deletedfwsection => "vsm.[1].dfwsection.[1]",
            },
            "AllowPing_VM1_VM2_Block_Rest" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule         => {
                  '[1]' => {
                        name    => 'Allow_Traffic_OnlyBetween_VM1_VM2',
                        action  => 'allow',
                        section => 'vsm.[1].dfwsection.[1]',
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[2]",
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
                        affected_service => [
                                               {
                                                  protocolname => 'ICMP',
                                               },
                                            ],
                  },
                  '[2]' => {
                        name    => 'Allow_STAF_SSH_NFS',
                        action  => 'allow',
                        section => 'vsm.[1].dfwsection.[1]',
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '22,2049,6500',
                                               },
                                            ],
                  },
                  '[3]' => {
                        layer => "layer3",
                        name    => 'Block all',
                        action  => 'deny',
                        section => 'default',
                  },
               },
            },
            "DeleteRule1_3" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
            "TrafficPing_VM1_VM2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "PASS",
            },
            "TrafficTCP_VM1_VM2" => {
               Type           => "Traffic",
               Expectedresult => "FAIL",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
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
         },
      },
      'TestDFWLayer2Functional'   => {
         TestName         => 'TestDFWLayer2Functional',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify functionality of L2 rules',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block ARP between VM1 and VM2'.
                             '3. Send ARPPing traffic between the VM1 and VM2'.
                                 ' in both directions'.
                             '4. Verify the traffic does not pass through between'.
                             '5. Delete the rule'.
                             '6. Verify the traffic passes through between'.
                                 ' VM1 and VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Draft',
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
                    ['PrepCluster'],
                    ['CreateUserSection'],
                    ['BlockARPPing_VM1_VM2'],
                    ['Traffic1ARPPing_VM1_VM2'],
                    ['DeleteRule1'],
                    ['Traffic2ARPPing_VM1_VM2'],
                    ],
            ExitSequence => [
                            ['RemoveUserSection'],
                            ['RevertToDefaultRules'],
                            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            'PrepCluster' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            "CreateUserSection" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               dfwsection      => {
                   '[1]' => {
                       layer => 'layer2',
                       sectionname => 'Section1',
                   },
               },
            },
            "RemoveUserSection" => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               deletedfwsection => "vsm.[1].dfwsection.[1]",
            },
            "BlockARPPing_VM1_VM2" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule         => {
                  '[1]' => {
                        name    => 'Block_ARP_Ping_VM1_VM2',
                        action  => 'deny',
                        section => 'vsm.[1].dfwsection.[1]',
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[2]",
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
                        affected_service => [
                                               {
                                                  protocolname => 'ARP',
                                               },
                                            ],
                  },
               },
            },
            "DeleteRule1" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
            "Traffic1ARPPing_VM1_VM2" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
               TestDuration     => "5",
               connectivitytest => "0",
            },
            "Traffic2ARPPing_VM1_VM2" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "PASS",
               TestDuration     => "5",
               connectivitytest => "0",
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
      'TestAppliedToField'   => {
         TestName         => 'TestAppliedToField',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify if different entities in applied-to'.
                             'field work as expected',
         Procedure        => '1. Create user section'.
                             '2. Add rule to allow management traffic to the section'.
                             '3. Add rule to block ping over DVPG to default section'.
                             '4. Send ping and TCP traffic between the VM1 and VM2'.
                             '5. Verify the TCP traffic is flowing between VM1 and '.
                                 'VM2 but Ping is blocked'.
                             '6. Delete rule in step 3'.
                             '7. Repeat for DC, Cluster, Vnics',
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
                    ['PrepCluster'],
                    ['CreateUserSection'],
                    ['AllowManagementTraffic'],
                    ['BlockPingOverDVPG'],
                    ['TrafficPing_VM1_VM2'],
                    ['TrafficTCP_VM1_VM2'],
                    ['DeleteRule2'],
                    ['BlockPingInDC'],
                    ['TrafficPing_VM1_VM2'],
                    ['TrafficTCP_VM1_VM2'],
                    ['DeleteRule2'],
                    ['BlockPingInCluster'],
                    ['TrafficPing_VM1_VM2'],
                    ['TrafficTCP_VM1_VM2'],
                    ['DeleteRule2'],
                    ['BlockPingOnVNIC'],
                    ['TrafficPing_VM1_VM2'],
                    ['TrafficTCP_VM1_VM2'],
                    ['DeleteRule2'],
                    ['CreateSecurityGroup'],
                    ['BlockPingInSecurityGroup'],
                    ['TrafficPing_VM1_VM2'],
                    ['TrafficTCP_VM1_VM2'],
                    ],
            ExitSequence => [
                            ['RevertToDefaultRules'],
                            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            'PrepCluster' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'CreateSecurityGroup' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               securitygroup => {
                  '[1]' => {
                     'name' => "VM_1_2_Security_Group",
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
            "CreateUserSection" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               dfwsection      => {
                   '[1]' => {
                       layer => 'layer3',
                       sectionname => 'Section1',
                   },
               },
            },
            "AllowManagementTraffic" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule         => {
                  '[1]' => {
                        name    => 'Allow_STAF_SSH_NFS',
                        action  => 'allow',
                        section => 'vsm.[1].dfwsection.[1]',
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '22,2049,6500',
                                               },
                                            ],
                  },
               },
            },
            "BlockPingInSecurityGroup" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule         => {
                  '[2]' => {
                        name    => 'Block Ping in Security Group',
                        action  => 'deny',
                        layer => 'layer3',
                        appliedto => [
                                           {
                                              type  => 'SecurityGroup',
                                              value => "vsm.[1].securitygroup.[1]",
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
            "BlockPingOverDVPG" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule         => {
                  '[2]' => {
                        name    => 'Block Ping on DVPG',
                        action  => 'deny',
                        layer => 'layer3',
                        appliedto => [
                                           {
                                              type  => 'DistributedVirtualPortgroup',
                                              value => "vc.[1].dvportgroup.[1]",
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
            "BlockPingInDC" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule         => {
                  '[2]' => {
                        name    => 'Block Ping In DC',
                        action  => 'deny',
                        layer => 'layer3',
                        appliedto => [
                                           {
                                              type  => 'Datacenter',
                                              value => "vc.[1].datacenter.[1]",
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
            "BlockPingInCluster" => {
               ExpectedResult  => "PASS",
               Type            => "NSX",
               TestNSX         => "vsm.[1]",
               firewallrule         => {
                  '[2]' => {
                        name    => 'Block Ping In Cluster',
                        action  => 'deny',
                        layer => 'layer3',
                        appliedto => [
                                           {
                                              type  => 'ClusterComputeResource',
                                              value => "vc.[1].datacenter.[1].cluster.[1]",
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
            "BlockPingOnVNIC" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule         => {
                  '[2]' => {
                        name    => 'Block Ping On VNIC',
                        action  => 'deny',
                        layer => 'layer3',
                        appliedto => [
                                           {
                                              type  => 'Vnic',
                                              value => "vm.[1].vnic.[1]",
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
            "DeleteRule2" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[2]",
            },
            "TrafficPing_VM1_VM2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               NoofOutbound    => "1",
               connectivitytest => "0",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "TrafficTCP_VM1_VM2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L3Protocol     => "ipv4",
               L4Protocol     => "tcp",
               NoofOutbound   => "1",
               TestDuration   => "5",
               connectivitytest => "0",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "PASS",
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
      'SecurityGroupSanity'   => {
         TestName         => 'Securitygroup Sanity',
         Category         => 'vShield-REST-APIs',
         Component        => 'Grouping Objects',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'Sanity test for Securitygroup Create/Update/Delete',
         ExpectedResult   => 'PASS',
         Tags             => 'nsx,CAT',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost,
         WORKLOADS => {
            Sequence => [
               ['CreateSecurityGroup'],
            ],
            ExitSequence => [
               ['DeleteSecurityGroup'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'CreateSecurityGroup' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               securitygroup => {
                  '[1]' => {
                       name => "securgrp_1_$$",
                       description => "security group creation",
                       revision  => "0",
                  },
               },
            },
            'DeleteSecurityGroup' => {
                 Type => 'NSX',
                 TestNSX => "vsm.[1]",
                 deletesecuritygroup => "vsm.[1].securitygroup.[1]",
            },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor for VSFW Firewall TDS
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
      my $self = $class->SUPER::new(\%DistributedFirewallSanity);
      return (bless($self, $class));
}

1;

