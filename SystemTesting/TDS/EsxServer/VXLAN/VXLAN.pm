#!/usr/bin/perl 
######################################################################### 
# Copyright (C) 2012 VMWare, Inc. 
# # All Rights Reserved 
######################################################################### 
package TDS::EsxServer::VXLAN::VXLANTds; 

# 
# This file contains the structured hash for VXLAN TDS. 
# The following lines explain the keys of the internal 
# hash in general. 
#
# SAMPLE TOPOLOGY:
#		________________													  ________________
#		|								|				__________					|							  |
#   | VM-A1  VM-A2  |				|				  |         | VM-B1   VM-B2 |
#   |               |_______| SWITCH  |_________|    					  |
#		|		 HOST-A		  |				|_________|					|    HOST-B	    |
#		|_______________|						|			 			    |_______________|
#									  						|			
#																|
#												 _______|________        _____________________________
#												|								 |      |												      |
#												|  R O U T E R	 |------|  VXLAN C O N T R O L L E R 	|
#												|________________|      |_____________________________|			
#																|
#																|
#		________________						|							  ________________
#		|								|				____|______					|							  |
#   | VM-C1  VM-C2  |				|				  |         | VM-D1   VM-D2 |
#   |               |_______| SWITCH  |_________|    					  |
#		|		 HOST-C		  |				|_________|					|    HOST-D	    |
#		|_______________|									 			    |_______________|
#									  									
#				
#  Topology Description:
#  
#  HOST-A and HOST-B are on the same segment (same L2 wire and same L3 subnet)
#  HOST-C and HOST-D are on a different segment ( but same L2 wire and same L3 subnet)
#  2 VM's are created per host. VM-A1 and VM-A2 reside on HOST-A, and so on.
#  In FVT Cloud lab, HOST-A (Also known as VTEP-A) and HOST-B (VTEP-B) have ip address from 172.18.0.0/24 subnet
#  HOST-C (VTEP-C) and HOST-D(VTEP-D) have ip address from 172.19.0.0/24 subnet
#  The two segments are connected via a Router (Cisco 6509)
#  All VM's have private ip addresses and VNI-multicast mapping as follows:
#
#  VM-A1 = 25.1.1.1/24   VNI = 2500    239.1.1.25
#  VM-B1 = 25.1.1.2/24   VNI = 2500    239.1.1.25
#  VM-C1 = 25.1.1.3/24   VNI = 2500    239.1.1.25
#  VM-D1 = 25.1.1.4/24   VNI = 2500    239.1.1.25
#
#  VM-A2 = 30.1.1.1/24   VNI = 3000    239.1.1.30
#  VM-B2 = 30.1.1.2/24   VNI = 3000    239.1.1.30
#  VM-C2 = 30.1.1.3/24   VNI = 3000    239.1.1.30
#  VM-D2 = 30.1.1.4/24   VNI = 3000    239.1.1.30
#
#  The VXLAN CONTROLLER is connected to the L3 network and need not be in the same subnet as any VTEP's.
#
#  ASSUMPTIONS: 
#								1. FVT will be testing only single controller scenario in OP (as per the current plan). 
# 								 We do not have plans (currently) to test multi controller scenarios.
#								2. To test scalability scenarios, FVT does not have the required hardware/servers/topologies. 
#								   We will be relying on agent testing mode to create big topologies.
#								3. There is a seperate TDS to test VXLAN Offloading scenarios.  They are not part of this TDS.
#								4. This TDS concerns mainly about data plane forwarding, not control plane (which involves VSM).
#									 The current plan is not to use VSM in data plane testing, so we will be relying on 
#									 Java commands for configuration and debugging purposes.
#								5. This TDS is written as an 'extension' to MN.Next TDS.  It assumes that every test case
#									 written for MN.Next is fully valid in OP too.  Hence, I am not testing scenarios that
#									 are already covered in MN.Next.
# 
use FindBin; 
use lib "$FindBin::Bin/.."; 
use TDS::Main::VDNetMainTds; 
use Data::Dumper; 

@ISA = qw(TDS::Main::VDNetMainTds); 
{
   %VXLAN = (
      'Configuration'   => {
         TestName         => 'Configuration',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify that VXLAN conroller can be configured ' .
                             'on every VTEP ',
				 Procedure        => '1. After loading the right build on ESX hosts, verify whether '.
                              ' the VXLAN controller can be configured using java CLIs '.
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

      'UpdateController'   => {
         TestName         => 'UpdateController',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify that VTEP updates the controller ' .
                             'with its local database ',
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
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

      'ControllerDatabase'   => {
         TestName         => 'ControllerDatabase',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether controller stores information  ' .
                             'about all VTEPs ',
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database on the controller is complete, ' .
                                 'in all respects.  Use larger VNI numbers on VTEPs, ' .
                                 'and larger ip addresses on VMs and verify that ' .
                                 'the controller stores the information in its entirity. ' .
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
      'VTEPDatabaseSync'   => {
         TestName         => 'VTEPdatabaseSync',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether a VTEP successfully gets information '.
         											'about other relevant VTEPs from the controller' .
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs, except VM-B2 ' .
                             		 ' and VM-C1' .
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. The controller must update VTEP-A and VTEP-D about' .
                                 'the presence of all VTEPs' .
                             '6. But VTEP-B must be updated about VTEP-A and VTEP-D only ' .
                                 ' And VTEP-C must be updated about VTEP-A and VTEP-D' .
                             '7. VTEP-B and VTEP-C must not know about each other, ' .
                                 ' as they dont participate in VNI 3000 and 2500 respectively ' .
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
      'VNIDatabaseUpdate'   => {
         TestName         => 'VNIDatabaseUpdate',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether VTEP updates controller when VNI is added/deleted '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs, except VM-B2 ' .
                             		 ' and VM-C1' .
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. The controller must update VTEP-A and VTEP-D about' .
                                 'the presence of all VTEPs' .
                             '6. But VTEP-B must be updated about VTEP-A and VTEP-D only ' .
                                 ' And VTEP-C must be updated about VTEP-A and VTEP-D' .
                             '7. VTEP-B and VTEP-C must not know about each other, ' .
                                 ' as they dont participate in VNI 3000 and 2500 respectively ' .
                             '8. Create VM-B2 and add it to VNI 3000.  The controller ' .
                                 ' must be updated by VTEP-B about this new VNI. ' .
                             '9. The controller must inturn update VTEP-B about the presence ' .
                                 ' of VTEP-C, as VTEP-C participates in VNI 3000 ' .
                             '10. Delete VM-B2 and observe that the delete updates are ' .
                                 ' propogated to relevant VTEPs by the controller ' .
                             '11. Create a new VM (VM-A3) on VTEP-A and add it to VNI 4000' .
                             '12. Verify that the controller is updated with this new VNI info ' .
                             '13. As changing the VNI id dynamically is not allowed, ' .
                                  ' delete VM-A1, recreate it back with VNI id of 5000 '.
                             '14. Verify on the controller and other VTEPs that the old ' .
                                  'information is replaced with the new VNI info. '.
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
      'VTEPPropertyUpdate'   => {
         TestName         => 'VTEPPropertyUpdate',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether controller updates all VTEPs ' .
         											' about change in a VTEPs property '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Configure the controller IP on all VTEPs '.
                             '3. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '4. The controller must update each VTEP about' .
                                 'the presence of all other VTEPs' .
                             '5. Verify the {VM-IP, VM-MAC} table on all hosts ' .
                             '6. Change the ip address of VM-A1, VM-B2, VM-C1 and VM-D2 ' .
                                 'to a different ip address in the same subnet ' .
                             '7. The {VM-IP, VM-MAC} table must be updated by the controller ' .
                                 ' to all hosts ' .
                             '8. Change the MAC addresses of the above VMs. '.
                             '9. The {VM-IP, VM-MAC} table must be updated by the controller ' .
                                 ' to all hosts ' .
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
      'VTEPIPUpdate'   => {
         TestName         => 'VTEPIPUpdate',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether change of vmknic ip of a VTEP is '.
         											'propogated to the controller. ' .
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Configure the controller IP on all VTEPs '.
                             '3. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '4. The controller must update each VTEP about' .
                                 'the presence of all other VTEPs' .
                             '5. The vmknic1 on the host is to be used for vxlan data plane encapsulation, '.
                                 ' and vmknic0 must be used for control traffic ' .
                                 ' to correspond with the controller '.
                             '6. Verify the <VNI-ID, VM-MAC> <--> <VTEP-IP, VTEP-MAC> table on all hosts ' .
                             '7. Change the ip address of VTEP-A to 25.1.1.10, ' .
                                 ' and observe that the controller is updated with the new ip ' .
                             '8. Check the <VNI-ID, VM-MAC> <--> <VTEP-IP, VTEP-MAC> table ' .
                                 ' on all hosts to verify the new ip address ' .
                             '9. Repeat this step on few other VTEPs and verify ' .
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
      'VTEPTrafficUnicast'   => {
         TestName         => 'VTEPTrafficUnicast',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether a VTEP converts the initial ARP request' .
         										 ' from a VM into unicast controller query and subsequently ' .
         										 ' updates its vxlan/arp mapping table '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. From VM-A1, initiate a ping for 25.1.1.4 (VM-D1) '.
                                 ' This ARP request (which is a Broadcast packet) '.
                                 ' reaches the VXLAN module which then checks its '.
                                 ' mapping table to see whether 25.1.1.4 is resolved '.
                                 ' If it is not resolved, VTEP-A will initiate a '.
                                 ' IP-Request connection to the controller and asks '.
                                 ' the controller how to reach 25.1.1.4 '.
                                 ' The controller will then provide VTEP-A with a '.
                                 ' mapping of <25.1.1.4, VM-D1-MAC, VTEP-D-IP> '.
                             '6. VTEP-A will update its VXLAN mapping table and also '.
                                 ' replies back to VM-A1 with VM-D1-MAC address '.
                                 ' This is somewhat similar to proxy-ARP (VTEP itself '.
                                 ' replying to the ARP request ) '.
                                 ' Sample command to get this mapping table is ' .
                                 ' esxcli network vswitch dvs vmware vxlan  network mapping list --vds-name=vds1 --vxlan-id=11 ' .
                             '7. VM-A1 now gets the mac address of 25.1.1.4 and '.
                                 ' construcs a unicast packet with DMAC as VM-D1-MAC '.
                                 ' SMAC = VM-A1-MAC, SIP = 25.1.1.1 and DIP = 25.1.1.4 ' .
                             '8. When VXLAN module receives this packet, it will check the '.
                                 ' <25.1.1.4, VM-D1-MAC, VTEP-D-IP> as mentioned above '.
                                 ' It then determines that to reach 25.1.1.4, it has to reach '.
                                 ' VTEP-D-IP.  Further, it looks up the dvs properties to '.
                                 ' determine the default gateway ip address and its mac address '.
                             '9. VTEP-A then constructs the VXLAN packet (UDP) as below: '.
                                 ' Outer DMAC = Default Gateways mac address ' .
                                 ' Outer SMAC = VMKNIC1s mac address ' .
                                 ' Outer DIP = VTEP-D-IP ' .
                                 ' Outer SIP = VTEP-A-IP ' .
                                 ' Outer IP_TYPE = UDP(17) ' .
                                 ' Outer UDP DP = 8472 ' .
                                 ' Outer UDP SP = 8472 ' .
                                 ' Inner DMAC = VM-D1-MAC ' .
                                 ' Inner SMAC = VM-A1-MAC ' .
                                 ' Inner DIP = 25.1.1.4 ' .
                                 ' Inner SIP = 25.1.1.1 ' .
                             '10. This packet is routed through the network and finally reaches VTEP-D ' .
                             '11. VTEP-D strips off the outer packet and after checking ' .
                                 ' the contents of the inner packet, will deliver the packet ' .
                                 ' to VM-D1 '.
                             '12.  There might be slight delay in ping response till the ARP is resolved ' .
                                 ' Observe that after the ARP is resolved, subsequent pings must ' .
                                 ' succeed without any packet loss. ' .
                             '13. The VTEPs will not keep the IP-MAC mapping of all VMs in the domain. '.
                                 ' They contact the controller only based on need. ' .
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
      'VTEPTrafficUnicastInfoNotPresent'   => {
         TestName         => 'VTEPTrafficUnicastInfoNotPresent',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether a VTEP converts the initial ARP request' .
         										 ' from a VM into multicast packet if the controller '.
         										 ' doesnt know how to reach the destination ip '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. From VM-A1, initiate a ping for any random ip 25.1.1.200 '.
                                 ' This ARP request (which is a Broadcast packet) '.
                                 ' reaches the VXLAN module which then checks its '.
                                 ' mapping table to see whether 25.1.1.200 is resolved '.
                                 ' If it is not resolved, VTEP-A will initiate a '.
                                 ' IP-Request connection to the controller and asks '.
                                 ' the controller how to reach 25.1.1.200 '.
                                 ' The controller in this case doesnt have the info '.
                                 ' to reach 25.1.1.200 '. 
                             '6. The controller will then inform VTEP-A that 25.1.1.200 ' .
                                 ' is not reachable. ' .
                             '7. VTEP-A, upon receiving this non-reachable message from the ' .
                                 ' controller, has two options: Either drop the packet, ' .
                                 ' or to fall back to MN.Next behavior, where it is '.
                                 ' assumed that the undelying network supports IP ' .
                                 ' multicast.  In O/P, the behavior is to fall back to '.
                                 ' MN.Next behavior, rather than dropping the packet ' .
                             '8. The VXLAN module then does a multicast-group lookup for '.
                                 ' VM-A1s VNI. In this case, the MG of VNI 2500 is 239.25.1.1 ' .
                             '9. VTEP-A then constructs the VXLAN packet (UDP) as below: '.
                                 ' Outer DMAC = 01:00:5e:19:01:01 ' .
                                 ' Outer SMAC = VMKNIC1s mac address ' .
                                 ' Outer DIP = 239.25.1.1 ' .
                                 ' Outer SIP = VTEP-A-IP ' .
                                 ' Outer IP_TYPE = UDP(17) ' .
                                 ' Outer UDP DP = 8472 ' .
                                 ' Outer UDP SP = 8472 ' .
                                 ' Inner DMAC = VM-D1-MAC ' .
                                 ' Inner SMAC = VM-A1-MAC ' .
                                 ' Inner DIP = 25.1.1.4 ' .
                                 ' Inner SIP = 25.1.1.1 ' .
                             '10. As the destination 25.1.1.200 is not available on the network' .
                                 ' observe that ping times out on VM-A1 ' .
                             '11. Further, on VTEP-D, create a new VM with ip address 25.1.1.200 ' .
                                 ' and add it VNI 2500 ' .
                             '12. Initiate the ping again from VM-A1 to DIP 25.1.1.200.  ' .
                                 ' VTEP-A must again contact the controller and the steps ' .
                                 ' mentioned in the previous testcase must happen ' .
                                 ' Observe that the multicast packet 239.25.1.1 is NOT sent out ' . 
                                 ' after the VTEP gets the information from controller. '.
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
      'VTEPTrafficUnicastDIPNotreachable'   => {
         TestName         => 'VTEPTrafficUnicastDIPNotreachable',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether a VTEP converts the unicast packet from VM '.
         										 ' to multicast packet, if the DIP becomes unreachable '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. From VM-A1, initiate a continuous IP traffic for 25.1.1.4 (VM-D1) '.
                             '6. VTEP-A knows how to reach VM-D1, via controller. '.
                             '7. With traffic flowing between the two VMs, shutdown VM-D1 abruptly. ' .
                             '8. The controller will be updated by VTEP-D about VM-D1s demise and '. 
                                 'the controller updates all other VTEPs about the same. '.
                             '9. When VTEP-A gets the message from the controller, it removes ' .
                                 ' VM-D1s entry from all its tables. ' .
                             '10. But VM-A1 should continue to send the packet as before ' .
                             '11. VTEP-A no longer knows how to reach the destination IP '.
                                 ' so it again contacts the controller via IP-Request message. ' .
                             '12.  The controller sends a not-reachable message to VTEP-A. ' .
                             '13. VTEP-A must now fall back to MN.Next behavior' .
                                 ' It should encapsulate the inner packet in multicast packet. ' .
                             '14. Observe that every packet generated by VM-A1 is now flooded ' .
                                 ' as multicast packets on vmknic1s network. '.
                             '15. Bring up VM-D1 back again.  After the database exchange has '.
                                 ' happenned, VTEP-A must stop converting VM-A1 traffic into multicast, ' .
                                 ' and inturn unicast them to VTEP-D. ' .
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
      'VTEPTrafficTcpUdp'   => {
         TestName         => 'VTEPTrafficTcpUdp',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether a VTEP converts the unicast packet from VM '.
         										 ' to multicast packet, if the DIP becomes unreachable '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. From VM-A1, send continuous TCP traffic for VM-B1, '.
                                 ' VM-C1 and VM-D1.  Two way communication must happen. '.
                             '6. From VM-A1, try to ping VM-A2 or VM-B2, VM-C2 but it '.
                                 ' should not reachable as they are in different VNIs. '.
                             '7. From VM-A1, send continuous UDP traffic for VM-B1, '.
                                 ' VM-C1 and VM-D1.  The two way communication must happen. '.
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
      'VTEPTrafficIPv6'   => {
         TestName         => 'VTEPTrafficTcpUdp',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether a VTEP converts the unicast packet from VM '.
         										 ' to multicast packet, if the DIP becomes unreachable '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. For this testcase to work, the underlying physical network '.
                                 ' must support ipv6 multicast, as ipv6 unicast depends on '.
                                 ' ipv6 multicast for neighbor discovery '.
                             '6. To test whether ipv6 packets can be encapsulated in vxlan header '.
                                 ' this test case uses Spirent VM. By using Spirent VM, '.
                                 ' any ipv6 stream can be created with pre-configured parameters '.
                                 ' without the need for ND. '.
                             '7. Send ipv6 IP packets from VM-A1 to all other VMs participating '.
                                 ' in the same VNI.  Traffic must reach the destination. '.
                             '8. Send ipv6 TCP packets from VM-A1 to all other VMs participating '.
                                 ' in the same VNI. Two-way communication must occur properly. '.
                             '9. Send ipv6 UDP packets from VM-A1 to all other VMs participating '.
                                 ' in the same VNI. The packets must get through without loss. '.
                             '10. Traffic between VMs belonging to different VNIs must not go through. ' .
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
      'VTEPTrafficBUM'   => {
         TestName         => 'VTEPTrafficBUM',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether a VTEP converts the BUM packets from VM '.
         										 ' to multicast packets, without contacting the controller'.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. From VM-A1, initiate a continuous broadcast IP traffic for 255.255.255.255 '.
                             '6. Observe that VTEP-A converts these packets to 239.25.1.1 MC pkts. '.
                             '7. From VM-A2, initiate a multicast packet stream for MC group ' .
                                 ' 230.1.1.1.  Observe that VTEP-A converts these packets to '.
                                 ' 239.25.1.1 (Mcast in Mcast scenario). '. 
                             '8. From VM-C1, initiate a ping for an unknown unicast ip (30.1.1.155). '.
                             '9. Observe that VTEP-C converts these packets to 239.30.1.1 MC group. ' .
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
      'ControllerDownUp'   => {
         TestName         => 'ControllerDownUp',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether a VTEP clears out all previously '.
         										 ' learnt data when the controller becomes unreachable. '.
         										 ' Also, the VTEP must relearn database from the controller '.
         										 ' once the controller becomes reachable again. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. After the database is synced, shutdown the controller. ' .
                             '6. The default dead time for the controller is 15 seconds. '.
                                 ' Verify that after 15 seconds, all VTEPs show that the controller '.
                                 ' is down. The <VNI, VM_MAC> <--> <VTEP_IP, VTEP_MAC> table ' .
                                 ' must be cleared. '.
                             '7. Verify that the mac table is not cleared as mac aging '.
                                 ' timeout is 5 minutes. '.
                             '8. Verify that the ARP table is not cleared, as arp aging '.
                                 ' timeout is 10 minutes. '.
                             '9. When the controller is not reachable, the VTEP should '.
                                 ' fall back to MN.Next behavior, by falling back to '.
                                 ' Multicast. '.
                             '10. Configure PIM BI-DIR on the router connected to hosts. '.
                                 ' Ping from VM-A1 to VM-C1 should go through, as both '.
                                 ' these VMs belong to the same VNI.  Ping should be '.
                                 ' successful due to multicast encapsulation. '.
                             '11. After few minutes, bring back the controller up. '.
                             '12. Once the controller becomes reachable, all VTEPs must '.
                                 ' update the controller with their local database and '.
                                 ' the controller must inturn re-sync the database to '.
                                 ' relevant VTEPs. '.
                             '13.  After the controller database is synced to all VTEPs, '.
                                 ' the VTEPs must stop using Multicast from VM-VM communication. ' .
                             '14. Send traffic between VMs participating in the same VNI. '.
                                 ' Observe that there are no losses.  But traffic between '.
                                 ' VMs belonging to different VNIs must not go through. ' .
                                 ' Also observe that all traffic is now unicast between '.
                                 ' VTEPs to VTEPs via vxlan unicast packets. '.
                              '15. Use other scenarios to bring down/Up the controller, like '.
                                 ' bringing down vmknic0, removing IP route, isolating parts of '.
                                 ' the underlying network, routing loops, etc. '.
                                 ' After the controller becomes unreachable, AND after the expiration of '.
                                 ' the dead time, verify that all mapping data is cleared. '.
                              '16. Bring up the connection back to the controller.  Verify that '.
                                 ' the database is properly synced across all VTEPs and controller. '.
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
      'ClearCommands'   => {
         TestName         => 'ClearCommands',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the available clear commands on VTEPs '.
         										 ' work as expected'.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Using the clear commands that are available in OP, '.
                                 ' clear the VNI/MAC/ARP databases and observe that '.
                                 ' the mapping tables are cleared and relearnt from '.
                                 ' the controller. '.
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
      'VerifyMTEPTable'   => {
         TestName         => 'VerifyMTEPTable',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the MTEP table on every host'.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. By default, the multicast proxy functionality will be '.
                                 ' enabled on all hosts in OP release. Verify that '.
                                 ' the controller has updated all member VTEPs with every '.
                                 ' other VTEP in the domain. '.
                             '6. Verify that the segment id is the subnet id of the VTEP. '.
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
      'MTEPFuncVTEPUpDown'   => {
         TestName         => 'MTEPFuncVTEPUpDown',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the MTEP table is updated on all hosts '.
         										 ' when a new VTEP is added or deleted to the controller. ' .
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Check the MTEP mapping table on every host to verify whether '.
                                 ' the host has learnt about all other hosts. ' .
                             '6. Shutdown VTEP-D. Observe on all other VTEPs that VTEP-D '.
                                 ' is no longer shown in the MTEP table. '.
                             '7. Bring back VTEP-D. After it comes online, observe that the '.
                                 ' controller updates the MTEP table of all other hosts '.
                                 ' with the right ip address and segment id of VTEP-D. '.
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
      'MTEPFuncTraffic'   => {
         TestName         => 'MTEPFuncTraffic',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether a VTEP chooses only one MTEP ' .
         										 ' per segment and sends traffic to only that MTEP. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Check the MTEP mapping table on every host to verify whether '.
                                 ' the host has learnt about all other hosts. ' .
                             '6. VTEP-A must show that the segment-id "30.0.0.0" has two '.
                             		 ' members, VTEP-C and VTEP-D. It can choose any VTEP '.
                             		 ' as the primary VTEP for that segment.'.
                             		 ' In this case, assume its VTEP-C. '.
                             '7. From VM-A1, ping an unknown ip address (133.133.133.133). As '.
                                 ' VTEP-A gets a not-reachable message from the controller '.
                                 ' for this ip address, it has to encapsulate the ARP request '.
                                 ' for 133.133.133.133 in the corresponding MC group (239.25.1.1). '.
                             '8. In addition to sending this packet out on the local segment, VTEP-A '.
                                 ' must also encapsulate the original VM packet in an vxlan header '.
                                 ' destined for VTEP-C.  The outer DIP address must be VTEP-C ip address. '.
                             '9. Verify that the above unicast vxlan packet has the bit "Replicate Locally" '.
                                 ' set to 1.  This can be verified by mirroring the packet on the router. '.
                            '10. When VTEP-C receives this unicast packet with "Replicat Locally" bit set, '.
                                 ' it should remove the outer header, and then encapsulate the original '.
                                 ' VM-A1 packet in the Multicast Group of VNI 2500 and send it '.
                                 ' out on the local segment. Also, VTEP-C must send the inner '.
                                 ' packet to all VMs participating in that VNI.  In this case, '.
                                 ' the original ARP broadcast must be seen on VM-C1.  Verify by '.
                                 ' using tcpdump on VM-C1. '.
                            '11. Observe that the "replicate locally" bit in this MC packet generated '.
                                 ' by VTEP-C is NOT set. '.
                            '12. Observe that VTEP-D receives this packet too.  Also, VTEP-D  '.
                            		 ' must NOT replicate this packet. '.
                            '13. Generate a multicast packet from VM-A1.  VTEP-A further encapsulates this '.
                                 ' into 239.25.1.1 MC group packet.  Also, it must send a unicast packet '.
                                 ' to VTEP-C. '.
                            '14. VTEP-A must send only one unicast packet per segment.  Observe on VTEP-D '.
                                 ' that it is not receiving any unicast packet from VTEP-A directly. '.
                            '15. From VM-A1, create a packet stream for an unknown unicast mac address '.
                                 ' and ip address, using Spirent VM. This packet will be encapsulated '.
                                 ' in 239.25.1.1 MC group packet, and also a unicast copy sent to VTEP-C. '.
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
      'MTEPPrimaryChange'   => {
         TestName         => 'MTEPPrimaryChange',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether a VTEP chooses a different MTEP '.
         										 ' for a segment when the primary MTEP goes down. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Check the MTEP mapping table on every host to verify whether '.
                                 ' the host has learnt about all other hosts. ' .
                             '6. VTEP-A must show that the segment-id "30.0.0.0" has two '.
                             		 ' members, VTEP-C and VTEP-D. It can choose any VTEP '.
                             		 ' as the primary VTEP for that segment.'.
                             		 ' In this case, assume its VTEP-C. '.
                             '7. From VM-A1, ping an unknown ip address (133.133.133.133). As '.
                                 ' VTEP-A gets a not-reachable message from the controller '.
                                 ' for this ip address, it has to encapsulate the ARP request '.
                                 ' for 133.133.133.133 in the corresponding MC group (239.25.1.1). '.
                             '8. In addition to sending this packet out on the local segment, VTEP-A '.
                                 ' must also encapsulate the original VM packet in an vxlan header '.
                                 ' destined for VTEP-C.  The outer DIP address must be VTEP-C ip address. '.
                             '9. Verify that the above unicast vxlan packet has the bit "Replicate Locally" '.
                                 ' set to 1.  This can be verified by mirroring the packet on the router. '.
                            '10. When VTEP-C receives this unicast packet with "Replicat Locally" bit set, '.
                                 ' it should remove the outer header, and then encapsulate the original '.
                                 ' VM-A1 packet in the Multicast Group of VNI 2500 and send it '.
                                 ' out on the local segment. '.
                            '11. Observe that the "replicate locally" bit in this MC packet generated '.
                                 ' by VTEP-C is NOT set. '.
                            '12. Observe that VTEP-D receives this packet too. '.
                            '13. Shutdown VTEP-C.  Observe that the database sync takes place on all '.
                                 ' hosts, as the controller updates every VTEP. '.
                            '14. VTEP-A must now choose VTEP-D as the primary MTEP for segment "30.0.0.0". '.
                                 ' Send BUM traffic from VM-A1 and verify that VTEP-A now unicasts '.
                                 ' those frames to VTEP-D. '.
                            '15. Bring back VTEP-C up. After the database is synced, VTEP-A must continue '.
                                 ' to keep VTEP-D as the primary MTEP for segment 30.0.0.0, and must not '.
                                 ' move back to VTEP-C unless VTEP-D goes down. '.
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
      'MTEPFuncEmptySegment'   => {
         TestName         => 'MTEPFuncEmptySegment',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the functionality when the last MTEP of a segment '.
            								 ' is brought down. '.
         										 ' RL bit is set, but the outer DIP is not a unicast. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Check the MTEP mapping table on every host to verify whether '.
                                 ' the host has learnt about all other hosts. ' .
                             '6. VTEP-A must show that the segment-id "30.0.0.0" has two '.
                             		 ' members, VTEP-C and VTEP-D. It can choose any VTEP '.
                             		 ' as the primary VTEP for that segment.'.
                             		 ' In this case, assume its VTEP-C. '.
                             '7. Similarly, VTEP-B must also show both VTEP-C and VTEP-D '.
                                 ' as members of segment 30.0.0.0. But, VTEP-B can '.
                                 ' choose VTEP-D as the primary MTEP for this segment. '.
                             '8. Bring down VTEP-C. Observe that VETP-A now shows VTEP-D '.
                                 ' as the MTEP for segment 30.0.0.0. No change in VTEP-B. '. 
                             '9. Bring down VTEP-D. Observe that both VTEP-A and VTEP-B '.
                                 ' remove the whole segment 30.0.0.0 from their database. '.
                            '10. Bring back VTEP-C. Observe that both VTEP-A and VTEP-B '.
                                 ' now show VTEP-C as the lone member of segment 30.0.0.0. '.
                            '11. Bring back VTEP-D. Observe that both VTEP-A and VTEP-B '.
                                 ' continue to keep VTEP-C as the MTEP for segment 30.0.0.0. '.
                            '12. Check the METP mapping table list to verify the above steps. '.
                                 ' esxcli network vswitch dvs vmware vxlan network mtep list --vxlan-id=<VNI> --vds-name=<NAME> '.
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
      'VerifyTimers'   => {
         TestName         => 'VerifyTimers',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the Keepalive and Dead timer values. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the default keepalive time between the VTEPs '.
                                 ' and the controller is 5 seconds.  Capture packets '.
                                 ' on both controller and the hosts to verify the timer. '.
                             '6. Verify that the default dead time is 3 times the keepalive. '.
                                 ' Bring down one of the host and observe that the controller '.
                                 ' doesnt remove it from the database for 15 seconds. '.
                                 ' After 15 seconds, it must inform other VTEPs about '.
                                 ' the demise of the first host. '.
                             '7. Change the keepalive time to very less value and repeat '.
                                 ' the above step. '.
                             '8. Change the keepalive time to very high value and repeat '.
                                 ' the above step. '.
                             '9. When a host goes down and comes back up within 15 seconds, '.
                                 ' the controller must continue to retain the information. '.
                                 ' This scenario can be tested effectively by creating an '.
                                 ' access-list on the Cisco router, such that the controller '.
                                 ' loses connectivity with VTEP-A.  Wait for about 12 seconds '.
                                 ' so that the controller misses 2 keepalives from VTEP-A. '.
                                 ' Remove the access-list from the router, and VTEP-A must '.
                                 ' now be able to talk with the controller.  The controller '.
                                 ' must continue to keep the database intact, as VTEP-A '.
                                 ' came back up within the dead time. '.
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
      'ConfigOrder'   => {
         TestName         => 'ConfigOrder',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the order of configuration of VTEP '. 
         										 ' and controller does not affect the way database is exchanged. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Do NOT bring up the controller.  Let it be shutdown. '.
                             '4. Configure the controller IP on all VTEPs. '.
                             '5. The VTEPs try to reach the controller, but as it is '.
                                 ' shutdown, they must time out. But they must keep '.
                                 ' trying to reach the controller every 5 seconds. '.
                             '6. Bring up the controller. As soon as it becomes fully '.
                                 ' operational, all VTEPs must be able to establish '.
                                 ' proper tcp connections and exchange database. '.
                             '7. Change the controller ip on VTEP-A to a different, '.
                                 ' but unreachable ip address. It must reset the connection '.
                                 ' with the existing controller and try to establish connection '.
                                 ' with the new ip address.  Observe that the existing controller '.
                                 ' updates all other VTEPs about the absence of VTEP-A. '.
                             '8. Change the controller ip on VTEP-A back to the working controller. '.
                                 ' Observe that it is able to establish connection and exchange database '.
                                 ' information. '.
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
      'Reboot'   => {
         TestName         => 'Reboot',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the functionality after the VTEP and '.
         										 ' the controller are rebooted. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. After the database sync has happened, reboot VTEP-A '.
                             '6. When VTEP-A is rebooting, the controller must update all '.
                                 ' other hosts about its loss, after the dead time expires. '. 
                                 ' Verify on other hosts that they have removed VTEP-A from '.
                                 ' their database. '.
                             '7. After VTEP-A comes back up online, verify that it updates '.
                                 ' the controller with its local database and the controller '.
                                 ' in turn updates all other relevant hots. '.
                             '8. Verify by sending traffic from VM-A1 to VM-C1.  There must be no loss. '.
                             '9. Reboot the controller. After the dead time expires, all VTEPs '.
                                 ' in the domain must clear the database and mapping tables. '.
                            '10. Send traffic from VM-A1 to VM-C1. The behavior must be similar '.
                                 ' to MN.Next, where every packet is encapsulated in relevant '.
                                 ' multicast group (239.25.1.1). '.
                            '11. After the controller reboots and comes back online, all VTEPs '.
                                 ' must now be able to establish connection with it and exchange '.
                                 ' proper databases. '.
                            '12. Verify by sending traffic from VM-A1 to VM-C1.  The traffic must '.
                                 ' now be unicasted to VTEP-C by VTEP-A. '.
                            '13. Shutdown/bring up the vCenter that is used to manage the hosts.  There must '.
                                 ' be no disruption to traffic flow in the vxlan domain. '.
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
      'CablePullPush'   => {
         TestName         => 'CablePullPush',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the functionality after the physical cable is '. 
         										 ' pulled out and pushed back from VTEPs and controller'.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. After the database sync has happened, pull out the '.
                                 ' physical cable from VTEP-A so that it is out of reach. '.
                             '6. When VTEP-A is out of reach, the controller must update all '.
                                 ' other hosts about its loss, after the dead time expires. '. 
                                 ' Verify on other hosts that they have removed VTEP-A from '.
                                 ' their database. '.
                             '7. Reconnect the cable back to VTEP-A.  After it becomes reachable, '.
                             		 ' verify that it updates the controller with its local database '.
                                 ' and the controller in turn updates all other relevant hots. '.
                             '8. Verify by sending traffic from VM-A1 to VM-C1.  There must be no loss. '.
                             '9. Disconnect the physical cable from the controller. After the dead time '.
                                 ' expires, all VTEPs must clear the database and mapping tables. '.
                            '10. Send traffic from VM-A1 to VM-C1. The behavior must be similar '.
                                 ' to MN.Next, where every packet is encapsulated in relevant '.
                                 ' multicast group (239.25.1.1). '.
                            '11. Reconnect the cable back to the controller. After the controller becomes, '.
                                 ' reachable, all VTEPs must now be able to establish connection with it '.
                                 ' and exchange proper databases. '.
                            '12. Verify by sending traffic from VM-A1 to VM-C1.  The traffic must '.
                                 ' now be unicasted to VTEP-C by VTEP-A. '.
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
      'vMotion'   => {
         TestName         => 'vMotion',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether the controller updates all VTEPs when a VM '.
                              'is vmotioned from one VTEP to another. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that all VTEPs know about all other VTEPs, as the same. ' .
                                 ' VNI exists on all of them. '.
                             '6. Send traffic from VM-A1 to VM-C1. VTEP-A must directly unicast '.
                                 ' this traffic to VTEP-C. '.
                             '7. While traffic flowing, move VM-A1 from VTEP-A to VTEP-B. '.
                             '8. Observe that VTEP-A sends a message to the controller about loss '.
                                 ' of VM-A1.  Simultaneously, VTEP-B must update the controller '.
                                 ' about the addition of VM-A1. The controller must update this '.
                                 ' change to all other VTEPs. The traffic from VM-A1 to VM-C1 must '.
                                 ' continue to flow unhindered. But this time, its VTEP-B which '.
                                 ' would unicast the packets to VTEP-C. '.
                             '9. Move VM-A1 back to VTEP-A.  Observe that the controller/VTEP database '.
                                 ' is synced once again and traffic flow is successful. '.
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
      'LogMessages'   => {
         TestName         => 'LogMessages',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether proper log messages are generated whenever '.
         										 ' a VTEP establishes or loses connection with the controller. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs ' .
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify the log messages in /var/log directory.  Proper log '.
                                 ' messages must be generated by relevant modules. '.
                             '6. Verify whether proper, readable log messages are generated '.
                                 ' when any event such as controller going down, VTEP going down, '.
                                 ' dead time expired, etc, happens. '.
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
      'StressControllerUpDown'   => {
         TestName         => 'StressControllerUpDown',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the controller is able to establish proper connections '.
         											' with all VTEPS simultaneously, when it is brought down and back up again. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. After the database is synced, shutdown the controller. ' .
                             '6. After the VTEPs detect that the controller is down, bring it '.
                                 ' back up again. '.
                             '7. When the controller comes back online, it has to start simultaneous '.
                                 ' tcp connections with all the VTEPs. Observe that it is able '.
                                 ' to properly establish connections and exchange database. '.
                             '8. Repeat this process seveal times to verify the behavior of controller '.
                                 ' in stress scenarios. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Stress',
				 TestcaseType     => 'Stress',
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
      'StressVNIAddDelete'   => {
         TestName         => 'StressVNIAddDelete',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the controller updates all VTEPs instantaneously, '.
         									   ' when a VNI on the VTEP is continuously deleted and added back. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. On VTEP-A, delete VM-A1s corresponding VNI data.  Observe that '.
                                 ' VTEP-A updates the controller and the controller in turn updates '.
                                 ' all other VTEPs. '.
                             '7. Add the VNI corresponding to VM-A1 back to VTEP.  Verify the database sync. '.
                             '8. Repeat this process in quick successions on multiple VTEPs.  Observe that '.
                                 ' the controller is able to properly update the database to all VTEPs. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Stress',
				 TestcaseType     => 'Stress',
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
      'StressVMotion'   => {
         TestName         => 'StressVMotion',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the controller updates all VTEPs instantaneously, '.
         									   ' when a VM is moved back and forth between hosts. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. VMotion VM-A1 from VTEP-A to VTEP-B.  Observe that VTEP-A and '.
                                 ' VTEP-B updates the controller and the controller in turn updates '.
                                 ' all other VTEPs. '.
                             '7. Move VM-A1 back to VTEP-A. Verify the database sync. '.
                             '8. Repeat this process in quick successions on multiple VTEPs.  Observe that '.
                                 ' the controller is able to properly update the database to all VTEPs. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Stress',
				 TestcaseType     => 'Stress',
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
      'StressVMIpMacChange'   => {
         TestName         => 'StressVMIpMacChange',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the controller updates all VTEPs instantaneously, '.
         									   ' when the ip address and mac address of a VM is changed continuously. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. Change the ip address of VM-A1 to 25.1.1.100.  Observe that VTEP-A '.
                                 ' updates the controller and the controller in turn updates '.
                                 ' all other VTEPs. '.
                             '7. Change the ip address of VM-A1 back to 25.1.1.1. Verify the database sync. '.
                             '8. Repeat this process in quick successions multiple times.  Observe that '.
                                 ' the controller is able to properly update the database to all VTEPs. '.
                             '9. Change the mac address of VM-B1.  Observe that VTEP-B '.
                                 ' updates the controller and the controller in turn updates '.
                                 ' all other VTEPs. '.
                             '10. Repeat this process in quick successions multiple times.  Observe that '.
                                 ' the controller is able to properly update the database to all VTEPs. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Stress',
				 TestcaseType     => 'Stress',
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
      'StressVTEPIpChange'   => {
         TestName         => 'StressVTEPIpChange',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the controller updates all VTEPs instantaneously, '.
         									   ' when the ip address of the VTEP is changed continuously. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. Change the ip address of VTEP-A to a different value. When the ip address '.
                                 ' of a VTEP changes, the existing TCP connection with the controller is '.
                                 ' reset and this event must be considered as a loss of VTEP. Observe that '.
                                 ' the controller updates all other VTEPs about the same. '.
                             '7. Simultaneously, a new TCP session must be initiatated between the new ip address '.
                                 ' of VTEP-A and the controller.  After the connection is established, '.
                                 ' database exchange/sync must happen across the domain. '.
                             '8. Change the ip address of VTEP-A back to its original ip.  The process '.
                                 ' mentioned in the above step must occur again. '.
                             '9. Repeat this process in quick successions multiple times.  Observe that '.
                                 ' the controller is able to properly update the database to all VTEPs. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Stress',
				 TestcaseType     => 'Stress',
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
      'StressControllerIpChange'   => {
         TestName         => 'StressControllerIpChange',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether VTEPs are able to converge, when the '.
         										 ' configured controller on them is switched between multiple ip addresses. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. On VTEP-A, change the controllers ip address to a different value. '.
                                 ' The existing tcp session must be reset and VTEP-A must try to '.
                                 ' establish fresh connection with the new ip address. '.
                                 ' The controller must in turn update all other VTEPs about the '.
                                 ' loss of VTEP-A. Verify on all VTEPs. '.
                             '7. Change the controller ip on VTEP-A back to the existing controller. '.
                                 ' The process mentioned in the above step must occur again. '.
                             '8. Repeat this process multiple times on VTEP-A. Observe that it is '.
                                 ' able to reset and initiate tcp connections multiple times. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Stress',
				 TestcaseType     => 'Stress',
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
      'StressSegmentIDChange'   => {
         TestName         => 'StressSegmentIDChange',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether controller updates all VTEPs '.
         										 ' when a segment id (segment subnet) is changed continuously. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. On VTEP-A, change the VTEPs segment ID by using any developer command. '.
																 ' Observe that the controller is updated and database sync happens. '.
                             '7. Repeat this process multiple times on VTEP-A. Observe that the segment ID '.
                                 ' is properly synced across all VTEPs. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Stress',
				 TestcaseType     => 'Stress',
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
      'StressPortUpDown'   => {
         TestName         => 'StressPortUpDown',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the functionality when the uplink port of '.
         										 ' VTEPs and the controller is brought up and down multiple times. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. On VTEP-A, bring down the uplink connected to the segment. '.
                                 ' Observe that VTEP-A is removed from the database from all '.
                                 ' other VTEPs after the expiration of dead interval. '.
                             '7. Bring up the uplink back on VTEP-A.  Observe that it is able '.
                                 ' to establish proper connection with the controller and '.
                                 ' database sync happens across the domain. '.
                             '8. Repeat this process multiple times on VTEP-A. Observe that the '.
                                 ' controller is able to sync across the domain every time. '.
                             '9. Repeat the same steps on the controller too. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Stress',
				 TestcaseType     => 'Stress',
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
      'InteropLACP'   => {
         TestName         => 'InteropLACP',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the VTEPs functionality when multiple uplinks '.
                             ' are bundled via LACP on the VTEPs. '.
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. On VTEP-A, connect one more uplink to the segment and '. 
                                 ' bundle both uplinks using LACP. Observe that there is '.
                                 ' no interference with VXLAN functionality, by sending '.
                                 ' traffic from VM-A1 to VM-C1. '.
                             '7. Bring down one member of LACP. Observe that as long as '.
                                 ' at least one member of the LACP lag is up, the logical '.
                                 ' port must be up and traffic betweeen VM-A1 to VM-C1 is '.
                                 ' uninterrupted. '.
                             '8. Bring up/down the member ports in random order, so that the '.
                                 ' traffic is sent/received on different uplinks. '.
                             '9. The traffic between VM-A1 to VM-C1 must not be affected when '.
                                 ' the member ports are brought up/down. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Interop',
				 TestcaseType     => 'Interop',
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
      'InteropQoS'   => {
         TestName         => 'InteropQoS',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the VTEP copies the QoS values (DSCP) '.
                             ' from the inner header to the outer VXLAN header. '. 
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. Send IP traffic from VM-A1 to VM-C1 and observe that it goes through. '.
                             '7. Modify the packets (generated from VM-A1) such that a non-default '.
                                 ' DSCP value is inserted in the IP header. '.
                             '8. When VXLAN module encapsulates this in VXLAN packet, it must copy the '.
                                 ' DSCP value of the original packet to the outer IP packet. Verify by '.
                                 ' configuring port mirroring on the Cisco router and capturing the packets. '.
                             '9. Send IP, TCP, UDP, ICMP, Multicast and Broadcast streams with non-default '.
                                 ' DSCP values from VM-A1.  Observe that the VXLAN module properly '.
                                 ' replicates the inner DSCP values to the outer IP header too. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Interop',
				 TestcaseType     => 'Interop',
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
      'InteropVCOPs'   => {
         TestName         => 'InteropVCOPs',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To be decided. '. 
				 Procedure        => '1.  '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Interop',
				 TestcaseType     => 'Interop',
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
      'MemoryLeak'   => {
         TestName         => 'MemoryLeak',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To check for any memory leak by vxlan module on both VTEPs and controller. '. 
				 Procedure        => '1. Connect the topology as shown, '.
                             '2. Create VNIs as shown on all VTEPs '.
                             '3. Configure the controller IP on all VTEPs '.
                             '4. Verify that all VTEPs update all their local databases ',
                                 ' to the controller.  Use relevant CLIs available '.
                                 ' on the hosts and the controller to verify the same. '.
                             '5. Verify that the database is synced across the vxlan domain '.
                             '6. Verify the free memory on VTEP-A before configuring the '.
                                 ' controller.  After the controller is configured and the '.
                                 ' database is synced, check the memory again. '.
                             '7. Delete the controller configuration on VTEP-A.  Check the memory again. '.
                             '8. Repeat this process multiple times and observe whether the vxlan '.
                                 ' module is leaking any memory. '.
                             '9. On the controller, check the memory before the database sync, and '.
                                 ' after the sync.  Now delete all the database using CLI commands. '.
                                 ' Check the memory again.  Repeat this process many times to get the '.
                                 ' average memory usage.  Also check for any memory leaks. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'MemoryLeak',
				 TestcaseType     => 'MemoryLeak',
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
      'ScaleMultipleVTEPs'   => {
         TestName         => 'ScaleMultipleVTEPs',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify whether the controller is able to '.
         										 ' establish proper connections with hundreds of VTEPs. '.
				 Procedure        => '1. This test requires hundreds of VTEPs in the domain. '.
				 										 '2. The controller has to establish proper TCP connections '.
				 										     ' with many VTEPs and exchange and sync databases across all of them. '.
				 										 '3. As per OP Functional Spec, 10K VTEPs can be supported by one '.
				 										     ' controller.  We can use agent testing mode to simulate '.
				 										     ' thousands of concurrent TCP connections. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Scalability',
				 TestcaseType     => 'Scalability',
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
      'ScaleMultipleVNIs'   => {
         TestName         => 'ScaleMultipleVNIs',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the case where one VTEP contains large number of VNIs. '.
				 Procedure        => '1. This test requires hundreds of VMs to be created on '.
				 												 ' multiple VTEPs. '.
				 										 '2. Each VM belongs to a different VNI '.
				 										 '3. This test verifies whehter controller is able to receive '.
				 										 	   ' and update other hosts about large number of VNIs. '.
				 										 '4. We can use agent testing mode to simulate large number '.
				 										     ' of VNIs in the network. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Scalability',
				 TestcaseType     => 'Scalability',
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
      'ScaleMultipleVTEPsPerSegment'   => {
         TestName         => 'ScaleMultipleVTEPsPerSegment',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the case where one segment contains large number '.
         											 ' of VTEPs'.
				 Procedure        => '1. This test requires thousands of VTEPs to be created on '.
				 												 ' the same segment'.
				 										 '2. We can use agent testing mode to simulate large number '.
				 										     ' of VTEPs on one network. '.
				 										 '3. The controller must be able to withstand large number of '.
				 										     ' VTEPs per segment, and in turn update all other hosts '.
				 										     ' with [<VTEP>,<Segment-ID>] table. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Scalability',
				 TestcaseType     => 'Scalability',
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
      'ScaleMultipleSegments'   => {
         TestName         => 'ScaleMultipleSegments',
         Category         => 'ESX Server',
         Component        => 'VXLAN',
				 Product          => 'ESX',
				 QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => ' To verify the case where there are multiple segments '.
         											 ' in the VXLAN domain. '.
				 Procedure        => '1. This test requires hundreds of segments to be created. '.
				 										 '2. Each segment contains hundreds of VTEPs. '.
				 										 '3. Each VTEP contains hundreds of VNIs. '.
				 										 '4. This tests the functionality and stealth of the controller. '.
				 										 '5. We can use agent testing mode to simulate large number '.
				 										     ' of segments, VTEPs and VNIs on the network. '.
				 ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
				 AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Scalability',
				 TestcaseType     => 'Scalability',
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
