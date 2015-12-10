#!/usr/bin/perl
#########################################################################
#Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::FPT::FPTBnx2xTds;

#
# This file contains the structured hash for category, FPT tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{

      %FPT = (

        'AddPCI' => {
           Component        => "network NPA/UPT/SRIOV",
           Category         => "ESX Server",
           TestName         => "AddPCI",
           Summary          => "Put device in passthrough mode on host and " .
                               "add the passthru device to FPT VM",
           ExpectedResult    => "PASS",
           Parameters   => {
              SUT      => {
                 host        => 1,
                 vm          => 1,
                 passthrough => 1,
                 vmnic       => [
                     {
                        driver => "bnx2x",
                        count  => 2,
                        speed  => "10G",
                     },
                     ],
                 pci => {
                     "[1]" => {           # initializes SUT:pci:1 pci device
                        passthrudevice => "SUT:vmnic:1",
                    },
                 },
               },
             helper1 => {
                host    => 1,
                'vmnic' => [
                             {
                               driver => "any",
                               count  => 1,
                               speed  => "10G",
                             },
                          ],
                vnic    => ['e1000:1'],
               },
            },
          WORKLOADS => {
            Sequence => [
                         ['ConfigureIP'],
                         ['BroadcastTraffic'],
                         ['MulticastTraffic'],
                         ['PingFlood'],
                         ['TCPTraffic'],
                         ['UDPTraffic'],
                        ],
            "ConfigureIP" => {
               Type           => "NetAdapter",
               TestAdapter    => "SUT:pci:1,helper1:vnic:1",
               IPv4           => "AUTO",
            },
            "TCPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               MaxTimeout                => "5000",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:vnic:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "tcp",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "1,2048,32768,64512",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "Verification_1",
               TestDuration              => "60",
            },
            "UDPTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               MaxTimeout                => "5000",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:vnic:1",
               L3Protocol                => "ipv4,ipv6",
               L4Protocol                => "UDP",
               NoofInbound               => "1",
               NoofOutbound              => "1",
               SendMessageSize           => "17,2048,32768,64512",
               LocalSendSocketSize       => "131072",
               RemoteSendSocketSize      => "131072",
               Verification              => "Verification_1",
               Minexpresult              => "IGNORE",
               TestDuration              => "20",
            },
            "PingFlood" => {
               Type                      => "Traffic",
               ToolName                  => "ping",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:vnic:1",
               L3Protocol                => "ipv4",
               NoofInbound               => "1",
               RoutingScheme             => "flood",
               TestDuration              => "60",
               connectivitytest          => "0",
            },
            "MulticastTraffic" => {
               Type                => "Traffic",
               ToolName            => "Iperf",
               TestAdapter         => "SUT:pci:1",
               SupportAdapter      => "helper1:vnic:1",
               TestDuration        => "60",
               NoofOutbound        => "1",
               NoofInbound         => "1",
               Routingscheme       => "multicast",
            },
            "BroadcastTraffic" => {
               Type           => "Traffic",
               ToolName       => "ping",
               RoutingScheme  => "broadcast",
               TestAdapter    => "SUT:pci:1",
               SupportAdapter => "helper1:vnic:1",
               NoofInbound   => "1",
               TestDuration   => "60",
            },

            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
         },
      },
      'ChangeDeviceState'   => {
         Component        => "network NPA/UPT/SRIOV",
         Category         => "ESX Server",
         TestName         => "VMOPs",
         Summary          => "This test case verifies operations ".
                             "on a VM that has FPT pci passthru device ",
         ExpectedResult   => "PASS",
         Parameters   => {
            SUT       => {
               host        => 1,
               vm          => 1,
               passthrough => 1,
               vmnic       => [
                              {
                                 driver => "bnx2x",
                                 count  => 2,
                                 speed  => "10G",
                              },
                           ],
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                 },
               },
            },
             helper1 => {
                host    => 1,
                'vmnic' => [
                             {
                               driver => "any",
                               count  => 1,
                               speed  => "10G",
                          },
                          ],
                vnic    => ['e1000:1'],
               },
            },
         WORKLOADS => {
            Sequence    => [
                           ['Suspend'],
                           ['Snapshot'],
                           ["TCPTraffic"],
                           ["ResetVM"],
                           ["WaitForVDNet"],
                           ["TCPTraffic"],
                           ["RebootVM"],
                           ["TCPTraffic"],
                           ["ResetPCI"],
                           ["TCPTraffic"],
                           ["DriverReload"],
                           ["TCPTraffic"],
                           ],
            "Suspend"         => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "suspend",
               ExpectedResult => "FAIL",
            },
            "Snapshot"        => {
               Type           => "VM",
               Target         => "SUT",
               Iterations     => "1",
               Operation      => "createsnap",
               SnapshotName   => "fptNeg",
               ExpectedResult => "FAIL",
            },
            "ResetPCI"   => {
               Type        => "NetAdapter",
               TestAdapter => "SUT:pci:1",
               Iterations  => "20",
               DeviceStatus=> "DOWN,UP",
            },
            'ResetVM' => {
               Type       => "VM",
               Target     => "SUT",
               Operation  => "reset",
               Iterations => "10",
               waitforvdnet => 0,
            },
            'WaitForVDNet' => {
               Type       => "VM",
               Target     => "SUT",
               Operation  => "waitforvdnet",
            },
            "RebootVM"     => {
               Type            => "VM",
               Iterations      => "5",
               Target          => "SUT",
               Operation       => "reboot",
               Waitforvdnet    => 1,
            },
            "DriverReload" => {
               Type           => "NetAdapter",
               TestAdapter    => "SUT:pci:1",
               Iterations     => "5",
               reload_driver  => "true",
             },
            "TCPTraffic" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "SUT:pci:1",
               SupportAdapter  => "helper1:vnic:1",
               L3Protocol      => "ipv4,ipv6",
               L4Protocol      => "tcp",
               NoofInbound     => "1",
               NoofOutbound    => "1",
               Verification    => "Verification_1",
               TestDuration    => "60",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
         },
      },

      'JumboFrames' => {
           Component        => "network NPA/UPT/SRIOV",
           Category         => "ESX Server",
           Tags             => "rpmt,bqmt",
           TestName         => "JumboFrames",
           Summary          => "Verify network performance with ".
                                "JF enabled inside FPT VM",
           ExpectedResult    => "PASS",
           Parameters   => {
            SUT       => {
               host        => 1,
               vm          => 1,
               passthrough => 1,
               vmnic       => [
                     {
                        driver => "bnx2x",
                        count  => 2,
                        speed  => "10G",
                     },
                     ],
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                 },
               },
            },
            helper1 => {
                host    => 1,
                'vmnic' => [
                            {
                              driver => "any",
                              count  => 1,
                              speed  => "10G",
                          },
                          ],
                vnic    => ['e1000:1'],
               },
            },
          WORKLOADS => {
            Iterations =>  "1",

              Sequence => [['BasicTraffic'],
                           ['SwitchJF'],
                           ['EnableNetAdapterJF'],
                           ['TCPTraffic'],['DisableSwitchJF'],
                           ['DisableNetAdapterJF']
                           ],
              "SwitchJF" => {
                  Type         => "Switch",
                  Target       => "helper1",
                  TestAdapter  => "1",
                  MTU          => "9000",
               },

              "EnableNetAdapterJF" => {
                  Type         => "NetAdapter",
                  TestAdapter  => "SUT:pci:1,helper1:vnic:1",
                  MTU          => "9000",
               },
              "DisableNetAdapterJF" => {
                  Type         => "NetAdapter",
                  TestAdapter  => "SUT:pci:1,helper1:vnic:1",
                  MTU          => "1500",
               },
              "DisableSwitchJF" => {
                  Type         => "Switch",
                  Target       => "helper1",
                  TestAdapter  => "1",
                  MTU          => "1500",
               },
               "BasicTraffic" => {
                  Type                 => "Traffic",
                  ToolName             => "netperf",
                  TestAdapter          => "SUT:pci:1",
                  SupportAdapter       => "helper1:vnic:1",
                  L3Protocol           => "ipv4,ipv6",
                  L4Protocol           => "tcp",
                  NoofInbound          => "1",
                  NoofOutbound         => "1",
               },
               "TCPTraffic" => {
                  Type                 => "Traffic",
                  ToolName             => "netperf",
                  MaxTimeout           => "5000",
                  TestAdapter          => "SUT:pci:1",
                  SupportAdapter       => "helper1:vnic:1",
                  L3Protocol           => "ipv4,ipv6",
                  L4Protocol           => "tcp,udp",
                  NoofInbound          => "1",
                  NoofOutbound         => "1",
                  SendMessageSize      => "2048,32768,64512",
                  LocalSendSocketSize  => "131072",
                  RemoteSendSocketSize => "131072",
                  Verification         => "Verification_1",
                  TestDuration         => "60",
              },
              "Verification_1" => {
                 'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "srcvm", # check TX since RX could have
                                               # LRO enabled
                  pktcapfilter     => "count 1500,size > 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
         },
      },

      'GuestVLAN' => {
           Component        => "network NPA/UPT/SRIOV",
           Category         => "ESX Server",
           Tags             => "rpmt,bqmt",
           TestName         => "GuestVLAN",
           Summary          => "Verify Guest vlantagging in FPT VM",
           ExpectedResult    => "PASS",
           Parameters   => {
            SUT       => {
               host        => 1,
               vm          => 1,
               passthrough => 1,
               vmnic       => [
                     {
                        driver => "bnx2x",
                        count  => 2,
                        speed  => "10G",
                     },
                     ],
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice => "SUT:vmnic:1",
                 },
               },
            },
            helper1 => {
                host    => 1,
                'vmnic' => [
                            {
                              driver => "any",
                              count  => 1,
                              speed  => "10G",
                          },
                          ],
                vnic    => ['e1000:1'],
               },
            },
          WORKLOADS => {
            Sequence => [['SwitchVlan'],['SUTPCIVLAN'],['HelperVnicVLAN'],['Traffic'],
                         ['SwitchVlanDisable'],
                         ['VnicVLANDisable'],
                         ['PCIVLANDisable']],

            "SwitchVlan" => {
               Type           => "Switch",
               Target         => "helper1",
               TestPG         => "1",
               VLAN           => "4095",
              },
            "SUTPCIVLAN" => {
               Type          => "NetAdapter",
               Target        => "SUT",
               Inttype       => "pci",
               TestAdapter   => "1",
               VLAN          => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B,
              },
            "HelperVnicVLAN" => {
               Type          => "NetAdapter",
               Target        => "helper1",
               Inttype       => "vnic",
               TestAdapter   => "1",
               VLAN          => VDNetLib::Common::GlobalConfig::VDNET_10G_VLAN_B,
              },
             "SwitchVlanDisable" => {
               Type           => "Switch",
               Target         => "helper1",
               TestPG         => "1",
               VLAN           => "0",
               },
            "VnicVLANDisable" => {
               Type           => "NetAdapter",
               Target         => "helper1",
               Inttype        => "vnic",
               TestAdapter    => "1",
               VLAN           => "0",
             },
            "PCIVLANDisable" => {
               Type           => "NetAdapter",
               Target         => "SUT",
               Inttype        => "pci",
               TestAdapter    => "1",
               VLAN           => "0",
             },
            "Traffic" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "SUT:pci:1",
               SupportAdapter  => "helper1:vnic:1",
               L3Protocol      => "ipv4,ipv6",
               L4Protocol      => "tcp,udp",
               NoofInbound     => "1",
               NoofOutbound    => "1",
               Verification    => "Verification_1",
               TestDuration    => "60",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
           },
         },

        'MemoryOverCommit' => {
           Component        => "network NPA/UPT/SRIOV",
           Category         => "ESX Server",
           Tags             => "rpmt,bqmt",
           TestName         => "MemoryOverCommit",
           Summary          => "Verify adding maximum memory".
                                "Would not poweron the FPT vm",
           ExpectedResult    => "PASS",
           Parameters   => {
            SUT       => {
               host        => 1,
               vm          => 1,
               passthrough => 1,
               vmnic       => [
                     {
                        driver => "bnx2x",
                        count  => 2,
                        speed  => "10G",
                     },
                     ],
               pci => {
                  "[1]" => {           # initializes SUT:pci:1 pci device
                     passthrudevice  => "SUT:vmnic:1",
                      },
                   },
              },
            helper1 => {
                host    => 1,
                'vmnic' => [
                            {
                              driver => "any",
                              count  => 1,
                              speed  => "10G",
                          },
                          ],
                vnic    => ['e1000:1'],
               },
            },
          WORKLOADS => {

            Sequence   => [['PoweroffVM'],['Snapshot'],
                           ['MemoryOverCommitVM'],
                           ['PoweronVM'],
                           ['RevertSnapshot'],
                           ['PoweronVMafterRevertSnapshot'],
                           ['TCPTraffic']
                          ],
            ExitSequence => [['HotRemoveVnic']],

            "PoweroffVM"  => {
                    Iterations      => "1",
                    Type            => "VM",
                    Target          => "SUT",
                    TestAdapter     => "1",
                    Operation       => "poweroff",
              },
           "Snapshot"  => {
                   Type             => "VM",
                   Target           => "SUT",
                   Iterations       => "1",
                   Operation        => "createsnap",
                   SnapshotName     => "fptNeg1",
              },
           "MemoryOverCommitVM"  => {
                   Iterations       => "1",
                   Type             => "VM",
                   Target           => "SUT",
                   Operation        => "memoryovercommit",
              },
           "RevertSnapshot" => {
                   Type           => "VM",
                   Target         => "SUT",
                   Iterations     => "1",
                   Operation      => "revertsnap",
                   Waitforvdnet   => "0",
                   SnapshotName   => "fptNeg1",
              },
            "PoweronVM"  => {
                   Iterations       => "1",
                   Type             => "VM",
                   Target           => "SUT",
                   Operation        => "Poweron",
                   ExpectedResult   => "FAIL",
             },
            "PoweronVMafterRevertSnapshot"  => {
                   Iterations       => "1",
                   Type             => "VM",
                   Target           => "SUT",
                   Operation        => "Poweron",
             },
            "TCPTraffic" => {
                   Type            => "Traffic",
                   ToolName        => "netperf",
                   TestAdapter     => "SUT:pci:1",
                   SupportAdapter  => "helper1:vnic:1",
                   L3Protocol      => "ipv4,ipv6",
                   L4Protocol      => "tcp",
                   NoofInbound     => "1",
                   NoofOutbound    => "1",
                   Verification    => "Verification_1",
                   TestDuration    => "60",
            },
           "HotRemoveVnic" => {
                   Type           => "VM",
                   Target         => "helper1",
                   Operation      => "hotremovevnic",
                   TestAdapter    => "1",
            },
            "Verification_1" => {
               'PktCapVerificaton' => {
                   verificationtype => "pktcap",
                   target           => "dstvm",
                   pktcapfilter     => "count 1500",
                   pktcount         => "1400+",
                   badpkt           => "0",
               },
             },
           },
         },

        'SamePCIID' => {
           Component        => "network NPA/UPT/SRIOV",
           Category         => "ESX Server",
           TestName         => "SamePCIID",
           Tags             => "bqmt",
           Summary          => "Verify addig same PCIID ".
                               "fails in FPT VM",
           Parameters   => {
              SUT      => {
                 host        => 1,
                 vm          => 1,
                 passthrough => 1,
                 vmnic       => [
                     {
                        driver => "bnx2x",
                        count  => 2,
                        speed  => "10G",
                     },
                     ],
                 pci => {
                     "[1]" => {           # initializes SUT:pci:1 pci device
                        passthrudevice => "SUT:vmnic:1",
                    },
                 },
               },
              helper1      => {
                 host        => 1,
                 vm          => 1,
                 pci => {
                     "[1]" => {           # initializes helper1:pci:1 pci device
                        passthrudevice => "SUT:vmnic:2",
                    },
                 },
             },
             helper2 => {
                host    => 1,
                'vmnic' => [
                             {
                               driver => "any",
                               count  => 1,
                               speed  => "10G",
                             },
                          ],
                vnic    => ['e1000:1'],
             },
             Rules  => "SUT.host == helper1.host," .
                       "helper1.host != helper2.host",
          },
          WORKLOADS => {
             Sequence => [
                          ['SameHostTraffic'],
                          ['PoweroffHelper1'],
                          ['AddPassthrutoVM'],
                          ['PoweronHelper1Neg'],
                          ['PoweroffSUT'],
                          ['PoweronHelper1Pos'],
                          ['DifferentHostTraffic'],
                         ],

             "PoweroffHelper1"     => {
                  Type            => "VM",
                  Target          => "helper1",
                  Operation       => "poweroff",
              },
             "AddPassthrutoVM"     => {
                  Type            => "VM",
                  Target          => "helper1",
                  TestAdapter     => "1",
                  Operation  => "addpcipassthruvm",
                  Passthroughadapter => "SUT:vmnic:1",
                  pciIndex => "1",
              },
             "PoweronHelper1Neg"     => {
                  Type            => "VM",
                  Target          => "helper1",
                  Operation       => "Poweron",
                  ExpectedResult  => "FAIL",
              },
             "PoweroffSUT"     => {
                  Type            => "VM",
                  Target          => "SUT",
                  Operation       => "poweroff",
              },
             "PoweronHelper1Pos"     => {
                  Type            => "VM",
                  Target          => "helper1",
                  Operation       => "Poweron",
              },
             "SameHostTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "SUT:pci:1",
               SupportAdapter            => "helper1:pci:1,helper2:vnic:1",
               L3Protocol                => "ipv4,ipv6",
               Verification              => "Verification_1",
               TestDuration              => "60",
             },
             "DifferentHostTraffic" => {
               Type                      => "Traffic",
               ToolName                  => "netperf",
               TestAdapter               => "helper1:pci:1",
               SupportAdapter            => "helper2:vnic:1",
               L3Protocol                => "ipv4,ipv6",
               Verification              => "Verification_1",
               TestDuration              => "60",
             },
             "Verification_1" => {
               'PktCapVerificaton' => {
                  verificationtype => "pktcap",
                  target           => "dstvm",
                  pktcapfilter     => "count 1500",
                  pktcount         => "1400+",
                  badpkt           => "0",
               },
            },
         },
      },
   ),
}

##########################################################################
# new --
#       This is the constructor for FPTTds
#
# Input:
#       none
#
# Results:
#       An instance/object of FPTTds class
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
      my $self = $class->SUPER::new(\%FPT);
      return (bless($self, $class));
}

1;


