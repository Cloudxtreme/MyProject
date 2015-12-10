#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::DistributedFirewall::DFWFunctionalTds;

#
# This file contains the structured hash for VSFW firewall TDS.
# The following lines explain the keys of the internal
# hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use TDS::NSX::DistributedFirewall::CommonWorkloads ':AllConstants';
@ISA = qw(TDS::Main::VDNetMainTds);

{
   %DFWFunctional = (
      'RejectL3RuleForTCP'   => {
         TestName         => 'Reject TCP traffic from VM1 to VM2,VM3',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that TCP Traffic is rejected from VM1'.
                             ' to VM2 & 3 and TCP RST pkt is rcvd on VM1',
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
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateUserSection'],
                    ['RejectTCPTrafficFromVM1ToVM2VM3'],
                    ['TCP_TRAFFIC_FAIL_VM1_VM2'],
                    ['TCP_TRAFFIC_FAIL_VM1_VM3'],
                    ],
            ExitSequence => [
                            ['DeleteRules'],
                            ['RemoveUserSection'],
                            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            "RevertToDefaultRules" => REVERT_DEFAULT_RULES,
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
            "CreateUserSection" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               dfwsection      => {
                   '[1]' => {
                       layer => 'layer3',
                       sectionname => 'user-section-1',
                   },
               },
            },
            "RemoveUserSection" => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               deletedfwsection => "vsm.[1].dfwsection.[1]",
            },
            "RejectTCPTrafficFromVM1ToVM2VM3" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule         => {
                  '[1]' => {
                        name    => 'Allow_Test_Ports',
                        action  => 'allow',
                        section => 'vsm.[1].dfwsection.[1]',
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '22,2049,6500',
                                               },
                                            ],
                   },
                  '[2]' => {
                        name    => 'Reject_Traffic',
                        action  => 'reject',
                        section => 'vsm.[1].dfwsection.[1]',
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[2]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[3]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                               },
                                            ],
                  },
               },
            },
            "TCP_TRAFFIC_FAIL_VM1_VM2" => {
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestDuration => "10",
               Type  => "Traffic",
               SleepBetweenCombos => "5",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification => "Verification_1",
               postmortem => "0",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,tcp-rst != 0,dst host ".
                                      "vm.[1].vnic.[1],src host ".
                                      "vm.[2].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "TCP_TRAFFIC_FAIL_VM1_VM3" => {
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestDuration => "10",
               Type  => "Traffic",
               SleepBetweenCombos => "5",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[3].vnic.[1]",
               TestAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification => "Verification_2",
               postmortem => "0",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,tcp-rst != 0,dst host ".
                                      "vm.[1].vnic.[1],src host ".
                                      "vm.[3].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
         },
      },
      'RejectL3RuleForTCPwTCPDeny'   => {
         TestName         => 'Reject IPv4 & v6 TCP traffic to VM2 & VM3',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that TCP Traffic is rejected from VM1'.
                             ' to VM2 & 3 and TCP RST pkt is rcvd on VM1 for '.
                             'both IPv4 and v6',
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
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['RejectTCPTrafficFromVM1ToVM2VM3'],
                    ['TCP_TRAFFIC_FAIL_VM1_VM2_IPv4'],
                    ['TCP_TRAFFIC_FAIL_VM1_VM2_IPv6'],
                    ['TCP_TRAFFIC_FAIL_VM1_VM3_IPv4'],
                    ['TCP_TRAFFIC_FAIL_VM1_VM3_IPv6'],
                    ],
            ExitSequence => [
                            ['DeleteRules'],
                            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            "RevertToDefaultRules" => REVERT_DEFAULT_RULES,
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
            "RejectTCPTrafficFromVM1ToVM2VM3" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                        name    => 'Allow_Test_Ports',
                        action  => 'allow',
                        section => 'default',
                        layer => "layer3",
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '22,2049,6500',
                                               },
                                            ],
                   },
                  '[2]' => {
                        name    => 'Reject_TCP_Traffic',
                        action  => 'reject',
                        section => 'default',
                        layer => "layer3",
                        logging_enabled => "true",
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[2]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[3]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '80,443',
                                               },
                                            ],
                  },
                  '[3]' => {
                        name    => 'Deny_TCP_Traffic',
                        action  => 'deny',
                        section => 'default',
                        layer => "layer3",
                        logging_enabled => "true",
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[2]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[3]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                               },
                                            ],
                  },
               },
            },
            "TCP_TRAFFIC_FAIL_VM1_VM2_IPv4" => {
               L4Protocol   => "tcp",
               ToolName     => "Iperf",
               TestDuration => "10",
               Type        => "Traffic",
               SleepBetweenCombos => "5",
               PortNumber	   => "80",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestAdapter    => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv4",
               postmortem     => "0",
            },
            "TCP_TRAFFIC_FAIL_VM1_VM2_IPv6" => {
               L4Protocol   => "tcp",
               L3Protocol   => "ipv6",
               ToolName     => "Iperf",
               TestDuration => "10",
               Type        => "Traffic",
               SleepBetweenCombos => "5",
               PortNumber	   => "80",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestAdapter    => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv6",
               postmortem     => "0",
            },
            "Verification_IPv4" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,tcp-rst != 0,".
                                      "dst host vm.[1].vnic.[1],".
                                      "src host vm.[2].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "Verification_IPv6" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,tcp-rst != 0,".
                                      "dst host ipv6/vm.[1].vnic.[1],".
                                      "src host ipv6/vm.[2].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "TCP_TRAFFIC_FAIL_VM1_VM3_IPv4" => {
               L4Protocol   => "tcp",
               ToolName     => "Iperf",
               TestDuration => "10",
               Type        => "Traffic",
               SleepBetweenCombos => "5",
               PortNumber	   => "80",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[3].vnic.[1]",
               TestAdapter    => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv4_2",
               postmortem     => "0",
            },
            "TCP_TRAFFIC_FAIL_VM1_VM3_IPv6" => {
               L4Protocol   => "tcp",
               L3Protocol   => "ipv6",
               ToolName     => "Iperf",
               TestDuration => "10",
               Type        => "Traffic",
               SleepBetweenCombos => "5",
               PortNumber	   => "80",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[3].vnic.[1]",
               TestAdapter    => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv6_2",
               postmortem     => "0",
            },
            "Verification_IPv4_2" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,tcp-rst != 0,".
                                      "dst host vm.[1].vnic.[1],".
                                      "src host vm.[3].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "Verification_IPv6_2" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,tcp-rst != 0,".
                                      "dst host ipv6/vm.[1].vnic.[1],".
                                      "src host ipv6/vm.[3].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
         },
      },
      'RejectL3RuleForUDP'   => {
         TestName         => 'Reject UDP traffic from VM1 & 3 to VM2',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that UDP Traffic is rejected from VM1'.
                            '& 3 to VM2 and ICMP un-reach pkt is rcvd on VM1',
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
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateUserSection'],
                    ['RejectUDPTrafficFromVM1VM3ToVM2'],
                    ['UDP_TRAFFIC_FAIL_VM1_VM2'],
                    ['UDP_TRAFFIC_FAIL_VM3_VM2'],
                    ],
            ExitSequence => [
                            ['DeleteRules'],
                            ['RemoveUserSection'],
                            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            "RevertToDefaultRules" => REVERT_DEFAULT_RULES,
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
            "CreateUserSection" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               dfwsection      => {
                   '[1]' => {
                       layer => 'layer3',
                       sectionname => 'user-section-1',
                   },
               },
            },
            "RemoveUserSection" => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               deletedfwsection => "vsm.[1].dfwsection.[1]",
            },
            "RejectUDPTrafficFromVM1VM3ToVM2" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule         => {
                  '[1]' => {
                        name    => 'Allow_Test_Ports',
                        action  => 'allow',
                        section => 'vsm.[1].dfwsection.[1]',
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '22,2049,6500',
                                               },
                                            ],
                   },
                  '[2]' => {
                        name    => 'Reject_Traffic',
                        action  => 'reject',
                        section => 'vsm.[1].dfwsection.[1]',
                        logging_enabled  => 'true',
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[3]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[2]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'UDP',
                                               },
                                            ],
                  },
               },
            },
            "UDP_TRAFFIC_FAIL_VM1_VM2" => {
               L4Protocol     => "udp",
               ToolName => "Iperf",
               TestDuration => "10",
               Type           => "Traffic",
               SleepBetweenCombos => "5",
               NoofOutbound    => "1",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification	=> "Verification_1",
               postmortem => "0",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                   verificationtype => "pktcap",
                   target           => "vm.[1].vnic.[1]",
                   pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                       "icmpcode == 10,".
                                       "dst host vm.[1].vnic.[1],".
                                       "src host vm.[2].vnic.[1]",
                   pktcount         => "1-10",
                   badpkt           => "0",
               },
            },
            "UDP_TRAFFIC_FAIL_VM3_VM2" => {
               L4Protocol     => "udp",
               ToolName => "Iperf",
               TestDuration => "10",
               Type           => "Traffic",
               SleepBetweenCombos => "5",
               NoofOutbound    => "1",
               SupportAdapter  => "vm.[2].vnic.[1]",
               TestAdapter => "vm.[3].vnic.[1]",
               Expectedresult => "FAIL",
               Verification	=> "Verification_2",
               postmortem => "0",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                   verificationtype => "pktcap",
                   target           => "vm.[3].vnic.[1]",
                   pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                       "icmpcode == 10,".
                                       "dst host vm.[3].vnic.[1],".
                                       "src host vm.[2].vnic.[1]",
                   pktcount         => "1-10",
                   badpkt           => "0",
               },
            },
         },
      },
      'RejectL3RuleForUDPwUDPDeny'   => {
         TestName         => 'Reject IPv4 & v6 UDP traffic to VM2 & 3',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that UDP Traffic is rejected from VM1 '.
                             'to VM2 & 3 and ICMP un-reach pkt is rcvd on VM1 '.
                             'for both IPv4 and v6',
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
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['RejectUDPTrafficFromVM1ToVM2VM3'],
                    ['UDP_TRAFFIC_FAIL_VM1_VM2_IPv4'],
                    ['UDP_TRAFFIC_FAIL_VM1_VM2_IPv6'],
                    ['UDP_TRAFFIC_FAIL_VM1_VM3_IPv4'],
                    ['UDP_TRAFFIC_FAIL_VM1_VM3_IPv6'],
                    ],
            ExitSequence => [
                            ['DeleteRules'],
                            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            "RevertToDefaultRules" => REVERT_DEFAULT_RULES,
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
            "RejectUDPTrafficFromVM1ToVM2VM3" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                        name    => 'Allow_Test_Ports',
                        action  => 'allow',
                        section => 'default',
                        layer => "layer3",
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '22,2049,6500',
                                               },
                                            ],
                   },
                  '[2]' => {
                        name    => 'Reject_UDP_Traffic',
                        action  => 'reject',
                        section => 'default',
                        layer => "layer3",
                        logging_enabled => "true",
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[2]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[3]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'UDP',
                                                  destinationport => '24000,24001',
                                               },
                                            ],
                  },
                  '[3]' => {
                        name    => 'Deny_UDP_Traffic',
                        action  => 'deny',
                        section => 'default',
                        layer => "layer3",
                        logging_enabled => "true",
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[2]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[3]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'UDP',
                                               },
                                            ],
                  },
               },
            },
            "UDP_TRAFFIC_FAIL_VM1_VM2_IPv4" => {
               L4Protocol   => "udp",
               ToolName     => "Iperf",
               TestDuration => "10",
               Type        => "Traffic",
               SleepBetweenCombos => "5",
               PortNumber	   => "24000",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestAdapter    => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv4",
               postmortem     => "0",
            },
            "UDP_TRAFFIC_FAIL_VM1_VM2_IPv6" => {
               L4Protocol   => "udp",
               L3Protocol   => "ipv6",
               ToolName     => "Iperf",
               TestDuration => "10",
               Type        => "Traffic",
               SleepBetweenCombos => "5",
               PortNumber	   => "24001",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestAdapter    => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv6",
               postmortem     => "0",
            },
            "Verification_IPv4" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                      "icmpcode == 10,".
                                      "dst host ipv4/vm.[1].vnic.[1],".
                                      "src host ipv4/vm.[2].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "Verification_IPv6" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                      "icmpcode == 10,".
                                      "dst host ipv6/vm.[1].vnic.[1],".
                                      "src host ipv6/vm.[2].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "UDP_TRAFFIC_FAIL_VM1_VM3_IPv4" => {
               L4Protocol   => "udp",
               ToolName     => "Iperf",
               TestDuration => "10",
               Type        => "Traffic",
               SleepBetweenCombos => "5",
               PortNumber	   => "24000",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[3].vnic.[1]",
               TestAdapter    => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv4_2",
               postmortem     => "0",
            },
            "UDP_TRAFFIC_FAIL_VM1_VM3_IPv6" => {
               L4Protocol   => "udp",
               L3Protocol   => "ipv6",
               ToolName     => "Iperf",
               TestDuration => "10",
               Type        => "Traffic",
               SleepBetweenCombos => "5",
               PortNumber	   => "24001",
               NoofOutbound   => "1",
               SupportAdapter => "vm.[3].vnic.[1]",
               TestAdapter    => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv6_2",
               postmortem     => "0",
            },
            "Verification_IPv4_2" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                      "icmpcode == 10,".
                                      "dst host ipv4/vm.[1].vnic.[1],".
                                      "src host ipv4/vm.[3].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "Verification_IPv6_2" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                      "icmpcode == 10,".
                                      "dst host ipv6/vm.[1].vnic.[1],".
                                      "src host ipv6/vm.[3].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
         },
      },
      'RejectL3RuleForICMP'   => {
         TestName         => 'Reject IPv4&v6 ICMP traffic from VM1 & 3 to VM2',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that ICMP Traffic is rejected from VM1'.
                             '& 3 to VM2 and ICMP unreach pkt is rcvd on VM1'.
                             ' for IPv4/6',
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
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateUserSection'],
                    ['RejectICMPTrafficFromVM1VM3ToVM2'],
                    ['ICMPv4_TRAFFIC_FAIL_VM1_VM2'],
                    ['ICMPv6_TRAFFIC_FAIL_VM1_VM2'],
                    ['ICMPv4_TRAFFIC_FAIL_VM3_VM2'],
                    ['ICMPv6_TRAFFIC_FAIL_VM3_VM2'],
                    ],
            ExitSequence => [
                            ['DeleteRules'],
                            ['RemoveUserSection'],
                            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            "RevertToDefaultRules" => REVERT_DEFAULT_RULES,
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
            "CreateUserSection" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               dfwsection      => {
                   '[1]' => {
                       layer => 'layer3',
                       sectionname => 'user-section-1',
                   },
               },
            },
            "RemoveUserSection" => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               deletedfwsection => "vsm.[1].dfwsection.[1]",
            },
            "RejectICMPTrafficFromVM1VM3ToVM2" => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                        name    => 'Allow_Test_Ports',
                        action  => 'allow',
                        section => 'vsm.[1].dfwsection.[1]',
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '22,2049,6500',
                                               },
                                            ],
                   },
                  '[2]' => {
                        name    => 'Reject_ICMPv4_6_Traffic',
                        action  => 'reject',
                        section => 'vsm.[1].dfwsection.[1]',
                        logging_enabled  => 'true',
                        sources => [
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[1]",
                                      },
                                      {
                                         type  => 'VirtualMachine',
                                         value  => "vm.[3]",
                                      },
                                   ],
                        destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[2]",
                                           },
                                        ],
                        affected_service => [
                                               {
                                                  protocolname => 'ICMP',
                                               },
                                               {
                                                  protocolname => 'IPV6ICMP',
                                               },
                                            ],
                  },
               },
            },
            "ICMPv4_TRAFFIC_FAIL_VM1_VM2" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "flood",
               L3Protocol     => "ipv4",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "5",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv4",
               postmortem     => "0",
            },
            "Verification_IPv4" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                      "icmpcode == 10,".
                                      "dst host ipv4/vm.[1].vnic.[1],".
                                      "src host ipv4/vm.[2].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "ICMPv6_TRAFFIC_FAIL_VM1_VM2" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "flood",
               L3Protocol     => "ipv6",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "5",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv6",
               postmortem     => "0",
            },
            "Verification_IPv6" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                      "icmpcode == 10,".
                                      "dst host ipv6/vm.[1].vnic.[1],".
                                      "src host ipv6/vm.[2].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "ICMPv4_TRAFFIC_FAIL_VM3_VM2" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "flood",
               L3Protocol     => "ipv4",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "5",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv4_2",
               postmortem     => "0",
            },
            "Verification_IPv4_2" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                      "icmpcode == 10,".
                                      "dst host ipv4/vm.[3].vnic.[1],".
                                      "src host ipv4/vm.[2].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
            "ICMPv6_TRAFFIC_FAIL_VM3_VM2" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "flood",
               L3Protocol     => "ipv6",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "5",
               Expectedresult => "FAIL",
               Verification   => "Verification_IPv6_2",
               postmortem     => "0",
            },
            "Verification_IPv6_2" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 1,icmptype == icmp-unreach,".
                                      "icmpcode == 10,".
                                      "dst host ipv6/vm.[3].vnic.[1],".
                                      "src host ipv6/vm.[2].vnic.[1]",
                  pktcount         => "1-10",
                  badpkt           => "0",
               },
            },
         },
      },
      'BlockAllTraffic' => {
         TestName         => 'BlockAllTraffic between VMs',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic is blocked based on the IP address in both direction',
         Procedure        => '1. Reset the rules on the host to Default ' .
                             '2. Add the rule to block all the traffic based on the IP addresses'.
                             '3. Send traffic between the IP addresses in both directions' .
                             '4. Verify the traffic does not pass through between the configured IP addresses',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['BlockAllTraffic'],
                    ['Traffic_Ping_Fail'],
                    ['TRAFFIC_TCP_FAIL_VM1_VM2'],
                    ['TRAFFIC_UDP_FAIL_VM3_VM2'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "BlockAllTraffic" => {
               Expectedresult => "PASS",
               Type           => "NSX",
               TestNSX        => "vsm.[1]",
               firewallrule   => {
                  '[1]' => {
                        name    => 'Allow_Test_Ports',
                        layer   => 'Layer3',
                        action  => "allow",
                        section => 'default',
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '22,2049,6500',
                                               },
                                            ],
                   },
                  '[2]' => {
                          name    => "Block_All_Traffic_InBothDir",
                          layer   => 'Layer3',
                          action  => "Deny",
                          logging_enabled  => 'true',
                          section => 'default',
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
                                           value  => "vm.[3]",
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
                                             {
                                                type  => 'VirtualMachine',
                                                value  => "vm.[3]",
                                             },
                                          ],
                  },
               },
            },
            "Traffic_Ping_Fail" => {
              Type           => "Traffic",
              ToolName       => "Ping",
              SleepBetweenCombos => "10",
              NoofInbound    => "2",
              NoofOutbound   => "2",
              TestAdapter    => "vm.[1].vnic.[1]",
              SupportAdapter => "vm.[2-3].vnic.[1]",
              Expectedresult => "FAIL",
            },
            "TRAFFIC_TCP_FAIL_VM1_VM2" => {
               Type           => "Traffic",
               L4Protocol     => "tcp",
               ToolName       => "Iperf",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification    => "Verification_1",
               SleepBetweenCombos => "10",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-10",
                  badpkt           => "0",
               },
            },
            "TRAFFIC_UDP_FAIL_VM3_VM2" => {
               Type           => "Traffic",
               L4Protocol     => "udp",
               ToolName       => "Iperf",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification    => "Verification_2",
               SleepBetweenCombos => "10",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-10",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'BlockAllTrafficVM1andVM2_AllowVM3' => {
         TestName         => 'BlockAllTrafficBetween_VM1andVM2_Allow_VM3',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic is blocked between VM1 and VM2 and allowed from and to VM3',
         Procedure        => '1. Reset the rules on the host to Default '.
                             '2. Add the rule to block all the traffic between VM1 and VM2'.
                             '3. Send traffic between the VM1 and VM2 ipaddresses in both directions' .
                             '4. Verify the traffic does not pass through between VM1 and VM2'.
                             '5. Add rule to allow traffic between to and from VM3'.
                             '6. Verify the traffic is flowing between VM1 and VM3 in both directions',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['BlockAllTraffic_VM1_VM2_Allow_VM3'],
                    ['TRAFFIC_PING_FAIL_VM1_VM2'],
                    ['TRAFFIC_PING_PASS_VM1_VM3'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "BlockAllTraffic_VM1_VM2_Allow_VM3" => {
               Expectedresult => "PASS",
               Type           => "NSX",
               TestNSX        => "vsm.[1]",
               firewallrule  => {
                  '[1]' => {
                        name    => 'Allow_Test_Ports',
                        layer   => 'Layer3',
                        action  => "allow",
                        section => 'default',
                        affected_service => [
                                               {
                                                  protocolname => 'TCP',
                                                  destinationport => '22,2049,6500',
                                               },
                                            ],
                   },
                  '[2]' => {
                         layer   => 'Layer3',
                         name    => "Block_All_Traffic_InBothDir_VM1_VM2",
                         action  => "Deny",
                         logging_enabled  => 'true',
                         sources => [
                                       {
                                          type    => "VirtualMachine",
                                          value   => "vm.[1]",
                                       },
                                       {
                                          type    => "VirtualMachine",
                                          value   => "vm.[2]",
                                       },
                                    ],
                         destinations => [
                                            {
                                               type    => "VirtualMachine",
                                               value   => "vm.[2]",
                                            },
                                            {
                                               type    => "VirtualMachine",
                                               value   => "vm.[1]",
                                            },
                                         ],
                 },
                 '[3]' => {
                        layer   => 'Layer3',
                        logging_enabled  => 'true',
                        name    => "Allow_Traffic_from_VM3",
                        action  => "Allow",
                        sources => [
                                      {
                                         type    => "VirtualMachine",
                                         value   => "vm.[3]",
                                      },
                                   ],
                 },
                 '[4]' => {
                        layer   => 'Layer3',
                        logging_enabled  => 'true',
                        name    => "Allow_Traffic_to_VM3",
                        action  => "Allow",
                        destinations => [
                                           {
                                              type    => "VirtualMachine",
                                              value   => "vm.[3]",
                                           },
                                        ],
                 },
              },
           },
           "TRAFFIC_PING_PASS_VM1_VM3" => {
              Type           => "Traffic",
              ToolName       => "Ping",
              SleepBetweenCombos => "5",
              NoofInbound    => "2",
              RoutingScheme  => "unicast",
              NoofOutbound   => "2",
              TestAdapter    => "vm.[1].vnic.[1]",
              SupportAdapter => "vm.[3].vnic.[1]",
              Expectedresult => "PASS",
           },
           "TRAFFIC_PING_FAIL_VM1_VM2" => {
              Type           => "Traffic",
              ToolName       => "Ping",
              SleepBetweenCombos => "5",
              NoofInbound    => "1",
              RoutingScheme  => "unicast",
              NoofOutbound   => "1",
              TestAdapter    => "vm.[1].vnic.[1]",
              SupportAdapter => "vm.[2].vnic.[1]",
              Expectedresult => "FAIL",
           },
           "DeleteRules" => {
              Type       => 'NSX',
              TestNSX    => "vsm.[1]",
              deletefirewallrule => "vsm.[1].firewallrule.[1-4]",
           },
         },
      },
      'BlockAllTraffic_AllowOnlyBetween_VM1andVM2' => {
         TestName         => 'BlockAllTraffic_AllowOnlyBetween_VM1andVM2',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic is allowed between VM1 and VM2 and all others are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic'.
                             '3. Add rule to allow traffic between VM1 and VM2'.
                             '4. Add rule to allow the the test ports for traffic testing'.
                             '5. Send traffic between the VM1 and VM2 ipaddresses in both directions' .
                             '6. Verify the traffic is flowing between VM1 and VM2 in both directions'.
                             '7. Verify the traffic does not pass through between VM1 and test VM'.
                             '8. Verify the traffic does not pass through between VM2 and test VM'.
                             '9. Verify the traffic does not pass through between VM3 and test VM',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['AllowTraffic_VM1_VM2_VM3'],
                    ['TRAFFIC_TCPAccept_VM1_VM2'],
                    ['TRAFFIC_PING_FAIL_FROMTO_VM1'],
                    ['TRAFFIC_PING_FAIL_FROMTO_VM2'],
                    ['TRAFFIC_PING_FAIL_FROMTO_VM3'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration     => "time in seconds",
            Iterations   => 1,
            "AllowTraffic_VM1_VM2_VM3" => {
               ExpectedResult => "PASS",
               Type	          => "NSX",
               TestNSX	      => "vsm.[1]",
               firewallrule   => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                          ],
                   },
                  '[2]' => {
                          name    => 'Allow_Traffic_OnlyBetween_VM1_VM2',
                          layer   => 'Layer3',
                          action  => 'allow',
                          logging_enabled  => 'true',
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
                                           value  => "vm.[3]",
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
                                             {
                                                type  => 'VirtualMachine',
                                                value => "vm.[3]",
                                             },
                                          ],
                  },
                  '[3]' => {
                          name   => 'Block_To_VM1_VM2_VM3',
                          layer  => 'Layer3',
                          action => 'Deny',
                          logging_enabled => 'true',
                          destinations => [
                                             {
                                                type  => 'Vnic',
                                                value => "vm.[1].vnic.[1]",
                                             },
                                             {
                                                type  => 'Vnic',
                                                value => "vm.[2].vnic.[1]",
                                             },
                                             {
                                                type  => 'Vnic',
                                                value => "vm.[3].vnic.[1]",
                                             },
                                          ],
                   },
                  '[4]' => {
                          name   => 'Block_From_VM1_VM2_VM3',
                          layer  => 'Layer3',
                          action => 'Deny',
                          logging_enabled => 'true',
                          sources => [
                                             {
                                                type  => 'Vnic',
                                                value => "vm.[1].vnic.[1]",
                                             },
                                             {
                                                type  => 'Vnic',
                                                value => "vm.[2].vnic.[1]",
                                             },
                                             {
                                                type  => 'Vnic',
                                                value => "vm.[3].vnic.[1]",
                                             },
                                     ],
                   },
               },
            },
            "TRAFFIC_TCPAccept_VM1_VM2" => {
               Type           => "Traffic",
               L4Protocol     => "tcp",
               ToolName       => "Iperf",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "30",
               Expectedresult => "PASS",
               Verification    => "Verification_1",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_PING_FAIL_FROMTO_VM1" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "TRAFFIC_PING_FAIL_FROMTO_VM2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "TRAFFIC_PING_FAIL_FROMTO_VM3" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "Verification_1" => {
                'PktCapVerificaton' => {
                    verificationtype => "pktcap",
                    target           => "vm.[2].vnic.[1]",
                    pktcapfilter     => "count 1500",
                    pktcount         => "1400+",
                    badpkt           => "0",
                },
             },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-4]",
            },
         },
      },
      'BlockAllTraffic_With_DstIpOfVM3' => {
         TestName         => 'BlockAllTraffic with DestIP of VM3',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic to VM3 IPv4/6 is blocked, but traffic from VM3 is allowed',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic with Dest IP of VM3'.
                             '3. Send traffic from VM1 to VM3 ipaddress'.
                             '4. Verify the traffic does not go through from VM1 and VM3'.
                             '5. Send traffic from VM3 ipaddress to VM1'.
                             '6. Verify the traffic does go out of VM3',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['BlockAllTraffic_To_VM3_IP'],
                    ['TRAFFIC_PING_PASS_FROM_VM3','TRAFFIC_PING_PASS_FROM_VM3_IPv6'],
                    ['TRAFFIC_PING_FAIL_TO_VM3_IPv4'],
                    ['TRAFFIC_PING_FAIL_TO_VM3_IPv6'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "BlockAllTraffic_To_VM3_IP" => {
               ExpectedResult => "PASS",
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                          ],
                   },
                  '[2]' => {
                         layer  => 'Layer3',
                         name   => 'Block_Traffic_To_VM3_Vnic',
                         action => 'Deny',
                         logging_enabled => 'true',
                         destinations => [
                                           {
                                             type => 'Vnic',
                                             value => "vm.[3].vnic.[1]",
                                           },
                                        ],
                  },
               },
            },
            "TRAFFIC_PING_PASS_FROM_VM3" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "PASS",
            },
            "TRAFFIC_PING_PASS_FROM_VM3_IPv6" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               L3Protocol     => 'ipv6',
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "PASS",
            },
            "TRAFFIC_PING_FAIL_TO_VM3_IPv4" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               L3Protocol     => "ipv4",
               RoutingScheme  => "flood",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "TRAFFIC_PING_FAIL_TO_VM3_IPv6" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               L3Protocol     => "ipv6",
               SleepBetweenCombos => "5",
               RoutingScheme  => "flood",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'BlockAllTraffic_WithNegate_DstIpOfVM3' => {
         TestName         => 'BlockAllTraffic with DestIP of VM3 negated',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic except with destination IP of VM3 is blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic except the Dest IP of VM3'.
                             '3. Send traffic from VM1(test VM) to VM3 ipaddress'.
                             '4. Verify the traffic goes through from VM1 and VM3'.
                             '5. Send traffic from VM1(test VM) to VM2 ipaddress'.
                             '6. Verify the traffic does not go through from VM1 and VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['BlockAllTraffic_ExceptTo_VM3_IP'],
                    ['TRAFFIC_PING_PASS_TO_VM3'],
                    ['TRAFFIC_PING_FAIL_TO_VM1_VM2','TRAFFIC_PING_FAIL_FROM_VM3_IPv4'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "BlockAllTraffic_ExceptTo_VM3_IP" => {
               ExpectedResult => "PASS",
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                          ],
                   },
                  '[2]' => {
                         layer  => 'Layer3',
                         name   => 'BlockAllTraffic_ExpectTo_VM3_Vnic',
                         action => 'Deny',
                         logging_enabled => 'true',
                         destinations => [
                                           {
                                             type => 'Vnic',
                                             value => "vm.[3].vnic.[1]",
                                           },
                                        ],
                         destinationnegate => 'true',
                  },
               },
            },
            "TRAFFIC_PING_PASS_TO_VM3" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               Expectedresult => "PASS",
            },
            "TRAFFIC_PING_FAIL_FROM_VM3_IPv4" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               L3Protocol     => "ipv4",
               RoutingScheme  => "flood",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "TRAFFIC_PING_FAIL_TO_VM1_VM2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               L3Protocol     => "ipv4",
               SleepBetweenCombos => "5",
               RoutingScheme  => "flood",
               NoofOutbound   => "1",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "vm.[1-2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'BlockAllTraffic_With_SrcIpOfVM3' => {
         TestName         => 'BlockAllTraffic with SrcIP of VM3',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic is blocked from VM3 IP, but traffic to VM3 is allowed',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic from Src IP of VM3'.
                             '3. Send traffic from VM3 to VM1 ipaddress'.
                             '4. Verify the traffic does not go through from VM3 and VM1'.
                             '5. Send traffic from VM1 ipaddress to VM3'.
                             '6. Verify the traffic does go through from VM1 to VM3'.
                             '7. Send traffic between from VM1 and VM2'.
                             '8. Verify the traffic does go through ',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['BlockAllTraffic_From_VM3_IP'],
                    ['TRAFFIC_PING_FAIL_FROM_VM3'],
                    ['TRAFFIC_PING_PASS_TO_VM3'],
                    ['TRAFFIC_PING_PASS_VM1_VM2'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "BlockAllTraffic_From_VM3_IP" => {
               ExpectedResult	=> "PASS",
               Type		=> "NSX",
               TestNSX		=> "vsm.[1]",
               firewallrule	=> {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                          ],
                   },
                  '[2]'	=> {
                          layer  => 'Layer3',
                          name   => 'Block_Traffic_From_VM3_IP',
                          action => 'Deny',
                          logging_enabled => 'true',
                          sources => [
                                        {
                                           type  => 'Ipv4Address',
                                           value => "vm.[3].vnic.[1]",
                                        },
                                     ],
                  }
               },
            },
            "TRAFFIC_PING_FAIL_FROM_VM3" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "TRAFFIC_PING_PASS_TO_VM3" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "PASS",
            },
            "TRAFFIC_PING_PASS_VM1_VM2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "PASS",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'BlockAllTraffic_WithNegate_SrcIpOfVM3' => {
         TestName         => 'BlockAllTraffic with Source IP of VM3 negated',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic is blocked except those with Source IP of VM3',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic except the Source IP of VM3'.
                             '3. Send traffic from VM3 to VM1(Test VM) ipaddress'.
                             '4. Verify the traffic goes through from VM3 to VM1'.
                             '5. Send traffic from Test VM to VM3 ipaddress'.
                             '6. Verify the traffic does not go through'.
                             '7. Send traffic between VM2 and VM1 ipaddress'.
                             '8. Verify the traffic does not go through',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                     ['BlockAllTraffic_ExceptFrom_VM3_IP'],
                     ['TRAFFIC_PING_PASS_FROM_VM3'],
                     ['TRAFFIC_PING_FAIL_TO_VM3'],
                     ['TRAFFIC_PING_FAIL_VM2_VM1'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "BlockAllTraffic_ExceptFrom_VM3_IP" => {
               ExpectedResult => "PASS",
               Type     => "NSX",
               TestNSX  => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Block_Traffic_ExceptFrom_VM3_IP',
                          action => 'Deny',
                          logging_enabled => 'true',
                          sources => [
                                        {
                                           type  => 'VirtualMachine',
                                           value => "vm.[3]",
                                        },
                                     ],
                          sourcenegate => "true",
                  },
               },
            },
            "TRAFFIC_PING_PASS_FROM_VM3" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "PASS",
            },
            "TRAFFIC_PING_FAIL_TO_VM3" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "TRAFFIC_PING_FAIL_VM2_VM1" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[1].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'AllowTraffic_With_DstIpOfVM3' => {
         TestName         => 'AllowTraffic with DestIP of VM3',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic to VM3 IP is allowed',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow all the traffic with Dest IP of VM3'.
                             '3. Send traffic from VM2 to VM3 ipaddress'.
                             '4. Verify the traffic does go through from VM2 to VM3'.
                             '5. Send traffic from VM3 ipaddress to VM2'.
                             '6. Verify the traffic does go out of VM3',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['AllowTraffic_To_VM3_IP'],
                    ['TRAFFIC_PING_PASS_VM2_VM3'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "AllowTraffic_To_VM3_IP" => {
               ExpectedResult => "PASS",
               Type  => "NSX",
               TestNSX  => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Allow_Traffic_To_VM3_IP',
                          action => 'Allow',
                          logging_enabled => 'true',
                          destinations => [
                                             {
                                                type  => 'Ipv4Address',
                                                value => "vm.[3].vnic.[1]",
                                             },
                                          ],
                  }
               },
            },
            "TRAFFIC_PING_PASS_VM2_VM3" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofOutbound   => "1",
               NoofInbound    => "1",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               Expectedresult => "PASS",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'AllowTraffic_With_SrcIpOfVM3' => {
         TestName         => 'AllowTraffic with Source IP of VM3',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic from VM3 IP is allowed',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow all the traffic from Source IP of VM3'.
                             '3. Send traffic from VM3 to VM2 ipaddress'.
                             '4. Verify the traffic does go through from VM3 to VM2'.
                             '5. Send traffic from VM2 ipaddress to VM3'.
                             '6. Verify the traffic does go out to VM3 IP ',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['AllowTraffic_From_VM3_IP'],
                    ['TRAFFIC_PING_PASS_VM2_VM3'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "AllowTraffic_From_VM3_IP" => {
               ExpectedResult => "PASS",
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                   '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                              ],
                  },
                  '[2]' => {
                         layer  => 'Layer3',
                         name   => 'Allow_Traffic_To_VM3_IP',
                         action => 'Allow',
                         logging_enabled => 'true',
                         sources => [
                                       {
                                          type => 'Ipv4Address',
                                          value => "vm.[3].vnic.[1]",
                                       },
                                    ],
                  }
               },
            },
            "TRAFFIC_PING_PASS_VM2_VM3" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               RoutingScheme  => "unicast",
               NoofOutbound   => "1",
               NoofInbound    => "1",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               Expectedresult => "PASS",
               SleepBetweenCombos => "5",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'Block_TCP_Traffic' => {
         TestName         => 'Block all the TCP traffic',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that All the TCP Traffic is blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the tcp protocol traffic except for the management Controller IPs'.
                             '3. Setup Iperf TCP traffic between a support VM and the test VM (VM1)'.
                             '4. Verify the traffic does not go through',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Block_TCP'],
                    ['TRAFFIC_FAIL_TCP'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Block_TCP" => {
               ExpectedResult => "PASS",
               Type      => "NSX",
               TestNSX   => "vsm.[1]",
               firewallrule	=> {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer   => 'Layer3',
                          name    => 'Block_TCP',
                          action  => 'Deny',
                          logging_enabled  => 'true',
                          sources => [
                                        {
                                           type => 'VirtualMachine',
                                           value => 'vm.[2]',
                                        },
                                        {
                                           type => 'VirtualMachine',
                                           value => 'vm.[3]',
                                        },
                                     ],
                          destinations => [
                                             {
                                                type => 'VirtualMachine',
                                                value => 'vm.[2]',
                                             },
                                             {
                                                type => 'VirtualMachine',
                                                value => 'vm.[3]',
                                             },
                                      ],
                          affected_service => [
                                                 {
                                                    protocolname => "TCP",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_FAIL_TCP" => {
               Type           => "Traffic",
               L4Protocol     => "tcp",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_1",
               SleepBetweenCombos => "20",
            },
            "Verification_1" => {
                   'PktCapVerificaton' => {
                      verificationtype => "pktcap",
                      target           => "vm.[2].vnic.[1]",
                      pktcapfilter     => "count 100",
                      pktcount         => "0-10",
                      badpkt           => "0",
                   },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'Block_UDP_Traffic' => {
         TestName         => 'Block all the UDP traffic',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that All the UDP Traffic is blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the UDP protocol traffic except for the management Controller IPs'.
                             '3. Setup Iperf UDP traffic between a support VM and the test VM (VM1)'.
                             '4. Verify the traffic does not go through',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Block_UDP'],
                    ['TRAFFIC_FAIL_UDP'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Block_UDP" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Block_UDP',
                          action => 'Deny',
                          logging_enabled => 'true',
                          sources => [
                                        {
                                           type => 'VirtualMachine',
                                           value => 'vm.[2]',
                                        },
                                        {
                                           type => 'VirtualMachine',
                                           value => 'vm.[3]',
                                        },
                                     ],
                         destinations => [
                                             {
                                                type => 'VirtualMachine',
                                                value => 'vm.[2]',
                                             },
                                             {
                                                type => 'VirtualMachine',
                                                value => 'vm.[3]',
                                             },
                                      ],
                          affected_service => [
                                                 {
                                                    protocolname => "UDP",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_FAIL_UDP" => {
               Type           => "Traffic",
               L4Protocol     => "udp",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_1",
               SleepBetweenCombos => "10",
            },
            "Verification_1" => {
                   'PktCapVerificaton' => {
                      verificationtype => "pktcap",
                      target           => "vm.[2].vnic.[1]",
                      pktcapfilter     => "count 100",
                      pktcount         => "0-10",
                      badpkt           => "0",
                   },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'Block_ICMP_Traffic' => {
         TestName         => 'Block all the ICMP traffic',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that All the ICMP Traffic is blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the ICMP protocol traffic except for the management Controller IPs'.
                             '3. Send Ping traffic (broadcast & flood) between a support VM and the test VM (VM1)'.
                             '4. Verify the Ping traffic is dropped',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Block_ICMP'],
                    ['TRAFFIC_ICMPDrop'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Block_ICMP" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer => 'Layer3',
                          name => 'Block_ICMP',
                          action => 'Deny',
                          logging_enabled => 'true',
                          sources => [
                                        {
                                           type => 'VirtualMachine',
                                           value => 'vm.[2]',
                                        },
                                        {
                                           type => 'VirtualMachine',
                                           value => 'vm.[3]',
                                        },
                                     ],
                          destinations => [
                                             {
                                                type => 'VirtualMachine',
                                                value => 'vm.[2]',
                                             },
                                             {
                                                type => 'VirtualMachine',
                                                value => 'vm.[3]',
                                             },
                                      ],
                          affected_service => [
                                                 {
                                                    protocolname => "ICMP",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_ICMPDrop" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "flood",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "30",
               Expectedresult => "FAIL",
               SleepBetweenCombos => "5",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'Block_IGMP_Traffic' => {
         TestName         => 'Block all the IGMP traffic',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that All the IGMP multicast Traffic is blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the IGMP protocol traffic'.
                             '3. Setup Iperf multicast traffic between a support VM and the test VM (VM1)'.
                             '4. Verify the traffic does not go through',
         ExpectedResult   => 'FAIL',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Block_IGMP'],
                    ['TRAFFIC_IGMPDrop'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Block_IGMP" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Block_IGMP',
                          action => 'Deny',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "IGMP",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_IGMPDrop" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               NoofInbound    => "1",
               RoutingScheme  => "multicast",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               TestDuration   => "10",
               multicasttimetolive => "32",
               Expectedresult => "IGNORE",
               SleepBetweenCombos  => "20",
             },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'AllowTraffic_With_DstMac' => {
         TestName         => 'Allow all the Traffic to a destination MAC address'.
                              ' and block the dest Mac of other Vnic on same VM',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic is allowed to a given destination MAC address and blocked for others ',
         Procedure        => '1. Reset the rules on the host to Default '.
                             '2. Add the rule to allow all the traffic to the given Dest MAC address'.
                             '3. Add the rule to block the traffic to the second Mac address on the same VM'.
                             '4. Send traffic to the interface with given the Dest MAC'.
                             '5. Verify the traffic does pass through to the Dest MAC'.
                             '6. Send traffic to the second destination MAC interface'.
                             '7. Verify the traffic does NOT pass through to the second Dest MAC',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateMACSet'],
                    ['Allow_Traffic_ToDstMac'],
                    ['TRAFFIC_PING_PASS'],
                    ['TRAFFIC_PING_FAIL'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
                        ['DeleteMACSet'],
            ],
            Duration => "time in seconds",
            Iterations  => 1,
            'CreateMACSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               macset  => {
                  '[1]' => {
                     name => "macset-vm1-vnic1",
                     value => "vm.[1].vnic.[1]",
                     inheritanceallowed  => "false",
                  },
                  '[2]' => {
                     name => "macset-vm3-vnic1",
                     value => "vm.[3].vnic.[1]",
                     inheritanceallowed  => "false",
                  },
               },
            },
            'DeleteMACSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deletemacset => "vsm.[1].macset.[1-2]",
            },
            "Allow_Traffic_ToDstMac" => {
               Expectedresult => "PASS",
               Type           => "NSX",
               TestNSX        => "vsm.[1]",
               firewallrule   => {
                  '[1]' => {
                          layer  => 'Layer2',
                          name   => "Allow_All_Inbound_Traffic_To_Dst_MAC",
                          action => "allow",
                          logging_enabled => 'true',
                          destinations => [
                                             {
                                                type => "MACSet",
                                                value => "vsm.[1].macset.[1]",
                                             },
                                          ],
                  },
                  '[2]' => {
                          layer  => 'Layer2',
                          name   => "Allow_All_Outbound_Traffic_From_Dst_MAC",
                          action => "allow",
                          logging_enabled => 'true',
                          sources => [
                                        {
                                           type => "MACSet",
                                           value => "vsm.[1].macset.[1]",
                                        },
                                     ],
                  },
                  '[3]' => {
                          layer  => 'Layer2',
                          name   => "Block_All_Inbound_Traffic_To_Dst_MAC_2",
                          action => "Deny",
                          logging_enabled => 'true',
                          destinations => [
                                             {
                                                type => "MACSet",
                                                value => "vsm.[1].macset.[2]",
                                             },
                                          ],
                  },
               },
            },
            "TRAFFIC_PING_PASS" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "10",
               RoutingScheme  => "unicast",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "PASS",
            },
            "TRAFFIC_PING_FAIL" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "10",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
         },
      },
      'AllowTraffic_With_SrcMac' => {
         TestName         => 'Allow all the Traffic with a specific Source MAC '.
                             'address and block the other Source Mac address',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic is allowed from a given Src MAC address and blocked for others ',
         Procedure        => '1. Reset the rules on the host to Default '.
                             '2. Add the rule to allow all traffic from Src MAC address of VM1'.
                             '3. Add the rule to block the traffic from the Src MAC address of VM2'.
                             '4. Send traffic to Src MAC of VM1'.
                             '5. Verify the traffic does through between the VM1 and test adapter'.
                             '6. Send traffic to Src MAC of VM2'.
                             '7. Verify the traffic does NOT pass through to VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                        ['CreateMACSet'],
                        ['Allow_Traffic_FromSrcMac'],
                        ['TRAFFIC_PING_PASS'],
                        ['TRAFFIC_PING_FAIL'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
                        ['DeleteMACSet'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'CreateMACSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               macset  => {
                  '[1]' => {
                     name => "macset-vm1-vnic1",
                     value => "vm.[1].vnic.[1]",
                     inheritanceallowed  => "false",
                  },
                  '[2]' => {
                     name => "macset-vm3-vnic1",
                     value => "vm.[3].vnic.[1]",
                     inheritanceallowed  => "false",
                  },
               },
            },
            'DeleteMACSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deletemacset => "vsm.[1].macset.[1-2]",
            },
            "Allow_Traffic_FromSrcMac" => {
               Expectedresult => "PASS",
               Type           => "NSX",
               TestNSX        => "vsm.[1]",
               firewallrule   => {
                  '[1]' => {
                          layer  => 'Layer2',
                          name   => "Allow_All_Outbound_Traffic_From_Src_MAC",
                          action => "allow",
                          logging_enabled => 'true',
                          sources => [
                                        {
                                        type => "MACSet",
                                        value => "vsm.[1].macset.[1]",
                                        },
                                     ],
                  },
                  '[2]' => {
                          layer  => 'Layer2',
                          name   => "Allow_All_Inbound_Traffic_To_Src_MAC",
                          action => "allow",
                          logging_enabled => 'true',
                          destinations => [
                                             {
                                                type => "Vnic",
                                                value => "vm.[1].vnic.[1]",
                                             },
                                          ],
                  },
                  '[3]' => {
                          layer  => 'Layer2',
                          name   => "Block_All_Outbound_Traffic_From_Src_MAC_2",
                          action => "Deny",
                          logging_enabled => 'true',
                          sources => [
                                        {
                                           type => "MACSet",
                                           value => "vsm.[1].macset.[2]",
                                        },
                                     ],
                  },
               },
            },
            "TRAFFIC_PING_PASS" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofInbound    => "2",
               NoofOutbound   => "2",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "PASS",
            },
            "TRAFFIC_PING_FAIL" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
         },
      },
      'BlockTraffic_With_SrcMac' => {
         TestName         => 'Block all the Traffic from a Source MAC address',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic is blocked from a given source MAC address ',
         Procedure        => '1. Reset the rules on the host to Default ' .
                             '2. Add the rule to block all the traffic based on the given Source MAC address'.
                             '3. Send traffic from the interface with the Source MAC' .
                             '4. Verify the traffic does not pass',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateUserSection'],
                    ['Block_Traffic_FromSrcMac'],
                    ['TRAFFIC_PING_FAIL'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
                        ['RemoveUserSection'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "CreateUserSection" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               dfwsection      => {
                   '[1]' => {
                       layer => 'layer2',
                       sectionname => 'user-section-1',
                   },
               },
            },
            "RemoveUserSection" => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               deletedfwsection => "vsm.[1].dfwsection.[1]",
            },
            "Block_Traffic_FromSrcMac" => {
               Expectedresult => "PASS",
               Type           => "NSX",
               TestNSX        => "vsm.[1]",
               firewallrule  => {
                  '[1]' => {
                          layer  => 'Layer2',
                          name   => "Block_All_Traffic_From_Src_MAC",
                          action => "Deny",
                          logging_enabled => 'true',
                          section => 'vsm.[1].dfwsection.[1]',
                          sources => [
                                        {
                                           type => "Vnic",
                                           value => "vm.[3].vnic.[1]",
                                        },
                                     ],
                  },
               },
            },
            "TRAFFIC_PING_FAIL" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "5",
               RoutingScheme  => "unicast",
               NoofOutbound   => "1",
               NoofInbound    => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
         },
      },
      'BlockTraffic_With_DstMac' => {
         TestName         => 'Block all the Traffic to a destination MAC address',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Traffic is blocked to a given destination MAC address ',
         Procedure        => '1. Reset the rules on the host to Default ' .
                             '2. Add the rule to block all the traffic based on the given Dest MAC address'.
                             '3. Send traffic to the interface with the Dest MAC' .
                             '4. Verify the traffic does not pass through to the Dest MAC',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateUserSection'],
                    ['Block_Traffic_ToDstMac'],
                    ['TRAFFIC_PING_FAIL'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
                        ['RemoveUserSection'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "CreateUserSection" => {
               ExpectedResult   => "PASS",
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               dfwsection      => {
                   '[1]' => {
                       layer => 'layer2',
                       sectionname => 'user-section-1',
                   },
               },
            },
            "RemoveUserSection" => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               deletedfwsection => "vsm.[1].dfwsection.[1]",
            },
            "Block_Traffic_ToDstMac" => {
               Expectedresult => "PASS",
               Type           => "NSX",
               TestNSX        => "vsm.[1]",
               firewallrule   => {
                  '[1]' => {
                          layer  => 'Layer2',
                          name   => "Block_All_Traffic_To_Dst_MAC",
                          action => "Deny",
                          logging_enabled => 'true',
                          section => "vsm.[1].dfwsection.[1]",
                          destinations => [
                                             {
                                                type => "Vnic",
                                                value => "vm.[3].vnic.[1]",
                                             },
                                          ],
                  },
               },
            },
            "TRAFFIC_PING_FAIL" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               SleepBetweenCombos => "10",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Expectedresult => "FAIL",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
         },
      },
      'BlockTraffic_With_DstPort_Http' => {
         TestName         => 'BlockAllTraffic with HTTP (TCP:80) as Destination Port',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic with destination port as HTTP is blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic with the Dest Port as HTTP(TCP:80)'.
                             '3. Setup netserver on VM2 and netperf client on VM1'.
                             '4. Send http traffic from client on VM1'.
                             '5. Verify the traffic does not reach the http server on VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Block_Dest_Http_Traffic'],
                    ['TRAFFIC_HTTPDrop'],
                    ['TRAFFIC_HTTPAccept'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Block_Dest_Http_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          layer => 'Layer3',
                          name => 'Block_Dest_HTTP_Port',
                          action => 'Deny',
                          logging_enabled => 'false',
                          affected_service => [
                                                 {
                                                    protocolname => "TCP",
                                                    destinationport => "80",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_HTTPDrop" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "80",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-10",
                  badpkt           => "0",
               },
            },
            "TRAFFIC_HTTPAccept" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "54321",
               ClientPort     => "80",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
         },
      },
      'BlockTraffic_With_SrcPort_Http' => {
         TestName         => 'BlockAllTraffic with HTTP (TCP:80) as Source Port',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic with Source port as HTTP is blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic with the Source Port as HTTP(TCP:80)'.
                             '3. Setup netserver on VM2 and netperf client on VM1'.
                             '4. Send http traffic from client(VM1) on http port'.
                             '5. Verify the traffic does not reach VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Block_Src_Http_Traffic'],
                    ['TRAFFIC_HTTPDrop'],
                    ['TRAFFIC_HTTPAccept'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Block_Src_Http_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          layer => 'Layer3',
                          name => 'Block_Src_HTTP_Port',
                          action => 'Deny',
                          affected_service => [
                                                 {
                                                    protocolname => "TCP",
                                                    sourceport => "80",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_HTTPAccept" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "80",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_HTTPDrop" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "54321",
               ClientPort     => "80",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-10",
                  badpkt           => "0",
               },
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
         },
      },
      'BlockTraffic_With_DstPortList' => {
         TestName         => 'BlockAllTraffic matching List of Dest Ports',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic matching with list of Dest ports are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic with the Dest Port list'.
                             ' of 80,22,21,121,2048,3333,4044,65535,11222,1,43,1449,6789,678,443'.
                             '3. Setup netserver with port 80 on VM2 and netperf client on VM1'.
                             '4. Send traffic to netserver:port 80 from client on VM1'.
                             '5. Verify the traffic does not reach VM2'.
                             '6. Setup netserver with port 65535 on VM2 and netperf client on VM1'.
                             '7. Send traffic to netserver:port 65535 from client on VM1'.
                             '8. Verify the traffic does not reach VM2'.
                             '9. Setup netserver with port 443 on VM2 and netperf client on VM1'.
                             '10. Send traffic to netserver:port 443 from client on VM1'.
                             '11. Verify the traffic does not reach VM2'.
                             '12. Setup netserver with port 10 on VM2 and netperf client on VM1'.
                             '13. Send traffic to netserver:port 10 from client on VM1'.
                             '14. Verify the traffic flows between VM1 and VM2'.
                             '15. Setup netserver with port 444 on VM2 and netperf client on VM1'.
                             '16. Send traffic to netserver:port 444 from client on VM1'.
                             '17. Verify the traffic flows between VM1 and VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Block_DstPort_Traffic'],
                    ['TRAFFIC_Drop_1'],
                    ['TRAFFIC_Drop_2'],
                    ['TRAFFIC_Drop_3'],
                    ['TRAFFIC_Accept_1'],
                    ['TRAFFIC_Accept_2'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Block_DstPort_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          layer => 'Layer3',
                          name  => 'Block_Dst_Port_List',
                          action => 'Deny',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "TCP",
                                                    destinationport => "80,22,21,121,2048,3333,4044,65535,11222,1,43,1449,6789,678,443",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_Accept_1" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "79",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_2" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "444",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Drop_1" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "80",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_2" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "65535",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_3" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "443",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-5",
                  badpkt           => "0",
               },
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[1].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
         },
      },
      'BlockTraffic_With_SrcPortList' => {
         TestName         => 'BlockAllTraffic matching list of Source Ports',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic matching with list of Source ports are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to block all the traffic with the Source Port list'.
                             '80,22,21,121,2048,3333,4044,65535,11222,1,43,1449,6789,678,443'.
                             '3. Setup netserver with port 54321 on VM2 and netperf client on VM1'.
                             '4. Send traffic on port 80 from client on VM1'.
                             '5. Verify the traffic does not reach VM2'.
                             '6. Setup netserver with port 54321 on VM2 and netperf client on VM1'.
                             '7. Send traffic on port 65535 from client on VM1'.
                             '8. Verify the traffic does not reach VM2'.
                             '9. Setup netserver with port 54321 on VM2 and netperf client on VM1'.
                             '10. Send traffic on port 443 from client on VM1'.
                             '11. Verify the traffic does not reach VM2'.
                             '12. Setup netserver with port 54321 on VM2 and netperf client on VM1'.
                             '13. Send traffic on port 79 from client on VM1'.
                             '14. Verify the traffic flows between VM1 and VM2'.
                             '15. Setup netserver with port 54321 on VM2 and netperf client on VM1'.
                             '16. Send traffic on port 444 from client on VM1'.
                             '17. Verify the traffic flows between VM1 and VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Block_SrcPort_Traffic'],
                    ['TRAFFIC_Drop_1'],
                    ['TRAFFIC_Drop_2'],
                    ['TRAFFIC_Drop_3'],
                    ['TRAFFIC_Accept_1'],
                    ['TRAFFIC_Accept_2'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Block_SrcPort_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          layer => 'Layer3',
                          name => 'Block_Src_Port_List',
                          action => 'Deny',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "TCP",
                                                    sourceport => "80,22,21,121,2048,3333,4044,65535,11222,1,43,1449,6789,678,443",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_Accept_1" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "54321",
               ClientPort     => "79",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_2" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "54321",
               ClientPort     => "444",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Drop_1" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "54321",
               ClientPort     => "80",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_2" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "54321",
               ClientPort     => "65535",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_3" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "54321",
               ClientPort     => "443",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-5",
                  badpkt           => "0",
               },
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
         },
      },
      'BlockTraffic_With_SrcPort_Range_List' => {
         TestName         => 'BlockAllTraffic matching a range & list of Source Ports',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic matching with a Range & list of Source ports are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Create a application service with TCP Source ports '.
                                 '(20001-20500),53,135,139,3268,3269,389,445,4464,5722,636,88,9389,5985'.
                             '3. Create rule to block all the traffic with the application service from step(2)'.
                             '4. Setup netserver with port 80 on VM2 and netperf client on VM1'.
                             '5. Send traffic on port 20001 from client on VM1'.
                             '6. Verify the traffic does not reach VM2'.
                             '7. Setup netserver with port 80 on VM2 and netperf client on VM1'.
                             '8. Send traffic on port 20500 from client on VM1'.
                             '9. Verify the traffic does not reach VM2'.
                             '10. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '11. Send traffic on port 53 from client on VM1'.
                             '12. Verify the traffic does not reach VM2'.
                             '13. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '14. Send traffic on port 5985 from client on VM1'.
                             '15. Verify the traffic does not reach VM2'.
                             '16. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '17. Send traffic on port 89 from client on VM1'.
                             '18. Verify the traffic flows between VM1 and VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateApplicationSet'],
                    ['Block_SrcPort_Traffic'],
                    ['TRAFFIC_Drop_1'],
                    ['TRAFFIC_Drop_2'],
                    ['TRAFFIC_Drop_3'],
                    ['TRAFFIC_Drop_4'],
                    ['TRAFFIC_Accept_1'],
            ],
            ExitSequence => [
                    ['DeleteRules'],
                    ['DeleteApplicationSet'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'CreateApplicationSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               applicationservice => {
                  '[1]' => {
                     name    => "appset-srcport-range-list",
                     element => {
                        applicationprotocol => "TCP",
                        sourceport => "20001-20500,53,135,139,3268,3269,389,445,4464,5722,636,88,9389,5985",
                     },
                     description => "mix of source port range & list",
                     inheritanceallowed => "true",
                  },
               },
            },
            'DeleteApplicationSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteapplicationservice => "vsm.[1].applicationservice.[1]",
            },
            "Block_SrcPort_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          layer => 'Layer3',
                          name => 'Block_Src_Port_Range_List',
                          action => 'Deny',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    type => "Application",
                                                    value => "vsm.[1].applicationservice.[1]",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_Accept_1" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "5555",
               ClientPort     => "5986",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Drop_1" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "80",
               ClientPort     => "20001",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_2" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "80",
               ClientPort     => "20500",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_3" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "5555",
               ClientPort     => "53",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_4" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "5555",
               ClientPort     => "5985",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-5",
                  badpkt           => "0",
               },
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
         },
      },
      'BlockTraffic_With_DstPort_Range_List' => {
         TestName         => 'BlockAllTraffic matching a range & list of Dst Ports',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic matching with a Range & list of Dest ports are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Create a application service with TCP Dest ports '.
                                 '53,135,139,3268,3269,389,445,4464,5722,636,88,9389,5985,(20001-20500)'.
                             '3. Create rule to block all the traffic with the application service from step(2)'.
                             '4. Setup netserver with port 53 on VM2 and netperf client on VM1'.
                             '5. Send traffic from client on VM1'.
                             '6. Verify the traffic does not reach VM2'.
                             '7. Setup netserver with port 5985 on VM2 and netperf client on VM1'.
                             '8. Send traffic from client on VM1'.
                             '9. Verify the traffic does not reach VM2'.
                             '10. Setup netserver with port 20001 on VM2 and netperf client on VM1'.
                             '11. Send traffic from client on VM1'.
                             '12. Verify the traffic does not reach VM2'.
                             '13. Setup netserver with port 20500 on VM2 and netperf client on VM1'.
                             '14. Send traffic  from client on VM1'.
                             '15. Verify the traffic does not reach VM2'.
                             '16. Setup netserver with port 20501 on VM2 and netperf client on VM1'.
                             '17. Send traffic from client on VM1'.
                             '18. Verify the traffic flows between VM1 and VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateApplicationSet'],
                    ['Block_DestPort_Traffic'],
                    ['TRAFFIC_Drop_1'],
                    ['TRAFFIC_Drop_2'],
                    ['TRAFFIC_Drop_3'],
                    ['TRAFFIC_Drop_4'],
                    ['TRAFFIC_Accept_1'],
            ],
            ExitSequence => [
                    ['DeleteRules'],
                    ['DeleteApplicationSet'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'CreateApplicationSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               applicationservice => {
                  '[1]' => {
                     name    => "appset-dstport-range-list",
                     element => {
                        applicationprotocol => "TCP",
                        value => "53,135,139,3268,3269,389,445,4464,5722,636,88,9389,5985,20001-20500",
                     },
                     description => "mix of dest port range & list",
                     inheritanceallowed => "true",
                  },
               },
            },
            'DeleteApplicationSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteapplicationservice => "vsm.[1].applicationservice.[1]",
            },
            "Block_DestPort_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          layer => 'Layer3',
                          name => 'Block_Dst_Port_Range_List',
                          action => 'Deny',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    type => "Application",
                                                    value => "vsm.[1].applicationservice.[1]",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_Accept_1" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "20501",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Drop_1" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "53",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_2" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "5985",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_3" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "20001",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_4" => {
               Type           => "Traffic",
               RoutingScheme  => "netperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "20500",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-5",
                  badpkt           => "0",
               },
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1]",
            },
         },
      },
      'AllowIPv6Traffic_With_DstPortList' => {
         TestName         => 'Allow Traffic matching List of Dest Ports',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic matching with list of Dest ports are allowed'.
                             'and others blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow all the traffic with the Dst Port list'.
                             ' of 80,22,21,121,2048,3333,4044,65535,11222,1,43,1449,6789,678,443'.
                             '3. Setup netserver with first port in list on VM2 and netperf client on VM1'.
                             '4. Send traffic to netserver:port from client on VM1'.
                             '5. Verify the traffic flows between VM1 and VM2'.
                             '6. Repeat 3-5 for all ports in list'.
                             '7. Setup netserver with port 555 on VM2 and netperf client on VM1'.
                             '8. Send traffic to netserver:port 555 from client on VM1'.
                             '9. Verify the traffic does not reach VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Allow_DstPort_Traffic'],
                    ['TRAFFIC_Accept_1'],
                    ['TRAFFIC_Accept_2'],
                    ['TRAFFIC_Accept_3'],
                    ['TRAFFIC_Drop_1'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Allow_DstPort_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                                 {
                                                    protocolname => 'UDP',
                                                    destinationport => '67,68',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer => 'Layer3',
                          name  => 'Allow_Dst_Port_List',
                          action => 'Allow',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "UDP",
                                                    destinationport => "80,22,21,121,2048,3333,4044,65535,11222,1,43,1449,6789,678,443",
                                                 },
                                              ],
                  },
                  '[3]' => {
                          layer => 'Layer3',
                          name  => 'Deny_All_UDP',
                          action => 'deny',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "UDP",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_Accept_1" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "udp",
               l3protocol     => "ipv6",
               PortNumber     => "80",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_2" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l3protocol     => "ipv6",
               l4protocol     => "udp",
               PortNumber     => "443",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_3" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "udp",
               l3protocol     => "ipv6",
               PortNumber     => "65535",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Drop_1" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               l3protocol     => "ipv6",
               PortNumber     => "555",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-5",
                  badpkt           => "0",
               },
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
         },
      },
      'AllowIPv6Traffic_With_SrcPortList' => {
         TestName         => 'Allow Traffic matching List of Src Ports(IPv6)',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic matching with list of Src ports are allowed'.
                             'and others blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow all the traffic with the Src Port list'.
                             ' of 80,22,21,121,2048,3333,4044,65535,11222,1,43,1449,6789,678,443'.
                             '3. Setup netserver with port 54321 in list on VM2 and netperf client on VM1'.
                             '4. Send traffic to netserver:port on first port in list from client on VM1'.
                             '5. Verify the traffic flows between VM1 and VM2'.
                             '6. Repeat 3-5 for all ports in list'.
                             '7. Setup netserver with port 54321 on VM2 and netperf client on VM1'.
                             '8. Send traffic to netserver:port on port 555 from client on VM1'.
                             '9. Verify the traffic does not reach VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Allow_SrcPort_Traffic'],
                    ['TRAFFIC_Accept_1'],
                    ['TRAFFIC_Accept_2'],
                    ['TRAFFIC_Accept_3'],
                    ['TRAFFIC_Drop_1'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Allow_SrcPort_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                                 {
                                                    protocolname => 'UDP',
                                                    destinationport => '67,68',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer => 'Layer3',
                          name  => 'Allow_Src_Port_List',
                          action => 'Allow',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "UDP",
                                                    sourceport => "80,22,21,121,2048,3333,4044,65535,11222,1,43,1449,6789,678,443",
                                                 },
                                              ],
                  },
                  '[3]' => {
                          layer => 'Layer3',
                          name  => 'DenyAll',
                          action => 'deny',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "UDP",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_Accept_1" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "udp",
               l3protocol     => "ipv6",
               PortNumber     => "80",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_2" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l3protocol     => "ipv6",
               l4protocol     => "udp",
               PortNumber     => "443",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_3" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[2].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "udp",
               l3protocol     => "ipv6",
               PortNumber     => "65535",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Drop_1" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               l3protocol     => "ipv6",
               PortNumber     => "555",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-5",
                  badpkt           => "0",
               },
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
         },
      },
      'AllowTraffic_With_DstPort_Range_List' => {
         TestName         => 'AllowAllTraffic matching a range & list of Dest Ports',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic matching with a Range of Dest ports are allowed',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow all the traffic with the Dest Port range of '.
                                '10-5000,4000-4100,6001-6100,6201-6300,11000-11499,111,222,333,9000-9100'.
                                ' and block others'.
                             '3. Setup netserver with port 80 on VM2 and netperf client on VM1'.
                             '4. Send traffic to netserver:port 80 from client on VM1'.
                             '5. Verify the traffic flows'.
                             '6. Setup netserver with port 5000 on VM2 and netperf client on VM1'.
                             '7. Send traffic to netserver:port 5000 from client on VM1'.
                             '8. Verify the traffic flows'.
                             '9. Setup netserver with port 4102 on VM2 and netperf client on VM1'.
                             '10. Send traffic to netserver:port 4102 from client on VM1'.
                             '11. Verify the traffic flows'.
                             '12. Setup netserver with port 9100 on VM2 and netperf client on VM1'.
                             '13. Send traffic to netserver:port 9100 from client on VM1'.
                             '14. Verify the traffic flows'.
                             '12. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '13. Send traffic to netserver:port 5555 from client on VM1'.
                             '14. Verify the traffic does not reach VM2'.
                             '15. Setup netserver with port 9999 on VM2 and netperf client on VM1'.
                             '16. Send traffic to netserver:port 9999 from client on VM1'.
                             '17. Verify the traffic does not reach VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateApplicationSet'],
                    ['Allow_DstPort_Traffic'],
                    ['TRAFFIC_Accept_1'],
                    ['TRAFFIC_Accept_2'],
                    ['TRAFFIC_Accept_3'],
                    ['TRAFFIC_Accept_4'],
                    ['TRAFFIC_Drop_1'],
                    ['TRAFFIC_Drop_2'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
                        ['DeleteApplicationSet'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'CreateApplicationSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               applicationservice => {
                  '[1]' => {
                     name    => "appset-dstport-range-list",
                     element => {
                        applicationprotocol => "UDP",
                        value => "10-5000,4000-4100,6001-6100,6201-6300,11000-11499,111,222,333,9000-9100",
                     },
                     description => "mix of dest port range & list",
                     inheritanceallowed => "true",
                  },
               },
            },
            'DeleteApplicationSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteapplicationservice => "vsm.[1].applicationservice.[1]",
            },
            "Allow_DstPort_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Allow_Dst_Port_Range',
                          action => 'Allow',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    type => "Application",
                                                    value => "vsm.[1].applicationservice.[1]",
                                                 },
                                              ],
                  },
                  '[3]' => {
                          layer  => 'Layer3',
                          name   => 'Deny-All-UDP',
                          action => 'deny',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "UDP",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_Accept_1" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "80",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_2" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "5000",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_3" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "4102",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_4" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "9100",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Drop_1" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "5555",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_2" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "9999",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-10",
                  badpkt           => "0",
               },
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
         },
      },
      'AllowTraffic_With_SrcPort_Range_List' => {
         TestName         => 'AllowAllTraffic matching a range & list of Src Ports',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that all the Traffic matching with a Range of Src ports are allowed',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow all the traffic with the Src Port range of '.
                                '10-5000,4000-4100,6001-6100,6201-6300,11000-11499,111,222,333,9000-9100'.
                                ' and block others'.
                             '3. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '4. Send traffic on port 80 from client on VM1'.
                             '5. Verify the traffic flows'.
                             '6. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '7. Send traffic on port 4500 from client on VM1'.
                             '8. Verify the traffic flows'.
                             '9. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '10. Send traffic on port 9000 from client on VM1'.
                             '11. Verify the traffic flows'.
                             '12. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '13. Send traffic on port 9100 from client on VM1'.
                             '14. Verify the traffic flows'.
                             '12. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '13. Send traffic on port 5002 from client on VM1'.
                             '14. Verify the traffic does not reach VM2'.
                             '15. Setup netserver with port 5555 on VM2 and netperf client on VM1'.
                             '16. Send traffic on 9999 from client on VM1'.
                             '17. Verify the traffic does not reach VM2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateApplicationSet'],
                    ['Allow_SrcPort_Traffic'],
                    ['TRAFFIC_Accept_1'],
                    ['TRAFFIC_Accept_2'],
                    ['TRAFFIC_Accept_3'],
                    ['TRAFFIC_Accept_4'],
                    ['TRAFFIC_Drop_1'],
                    ['TRAFFIC_Drop_2'],
            ],
            ExitSequence => [
                        ['DeleteRules'],
                        ['DeleteApplicationSet'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'CreateApplicationSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               applicationservice => {
                  '[1]' => {
                     name    => "appset-srcport-range-list",
                     element => {
                        applicationprotocol => "UDP",
                        sourceport => "10-5000,4000-4100,6001-6100,6201-6300,11000-11499,111,222,333,9000-9100",
                     },
                     description => "mix of src port range & list",
                     inheritanceallowed => "true",
                  },
               },
            },
            'DeleteApplicationSet' => {
               Type => 'NSX',
               TestNSX => "vsm.[1]",
               deleteapplicationservice => "vsm.[1].applicationservice.[1]",
            },
            "Allow_SrcPort_Traffic" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Allow_Src_Port_Range',
                          action => 'Allow',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    type => "Application",
                                                    value => "vsm.[1].applicationservice.[1]",
                                                 },
                                              ],
                  },
                  '[3]' => {
                          layer  => 'Layer3',
                          name   => 'Deny-All-UDP',
                          action => 'deny',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "UDP",
                                                 },
                                              ],
                  },
               },
            },
            "TRAFFIC_Accept_1" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "80",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_2" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "4500",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_3" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "9000",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Accept_4" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "9100",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Accept",
            },
            "TRAFFIC_Drop_1" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "5002",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "TRAFFIC_Drop_2" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[3].vnic.[1]",
               l4protocol     => "udp",
               PortNumber     => "9999",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-10",
                  badpkt           => "0",
               },
            },
            "Verification_Accept" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
         },
      },
      'Allow_OnlyTCP_Traffic_IPv6' => {
         TestName         => 'Allow only the TCP traffic(IPv6)',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that only the TCP Traffic is allowed and others are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow tcp protocol traffic and block others'.
                             '3. Setup Iperf TCP traffic between a support VM and the test VM (VM1)'.
                             '4. Verify the traffic goes through'.
                             '5. Setup Iperf UDP/ICMP traffic between support VM and the test VM'.
                             '6. Verify the traffic does NOT go through',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Allow_Only_TCP'],
                    ['TRAFFIC_TCPAccept'],
                    ['TRAFFIC_UDPDrop'],
                    ['TRAFFIC_ICMPDrop'],
            ],
            ExitSequence => [
                        ['DeleteRule_3'],
                        ['DeleteRule_1_2'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Allow_Only_TCP" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                                 {
                                                    protocolname => 'UDP',
                                                    destinationport => '67,68,69',
                                                 },
                                                 {
                                                    protocolname => "IPV6ICMP",
                                                    subprotocol => '135',
                                                 },
                                                 {
                                                    protocolname => "IPV6ICMP",
                                                    subprotocol => '136',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Allow_Only_TCP',
                          action => 'Allow',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "TCP",
                                                 },
                                              ],
                  },
                  '[3]' => {
                          layer => 'Layer3',
                          logging_enabled => 'true',
                          name => 'Block_Others',
                          action => 'Deny',
                  },
               },
            },
            "TRAFFIC_TCPAccept" => {
               Type           => "Traffic",
               L4Protocol     => "tcp",
               L3Protocol     => "ipv6",
               ToolName       => "Iperf",
               NoofOutbound   => "2",
               NoofInbound    => "2",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_1",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_UDPDrop" => {
               Type           => "Traffic",
               L4Protocol     => "udp",
               L3Protocol     => "ipv6",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_2",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_ICMPDrop" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "flood",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               SleepBetweenCombos => "20",
            },
            "Verification_1" => {
                   'PktCapVerificaton' => {
                      verificationtype => "pktcap",
                      target           => "vm.[2].vnic.[1]",
                      pktcapfilter     => "count 1000",
                      pktcount         => "900+",
                      badpkt           => "0",
                   },
            },
            "Verification_2" => {
                   'PktCapVerificaton' => {
                      verificationtype => "pktcap",
                      target           => "vm.[2].vnic.[1]",
                      pktcapfilter     => "count 100",
                      pktcount         => "0-10",
                      badpkt           => "0",
                   },
            },
            "DeleteRule_3" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[3]",
            },
            "DeleteRule_1_2" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'Allow_OnlyUDP_Traffic_IPv6' => {
         TestName         => 'Allow only the UDP traffic(IPv6)',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that only the UDP Traffic is allowed and others are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow udp protocol traffic and block others'.
                             '3. Setup Iperf UDP traffic between a support VM and the test VM (VM1)'.
                             '4. Verify the traffic goes through'.
                             '5. Setup Iperf TCP/ICMP traffic between support VM and the test VM'.
                             '6. Verify the traffic does NOT go through',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Allow_Only_UDP'],
                    ['TRAFFIC_UDPAccept'],
                    ['TRAFFIC_TCPDrop'],
                    ['TRAFFIC_ICMPDrop'],
            ],
            ExitSequence => [
                        ['DeleteRule_3'],
                        ['DeleteRule_1_2'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Allow_Only_UDP" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                                 {
                                                    protocolname => 'UDP',
                                                    destinationport => '67,68,69',
                                                 },
                                                 {
                                                    protocolname => "IPV6ICMP",
                                                    subprotocol => '135',
                                                 },
                                                 {
                                                    protocolname => "IPV6ICMP",
                                                    subprotocol => '136',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Allow_Only_UDP',
                          action => 'Allow',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "UDP",
                                                 },
                                              ],
                  },
                  '[3]' => {
                          layer => 'Layer3',
                          logging_enabled => 'true',
                          name => 'Block_Others',
                          action => 'Deny',
                  },
               },
            },
            "TRAFFIC_UDPAccept" => {
               Type           => "Traffic",
               L4Protocol     => "udp",
               L3Protocol     => "ipv6",
               ToolName       => "Iperf",
               NoofOutbound   => "2",
               NoofInbound    => "2",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_1",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_TCPDrop" => {
               Type           => "Traffic",
               L4Protocol     => "tcp",
               L3Protocol     => "ipv6",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_2",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_ICMPDrop" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "flood",
               L3Protocol     => 'ipv6',
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               SleepBetweenCombos => "20",
            },
            "Verification_1" => {
                   'PktCapVerificaton' => {
                      verificationtype => "pktcap",
                      target           => "vm.[2].vnic.[1]",
                      pktcapfilter     => "count 1000",
                      pktcount         => "900+",
                      badpkt           => "0",
                   },
            },
            "Verification_2" => {
                   'PktCapVerificaton' => {
                      verificationtype => "pktcap",
                      target           => "vm.[2].vnic.[1]",
                      pktcapfilter     => "count 100",
                      pktcount         => "0-10",
                      badpkt           => "0",
                   },
            },
            "DeleteRule_3" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[3]",
            },
            "DeleteRule_1_2" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'Allow_OnlyICMP_Traffic_IPv6' => {
         TestName         => 'Allow only the ICMP traffic(IPv6)',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that only the ICMPv4/6 Traffic is allowed and others are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow ICMP protocol traffic and block others'.
                             '3. Setup ping (broadcast/flood) traffic between a support VM and the test VM (VM1)'.
                             '4. Verify the traffic goes through'.
                             '5. Setup Iperf TCP,UDP traffic between support VM and the test VM'.
                             '6. Verify the traffic does NOT go through',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Allow_Only_ICMP'],
                    ['TRAFFIC_ICMPAccept'],
                    ['TRAFFIC_TCPDrop'],
                    ['TRAFFIC_UDPDrop'],
            ],
            ExitSequence => [
                        ['DeleteRule_3'],
                        ['DeleteRule_1_2'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Allow_Only_ICMP" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                                 {
                                                    protocolname => 'UDP',
                                                    destinationport => '67,68,69',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Allow_Only_ICMP',
                          action => 'Allow',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "ICMP",
                                                 },
                                                 {
                                                    protocolname => "IPV6ICMP",
                                                    subprotocol => '',
                                                 },
                                              ],
                  },
                  '[3]' => {
                          layer => 'Layer3',
                          logging_enabled => 'true',
                          name => 'Block_Others',
                          action => 'Deny',
                  },
               },
            },
            "TRAFFIC_UDPDrop" => {
               Type           => "Traffic",
               L4Protocol     => "udp",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_1",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_TCPDrop" => {
               Type           => "Traffic",
               L4Protocol     => "tcp",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_1",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_ICMPAccept" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "flood",
               L3Protocol     => 'ipv6',
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "30",
               Expectedresult => "PASS",
               SleepBetweenCombos => "20",
            },
            "Verification_1" => {
                   'PktCapVerificaton' => {
                      verificationtype => "pktcap",
                      target           => "vm.[2].vnic.[1]",
                      pktcapfilter     => "count 100",
                      pktcount         => "0-10",
                      badpkt           => "0",
                   },
            },
            "DeleteRule_3" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[3]",
            },
            "DeleteRule_1_2" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'Allow_OnlyIGMP_Traffic' => {
         TestName         => 'Allow only the IGMP multicast traffic',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that only the IGMP multicast Traffic is allowed and others are blocked',
         Procedure        => '1. Reset the rules on the host to Default'.
                             '2. Add the rule to allow IGMP protocol traffic and block others'.
                             '3. Setup Iperf multicast traffic between a support VM and the test VM (VM1)'.
                             '4. Verify the traffic goes through'.
                             '5. Setup Iperf TCP,UDP & ICMP traffic between support VM and the test VM'.
                             '6. Verify the traffic does NOT go through',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['Allow_Only_IGMP'],
                    ['TRAFFIC_IGMPAccept'],
                    ['TRAFFIC_TCPDrop'],
                    ['TRAFFIC_ICMPDrop'],
                    ['TRAFFIC_UDPDrop'],
            ],
            ExitSequence => [
                        ['DeleteRule_3'],
                        ['DeleteRule_1_2'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            "Allow_Only_IGMP" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                                 {
                                                    protocolname => 'UDP',
                                                    destinationport => '67,68,69',
                                                 },
                                                 {
                                                    protocolname => "IPV6ICMP",
                                                    subprotocol => '135',
                                                 },
                                                 {
                                                    protocolname => "IPV6ICMP",
                                                    subprotocol => '136',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Allow_Only_IGMP',
                          action => 'Allow',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => "IGMP",
                                                 },
                                              ],
                  },
                  '[3]' => {
                          layer => 'Layer3',
                          logging_enabled => 'true',
                          name => 'Block_Others',
                          action => 'Deny',
                  },
               },
            },
            "TRAFFIC_UDPDrop" => {
               Type           => "Traffic",
               L4Protocol     => "udp",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_1",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_TCPDrop" => {
               Type           => "Traffic",
               L4Protocol     => "tcp",
               ToolName       => "Iperf",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_1",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_ICMPDrop" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "unicast",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               SleepBetweenCombos => "20",
            },
            "TRAFFIC_IGMPAccept" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               RoutingScheme  => "multicast",
               NoofInbound    => "1",
               NoofOutbound   => "1",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "20",
               multicasttimetolive => "32",
               Expectedresult => "IGNORE",
               SleepBetweenCombos  => "20",
            },
            "Verification_1" => {
                   'PktCapVerificaton' => {
                      verificationtype => "pktcap",
                      target           => "vm.[2].vnic.[1]",
                      pktcapfilter     => "count 100",
                      pktcount         => "0-10",
                      badpkt           => "0",
                   },
            },
            "DeleteRule_3" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[3]",
            },
            "DeleteRule_1_2" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-2]",
            },
         },
      },
      'VMSecurityGroupMembership' => {
         TestName         => 'Check Rules applied when VM added/removed to/from SG',
         Category         => 'Stateful Firewall',
         Component        => 'vSFW PF',
         Product          => 'vShield',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => 'To verify that Rules are applied correctly when VM added/removed from SG',
         Procedure        => '1. Add VM1 to SG1'.
                             '2. Add a rule to allow http traffic applied on SG1'.
                             ' and block everything else'.
                             '3. Setup HTTP traffic between VM1 and VM2'.
                             '4. Verify the traffic does NOT go through'.
                             '5. Add VM2 to SG1'.
                             '6. Setup Iperf HTTP traffic between VM1 and VM2'.
                             '7. Verify the traffic goes through'.
                             '8. Remove VM2 from SG1'.
                             '9. Setup Iperf HTTP traffic between VM1 and VM2'.
                             '10. Verify the traffic does NOT go through',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         PMT              => '6650',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'svijayan',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2' ,
         TestbedSpec      => COMMON_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                    ['CreateSecurityGroupWithVM1'],
                    ['Allow_Only_HTTP'],
                    ['AddVM2_To_SG'],
                    ['TRAFFIC_HTTPAllow'],
                    ['RemoveVM2_From_SG'],
                    ['TRAFFIC_HTTPDrop'],
            ],
            ExitSequence => [
                    ['DeleteRules'],
                    ['DeleteSecurityGroup'],
            ],
            Duration => "time in seconds",
            Iterations => 1,
            'RemoveVM2_From_SG' => {
               Type       => 'GroupingObject',
               Testgroupingobject => "vsm.[1].securitygroup.[1]",
               updatesecuritygroup => "True",
               member => [
                     {
                        'vm_id' => "vm.[1]",
                        'objecttypename' => "VirtualMachine",
                     },
					],
            },
            'AddVM2_To_SG' => {
               Type       => 'GroupingObject',
               Testgroupingobject => "vsm.[1].securitygroup.[1]",
               updatesecuritygroup => "True",
               member => [
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
            'DeleteSecurityGroup' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletesecuritygroup => "vsm.[1].securitygroup.[1]",
            },
            'CreateSecurityGroupWithVM1' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               securitygroup => {
                  '[1]' => {
                     'name' => "DFW_SG_1",
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
               },
            },
            "Allow_Only_HTTP" => {
               ExpectedResult => "PASS",
               Type => "NSX",
               TestNSX => "vsm.[1]",
               firewallrule => {
                  '[1]' => {
                          name   => 'Allow_Test_Ports',
                          action => 'Allow',
                          layer  => 'layer3',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '22,2049,6500',
                                                 },
                                                 {
                                                    protocolname => 'UDP',
                                                    destinationport => '67,68,69',
                                                 },
                                                 {
                                                    protocolname => "IPV6ICMP",
                                                    subprotocol => '135',
                                                 },
                                                 {
                                                    protocolname => "IPV6ICMP",
                                                    subprotocol => '136',
                                                 },
                                              ],
                  },
                  '[2]' => {
                          layer  => 'Layer3',
                          name   => 'Allow_HTTP_On_SG_1',
                          action => 'Allow',
                          logging_enabled => 'true',
                          affected_service => [
                                                 {
                                                    protocolname => 'TCP',
                                                    destinationport => '80',
                                                 },
                                              ],
                          appliedto => [
                                           {
                                              type  => 'SecurityGroup',
                                              value => "vsm.[1].securitygroup.[1]",
                                           },
                                     ],
                  },
                  '[3]' => {
                          layer => 'Layer3',
                          logging_enabled => 'true',
                          name => 'Block_Others',
                          action => 'Deny',
                  },
               },
            },
            "TRAFFIC_HTTPDrop" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "80",
               TestDuration   => "10",
               Expectedresult => "FAIL",
               Verification   => "Verification_Drop",
            },
            "Verification_Drop" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-10",
                  badpkt           => "0",
               },
            },
            "TRAFFIC_HTTPAllow" => {
               Type           => "Traffic",
               ToolName       => "iperf",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               l4protocol     => "tcp",
               PortNumber     => "80",
               TestDuration   => "20",
               Expectedresult => "PASS",
               Verification   => "Verification_Allow",
            },
            "Verification_Allow" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
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
      my $self = $class->SUPER::new(\%DFWFunctional);
      return (bless($self, $class));
}

1;
