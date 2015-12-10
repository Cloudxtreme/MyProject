#!/usr/bin/perl
#########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::DistributedFirewall::DFWVMotionTds;

#
# This file contains hash to test and verify the persistance
# of DFW config on VMotion.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use TDS::NSX::DistributedFirewall::CommonWorkloads ':AllConstants';
@ISA = qw(TDS::Main::VDNetMainTds);

{
   %DFWVMotion = (
      'TestDFWVMotionMultipleVnics'   => {
         TestName         => 'TestDFWVMotionMultipleVnics',
         Category         => 'Stateful Firewall',
         Product          => 'vShield',
         Component        => 'DFW',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => ' Configure and verify working of DFW'.
                             ' Before and after vMotion',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '1200',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_TwoCluster_ThreeHost_OneDVS_Threedvpg_SixVM,
         WORKLOADS => {
            Sequence => [
               # Workloads for bringing up network connectivity
               ['HostPrepCluster1',
               'HostPrepCluster2'],
               ['AddvNICsOnVM1VM2',
               'AddvNICsOnVM3VM4',
               'AddvNICsOnVM5VM6'],

               ['PoweronVM1VM2',
               'PoweronVM3VM4',
               'PoweronVM5VM6'],

               # Enable DRS after VM powerOn to avoid VM migration
               # during powerOn
               ['EnableDRSOnCluster_1_2'],

               # Initial config for DFW

               # Run Traffic to test DFW datapath

               # VMotion workload
               ['NetperfIPv4TrafficBetweenVM1AndVM2',
               'NetperfIPv6TrafficBetweenVM1AndVM2',
               'VMotionVM1ToHost2'],
               ['VMotionVM1ToHost1'],

               # Maintenance mode workload
               # Currently VDnet uses esxcli commands to put host into
               # maintenance mode. This will not auto migrate vms.
               ['NetperfIPv4TrafficBetweenVM1AndVM2',
               'NetperfIPv6TrafficBetweenVM1AndVM2',
               'VMotionVM1ToHost2',
               'VMotionVM2ToHost2',],
               ['EnableMaintenanceModeHost1'],
               ['DisableMaintenanceModeHost1'],
               ['VMotionVM1ToHost1','VMotionVM2ToHost1'],

               # Cleanup the setup
               ['RemovevNICFromVM1to6'],
               ['PoweroffVM1VM6'],
               ['DisableDRSOnCluster_1_2'],
            ],
            'DisableDRSOnCluster_1_2' => {
               Type => "Cluster",
               TestCluster => "vc.[1].datacenter.[1].cluster.[1-2]",
               EditCluster => "edit",
               drs   => 0,
            },
            'EnableDRSOnCluster_1_2' => {
               Type => "Cluster",
               TestCluster => "vc.[1].datacenter.[1].cluster.[1-2]",
               EditCluster => "edit",
               drs   => 1,
            },
            'HostPrepCluster1' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'HostPrepCluster2' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[2]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'AddvNICsOnVM1VM2' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
                  '[2]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[2]",
                  },
               },
            },
            'AddvNICsOnVM3VM4' => {
               Type   => "VM",
               TestVM => "vm.[3],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
                  '[2]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[2]",
                  },
               },
            },
            'AddvNICsOnVM5VM6' => {
               Type   => "VM",
               TestVM => "vm.[5],vm.[6]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
                  '[2]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[2]",
                  },
               },
            },
            'PoweronVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweron",
            },
            'PoweronVM3VM4' => {
               Type    => "VM",
               TestVM  => "vm.[3-4]",
               vmstate => "poweron",
            },
            'PoweronVM5VM6' => {
               Type    => "VM",
               TestVM  => "vm.[5-6]",
               vmstate => "poweron",
            },
            'NetperfIPv4TrafficBetweenVM1AndVM2' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l3protocol' => 'ipv4',
              'l4protocol' => 'tcp,udp',
              'toolname' => 'netperf',
              'testduration' => '45',
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'NetperfIPv6TrafficBetweenVM1AndVM2' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l3protocol' => 'ipv6',
              'l4protocol' => 'tcp,udp',
              'toolname' => 'netperf',
              'testduration' => '45',
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'VMotionVM1ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM1ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM2ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[2]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM2ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[2]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            "EnableMaintenanceModeHost1" => {
               Type            => "Host",
               TestHost        => "host.[1].x.[x]",
               maintenancemode => "true",
            },
            "DisableMaintenanceModeHost1" => {
               Type            => "Host",
               TestHost        => "host.[1].x.[x]",
               maintenancemode => "false",
              'sleepbetweenworkloads' => '30',
            },
            'RemovevNICFromVM1to6' => {
               Type       => "VM",
               TestVM     => "vm.[1-6]",
               deletevnic => "vm.[x].vnic.[x]",
            },
            'PoweroffVM1VM6' => {
               Type    => "VM",
               TestVM  => "vm.[1-6]",
               vmstate => "poweroff",
            },
         },
      },
      'TestDFWVMotionScaleVMs'   => {
         TestName         => 'TestDFWVMotionScaleVMs',
         Category         => 'Stateful Firewall',
         Product          => 'vShield',
         Component        => 'DFW',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => ' Configure and verify working of DFW'.
                             ' Before and after vMotion',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '1200',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneCluster_TwoHost_OneDVS_Twodvpg_TwentyFourVM,
         WORKLOADS => {
            Sequence => [
               # Workloads for bringing up network connectivity
               ['HostPrepCluster1'],
               ['PoweronVM1ToVM8',
               'PoweronVM9ToVM16',
               'PoweronVM17ToVM24',
               ],
               # Initial config for DFW

               # Run Traffic to test DFW datapath

               # VMotion workload
               # Following workloads will migrate 24 vms at same time.
               ['VMotionVM1ToHost2',
                'VMotionVM2ToHost2',
                'VMotionVM3ToHost2',
                'VMotionVM4ToHost2',
                'VMotionVM5ToHost2',
                'VMotionVM6ToHost2',
                'VMotionVM7ToHost2',
                'VMotionVM8ToHost2',
                'VMotionVM9ToHost2',
                'VMotionVM10ToHost2',
                'VMotionVM11ToHost2',
                'VMotionVM12ToHost2',
                'VMotionVM13ToHost2',
                'VMotionVM14ToHost2',
                'VMotionVM15ToHost2',
                'VMotionVM16ToHost2',
                'VMotionVM17ToHost2',
                'VMotionVM18ToHost2',
                'VMotionVM19ToHost2',
                'VMotionVM20ToHost2',
                'VMotionVM21ToHost2',
                'VMotionVM22ToHost2',
                'VMotionVM23ToHost2',
                'VMotionVM24ToHost2'],

               ['VMotionVM1ToHost1',
                'VMotionVM2ToHost1',
                'VMotionVM3ToHost1',
                'VMotionVM4ToHost1',
                'VMotionVM5ToHost1',
                'VMotionVM6ToHost1',
                'VMotionVM7ToHost1',
                'VMotionVM8ToHost1',
                'VMotionVM9ToHost1',
                'VMotionVM10ToHost1',
                'VMotionVM11ToHost1',
                'VMotionVM12ToHost1',
                'VMotionVM13ToHost1',
                'VMotionVM14ToHost1',
                'VMotionVM15ToHost1',
                'VMotionVM16ToHost1',
                'VMotionVM17ToHost1',
                'VMotionVM18ToHost1',
                'VMotionVM19ToHost1',
                'VMotionVM20ToHost1',
                'VMotionVM21ToHost1',
                'VMotionVM22ToHost1',
                'VMotionVM23ToHost1',
                'VMotionVM24ToHost1'],

               # Cleanup the setup
               ['PoweroffVM1VM24'],
            ],
            'HostPrepCluster1' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'PoweronVM1ToVM8' => {
               Type    => "VM",
               TestVM  => "vm.[1-8]",
               vmstate => "poweron",
            },
            'PoweronVM9ToVM16' => {
               Type    => "VM",
               TestVM  => "vm.[9-16]",
               vmstate => "poweron",
            },
            'PoweronVM17ToVM24' => {
               Type    => "VM",
               TestVM  => "vm.[17-24]",
               vmstate => "poweron",
            },
            'VMotionVM1ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM2ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[2]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM3ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[3]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM4ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[4]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM5ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[5]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM6ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[6]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM7ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[7]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM8ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[8]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM9ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[9]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM10ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[10]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM11ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[11]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM12ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[12]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM13ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[13]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM14ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[14]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM15ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[15]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM16ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[16]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM17ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[17]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM18ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[18]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM19ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[19]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM20ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[20]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM21ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[21]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM22ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[22]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM23ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[23]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM24ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[24]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM1ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM2ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[2]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM3ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[3]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM4ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[4]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM5ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[5]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM6ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[6]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM7ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[7]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM8ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[8]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM9ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[9]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM10ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[10]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM11ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[11]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM12ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[12]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM13ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[13]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM14ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[14]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM15ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[15]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM16ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[16]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM17ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[17]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM18ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[18]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM19ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[19]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM20ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[20]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM21ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[21]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM22ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[22]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM23ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[23]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'VMotionVM24ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[24]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'PoweroffVM1VM24' => {
               Type    => "VM",
               TestVM  => "vm.[1-24]",
               vmstate => "poweroff",
            },
         },
      },
      'TestDFWVMotionConcurrentConnections'   => {
         TestName         => 'TestDFWVMotionConcurrentConnections',
         Category         => 'Stateful Firewall',
         Product          => 'vShield',
         Component        => 'DFW',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => ' Configure and verify working of DFW'.
                             ' Before and after vMotion',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'nsx,CAT',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '1200',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_TwoCluster_TwoHost_OneDVS_Threedvpg_TwoVMLightHttpd,
         WORKLOADS => {
            Sequence => [
               # Workloads for bringing up network connectivity
               ['HostPrepCluster1'],
               ['AddvNICsOnVM1VM2'],
               ['PoweronVM1VM2'],
               # Initial config for DFW
               ['SetDFWRules'],
               # Run Traffic to test DFW datapath
               # VMotion workload
               [
               'HTTPTraffic',
               'VMotionVM1ToHost2',
               ],
               ['VMotionVM1ToHost1'],
               # Cleanup setup
               ['RemovevNICFromVM1to2'],
               ['PoweroffVM1VM2'],
            ],
            'HostPrepCluster1' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'AddvNICsOnVM1VM2' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
               },
            },
            'PoweronVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweron",
            },
            'SetDFWRules' => {
               ExpectedResult   => "PASS",
               Type             => "NSX",
               TestNSX          => "vsm.[1]",
               firewallrule     => {
                  '[1]' => {
                        layer => "layer3",
                        name    => 'Allow_Traffic_OnlyBetween_VM1_VM2',
                        action  => 'allow',
                        logging_enabled => 'true',
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
                              value     => "vm.[1]",
                           },
                           {
                              type  => 'VirtualMachine',
                              value     => "vm.[2]",
                           },
                        ],
                        affected_service => [
                           {
                              protocolname => 'TCP',
                              destinationport => '80,443',
                              sourceport => '80,443',
                           },
                        ],
                  },
                  '[2]' => {
                     layer => "layer3",
                     name    => 'Block all',
                     action  => 'deny',
                     section => 'default',
                     logging_enabled => 'true',
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
                           value     => "vm.[1]",
                        },
                        {
                           type  => 'VirtualMachine',
                           value     => "vm.[2]",
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
            'HTTPTraffic' => {
               Type => 'Traffic',
               toolname => 'lighttpd',
               requestcount => '10000',
               threadcount => '50',
               concurrentclients => '1000',
               testadapter => 'vm.[2].vnic.[1]',
               supportadapter => 'vm.[1].vnic.[1]',
               connectivitytest => "0",
               iterations => "5",
            },
            'VMotionVM1ToHost2' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[2]',
            },
            'VMotionVM1ToHost1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'RemovevNICFromVM1to2' => {
               Type       => "VM",
               TestVM     => "vm.[1-2]",
               deletevnic => "vm.[x].vnic.[x]",
            },
            'PoweroffVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweroff",
            },
         },
      },
      'TestDFWVMotionAcrossClusters'   => {
         TestName         => 'TestDFWVMotionAcrossClusters',
         Category         => 'Stateful Firewall',
         Product          => 'vShield',
         Component        => 'DFW',
         QCPath           => 'OP\Networking-FVT\DFW',
         Summary          => ' Configure and verify working of DFW'.
                             ' Before and after vMotion between clusters',
         Procedure        => '1. Add Rule-1 to block traffic between VM1 & 3 in Cluster-1'.
                             ' and applied to cluster-1'.
                             '2. Add rule-2 to allow all traffic from secgrp-2(Cluster-2) '.
                             ' to secgrp-1(Cluster-1)'.
                             '3. Send traffic between VM1&3 while VMotion of VM1 from host-1'.
                             '(in cluster-1) to host-2(in cluster-2)'.
                             '4. Verify the traffic is blocked during and after vmotion by rule-1'.
                             '5. Send traffic between VM1(now in cluster-2) to VM2(in cluster-1)'.
                             '6. Verify the traffic flows by rule-2',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'CAT',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Partnerfacing    => 'N',
         Duration         => '1200',
         Version          => '2' ,
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_TwoCluster_ThreeHost_OneDVS_Threedvpg_SixVM,
         WORKLOADS => {
            Sequence => [
               # Workloads for bringing up network connectivity
               ['HostPrepCluster1',
               'HostPrepCluster2'],
               ['AddvNICsOnVM1VM2',
               'AddvNICsOnVM3VM4',
               'AddvNICsOnVM5VM6'],
               ['PoweronVM1VM2',
               'PoweronVM3VM4',
               'PoweronVM5VM6'],

               # Initial config for DFW
               ['CreateSG_1_2_With_Cluster_1_2'],
               ['Block_VM1_VM3_Traffic'],

               # VMotion workload
               ['NetperfIPv4TrafficBetweenVM1AndVM3',
               'NetperfIPv6TrafficBetweenVM1AndVM3',
               'VMotionVM1To_Cluster2Host3'],

               # Check traffic flows from Cluster-2 to Cluster-1
               ['NetperfIPv4TrafficBetweenVM1AndVM2',
               'NetperfIPv6TrafficBetweenVM1AndVM2',],
               ['VMotionVM1To_Cluster1Host1'],

               # Cleanup the setup
               ['DeleteRules'],
               ['DeleteSecurityGroups_1_2'],
               ['RemovevNICFromVM1to6'],
               ['PoweroffVM1VM6'],
            ],
            'DeleteSecurityGroups_1_2' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletesecuritygroup => "vsm.[1].securitygroup.[1-2]",
            },
            "DeleteRules" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletefirewallrule => "vsm.[1].firewallrule.[1-3]",
            },
            "CreateSG_1_2_With_Cluster_1_2" => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               securitygroup => {
                  '[1]' => {
                     'name' => "DFW_SG1_Cluster1",
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
                        'cluster_id' => "vc.[1].datacenter.[1].cluster.[1]",
                        'objecttypename' => "ClusterComputeResource",
                     },
                     ],
                  },
                  '[2]' => {
                     'name' => "DFW_SG2_Cluster2",
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
                        'cluster_id' => "vc.[1].datacenter.[1].cluster.[2]",
                        'objecttypename' => "ClusterComputeResource",
                     },
                     ],
                  },
               },
            },
            "Block_VM1_VM3_Traffic" => {
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
                          name   => 'Block_VM1_VM3',
                          action => 'Deny',
                          logging_enabled => 'true',
                          sources => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[1]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[3]",
                                           },
                          ],
                          destinations => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[1]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[3]",
                                           },
                          ],
                          appliedto => [
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[1]",
                                           },
                                           {
                                              type  => 'VirtualMachine',
                                              value => "vm.[3]",
                                           },
                                     ],
                  },
                  '[3]' => {
                          layer => 'Layer3',
                          logging_enabled => 'true',
                          name => 'Allow_SG1_SG2',
                          action => 'Allow',
                          sources => [
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
                          ],
                  },
               },
            },
            'HostPrepCluster1' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[1]",
                  },
               },
            },
            'HostPrepCluster2' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[2]' => {
                     cluster => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'AddvNICsOnVM1VM2' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[2]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
               },
            },
            'AddvNICsOnVM3VM4' => {
               Type   => "VM",
               TestVM => "vm.[3],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
               },
            },
            'AddvNICsOnVM5VM6' => {
               Type   => "VM",
               TestVM => "vm.[5],vm.[6]",
               vnic => {
                  '[1]'   => {
                     driver     => "vmxnet3",
                     portgroup  => "vc.[1].dvportgroup.[1]",
                  },
               },
            },
            'PoweronVM1VM2' => {
               Type    => "VM",
               TestVM  => "vm.[1-2]",
               vmstate => "poweron",
            },
            'PoweronVM3VM4' => {
               Type    => "VM",
               TestVM  => "vm.[3-4]",
               vmstate => "poweron",
            },
            'PoweronVM5VM6' => {
               Type    => "VM",
               TestVM  => "vm.[5-6]",
               vmstate => "poweron",
            },
            'NetperfIPv4TrafficBetweenVM1AndVM3' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l3protocol' => 'ipv4',
              'l4protocol' => 'tcp,udp',
              'toolname' => 'netperf',
              'testduration' => '20',
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]',
              'Expectedresult' => "FAIL",
              'Verification'   => "Verification_Drop",
            },
            'Verification_Drop' => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[3].vnic.[1]",
                  pktcapfilter     => "count 100",
                  pktcount         => "0-10",
                  badpkt           => "0",
               },
            },
            'NetperfIPv6TrafficBetweenVM1AndVM3' => {
              'Type' => 'Traffic',
              'l3protocol' => 'ipv6',
              'l4protocol' => 'tcp,udp',
              'toolname' => 'netperf',
              'testduration' => '20',
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[3].vnic.[1]',
              'Expectedresult' => "FAIL",
              'Verification'   => "Verification_Drop",
            },
            'NetperfIPv4TrafficBetweenVM1AndVM2' => {
              'Type' => 'Traffic',
              'noofoutbound' => '1',
              'l3protocol' => 'ipv4',
              'l4protocol' => 'tcp,udp',
              'toolname' => 'netperf',
              'testduration' => '20',
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]',
              'Expectedresult' => "PASS",
              'Verification'   => "Verification_Allow",
            },
            'Verification_Allow' => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "vm.[2].vnic.[1]",
                  pktcapfilter     => "count 1000",
                  pktcount         => "900+",
                  badpkt           => "0",
               },
            },
            'NetperfIPv6TrafficBetweenVM1AndVM2' => {
              'Type' => 'Traffic',
              'l3protocol' => 'ipv6',
              'l4protocol' => 'tcp,udp',
              'toolname' => 'netperf',
              'testduration' => '20',
              'noofinbound' => 1,
              'testadapter' => 'vm.[1].vnic.[1]',
              'supportadapter' => 'vm.[2].vnic.[1]',
              'Expectedresult' => "PASS",
              'Verification'   => "Verification_Allow",
            },
            'VMotionVM1To_Cluster2Host3' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[3]',
            },
            'VMotionVM1To_Cluster1Host1' => {
              'Type' => 'VM',
              'TestVM' => 'vm.[1]',
              'priority' => 'high',
              'vmotion' => 'singletrip',
              'sleepbetweenworkloads' => '30',
              'dsthost' => 'host.[1]',
            },
            'RemovevNICFromVM1to6' => {
               Type       => "VM",
               TestVM     => "vm.[1-6]",
               deletevnic => "vm.[x].vnic.[x]",
            },
            'PoweroffVM1VM6' => {
               Type    => "VM",
               TestVM  => "vm.[1-6]",
               vmstate => "poweroff",
            },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor for DFWVMotion
#
# Input:
#       none
#
# Results:
#       An instance/object of DFWVMotion class
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
      my $self = $class->SUPER::new(\%DFWVMotion);
      return (bless($self, $class));
}

1;
