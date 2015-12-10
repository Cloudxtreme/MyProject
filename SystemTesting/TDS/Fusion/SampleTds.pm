#!/usr/bin/perl
########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::Fusion::SampleTds;

#
# This file contains the structured hash for virtual network devices tests.
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use Data::Dumper;
use TDS::Main::VDNetMainTds;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack );

@ISA = qw(TDS::Main::VDNetMainTds);

{
    # List of tests in this test category
    # Assuming in all the test-cases that Fusion is installed, and the SUT and
    # helper VMs are installed and also have Tools installed in them.
    @TESTS = ("IcmpTrafficNat", "DefaultBridgeDaemon", "VirtualNetAdapters",
              "VmnetProcesses", "DisableDHCPServiceBridged", "BridgedIcmpTrafficHostToGuest",
              "BridgedIcmpTrafficGuestToGuest", "NatIcmpTrafficHostToGuest",
              "PingIpv6HostToVM", "PingIpv6VMToVM", "IperfTSOIpv6VMToVM",
              "IperfTSOIpv6HostToVM", "Ipv6SuspendResumeHToG",
              "Ipv6SnapshotHToG", "SubnetDirectedBroadcastFromVM",
              "Ipv6TSOSuspendResumeGToG", "Ipv6TSOSuspendResumeHToG",
              "Ipv6TSOSnapshotRevert", "SubnetDirectedBroadcastFromHost",
              "NatConnectionStress", "BroadcastBridgedHostToVMNatAndBridge",
              "BroadcastBridgedVMToVMNatAndBridge", "BroadcastNatHostToVMNatAndBridge",
              "DisableDHCPServiceHostOnly", "PingIpv6VMToHost",
              "BridgedIcmpTrafficGuestToHost", "NatIcmpTrafficGuestToHost");

    %Sample = (

        'IcmpTrafficNat' => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "IcmpTraffic",
            Summary              => "Run Ping traffic stressing both inbound and " .
                                    "outbound path",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                },
                helper1 => {
                    host         => 1,
                },
            },

            WORKLOADS  => {
                Iterations       =>  "1",
                Sequence         => [['NetAdapter_1'], ['VMOperation_1'],
                                     ['PingTraffic'], ['IperfTraffic']],

                "NetAdapter_1" => {
                   Type           => "NetAdapter",
                   Target         => "SUT,helper1",
                   TestAdapter    => "1",
                   MTU            => "1500",
                },

                "VMOperation_1" => {
                   Type           => "VM",
                   Target         => "SUT",
                   Iterations     => "1",
                   Operation      => "suspend,resume",
                },

                "IperfTraffic"     => {
                   Type           => "Traffic",
                   ToolName       => "Iperf",
                   l4protocol     => "tcp,udp",
                   NoofInbound    => "1",
                   NoofOutbound   => "1",
                },

                "PingTraffic"     => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   NoofOutbound   => "1",
                   NoofInbound   => "1",
                },
            }
        },

        'DefaultBridgeDaemon' => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "DefaultBridgeDaemon",
            Summary              => "DefaultBridgeDaemon",
            ExpectedResult       => "PASS",

            Parameters        => {
               SUT            => {
                 host        => 1,
                },
            },

            WORKLOADS => {
                Sequence          => [['getdaemonprocess']],

                "getdaemonprocess" => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "ps -ax | grep vmnet-bridge",
                    Args           => "",
                    expectedString => "/var/run/vmnet-bridge-vmnet.pid",
                },
            },
        },

        'VirtualNetAdapters' => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "VirtualNetAdapters",
            Summary              => "VirtualNetAdapters",
            ExpectedResult       => "PASS",
            Parameters        => {
               SUT            => {
                   host        => 1,
                },
            },

            WORKLOADS => {
                Sequence           => [['getvmnet1'], ['getvmnet8']],
                Duration           => "time in seconds",
                "getvmnet1"        => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "ifconfig | grep vmnet1",
                    Args           => "",
                    expectedString => "vmnet1",
                },
                "getvmnet8"        => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "ifconfig | grep vmnet8",
                    Args           => "",
                    expectedString => "vmnet8",
                },
            },
        },

        'VmnetProcesses' => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "VmnetProcesses",
            Summary              => "VmnetProcesses",
            ExpectedResult       => "PASS",
            Parameters        => {
               SUT            => {
                    host        => 1,
                },
            },

            # TODO: To extend the command workload to return the number of process
            # instances. For eg: for the workload below, the number of netif-up
            # processes should be equal to the number of VMs that are on, and
            # command workload should return each of them.
            WORKLOADS  => {
                Sequence           => [['getvmnetbridge'], ['getvmnetdhcpd'],
                                      ['getvmnetnetifup'], ['getvmnetnatd']],
                Duration           => "time in seconds",
                "getvmnetbridge"   => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "ps auxc | grep vmnet-bridge",
                    Args           => "",
                    expectedString => "vmnet-bridge",
                },
                "getvmnetdhcpd"    => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "ps auxc | grep vmnet-dhcpd",
                    Args           => "",
                    expectedString => "vmnet-dhcpd",
                },
                "getvmnetnetifup"  => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "ps auxc | grep vmnet-netifup",
                    Args           => "",
                    expectedString => "vmnet-netifup",
                },
                "getvmnetnatd"     => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "ps auxc | grep vmnet-natd",
                    Args           => "",
                    expectedString => "vmnet-natd",
                },
            },
        },

        'DisableDHCPServiceBridged' => {
            Component            => "Host",
            Category             => "Sample",
            TestName             => "DisableDHCPServiceBridged",
            Summary              => "Restart the vmnet8 service in host " .
                                    " and re-restart it and check if the " .
                                    " VM receives the changed IP",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                # Assuming here that the helper VM is Windows.
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            # TODO: Add a process in vdnet to validate the IP address obtained
            # against the expected IP address format when it aquires an address
            # in the vmnet8 subnet.This can be called in the the "validateNewIpAddress"
            # workload.
            WORKLOADS => {
                Sequence           => [#['VMOperations_1'],
                                       ['killvmnet8dhcpd'],
                                       ['vmipconfigrelease'],['vmipconfigrenew'],
                                       ['startvmnet8dhcpd'], ['vmipconfigrenew'],
                                       ['PingTraffic']
                                       # ,['validateNewIpAddress'],
                                      ],
                Duration           => "time in seconds",

                'VMOperations_1'  => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                "killvmnet8dhcpd" => {
                   Type           => "Host",
                   Target         => "SUT",
                   killvmprocess  => "killvmprocess",
                   processname    => "vmnet-dhcpd-vmnet8",
                },

                'startvmnet8dhcpd' => {
                    Type           => "Host",
                    Target         => "SUT",
                    startvmnetdhcp => "startvmnetdhcp",
                    vmnetname      => "vmnet8",
                },

                'vmipconfigrelease' => {
                    Type           => "Command",
                    Target         => "VM",
                    HostType       => "darwin",
                    Command        => "ipconfig /release",
                    Args           => "",
                    expectedString => "",
                },

                'vmipconfigrenew' => {
                    Type           => "Command",
                    Target         => "VM",
                    HostType       => "darwin",
                    Command        => "ipconfig /renew",
                    Args           => "",
                    expectedString => "",
                },

                "PingTraffic"     => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   NoofOutbound   => "1",
                   NoofInbound    => "1",
                },

            },
        },

        'BridgedIcmpTrafficHostToGuest'   => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "BridgedIcmpTrafficHostToGuest",
            Summary              => "Send ping traffic between the host and".
                                    " the guest.for 100 seconds",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [#['VMOPERATION_1'],
                                       ['TRAFFIC_1']],
                Duration           => "time in seconds",

                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'TRAFFIC_1'  => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofOutbound  => "1",
                    TestDuration  => "100",
                },
            },
        },


        'BridgedIcmpTrafficGuestToHost'   => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "BridgedIcmpTrafficHostToGuest",
            Summary              => "Send ping traffic between the host and".
                                    " the guest.for 100 seconds",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [#['VMOPERATION_1'],
                                       ['TRAFFIC_1']],
                Duration           => "time in seconds",

                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'TRAFFIC_1'  => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofInbound   => "1",
                    TestDuration  => "100",
                },
            },
        },


        'BridgedIcmpTrafficGuestToGuest'   => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "BridgedIcmpTrafficGuestToGuest",
            Summary              => "Send ping traffic between two guests",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [#['VMOPERATION_1'],
                                       ['TRAFFIC_1']],
                Duration           => "time in seconds",

                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    TestDuration  => "100",
                },
            },
        },

        'NatIcmpTrafficHostToGuest'   => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "NatIcmpTrafficHostToGuest",
            Summary              => "Send ping traffic between the host and".
                                    " the guest, the guest being in the nat mode",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [# ['VMOPERATION_1'],
                                      ['TRAFFIC_1']],
                Duration           => "time in seconds",

                # TODO: To write a method to change the networking mode of an
                # NIC on the fly.
                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofOutbound  => "1",
                    TestDuration  => "100",
                },

            },
        },

        'NatIcmpTrafficGuestToHost'   => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "NatIcmpTrafficHostToGuest",
            Summary              => "Send ping traffic between the host and".
                                    " the guest, the guest being in the nat mode",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [# ['VMOPERATION_1'],
                                      ['TRAFFIC_1']],
                Duration           => "time in seconds",

                # TODO: To write a method to change the networking mode of an
                # NIC on the fly.
                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofInbound   => "1",
                    TestDuration  => "100",
                },

            },
        },

        'PingIpv6HostToVM'       => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "PingIpv6HostToVM",
            Summary              => "Send ping traffic between the host and".
                                    " the guest. using the ipv6 address",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [#['VMOperations_1'],
                                       ['TRAFFIC_1']],
                Duration           => "time in seconds",

                'VMOperations_1'  => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                },
            },
        },

        'PingIpv6VMToHost'       => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "PingIpv6HostToVM",
            Summary              => "Send ping traffic between the host and".
                                    " the guest. using the ipv6 address",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [#['VMOperations_1'],
                                       ['TRAFFIC_1']],
                Duration           => "time in seconds",

                'VMOperations_1'  => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofInbound   => "1",
                    L3Protocol    => "ipv6",
                },
            },
        },


        'PingIpv6VMToVM'       => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "PingIpv6VMToVM",
            Summary              => "Send ping traffic between two VMs".
                                    " using the ipv6 address",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [#['VMOperations_1'],
                                       ['TRAFFIC_1']],
                Duration           => "time in seconds",

                'VMOperations_1'  => {
                   Type           => "VM",
                   Target         => "helper1,SUT",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                },
            },
        },


        'IperfTSOIpv6VMToVM'       => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "IperfTSOIpv6VMToVM",
            Summary              => "Send iperf traffic between two VMs".
                                    " using the ipv6 address",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [#['VMOperations_1'],
                                       ['TRAFFIC_1']],
                Duration           => "time in seconds",

                'VMOperations_1'  => {
                   Type           => "VM",
                   Target         => "helper1,SUT",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "iperf",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                },
            },
        },

        # TODO: The VMs have to be bridged to both the wired and the wireless
        # physical interface and tested with traffic workload for both the cases.
        'IperfTSOIpv6HostToVM'   => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "IperfTSOIpv6HostToVM",
            Summary              => "Send iperf traffic between the host and".
                                    " the guest. using the ipv6 address",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS => {
                Sequence           => [['TRAFFIC_1']],
                Duration           => "time in seconds",

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "iperf",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                },
            },
        },


        'Ipv6TSOSuspendResumeGToG'   => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "Ipv6SuspendResumeHToG",
            Summary              => "Ping from the host to guest and ".
                                    "vice-versa , then suspend and resume".
                                    " the VM and ping again both ways",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                    host         => 1,
                },
                # We intend to use a remote host as helper2 in this case.
                helper2 => {
                    host         => 2,
                },
            },

            WORKLOADS            => {
                Sequence           => [['VMOperations_2'], ['TRAFFIC_1'],
                                       ['VMOPERATION_3'],['TRAFFIC_2'],
                                       ['VMOperations_1'], ['TRAFFIC_1'],
                                       ['VMOPERATION_3'],['TRAFFIC_2'],
                                       ['TRAFFIC_3']],
                Duration           => "time in seconds",

                'VMOperations_1'  => {
                   Type           => "VM",
                   Target         => "SUT",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'VMOperations_2'  => {
                   Type           => "VM",
                   Target         => "SUT,helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                    TestAdapter   => "SUT:vnic:1",
                    SupportAdapter => "helper1:vnic:1"
                },

                "VMOPERATION_3" => {
                   Type           => "VM",
                   Target         => "SUT",
                   Iterations     => "1",
                   Operation      => "suspend,resume",
                },

                'TRAFFIC_2'       => {
                    Type          => "Traffic",
                    ToolName      => "iperf",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                    TestAdapter   => "SUT:vnic:1",
                    SupportAdapter => "helper1:vnic:1"
                },

                'TRAFFIC_3'       => {
                    Type          => "Traffic",
                    ToolName      => "iperf",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                    TestAdapter   => "SUT:vnic:1",
                    SupportAdapter => "helper2:vmnic:1"
                },
            },
        },


        'Ipv6SnapshotHToG'       => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "Ipv6SnapshotHToG",
            Summary              => "Ping from the host to guest and ".
                                    "vice-versa , then take the snapshot".
                                    " the VM and ping again both ways",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS            => {
                Sequence           => [['TRAFFIC_1'], ['VMOPERATIONS_1'],
                                      ['TRAFFIC_1']],
                Duration           => "time in seconds",
                ExitSequence      => [ ['SnapshotDelete']],

                "SnapshotDelete" => {
                   Type           => "VM",
                   Target         => "SUT",
                   Iterations     => "1",
                   Operation      => "rmsnap",
                   SnapshotName   => "snapshot_sut",
                   WaitForVDNet   => "1"
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                },

                "VMOPERATIONS_1" => {
                   Type           => "VM",
                   Target         => "SUT",
                   Iterations     => "1",
                   Operation      => "CREATESNAP,REVERTSNAP",
                   Snapshotname   => "snapshot_sut",
                },

            },
        },


        'Ipv6SuspendResumeHToG'   => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "Ipv6TSOSuspendResumeHToG",
            Summary              => "Send iperf traffic from host to guest and ".
                                    "vice-versa , then suspend and resume".
                                    " the VM and send traffic again both ways",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS            => {
                Sequence           => [['TRAFFIC_1'], ['VMOPERATION_1'],
                                       ['TRAFFIC_1']],
                Duration           => "time in seconds",

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                },

                "VMOPERATION_1" => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "suspend,resume",
                },

            },
        },

        # TODO: Check for similarity to IperfTSOIpv6HostToVM
        'Ipv6TSOSuspendResumeHToG'   => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "Ipv6TSOSuspendResumeHToG",
            Summary              => "Send iperf traffic from host to guest and ".
                                    "vice-versa , then suspend and resume".
                                    " the VM and send traffic again both ways",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS            => {
                Sequence           => [['TRAFFIC_1'], ['VMOPERATION_1'],
                                       ['VMOPERATION_2'], ['TRAFFIC_1']],
                Duration           => "time in seconds",

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "iperf",
                    NoofInbound   => "2",
                    RoutingScheme => "unicast",
                    NoofOutbound  => "2",
                    L3Protocol    => "ipv6",
                },

                "VMOPERATION_1" => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "suspend",
                },

                "VMOPERATION_2" => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "resume",
                },
            },
        },


        'Ipv6TSOSnapshotRevert'  => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "Ipv6SuspendResumeHToG",
            Summary              => "Ping from the host to guest and ".
                                    "vice-versa , then suspend and resume".
                                    " the VM and ping again both ways",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                    host         => 1,
                },
                # We intend to use a remote host as helper2 in this case.
                helper2 => {
                    host         => 2,
                },
            },

            WORKLOADS            => {
                Sequence           => [['VMOperations_2'], ['TRAFFIC_1'],
                                       ['VMOPERATION_3'],['TRAFFIC_2'],
                                       ['VMOperations_1'], ['TRAFFIC_1'],
                                       ['VMOPERATION_3'],['TRAFFIC_2'],
                                       ['TRAFFIC_3']],
                Duration           => "time in seconds",
                ExitSequence      => [['SnapshotDelete']],

                "SnapshotDelete" => {
                   Type           => "VM",
                   Target         => "SUT",
                   Iterations     => "1",
                   Operation      => "rmsnap",
                   SnapshotName   => "snapshot_sut",
                   WaitForVDNet   => "1"
                },

                'VMOperations_1'  => {
                   Type           => "VM",
                   Target         => "SUT",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'VMOperations_2'  => {
                   Type           => "VM",
                   Target         => "SUT,helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                'TRAFFIC_1'       => {
                    Type          => "Traffic",
                    ToolName      => "ping",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                    TestAdapter   => "SUT:vnic:1",
                    SupportAdapter => "helper1:vnic:1"
                },

                "VMOPERATION_3" => {
                   Type           => "VM",
                   Target         => "SUT",
                   Iterations     => "1",
                   Operation      => "CREATESNAP,REVERTSNAP",
                },

                'TRAFFIC_2'       => {
                    Type          => "Traffic",
                    ToolName      => "iperf",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                    TestAdapter   => "SUT:vnic:1",
                    SupportAdapter => "helper1:vnic:1"
                },

                'TRAFFIC_3'       => {
                    Type          => "Traffic",
                    ToolName      => "iperf",
                    NoofInbound   => "1",
                    NoofOutbound  => "1",
                    L3Protocol    => "ipv6",
                    TestAdapter   => "SUT:vnic:1",
                    SupportAdapter => "helper2:vmnic:1"
                },
            },
        },


        'NatConnectionStress'     => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "NatConnectionStress",
            Summary              => "Open up connections from NAT VMs to the".
                                    "the outside network, and then stop all the ".
                                    "VMs all of a sudden, the network connections".
                                    " should close",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper2 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper3 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper4 => {
                    # We intend to use a remote host as the helper4
                    host         => 2,
                },
            },

            # Assumption here is that all the 3 VMs and the 1 SUT is powered on.
            # and have tools installed.
            WORKLOADS           => {
                Sequence           => [['TRAFFIC_1', 'TRAFFIC_2', 'TRAFFIC_3',
                                       'VMOPERATIONS_1'],['COMMAND_1']],
                Duration           => "time in seconds",


                "VMOPERATIONS_1"  => {
                   Type           => "VM",
                   SleepBetweenCombos => "30",
                   Target         => "helper1,helper2,helper3",
                   Operation      => "poweroff",
                },

                # TODO: Check the format of supplying the host adapter as the
                # support adapter, because traffic module expects Support
                # adapter to be a 'vnic'. And when a host is passed as :
                # 10.20.132.120:10.20.132.120,vnic='e1000', it looks for
                # the vmx file of the same.
                "TRAFFIC_1"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   TestAdapter    => "helper1:vnic:1",
                   SupportAdapter => "helper4:vmnic:1",
                },

                "TRAFFIC_2"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   TestAdapter    => "helper2:vnic:1",
                   SupportAdapter => "helper4:vnic:1",
                },

                "TRAFFIC_3"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   TestAdapter    => "helper3:vnic:1",
                   SupportAdapter => "helper4:vnic:1",
                },

                "COMMAND_1"        => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "lsof -n | grep vmnet",
                    Args           => "",
                    expectedString => " ",
                }
            },
        },


        'BroadcastBridgedHostToVMNatAndBridge' => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "BroadcastHostToVMNatAndBridge",
            Summary              => "Two out of the three helper VMs should be ".
                                    "in the bridged mode and one VM should be in ".
                                    "the NAT mode. When a broadcast traffic is ".
                                    "initiated from the host to the VMs, the VM".
                                    " in the NAT mode should not receive the ping",
            ExpectedResult       => "PASS",

            # Assuming here that helper1 and helper2 is in the bridged mode and
            # the helper3 is in the NAT mode. And that the VMs have Tools
            # installed.
            Parameters  => {

                # The host IP/adapter supplied here should be that of the
                # adapter to which the VMs are "bridged".
                # TODO: The functionality to accept the physical adapter of
                # the host needs to be added.
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper2 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper3 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS           => {
                Sequence           => [#['VMOPERATION_1'], ['VMOPERATION_2'],
                                       ['TRAFFIC_1', 'TRAFFIC_2', 'TRAFFIC_3']],
                Duration           => "time in seconds",

                "RSS"                    => {
                   Type                  => "NetAdapter",
                   Iterations            => "1",
                   Target                => "helper3",
                   TestAdapter           => "1",
                   Gateway               => "192.168.10.1",
                   Netmask               => "255.255.255.0",
                   Network               => "192.168.110.0",
                },

                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1,helper2",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'VMOPERATION_2'   => {
                   Type           => "VM",
                   Target         => "helper3",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                # TODO: Check the format of supplying the host adapter as the
                # support adapter, because traffic module expects Support
                # adapter to be a 'vnic'. And when a host is passed as :
                # 10.20.132.120:10.20.132.120,vnic='e1000', it looks for
                # the vmx file of the same.
                "TRAFFIC_1"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "20",
                   NoOfInbound    => "1",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "helper1:vnic:1",
                   SupportAdapter => "SUT:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "PASS",
                },

                "TRAFFIC_2"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "20",
                   NoOfInbound    => "1",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "helper2:vnic:1",
                   SupportAdapter => "SUT:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "PASS",
                },

                "TRAFFIC_3"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "20",
                   NoOfInbound    => "1",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "helper3:vnic:1",
                   SupportAdapter => "SUT:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "FAIL",
                },
            },
        },


        'BroadcastNatHostToVMNatAndBridge' => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "BroadcastHostToVMNatAndBridge",
            Summary              => "Two out of the three helper VMs should be ".
                                    "in the bridged mode and one VM should be in ".
                                    "the NAT mode. When a broadcast traffic is ".
                                    "initiated from the bridged VM to the VMs, the VM".
                                    " in the NAT mode should not receive the ping",
            ExpectedResult       => "PASS",

            # Assuming here that helper1 and helper2 is in the bridged mode and
            # the helper3 is in the NAT mode. Also that the VMs have Tools
            # installed.
            Parameters  => {

                # The host IP/adapter supplied here should be that of the
                # adapter to which the VMs are "bridged".
                # TODO: The functionality to accept the physical adapter of
                # the host needs to be added.
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper2 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper3 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS           => {
                Sequence           => [#['VMOPERATION_1'], ['VMOPERATION_3'],
                                       ['COMMAND_1', 'TRAFFIC_1', 'TRAFFIC_2',
                                       'TRAFFIC_3']],
                Duration           => "time in seconds",

                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1,helper2",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'VMOPERATION_3'   => {
                   Type           => "VM",
                   Target         => "helper3",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                # TODO: Check the format of supplying the host adapter as the
                # support adapter, because traffic module expects Support
                # adapter to be a 'vnic'. And when a host is passed as :
                # 10.20.132.120:10.20.132.120,vnic='e1000', it looks for
                # the vmx file of the same.
                "TRAFFIC_1"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vmnic:1",
                   SupportAdapter => "helper1:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "PASS",
                },

                "TRAFFIC_2"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vmnic:1",
                   SupportAdapter => "helper2:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "PASS",
                },

                "TRAFFIC_3"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vmnic:1",
                   SupportAdapter => "helper3:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "FAIL",
                },

                "COMMAND_1"        => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "ping 255.255.255.255",
                    Args           => "",
                    expectedString => " ",
                }
            },
        },

        # TODO: Provision to direct ping traffic to a particular subnet.
        # Currently as a workaround, a ping is generted through the
        # Command Workload(in this testcase and the similar testcase for host
        # to VMs), but for VMs, command workload will not work, as the comman
        # will run on the host.
        'BroadcastBridgedVMToVMNatAndBridge' => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "BroadcastHostToVMNatAndBridge",
            Summary              => "Two out of the three helper VMs should be ".
                                    "in the bridged mode and one VM should be in ".
                                    "the NAT mode. When a broadcast traffic is ".
                                    "initiated from one of the bridged VMs, the VM".
                                    " in the NAT mode should not receive the ping",
            ExpectedResult       => "PASS",

            # Assuming here that SUT and helper1 is in the bridged mode and
            # the helper2 is in the NAT mode. And that the VMs have Tools
            # installed.
            Parameters  => {

                # The host IP/adapter supplied here should be that of the
                # adapter to which the VMs are "nated", i.e the one in the
                # same subnet as the NAT'd VMs
                # TODO: The functionality to accept the physical adapter of
                # the host needs to be added.
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper2 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper3 => {
                    host         => 1,
                },
            },

            WORKLOADS           => {
                Sequence           => [#['VMOPERATION_1'], ['VMOPERATION_2'],
                                       ['COMMAND_1', 'TRAFFIC_1', 'TRAFFIC_2', 'TRAFFIC_3']],
                Duration           => "time in seconds",

                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1, SUT",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'VMOPERATION_2'   => {
                   Type           => "VM",
                   Target         => "helper2",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                # TODO: Check the format of supplying the host adapter as the
                # support adapter, because traffic module expects Support
                # adapter to be a 'vnic'. And when a host is passed as :
                # 10.20.132.120:10.20.132.120,vnic='e1000', it looks for
                # the vmx file of the same.
                "TRAFFIC_1"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vnic:1",
                   SupportAdapter => "helper1:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "FAIL",
                },

                "TRAFFIC_2"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vnic:1",
                   SupportAdapter => "helper2:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "FAIL",
                },

                "TRAFFIC_3"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vnic:1",
                   SupportAdapter => "helper3:vmnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "PASS",
                },

                "COMMAND_1"        => {
                    Type           => "Command",
                    Target         => "SUT",
                    HostType       => "darwin",
                    Command        => "ping 255.255.255.255",
                    Args           => "",
                    expectedString => " ",
                }
            },
        },

        'SubnetDirectedBroadcastFromHost' => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "BroadcastHostToVMNatAndBridge",
            Summary              => "Two out of the three helper VMs should be ".
                                    "in the bridged mode and one VM should be in ".
                                    "the NAT mode. When a broadcast traffic is ".
                                    "initiated from the bridged VM to the VMs, the VM".
                                    " in the NAT mode should not receive the ping",
            ExpectedResult       => "PASS",

            # Assuming here that helper1 and helper2 is in the bridged mode and
            # the helper3 is in the NAT mode. Also that the VMs have Tools
            # installed.
            Parameters  => {

                # The host IP/adapter supplied here should be that of the
                # adapter to which the VMs are "bridged".
                # TODO: The functionality to accept the physical adapter of
                # the host needs to be added.
                SUT  => {
                    host         => 1,
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper2 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper3 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            WORKLOADS           => {
                Sequence           => [#['VMOPERATION_1'], ['VMOPERATION_3'],
                                       ['TRAFFIC_4'], ['TRAFFIC_1', 'TRAFFIC_2',
                                       'TRAFFIC_3']],
                Duration           => "time in seconds",

                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1,helper2",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'VMOPERATION_3'   => {
                   Type           => "VM",
                   Target         => "helper3",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                # TODO: Check the format of supplying the host adapter as the
                # support adapter, because traffic module expects Support
                # adapter to be a 'vnic'. And when a host is passed as :
                # 10.20.132.120:10.20.132.120,vnic='e1000', it looks for
                # the vmx file of the same.
                "TRAFFIC_1"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vmnic:1",
                   SupportAdapter => "helper1:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "PASS",
                },

                "TRAFFIC_2"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vmnic:1",
                   SupportAdapter => "helper2:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "PASS",
                },

                "TRAFFIC_3"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vmnic:1",
                   SupportAdapter => "helper3:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "FAIL",
                },

                "TRAFFIC_4"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "20",
                   TestAdapter    => "helper3:vmnic:1",
                   SupportAdapter => "SUT:vnic:1",
                },

            },
        },

        'SubnetDirectedBroadcastFromVM' => {
            Component            => "vmxnet3",
            Category             => "Sample",
            TestName             => "SubnetDirectedBroadcast",
            Summary              => "Two out of the three helper VMs should be ".
                                    "in the bridged mode and one VM should be in ".
                                    "the NAT mode. When a broadcast traffic is ".
                                    "initiated from one of the bridged VMs, the VM".
                                    " in the NAT mode should not receive the ping".
                                    " The broadcast traffic will be initiated to ".
                                    "subnet the VM is part off",
            ExpectedResult       => "PASS",

            # Assuming here that helper1 and helper2 is in the bridged mode and
            # the helper3 is in the NAT mode. And that the VMs have Tools
            # installed.
            Parameters  => {

                # The host IP/adapter supplied here should be that of the
                # adapter to which the VMs are "nated", i.e the one in the
                # same subnet as the NAT'd VMs
                # TODO: The functionality to accept the physical adapter of
                # the host needs to be added.
                SUT  => {
                    vnic         => ['vmxnet3:1'],
                },
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper2 => {
                    vnic         => ['vmxnet3:1'],
                },
                helper3 => {
                    host         => 1,
                },
            },

            WORKLOADS           => {
                Sequence           => [#['VMOPERATION_1'], ['VMOPERATION_2'],
                                       ['TRAFFIC_4'],
                                       ['TRAFFIC_1', 'TRAFFIC_2', 'TRAFFIC_3']],
                Duration           => "time in seconds",

                'VMOPERATION_1'   => {
                   Type           => "VM",
                   Target         => "helper1, SUT",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "bridged",
                },

                'VMOPERATION_2'   => {
                   Type           => "VM",
                   Target         => "helper2",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "nat",
                },

                # TODO: Check the format of supplying the host adapter as the
                # support adapter, because traffic module expects Support
                # adapter to be a 'vnic'. And when a host is passed as :
                # 10.20.132.120:10.20.132.120,vnic='e1000', it looks for
                # the vmx file of the same.
                "TRAFFIC_1"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vnic:1",
                   SupportAdapter => "helper1:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "FAIL",
                },

                "TRAFFIC_2"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vnic:1",
                   SupportAdapter => "helper2:vnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "FAIL",
                },

                "TRAFFIC_3"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "100",
                   NoOfOutbound   => "1",
                   RoutingScheme  => "broadcast",
                   TestAdapter    => "SUT:vnic:1",
                   SupportAdapter => "helper3:vmnic:1",
                   Verification   => "pktcap",
                   ExpectedResult => "PASS",
                },

                "TRAFFIC_4"       => {
                   Type           => "Traffic",
                   ToolName       => "ping",
                   TestDuration   => "20",
                   TestAdapter    => "helper2:vnic:1",
                   SupportAdapter => "helper3:vmnic:1",
                },

            },
        },


        # TODO: We need to verify the IP acquired by the VM after the DHCP is
        # restarted, A new functionality needs to be added whether to the
        # NetAdapter Workload or to the HostOperations Workload.
        'DisableDHCPServiceHostOnly' => {
            Component            => "Host",
            Category             => "Sample",
            TestName             => "DisableDHCPServiceBridged",
            Summary              => "Restart the vmnet8 service in host " .
                                    " and re-restart it and check if the " .
                                    " VM receives the changed IP",
            ExpectedResult       => "PASS",

            Parameters  => {
                SUT  => {
                    host         => 1,
                },
                # Assuming here that the helper VM is Windows.
                helper1 => {
                    vnic         => ['vmxnet3:1'],
                },
            },

            # TODO: Add a process in vdnet to validate the IP address obtained
            # against the expected IP address format when it aquires an address
            # in the vmnet8 subnet.This can be called in the the "validateNewIpAddress"
            # workload.
            WORKLOADS => {
                Sequence           => [#['VMOperations_1'],
                                       ['killvmnet1dhcpd'],
                                       ['DHCPEnableDisable'],
                                       ['startvmnet1dhcpd'], ['DHCPEnable']
                                       # ,['validateNewIpAddress'],
                                      ],
                Duration           => "time in seconds",

                'VMOperations_1'  => {
                   Type           => "VM",
                   Target         => "helper1",
                   Iterations     => "1",
                   Operation      => "changenetworkingmode",
                   Mode           => "hostonly",
                },

                "killvmnet1dhcpd" => {
                   Type           => "Host",
                   Target         => "SUT",
                   killvmprocess  => "killvmprocess",
                   processname    => "vmnet1",
                },

                'startvmnet1dhcpd' => {
                    Type           => "Host",
                    Target         => "SUT",
                    startvmnetdhcp => "startvmnetdhcp",
                    vmnetname      => "vmnet-dhcpd-vmnet1",
                },

                "DHCPDisable" => {
                    Type           => "NetAdapter",
                    Iterations     => "1",
                    Target         => "SUT",
                    TestAdapter    => "1",
                    IntType        => "vmknic",
                    DeviceStatus   => "DOWN",
                 },

                "DHCPEnable" => {
                    Type           => "NetAdapter",
                    Iterations     => "1",
                    Target         => "SUT",
                    TestAdapter    => "1",
                    IntType        => "vmknic",
                    DeviceStatus   => "UP",
                 },

            },
        },

    );
}



########################################################################
#
# new --
#       This is the constructor for SampleTds
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
   my $self = $class->SUPER::new(\%Sample);
   return (bless($self, $class));
}
