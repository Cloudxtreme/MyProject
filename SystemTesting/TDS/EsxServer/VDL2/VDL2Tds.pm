#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VDL2::VDL2Tds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestConstants;
use TDS::EsxServer::VDL2::TestbedSpec;
use TDS::EsxServer::VDL2::TestbedSpec ':AllConstants';
use TDS::EsxServer::VDL2::CommonWorkloads ':AllConstants';

@ISA = qw(TDS::Main::VDNetMainTds);
{
   %VDL2 = (
      'CheckIGMP' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'CheckIGMP',
         'Summary' => 'Verify that vdl2 vmknic will send out igmp group join ' .
                      'message when a vdl2 network is activated',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['EnableTSODHCPForVnicofVM'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['ChangePortgroup1'],
               ['CheckIGMPGroup1'],
               ['ChangePortgroup2'],
               ['CheckIGMPGroup2'],
               ['ChangePortgroup3'],
               ['CheckIGMPGroup1'],
               ['ChangePortgroup4'],
               ['CheckIGMPGroup3']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'ChangePortgroup1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'CheckIGMPGroup1' => {
               'Type' => 'Command',
               'command' => 'net-vdl2 -l',
               'expectedstring' => 'Multicast group count:\\s+1',
               'testhost' => 'host.[1]'
            },
            'ChangePortgroup2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'CheckIGMPGroup2' => {
               'Type' => 'Command',
               'command' => 'net-vdl2 -l',
               'expectedstring' => 'Multicast group count:\\s+2',
               'testhost' => 'host.[1]'
            },
            'ChangePortgroup3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'ChangePortgroup4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'CheckIGMPGroup3' => {
               'Type' => 'Command',
               'command' => 'net-vdl2 -l',
               'expectedstring' => 'Multicast group count:\\s+0',
               'testhost' => 'host.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
         }
      },

      'PromiscuousMode' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'PromiscuousMode',
         'Summary' => 'Verify PromiscuousMode funcitonal in vDL2 networks',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroupWork1'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['EnableTSODHCPForVnicofVM'],
               ['NetperfTraffic1'],
               ['EnablePromiscuous'],
               ['NetperfTraffic2']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'NetperfTraffic1' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'verification' => 'Verification',
               'l4protocol' => 'tcp',
               'toolname' => 'netperf',
               'testduration' => '60',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'EnablePromiscuous' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'setpromiscuous' => 'Enable',
               'dvportgroup' => 'promiscuous_group'
            },
            'NetperfTraffic2' => {
               'Type' => 'Traffic',
               'verification' => 'Verification',
               'l4protocol' => 'tcp',
               'testduration' => '60',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
            'Verification' => {
               'PktCapVerificaton' => {
                  'target' => 'vm.[3].vnic.[1]',
                  'verificationtype' => 'pktcap'
               }
            }
         }
      },

      'IPv6' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'IPv6',
         'Summary' => 'Verify that the IPv6 traffic can run smoothly in vdl2' .
                      ' network',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated,rerun',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_2,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroupWork1'],
               ['ChangePortgroupWork2'],
               ['ChangePortgroupWork3'],
               ['ChangePortgroupWork4'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['AddIPv6ForVM'],
               ['Iperf_1'],
               ['Iperf_2'],
               ['Iperf_3'],
               ['Iperf_4']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroupWork2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroupWork3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[5]'
            },
            'ChangePortgroupWork4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[4].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[6]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AddIPv6ForVM' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-4].vnic.[1]',
               'ipv6' => 'ADD',
               'ipv6addr' => 'DEFAULT',
               'iterations' => '1'
            },
            'Iperf_1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'l3protocol' => 'ipv6',
               'toolname' => 'netperf',
               'testduration' => '20',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'l3protocol' => 'ipv6',
               'toolname' => 'netperf',
               'testduration' => '20',
               'noofinbound' => '1',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Iperf_3' => {
               'Type' => 'Traffic',
               'toolname' => 'netperf',
               'testduration' => '20',
               'testadapter' => 'vm.[1].vnic.[1]',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'tcp',
               'l3protocol' => 'ipv6',
               'noofinbound' => '1',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Iperf_4' => {
               'Type' => 'Traffic',
               'l4protocol' => 'udp',
               'l3protocol' => 'ipv6',
               'toolname' => 'netperf',
               'testduration' => '20',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
         }
      },

      'OffloadingIPv6' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'OffloadingIPv6',
         'Summary' => 'Verify that the change of Hardware Capabilities will ' .
                      'not affect vdl2 network.',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroupWork1'],
               ['ChangePortgroupWork2'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_Vds1Vlan0'],
               ['AttachVDL2_1'],
               ['AddIPv6ForVM'],
               ['EnableTSODHCPForVnicofVM_IPv4'],
               ['Vmnic_hw1'],
               ['Netperf_1'],
               ['Vmnic_hw2'],
               ['Netperf_2'],
               ['Vmnic_hw3'],
               ['Netperf_3'],
               ['Vmnic_hw4'],
               ['Netperf_4'],
               ['Vmnic_hw5'],
               ['Netperf_1'],
               ['Vmnic_hw6'],
               [ 'Netperf_2'],
               ['Vmnic_hw7'],
               ['Netperf_3'],
               ['Vmnic_hw8'],
               ['Netperf_4'],
               ['Vmnic_hw9'],
               ['Netperf_1'],
               ['Vmnic_hw10'],
               ['Netperf_2'],
               ['Vmnic_hw11'],
               ['Netperf_3'],
               ['Vmnic_hw12'],
               ['Netperf_4'],
               ['Vmnic_hw13'],
               ['Netperf_1']
            ],
            'ExitSequence' => [
               ['SetToDefault_hw1'],
               ['SetToDefault_hw2'],
               ['SetToDefault_hw3'],
               ['SetToDefault_hw4'],
               ['SetToDefault_hw5'],
               ['SetToDefault_hw6'],
               ['SetToDefault_hw7'],
               ['SetToDefault_hw8'],
               ['SetToDefault_hw9'],
               ['SetToDefault_hw10'],
               ['SetToDefault_hw11'],
               ['SetToDefault_hw12'],
               ['SetToDefault_hw13'],
               ['DetachVDL2_1'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2_1']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroupWork2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_Vds1Vlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AddIPv6ForVM' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'ipv6' => 'ADD',
               'ipv6addr' => 'DEFAULT',
               'iterations' => '1'
            },
            'EnableTSODHCPForVnicofVM_IPv4' => EnableTSODHCPForVnicofVM,
            'Vmnic_hw1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'nethighdma' => '0'
            },
            'Netperf_1' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '131072',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'remotesendsocketsize' => '131072',
               'verification' => 'Verification',
               'l4protocol' => 'tcp',
               'l3protocol' => 'ipv6',
               'sendmessagesize' => '1024,2048,4096,8000',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmnic_hw2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'netsgspanpgs' => '0'
            },
            'Netperf_2' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '655356',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'remotesendsocketsize' => '655356',
               'verification' => 'Verification',
               'l4protocol' => 'udp',
               'l3protocol' => 'ipv6',
               'sendmessagesize' => '63488-18192,25872',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmnic_hw3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'netsg' => '0'
            },
            'Netperf_3' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '13107',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'remotesendsocketsize' => '13107',
               'verification' => 'Verification',
               'l4protocol' => 'udp',
               'l3protocol' => 'ipv6',
               'sendmessagesize' => '1024,2048,4096,8000',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmnic_hw4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'ipchecksum' => '0'
            },
            'Netperf_4' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '655356',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'remotesendsocketsize' => '655356',
               'verification' => 'Verification',
               'l4protocol' => 'tcp',
               'l3protocol' => 'ipv6',
               'sendmessagesize' => '1024,16384,655356',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmnic_hw5' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'vlanrx' => '0'
            },
            'Vmnic_hw6' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'vlantx' => '0'
            },
            'Vmnic_hw7' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'offload16offset' => '1'
            },
            'Vmnic_hw8' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'offload8offset' => '1'
            },
            'Vmnic_hw9' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'tsoipv4' => '0'
            },
            'Vmnic_hw10' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'tso6exthdrs' => '1'
            },
            'Vmnic_hw11' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'tsoipv6' => '0'
            },
            'Vmnic_hw12' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'ipv6extchecksum' => '1'
            },
            'Vmnic_hw13' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'ipv6checksum' => '0'
            },
            'SetToDefault_hw1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'nethighdma' => '1'
            },
            'SetToDefault_hw2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'netsgspanpgs' => '1'
            },
            'SetToDefault_hw3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'netsg' => '1'
            },
            'SetToDefault_hw4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'ipchecksum' => '1'
            },
            'SetToDefault_hw5' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'vlanrx' => '1'
            },
            'SetToDefault_hw6' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'vlantx' => '1'
            },
            'SetToDefault_hw7' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'offload16offset' => '0'
            },
            'SetToDefault_hw8' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'offload8offset' => '0'
            },
            'SetToDefault_hw9' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'tsoipv4' => '1'
            },
            'SetToDefault_hw10' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'tso6exthdrs' => '0'
            },
            'SetToDefault_hw11' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'tsoipv6' => '1'
            },
            'SetToDefault_hw12' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'ipv6extchecksum' => '0'
            },
            'SetToDefault_hw13' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'ipv6checksum' => '1'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2_1' => DisableVDL2,
            'Verification' => {
               'PktCapVerificaton' => {
                  'target' => 'dst',
                  'pktcount' => '100+',
                  'pktcapfilter' => 'count 5000',
                  'verificationtype' => 'pktcap'
               }
            }
         }
      },

      'UDPPortConfiguration' => {
		   'Component' => 'VXLAN',
		   'Category' => 'ESX Server',
		   'TestName' => 'UDPPortConfiguration',
		   'Summary' => 'Verify vdl2 UDP port can be configured per vds per host',
		   'ExpectedResult' => 'PASS',
		   'AutomationStatus'  => 'Automated',
		   'Version' => '2',
		   'TestbedSpec' => Functional_Topology_1,
		   'WORKLOADS' => {
		      'Sequence' => [
		         ['CheckAndInstallVDL2'],
		         ['SetMTU_VDS'],
		         ['ChangePortgroup1'],
		         ['ChangePortgroup2'],
		         ['ChangePortgroup3'],
		         ['ChangePortgroup4'],
		         ['EnableVDL2'],
		         ['CreateVDL2Vmknic_VDSVlan0'],
		         ['SetUDPPort1'],
		         ['CheckUDPPort1'],
		         ['SetUDPPort2'],
		         ['CheckUDPPort2'],
		         ['AttachVDL2_1'],
		         ['AttachVDL2_2'],
		         ['AttachVDL2_3'],
		         ['AttachVDL2_4'],
		         ['SetUDPPort3'],
		         ['CheckUDPPort3'],
		         ['SetUDPPort4'],
		         ['CheckUDPPort4'],
		         ['EnableTSODHCPForVnicofVM'],
		         ['Iperf_1'],
		         ['Iperf_2'],
		         ['Iperf_3']
		      ],
		      'ExitSequence' => [
		         ['DetachVDL2_1'],
		         ['DetachVDL2_2'],
		         ['DetachVDL2_3'],
		         ['DetachVDL2_4'],
		         ['RemoveVDL2Vmknic_VDSVlan0'],
		         ['DisableVDL2']
		      ],
		      'Duration' => 'time in seconds',
		      'CheckAndInstallVDL2' => CheckAndInstallVDL2,
		      'SetMTU_VDS' => SetMTU_VDS,
		      'ChangePortgroup1' => {
		         'Type' => 'NetAdapter',
		         'TestAdapter' => 'vm.[1].vnic.[1]',
		         'reconfigure' => 'true',
		         'portgroup' => 'vc.[1].dvportgroup.[3]'
		      },
		      'ChangePortgroup2' => {
		         'Type' => 'NetAdapter',
		         'TestAdapter' => 'vm.[2].vnic.[1]',
		         'reconfigure' => 'true',
		         'portgroup' => 'vc.[1].dvportgroup.[4]'
		      },
		      'ChangePortgroup3' => {
		         'Type' => 'NetAdapter',
		         'TestAdapter' => 'vm.[3].vnic.[1]',
		         'reconfigure' => 'true',
		         'portgroup' => 'vc.[1].dvportgroup.[5]'
		      },
		      'ChangePortgroup4' => {
		         'Type' => 'NetAdapter',
		         'TestAdapter' => 'vm.[4].vnic.[1]',
		         'reconfigure' => 'true',
		         'portgroup' => 'vc.[1].dvportgroup.[6]'
		      },
		      'EnableVDL2' => EnableVDL2,
		      'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
		      'SetUDPPort1' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'udpport' => '10000',
		         'vds' => 'vc.[1].vds.[1]',
		         'opt' => 'setvdl2udpport',
		         'testhost' => 'host.[1]'
		      },
		      'CheckUDPPort1' => {
		         'Type' => 'Command',
		         'command' => 'net-vdl2 -l',
		         'expectedstring' => 'UDP port:\\s+10000',
		         'testhost' => 'host.[1]'
		      },
		      'SetUDPPort2' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'udpport' => '10000',
		         'vds' => 'vc.[1].vds.[2]',
		         'opt' => 'setvdl2udpport',
		         'testhost' => 'host.[1]'
		      },
		      'CheckUDPPort2' => {
		         'Type' => 'Command',
		         'command' => 'net-vdl2 -l',
		         'expectedstring' => 'UDP port:\\s+10000',
		         'testhost' => 'host.[1]'
		      },
		      'AttachVDL2_1' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'portgroup' => 'vc.[1].dvportgroup.[3]',
		         'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
		         'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
		         'vds' => 'vc.[1].vds.[1]',
		         'opt' => 'attachvdl2'
		      },
		      'AttachVDL2_2' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'portgroup' => 'vc.[1].dvportgroup.[6]',
		         'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
		         'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
		         'vds' => 'vc.[1].vds.[2]',
		         'opt' => 'attachvdl2'
		      },
		      'AttachVDL2_3' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'portgroup' => 'vc.[1].dvportgroup.[4]',
		         'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
		         'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
		         'vds' => 'vc.[1].vds.[1]',
		         'opt' => 'attachvdl2'
		      },
		      'AttachVDL2_4' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'portgroup' => 'vc.[1].dvportgroup.[5]',
		         'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
		         'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
		         'vds' => 'vc.[1].vds.[2]',
		         'opt' => 'attachvdl2'
		      },
		      'SetUDPPort3' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'udpport' => '10000',
		         'vds' => 'vc.[1].vds.[2]',
		         'opt' => 'setvdl2udpport',
		         'testhost' => 'host.[2]'
		      },
		      'CheckUDPPort3' => {
		         'Type' => 'Command',
		         'command' => 'net-vdl2 -l',
		         'expectedstring' => 'UDP port:\\s+10000',
		         'testhost' => 'host.[2]'
		      },
		      'SetUDPPort4' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'udpport' => '10000',
		         'vds' => 'vc.[1].vds.[1]',
		         'opt' => 'setvdl2udpport',
		         'testhost' => 'host.[2]'
		      },
		      'CheckUDPPort4' => {
		         'Type' => 'Command',
		         'command' => 'net-vdl2 -l',
		         'expectedstring' => 'UDP port:\\s+10000',
		         'testhost' => 'host.[2]'
		      },
		      'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
		      'Iperf_1' => {
		         'Type' => 'Traffic',
		         'testduration' => '20',
		         'toolname' => 'Iperf',
		         'noofinbound' => '1',
		         'testadapter' => 'vm.[1].vnic.[1]',
		         'supportadapter' => 'vm.[4].vnic.[1]'
		      },
		      'Iperf_2' => {
		         'Type' => 'Traffic',
		         'testduration' => '20',
		         'toolname' => 'Iperf',
		         'noofinbound' => '1',
		         'testadapter' => 'vm.[2].vnic.[1]',
		         'supportadapter' => 'vm.[3].vnic.[1]'
		      },
		      'Iperf_3' => {
		         'Type' => 'Traffic',
		         'expectedresult' => 'FAIL',
		         'testduration' => '20',
		         'toolname' => 'Iperf',
		         'noofinbound' => '1',
		         'testadapter' => 'vm.[1].vnic.[1]',
		         'supportadapter' => 'vm.[2].vnic.[1]'
		      },
		      'DetachVDL2_1' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'portgroup' => 'vc.[1].dvportgroup.[3]',
		         'vds' => 'vc.[1].vds.[1]',
		         'opt' => 'detachvdl2'
		      },
		      'DetachVDL2_2' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'portgroup' => 'vc.[1].dvportgroup.[6]',
		         'vds' => 'vc.[1].vds.[2]',
		         'opt' => 'detachvdl2'
		      },
		      'DetachVDL2_3' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'portgroup' => 'vc.[1].dvportgroup.[4]',
		         'vds' => 'vc.[1].vds.[1]',
		         'opt' => 'detachvdl2'
		      },
		      'DetachVDL2_4' => {
		         'Type' => 'VC',
		         'TestVC' => 'vc.[1]',
		         'portgroup' => 'vc.[1].dvportgroup.[5]',
		         'vds' => 'vc.[1].vds.[2]',
		         'opt' => 'detachvdl2'
		      },
		      'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
		      'DisableVDL2' => DisableVDL2,
		   }
		},

      'InvalidConfigSequence' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'InvalidConfigSequence',
         'Summary' => 'Verify that invalid configuration sequence will get ' .
                      'proper warnings and not cause any problem',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroup'],
               ['EnableVDL2'],
               ['DisableVDL2_2'],
               ['CreateVDL2VMKNic_1'],
               ['RemoveVDL2VMKNic'],
               ['AttachVDL2_1'],
               ['DetachVDL2'],
               ['EnableVDL2'],
               ['CreateVDL2VMKNic_2'],
               ['AttachVDL2_2'],
               ['EnableTSODHCPForVnicofVM'],
               ['NetperfTraffic'],
               ['Ping'],
               ['DisableVDL2_1'],
               ['DetachVDL2'],
               ['RemoveVDL2VMKNic']
            ],
            'ExitSequence' => [
               ['DetachVDL2'],
               ['RemoveVDL2VMKNic'],
               ['DisableVDL2_2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'enablevdl2'
            },
            'DisableVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'disablevdl2'
            },
            'CreateVDL2VMKNic_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'expectedresult' => 'FAIL',
               'vlanid' => '0',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'createvdl2vmknic'
            },
            'RemoveVDL2VMKNic' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vlanid' => '0',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'removevdl2vmknic'
            },
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2',
               'expectedresult' => 'FAIL',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A
            },
            'DetachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'CreateVDL2VMKNic_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vlanid' => '0',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'createvdl2vmknic'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'NetperfTraffic' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '60',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Ping' => {
               'Type' => 'Traffic',
               'noofoutbound' => 1,
               'testduration' => 5,
               'toolname' => 'ping',
               'pingpktsize' => '1472,9000',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DisableVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'expectedresult' => 'FAIL',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'disablevdl2'
            }
         }
      },

      'VCShutdown' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'VCShutdown',
         'Summary' => 'Verify traffic persistence when VC is down',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroup1'],
               ['EnableTSODHCPForVnicofVM'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2'],
               ['Iperf1'],
               ['Stopvpxa','Iperf2'],
               ['Startvpxa','Iperf1']
            ],
            'ExitSequence' => [
               ['DetachVDL2'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroup1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'Iperf1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '60',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Stopvpxa' => {
               'Type' => 'Command',
               'command' => '/etc/init.d/vpxa stop',
               'testhost' => 'host.[2]'
            },
            'Iperf2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '900',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Startvpxa' => {
               'Type' => 'Command',
               'command' => '/etc/init.d/vpxa start',
               'testhost' => 'host.[2]'
            },
            'DetachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
         }
      },

      'Portdown' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'Portdown',
         'Summary' => 'Verify if traffic can restore when port from down to up',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroup1'],
               ['EnableTSODHCPForVnicofVM'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2'],
               ['Iperf_1'],
               ['RemoveUplink'],
               ['Iperf_2'],
               ['AddUplink'],
               ['Iperf_3']
            ],
            'ExitSequence' => [
               ['DetachVDL2'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2'],
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroup1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'Iperf_1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'RemoveUplink' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'configureuplinks' => 'remove',
               'vmnicadapter' => 'host.[1].vmnic.[1]'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'AddUplink' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'configureuplinks' => 'add',
               'vmnicadapter' => 'host.[1].vmnic.[1]'
            },
            'Iperf_3' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'sleepbetweencombos' => '60',
               'toolname' => 'Iperf',
               'testduration' => '120',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DetachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
         }
      },

      'PortMirror' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'PortMirror',
         'Summary' => 'Verify DVMirror functional in vDL2 networks',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroupWork1'],
               ['ChangePortgroupWork2'],
               ['ChangePortgroupWork3'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['EnableTSODHCPForVnicofVM'],
               ['CreateSession1'],
               ['NetperfTraffic'],
               ['DetachVDL2_3'],
               ['AttachVDL2_4'],
               ['NetperfTraffic']
            ],
            'ExitSequence' => [
               ['RemoveSession1'],
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroupWork2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroupWork3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[5]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'CreateSession1' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'mirrorlength' => '1500',
               'sessiontype' => 'dvPortMirror',
               'dstport' => 'vm.[3].vnic.[1]',
               'srcrxport' => 'vm.[1].vnic.[1]',
               'addmirrorsession' => 'Session1',
               'mirrorversion' => 'v2',
               'srctxport' => 'vm.[1].vnic.[1]'
            },
            'NetperfTraffic' => {
               'Type' => 'Traffic',
               'verification' => 'Verification',
               'l4protocol' => 'tcp',
               'testduration' => '60',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'RemoveSession1' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'removemirrorsession' => 'Session1',
               'mirrorversion' => 'v2'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
            'Verification' => {
               'PktCapVerificaton' => {
                  'target' => 'vm.[3].vnic.[1]',
                  'verificationtype' => 'pktcap'
               }
            }
         }
      },

      'ChangeVDL2ID' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'ChangeVDL2ID',
         'Summary' => 'Verify that vdl2 id cannot be changed while there is ' .
                      'an active dvport',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroup1'],
               ['ChangePortgroup2'],
               ['ChangePortgroup3'],
               ['ChangePortgroup4'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['EnableTSODHCPForVnicofVM'],
               ['Iperf_1'],
               ['Iperf_2'],
               ['Iperf_3'],
               ['ChangeVDL2ID1'],
               ['ChangePortgroup5'],
               ['DetachVDL2_1'],
               ['ChangeVDL2ID2'],
               ['ChangePortgroup1'],
               ['Iperf_4'],
               ['Iperf_5']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroup1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroup3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[5]'
            },
            'ChangePortgroup4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[4].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[6]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'Iperf_1' => {
               'Type' => 'Traffic',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Iperf_3' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'ChangeVDL2ID1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2',
               'expectedresult' => 'FAIL',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B
            },
            'ChangePortgroup5' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'ChangeVDL2ID2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'Iperf_4' => {
               'Type' => 'Traffic',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Iperf_5' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
         }
      },

      'PartialDeploy' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'PartialDeploy',
         'Summary' => 'Verify that vdl2 module works correctly when dvportgroups' .
                      ' are partially deployed in vdl2 networks',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroupWork1'],
               ['ChangePortgroupWork2'],
               ['ChangePortgroupWork3'],
               ['ChangePortgroupWork4'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['EnableTSODHCPForVnicofVM'],
               ['Iperf_1'],
               ['Iperf_2']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' =>SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroupWork2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroupWork3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[5]'
            },
            'ChangePortgroupWork4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[4].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[6]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'Iperf_1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
         }
      },

      'Multicast' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'Multicast',
         'Summary' => 'Verify multicast connectivity/isolation of VMs which ' .
                      'are deployed in vDL2 networks',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroupWork1'],
               ['ChangePortgroupWork2'],
               ['ChangePortgroupWork3'],
               ['ChangePortgroupWork4'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['EnableTSODHCPForVnicofVM'],
               ['Iperf_1'],
               ['Iperf_2'],
               ['Iperf_3']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroupWork2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroupWork3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[5]'
            },
            'ChangePortgroupWork4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[4].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[6]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'Iperf_1' => {
               'Type' => 'Traffic',
               'toolname' => 'Iperf',
               'testduration' => '20',
               'udpbandwidth' => '1000M',
               'routingscheme' => 'multicast',
               'testadapter' => 'vm.[1].vnic.[1]',
               'noofinbound' => '1',
               'supportadapter' => 'vm.[4].vnic.[1]',
               'multicasttimetolive' => '32'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'toolname' => 'Iperf',
               'testduration' => '20',
               'routingscheme' => 'multicast',
               'testadapter' => 'vm.[2].vnic.[1]',
               'noofinbound' => '1',
               'supportadapter' => 'vm.[3].vnic.[1]',
               'multicasttimetolive' => '32'
            },
            'Iperf_3' => {
               'Type' => 'Traffic',
               'toolname' => 'Iperf',
               'testduration' => '20',
               'routingscheme' => 'multicast',
               'testadapter' => 'vm.[1].vnic.[1]',
               'verification' => 'Verification_1',
               'noofinbound' => '1',
               'multicasttimetolive' => '32',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
            'Verification_1' => {
               'PktCapVerificaton' => {
                  'target' => 'dst',
                  'pktcount' => '0',
                  'pktcapfilter' => 'count 999',
                  'verificationtype' => 'pktcap'
               }
            }
         }
      },

      'Unicast' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'Unicast',
         'Summary' => 'Verify unicast connectivity/isolation of VMs which are' .
                      ' deployed in vDL2 networks',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroupWork1'],
               ['ChangePortgroupWork2'],
               ['ChangePortgroupWork3'],
               ['ChangePortgroupWork4'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['EnableTSODHCPForVnicofVM'],
               ['Iperf_1'],
               ['Iperf_2'],
               ['Iperf_3']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroupWork2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroupWork3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[5]'
            },
            'ChangePortgroupWork4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[4].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[6]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'Iperf_1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Iperf_3' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2
         }
      },

      'Broadcast' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'Broadcast',
         'Summary' => 'Verify broadcast connectivity/isolation of VMs which ' .
                      'are deployed in vDL2 networks',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['ChangePortgroupWork1'],
               ['ChangePortgroupWork2'],
               ['ChangePortgroupWork3'],
               ['ChangePortgroupWork4'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['EnableTSODHCPForVnicofVM'],
               ['Ping1'],
               ['Ping2']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' =>CheckAndInstallVDL2,
            'SetMTU_VDS' =>SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroupWork2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'ChangePortgroupWork3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[5]'
            },
            'ChangePortgroupWork4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[4].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[6]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' =>CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'Ping1' => {
               'Type' => 'Traffic',
               'toolname' => 'ping',
               'noofinbound' => '1',
               'routingscheme' => 'broadcast',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Ping2' => {
               'Type' => 'Traffic',
               'toolname' => 'ping',
               'noofinbound' => '1',
               'routingscheme' => 'broadcast',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2
         }
      },

      'ImproperMTU' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'ImproperMTU',
         'Summary' => 'Verify the improper MTU setting only blocks traffic, ' .
                      'no other impacts to vdl2 network',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['ChangePortgroup'],
               ['EnableTSODHCPForVnicofVM'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2'],
               ['SetMTU'],
               ['Ping1'],
               ['SetMTU_VDS'],
               ['NetperfTraffic2'],
               ['Ping2'],
               ['SetMTU'],
               ['Ping1']
            ],
            'ExitSequence' => [
               ['DetachVDL2'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'ChangePortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'Ping1' => {
               'Type' => 'Traffic',
               'toolname' => 'ping',
               'testduration' => 5,
               'pingpktsize' => '1472,9000',
               'testadapter' => 'vm.[1].vnic.[1]',
               'expectedresult' => 'FAIL',
               'noofoutbound' => 1,
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'SetMTU_VDS' => SetMTU_VDS,
            'NetperfTraffic2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '60',
               'sleepbetweencombos' => '10',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Ping2' => {
               'Type' => 'Traffic',
               'noofoutbound' => 1,
               'testduration' => 5,
               'toolname' => 'ping',
               'pingpktsize' => '1472,9000',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'SetMTU' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'mtu' => '1500'
            },
            'DetachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2
         }
      },

      'Nmap' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'Nmap',
         'Summary' => 'Use network scanning tool nmap to test vdl2 security',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['EnabledNTP'],
               ['ChangePortgroup_1'],
               ['ChangePortgroup_2'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2'],
               ['EnableTSODHCPForVnicofVM'],
               ['Nmap_TCP','Nmap_UDP','Iperf']
            ],
            'ExitSequence' => [
               ['DetachVDL2'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'EnabledNTP' => {
               'Type' => 'Host',
               'TestHost' => 'host.[1]',
               'firewall' => 'setenabled',
               'flag' => 'enabled',
               'servicename' => 'ntpClient'
            },
            'ChangePortgroup_1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup_2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'Nmap_TCP' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '30',
               'toolname' => 'nmap',
               'noofoutbound' => '1',
               'testadapter' => 'vm.[3].vnic.[1]',
               'supportadapter' => 'host.[1].vmknic.[1]'
            },
            'Nmap_UDP' => {
               'Type' => 'Traffic',
               'l4protocol' => 'udp',
               'testduration' => '30',
               'toolname' => 'nmap',
               'testadapter' => 'vm.[3].vnic.[1]',
               'supportadapter' => 'host.[1].vmknic.[1]'
            },
            'Iperf' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '60',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DetachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2
         }
      },

      'OffloadingIPv4' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'OffloadingIPv4',
         'Summary' => 'Verify that the change of Hardware Capabilities will ' .
                      'not affect vdl2 network',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['EnableTSODHCPForVnicofVM'],
               ['ChangePortgroupWork1'],
               ['ChangePortgroupWork2'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2'],
               ['Vmnic_hw1'],
               ['Netperf_1'],
               ['Vmnic_hw2'],
               ['Netperf_2'],
               ['Vmnic_hw3'],
               ['Netperf_3'],
               ['Vmnic_hw4'],
               ['Netperf_4'],
               ['Vmnic_hw5'],
               ['Netperf_1'],
               ['Vmnic_hw6'],
               ['Netperf_2'],
               ['Vmnic_hw7'],
               ['Netperf_3'],
               ['Vmnic_hw8'],
               ['Netperf_4'],
               ['Vmnic_hw9'],
               ['Netperf_1']
            ],
            'ExitSequence' => [
               ['SetToDefault_hw1'],
               ['SetToDefault_hw2'],
               ['SetToDefault_hw3'],
               ['SetToDefault_hw4'],
               ['SetToDefault_hw5'],
               ['SetToDefault_hw6'],
               ['SetToDefault_hw7'],
               ['SetToDefault_hw8'],
               ['SetToDefault_hw9'],
               ['DetachVDL2'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroupWork2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' =>EnableTSODHCPForVnicofVM,
            'Vmnic_hw1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'nethighdma' => '0'
            },
            'Netperf_1' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '131072',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'remotesendsocketsize' => '131072',
               'verification' => 'Verification',
               'l4protocol' => 'tcp',
               'sendmessagesize' => '1024,2048,4096,8000',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmnic_hw2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'netsgspanpgs' => '0'
            },
            'Netperf_2' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '655356',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'remotesendsocketsize' => '655356',
               'verification' => 'Verification',
               'l4protocol' => 'udp',
               'sendmessagesize' => '63488-18192,25872',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmnic_hw3' => {
              'Type' => 'NetAdapter',
              'TestAdapter' => 'host.[1].vmnic.[1]',
              'netsg' => '0'
            },
            'Netperf_3' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '13107',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'remotesendsocketsize' => '13107',
               'verification' => 'Verification',
               'l4protocol' => 'udp',
               'sendmessagesize' => '1024,2048,4096,8000',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmnic_hw4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'ipchecksum' => '0'
            },
            'Netperf_4' => {
               'Type' => 'Traffic',
               'localsendsocketsize' => '655356',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'remotesendsocketsize' => '655356',
               'verification' => 'Verification',
               'l4protocol' => 'tcp',
               'sendmessagesize' => '1024,16384,655356',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'Vmnic_hw5' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'vlanrx' => '0'
            },
            'Vmnic_hw6' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'vlantx' => '0'
            },
            'Vmnic_hw7' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'offload16offset' => '1'
            },
            'Vmnic_hw8' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'offload8offset' => '1'
            },
            'Vmnic_hw9' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'tsoipv4' => '0'
            },
            'SetToDefault_hw1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'nethighdma' => '1'
            },
            'SetToDefault_hw2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'netsgspanpgs' => '1'
            },
            'SetToDefault_hw3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'netsg' => '1'
            },
            'SetToDefault_hw4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'ipchecksum' => '1'
            },
            'SetToDefault_hw5' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'vlanrx' => '1'
            },
            'SetToDefault_hw6' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'vlantx' => '1'
            },
            'SetToDefault_hw7' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'offload16offset' => '0'
            },
            'SetToDefault_hw8' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'expectedresult' => 'Ignore',
               'offload8offset' => '0'
            },
            'SetToDefault_hw9' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'host.[1].vmnic.[1]',
               'tsoipv4' => '1'
            },
            'DetachVDL2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
            'Verification' => {
               'PktCapVerificaton' => {
                  'target' => 'dst',
                  'pktcount' => '100+',
                  'pktcapfilter' => 'count 5000',
                  'verificationtype' => 'pktcap'
               }
            }
         }
      },

      'ConfigurationPersistence' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'ConfigurationPersistence',
         'Summary' => 'Verify configuration persistence of VDL2 module ' .
                      'after server reboot',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
           'Sequence' => [
             ['CheckAndInstallVDL2'],
             ['SetMTU_VDS'],
             ['EnableTSODHCPForVnicofVM'],
             ['ChangePortgroup1'],
             ['EnableVDL2'],
             ['CreateVDL2Vmknic_VDSVlan0'],
             ['AttachVDL2_1'],
             ['AttachVDL2_2'],
             ['NetperfTraffic1'],
             ['Ping_BigPacket'],
             ['RebootSUTHost'],
             ['PowerOnVM'],
             ['EnableTSODHCPForVnicofVM'],
             ['NetperfTraffic1'],
             ['Ping_BigPacket'],
             ['ChangePortgroup2'],
             ['Ping_Fail']
           ],
           'ExitSequence' => [
             ['DetachVDL2_1'],
             ['DetachVDL2_2'],
             ['RemoveVDL2Vmknic_VDSVlan0'],
             ['DisableVDL2'],
             ['PowerOnVM']
           ],
           'Duration' => 'time in seconds',
           'CheckAndInstallVDL2' => CheckAndInstallVDL2,
           'SetMTU_VDS' => SetMTU_VDS,
           'ChangePortgroup1' => {
             'Type' => 'NetAdapter',
             'TestAdapter' => 'vm.[1-2].vnic.[1]',
             'reconfigure' => 'true',
             'portgroup' => 'vc.[1].dvportgroup.[3]'
           },
           'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
           'EnableVDL2' => EnableVDL2,
           'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
           'AttachVDL2_1' => {
             'Type' => 'VC',
             'TestVC' => 'vc.[1]',
             'portgroup' => 'vc.[1].dvportgroup.[3]',
             'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
             'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
             'vds' => 'vc.[1].vds.[1]',
             'opt' => 'attachvdl2'
           },
           'AttachVDL2_2' => {
             'Type' => 'VC',
             'TestVC' => 'vc.[1]',
             'portgroup' => 'vc.[1].dvportgroup.[4]',
             'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
             'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
             'vds' => 'vc.[1].vds.[1]',
             'opt' => 'attachvdl2'
           },
           'NetperfTraffic1' => {
             'Type' => 'Traffic',
             'l4protocol' => 'tcp',
             'testduration' => '60',
             'toolname' => 'netperf',
             'testadapter' => 'vm.[1].vnic.[1]',
             'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'Ping_BigPacket' => {
             'Type' => 'Traffic',
             'noofoutbound' => 1,
             'testduration' => 5,
             'toolname' => 'ping',
             'pingpktsize' => '1472,9000',
             'testadapter' => 'vm.[1].vnic.[1]',
             'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'RebootSUTHost' => {
             'Type' => 'Host',
             'TestHost' => 'host.[1]',
             'reboot' => 'yes'
           },
           'PowerOnVM' => PowerOnVM,
           'ChangePortgroup2' => {
             'Type' => 'NetAdapter',
             'TestAdapter' => 'vm.[1].vnic.[1]',
             'reconfigure' => 'true',
             'portgroup' => 'vc.[1].dvportgroup.[4]'
           },
           'Ping_Fail' => {
             'Type' => 'Traffic',
             'toolname' => 'ping',
             'testduration' => 5,
             'testadapter' => 'vm.[1].vnic.[1]',
             'expectedresult' => 'FAIL',
             'noofoutbound' => 1,
             'supportadapter' => 'vm.[2].vnic.[1]'
           },
           'DetachVDL2_1' => {
             'Type' => 'VC',
             'TestVC' => 'vc.[1]',
             'portgroup' => 'vc.[1].dvportgroup.[3]',
             'vds' => 'vc.[1].vds.[1]',
             'opt' => 'detachvdl2'
           },
           'DetachVDL2_2' => {
             'Type' => 'VC',
             'TestVC' => 'vc.[1]',
             'portgroup' => 'vc.[1].dvportgroup.[4]',
             'vds' => 'vc.[1].vds.[1]',
             'opt' => 'detachvdl2'
           },
           'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
           'DisableVDL2' => DisableVDL2
         }
      },

      'ChangeMulticastIP' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'ChangeMulticastIP',
         'Summary' => 'Verify that multicast ip changing doesn\'t affect the ' .
                      'traffic flow',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['EnableTSODHCPForVnicofVM'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['Iperf_1'],
               ['Iperf_2'],
               ['Iperf_3'],
               ['ChangeVDL2MCIP1'],
               ['ChangeVDL2MCIP2'],
               ['Iperf_1'],
               ['Iperf_2'],
               ['Iperf_3'],
               ['ChangeVDL2MCIP3'],
               ['ChangeVDL2MCIP4'],
               ['Iperf_1'],
               ['Iperf_2'],
               ['Iperf_3']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'Iperf_1' => {
               'Type' => 'Traffic',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Iperf_3' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'ChangeVDL2MCIP1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2mcip'
            },
            'ChangeVDL2MCIP2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2mcip'
            },
            'ChangeVDL2MCIP3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_C,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2mcip'
            },
            'ChangeVDL2MCIP4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_C,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2mcip'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2
         }
      },

      'PortBinding' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'PortBinding',
         'Summary' => 'Verify three type port binding in vDL2 networks',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CreateDVPGs_VDS'],
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['EnableTSODHCPForVnicofVM'],
               ['ChangePortgroupWork1'],
               ['ChangePortgroupWork2'],
               ['ChangePortgroupWork3'],
               ['ChangePortgroupWork4'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['Iperf_1'],
               ['Iperf_2'],
               ['Iperf_3']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'ChangePortgroupofVMs' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[-1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[1]'
            },
            'CreateDVPGs_VDS' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'dvportgroup' => {
                  '[7]' => {
                     'ports' => '1',
                     'name' => 'pg7',
                     'autoExpand' => '0',
                     'binding' => 'earlyBinding',
                     'vds' => 'vc.[1].vds.[1]'
                  },
                  '[8]' => {
                     'ports' => '1',
                     'name' => 'pg8',
                     'binding' => 'ephemeral',
                     'vds' => 'vc.[1].vds.[1]'
                  },
                  '[9]' => {
                     'ports' => '1',
                     'name' => 'pg9',
                     'autoExpand' => '0',
                     'binding' => 'earlyBinding',
                     'vds' => 'vc.[1].vds.[2]'
                  },
                  '[10]' => {
                     'ports' => '1',
                     'name' => 'pg10',
                     'binding' => 'lateBinding',
                     'vds' => 'vc.[1].vds.[2]'
                  }
               }
            },
            'SetMTU_VDS' => SetMTU_VDS,
            'ChangePortgroupWork1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[7]'
            },
            'ChangePortgroupWork2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[8]'
            },
            'ChangePortgroupWork3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[9]'
            },
            'ChangePortgroupWork4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[4].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[10]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[7]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[10]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
              'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[8]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[9]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'Iperf_1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Iperf_3' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[7]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[8]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[9]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[10]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2
         }
      },

      'JumboFrame' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'JumboFrame',
         'Summary' => 'Verify that the vdl2 module can work well with jumbo frames',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_Jumbo'],
               ['EnableTSODHCPForVnicofVM'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['Iperf_1'],
               ['Iperf_2'],
               ['Ping_Fail']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_Jumbo' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1-2]',
               'mtu' => '9000'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'Iperf_1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'Ping_Fail' => {
               'Type' => 'Traffic',
               'expectedresult' => 'FAIL',
               'testduration' => '5',
               'toolname' => 'ping',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[2].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2
         }
      },

      'DVShaper' => {
         'Component' => 'network CHF/BFN/VDL2/VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'DVShaper',
         'Summary' => 'Verify traffic shapping with VDL2',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'testID' => 'TDS::EsxServer::VDL2::VDL2::DVShaper',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['EnableTSODHCPForVnicofVM'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['EnableShaping1'],
               ['EnableShaping2'],
               ['EnableShaping3'],
               ['EnableShaping4']
            ],
            'ExitSequence' => [
               ['DisableShaping1'],
               ['DisableShaping2'],
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[3]',
              'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
              'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
              'vds' => 'vc.[1].vds.[1]',
              'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[6]',
              'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
              'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
              'vds' => 'vc.[1].vds.[2]',
              'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[4]',
              'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
              'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
              'vds' => 'vc.[1].vds.[1]',
              'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
              'Type' => 'VC',
              'TestVC' => 'vc.[1]',
              'portgroup' => 'vc.[1].dvportgroup.[5]',
              'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
              'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
              'vds' => 'vc.[1].vds.[2]',
              'opt' => 'attachvdl2'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'EnableShaping1' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'peakbandwidth' => '100000',
               'enableoutshaping' => 'vc.[1].dvportgroup.[3]',
               'avgbandwidth' => '100000',
               'enableinshaping' => 'vc.[1].dvportgroup.[3]',
               'burstsize' => '102400',
               'runworkload' => 'Traffic1'
            },
            'EnableShaping2' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[2]',
               'peakbandwidth' => '10000',
               'enableoutshaping' => 'vc.[1].dvportgroup.[5]',
               'avgbandwidth' => '10000',
               'runworkload' => 'Traffic2',
               'enableinshaping' => 'vc.[1].dvportgroup.[5]',
               'burstsize' => '10240'
            },
            'EnableShaping3' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[2]',
               'peakbandwidth' => '20000',
               'enableoutshaping' => 'vc.[1].dvportgroup.[5]',
               'avgbandwidth' => '20000',
               'runworkload' => 'Traffic3',
               'enableinshaping' => 'vc.[1].dvportgroup.[5]',
               'burstsize' => '10240'
            },
            'EnableShaping4' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'peakbandwidth' => '100000',
               'enableoutshaping' => 'vc.[1].dvportgroup.[3]',
               'avgbandwidth' => '100000',
               'runworkload' => 'Traffic4',
               'enableinshaping' => 'vc.[1].dvportgroup.[3]',
               'burstsize' => '102400'
            },
            'Traffic1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'udp',
               'localsendsocketsize' => '32768',
               'remotesendsocketSize' => '65535',
               'sendmessagesize' => '1470',
               'testduration' => '10',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]',
               'maxthroughput' => '100',
               'expectedresult' => 'PASS',
            },
            'Traffic2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'udp',
               'testduration' => '10',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]',
               'maxthroughput' => '10',
               'expectedresult' => 'PASS',
               'localsendsocketsize' => '32768',
               'remotesendsocketSize' => '65535',
               'sendmessagesize' => '1470',
            },
            'Traffic3' => {
               'Type' => 'Traffic',
               'l4protocol' => 'udp',
               'testduration' => '10',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]',
               'maxthroughput' => '20',
               'expectedresult' => 'PASS',
               'localsendsocketsize' => '32768',
               'remotesendsocketSize' => '65535',
               'sendmessagesize' => '1470',
            },
            'Traffic4' => {
               'Type' => 'Traffic',
               'l4protocol' => 'udp',
               'testduration' => '10',
               'toolname' => 'netperf',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]',
               'maxthroughput' => '100',
               'expectedresult' => 'FAIL',
               'localsendsocketsize' => '65535',
               'remotesendsocketSize' => '65535',
               'sendmessagesize' => '1470',
            },
            'DisableShaping1' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'disableoutshaping' => 'vc.[1].dvportgroup.[3]'
            },
            'DisableShaping2' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[2]',
               'disableoutshaping' => 'vc.[1].dvportgroup.[5]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2
         }
      },

      'DuplicatedAddress' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'DuplicatedAddress',
         'Summary' => 'Verify that VMs in different vDL2 networks can have ' .
                      'duplicated ip and mac address',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['AcceptMACChange_1'],
               ['AcceptForgedTx_1'],
               ['AcceptMACChange_2'],
               ['AcceptForgedTx_2'],
               ['ChangePortgroup1'],
               ['ChangePortgroup2'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['SetMACVM1Vnic'],
               ['SetIPTSOVM1Vnic'],
               ['SetMACVM2Vnic'],
               ['SetIPTSOVM2Vnic'],
               ['SetMACVM3Vnic'],
               ['SetIPTSOVM3Vnic'],
               ['SetMACVM4Vnic'],
               ['SetIPTSOVM4Vnic'],
               ['Iperf1','Iperf2'],
               ['ChangePortgroup3'],
               ['ChangePortgroup4'],
               ['Iperf1','Iperf2']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2'],
               ['ResetMAC']
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'AcceptMACChange_1' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'dvportgroup' => 'dvportgroup3, dvportgroup4',
               'setmacaddresschange' => 'Enable'
            },
            'AcceptForgedTx_1' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'dvportgroup' => 'dvportgroup3, dvportgroup4',
               'setforgedtransmit' => 'Enable'
            },
            'AcceptMACChange_2' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[2]',
               'dvportgroup' => 'dvportgroup5, dvportgroup6',
               'setmacaddresschange' => 'Enable'
            },
            'AcceptForgedTx_2' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[2]',
               'dvportgroup' => 'dvportgroup5, dvportgroup6',
               'setforgedtransmit' => 'Enable'
            },
            'ChangePortgroup1' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'ChangePortgroup2' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[4]'
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'SetMACVM1Vnic' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'setmacaddr' => '00:50:56:11:11:11'
            },
            'SetIPTSOVM1Vnic' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
               'ipv4' => '192.168.100.11',
            },
            'SetMACVM2Vnic' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'setmacaddr' => '00:50:56:22:22:22'
            },
            'SetIPTSOVM2Vnic' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
               'ipv4' => '192.168.100.22',
            },
            'SetMACVM3Vnic' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'setmacaddr' => '00:50:56:22:22:22'
            },
            'SetIPTSOVM3Vnic' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
               'ipv4' => '192.168.100.22',
            },
            'SetMACVM4Vnic' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[4].vnic.[1]',
               'setmacaddr' => '00:50:56:11:11:11'
            },
            'SetIPTSOVM4Vnic' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[4].vnic.[1]',
               'configure_offload' =>{
                  'offload_type' => 'tsoipv4',
                  'enable'       => 'true',
               },
               'ipv4' => '192.168.100.11',
            },
            'Iperf1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '60',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[1].vnic.[1]'
            },
            'Iperf2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '60',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[3].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'ChangePortgroup3' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[5]'
            },
            'ChangePortgroup4' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[3].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[6]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
            'ResetMAC' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1-4].vnic.[1]',
               'setmacaddr' => 'reset'
            }
         }
      },

      'VST' => {
		   'Component' => 'VXLAN',
		   'Category' => 'ESX Server',
		   'TestName' => 'VST',
		   'Summary' => 'Verify that the vdl2 network can work correctly in ' .
		                'VLAN VST environment.',
		   'ExpectedResult' => 'PASS',
		   'AutomationStatus'  => 'Automated',
		   'Version' => '2',
		   'TestbedSpec' => Functional_Topology_2,
		   'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['SetMTU_VDS'],
               ['EnableTSODHCPForVnicofVM'],
               ['SetVDSPG3VlanA'],
               ['SetVDSPG6VlanB'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_Vds1VlanA'],
               ['CreateVDL2Vmknic_Vds2VlanA'],
               ['CreateVDL2Vmknic_Vds2VlanB'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['AttachVDL2_3'],
               ['AttachVDL2_4'],
               ['Iperf_1'],
               ['Iperf_2'],
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['DetachVDL2_3'],
               ['DetachVDL2_4'],
               ['RemoveVDL2Vmknic_Vds1VlanA'],
               ['RemoveVDL2Vmknic_Vds2VlanA'],
               ['RemoveVDL2Vmknic_Vds2VlanA'],
               ['RemoveVDL2Vmknic_Vds2VlanB'],
               ['DisableVDL2'],
            ],
            'Duration' => 'time in seconds',
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'SetMTU_VDS' => SetMTU_VDS,
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'SetVDSPG3VlanA' => {
               'Type' => 'PortGroup',
               'TestPortGroup' => 'vc.[1].dvportgroup.[3]',
               'vlantype' => 'access',
               'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A
            },
            'SetVDSPG6VlanB' => {
               'Type' => 'PortGroup',
               'TestPortGroup' => 'vc.[1].dvportgroup.[6]',
               'vlantype' => 'access',
               'vlan' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_B
            },
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_Vds1VlanA' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'createvdl2vmknic'
            },
            'CreateVDL2Vmknic_Vds2VlanA' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'createvdl2vmknic'
            },
            'CreateVDL2Vmknic_Vds2VlanB' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'createvdl2vmknic'
            },
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_B,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'Iperf_1' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[1].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Iperf_2' => {
               'Type' => 'Traffic',
               'l4protocol' => 'tcp',
               'testduration' => '20',
               'toolname' => 'Iperf',
               'noofinbound' => '1',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[3].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_3' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[4]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_4' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[5]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_Vds1VlanA' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'removevdl2vmknic'
            },
            'RemoveVDL2Vmknic_Vds2VlanA' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'removevdl2vmknic'
            },
            'RemoveVDL2Vmknic_Vds2VlanB' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'vlanid' => VDNetLib::Common::GlobalConfig::VDNET_VLAN_VDL2_B,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'removevdl2vmknic'
            },
            'DisableVDL2' => DisableVDL2,
         }
		},

      'NetFlow' => {
         'Component' => 'VXLAN',
         'Category' => 'ESX Server',
         'TestName' => 'NetFlow',
         'Summary' => 'Test NetFlow and VDL2/VXLAN interops',
         'ExpectedResult' => 'PASS',
         'AutomationStatus'  => 'Automated',
         'Version' => '2',
         'testID' => 'TDS::EsxServer::VDL2::VDL2::NetFlow',
         'TestbedSpec' => Functional_Topology_1,
         'WORKLOADS' => {
            'Sequence' => [
               ['CheckAndInstallVDL2'],
               ['EnableMonitoring'],
               ['SetMTU_VDS'],
               ['ChangePortgroup'],
               ['EnableTSODHCPForVnicofVM'],
               ['EnableVDL2'],
               ['CreateVDL2Vmknic_VDSVlan0'],
               ['AttachVDL2_1'],
               ['AttachVDL2_2'],
               ['SetNetFlow_1'],
               ['Traffic1'],
               ['SetNetFlow_2'],
               ['Traffic2'],
               ['Traffic3']
            ],
            'ExitSequence' => [
               ['DetachVDL2_1'],
               ['DetachVDL2_2'],
               ['RemoveVDL2Vmknic_VDSVlan0'],
               ['DisableVDL2']
            ],
            'CheckAndInstallVDL2' => CheckAndInstallVDL2,
            'EnableMonitoring' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'set_monitoring' => {
                  'status' => 'true',
                  'dvportgroup' => 'vc.[1].dvportgroup.[3]',
               }
            },
            'ChangePortgroup' => {
               'Type' => 'NetAdapter',
               'TestAdapter' => 'vm.[1].vnic.[1],vm.[2].vnic.[1]',
               'reconfigure' => 'true',
               'portgroup' => 'vc.[1].dvportgroup.[3]'
            },
            'EnableTSODHCPForVnicofVM' => EnableTSODHCPForVnicofVM,
            'SetMTU_VDS' => SetMTU_VDS,
            'EnableVDL2' => EnableVDL2,
            'CreateVDL2Vmknic_VDSVlan0' => CreateVDL2Vmknic_VDSVlan0,
            'AttachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'attachvdl2'
            },
            'AttachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vdl2id' => VDNetLib::TestData::TestConstants::VDL2ID_A,
               'mcastip' => VDNetLib::TestData::TestConstants::VDL2MCASTIP_A,
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'attachvdl2'
            },
            'Traffic1' => {
               'Type' => 'Traffic',
               'expectedresult' => 'PASS',
               'verification' => 'Verification_1',
               'l4protocol' => 'tcp',
               'toolname' => 'iperf',
               'testduration' => '60',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'SetNetFlow_1' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'confignetflow' => 'local',
               'activetimeout' => '120',
               'sampling' => '10',
               'idletimeout' => '30'
            },
            'SetNetFlow_2' => {
               'Type' => 'Switch',
               'TestSwitch' => 'vc.[1].vds.[1]',
               'confignetflow' => 'local',
               'activetimeout' => '60',
               'sampling' => '0',
               'idletimeout' => '15'
            },
            'Traffic2' => {
               'Type' => 'Traffic',
               'expectedresult' => 'PASS',
               'verification' => 'Verification_3',
               'l4protocol' => 'udp',
               'toolname' => 'iperf',
               'testduration' => '60',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'Traffic3' => {
               'Type' => 'Traffic',
               'expectedresult' => 'PASS',
               'verification' => 'Verification_2',
               'testduration' => '60',
               'toolname' => 'Ping',
               'testadapter' => 'vm.[2].vnic.[1]',
               'supportadapter' => 'vm.[4].vnic.[1]'
            },
            'DetachVDL2_1' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[3]',
               'vds' => 'vc.[1].vds.[1]',
               'opt' => 'detachvdl2'
            },
            'DetachVDL2_2' => {
               'Type' => 'VC',
               'TestVC' => 'vc.[1]',
               'portgroup' => 'vc.[1].dvportgroup.[6]',
               'vds' => 'vc.[1].vds.[2]',
               'opt' => 'detachvdl2'
            },
            'RemoveVDL2Vmknic_VDSVlan0' => RemoveVDL2Vmknic_VDSVlan0,
            'DisableVDL2' => DisableVDL2,
            'Verification_1' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'tcp',
                  'src' => 'vm.[2].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[4].vnic.[1]'
               }
            },
            'Verification_3' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'udp',
                  'src' => 'vm.[2].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[4].vnic.[1]'
               }
            },
            'Verification_2' => {
               'NFdumpVerificaton' => {
                  'protocol' => 'icmp',
                  'src' => 'vm.[2].vnic.[1]',
                  'verificationtype' => 'nfdump',
                  'dst' => 'vm.[4].vnic.[1]'
               }
            }
         }
      },
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for VDL2.
#
# Input:
#       None.
#
# Results:
#       An instance/object of VDL2 class.
#
# Side effects:
#       None.
#
########################################################################

sub new
{
   my ($proto) = @_;
   my $class     = shift;
   my %options = @_;

   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%VDL2);
   $self->{'testSession'} = $options{"testSession"};
   return (bless($self, $class));
}


#######################################################################
#
# Setup --
#       Do pre-configuration for Vdl2;
#
# Input:
#       None.
#
# Results:
#       SUCCESS always;
#
# Side effects:
#       None.
#
########################################################################

sub Setup
{
   my $self    = shift;
   my $logger  = $self->{'testSession'}->{'logger'};

   if (FAILURE eq $self->SUPER::Setup(@_)) {
      $logger->Error("Failed to initialize using parent method");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ( ( ! $testSession->{"dontUpgSTAFSDK"}) &&
        ($ENV{CLASSPATH} !~ "commons-cli-1.2.jar" ||
         $ENV{CLASSPATH} !~ "vspancfgtool.jar")) {

      $logger->Info("Append commons-cli-1.2.jar and vspancfgtool.jar to " .
                    "CLASSPATH for PortMirror Java tools");

      my $globalConfig = VDNetLib::Common::GlobalConfig->new();
      my $vdNetRootPath = $globalConfig->GetVdNetRootPath();
      my $myLibPath = "$vdNetRootPath/bin/PortMirror_jar/vspanCfgTool/lib";
      my $libClassPath = "$myLibPath/commons-cli-1.2.jar:".
                         "$myLibPath/vspancfgtool.jar";
      $ENV{CLASSPATH} = $libClassPath . ":" . $ENV{CLASSPATH};
   }

   return SUCCESS;
}


#######################################################################
#
# Cleanup --
#       Clean settings changed in Setup.
#
# Input:
#       None.
#
# Results:
#       SUCCESS always;
#
# Side effects:
#       None.
#
########################################################################

sub Cleanup
{
   my $self = shift;
   my $logger  = $self->{'testSession'}->{'logger'};

   if ( FAILURE eq $self->SUPER::Cleanup(@_) ) {
      $logger->Error("Failed to initialize using parent method");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}

1;
