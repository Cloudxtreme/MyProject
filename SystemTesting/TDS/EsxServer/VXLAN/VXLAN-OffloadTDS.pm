#!/usr/bin/perl
#########################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::VXLAN::VXLAN-OffloadTDS;

#
# This file contains the structured hash for VXLAN-Offload TDS.
# The following lines explain the keys of the internal
# hash in general.
#
# SAMPLE TOPOLOGY:
#         ________________                            _________________
#        |               |        __________          |                |
#        | VM-A1  VM-A2  |        |         |         | VM-B1   VM-B2  |
#        |               |________| SWITCH  |_________|                |
#        |    HOST-A     |        |_________|         |    HOST-B      |
#        |_______________|                            |________________|
#
#  Topology Description:
# 
#  HOST-A and HOST-B are on the same segment (same L2 wire and same L3 subnet)
#  2 VM's are created per host. VM-A1 and VM-A2 reside on HOST-A, and so on.
#  In FVT Cloud lab, HOST-A (Also known as VTEP-A) and HOST-B (VTEP-B) have ip address from 172.18.0.0/24 subnet
#  All VM's have private ip addresses and VNI-multicast mapping as follows:
#
#  VM-A1 = 25.1.1.1/24   VNI = 2500    239.1.1.25
#  VM-B1 = 25.1.1.2/24   VNI = 2500    239.1.1.25
#
#  VM-A2 = 30.1.1.1/24   VNI = 3000    239.1.1.30
#  VM-B2 = 30.1.1.2/24   VNI = 3000    239.1.1.30
#
#
#  ASSUMPTIONS:
#    1. FVT will be testing only with Skyhawk NIC, which supports VXLAN offloading.
#    2. As of writing this test plan (11/03/2012), FVT has only ONE skyhawk NIC.
#       Hence, we will be using normal Intel NIC on the second host.
#    3. All the test cases assume that VTEP-A has the Skyhawk NIC installed in it.
#
use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   %VXLAN-Offload = (
      'Configuration'   => {
         TestName         => 'Configuration',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether the VSISH CLI to enable/disable VXLAN ',
                              ' Offloading works as intended. '.
         Procedure        => '1. After loading the right build on ESX hosts, verify whether '.
                              ' the VXLAN offloading (both TSO and CKO) can be enabled/disabled.'.
                             '2. Delete the configuration and add it back.  Verify. ' .
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOenabledCKODisabledTCP'   => {
         TestName         => 'TSOenabledCKODisabledTCP',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO is enabled but CKO is disabled for TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable TSO but disable CKO using ethtool.'.
                             '4. Send IPv4 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is enabled, VTEP-A must do inner TCP packet TSO. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Not done. '.
                                 ' Inner IP Checksum = Not done. '.
                                 ' Outer UDP Checksum = Not done. '.
                                 ' Outer IP Checksum = Not done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      'TSOenabledCKODisabledNonTCP'   => {
         TestName         => 'TSOenabledCKODisabledNonTCP',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO is enabled but CKO is disabled for non-TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable TSO but disable CKO using ethtool.'.
                             '4. Send IPv4 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. Though TSO is enabled, VTEP-A must consider it as '.
                                 ' No-operation for non-TCP traffic. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. As CKO is disabled, using "pktcap-uw" tool, verify whether the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Not done. '.
                                 ' Inner IP Checksum = Not done. '.
                                 ' Outer UDP Checksum = Not done. '.
                                 ' Outer IP Checksum = Not done. '.
                              '7. Send different types of IPv4 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1. Observe that the behavior is as per table above. '. 
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOenabledCKOenabledTCP'   => {
         TestName         => 'TSOenabledCKOenabledTCP',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO and CKO are both enabled for TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Send IPv4 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is enabled, VTEP-A must do inner TCP packet TSO. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Done. '.
                                 ' Inner IP Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOenabledCKOenabledNonTCP'   => {
         TestName         => 'TSOenabledCKOenabledNonTCP',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO and CKO are both enabled for non-TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Send IPv4 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. Though TSO is enabled, VTEP-A must consider it as '.
                                 ' No-operation for non-TCP traffic. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Done. '.
                                 ' Inner IP Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
                              '7. Send different types of IPv4 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1. Though CKO enabled, Skyhawk must not '.
                                 ' calculate checksums for non TCP/non UDP packets. '.
                                 ' The net result must be: '.
                                 ' Inner IP Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOdisbledCKOenabledTCP'   => {
         TestName         => 'TSOdisbledCKOenabledTCP',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO is disabled but CKO is enabled for TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. disable TSO but enable CKO using ethtool.'.
                             '4. Send IPv4 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is disabled, VTEP-A must not do TSO. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Done. '.
                                 ' Inner IP Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOdisbledCKOenabledNonTCP'   => {
         TestName         => 'TSOdisbledCKOenabledNonTCP',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO is disabled but CKO is enabled for non-TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. disable TSO but enable CKO using ethtool.'.
                             '4. Send IPv4 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is disabled AND as it is a non-tcp packet, '.
                                 ' VTEP-A must consider it No-operation '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Done. '.
                                 ' Inner IP Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
                              '7. Send different types of IPv4 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1. Though CKO enabled, Skyhawk must not '.
                                 ' calculate checksums for non TCP/non UDP packets. '.
                                 ' The net result must be: '.
                                 ' Inner IP Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOdisbledCKOdisabledTCP'   => {
         TestName         => 'TSOdisbledCKOdisabledTCP',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' both TSO and CKO are disabled for TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. disable both TSO and CKO using ethtool.'.
                             '4. Send IPv4 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is disabled, VTEP-A must not do TSO. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Not Done. '.
                                 ' Inner IP Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOdisbledCKOdisabledNonTCP'   => {
         TestName         => 'TSOdisbledCKOdisabledNonTCP',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' both TSO and CKO are disabled for non-TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. disable both TSO and CKO using ethtool.'.
                             '4. Send IPv4 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is disabled AND as it is a non-tcp packet, '.
                                 ' VTEP-A must consider it No-operation '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Not Done. '.
                                 ' Inner IP Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
                              '7. Send different types of IPv4 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1. As CKO is disabled, Skyhawk must not '.
                                 ' calculate checksums for any packet. '.
                                 ' The net result must be: '.
                                 ' Inner IP Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOenabledCKODisabledTCPIPv6'   => {
         TestName         => 'TSOenabledCKODisabledTCPIPv6',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO is enabled but CKO is disabled for IPv6 TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable TSO but disable CKO using ethtool.'.
                             '4. Send IPv6 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is enabled, VTEP-A must do inner TCP packet TSO. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Not done. '.
                                 ' Inner IPv6 Checksum = Not done. '.
                                 ' Outer UDP Checksum = Not done. '.
                                 ' Outer IP Checksum = Not done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      'TSOenabledCKODisabledNonTCPIPv6'   => {
         TestName         => 'TSOenabledCKODisabledNonTCPIPv6',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO is enabled but CKO is disabled for IPV6 non-TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable TSO but disable CKO using ethtool.'.
                             '4. Send IPv6 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. Though TSO is enabled, VTEP-A must consider it as '.
                                 ' No-operation for non-TCP traffic. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. As CKO is disabled, using "pktcap-uw" tool, verify whether the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Not done. '.
                                 ' Inner IPv6 Checksum = Not done. '.
                                 ' Outer UDP Checksum = Not done. '.
                                 ' Outer IP Checksum = Not done. '.
                              '7. Send different types of IPv6 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1. Observe that the behavior is as per table above. '. 
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOenabledCKOenabledTCPIPv6'   => {
         TestName         => 'TSOenabledCKOenabledTCPIPv6',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO and CKO are both enabled for IPv6 TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Send IPv6 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is enabled, VTEP-A must do inner TCP packet TSO. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Done. '.
                                 ' Inner IPv6 Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOenabledCKOenabledNonTCPIPv6'   => {
         TestName         => 'TSOenabledCKOenabledNonTCPIPv6',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO and CKO are both enabled for IPv6 non-TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Send IPv6 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. Though TSO is enabled, VTEP-A must consider it as '.
                                 ' No-operation for non-TCP traffic. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Done. '.
                                 ' Inner IPv6 Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
                              '7. Send different types of IPv6 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1. Though CKO enabled, Skyhawk must not '.
                                 ' calculate checksums for non TCP/non UDP packets. '.
                                 ' The net result must be: '.
                                 ' Inner IPv6 Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOdisbledCKOenabledTCPIPv6'   => {
         TestName         => 'TSOdisbledCKOenabledTCPIPv6',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO is disabled but CKO is enabled for IPv6 TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. disable TSO but enable CKO using ethtool.'.
                             '4. Send IPv6 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is disabled, VTEP-A must not do TSO. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Done. '.
                                 ' Inner IPv6 Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOdisbledCKOenabledNonTCPIPv6'   => {
         TestName         => 'TSOdisbledCKOenabledNonTCPIPv6',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO is disabled but CKO is enabled for IPv6 non-TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. disable TSO but enable CKO using ethtool.'.
                             '4. Send IPv6 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is disabled AND as it is a non-tcp packet, '.
                                 ' VTEP-A must consider it No-operation '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Done. '.
                                 ' Inner IPv6 Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
                              '7. Send different types of IPv6 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1. Though CKO enabled, Skyhawk must not '.
                                 ' calculate checksums for non TCP/non UDP packets. '.
                                 ' The net result must be: '.
                                 ' Inner IPv6 Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOdisbledCKOdisabledTCPIPv6'   => {
         TestName         => 'TSOdisbledCKOdisabledTCPIPv6',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' both TSO and CKO are disabled for IPv6 TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. disable both TSO and CKO using ethtool.'.
                             '4. Send IPv6 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is disabled, VTEP-A must not do TSO. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Not Done. '.
                                 ' Inner IPv6 Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TSOdisbledCKOdisabledNonTCPIPv6'   => {
         TestName         => 'TSOdisbledCKOdisabledNonTCPIPv6',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' both TSO and CKO are disabled for IPv6 non-TCP traffic. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. disable both TSO and CKO using ethtool.'.
                             '4. Send IPv6 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is disabled AND as it is a non-tcp packet, '.
                                 ' VTEP-A must consider it No-operation '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Not Done. '.
                                 ' Inner IPv6 Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
                              '7. Send different types of IPv6 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1. As CKO is disabled, Skyhawk must not '.
                                 ' calculate checksums for any packet. '.
                                 ' The net result must be: '.
                                 ' Inner IPv6 Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'MultipleIPv6Headers'   => {
         TestName         => 'MultipleIPv6Headers',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when TSO and CKO are both enabled',
                             '  for IPv6 packets having multiple headers. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Create a stream of IPv6 traffic on VM-A1, such that ALL IPv6 headers '.
                                 ' are inserted to the packet.  The last header must be TCP. '.
                             '5. Send this stream from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '6. As TSO is enabled, VTEP-A must do inner TCP packet TSO, '.
                                 ' as the last header is TCP. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                             '7. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Done. '.
                                 ' Inner IPv6 Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
                              '8. Change the packet stream such that the last header is UDP. '.
                                 ' Using pktcap-uw tool, observe that VTEP-A does the following. '.
                                 ' Inner TSO = Not done [Dont care]. '.
                                 ' Inner UDP Checksum = Done. '.
                                 ' Inner IPv6 Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'MisMatchedIPv6Headers'   => {
         TestName         => 'MisMatchedIPv6Headers',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when TSO and CKO are both enabled',
                             '  for IPv6 packets having multiple headers, but in mismatched order. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Create a stream of IPv6 traffic on VM-A1, such that ALL IPv6 headers '.
                                 ' are inserted to the packet.  The second header must be TCP. '.
                             '5. Send this stream from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. As TSO is enabled, VTEP-A must do inner TCP packet TSO, '.
                                 ' as the last header is TCP. '.
                                 ' Use the "pktcap-uw" tool to verify the same.  This tool '.
                                 ' shows whether TSO is done on VTEP-A or not. '.
                              '6. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Done. '.
                                 ' Inner IPv6 Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'JumboFrames'   => {
         TestName         => 'JumboFrames',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' both TSO and CKO are enabled for Jumbo Frames. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Set the MTU on dvs and uplink ports to 9000.
                             '5. Send 8950 size IPv4 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '6. Use the "pktcap-uw" tool to verify that VTEP-A is doing the TSO '.
                                 ' for this traffic stream. '.
                             '7. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Done. '.
                                 ' Inner IP Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
                             '8. Send 8950 size IPv4 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '9. Use the "pktcap-uw" tool to verify that VTEP-A is NOT doing the TSO '.
                                 ' for this traffic stream, as this is a UDP packet '.
                            '10. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Done. '.
                                 ' Inner IP Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
                             '11. Send different types of IPv4 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1, with packet size of 8959 bytes. '.
                                 ' from VM-A1 to VM-B1. Though CKO enabled, Skyhawk must not '.
                                 ' calculate checksums for non TCP/non UDP packets. '.
                                 ' The net result must be: '.
                                 ' Inner IP Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
                             '12. Repeat steps 5 through 7 for packet sizes ranging from '.
                                 ' 1000 bytes to 8000 bytes, in increments of 1000. '.
                             '13. Repeat steps 8 through 10 for packet sizes ranging from '.
                                 ' 1000 bytes to 8000 bytes, in increments of 1000. '.
                             '14. Repeat step 11 for packet sizes ranging from '.
                                 ' 1000 bytes to 8000 bytes, in increments of 1000. '.
                             '15. Irrespective of the packet sizes, the net result must be '.
                                 ' as shown in the respective fields. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'SmallFrames'   => {
         TestName         => 'SmallFrames',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' both TSO and CKO are enabled for frames less than 1000 bytes '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Set the MTU on dvs and uplink ports to 9000.
                             '5. Send 999 size IPv4 TCP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '6. Use the "pktcap-uw" tool to verify that VTEP-A is doing the TSO '.
                                 ' for this traffic stream. '.
                             '7. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner TCP Checksum = Done. '.
                                 ' Inner IP Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
                             '8. Send 999 size IPv4 UDP traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '9. Use the "pktcap-uw" tool to verify that VTEP-A is NOT doing the TSO '.
                                 ' for this traffic stream, as this is a UDP packet '.
                            '10. Also verify using "pktcap-uw" tool that the following '.
                                 ' functions are true: '.
                                 ' Inner UDP Checksum = Done. '.
                                 ' Inner IP Checksum = Done. '.
                                 ' Outer UDP Checksum = Done. '.
                                 ' Outer IP Checksum = Done. '.
                             '11. Send different types of IPv4 packets [like ping, ICMP, IGMP ] '.
                                 ' from VM-A1 to VM-B1, with packet size of 999 bytes. '.
                                 ' from VM-A1 to VM-B1. Though CKO enabled, Skyhawk must not '.
                                 ' calculate checksums for non TCP/non UDP packets. '.
                                 ' The net result must be: '.
                                 ' Inner IP Checksum = Not Done. '.
                                 ' Outer UDP Checksum = Not Done. '.
                                 ' Outer IP Checksum = Not Done. '.
                             '12. Repeat steps 5 through 7 for packet sizes ranging from '.
                                 ' 64 bytes to 900 bytes, in increments of 64. '.
                             '13. Repeat steps 8 through 10 for packet sizes ranging from '.
                                 ' 64 bytes to 900 bytes, in increments of 64. '.
                             '14. Repeat step 11 for packet sizes ranging from '.
                                 ' 64 bytes to 900 bytes, in increments of 64. '.
                             '15. Irrespective of the packet sizes, the net result must be '.
                                 ' as shown in the respective fields. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'VXLANMTEPFunctionality'   => {
         TestName         => 'VXLANMTEPFunctionality',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the VXLANs MTEP functionality when ',
                             ' both TSO and CKO are enabled. '.
         Procedure        => '1. Connect the topology as shown, with a third Host [Host-C] '
                                 ' connected to a different segment. Configure a conroller too. '.
                             '2. Create VNIs as shown on all VTEPs, including VTEP-C. ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Configure the controller such that VTEP-C chooses VTEP-A '.
                                 ' as the MTEP for Host-As segment. '.
                             '5. Send a packet from VTEP-C to VTEP-A, with "replicate locally '.
                                 ' bit set.  When VTEP-A receives this packet, it has to replicate '.
                                 ' the original packet on its local segment. '.
                             '6. Observe that VTEP-B receives a copy of the replicated packet from '.
                                 ' VTEP-A. '.
                             '7. Send different packets [TCP, UDP, IP] from VTEP-C to VTEP-A with RL bit set. '.
                                 ' Observe that VTEP-A properly replicates every packet that it receives. '.
                             '8. Send Jumbo frames from VTEP-C to VTEP-A and observe the same '.
                                 ' functionality on VTEP-A. '.
                             '9. Disable TSO and CKO on VTEP-A using ethtool.  Repeat steps from 5 through 8. '.
                                 ' Irrespective of whether TSO/CKO are enabled or disabled, VTEP-A must '.
                                 ' replicate the packets if RL bit is set. '.
                             '10. Enable TSO/CKO on VTEP-A.  Send a packet from VTEP-A to VTEP-C with RL bit set. '.
                             '11. Using pktcap-uw tool, observe that VTEP-A is doing TSO/CKO for the unicast '.
                                 ' packets sent to VTEP-C. '.
                             '12. Also observe that VTEP-A is doing TSO/CKO for the packets that are multicasted '.
                                 ' on the local segment. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'DisableEnableVXLAN'   => {
         TestName         => 'DisableEnableVXLAN',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the Skyhawk functionality when TSO/CKO are enabled,. '.
                             ' and VXLAN configuration is enabled/disabled. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Send TCP/UDP/IP packets from VM-A1 to VM-B1. '. 
                                ' Observe that VTEP-A does TSO/CKO for relevant pkts. '.
                             '5. Disable VXLAN configuration on VTEP-A, and add them back.'.
                             '6. Repeat step 4.  Observe that TSO/CKO is properly done by VTEP-A. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'AddDeleteUplinks'   => {
         TestName         => 'AddDeleteUplinks',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO and CKO are both enabled and uplinks are added/deleted. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Send different traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. Observe that VTEP-A does TSO/CKO for relevant packets. '.
                             '6. Remove the uplink from the vds on which VXLAN is configured '.
                                 ' and add it back. '.
                             '7. Repeat step 4 and observe that VTEP-A does TSO/CKO for '.
                                 ' relevant packets. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'DisableEnablePNIC'   => {
         TestName         => 'DisableEnablePNIC',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO and CKO are both enabled and PNIC is disabled/enabled. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '4. Send different traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '5. Observe that VTEP-A does TSO/CKO for relevant packets. '.
                             '6. Disable and enable PNIC on VTEP-A. '.
                             '7. Repeat step 4 and observe that VTEP-A does TSO/CKO for '.
                                 ' relevant packets. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'LACPSameNIC'   => {
         TestName         => 'LACPSameNIC',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when ',
                             ' TSO and CKO are both enabled and LACP is enabled.. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Connect the 2nd port of Skyhawk NIC to the same switch, '.
                                ' and configure LACP across both links between host and switch. '.
                             '3. Create VNIs as shown on all VTEPs ' .
                             '4. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '5. Send different traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '6. Observe that VTEP-A does TSO/CKO for relevant packets. '.
                             '7. Bring down one of the LACP members. Skyhawk must do TSO/CKO on  '.
                                 ' the other active link. '.  
                             '8. Bring down LACP logical interface and bring it back up. '.
                                 ' After LACP protocol has converged and the logical interface '.
                                 ' comes back up, observe that VTEP-A continues to do TSO/CKO. '.
                             '9. Disable LACP and renable it back.  TSO/CKO must continue to happen. '.
                            '10. Disable LACP and bring the ports back to standalone mode. '.
                                ' Observe that TSO/CKO happens as usual. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Interop',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'LACPDifferentNIC'   => {
         TestName         => 'LACPDifferentNIC',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when TSO and CKO are both enabled',
                             '  and LACP is configured across two ports on two different Skyhwak NICs. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Install a second Skyhawk NIC to VTEP-A and connect one link to the switch. '.
                                 'Configure LACP across both links between host and switch. '.
                             '3. Create VNIs as shown on all VTEPs ' .
                             '4. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '5. Send different traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '6. Observe that VTEP-A does TSO/CKO for relevant packets. '.
                             '7. Bring down one of the LACP members. Skyhawk must do TSO/CKO on  '.
                                 ' the other active link. Toggle between two member ports. '.  
                             '8. Bring down LACP logical interface and bring it back up. '.
                                 ' After LACP protocol has converged and the logical interface '.
                                 ' comes back up, observe that VTEP-A continues to do TSO/CKO. '.
                             '9. Disable LACP and renable it back.  TSO/CKO must continue to happen. '.
                            '10. Disable LACP and bring the ports back to standalone mode. '.
                                ' Observe that TSO/CKO happens as usual. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Interop',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'LACPMismatchedNIC'   => {
         TestName         => 'LACPMismatchedNIC',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when TSO and CKO are both enabled',
                             '  and LACP is configured across two ports on two different NICs. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Install a second non-Skyhawk NIC to VTEP-A and connect one link to the switch. '.
                                 'Configure LACP across both links between host and switch. '.
                             '3. Create VNIs as shown on all VTEPs ' .
                             '4. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '5. Send different traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '6. Further steps to be written based on actual testing. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Interop',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'vMotion'   => {
         TestName         => 'vMotion',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when TSO and CKO are both enabled',
                             '  and the VM is vMotioned between different hosts. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' 
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '5. Send different traffic from VM-A1 to VM-B1. This traffic '.
                                 ' will be encapsulated in VXLAN header by VTEP-A. '
                             '6. Observe that VTEP-A does proper TSO/CKO for relevant packets.'.
                             '7. Move VM-A1 from VTEP-A to VTEP-B, and back to VTEP-A, while traffic '.
                                 ' is flowing between VM-A1 to VM-B1. '.
                             '8. Observe that VTEP-A continues to do TSO/CKO for relevant packets. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'vMotion',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'Reboot'   => {
         TestName         => 'Reboot',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when TSO and CKO are both enabled',
                             '  and the ESX host is rebooted. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' 
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '5. Send different traffic from VM-A1 to VM-B1 continuously.'.
                                 ' This traffic will be encapsulated in VXLAN header by VTEP-A. '
                             '6. Observe that VTEP-A does proper TSO/CKO for relevant packets.'.
                             '7. Reboot VTEP-A and after it comes back up, observe that it continues to do
                                 ' TSO/CKO for relevant packets. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'vMotion',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'DifferentUDPPort'   => {
         TestName         => 'DifferentUDPPort',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when TSO and CKO are both enabled',
                             '  and the source port for VXLAN header is changed from 8472. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' 
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '5. Send different traffic from VM-A1 to VM-B1 continuously.'.
                                 ' This traffic will be encapsulated in VXLAN header by VTEP-A. '
                             '6. Observe that VTEP-A does proper TSO/CKO for relevant packets.'.
                             '7. On VTEP-A, using net-vdl2 command, change the source port of VXLAN '.
                                 ' header different from 8472. Observe that Skyhawk continues to '.
                                 ' do TSO/CKO for relevant packets, even when different UDP port '.
                                 'numbers are used. '.
                             '8. Change the UDP port number back to 8472 and observe that VTEP-A '.
                                 ' continues to do TSO/CKO. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'vMotion',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'Stress'   => {
         TestName         => 'Stress',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'This test verifies the functionality when TSO and CKO are both enabled',
                             '  under stress scenarios. '.
         Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' 
                             '3. On VTEP-A. enable both TSO and CKO using ethtool.'.
                             '5. Send different traffic from VM-A1 to VM-B1 continuously.'.
                                 ' This traffic will be encapsulated in VXLAN header by VTEP-A. '
                             '6. Observe that VTEP-A does proper TSO/CKO for relevant packets.'.
                             '7. Disable TSO/CKO capabilities on VTEP-A using ethtool in quick. '.
                                 ' successions. Wait for 5 seconds between each disable/enable. '.
                             '8. Observe that VTEP-A continues to do TSO/CKO for relevant packets when '.
                                 ' the capabilities are enabled. '.
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'vMotion',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'jana',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
    );
}

##########################################################################
# new --
#       This is the constructor for VXLAN TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of VXLAN class
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
      my $self = $class->SUPER::new(\%VXLAN);
      return (bless($self, $class));
}

1;
