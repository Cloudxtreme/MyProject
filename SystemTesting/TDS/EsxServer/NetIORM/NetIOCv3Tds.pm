#!/usr/bin/perl
#########################################################################
#Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::NetIORM::NetIOCv3Tds;

#
# This file contains the structured hash for category, TDS tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
#
# Run IO sessions with TCP, UDP, IPv4, IPv6
# and cover a range of packet and socket sizes
#
@ISA = qw(TDS::Main::VDNetMainTds);
{
   %NetIOCv3 = (
      'VerifyResources'   => {
         TestName         => 'VerifyResources',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify available resources by changing ' .
                             'reservation at vnic, resource pool, '.
                             'infrastructure traffic configuration ',
         ExpectedResult   => 'The available resources should reflect ' .
                             'value whenever there is change in configuration',
         Status           => 'Execution Ready',
         Tags             => 'sanity,automated',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHostNIOCv3VDS,
         WORKLOADS => {
             Sequence        => [
                                 ['SetInfrastructureSLR'],
                                 ['NegChangeVMReservation'],
                                 ['PosChangeFTReservation'],
                                 ['PosChangeVMReservation'],
                                 ['NegChangeFTReservation'],
                                ],
            SetInfrastructureSLR => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               niocinfrastructuretraffic  => {
                  'virtualMachine' => "50:100:500",
                  'faultTolerance' => "100:100:500",
                  'iSCSI'          => "100:100:500",
                  'vmotion'        => "100:100:500",
                  'nfs'            => "100:100:500",
                  'hbr'            => "100:100:500",
                  'vsan'           => "100:100:500",
                  'management'     => "100:100:500",
               },
            },
            'NegChangeVMReservation'   => {
               Type        => "Switch",
               TestSwitch  => "vc.[1].vds.[1]",
               ExpectedResult => "FAIL",
               NIOCInfrastructureTraffic  => {
                  'virtualMachine' => "51:100:500",
               },
            },
            'PosChangeFTReservation'   => {
               Type        => "Switch",
               TestSwitch  => "vc.[1].vds.[1]",
               NIOCInfrastructureTraffic  => {
                  'faultTolerance' => "0:100:500",
               },
            },
            'PosChangeVMReservation'   => {
               Type        => "Switch",
               TestSwitch  => "vc.[1].vds.[1]",
               NIOCInfrastructureTraffic  => {
                  'virtualMachine' => "75:100:500",
               },
            },
            'NegChangeFTReservation'   => {
               Type        => "Switch",
               TestSwitch  => "vc.[1].vds.[1]",
               ExpectedResult => "FAIL",
               NIOCInfrastructureTraffic  => {
                  'faultTolerance' => "100:100:500",
               },
            },
         },

      },
      'InfraTrafficNFS'   => {
         TestName         => 'InfraTrafficNFS',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that SLR are honored ' .
                             'for the system pool NFS traffic ',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Power on 2 VMs and start an NFS IO workload'.
                             '3. Start VM Traffic to saturate the uplink ' .
                             '4. Verify that SLR are honored ' .
                             '5. Sustained throughput should not vary over 5%',
         ExpectedResult   => 'SLR honored for NFS specific IO ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InfraTrafficSCSI'   => {
         TestName         => 'InfraTrafficSCSI',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that SLR are honored ' .
                             'for the system pool iSCSI traffic ',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Power on 2 VMs on iSCSI and start iSCSI IO workload '.
                             '3. Start VM Traffic to saturate the uplink ' .
                             '4. Verify that SLR are honored ' .
                             '5. Sustained throughput should not vary over 5%' ,
         ExpectedResult   => 'SLR honored for iSCSI specific IO ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InfraTrafficMGMT'   => {
         TestName         => 'InfraTrafficMGMT',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         TestName         => 'GenerateMGMTTraffic',
         Summary          => 'To verify that SLR are honored ' .
                             'for the system pool MGMT traffic ',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with multiple portgroups ' .
                             '2. Create a vmknic on DVPG ' .
                             '3. Pin the vmknic to management ' .
                             '4. Start traffic on the vmknic ' .
                             '5. Start VM Traffic to saturate the uplink ' .
                             '6. Verify that SLR are honored ' .
                             '7. Sustained throughput should not vary over 5% ' ,
         ExpectedResult   => 'SLR honored for MGMT specific IO ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InfraTrafficVSAN'   => {
         TestName         => 'InfraTrafficVSAN',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that SLR are honored ' .
                             'for the system pool VSAN traffic ',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with NIOC enabled ' .
                             '2. Power on 2 VMs on VSAN and start VSAN IO workload '.
                             '3. Start VM Traffic to saturate the uplink ' .
                             '4. Verify that SLR are honored ' .
                             '5. Sustained throughput should not vary over 5%' ,
         ExpectedResult   => 'SLR honored for VSAN specific IO ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InfraTrafficFTVMotion'   => {
         TestName         => 'InfraTrafficFTVMotion',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that SLR are honored ' .
                             'for FT and VMotion traffic ',
         ExpectedResult   => 'PASS',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with NIOC enabled ' .
                             '2. Power on 2 VMs on NFS with FT enabled ' .
                             '3. Power on 2 VMs on NFS with VMotion enabled ' .
                             '4. Trigger FT Failovers and VMotions on all VMs ' .
                             '4. Verify that SLR are honored ' .
                             '5. Sustained throughput should not vary over 5%' ,
         ExpectedResult   => 'SLR honored for FT and VMotion traffic ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            nteropNetFlowSequence => [],
         },
      },
      'TrafficVideoVOIP'   => {
         TestName         => 'TrafficVideoVOIP',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Generate Video/VOIP traffic ' .
                             'while NIOC is enabled and configured ',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS ' .
                             '2. Power on 2 VMs and start multiple VOIP workloads ' .
                             '3. Power on 1 Video Server and many clients ' .
                             '4. Where possible, verify the traffic type quality ' .
                             '5. Enable QOS Marking (DSCP) ' .
                             '6. Verify that packets are getting tagged ' .
                             '7. Sustained throughput should not vary over 5%' ,
         ExpectedResult   => 'SLR honored for Video/Voice specific IO' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1', #Use case from PRD
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InteropNetFlow'   => {
         TestName         => 'InteropNetFlow',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that netflow control packets ' .
                             'are unaffected while NIOC is enabled ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with NIOC and NetFlow enabled ' .
                             '2. Power on 2 VMs on and start various IO workloads ' .
                             '3. Verify that SLR are honored ' .
                             '4. Sustained throughput should not vary over 5%' .
         ExpectedResult   => 'Netflow packets should not be affected by NIOC ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'MarkingWithVLAN'   => {
         TestName         => 'MarkingWithVLAN',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that VLAN packets with traffic marking ' .
                             'enabled ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with NIOC with VLAN enabled ' .
                             '2. Configure QOS Marking from src to dst ' .
                             '3. Power on 2 VMs on same VLAN start IO ' .
                             '4. Verify that SLR are honored ' .
                             '5. Sustained throughput should not vary over 5%' ,
         ExpectedResult   => 'QOS Marked IO on VLAN should be successful ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'MarkingWithGuestVLAN'   => {
         TestName         => 'MarkingWithGuestVLAN',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify guest VLAN packets with traffic marking ' .
                             'enabled ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with NIOC and VLAN 4095 ' .
                             '2. Configure QOS Marking from src to dst ' .
                             '3. Configure Guest VLAN Tagging on src/dst VMs ' .
                             '4. Verify that SLR are honored ' .
                             '5. Sustained throughput should not vary over 5% ' ,
         ExpectedResult   => 'QOS Marked IO on Guest VLAN packets should be successful ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InfraTrafficChangeLinkStatus'   => {
         TestName         => 'InfraTrafficChangeLinkStatus',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that SLR are still honored ' .
                             'after vDS Operations or Features are enabled ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with multiple physical uplinks ' .
                             '2. Power on 2 VMs on NFS, start various IO workloads ' .
                             '3. Verify that SLR are honored for NFS/VM Traffic ' .
                             '6. Perform (no)shutdown on switchport ' .
                             '7. Verify that SLR are still honored on failover ' .
                             '8. Perform failback and reverify ' ,
         ExpectedResult   => 'SRL honored in link up/down situations ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'TeamingMultipleUplinkActiveStandby'   => {
         TestName         => 'TeamingMultipleUplinkActiveStandby',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that SLR are still honored with multiple ' .
                             'uplinks after changing active/standby mode. ' .
                             'Teaming policy behaves needs to be documented' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with multiple physical uplinks ' .
                             '2. Set VM1 Reservation to utilize bandwith ' .
                             'from multiple adaptors ' .
                             '3. Power on VM1 on and start workload ' .
                             '4. Start VM Traffic utilize full reservation ' .
                             '5. Verify that SLR are honored ' .
                             '6. Sustained throughput should not vary over 5% ' .
                             '7. Place physical uplink into standby ' .
                             '8. Verify SLR still honored on remaining active uplinks ' .
                             '9. Reset to Active, reverify, repeat ' ,
         ExpectedResult   => 'Nic placement should only happen on active nics;' .
                             'SLR honored during secondary pnic active/standby',
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         DurInfraTrafficChangeLinkStatusation         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'VMUpgrade'   => {
         TestName         => 'VMUpgrade',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that NIOC vnic settings ' .
                             'are unavailable on older vDS versions ',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a 5.1 vDS with a default portgroup ' .
                             '2. Power on 1 VM with a VHW version of 10 '.
                             '3. Edit the VM properties ' .
                             '3. Verify SLR are not configurable ' ,
         Status           => 'Draft',
         FullyAutomatable => 'Y',
         AutomationStatus => 'Automated',
         Tags             => 'automated',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec      => {
           'vc' => {
                  '[1]' => {
                    'datacenter' => {
                           '[1]' => {
                                     'host' => 'host.[1]'
                            }
                   },
                   'dvportgroup' => {
                           '[1]' => {
                                     'vds' => 'vc.[1].vds.[1]',
                                       dvport   => {
                                              '[1-10]' => {
                                        }
                                      },
                          }
                   },
                   'vds' => {
                      '[1]' => {
                                'datacenter' => 'vc.[1].datacenter.[1]',
                                'vmnicadapter' => 'host.[1].vmnic.[1]',
                                'configurehosts' => 'add',
                                'host' => 'host.[1]',
                                'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                                'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
                                niocinfrastructuretraffic  => {
                                     'virtualMachine' => "500:100:1000",
                                },
                     }
                 }
              }
          },
          'host' => {
               '[1]' => {
                 'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                 }
               }
          },
        },
        WORKLOADS => {
           Sequence => [
                        ['AddVMHW08','AddVMHW09'],
                        ['AddVnic'],
                        ['VerifyPlacement'],
                        ['UpdateVMHW10'],
                        ['PowerON'],
                        ['VerifyPlacement'],
                        ],
            VerifyPlacement => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1-2].vnic.[1]",
               nicplacement => "1",
            },
            AddVMHW08  => {
                 Type  => "Root",
                 TestNode  => "root.[1]",
                 vm  => {
                    '[1]'   => {
                       host  => "host.[1]",
                       version  =>  VDNetLib::TestData::TestConstants::VM_LAST_SUPPORTED_HW_VERSION,
                       template => VDNetLib::TestData::TestConstants::VDNet_DEFAULT_VM,
                    },
                 },
            },
            AddVnic => {
               Type       => "VM",
               TestVM     => "vm.[1-2]",
               vnic => {
                  '[1]'   => {
                     driver	   => "vmxnet3",
                     portgroup   => "vc.[1].dvportgroup.[1]",
                     shares      => "50",
                     reservation => "50",
                     limit       => "1000",
                     connected   => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            UpdateVMHW10 => {
                 Type  => "VM",
                 TestVM   => "vm.[1-2]",
                 vmstate  => "poweroff",
                 version  => VDNetLib::TestData::TestConstants::VM_DEFAULT_HW_VERSION,
              },
            PowerON => {
                 Type  => "VM",
                 TestVM   => "vm.[1-2]",
                 vmstate  => "poweron",
              },
            AddVMHW09  => {
                 Type  => "Root",
                 TestNode  => "root.[1]",
                 vm  => {
                    '[2]'   => {
                       host  => "host.[1]",
                       version  => VDNetLib::TestData::TestConstants::VM_LAST_RELEASED_HW_VERSION,
                       template => VDNetLib::TestData::TestConstants::VDNet_DEFAULT_VM,
                    },
                 },
              },
         },
      },
      'VMotionUpgrade'   => {
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         TestName         => 'VMVersionTen',
         Summary          => 'To verify VMotion from ESXi 5.1 to 6.0 ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Install ESXi 5.1 on host1 ' .
                             '2. Install ESXi 6.0 on host2 ' .
                             '3. Create a 5.1 vDS, add both hosts ' .
                             '4. Enable NIOCv2 and set SL ' .
                             '5. Power on a VM with a a vnic connected to vDS ' .
                             '6. VMotion the VM both ways ' .
                             '7. Verify SL are still honored after VMotion ' .
                             '8. Repeat this upgrade test for older ESX ' .
                             'versions 4.0, 4.1, 5.0',
         ExpectedResult   => 'VMotion to/from upgraded machine succeeds ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InteropFTFailover'   => {
         TestName         => 'InteropFTFailover',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that FT Failover co-exists with NetIORMv3 ' ,
         Tags             => '',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a Cluster with FT enabled ' .
                             '2. Add hosts to a NetIOCv3 enabled vDS ' .
                             '3. Configure FT on a VM '.
                             '4. Configure SLR on the VM vnic ' .
                             '5. Verify that SLR are honored  ' .
                             '6. Force the FT Failover ' .
                             '7. Verify that the FT Failover was successful ' .
                             '8. Verify that SLR are still honored  ' ,
         ExpectedResult   => 'SLR should still be honored after failover ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InteropHAFailover'   => {
         TestName         => 'InteropHAFailover',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that HA Failover co-exists with NetIORMv3 ' ,
         Tags             => '',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a Cluster with HA enabled ' .
                             '2. Add hosts to a NetIOCv3 enabled vDS ' .
                             '3. Configure HA on a VM '.
                             '4. Configure SLR on the VM vnic ' .
                             '5. Verify that SLR are honored  ' .
                             '6. Force the HA Failover ' .
                             '7. Verify that the HA Failover was successful ' .
                             '8. Verify that SLR are still honored  ' ,
         ExpectedResult   => 'SLR should still be honored after failover ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2', # may not be required since it is
                                   # equivalent to bringing up a new
                                   # vm with SLR
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'LimitsVerifyAllSpeeds'   => {
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         TestName         => 'LimitsVerify',
         Summary          => 'To verify that Limits are honored for VM Traffic ' .
                             'for all speeds capable. 100,200...1G,2G,3g... ',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Add a host to a NetIOCv3 enabled vDS ' .
                             '2. Configure NetIOCv3 Limits ' .
                             '3. Power on 2 VMs, generate traffic ' .
                             '4. Verify max throughput for a  baseline ' .
                             '4. Verify that Limits caps throughput ' .
                             '5. Verify at all speeds 100,200...1G,2G,3g... ' .
                             '6. Include negative as well as pos cases ' .
                             '7. Verify that no excessive fluctuation exists ' ,
         ExpectedResult   => 'Limits honored for all speeds to 10G ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InfraShareOrder'   => {
         TestName         => 'InfraShareOrder',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that Reservations take precedence over ' .
                             'Shares while available bandwidth is saturated ' ,
         Tags             => '',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Add a host to a NetIOCv3 enabled vDS ' .
                             '2. Configure NetIOCv3 Reservation and Shares ' .
                             '3. Power on 3 VMs generate traffic capable of
                             saturation ' .
                             '4. Set Shares on each VM as follows ' .
                             '5. VM1 = High, VM2 = Med, VM3 = Below Reservation ' .
                             '6. Verify that Reservations are honored over Shares ' .
                             '7. Verify that no excessive fluctuation exists ' ,
         ExpectedResult   => 'Verify that Reservations are honored over Shares ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'InfraReservationLimits'   => {
         TestName         => 'InfraReservationLimits',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that Reservations and Limits co-exist' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Add a host to a NetIOCv3 enabled vDS ' .
                             '2. Configure NetIOCv3 Reservation and Limits ' .
                             '3. Power on 2 VMs, generate traffic ' .
                             '4. Verify that Reservations and limits are honored ' .
                             '5. Verify that no excessive fluctuation exists ' .
                             '6. Repeat for a number of different RL ' ,
         ExpectedResult   => 'Set and Verify RL at all levels ' ,
         Status           => 'Draft',
         AutomationLevel  => 'automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
           vc => {
              '[1]' => {
                datacenter => {
                     '[1]' => {
                          'host' => 'host.[1]'
                     },
                },
                dvportgroup => {
                   '[1]' => {
                       'vds' => 'vc.[1].vds.[1]',
                            dvport  => {
                              '[1-10]' => {
                              },
                            },
                   },
                   '[2]' => {
                       'vds' => 'vc.[1].vds.[2]',
                            dvport   => {
                                '[1-10]' => {
                                },
                            },
                       },
                 },

                 vds => {
                    '[1]' => {
                       'datacenter' => 'vc.[1].datacenter.[1]',
                       'vmnicadapter' => 'host.[1].vmnic.[1]',
                       'configurehosts' => 'add',
                       'host' => 'host.[1]',
                       'nioc' =>'enable',
                       'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
                       'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                        niocinfrastructuretraffic  => {
                                     'virtualMachine' => "750:100:1000",
                                },
                     },
                     '[2]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[2]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                     },
                 },
               },
            },
            host => {
                 '[1]' => {
                    vmnic => {
                         '[1-2]' => {
                              'driver' => 'any'
                         },
                     },
                  },
            },
              vm => {
                 '[1-2]' => {
                     vnic => {
                         '[1]' => {
                              'portgroup' => 'vc.[1].dvportgroup.[1]',
                              'driver' => 'vmxnet3',
                              reservation => "100",
                              limit       => "1000",
                              connected   => 1,
                              startconnected    => 1,
                              allowguestcontrol => 1,
                        },
                    },
                    'host' => 'host.[1]'
                  },
                  '[3]' => {
                       vnic => {
                             '[1]' => {
                                  'portgroup' => 'vc.[1].dvportgroup.[2]',
                                  'driver' => 'vmxnet3',
                             },
                       },
                       'host' => 'host.[1]'
                   },
              },
         },
         WORKLOADS => {
            Sequence => [
                         ['EditRLVM500'],
                         ['Traffic'],
                         ['EditRLVM1'],
                         ['Traffic'],
                         ['EditRLVM600'],
                         ['Traffic'],
                         ],

            'EditRLVM500' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "650",
               limit       => "850",
               portgroup   => "vc.[1].dvportgroup.[1]",
             },
            'EditRLVM1' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "1",
               limit       => "750",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            'EditRLVM600' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "600",
               limit       => "600",
               portgroup   => "vc.[1].dvportgroup.[1]",
             },
             'Traffic' => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               parallelsession       => "yes",
               TestAdapter           => "vm.[1].vnic.[1]",
               SupportAdapter        => "vm.[3].vnic.[1]",
               L3Protocol            => "ipv4,ipv6",
               L4Protocol            => "tcp",
               NoofOutbound          => "1",
               NoofInbound           => "1",
               SendMessageSize       => "1024,4094,64512",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               testduration          => "5",
               maxthroughput         => "700",
            },
         },
      },
      'RXTraffic'   => {
         TestName         => 'RXTraffic',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that Shares are honored where ' .
                             'RX traffic exist on the same uplink ' ,
         Procedure        => '1. Add a host to a NetIOCv3 enabled vDS ' .
                             '2. Configure NetIOCv3 SLR on vnic ' .
                             '3. Power on a VM, generate bidirectional traffic ' ,
         ExpectedResult   => 'Verify that SLR are honored for TX traffic ' .
                             'and RX traffic is unaffected by SLR config ' ,
         Status           => 'Execution Ready',
         Tags             => 'automated',
         Tags             => 'physicalonly',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_FiveVMs_NETIOC,
         WORKLOADS => {
         Sequence => [
                     ['Traffic']
                     ],

           Traffic => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               parallelsession       => "yes",
               TestAdapter           => "vm.[1-4].vnic.[1]",
               SupportAdapter        => "vm.[5].vnic.[1]",
               L3Protocol            => "ipv4,ipv6",
               L4Protocol            => "tcp",
               NoofOutbound          => "1",
               NoofInbound           => "1",
               SendMessageSize      => "1024,4096,8192," .
                                        "16384,64512",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               testduration          => "5",
            },
         },
      },
      'VerifyShares'   => {
         TestName         => 'VerifyShares',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that Shares are honored when ' .
                             'different share values are used' ,
         Procedure        => '1. Add a host to a NetIOCv3 enabled vDS ' .
                             '2. Configure NetIOCv3 SLR on vnic ' .
                             '3. Power on a VM, generate bidirectional traffic ' ,
         ExpectedResult   => 'Verify that SLR are honored for TX traffic ' .
                             'and RX traffic is unaffected by SLR config ' ,
         Status           => 'Execution Ready',
         Tags             => 'automated',
         Tags             => 'physicalonly',
         PMT              => '4084',
         AutomationLevel  => 'automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_FiveVMs_NETIOC,
         WORKLOADS => {
         Sequence => [
                     ['EditShares'],
                     ['EditReservation'],
                     ['Traffic']
                     ],

           'Traffic' => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               parallelsession       => "yes",
               TestAdapter           => "vm.[1-4].vnic.[1]",
               SupportAdapter        => "vm.[5].vnic.[1]",
               L3Protocol            => "ipv4",
               L4Protocol            => "tcp",
               NoofOutbound          => "1",
               SendMessageSize       => "327685",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               testduration          => "5",
               verification          => "Verification",
            },
            'Verification' => {
               'NIOCVerificaton' => {
                  verificationtype => "NIOC",
                  target           => "srcVM",
                  uplinks          => "host.[1].vmnic.[1]",
               },
            },
            'EditShares' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               shares      => "25",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            'EditReservation' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-4].vnic.[1]",
               reconfigure => "true",
               reservation      => "1",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
         },
      },

      'VerifyVDSUpgrade'   => {
         TestName         => 'VerifyVDSUpgrade',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To NIOC is working  when VDS is' .
                             'Upgraded' ,
         Procedure        => '1. Configure a vDS version 5.5 ' .
                             '5. Configure NIOC with version2 ' .
                             '6. upgrade the vDS to 6.0 and NIOC to version3' .
                             '8. Power on VMs ' .
                             '9. Verify Placement ' ,
         ExpectedResult   => 'VDS Upgrade should succeed, share/limits ' .
                             '(user defined pools configuration) values ' .
                             'should be removed ' ,
         Status           => 'Execution Ready',
         Tags             => 'automated',
         Tags             => 'physicalonly',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
          vc => {
              '[1]' => {
                datacenter => {
                     '[1]' => {
                          'host' => 'host.[1]'
                     },
                },
                dvportgroup => {
                   '[1]' => {
                       'vds' => 'vc.[1].vds.[1]',
                            dvport  => {
                              '[1-10]' => {
                              },
                            },
                   },
                   '[2]' => {
                       'vds' => 'vc.[1].vds.[2]',
                            dvport   => {
                                '[1-10]' => {
                                },
                            },
                       },
                 },

                 vds => {
                    '[1]' => {
                       'datacenter' => 'vc.[1].datacenter.[1]',
                       'vmnicadapter' => 'host.[1].vmnic.[1]',
                       'configurehosts' => 'add',
                       'host' => 'host.[1]',
                       'nioc' =>'enable',
                       'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_LAST_RELEASED_VERSION,
                       'version' => VDNetLib::TestData::TestConstants::VDS_LAST_RELEASED_VERSION,
                     },
                     '[2]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[2]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                     },
                 },
               },
            },
            host => {
                 '[1]' => {
                    vmnic => {
                         '[1-2]' => {
                              'driver' => 'any'
                         },
                     },
                  },
            },
              vm => {
                 '[1-2]' => {
                     vnic => {
                         '[1]' => {
                              'portgroup' => 'vc.[1].dvportgroup.[1]',
                              'driver' => 'vmxnet3',
                        },
                    },
                    'host' => 'host.[1]'
                  },
                  '[3]' => {
                       vnic => {
                             '[1]' => {
                                  'portgroup' => 'vc.[1].dvportgroup.[2]',
                                  'driver' => 'vmxnet3',
                             },
                       },
                       'host' => 'host.[1]'
                   },
            },

         },
         WORKLOADS => {
         Sequence => [
                     ['AddSLVM'],
                     ['UpgradeVDS6'],
                     ['SetVDSSLR'],
                     ['AddSLRVM'],
                     ['VerifyPlacement'],
                     ['Traffic']
                     ],

           'Traffic' => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               parallelsession       => "yes",
               TestAdapter           => "vm.[1-2].vnic.[1]",
               SupportAdapter        => "vm.[3].vnic.[1]",
               L3Protocol            => "ipv4",
               L4Protocol            => "tcp",
               NoofOutbound          => "1",
               SendMessageSize       => "327685",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               testduration          => "5",
               verification          => "Verification",
            },
            'Verification' => {
               'NIOCVerificaton' => {
                  verificationtype => "NIOC",
                  target           => "srcVM",
                  uplinks          => "host.[1].vmnic.[1]",
               },
            },
            'SetVDSSLR' => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
              'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
               'niocinfrastructuretraffic'  => {
                  'virtualMachine' => "500:100:1000",
               },
            },
            'AddSLVM' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-2].vnic.[1]",
               reconfigure => "true",
               shares      => "50",
               limit       => "1000",
            },
            'AddSLRVM' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-2].vnic.[1]",
               reconfigure => "true",
               shares      => "50",
               reservation => "100",
               limit       => "1000",
            },
            'UpgradeVDS6' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'upgradevds' => '6.0.0',
            },
            'VerifyPlacement' => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1-2].vnic.[1]",
               nicplacement => "1",
            },

         },
      },

      'VMNPGAssociated'   => {
         TestName         => 'VMNRPAssociated',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that SLR comes from the associated ' .
                             'portgroup ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Add a host to a NetIOCv3 enabled vDS ' .
                             '2. Enable NetIOCv3 ' .
                             '3. Power on a VM ' .
                             '4. Edit VM Reservation ' .
                             '5. Verify that reservation comes from the ' .
                             'VM System Pool ' .
                             '6. Create a UDPG and associate it to the ' .
                             'corresponding vnics PG ' .
                             '7. Verify that Reservations are from the
                             associated UDRP ' .
                             '8. Verify that Reservations are released
                             from the System Pool ' ,
         ExpectedResult   => 'Verify reservation comes from the correct ' .
                             'Resource Pool ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'DefaultVMStarving'   => {
         TestName         => 'DefaultVMStarving',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify the impact on a default vm ' .
                             'with no SLR on the same host ' .
                             'where there are VMs with SLR ',
         Procedure        => '1. Enable NIOC v3 on a VDS ' .
                             '2. Configure 3 VMs each with 1/3rd of available ' .
                             'VM bandwidth ' .
                             '3. Run IO session across all 4 VMs' .
                             '4. Next, configure only one VM with 25% of ' .
                             'available VM bandwidth and rest with no SLR',
         ExpectedResult   => 'VM with no SLR should get minimum (TBD) ' .
                             'performance when no SLR is configured ',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VMConfigNegNIOCv2VMEdit'   => {
         TestName         => 'VMConfigNegNIOCv2VMEdit',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Negative case to verify that NOICv2 will not allow ' .
                             'the SLR to be edited at the VM vnic level ' ,
         ExpectedResult   => 'PASS',
         Tags             => '',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Add a host to a NetIOCv2 enabled vDS ' .
                             '2. Enable NetIOCv2 ' .
                             '4. Power on a VM ' .
                             '5. Attempt to edit VM Reseravation ' .
                             '6. Verify editing the VM settings are not possible ' ,
         ExpectedResult   => 'Attempts to edit SLR at VM Setting should fail ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
          vc => {
              '[1]' => {
                datacenter => {
                     '[1]' => {
                          'host' => 'host.[1]'
                     },
                },
                dvportgroup => {
                   '[1]' => {
                       'vds' => 'vc.[1].vds.[1]',
                            dvport  => {
                              '[1-10]' => {
                              },
                            },
                   },
                 },

                 vds => {
                    '[1]' => {
                       'datacenter' => 'vc.[1].datacenter.[1]',
                       'vmnicadapter' => 'host.[1].vmnic.[1]',
                       'configurehosts' => 'add',
                       'host' => 'host.[1]',
                       'nioc' =>'enable',
                       'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_LAST_RELEASED_VERSION,
                       'version' => VDNetLib::TestData::TestConstants::VDS_LAST_RELEASED_VERSION,
                     },
                 },
               },
            },
            host => {
                 '[1]' => {
                    vmnic => {
                         '[1-2]' => {
                              'driver' => 'any'
                         },
                     },
                  },
            },
              vm => {
                 '[1]' => {
                     vnic => {
                         '[1-2]' => {
                              'portgroup' => 'vc.[1].dvportgroup.[1]',
                              'driver' => 'vmxnet3',
                        },
                    },
                    'host' => 'host.[1]'
                  },
            },


         },
         WORKLOADS => {
            Sequence => [
                         ['AddSLVM'],
                         ['AddReservationVM'],
                         ],

            'AddSLVM' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1-2]",
               reconfigure => "true",
               shares      => "50",
               limit       => "1000",
            },
            'AddReservationVM' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1-2]",
               reconfigure => "true",
               reservation     => "100",
               ExpectedResult => "FAIL",
            },
         },
      },
      'VerifyHostUpgrade'   => {
         TestName         => 'VerifyHostUpgrade',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Install ESXi 5.1 configure VDS version 5.1 ' .
                             'upgrade the host to 6.0 verify NIOC ' .
                             'the SLR to be edited at the VM vnic level ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Install ESXi 5.1, configure a vDS version 5.1 ' .
                             '2. Power on 2 VMs, generate TX traffic ' .
                             '3. Verify that SL are honored ' .
                             '4. upgrade the host to 6.0 ' .
                             '5. Verify that upgrade succeeds ' .
                             '5. Power on VMs and resume traffic ' .
                             '6. Verify that SL are still honored ' .
                             '7. Repeat this test for ESX versions 4.0, 4.1 ' .
                             'and 5.0 as well',
         ExpectedResult   => 'Host upgrade should not affect share/limits ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'MarkOnePTag'   => {
         TestName         => 'MarkOnePTag',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify that 802.1p packets leave the host ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Configure a vDS, add host ' .
                             '2. Set QOS to mark packets with a 802.1q tag ' .
                             '3. Power on a VM and and generate traffic ' .
                             '4. Verify that the packet was tagged ' .
                             '5. Continue setting values for 802.1p 0-7 ' .
                             '6. Re Verify ' ,
         ExpectedResult   => 'Verify 1p tags on the wire ',
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'MarkDSCP'   => {
         TestName         => 'MarkDSCP',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify that DSCP tagged packets leave the host ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Configure a vDS, add host ' .
                             '2. Set QOS to mark packets with a DSCP tag ' .
                             '3. Power on a VM and and generate traffic ' .
                             '4. Verify that the packet was tagged ' .
                             '5. Continue setting values for DSCP 0-63' .
                             '6. Re Verify' ,
         ExpectedResult   => 'Verify DSCP tags on the wire ',
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'MarkDSCPOnePTag'   => {
         TestName         => 'MarkDSCPOnePTag',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify DSCP/802.1p tagged packets leave the host ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Install ESXi, configure a vDS, add host ' .
                             '2. Set QOS to mark packets with a both tags ' .
                             '3. Power on a VM and and generate traffic ' .
                             '4. Verify that the packet was tagged ' .
                             '5. Continue setting values for DSCP/802.1p' .
                             '6. Re Verify' ,
         ExpectedResult   => 'Both tagging types work together ',
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'VerifyGuestPTagOverwrite'   => {
         TestName         => 'VerifyGuestPTagOverwrite',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify guest DSCP/.1p tags are overwritten ' .
                             'when NIOC tags are enabled and pass thru when ' .
                             'disabled ' ,
         ExpectedResult   => 'PASS',
         Tags             => '',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Install ESXi, configure a vDS, add host ' .
                             '2. Power on a VM with guest tagging enabled ' .
                             '3. Generate traffic, verify guest tag on wire ' .
                             '4. Enable NIOC and config a different .1p tag ' .
                             '5. Generate traffic, verify NIOC tag on wire ' .
                             '6. Repeat setting values for DSCP' ,
         ExpectedResult   => 'Guest generated tags are overwritten by NIOC ',
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'FiveTuplesTCP'   => {
         TestName         => 'FiveTuplesTCP',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Enable QOS 5 tuple for both DSCP and 802.1p ' .
                             'verify TCP packets are marked based on rule ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Install ESXi, configure a vDS, add host ' .
                             '2. Power on a VM and and generate TCP traffic ' .
                             '3. Verify no marking on the packet ' .
                             '4. Set ip src dst, port src dst, transport TCP ' .
                             '5. Verify that the packet is now tagged ' .
                             '6. Continue setting values for DSCP/802.1p' .
                             '7. Re Verify' ,
         ExpectedResult   => 'TCP Packets tagged based on defined rules ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },
      'FiveTuplesUDP'   => {
         TestName         => 'FiveTuplesUDP',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Enable QOS 5 tuple for both DSCP and 802.1p ' .
                             'verify UDP packets are marked based on rule ' ,
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Install ESXi, configure a vDS, add host ' .
                             '2. Power on a VM and and generate UDP traffic ' .
                             '3. Verify no marking on the packet ' .
                             '4. Set ip src dst, port src dst, transport UDP' .
                             '5. Verify that the packet is now tagged ' .
                             '6. Continue setting values for DSCP/802.1p' .
                             '7. Re Verify' ,
         ExpectedResult   => 'UDP Packets tagged based on defined rules ' ,
         Status           => 'Draft',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
         },
         WORKLOADS => {
            Sequence => [],
         },
      },

      'VMConfigHardwareVersion'   => {
         TestName         => 'VMConfigHardwareVersion',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Configure VM with SLR with different hardware '.
                             'versions',
         Procedure        => '1. Configure SLR with HW version 9 and try ' .
                             'and power on. Either power on should fail or '.
                             'SLR configuration should be ignored. ' .
                             '2.Configure SLR with HW version 10 or above. ' .
                             'Powering on VM should work and SLR should be ' .
                             'honored',
         ExpectedResult   => 'SLR should work only with HW version 10 or above',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VMConfigDifferentDevices'   => {
         TestName         => 'VMConfigDifferentDevices',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Configure SLR on VM with different devices ' .
                             'backends',
         Procedure        => '1. Configure SLR on VM with vmxnet3, e1000, ' .
                             'vmxnet2, e1000e devices. SLR configuration '.
                             'should work with all devices. ' .
                             '2. Configure SLR on a pci passthru device. ' .
                             'The expected result is yet to be confirmed',
         ExpectedResult   => 'SLR should be successfully configured on all ' .
                             'devices',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'OvercommitBandwidth'   => {
         TestName         => 'OvercommitBandwidth',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Check overcommit takes vnic out of placement',
         ExpectedResult   => 'Overcommit should allow vm reconfigure to succeed' .
                             ' but vnic should not be placed on any uplink',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHostNIOCv3VDS,
         WORKLOADS => {
            Sequence => [
               ['SetVMReservation'],
               ['EditReservationPos'],
               ['VerifyPlacementPos'],
               ['OvercommitReservation'],
               ['VerifyPlacementNeg']
               ],

            SetVMReservation => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               niocinfrastructuretraffic  => {
                  'virtualMachine' => "500:100:1000",
               },
            },
            EditReservationPos => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "100",
            },
            OvercommitReservation => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "600",
            },
            VerifyPlacementPos => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "1",
            },
            VerifyPlacementNeg => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "0",
            },
         },
      },
      'VMConfigReleaseBandwidth'   => {
         TestName         => 'VMConfigReleaseBandwidth',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Check hot add and remove behavior of ' .
                             'network adapter with SLR configuration. ',
         Procedure        => '1. Hot add a network card with SLR configuration ' .
                             'and expect it work if there is sufficient ' .
                             'bandwidth available on the uplinks. ' .
                             '2. Hot remove an adapter with SLR configuration ' .
                             'and expect the resources to be released',
         ExpectedResult   => 'Available resources should be reduced after ' .
                             'hot add and released after hot remove',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHostNIOCv3VDS,
         WORKLOADS => {
            Sequence => [
               ['SetVMReservation'],
               ['EditReservation'],
               ['AddVnics'],
               # gyang's change allows overcommit
               ['AddExtraVnicNeg'],
               #['VerifyPlacementNeg'],
               ['RemoveVnic'],
               ['AddExtraVnicPos'],
               ['VerifyPlacement'],
               ['RebootVM'],
               ['VerifyPlacement'],
               ['DisconnectVnics'],
               ['ConnectVnics'],
               ['VerifyPlacement']
               ],

            SetVMReservation => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               niocinfrastructuretraffic  => {
                  'virtualMachine' => "500:100:1000",
               },
            },
            EditReservation => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "100",
            },
            AddVnics => {
               Type       => "VM",
               TestVM     => "vm.[1]",
               vnic => {
                  '[2-5]'   => {
                     driver	   => "vmxnet3",
                     portgroup   => "vc.[1].dvportgroup.[1]",
                     shares      => "50",
                     reservation => "100",
                     limit       => "1000",
                     connected   => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            RemoveVnic => {
               Type       => "VM",
               TestVM     => "vm.[1]",
               deletevnic => "vm.[1].vnic.[5]"
            },
            AddExtraVnicNeg => {
               Type       => "VM",
               TestVM     => "vm.[1]",
               vnic => {
                  '[6]'   => {
                     driver	   => "vmxnet3",
                     portgroup   => "vc.[1].dvportgroup.[1]",
                     shares      => "50",
                     reservation => "100",
                     limit       => "1000",
                     connected   => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
               ExpectedResult => "FAIL",
            },
            AddExtraVnicPos => {
               Type       => "VM",
               TestVM     => "vm.[1]",
               vnic => {
                  '[6]'   => {
                     driver	   => "vmxnet3",
                     portgroup   => "vc.[1].dvportgroup.[1]",
                     shares      => "50",
                     reservation => "100",
                     limit       => "1000",
                     connected   => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            VerifyPlacementNeg => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[6]",
               nicplacement => "0",
            },
            VerifyPlacement => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1-4],vm.[1].vnic.[6]",
               nicplacement => "1",
            },
            RebootVM => {
               Type => "VM",
               TestVM => "vm.[1]",
               operation   => "reboot",
               waitforvdnet => 0,
            },
            DisconnectVnics => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1-4]",
               reconfigure => "true",
               connected   => 0,
               startconnected    => 0,
               allowguestcontrol => 0,
            },
            ConnectVnics => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1-4]",
               reconfigure => "true",
               connected   => 1,
               startconnected    => 1,
               allowguestcontrol => 1,
            },
         },
      },
      'VMConfigSLRCombinations'   => {
         TestName         => 'VMConfigSLRCombinations',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Configure VM with different combinations of ' .
                             'SLR values ',
         Procedure        => '1. Configure a network adapter with shares only ' .
                             '2. Configure network adapter with limits only ' .
                             '3. Configure network adapter with reservation ' .
                             'only '                                          .
                             '4. Configure SLR with different combinations '  .
                             'including invalid values.'                      .
                             'The configuration should fail for invalid '     .
                             'values and succeed for valid values',
         ExpectedResult   => 'SLR configuration should be successful for ' .
                             'valid scenarios',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VMConfigEnableDisableSLR'   => {
         TestName         => 'VMConfigEnableDisableSLR',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Enable/disable SLR for a vnic in a ' .
                             'loop to check for any memory leak ',
         Procedure        => '1. Configure NIOC/SLR values on a vnic ' .
                             '2. Disable NIOC/SLR values on vnic '.
                             '3. Run the steps above in a loop ',
         ExpectedResult   => 'At the end of multiple iterations, the vnic' .
                             'should be in a functional state',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
           vc => {
              '[1]' => {
                datacenter => {
                     '[1]' => {
                          'host' => 'host.[1]'
                     },
                },
                dvportgroup => {
                   '[1]' => {
                       'vds' => 'vc.[1].vds.[1]',
                            dvport  => {
                              '[1-10]' => {
                              },
                            },
                   },
                   '[2]' => {
                       'vds' => 'vc.[1].vds.[2]',
                            dvport   => {
                                '[1-10]' => {
                                },
                            },
                       },
                 },

                 vds => {
                    '[1]' => {
                       'datacenter' => 'vc.[1].datacenter.[1]',
                       'vmnicadapter' => 'host.[1].vmnic.[1]',
                       'configurehosts' => 'add',
                       'host' => 'host.[1]',
                       'nioc' =>'enable',
                       'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
                       'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                        niocinfrastructuretraffic  => {
                                     'virtualMachine' => "750:100:1000",
                                },
                     },
                     '[2]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[2]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                     },
                 },
               },
            },
            host => {
                 '[1]' => {
                    vmnic => {
                         '[1-2]' => {
                              'driver' => 'any'
                         },
                     },
                  },
            },
              vm => {
                 '[1-2]' => {
                     vnic => {
                         '[1]' => {
                              'portgroup' => 'vc.[1].dvportgroup.[1]',
                              'driver' => 'vmxnet3',
                              'reservation' => "100",
                              'shares'    => "50",
                              'limit'       => "1000",
                              'connected'   => 1,
                              'startconnected'    => 1,
                              'allowguestcontrol' => 1,
                        },
                    },
                    'host' => 'host.[1]'
                  },
                  '[3]' => {
                       vnic => {
                             '[1]' => {
                                  'portgroup' => 'vc.[1].dvportgroup.[2]',
                                  'driver' => 'vmxnet3',
                             },
                       },
                       'host' => 'host.[1]'
                   },
              },
         },
         WORKLOADS => {
         Sequence => [
                       ['EnableSLR'],
                       ['DisableSLR'],
                       ['EnableSLR'],
                       ['DisableSLR'],
                       ['EnableSLR'],
                       ['DisableSLR'],
                       ['EnableSLR'],
                       ['DisableSLR'],
                       ['EnableSLR'],
                       ['DisableSLR'],
                       ['EnableSLR'],
                       ['DisableSLR'],
                       ['EnableSLR'],
                       ['DisableSLR'],
                       ['EnableSLR'],
                       ['DisableSLR'],
                       ['EnableSLR'],
                       ['Traffic'],
                       ['VerifyPlacement'],
                       ],
             'DisableSLR' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-2].vnic.[1]",
               reconfigure => "true",
               reservation => "0",
               shares      => "0",
               limit       => "1",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            'EnableSLR' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-2].vnic.[1]",
               reconfigure => "true",
               reservation => "200",
               limit       => "1000",
               shares      => "50",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
             'Traffic' => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               parallelsession       => "yes",
               TestAdapter           => "vm.[1-2].vnic.[1]",
               SupportAdapter        => "vm.[3].vnic.[1]",
               L3Protocol            => "ipv4,ipv6",
               L4Protocol            => "tcp",
               NoofOutbound          => "1",
               NoofInbound           => "1",
               SendMessageSize       => "1024,4094,64512",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               testduration          => "5",
               maxthroughput         => "700",
            },
            'VerifyPlacement' => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1-2].vnic.[1]",
               nicplacement => "1",
            },
         },
      },
      'NicPlacementNoTeaming'   => {
         TestName         => 'NicPlacementNoTeaming',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify vnic placement on a vmnic with no ' .
                             'teaming enabled',
         Procedure        => '1. Configure reservation on a network adapter ' .
                             '2. Disable teaming on the VDS ' .
                             '3. Power on the VM',
         ExpectedResult   => 'Vnic should successfully be placed on a vmnic ' .
                             'and the traffic should go through the same vmnic',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'lkutik',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_FiveVMs_NETIOC_Teaming,

         WORKLOADS => {
         Sequence => [
                      ['VerifyPlacement']
                      ],
         'VerifyPlacement' => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1-2].vnic.[1],",
               nicplacement => "1",
            },
         },
      },
      'NicPlacementWithTeaming'   => {
         TestName         => 'NicPlacementWithTeaming',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify vnic placement on a vmnic teaming with ' .
                             'all different hashing algorithms',
         Procedure        => '1. Configure reservation on a vnic ' .
                             '2. Configure teaming on the VDS ' .
                             '3. Power on the VM and check the vnic placement ' .
                             'meets the bandwidth requirement instead of ' .
                             'teaming algorithm' .
                             '4. Configure another vnic with no reservation' ,
         ExpectedResult   => 'When reservation is configured, then active' .
                             'should be selected based on bandwidth ' .
                             'requirements. For vnic with no reservation, ' .
                             'the active uplink should be based on legacy ' .
                             'teaming policy',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
          vc => {
              '[1]' => {
                datacenter => {
                     '[1]' => {
                          'host' => 'host.[1]'
                     },
                },
                dvportgroup => {
                   '[1]' => {
                       'vds' => 'vc.[1].vds.[1]',
                            dvport  => {
                              '[1-10]' => {
                              },
                            },
                   },
                   '[2]' => {
                       'vds' => 'vc.[1].vds.[2]',
                            dvport   => {
                                '[1-10]' => {
                                },
                            },
                       },
                 },

                 vds => {
                    '[1]' => {
                       'datacenter' => 'vc.[1].datacenter.[1]',
                       'vmnicadapter' => 'host.[1].vmnic.[1-2]',
                       'configurehosts' => 'add',
                       'host' => 'host.[1]',
                       'nioc' =>'enable',
                       'numuplinkports' => 2,
                       'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
                       'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                       'niocinfrastructuretraffic'  => {
                            'virtualMachine' => "750:100:1000",
                        },

                     },
                     '[2]' => {
                        'datacenter' => 'vc.[1].datacenter.[1]',
                        'vmnicadapter' => 'host.[1].vmnic.[3]',
                        'configurehosts' => 'add',
                        'host' => 'host.[1]',
                        'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                     },
                 },
               },
            },
            host => {
                 '[1]' => {
                    vmnic => {
                         '[1-3]' => {
                              'driver' => 'any'
                         },
                     },
                  },
            },
              vm => {
                 '[1-4]' => {
                     vnic => {
                         '[1]' => {
                              'portgroup' => 'vc.[1].dvportgroup.[1]',
                              'driver' => 'vmxnet3',
                              shares      => "50",
                              reservation => "100",
                              limit       => "1000",
                              connected   => 1,
                              startconnected    => 1,
                              allowguestcontrol => 1,
                        },
                    },
                    'host' => 'host.[1]'
                  },
                  '[5]' => {
                       vnic => {
                             '[1]' => {
                                  'portgroup' => 'vc.[1].dvportgroup.[2]',
                                  'driver' => 'vmxnet3',
                             },
                       },
                       'host' => 'host.[1]'
                   },
            },

         },
         WORKLOADS => {
         Sequence => [
                      ['ConfigTeaming'],
                      ['VerifyPlacement'],
                      ['ConfigTeamingIPHash'],
                      ['VerifyPlacement'],
                      ['ConfigTeamingexplict'],
                      ['VerifyPlacementforfailover'],
                      ['ConfigTeaminglinkstatus'],
                      ['VerifyPlacementforfailover'],
                       ],
          'ConfigTeaming' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'lbpolicy' => 'portid',
              'notifyswitch' => 'yes',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
           'ConfigTeamingIPHash' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'lbpolicy' => 'iphash',
              'notifyswitch' => 'yes',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
            'ConfigTeamingexplict' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'standbynics' => 'host.[1].vmnic.[2]',
              'lbpolicy' => 'explicit',
              'notifyswitch' => 'yes',
              'failover' => 'beaconprobing',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]'
            },
            'ConfigTeaminglinkstatus' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'failback' => 'yes',
              'standbynics' => 'host.[1].vmnic.[2]',
              'lbpolicy' => 'explicit',
              'failover' => 'linkstatusonly',
              'confignicteaming' => 'vc.[1].dvportgroup.[1]',
              'notifyswitch' => 'yes'
            },
           'VerifyPlacement' => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1-4].vnic.[1],",
               nicplacement => "1",
            },
           'VerifyPlacementforfailover' => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1-4].vnic.[1],",
               nicplacement => "host.[1].vmnic.[1]",
            },
        },
      },
      'NicPlacementChanges'   => {
         TestName         => 'NicPlacementChanges',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify vnic placement changes due to vnic\'s ' .
                             'bandwidth and available bandwidth changes',
         Procedure        => '1. Saturate available VM bandwidth on uplinks ' .
                             'using multiple vnics ' .
                             '2. Trigger vnic placement algorithm by changing ' .
                             'vnic reservation values. Verify that every vnic' .
                             'gets a vmnic assigned' .
                             '3. Enable/disable vmnic to verify the changes ' .
                             ' in vnic placement',
         ExpectedResult   =>  'Vnic should be placed successfully on a vmnic',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationStatus => 'Automated',
         Tags             => 'automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
           'vc' => {
                  '[1]' => {
                    'datacenter' => {
                           '[1]' => {
                                     'host' => 'host.[1]'
                            }
                   },
                   'dvportgroup' => {
                           '[1]' => {
                                     'vds' => 'vc.[1].vds.[1]',
                                       dvport   => {
                                              '[1-20]' => {
                                        }
                                      },
                          }
                   },
                   'vds' => {
                      '[1]' => {
                                'datacenter' => 'vc.[1].datacenter.[1]',
                                'vmnicadapter' => 'host.[1].vmnic.[1]',
                                'configurehosts' => 'add',
                                'host' => 'host.[1]',
                                'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
                                'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                                'niocinfrastructuretraffic'  => {
                                    'virtualMachine' => "500:100:1000",
                                },
                     }
                 }
              }
           },
           'host' => {
               '[1]' => {
                 'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                 }
               }
           },
           'vm' => {
            '[1]' => {
               'vnic' => {
                  '[1-2]' => {
                      'portgroup' => 'vc.[1].dvportgroup.[1]',
                      'driver' => 'vmxnet3',
                       shares      => "50",
                       reservation => "100",
                       limit       => "1000",
                       connected   => 1,
                       startconnected    => 1,
                       allowguestcontrol => 1,
                  }
               },
               'host' => 'host.[1]'
           },
          }

        },
        WORKLOADS => {
        Sequence => [
                      [VerifyPlacement],
                      [AddVnics],
                      [ReVerifyPlacement],
                      [RemoveVnics],
                     ],

            VerifyPlacement => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1-2]",
               nicplacement => "1",
            },
            AddVnics => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[3-6]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3',
                           shares      => "50",
                           reservation => "50",
                           limit       => "1000",
                           connected   => 1,
                           startconnected    => 1,
                           allowguestcontrol => 1,
		        }
		      }
            },
            RemoveVnics => {
               Type       => "VM",
               TestVM     => "vm.[1]",
               deletevnic => "vm.[1].vnic.[3-6]"
            },
            ReVerifyPlacement => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1-6]",
               nicplacement => "1",
            },
         },
      },
      'VMConfigVSSToVDS'  => {
         TestName         => '',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify the NIOC behavior while changing ' .
                             'between vss and vds',
         Procedure        => '1. Configure vnic with SLR and backend as VSS ' .
                             'portgroup. Verify SLR configuration is ignored ' .
                             '2. While the VM is powered on, change vnic ' .
                             'network to a dvportgroup which has NIOC enabled',
         ExpectedResult   => 'Vnic should be placed on vmnic and SLR ' .
                             'configuration should be honored when connected ' .
                             'to a VDS',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHostNIOCv3VDS,
         WORKLOADS => {
            Sequence => [
                ['SetVMReservation'],
                ['EditReservation1'],
                ['VerifyPlacementPos'],
                ['CreateVSSBacking'],
                ['ChangeBackingToVSS'],
                ['VerifyPlacementNeg'],
                ['ChangeBackingToVDS'],
                ['VerifyPlacementPos'],
               ],

            SetVMReservation => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               niocinfrastructuretraffic  => {
                  'virtualMachine' => "500:100:1000",
               },
            },
            EditReservation1 => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "100",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            CreateVSSBacking => {
               Type  => "Host",
               TestHost => "host.[1]",
               vss => {
                  '[1]'   => { # create VSS
                  },
               },
               portgroup => {
                  '[1]' => {
                     vss  => "host.[1].vss.[1]",
                  },
               },
            },
            ChangeBackingToVSS => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               portgroup   => "host.[1].portgroup.[1]",
            },
            ChangeBackingToVDS => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            VerifyPlacementPos => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "1",
            },
            VerifyPlacementNeg => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "0",
               ExpectedResult => "FAIL",
            },
         },
      },
      'EnableDisableNIOC'   => {
         TestName         => 'VMConfigEnableDisableNIOC',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Enable, disable NIOC on VDS in a loop ',
         Procedure        => '1. Configure SLR on a vnic attached to a ' .
                             'dvportgroup which has NIOC enabled ' .
                             '2. Disable and enable NIOC on VDS in a loop ',
         ExpectedResult   => 'When NIOC is disabled SLR should be ignored and ' .
                             'after multiple iterations the vnic/vm/host ' .
                             'be functional',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHostNIOCv3VDS,
         WORKLOADS => {
         Sequence => [
                     ['SetVMReservation'],
                     ['EditReservation'],
                     ['DisableNIOC'],
                     ['VerifyPlacementNeg'],
                     ['EnableNIOC'],
                     ['VerifyPlacementPos']
                     ],
            SetVMReservation => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               niocinfrastructuretraffic  => {
                  'virtualMachine' => "500:100:1000",
               },
            },
            EditReservation => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "100",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            VerifyPlacementPos => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "1",
            },
            VerifyPlacementNeg => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "0",
            },
            EnableNIOC => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               nioc  => "enable",
            },
            DisableNIOC => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               nioc  => "disable",
            },
         },
      },
      'VMConfigVDSNoUplink'   => {
         TestName         => 'VMConfigVDSNoUplink',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify VDS with NIOC and no uplinks does ' .
                             'ignores SLR configuration on vNic.',
         Procedure        => '1. Configure vnic with dvportgroup which ' .
                             'has NIOC enabled and no uplinks.',
         ExpectedResult   => 'SLR configuration on vnic should be ignored  ' .
                             'and regular VM to VM traffic on same host ' .
                             'should work.',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHostNIOCv3VDS,
         WORKLOADS => {
            Sequence => [
               ['SetVMReservation'],
               ['EditReservation'],
               ['VerifyPlacementPos'],
               ['DisableUplink'],
               ['VerifyPlacementNeg'],
               ['EnableUplink'],
               ['VerifyPlacementPos']
               ],
         ExitSequence => [['EnableUplink']],
            SetVMReservation => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               niocinfrastructuretraffic  => {
                  'virtualMachine' => "500:100:1000",
               },
            },
            EditReservation => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "100",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            DisableUplink => {
               Type         => "NetAdapter",
               TestAdapter  => "host.[1].vmnic.[1]",
               DeviceStatus   => "DOWN",
            },
            EnableUplink => {
               Type         => "NetAdapter",
               TestAdapter  => "host.[1].vmnic.[1]",
               DeviceStatus   => "UP",
            },
            VerifyPlacementPos => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "1",
            },
            VerifyPlacementNeg => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "0",
            },
         },
      },
      'AdmissionControlConnectDisconnectVNic'   => {
         TestName         => 'AdmissionControlConnectDisconnectVNic',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Connect/disconnect adapter and check vnic ' .
                             'placement and pnic bandwidth.',
         Procedure        => '1. Configure reservation on a vnic and add to ' .
                             'to a dvportgroup that has NIOC enabled. ' .
                             '2. Add more adapters to the saturate available ' .
                             'bandwidth ' .
                             '3. Verify the nic placement on vmnic. ' .
                             '4. Disconnect the vnic and move the reserved ' .
                             'bandwidth to another vnic' .
                             '4. Now, change the connection status of the ' .
                             'test vnic',
         ExpectedResult   => 'Expect error since the bandwidth originally ' .
                             'reserved on test vnic cannot be allocated',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'lkutik',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_TwoVMs_NETIOC,
         WORKLOADS => {
         Sequence => [
                       ['AddVnics'],
                       ['VerifyPlacement'],
                       ['DisconnectvNic'],
                       ['AddVnic6'],
                       ['VerifyPlacementafterDisconnect'],
                       ['ConnectvNic']
                       ],

         ExitSequence => [ ['DeletevNic']],

         "AddVnics" => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[3-5]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3',
                           shares      => "50",
                           reservation => "100",
                           limit       => "1000",
                           connected   => 1,
                           startconnected    => 1,
                           allowguestcontrol => 1,
		        }
		      }
         },
         "AddVnic6" => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[6]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3',
                           shares      => "50",
                           reservation => "100",
                           limit       => "1000",
                           connected   => 1,
                           startconnected    => 1,
                           allowguestcontrol => 1,
		        },
		      },
         },
         VerifyPlacement => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1-5]",
               nicplacement => "1",
         },
         VerifyPlacementafterDisconnect => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[2-6]",
               nicplacement => "1",
         },
         "DisconnectvNic" => {
               Type        => "NetAdapter",
               reconfigure => "true",
               TestAdapter => "vm.[1].vnic.[1]",
               connected   =>  0,
         },
         "ConnectvNic" => {
               Type        => "NetAdapter",
               reconfigure => "true",
               TestAdapter => "vm.[1].vnic.[1]",
               connected   => 1 ,
               ExpectedResult => "FAIL",
         },
         "DeletevNic" => {
               Type           => "VM",
               TestVM         => "vm.[1]",
               deletevnic     => "vm.[1].vnic.[3-5]",
         },
        },
      },
      'AdmissionControlEnableDisableVNic'   => {
         TestName         => 'AdmissionControlEnableDisableVNic',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Enable/disable adapter and check vnic ' .
                             'placement and pnic bandwidth ',
         Procedure        => '1. Configure reservation on a vnic and add to ' .
                             'to a dvportgroup that has NIOC enabled. ' .
                             '2. Add more adapters to the saturate available ' .
                             'bandwidth ' .
                             '3. Verify the nic placement on vmnic. ' .
                             '4. Disable the vnic and move the reserved ' .
                             'bandwidth to another vnic' .
                             '4. Now, change the device status of the ' .
                             'test vnic',
         ExpectedResult   => 'Expect error since the bandwidth originally ' .
                             'reserved on test vnic cannot be allocated',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'lkutik',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_TwoVMs_NETIOC,
         WORKLOADS => {
         Sequence => [
                      ['AddVnics'],
                       ['VerifyPlacement'],
                       ['DisablevNic'],
                       ['VerifyPlacementNeg'],
                       ['AddVnic6'],
                       ['VerifyPlacementafterDisconnect'],
                       ['EnablevNic'],
                      ],
         ExitSequence => [ ['DeletevNic']],
         "AddVnics" => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[3-5]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3',
                           shares      => "50",
                           reservation => "100",
                           limit       => "1000",
                           connected   => 1,
                           startconnected    => 1,
                           allowguestcontrol => 1,
		        }
		      }
         },
         "AddVnic6" => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[6]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3',
                           shares      => "50",
                           reservation => "100",
                           limit       => "1000",
                           connected   => 1,
                           startconnected    => 1,
                           allowguestcontrol => 1,
		        },
		      },
         },
         VerifyPlacement => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1-5]",
               nicplacement => "1",
         },
         VerifyPlacementNeg => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "0",
         },
         VerifyPlacementafterDisconnect => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[2-6]",
               nicplacement => "1",
         },
         "DisablevNic" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               devicestatus   => "DOWN",
         },
         "EnablevNic" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               devicestatus   => "UP",
               ExpectedResult => "FAIL",
         },
         "DeletevNic" => {
               Type           => "VM",
               TestVM         => "vm.[1]",
               deletevnic     => "vm.[1].vnic.[3-5]",
         },
        },
      },
      'AdmissionControlSuspendResumeVM'   => {
         TestName         => 'AdmissionControlSuspendResumeVM',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Check admission control after suspend/resume VM',
         Procedure        => '1. Configure reservation on a vnic and add to ' .
                             'to a dvportgroup that has NIOC enabled. ' .
                             '2. Add more adapters to the saturate available ' .
                             'bandwidth ' .
                             '3. Verify the nic placement on vmnic. ' .
                             '4. Suspend the VM and move the reserved ' .
                             'bandwidth to another vnic' .
                             '4. Now, resume the VM ',
         ExpectedResult   => 'Expect error since the bandwidth originally ' .
                             'reserved on test vnic cannot be allocated',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         PMT              => '4084',
         AutomationLevel  => 'automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'lkutik',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_TwoVMs_NETIOC,
         WORKLOADS => {
         Sequence => [
                       ['AddVnicsVM1'],
                       ['VerifyPlacement'],
                       ['SuspendVM'],
                       ['VerifyPlacementNeg'],
                       ['AddVnicsVM2'],
                       ['VerifyPlacementafterSuspend'],
                       ['ResumeVM'],
                      ],

         "AddVnicsVM1" => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[1]',
		      'vnic' => {
		        '[3-5]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[1]',
		          'driver' => 'vmxnet3',
                           shares      => "50",
                           reservation => "100",
                           limit       => "1000",
                           connected   => 1,
                           startconnected    => 1,
                           allowguestcontrol => 1,
		        }
		      }
         },
         "AddVnicsVM2" => {
		      'Type' => 'VM',
		      'TestVM' => 'vm.[2]',
		      'vnic' => {
		        '[2-6]' => {
		          'portgroup' => 'vc.[1].dvportgroup.[2]',
		          'driver' => 'vmxnet3',
                           shares      => "50",
                           reservation => "100",
                           limit       => "1000",
                           connected   => 1,
                           startconnected    => 1,
                           allowguestcontrol => 1,
		        }
		      }
         },
         VerifyPlacement => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1-5]",
               nicplacement => "1",
         },
         VerifyPlacementNeg => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1-5]",
               nicplacement => "0",
         },
         VerifyPlacementafterSuspend => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[2].vnic.[2-6]",
               nicplacement => "1",
         },
         "SuspendVM" => {
               Type           => "VM",
               TestVM         => "vm.[1]",
               vmstate        => "suspend",
         },
         "ResumeVM" => {
               Type           => "VM",
               TestVM         => "vm.[1]",
               TestAdapter    => "vm.[1].vnic.[1-5]",
               Operation      => "resume",
               ExpectedResult => "FAIL",
         },
         },
      },
      'AdmissionControlSnapshotRevertVM'   => {
         TestName         => 'AdmissionControlSnapshotRevertVM',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Check admission control with snapshot/revert ' .
                             'operation',
         Procedure        => '1. Configure SLR on VM1 ' .
                             '2. Snapshot VM1 at this state A ' .
                             '3. Revert to state before  A ' .
                             '4. Release the free bandwidth to another VM2 ' .
                             '5. Revert the VM1 to state A ',
         ExpectedResult   => 'Expect error since the bandwidth originally ' .
                             'reserved on test vnic cannot be allocated',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'AdmissionControlChangeGuestState'   => {
         TestName         => 'AdmissionControlChangeGuestState',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'sleep/standby/hibernate and resume and check vnic
         placement' .
                             ' '.
                             ' ',
         Procedure        => '1. Configure reservation on a vnic and add to ' .
                             'to a dvportgroup that has NIOC enabled. ' .
                             '2. Add more adapters to the saturate available ' .
                             'bandwidth ' .
                             '3. Verify the nic placement on vmnic. ' .
                             '4. Put the guest to sleep and move the reserved ' .
                             'bandwidth to another vnic' .
                             '4. Now, resume the VM and expect error since ' .
                             'the bandwidth originally reserved on test vnic ' .
                             'cannot be allocated' .
                             '5. Repeat the steps above with standby and ' .
                             'hibernate operations on the guest',
         ExpectedResult   => 'Expect error since the bandwidth originally ' .
                             'reserved on test vnic cannot be allocated',
         Status           => 'Execution Ready',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VMConfigChangeSLR'   => {
         TestName         => 'VMConfigChangeSLR',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Configure different values of SLR',
         Procedure        => '',
         ExpectedResult   => 'SLR configured is expected to work at the end ' .
                             'of all different changes and no host/vm crash',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHostNIOCv3VDS,
         WORKLOADS => {
         Sequence => [
                     ['SetVMReservation'],
                     ['EditReservationPos1'],
                     ['EditReservationNeg1'],
                     ['EditLimits1'],
                     ['EditLimitsNeg'],
                     ['EditSharesPos'],
                     ['EditSharesNeg1'],
                     ['EditSharesNeg2'],
                     ['EditBadReservation'],
                     ],
            SetVMReservation => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               niocinfrastructuretraffic  => {
                  'virtualMachine' => "500:100:1000",
               },
            },
            EditReservationPos1 => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "0-500,50",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            EditReservationNeg1 => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "-1",
               portgroup   => "vc.[1].dvportgroup.[1]",
               ExpectedResult => "FAIL",
            },
            EditLimits1 => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               limit       => "1-500,50",
               reservation => "0",
               portgroup   => "vc.[1].dvportgroup.[1]",
            },
            EditLimitsLarge => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               limit       => "100001",
               reservation => "0",
               portgroup   => "vc.[1].dvportgroup.[1]",
           },
            EditLimitsNeg => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               limit       => "0",
               portgroup   => "vc.[1].dvportgroup.[1]",
               ExpectedResult => "FAIL",
           },
            EditSharesPos => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               shares      => "0-100,25",
               portgroup   => "vc.[1].dvportgroup.[1]",
           },
            EditSharesNeg1 => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               shares      => "-1",
               portgroup   => "vc.[1].dvportgroup.[1]",
               ExpectedResult => "FAIL",
           },
            EditSharesNeg2 => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               shares      => "101",
               portgroup   => "vc.[1].dvportgroup.[1]",
               ExpectedResult => "FAIL",
           },
            EditBadReservation => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               limit       => "10",
               reservation => "20", # reservation greater than limit
               portgroup   => "vc.[1].dvportgroup.[1]",
               ExpectedResult => "FAIL",
           },
            VerifyPlacementPos => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "1",
            },
         },
      },
      'VMConfigCheckPersistence'   => {
         TestName         => 'VMConfigCheckPersistence',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Check SLR persistence test after rebooting ' .
                             'guest, reset vm, driver reload and host reboot ',
         Procedure        => '1. Configure SLR on a vnic which is connected ' .
                             'to a portgroup that has NIOC enabled ' .
                             '2. Verify that SLR values are honored ' .
                             '3. Reboot the guest OS and check if the ' .
                             'configuration is persistent' .
                             '4.Repeat the steps above with VM reset and ' .
                             'host reset',
         ExpectedResult   => 'SLR configuration should be persistent',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'NicPlacementChangeVmnicState'   => {
         TestName         => 'NicPlacementChangeVmnicState',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify placement by changing vmnic ' .
                             'link state, device state and ' .
                             'and reloading  driver ',
         Procedure        => '1. Configure SLR on a vnic connected to ' .
                             'a portgroup with NIOC enabled  ' .
                             '2. Verify vnic placement on vmnic ' .
                             '3. Change the device state of vmnic ' .
                             ' and verify vnic placement ' .
                             '4. Change the link state of vmnic ' .
                             ' and verify vnic placement ' .
                             '5. Reload vmnic driver',
         ExpectedResult   => 'Vnic should be placed successfully',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'NicPlacementLimits'   => {
         TestName         => 'NicPlacementLimits',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify nic placement can be successful ' .
                             'at large scale ',
         Procedure        => '1. Enable NIOC v3 on a VDS ' .
                             '2. Add 2 10G uplink ports to VDS from same host ' .
                             '3. Configure maximum possible value for ' .
                             'vm traffic ' .
                             '4. Divide the aggregate VM bandwidth on this ' .
                             'host to Y Mbps, create the result X number of ' .
                             'vnic ports each with Y Mbps reservation',
         ExpectedResult   => 'Verify that the nic placement is successful ' .
                             'for all X vnic ports and run IO to verify' .
                             'bandwidth requirements are met',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'StressOptionZeroBandwidth'   => {
         TestName         => 'StressOptionZeroBandwidth',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Stress option to simulate zero bandwidth on ' .
                             'uplinks',
         Procedure        => '1. Verify admission control by enabling stress ' .
                             'option to simulate zero bandwidth',
         ExpectedResult   => 'VM should fail to power on due to lack of ' .
                             'resources',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'InterOpLACP'   => {
         TestName         => 'InterOpLACP',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Perform NIOC-LACP interop test',
         Procedure        => 'TBD',
         ExpectedResult   => 'TBD',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'InterOpCDPAndLLDP'   => {
         TestName         => 'InterOpCDPAndLLDP',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify the interop between NIOC and ' .
                             'CDP, LLDP ',
         Procedure        => ' ' .
                             ' '.
                             ' ',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'InterOPSRIOV'   => {
         TestName         => 'InterOPSRIOV',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify interop between NIOC and ' .
                             'SRIOV, FPT ',
         Procedure        => 'TBD' .
                             ' '.
                             ' ',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'VCAdmissionControlWithDRS'   => {
         TestName         => 'VCAdmissionControlWithDRS',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Test admission control and nic placement ' .
                             'using basic DRS setup ',
         Procedure        => '1. Create a cluster with 2 hosts ' .
                             'and enable DRS on it' .
                             '2. Configure a vm with reservation equal to ' .
                             'available pnic bandwith for vm traffic on ' .
                             'host 1' .
                             '3. Configure another vm with reservation more ' .
                             'than available pnic bandwith for vm traffic ' .
                             'on host 1.',
         ExpectedResult   => 'DRS should place the second VM on host 2 ',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'DRSClusterWithNoResource'   => {
         TestName         => 'DRSClusterWithNoResource',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Enable DRS with no uplinks/resource on ' .
                             'second host',
         Procedure        => '1. Create a cluster with 2 hosts and DRS ' .
                             'enabled ' .
                             '2. Saturate available bandwidth on host 1 & 2 ' .
                             '3. Power on another VM on host 1 ',
         ExpectedResult   => 'DRS placement should fail since there is ' .
                             'available bandwidth on second host',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'InterOpPortgroupShaper'   => {
         TestName         => 'InterOpPortgroupShaper',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify InterOP between portgroup shaper ' .
                             'and limits configured on vnic port ',
         Procedure        => '1. Enable NIOC on a VDS ' .
                             '2. Enable portgroup shaper on same VDS ' .
                             '3. Set the value of vnic limit greater than ' .
                             'limit value on portgroup shaper ' .
                             '4. Set the value of portgroup limit greater ' .
                             'than the vnic limit value' .
                             '5. Repeat the steps above for values ranging ' .
                             'from 0 to vmnic link speed',
         ExpectedResult   => 'Verify that the avg bandwidth from vnic does ' .
                             'not exceed the minimum of portgroup shaper ' .
                             'limit and vnic limit',
         Status           => 'Execution Ready',
         Tags             => 'automated',
         Tags             => 'physicalonly',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHost_TwoVMs_NETIOC,
         WORKLOADS => {
         Sequence => [
                      ['EditVniclimit100'],
                      ['EnableShaping100'],
                      ['Traffic100'],
                      ['EditVniclimit200'],
                      ['EnableShaping100'],
                      ['Traffic100'],
                      ['EditVniclimit100'],
                      ['EnableShaping200'],
                      ['Traffic100'],
                      ['EditVniclimit500'],
                      ['EnableShaping200'],
                      ['Traffic200'],
                      ['EditVniclimit200'],
                      ['EnableShaping500'],
                      ['Traffic200'],
                     ],
            'EnableShaping100' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'peakbandwidth' => '100000',
              'avgbandwidth' => '100000',
              'enableoutshaping' => 'vc.[1].dvportgroup.[1]',
              'burstsize' => '100000'
            },
            'EnableShaping500' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'peakbandwidth' => '500000',
              'avgbandwidth' => '500000',
              'enableoutshaping' => 'vc.[1].dvportgroup.[1]',
              'burstsize' => '500000'
            },
            Traffic100 => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               parallelsession       => "yes",
               TestAdapter           => "vm.[1].vnic.[1-2]",
               SupportAdapter        => "vm.[2].vnic.[1]",
               L3Protocol            => "ipv4,ipv6",
               L4Protocol            => "tcp",
               NoofOutbound           => "1",
               SendMessageSize       => "64512",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               testduration          => "10",
               maxthroughput         => '100',
            },
            Traffic200 => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               parallelsession       => "yes",
               TestAdapter           => "vm.[1].vnic.[1-2]",
               SupportAdapter        => "vm.[2].vnic.[1]",
               L3Protocol            => "ipv4,ipv6",
               L4Protocol            => "tcp",
               NoofOutbound           => "1",
               SendMessageSize       => "64512",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               testduration          => "10",
               maxthroughput         => '200',
            },
            EditVniclimit200 => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1-2]",
               reconfigure => "true",
               limit => "200",
            },
            EditVniclimit100 => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1-2]",
               reconfigure => "true",
               limit => "100",
            },
            EditVniclimit500 => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1-2]",
               reconfigure => "true",
               limit => "500",
            },

            'EnableShaping200' => {
              'Type' => 'Switch',
              'TestSwitch' => 'vc.[1].vds.[1]',
              'peakbandwidth' => '200000',
              'enableoutshaping' => 'vc.[1].dvportgroup.[1]',
              'avgbandwidth' => '200000',
              'burstsize' => '200000'
            },
         },
      },
      'InteropVMotion'   => {
         TestName         => 'InteropVMotion',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Vmotion a VM1 from host A and B under valid ' .
                             'scenario and also after the pre-check is passed ' .
                             'release the resource on host B to some other ' .
                             'VM and do vmotion',
         Procedure        => '1. Configure a SLR on a VM ' .
                             '2. Vmotion this VM from host A to B ' .
                             '3. Verify SLR is still honored on host B ' .
                             '4. From host B, trigger vmotion to host B ' .
                             '5. After the pre-check is passed, saturate the ' .
                             'resources on host A and do vmotion ',
         ExpectedResult   => 'VMotion is expected to fail and VM should ' .
                             'function correctly on host B',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'InterOpVCOps'   => {
         TestName         => 'InterOpVCOps',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify the interop between NIOC and ' .
                             'VCOps stats ',
         Procedure        => '1. Configure NIOC on a VDS ' .
                             '2. Configure SLR on a vnic and initiate ' .
                             'IO sessions ',
         ExpectedResult   => 'All the stats that are exposed to VCOps should' .
                             'reflect the correction information',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'InterOpVxLAN'   => {
         TestName         => 'InterOpVxLAN',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify interop between NIOC and VxLAN',
         Procedure        => 'TBD' .
                             ' ' .
                             ' ',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'ResourcePoolAddRemove'   => {
         TestName         => 'ResourcePoolAddRemove',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Add and remove resource pool and check if ' .
                             'the available bandwidth changes accordingly ',
         Procedure        => '1. Add a resource pool on a VDS with ' .
                             'NIOC v3 ' .
                             '2. Verify the changes in available aggregate ' .
                             'bandwidth ' .
                             '3. Remove the resource pool added in step 1 ' .
                             'and verify changes in aggregate bandwidth ' .
                             '4. Repeat the steps above multiple times',
         ExpectedResult   => 'Aggregate bandwidth value is expected to change ' .
                             'when resource pools are added/removed',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'ResourcePoolVmnicChanges'   => {
         TestName         => 'ResourcePoolVmnicChanges',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Connect/disconnect uplinks on DVS and check ' .
                             'aggregate bandwidth value changes',
         Procedure        => '1. Add a resource pool on a VDS with ' .
                             'NIOC v3 ' .
                             '2. Verify the changes in available aggregate ' .
                             'bandwidth ' .
                             '3. Now disconnect or disable the uplinks on ' .
                             'VDS',
         ExpectedResult   => 'Expect warnings/errors that the resource pool ' .
                             'configurations are invalid',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'ResourcePoolLimits'   => {
         TestName         => 'ResourcePoolLimits',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Create maximum (TBD) of resource pools with ' .
                             'with smaller bandwidth reservations ',
         Procedure        => '1. Allocate reservation for VM traffic ' .
                             '2. Create maximum possible number of resource ' .
                             'pools with smaller bandwidth requirements ',
         ExpectedResult   => 'Resource pools should be created successfully',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'ResourcePoolVnicLimits'   => {
         TestName         => 'ResourcePoolVnicLimits',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify dvportgroups limit per VDS',
         Procedure        => '1. Create 256 portgroups and associate them ' .
                             'with 256 resource pools ' .
                             '2. Add one vnic per portgroup' .
                             '3. Run IO traffic from all vnic ports ',
         ExpectedResult   => 'Expect no failure in the IO sessions and ' .
                             'SLR values should be honored',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'ResourcePoolSmallVmnics'   => {
         TestName         => 'ResourcePoolSmallVmnics',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'Verify that addition of an uplink ' .
                             'with link speed less than the total ' .
                             'infrastructure traffic reservation is ' .
                             'prohibited',
         Procedure        => '1. Create a VDS with NIOC v3 ' .
                             '2. Add one 10G uplink to the VDS ' .
                             '3. Configure infrastructure traffic ' .
                             'reservation equally between all traffic ' .
                             '4. Now, add a 1G uplink to this VDS',
         ExpectedResult   => 'Adding 1G uplink should throw error since ' .
                             'this uplink cannot meet the reservation ' .
                             'configured already on VDS',
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '4084',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Partnerfacing    => 'N',
         Duration         => '100',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
         },
         WORKLOADS => {
         Sequence => [],
         },
      },
      'BasicPlacement'   => {
         TestName         => 'BasicPlacement',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify vnics are placed successfully ' .
                             'on vmnic based on reservation ',
         Tags             => 'automated,sanity',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with NIOC enabled ' .
                             '2. Add one uplink to the VDS and configure ' .
                             '   500Mbps reservation for VM traffic ' .
                             '3. Deploy a VM and configure reservation ' .
                             '4. Power on the VM and verify vnic is placed ',
         ExpectedResult   => 'Vnic should be placed successfully ' ,
         Status           => 'complete',
         AutomationLevel  => 'automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneHostNIOCv3VDS,
         WORKLOADS => {
            Sequence        => [
                                 ['SetVMReservation'],
                                ['EditReservation'],
                                ['VerifyPlacement'],
                                ],
            SetVMReservation => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               niocinfrastructuretraffic  => {
                  'virtualMachine' => "500:100:1000",
               },
            },
            VerifyPlacement => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               nicplacement => "1",
            },
            EditReservation => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               reconfigure => "true",
               reservation => "100",
            },
         },
      },
      'JumboFrames'   => {
         TestName         => 'JumboFrames',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify vnics are placed successfully ' .
                             'on vmnic based on reservation and ' .
                             'jumbo frames configuratio works fine',
         Tags             => 'scheduler,sanity',
         PMT              => '4084',
         ExpectedResult   => 'Vnic entitlement for all the vnics ' ,
         Status           => 'complete',
         AutomationLevel  => 'automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
			               host  => "host.[1-2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter     => "vc.[1].datacenter.[1]",
                        version        => "6.0.0",
                        configurehosts => "add",
                        host           => "host.[1-2]",
                        vmnicadapter   => "host.[1].vmnic.[2]",
                        niocversion    => "3.0",
                        niocinfrastructuretraffic  => {
                           'virtualMachine' => "750:100:1000",
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                   vss => {
                     '[1]'   => { # create VSS
                        vmnicadapter     => "host.[1].vmnic.[1]",
                        configureuplinks => "add",
		               },
                  },
                  portgroup => {
                     '[1]' => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                   vss => {
                     '[1]'   => { # create VSS
                        vmnicadapter     => "host.[2].vmnic.[1]",
                        configureuplinks => "add",
		               },
                  },
                  portgroup => {
                     '[1]' => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
		            host  => "host.[1].x.[1]",
                  vnic => {
                     '[1]'   => {
                        driver	   => "e1000",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        shares      => "50",
                        reservation => "450",
                        limit       => "1000",
                        connected   => 1,
                        startconnected    => 1,
                        allowguestcontrol => 1,
                     },
                  },
               },
               '[2-4]'   => {
		            host  => "host.[1].x.[1]",
                  vnic => {
                     '[1]'   => {
                        driver	   => "e1000",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        shares      => "50",
                        reservation => "100",
                        limit       => "1000",
                        connected   => 1,
                        startconnected    => 1,
                        allowguestcontrol => 1,
                     },
                  },
               },
               '[5-8]'   => {
		            host  => "host.[2].x.[1]",
                  vnic => {
                     '[1]'   => {
                        driver	   => "e1000",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        connected   => 1,
                        startconnected    => 1,
                        allowguestcontrol => 1,
                     },
                  },
               },
             },
         },
         WORKLOADS => {
            Sequence        => [
                                ['VerifyPlacement'],
                                ['SetMTU', 'SetVnicMTU'],
                                ['TCPTraffic']
                               ],
            SetMTU => {
               Type => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               mtu => "9000",
            },
            SetVnicMTU => {
               Type => "NetAdapter",
               TestAdapter => "vm.[1-8].vnic.[1]",
               mtu => "9000",
               configure_offload =>{
                  offload_type => "tsoipv4",
                  enable'      => "false",
               },
            },

            VerifyPlacement => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-4].vnic.[1]",
               nicplacement => "1",
            },

            TCPTraffic => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               maxtimeout            => "5000",
               parallelsession       => "yes",
               TestAdapter           => "vm.[1-4].vnic.[1]",
               SupportAdapter        => "vm.[5-8].vnic.[1]",
               L3Protocol            => "ipv4,ipv6",
               L4Protocol            => "tcp", # udp
               NoofOutbound          => "1",
               SendMessageSize       => "1024,4096,8192," .
                                        "16384,64512",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               testduration          => "60",
               Verification   => "Verification",
            },
            "Verification" => {
               'NIOCVerificaton' => {
                  verificationtype => "NIOC",
                  target           => "srcVM",
                  uplinks          => "host.[1].vmnic.[2]",
               },
            },
         },
      },

      'EnableDisableStress'   => {
         TestName         => 'EnableDisableStress',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify that NIOC  settings ' .
                             ' are intact after 100 iterations of'.
                             'enable/disable',
         Tags             => '',
         PMT              => '4084',
         Procedure        => '1. Create a 6.0 vDS with a NIOC enabled/version2 ' .
                             '2. Power on 1 VM wit slr configure'.
                             '3. enable/disable using version3 100 times' .
                             '3. Verify no PSOD or no issues' ,
         Status           => 'Draft',
         FullyAutomatable => 'Y',
         AutomationStatus => 'Automated',
         Tags             => 'automated',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'steve',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec      => {
           'vc' => {
                  '[1]' => {
                    'datacenter' => {
                           '[1]' => {
                                     'host' => 'host.[1]'
                            }
                   },
                   'dvportgroup' => {
                           '[1]' => {
                                     'vds' => 'vc.[1].vds.[1]',
                                       dvport   => {
                                              '[1-3]' => {
                                        }
                                      },
                           }
                   },
                   'vds' => {
                      '[1]' => {
                                'datacenter' => 'vc.[1].datacenter.[1]',
                                'vmnicadapter' => 'host.[1].vmnic.[1]',
                                'configurehosts' => 'add',
                                'host' => 'host.[1]',
                                'niocversion' => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
                                'version' => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                                niocinfrastructuretraffic  => {
                                    'virtualMachine' => "500:100:1000",
                                },
                     }
                 }
              }
          },
          'host' => {
               '[1]' => {
                 'vmnic' => {
                     '[1]' => {
                       'driver' => 'any'
                     }
                 }
               }
          },
          'vm' => {
            '[1]' => {
               'vnic' => {
                  '[1-2]' => {
                      'portgroup' => 'vc.[1].dvportgroup.[1]',
                      'driver' => 'vmxnet3',
                      shares      => "50",
                      reservation => "50",
                      limit       => "1000",
                      connected   => 1,
                      startconnected    => 1,
                      allowguestcontrol => 1,
                  }
               },
               'host' => 'host.[1]'
            },
          }

        },
        WORKLOADS => {
          Sequence => [
                       ['ResetNIOC'],
                       ['EnableNIOC'],
                       ['VerifyPlacement'],
                      ],

            ResetNIOC => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               nioc  => "enable,disable",
               Iterations => '100',
            },
            EnableNIOC => {
               Type       => "Switch",
               TestSwitch => "vc.[1].vds.[1]",
               nioc  => "enable",
            },
            VerifyPlacement => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1-2]",
               nicplacement => "1",
            },
         },
      },
      'BasicScheduler'   => {
         TestName         => 'BasicScheduler',
         Category         => 'ESX Server',
         Component        => 'network io resource management',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetIOCv3',
         Summary          => 'To verify vnics are placed successfully ' .
                             'on vmnic based on reservation and ' .
                             'each vnic gets its entitled bandwidth',
         Tags             => 'scheduler,sanity',
         PMT              => '4084',
         Procedure        => '1. Create a vDS with NIOC enabled ' .
                             '2. Add one uplink to the VDS and configure ' .
                             '   750Mbps reservation for VM traffic ' .
                             '3. Deploy 5 VMs and configure reservation '  .
                             '   of one VM to be higher than other 4 VMs ' .
                             '4. Power on the VMs and verify vnic is placed ' .
                             '5. Start IO session between 5 VMs and a vmknic',
         ExpectedResult   => 'Vnic entitlement for all the vnics ' ,
         Status           => 'complete',
         Tags             => 'automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'gjayavelu',
         Testbed          => '',
         Version          => '2' ,

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
			               host  => "host.[1]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter     => "vc.[1].datacenter.[1]",
                        version        => VDNetLib::TestData::TestConstants::VDS_DEFAULT_VERSION,
                        configurehosts => "add",
                        host           => "host.[1]",
                        vmnicadapter   => "host.[1].vmnic.[2]",
                        niocversion    => VDNetLib::TestData::TestConstants::VDS_NIOC_DEFAULT_VERSION,
                        niocinfrastructuretraffic  => {
                           'virtualMachine' => "750:100:1000",
                        },
                     },
                  },
                  dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1-2]'   => {
                        driver => "any",
                     },
                  },
                   vss => {
                     '[1]'   => { # create VSS
                        vmnicadapter     => "host.[1].vmnic.[1]",
                        configureuplinks => "add",
		               },
                  },
                  portgroup => {
                     '[1]' => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => { # create 2 vmknic on vss 1
                        portgroup => "host.[1].portgroup.[1]",
                     },
                  },
               },
            },
            vm  => {
               '[1]'   => {
		            host  => "host.[1].x.[1]",
                  vnic => {
                     '[1]'   => {
                        driver	   => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        shares      => "50",
                        reservation => "450",
                        limit       => "1000",
                        connected   => 1,
                        startconnected    => 1,
                        allowguestcontrol => 1,
                     },
                  },
               },
               '[2-4]'   => {
		            host  => "host.[1].x.[1]",
                  vnic => {
                     '[1]'   => {
                        driver	   => "vmxnet3",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                        shares      => "50",
                        reservation => "100",
                        limit       => "1000",
                        connected   => 1,
                        startconnected    => 1,
                        allowguestcontrol => 1,
                     },
                  },
               },
             },
         },
         WORKLOADS => {
            Sequence        => [['VerifyPlacement'],
                                ['TCPTraffic']],

            VerifyPlacement => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-4].vnic.[1]",
               nicplacement => "1",
            },

            TCPTraffic => {
               Type                  => "Traffic",
               ToolName              => "netperf",
               parallelsession       => "yes",
               TestAdapter           => "vm.[1-4].vnic.[1]",
               SupportAdapter        => "host.[1].vmknic.[1]",
               L3Protocol            => "ipv4,ipv6",
               L4Protocol            => "tcp,udp",
               NoofOutbound          => "1",
               SendMessageSize       => "64512",
               LocalSendSocketSize   => "131072",
               RemoteSendSocketSize  => "131072",
               testduration          => "60",
               Verification   => "Verification",
            },
            "Verification" => {
               'NIOCVerificaton' => {
                  verificationtype => "NIOC",
                  target           => "srcVM",
                  uplinks          => "host.[1].vmnic.[2]",
               },
            },
         },
      },
   );
}

##########################################################################
# new --
#       This is the constructor for NetIOCv3
#
# Input:
#       none
#
# Results:
#       An instance/object of NetIOCv3Tds class
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
      my $self = $class->SUPER::new(\%NetIOCv3);
      return (bless($self, $class));
}

1;
