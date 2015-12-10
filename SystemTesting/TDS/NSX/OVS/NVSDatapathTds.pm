#!/usr/bin/perl
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::OVS::NVSDatapathTds;

@ISA = qw(TDS::Main::VDNetMainTds);
#
# This file contains the structured hash for NVSDatapath tests
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

use constant STANDARD_TRAFFIC_SESSION => {
   Type           => "Traffic",
   ToolName       => "netperf",
   TestAdapter    => "vm.[1].vnic.[1]",
   SupportAdapter => "vm.[2].vnic.[1]",
   L3Protocol     => "ipv4",
   L4Protocol     => "tcp",
   parallelsession   => "yes",
   SendMessageSize   => "63488",
   NoofOutbound      => "1",
   NoofInbound       => "1",
   LocalSendSocketSize => "131072",
   RemoteSendSocketSize => "131072",
   TestDuration         => "10",
};

#
# Begin test cases
#
{
   %NVSDatapath = (
      'NoUplink' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "NoUplink",
         Version          => "2" ,
         Tags             => "precheckin",
         Summary          => "This is the precheck-in test case ".
                             "for OVS with no uplinks",
         ExpectedResult   => "PASS",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::ovsOneHostTopology01,

         WORKLOADS => {
            Sequence   => [
                          ['Traffic'],
                          ],

            'Traffic' => STANDARD_TRAFFIC_SESSION,
         },
      },
      'GRE64Tunnel' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "GRE64Tunnel",
         Version          => "2" ,
         Summary          => "This is the precheck-in unit test case ".
                             "for GRE64 tunneling",
         ExpectedResult   => "PASS",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::ovsTwoHostTopology01,

         WORKLOADS => {
            Sequence   => [
                           ['AddUplinkOnHost1', 'AddUplinkOnHost2'],
                           ['EditUplinkOnHost1', 'EditUplinkOnHost2'],
                           ['AssignIP'],
                           ['AddGRE64PortsOnHost1', 'AddGRE64PortsOnHost2'],
                           ['AddFlowsOnHost1', 'AddFlowsOnHost2'],
                           ['Traffic1'],
                           ],
            ExitSequence => [
                               ["DeletePorts1", "DeletePorts2"],
                               ['RemoveUplinkIPOnHost1', 'RemoveUplinkIPOnHost2'],
                               ['RemoveUplinkOnHost1', 'RemoveUplinkOnHost2'],
                            ],

            'AddUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "add",
            },
            'AddUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "add",
            },
            'EditUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            'EditUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            'RemoveUplinkIPOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkIPOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "remove",
            },
            'RemoveUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "remove",
            },
            'AssignIP'  => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-2].vnic.[1]",
               ipv4        => "AUTO",
               configure_offload =>{  #workaround for redmine #15763
                 offload_type => "tsoipv4",
                 enable       => "false",
               },
            },
            'AddGRE64PortsOnHost1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               port => {
                  '[1]' => {
                     bridge   => "br-int",
                     type     => "gre64",
                     name     => "gre640",
                     remotetunnel => "host.[2].vmnic.[1]",
                  },
               },
            },
            'AddGRE64PortsOnHost2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               port => {
                  '[1]' => {
                     bridge   => "br-int",
                     type     => "gre64",
                     name     => "gre640",
                     remotetunnel => "host.[1].vmnic.[1]",
                  },
               },
            },
            'AddFlowsOnHost1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               AddFlow => [
                     {
                        protocol    => ['ip', 'arp', 'tcp', 'udp'],
                        destination => "vm.[2].vnic.[1]",
                        gateway     => "host.[1].ovs.[1].port.[1]",
                     },
               ],
            },
            'AddFlowsOnHost2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               AddFlow => [
                     {
                        protocol    => ['ip', 'arp', 'tcp', 'udp'],
                        destination => "vm.[1].vnic.[1]",
                        gateway     => "host.[2].ovs.[1].port.[1]",
                     },
               ],
            },
            'DeletePorts1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               DeletePort => "host.[1].ovs.[1].port.[1]",
            },
            'DeletePorts2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               DeletePort => "host.[2].ovs.[1].port.[1]",
            },
            'InitVmknic1'   => {
               Type        => "NetAdapter",
               TestAdapter => "host.[1-2].vmknic.[1]",
               IPv4        => "none",
            },
            'InitVmknic2'   => {
               Type        => "NetAdapter",
               TestAdapter => "host.[1-2].vmknic.[1]",
               IPv4        => "dhcp",
            },
            'Traffic1' => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4,ipv6",
               L4Protocol      => "tcp",
               parallelsession => "yes",
               SendMessageSize => "1024,2048,4096,8192," .
                                  "16384,32768,64512",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "10",
            },
         },
      },
      'STTTunnel' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "STTTunnel",
         Version          => "2" ,
         Tags             => "precheckin",
         Summary          => "This is the precheck-in unit test case ".
                             "for STT tunneling",
         ExpectedResult   => "PASS",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::ovsTwoHostTopology01,

         WORKLOADS => {
            Sequence   => [
                           ['AddUplinkOnHost1', 'AddUplinkOnHost2'],
                           ['EditUplinkOnHost1', 'EditUplinkOnHost2'],
                           ['AssignIP'],
                           ['AddSTTPortsOnHost1', 'AddSTTPortsOnHost2'],
                           ['AddFlowsOnHost1', 'AddFlowsOnHost2'],
                           ['Traffic1'],
                           ],
            ExitSequence => [
                               ["DeletePorts1", "DeletePorts2"],
                               ['RemoveUplinkIPOnHost1', 'RemoveUplinkIPOnHost2'],
                               ['RemoveUplinkOnHost1', 'RemoveUplinkOnHost2'],
                            ],

            'AddUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "add",
            },
            'AddUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "add",
            },
            'EditUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            'EditUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            'RemoveUplinkIPOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkIPOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "remove",
            },
            'RemoveUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "remove",
            },
            'AssignIP'  => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-2].vnic.[1]",
               ipv4        => "AUTO",
               #tsoipv4     => "disable" #workaround for redmine #15763

            },
            'AddSTTPortsOnHost1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               port => {
                  '[1]' => {
                     bridge   => "br-int",
                     type     => "stt",
                     name     => "stt0",
                     remotetunnel => "host.[2].vmnic.[1]",
                  },
               },
            },
            'AddSTTPortsOnHost2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               port => {
                  '[1]' => {
                     bridge   => "br-int",
                     type     => "stt",
                     name     => "stt0",
                     remotetunnel => "host.[1].vmnic.[1]",
                  },
               },
            },
            'AddFlowsOnHost1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               AddFlow => [
                     {
                        protocol    => ['ip', 'arp', 'tcp', 'udp'],
                        destination => "vm.[2].vnic.[1]",
                        gateway     => "host.[1].ovs.[1].port.[1]",
                     },
               ],
            },
            'AddFlowsOnHost2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               AddFlow => [
                     {
                        protocol    => ['ip', 'arp', 'tcp', 'udp'],
                        destination => "vm.[1].vnic.[1]",
                        gateway     => "host.[2].ovs.[1].port.[1]",
                     },
               ],
            },
            'DeletePorts1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               DeletePort => "host.[1].ovs.[1].port.[1]",
            },
            'DeletePorts2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               DeletePort => "host.[2].ovs.[1].port.[1]",
            },
            'InitVmknic1'   => {
               Type        => "NetAdapter",
               TestAdapter => "host.[1-2].vmknic.[1]",
               IPv4        => "none",
            },
            'InitVmknic2'   => {
               Type        => "NetAdapter",
               TestAdapter => "host.[1-2].vmknic.[1]",
               IPv4        => "dhcp",
            },
            'Traffic1' => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4,ipv6",
               L4Protocol      => "tcp",
               parallelsession => "yes",
               SendMessageSize => "1024,2048,4096,8192," .
                                  "16384,32768,64512",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "10",
            },
         },
      },
      'VxLANTunnel' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "VxLANTunnel",
         Version          => "2" ,
         Summary          => "Test to cover extensive IO session ".
                             "for VxLAN tunneling",
         ExpectedResult   => "PASS",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::ovsTwoHostTopology01,

         WORKLOADS => {
            Sequence   => [
                           ['AddUplinkOnHost1', 'AddUplinkOnHost2'],
                           ['EditUplinkOnHost1', 'EditUplinkOnHost2'],
                           ['AssignIP'],
                           ['AddVxLANPortsOnHost1', 'AddVxLANPortsOnHost2'],
                           ['AddFlowsOnHost1', 'AddFlowsOnHost2'],
                           ['Traffic1'],
                           ],
            ExitSequence => [
                               ["DeletePorts1", "DeletePorts2"],
                               ['RemoveUplinkIPOnHost1', 'RemoveUplinkIPOnHost2'],
                               ['RemoveUplinkOnHost1', 'RemoveUplinkOnHost2'],
                            ],

            'AddUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "add",
            },
            'AddUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "add",
            },
            'EditUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            'EditUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            'RemoveUplinkIPOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkIPOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "remove",
            },
            'RemoveUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "remove",
            },
            'AssignIP'  => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-2].vnic.[1]",
               ipv4        => "AUTO",
               configure_offload =>{  #workaround for redmine #15763
                 offload_type => "tsoipv4",
                 enable       => "false",
               },
            },
            'AddVxLANPortsOnHost1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               port => {
                  '[1]' => {
                     bridge   => "br-int",
                     type     => "vxlan",
                     name     => "vxlan0",
                     remotetunnel => "host.[2].vmnic.[1]",
                  },
               },
            },
            'AddVxLANPortsOnHost2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               port => {
                  '[1]' => {
                     bridge   => "br-int",
                     type     => "vxlan",
                     name     => "vxlan0",
                     remotetunnel => "host.[1].vmnic.[1]",
                  },
               },
            },
            'AddFlowsOnHost1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               AddFlow => [
                     {
                        protocol    => ['ip', 'arp', 'tcp', 'udp'],
                        destination => "vm.[2].vnic.[1]",
                        gateway     => "host.[1].ovs.[1].port.[1]",
                     },
               ],
            },
            'AddFlowsOnHost2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               AddFlow => [
                     {
                        protocol    => ['ip', 'arp', 'tcp', 'udp'],
                        destination => "vm.[1].vnic.[1]",
                        gateway     => "host.[2].ovs.[1].port.[1]",
                     },
               ],
            },
            'DeletePorts1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               DeletePort => "host.[1].ovs.[1].port.[1]",
            },
            'DeletePorts2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               DeletePort => "host.[2].ovs.[1].port.[1]",
            },
            'InitVmknic1'   => {
               Type        => "NetAdapter",
               TestAdapter => "host.[1-2].vmknic.[1]",
               IPv4        => "none",
            },
            'InitVmknic2'   => {
               Type        => "NetAdapter",
               TestAdapter => "host.[1-2].vmknic.[1]",
               IPv4        => "dhcp",
            },
            'Traffic1' => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4, ipv6",
               L4Protocol      => "tcp",
               parallelsession => "yes",
               SendMessageSize => "1024,2048,4096,8192," .
                                  "16384,32768,64512",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "10",
            },
         },
      },
      'UplinkPortChanges' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "UplinkPortChanges",
         Version          => "2" ,
         Tags             => "physical",
         Summary          => "This is to impact on connections on ovs ports ".
                             "when the uplink ports are disconnected",
         ExpectedResult   => "PASS",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::ovsTwoHostTopology01,

         WORKLOADS => {
            Sequence   => [
               ['Initpswitchport'],
               ['AddUplinkOnHost1', 'AddUplinkOnHost2'],
               ['EditUplinkOnHost1', 'EditUplinkOnHost2'],
               ['AssignIP'],
               ['AddSTTPortsOnHost1', 'AddSTTPortsOnHost2'],
               ['AddFlowsOnHost1', 'AddFlowsOnHost2'],
               ['Traffic1'],
               ['DisablePort'],
               ['TrafficFail'],
               ['EnablePort'],
               ['Traffic1'],
            ],
            ExitSequence => [
               ["DeletePorts1", "DeletePorts2"],
               ['RemoveUplinkIPOnHost1', 'RemoveUplinkIPOnHost2'],
               ['RemoveUplinkOnHost1', 'RemoveUplinkOnHost2'],
            ],

            'Initpswitchport' => {
               Type  => "Host",
               TestHost => "host.[1]",
               pswitchport => {
                  '[1]' => {
                     vmnic => "host.[1].vmnic.[1]",
                  },
               },
            },
            "DisablePort" => {
               Type         => "Port",
               TestPort     => "host.[1].pswitchport.[1]",
               portstatus   => "disable",
            },

            "EnablePort" => {
               Type         => "Port",
               TestPort     => "host.[1].pswitchport.[1]",
               portstatus   => "enable",
            },
            'AddUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "add",
            },
            'AddUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "add",
            },
            'EditUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            'EditUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "dhcp",
            },
            'RemoveUplinkIPOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkIPOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "edit",
               ipv4address => "none",
            },
            'RemoveUplinkOnHost1' => {
               Type        => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               vmnicadapter => "host.[1].vmnic.[1]",
               configureuplinks => "remove",
            },
            'RemoveUplinkOnHost2' => {
               Type        => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               vmnicadapter => "host.[2].vmnic.[1]",
               configureuplinks => "remove",
            },
            'AssignIP'  => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1-2].vnic.[1]",
               ipv4        => "AUTO",
               configure_offload =>{  #workaround for redmine #15763
                 offload_type => "tsoipv4",
                 enable       => "false",
               },
            },
            'AddSTTPortsOnHost1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               port => {
                  '[1]' => {
                     bridge   => "br-int",
                     type     => "stt",
                     name     => "stt0",
                     remotetunnel => "host.[2].vmnic.[1]",
                  },
               },
            },
            'AddSTTPortsOnHost2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               port => {
                  '[1]' => {
                     bridge   => "br-int",
                     type     => "stt",
                     name     => "stt0",
                     remotetunnel => "host.[1].vmnic.[1]",
                  },
               },
            },
            'AddFlowsOnHost1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               AddFlow => [
                     {
                        protocol    => ['ip', 'arp', 'tcp', 'udp'],
                        destination => "vm.[2].vnic.[1]",
                        gateway     => "host.[1].ovs.[1].port.[1]",
                     },
               ],
            },
            'AddFlowsOnHost2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               AddFlow => [
                     {
                        protocol    => ['ip', 'arp', 'tcp', 'udp'],
                        destination => "vm.[1].vnic.[1]",
                        gateway     => "host.[2].ovs.[1].port.[1]",
                     },
               ],
            },
            'DeletePorts1'  => {
               Type     => "Switch",
               TestSwitch  => "host.[1].ovs.[1]",
               DeletePort => "host.[1].ovs.[1].port.[1]",
            },
            'DeletePorts2'  => {
               Type     => "Switch",
               TestSwitch  => "host.[2].ovs.[1]",
               DeletePort => "host.[2].ovs.[1].port.[1]",
            },
            'InitVmknic1'   => {
               Type        => "NetAdapter",
               TestAdapter => "host.[1-2].vmknic.[1]",
               IPv4        => "none",
            },
            'InitVmknic2'   => {
               Type        => "NetAdapter",
               TestAdapter => "host.[1-2].vmknic.[1]",
               IPv4        => "dhcp",
            },
            'Traffic1' => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",#ipv6",
               L4Protocol      => "tcp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "10",
            },
            'TrafficFail' => {
               Type            => "Traffic",
               ToolName        => "ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               ExpectedResult  => "FAIL",
            },
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for OVSTds
#
# Input:
#       none
#
# Results:
#       An instance/object of SampleTds class
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
   my $self = $class->SUPER::new(\%NVSDatapath);
   return (bless($self, $class));
}

1;

