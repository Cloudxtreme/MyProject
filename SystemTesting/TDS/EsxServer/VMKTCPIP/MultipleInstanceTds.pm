#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::VMKTCPIP::MultipleInstanceTds;

#
# This file contains the structured hash for the multiple instance
# part of vmkernel tcpip module.
#
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   %MultipleInstance = (
      'DefaultInstance'   => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "DefaultInstance",
         Version          => "2" ,
         Summary          => "This test verifies that default instance exists
                              in the system",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
		     },
		  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence => [['Traffic1'],['Traffic2']],
            "Traffic1" => {
               Type => "Traffic",
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "120",
               verification  => "Verification_1",
            },
             "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "udp",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "120",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },
      "CreateDeleteInstance" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "CreateDeleteInstance",
         Version          => "2" ,
         Summary          => "This test case verifies that traffic
                             can be run between vmknics which belongs to
                             different instances",
         Tags             => 'sanity,CAT_P0,batnovc',
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1-2]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[1].portgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1-2]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[2].portgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['Traffic1'],['Traffic2']],
            "Traffic1" => {
               Type => "Traffic",
               L4Protocol     => "tcp,udp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "60",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               TestDuration => "120",
               verification  => "Verification_2",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[2]",
                  pktcount           => "3000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },
      "AddRemoveInterface" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "AddRemoveInterface",
         Version          => "2" ,
         Summary          => "This test case verifies the host ".
                              "add remove interface",
         ExpectedResult   => "PASS",
         Tags             => 'sanity',
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1-5]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[1].portgroup.[2]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[3]' => {
                        portgroup => "host.[1].portgroup.[3]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[4]' => {
                        portgroup => "host.[1].portgroup.[4]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[5]' => {
                        portgroup => "host.[1].portgroup.[5]",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1-5]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[2].portgroup.[2]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[3]' => {
                        portgroup => "host.[2].portgroup.[3]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[4]' => {
                        portgroup => "host.[2].portgroup.[4]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[5]' => {
                        portgroup => "host.[2].portgroup.[5]",
                        netstack => "host.[2].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['EnablePromiscuous'],['Traffic1'],['Traffic2'],
                         ['Traffic3'],['Traffic4'],['Traffic5']],
            "EnablePromiscuous" => {
               Type => "PortGroup",
               TestPortgroup => "host.[1].portgroup.[1]",
               promiscous => "Enable",
            },
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "60",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               TestDuration => "60",
               verification  => "Verification_2",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[2]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic3" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               TestDuration => "60",
               verification  => "Verification_3",
            },
            "Verification_3" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[3]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic4" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
               TestDuration => "60",
               verification  => "Verification_4",
            },
            "Verification_4" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[4]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic5" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[5]",
               SupportAdapter => "host.[2].vmknic.[5]",
               TestDuration => "60",
               verification  => "Verification_5",
            },
            "Verification_5" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[5]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },

      "AddRemoveInstanceVmknic" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "AddRemoveInstanceVmknic",
         Version          => "2" ,
         Summary          => "This test case verifies the adding removing
                             instances and vmknics can be done together",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  portgroup   => {
                     '[1-5]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['AddNetstack1'],['AddVmk1','AddNetstack2'],
                         ['AddVmk2','AddNetstack3'],['AddVmk3','AddNetstack4'],
                         ['AddVmk4','AddNetstack5'],['AddVmk5','AddNetstack6'],
                         ['RemoveNetstack6','RemoveVmk1'],['RemoveNetstack1',
                          'RemoveVmk2'],['RemoveVmk3','RemoveNetstack2'],
                         ['RemoveVmk4','RemoveNetstack3'],
                         ['RemoveVmk5','RemoveNetstack4'],['RemoveNetstack5'],
                         ],

            "AddNetstack1" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  "[1]" => {
                     netstackname => "test1",
                  },
               },
            },
            "AddNetstack2" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  "[2]" => {
                     netstackname => "test2",
                  },
               },
            },
            "AddNetstack3" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  "[3]" => {
                     netstackname => "test3",
                  },
               },
            },
            "AddNetstack4" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  "[4]" => {
                     netstackname => "test4",
                  },
               },
            },
            "AddNetstack5" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  "[5]" => {
                     netstackname => "test5",
                  },
               },
            },
            "AddNetstack6" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  "[6]" => {
                     netstackname => "test6",
                  },
               },
            },
            "AddVmk1" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" => {
                  portgroup => "host.[1].portgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv4address => "dhcp",
               },
               },
            },
            "AddVmk2" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[2]" => {
                  portgroup => "host.[1].portgroup.[2]",
                  netstack => "host.[1].netstack.[2]",
                  ipv4address => "dhcp",
               },
               },
            },
            "AddVmk3" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[3]" => {
                  portgroup => "host.[1].portgroup.[3]",
                  netstack => "host.[1].netstack.[3]",
                  ipv4address => "dhcp",
               },
               },
            },
            "AddVmk4" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[4]" => {
                  portgroup => "host.[1].portgroup.[4]",
                  netstack => "host.[1].netstack.[4]",
                  ipv4address => "dhcp",
               },
               },
            },
            "AddVmk5" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[5]" => {
                  portgroup => "host.[1].portgroup.[5]",
                  netstack => "host.[1].netstack.[5]",
                  ipv4address => "dhcp",
               },
               },
            },
            "RemoveNetstack1" => {
               Type => "Host",
               TestHost => "host.[1]",
               removenetstack => "host.[1].netstack.[1]",
            },
            "RemoveNetstack2" => {
               Type => "Host",
               TestHost => "host.[1]",
               removenetstack => "host.[1].netstack.[2]",
            },
            "RemoveNetstack3" => {
               Type => "Host",
               TestHost => "host.[1]",
               removenetstack => "host.[1].netstack.[3]",
            },
            "RemoveNetstack4" => {
               Type => "Host",
               TestHost => "host.[1]",
               removenetstack => "host.[1].netstack.[4]",
            },
            "RemoveNetstack5" => {
               Type => "Host",
               TestHost => "host.[1]",
               removenetstack => "host.[1].netstack.[5]",
            },
            "RemoveNetstack6" => {
               Type => "Host",
               TestHost => "host.[1]",
               removenetstack => "host.[1].netstack.[6]",
            },
            "RemoveVmk1" => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[1]",
            },
            "RemoveVmk2" => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[2]",
            },
            "RemoveVmk3" => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[3]",
            },
            "RemoveVmk4" => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[4]",
            },
            "RemoveVmk5" => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic => "host.[1].vmknic.[5]",
            },
         },
      },
      "MigrateVmknicToNewInstance" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "MigrateVmknicToNewInstnace",
         Version          => "2" ,
         Summary          => "This test case verifes that a vmknic can
                              be moved from one instance to another instance",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1-2]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['Traffic1'],['Traffic2'],
                         ['RemoveVMK1'],['AddNetstack1'],
                         ['AddVMK2'],['Traffic1'],['Traffic2'],
                         ['RemoveVMK2'],['AddVMK1'],
                         ['RemoveNetstack1']],
            "AddNetstack1" => {
               Type => "Host",
               TestHost => "host.[1]",
               netstack => {
                  "[2]" => {
                     netstackname => "newstack",
                  },
               },
            },
            "AddVMK2" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" => {
                  ipv4address => "dhcp",
                  portgroup => "host.[1].portgroup].[2]",
                  netstack => "host.[1].netstack.[2]",
               },
               },
            },
            "RemoveVMK1" => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic  => "host.[1].vmknic.[1]",
            },
            "RemoveVMK2" => {
               Type => "Host",
               TestHost => "host.[1]",
               removevmknic   => "host.[1].vmknic.[1]",
            },
            "RemoveNetstack1" => {
               Type => "Host",
               TestHost => "host.[1]",
               removenetstack => "host.[1].netstack.[2]",
            },
            "AddVMK1" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" => {
                  ipv4address => "dhcp",
                  portgroup => "host.[1].portgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
               },
               },
            },
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "180",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "3000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic2" => {
               Type => "Traffic",
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "180",
               verification  => "Verification_1",
            },
         },
      },
      "ConfigurationIsolation" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "ConfigurationIsolation",
         Version          => "2" ,
         Summary          => "This test case verifies that changing the
                             configuration of one instance doesn't impact
                             the another instance.",
         Tags             => '',
         ExpectedResult   => "PASS",
         TestbedSpec => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1-2]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[1].portgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1-2]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[2].portgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['Traffic1'],['SetNetstackName'],
                         ['Traffic1'],['Traffic2'],
                         ['SetConnections'],['Traffic1'],
                         ['Traffic2']],
            "Traffic1" => {
               Type => "Traffic",
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "120",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               TestDuration => "120",
               verification  => "Verification_2",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[2]",
                  pktcount           => "3000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "SetNetstackName" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[2]",
               setnetstackname =>  "teststack",
            },
            "SetConnections" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[2]",
               setmaxconnections => "6000",
            },
         },
      },
      "ConnectionIsolation" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "ConnectionIsolation",
         Version          => "2" ,
         Summary          => "This test case verifies that different netstack
                              instances are isolated",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
         TestbedSpec     => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
                  portgroup => {
                     '[1-3]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  netstack => {
                     '[1-3]' => {
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[1].portgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                     },
                     '[3]' => {
                        portgroup => "host.[1].portgroup.[3]",
                        netstack => "host.[1].netstack.[3]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['SetPromiscousMode'],['Traffic']],

            "Traffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
               TestDuration => "120",
               verification  => "Verification_2",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[1].vmknic.[2]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "SetPromiscousMode" => {
               Type => "PortGroup",
               TestPortgroup => "host.[1].portgroup.[3]",
               promiscous => "Enable",
            },
         },
      },
      "MaxInstances" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "MaxInstances",
         Version          => "2" ,
         Summary          => "This test case verifies that user can
                              create max instances and creating more
                              than supported returns the error",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
         TestbedSpec     => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-5]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [[]],
         },
      },
      "MaxVmknic" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "MaxVmknic",
         Version          => "2" ,
         Summary          => "This test case verifies that user can
                              create max number of vmknics (256)",
         Tags             => '',
         ExpectedResult   => "PASS",
         TestbedSpec     => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1-8]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[1].portgroup.[2]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[3]' => {
                        portgroup => "host.[1].portgroup.[3]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[4]' => {
                        portgroup => "host.[1].portgroup.[4]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[5]' => {
                        portgroup => "host.[1].portgroup.[5]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[6]' => {
                        portgroup => "host.[1].portgroup.[6]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[7]' => {
                        portgroup => "host.[1].portgroup.[7]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[8]' => {
                        portgroup => "host.[1].portgroup.[8]",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [[]],
         },
      },
      "Teaming" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "Teaming",
         Version          => "2" ,
         Summary          => "This test case verifies that teaming and multiple instances
                              can coexist",
         Tags             => '',
         ExpectedResult   => "PASS",
          TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1];;host.[1].vmnic.[2]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  vmnic => {
                     '[1-2]' => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
               },
               '[2]' => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1];;host.[2].vmnic.[2]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[2].vss.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  vmnic => {
                     '[1-2]' => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['Traffic1'],['Traffic2']],
            "Traffic1" => {
               Type => "Traffic",
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "60",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "120",
               verification  => "Verification_2",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "3000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },
      "DHCP" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "DHCP",
         Version          => "2" ,
         Summary          => "This test case verifies that vmknics can get dhcp with
                             multiple instance enabled",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
          TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  vmnic => {
                     '[1]' => {
                        driver => "any",
                     },
                  },
               },
               '[2]' => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[2].vss.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  vmnic => {
                     '[1]' => {
                        driver => "any",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['AddVMK1'],['AddVMK2'],
                         ['Traffic1']],
            "AddVMK1" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
                  "[1]" => {
                     portgroup => "host.[1].portgroup.[1]",
                     netstack => "host.[1].netstack.[1]",
                     ipv4address => "dhcp",
                  },
               },
            },
            "AddVMK2" => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
                  "[1]" => {
                     portgroup => "host.[2].portgroup.[1]",
                     netstack => "host.[2].netstack.[1]",
                     ipv4address => "dhcp",
                  },
               },
            },
            "Traffic1" => {
               Type => "Traffic",
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "60",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },
      "Multicast" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "Multicast",
         Version          => "2" ,
         Summary          => "This test case verifies that multicast traffic works
                              when vmknics belong to a non default instance",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
          TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  vmnic => {
                     '[1]' => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[1].portgroup.[1]",
                        ipv4address => "192.10.10.10",
                        netmask => "255.255.255.0",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
               },
               '[2]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  vmnic => {
                     '[1]' => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[2].portgroup.[1]",
                        ipv4address => "192.10.10.20",
                        netmask => "255.255.255.0",
                        netstack => "host.[2].netstack.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [
                         ['AddRoute1'],
                         ['AddRoute2'],
                         ['MulticastTraffic']],
            "AddRoute1" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "add",
               route => "192.10.10.1", # set random route otherwise multicast fails, pr
            },
            "AddRoute2" => {
               Type => "Netstack",
               TestNetstack => "host.[2].netstack.[1]",
               setnetstackgateway => "add",
               route => "192.10.10.1", # set random route otherwise multicast fails, pr
            },
            "MulticastTraffic" => {
               Type                => "Traffic",
               ToolName            => "Iperf",
               NoofInbound         => "1",
               Routingscheme       => "multicast",
               Multicasttimetolive => "32",
               TestDuration        => "120",
               TestAdapter         => "host.[1].vmknic.[1]",
               SupportAdapter      => "host.[2].vmknic.[1]",
            },
         },
      },
      "ScalabilityMaxInstances" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "ScalabilityMaxInstances",
         Version          => "2" ,
         Summary          => "This test case verifies the scalibility of
                              the tcpip instances",
         Tags             => '',
         ExpectedResult   => "PASS",
          TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1-5]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                        ipv4address => "192.10.1.10",
                        netmask => "255.255.255.0",
                     },
                     '[2]' => {
                        portgroup => "host.[1].portgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                        ipv4address => "192.10.2.10",
                        netmask => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "host.[1].portgroup.[3]",
                        netstack => "host.[1].netstack.[3]",
                        ipv4address => "192.10.3.10",
                        netmask => "255.255.255.0",
                     },
                     '[4]' => {
                        portgroup => "host.[1].portgroup.[4]",
                        netstack => "host.[1].netstack.[4]",
                        ipv4address => "192.10.4.10",
                        netmask => "255.255.255.0",
                     },
                     '[5]' => {
                        portgroup => "host.[1].portgroup.[5]",
                        netstack => "host.[1].netstack.[5]",
                        ipv4address => "192.10.5.10",
                        netmask => "255.255.255.0",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-5]' => {
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1-5]'   => {
                        vss  => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                        ipv4address => "192.10.1.20",
                        netmask => "255.255.255.0",
                     },
                     '[2]' => {
                        portgroup => "host.[2].portgroup.[2]",
                        netstack => "host.[2].netstack.[2]",
                        ipv4address => "192.10.2.20",
                        netmask => "255.255.255.0",
                     },
                     '[3]' => {
                        portgroup => "host.[2].portgroup.[3]",
                        netstack => "host.[2].netstack.[3]",
                        ipv4address => "192.10.3.20",
                        netmask => "255.255.255.0",
                     },
                     '[4]' => {
                        portgroup => "host.[2].portgroup.[4]",
                        netstack => "host.[2].netstack.[4]",
                        ipv4address => "192.10.4.20",
                        netmask => "255.255.255.0",
                     },
                     '[5]' => {
                        portgroup => "host.[2].portgroup.[5]",
                        netstack => "host.[2].netstack.[5]",
                        ipv4address => "192.10.5.20",
                        netmask => "255.255.255.0",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-5]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['Traffic1','Traffic2'],
                         ['Traffic3','Traffic4'],
                         ['Traffic5']],
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "120",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[2]",
               SupportAdapter => "host.[2].vmknic.[2]",
               TestDuration => "120",
               verification  => "Verification_2",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[2]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic3" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[3]",
               SupportAdapter => "host.[2].vmknic.[3]",
               TestDuration => "120",
               verification  => "Verification_3",
            },
            "Verification_3" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[3]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic4" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[4]",
               SupportAdapter => "host.[2].vmknic.[4]",
               TestDuration => "120",
               verification  => "Verification_4",
            },
            "Verification_4" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[4]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic5" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[5]",
               SupportAdapter => "host.[2].vmknic.[5]",
               TestDuration => "120",
               verification  => "Verification_5",
            },
            "Verification_5" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[5]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },
      "VDS" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "VDS",
         Version          => "2" ,
         Summary          => "This test case verifies the netstack and VDS
                             interoperability",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter  => {
                     '[1]'   => {
                         host  => "host.[1];;host.[2]",
                     },
                  },
                  vds   => {
                     '[1]'   => {
                        datacenter  => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1-2].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1-2]",
                     },
                  },
                  dvportgroup  => {
                     '[1-2]'   => {
                        vds     => "vc.[1].vds.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        netstack => "host.[1].netstack.[2]",
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
               '[2]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "vc.[1].dvportgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                     '[2]' => {
                        netstack => "host.[2].netstack.[2]",
                        portgroup => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['Traffic1'],
                         ['Traffic2']],
            "Traffic1" => {
               Type => "Traffic",
               L4Protocol     => "tcp",
               ToolName => "Iperf",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "60",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic2" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "120",
               verification  => "Verification_2",
            },
            "Verification_2" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "3000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },
      "IPv6" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "IPv6",
         Version          => "2" ,
         Summary          => "This test case verifies that IPv6 traffic
                             can be run between vmknics which belongs to
                             different instances",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
               '[2]' => {
                   vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[2].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['AddVMK1'],['AddVMK2'],
                         ['Traffic']],
             "AddVMK1" => {
               Type => "Host",
               TestHost => "host.[1]",
               vmknic => {
               "[1]" => {
                  portgroup => "host.[1].portgroup.[1]",
                  netstack => "host.[1].netstack.[1]",
                  ipv6addr => "2001::1",
                  prefixlen => "64",
               },
               },
            },
            "AddVMK2" => {
               Type => "Host",
               TestHost => "host.[2]",
               vmknic => {
               "[1]" => {
                  portgroup => "host.[2].portgroup.[1]",
                  netstack => "host.[2].netstack.[1]",
                  ipv6addr => "2001::2",
                  prefixlen => "64",
               },
               },
            },
            "SetGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "add",
               route => "2000::1",
               netaddress => "2222::/64",
            },
            "RemoveGateway" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackgateway => "remove",
               route => "2000::1",
               netaddress => "2222::/64",
            },
            "Traffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               L3Protocol     => "IPv6",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "360",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "1000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },
      "Tagging" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "Tagging",
         Version          => "2" ,
         Summary          => "This test case verifies the interface tagging",
         Tags             => '',
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        netstack => "host.[1].netstack.[1]",
                        portgroup => "host.[1].portgroup.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['AddTag'],['RemoveTag']],
            "AddTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "RemoveTag" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
         },
      },
      "IPSec" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "IPSec",
         Version          => "2" ,
         Summary          => "This test case verifies that ipsec with multiple instance",
         Tags             => 'sanity,CAT_P0',
         ExpectedResult   => "PASS",
         TestbedSpec     => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
               '[2]' => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[2].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['AddSA1'],['AddSA2'],['AddSP1InTraffic'],
                         ['AddSP2InTraffic'],['AddSP1OutTraffic'],
                         ['AddSP2OutTraffic'],['Traffic']],
            ExitSequence =>  [['RemoveSP1'],['RemoveSP2'],
                              ['RemoveSA1'],['RemoveSA2']],
            "AddSA1" => {
               Type => "Host",
               TestHost => "host.[1]",
               sa => "add",
               ipsecconfigspec => {
                  name => "ipsecTCP",
                  encryption => "aes128-cbc",
                  encryptionkey => "0x41414141414141414141414141414141",
                  integrity => "hmac-sha1",
                  integritykey => "0x4141414141414141414141414141414141414141",
                  destination => "any",
                  mode        => "transport",
                  source      => "any",
                  spi         => "0x1000",
               },
            },
            "AddSA2" => {
               Type => "Host",
               TestHost => "host.[2]",
               sa => "add",
               ipsecconfigspec => {
                  name => "ipsecTCP",
                  encryption => "aes128-cbc",
                  encryptionkey => "0x41414141414141414141414141414141",
                  integrity => "hmac-sha1",
                  integritykey => "0x4141414141414141414141414141414141414141",
                  destination => "any",
                  mode        => "transport",
                  source      => "any",
                  spi         => "0x1000",
               },
            },
            "AddSP1OutTraffic" => {
               Type => "Host",
               TestHost => "host.[1]",
               sp => "add",
               ipsecconfigspec => {
                  saname => "ipsecTCP",
                  spname => "ipsecTCPSPOut",
                  direction => "out",
                  protocol => "tcp",
                  action => "ipsec",
                  sourceport => "2100",
                  destinationport => "2100",
               },
            },
            "AddSP1InTraffic" => {
               Type => "Host",
               TestHost => "host.[1]",
               sp => "add",
               ipsecconfigspec => {
                  saname => "ipsecTCP",
                  spname => "ipsecTCPSPIn",
                  direction => "in",
                  protocol => "tcp",
                  action => "ipsec",
                  sourceport => "2100",
                  destinationport => "2100",
               },
            },
            "AddSP2InTraffic" => {
               Type => "Host",
               sp => "add",
               TestHost => "host.[2]",
               ipsecconfigspec => {
                  saname => "ipsecTCP",
                  spname => "ipsecTCPSPIn",
                  direction => "in",
                  protocol => "tcp",
                  action => "ipsec",
                  sourceport => "2100",
                  destinationport => "2100",
               },
            },
            "AddSP2OutTraffic" => {
               Type => "Host",
               sp => "add",
               TestHost => "host.[2]",
               ipsecconfigspec => {
                  saname => "ipsecTCP",
                  spname => "ipsecTCPSPOut",
                  direction => "out",
                  protocol => "tcp",
                  action => "ipsec",
                  sourceport => "2100",
                  destinationport => "2100",
               },
            },
            "RemoveSA1" => {
               Type => "Host",
               TestHost => "host.[1]",
               sa => "remove",
               ipsecconfigspec => {
                  name => "ipsecTCP",
               },
            },
            "RemoveSA2" => {
               Type => "Host",
               TestHost => "host.[2]",
               sa => "remove",
               ipsecconfigspec => {
                  name => "ipsecTCP",
               },
            },
            "RemoveSP1" => {
               Type => "Host",
               TestHost => "host.[1]",
               sp => "remove",
               ipsecconfigspec => {
                  spname => "all",
               },
            },
             "RemoveSP2" => {
               Type => "Host",
               TestHost => "host.[2]",
               sp => "remove",
               ipsecconfigspec => {
                  spname => "all",
               },
            },
            "Traffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               L3Protocol     => "IPv6",
               PortNumber     => "2100",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "180",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "100+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },
      "VLAN" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "VLAN",
         Version          => "2" ,
         Summary          => "This test case verifies that VLAN and multiple instances
                              can coexist",
         Tags             => '',
         ExpectedResult   => "PASS",
          TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  vmnic => {
                     '[1]' => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
               },
               '[2]' => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[2].vmnic.[1];;host.[2].vmnic.[2]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[2].vss.[1]",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  vmnic => {
                     '[1-2]' => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[2].portgroup.[1]",
                        netstack => "host.[2].netstack.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['SetVLAN1'],['SetVLAN2'],
                         ['Traffic']],

            "SetVLAN1" => {
               Type => "PortGroup",
               TestPortgroup => "host.[1].portgroup.[1]",
               vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D
            },
            "SetVLAN2" => {
               Type => "PortGroup",
               TestPortgroup => "host.[2].portgroup.[1]",
               vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_D,
            },
            "Traffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               TestDuration => "120",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[2].vmknic.[1]",
                  pktcount           => "3000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
         },
      },
      "DefaultInstanceInterface" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "DefaultInstanceInterface",
         Version          => "2" ,
         Summary          => "This test case verifies that in default instance the user
                              can create vmknic for vmotion etc. traffic types",
         Tags             => '',
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup => {
                     '[1]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[1].portgroup.[1]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['SetVMotion'],['SetFT']],
            "SetVMotion" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "SetFT" => {
               Type => "NetAdapter",
               TestAdapter => "host.[1].vmknic.[1]",
               Tagging => "add",
               tagname => "faultToleranceLogging",
            },
         },
      },
      "EditInstance" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "EditInstance",
         Version          => "2" ,
         Summary          => "This test case verifies that properties of custom netstack
                              instance can be changed",
         Tags             => '',
         ExpectedResult   => "PASS",
         TestbedSpec => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['EditName'],['EditConnections']],
            "EditName" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setnetstackname => "teststack",
            },
            "EditConnections" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setmaxconnections => "6000",
            },
         },
      },
      "MaxConnections" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "MaxConnections",
         Version          => "2" ,
         Summary          => "This test case verifies that user can set the max connections
                              for the netstack instance",
         Tags             => '',
         ExpectedResult   => "PASS",
         TestbedSpec => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                        configureuplinks => "add",
                        vmnicadapter => "host.[1].vmnic.[1]",
                     },
                  },
                  portgroup   => {
                     '[1]'   => {
                        vss  => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                  },
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  netstack => {
                     '[1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['connections1'],['connections2'],
                         ['connections3'],['connections4']],
            # max is 20K
            "connections1" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setmaxconnections => "20000",
            },
            "connections2" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setmaxconnections => "20001",
               ExpectedResult => "FAIL",
            },
            "connections3" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setmaxconnections => "1999",
               ExpectedResult => "FAIL",
            },
            # min is 2K
            "connections4" => {
               Type => "Netstack",
               TestNetstack => "host.[1].netstack.[1]",
               setmaxconnections => "2000",
            },
         },
      },
      "LoopbackInterface" => {
         Component        => "Networking",
         Category         => "VMKTCPIP",
         TestName         => "LoopbackInterface",
         Version          => "2" ,
         Summary          => "This test case verifies that different netstack
                              instances are isolated",
         Tags             => 'sanity',
         ExpectedResult   => "PASS",
         TestbedSpec     => {
            host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
                  netstack => {
                     '[1-2]' => {
                     },
                  },
                  portgroup => {
                     '[1-2]' => {
                        vss => "host.[1].vss.[1]",
                     },
                  },
                  vmknic => {
                     '[1]' => {
                        portgroup => "host.[1].portgroup.[1]",
                        netstack => "host.[1].netstack.[1]",
                     },
                     '[2]' => {
                        portgroup => "host.[1].portgroup.[2]",
                        netstack => "host.[1].netstack.[2]",
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence => [['SetVLAN1'],['SetVLAN2'],
                         ['Traffic'],['RemoveVLAN1'],
                         ['RemoveVLAN2'],['Traffic1']],
            "SetVLAN1" => {
               Type => "PortGroup",
               TestPortgroup => "host.[1].portgroup.[1]",
               vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_A,
            },
            "SetVLAN2" => {
               Type => "PortGroup",
               TestPortgroup => "host.[1].portgroup.[2]",
               vlan          => VDNetLib::Common::GlobalConfig::VDNET_VLAN_B,
            },
            "RemoveVLAN1" => {
               Type => "PortGroup",
               TestPortgroup => "host.[1].portgroup.[1]",
               vlan          => "0",
            },
            "RemoveVLAN2" => {
               Type => "PortGroup",
               TestPortgroup => "host.[1].portgroup.[2]",
               vlan          => "0",
            },
            "Traffic1" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
               TestDuration => "120",
               verification  => "Verification_1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "host.[1].vmknic.[2]",
                  pktcount           => "3000+",
                  pktcapfilter       => "snaplen 256",
               },
            },
            "Traffic" => {
               Type           => "Traffic",
               ToolName       => "netperf",
               L4Protocol     => "tcp",
               SendMessageSize  => "63488",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestAdapter => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[1].vmknic.[2]",
               TestDuration => "60",
               ExpectedResult => "FAIL",
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
   my $self = $class->SUPER::new(\%MultipleInstance);
   return (bless($self, $class));
}

1;

