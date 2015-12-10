#!/usr/bin/perl
##########################################################################
# Copyright (C) 2013 VMWare, Inc.
#  All Rights Reserved
##########################################################################
package TDS::NSX::Networking::VirtualRouting::VDRTds;

#
#
# This file contains the structured hash for VDR TDS.
# The following lines explain the keys of the internal
# hash in general.
#
#
use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
@ISA = qw(TDS::Main::VDNetMainTds);

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';

my $teamingWorkload = {
   Sequence =>  [
	         ['CreateVirtualWires'],
                 ['PlaceVMsOnVirtualWire1'],
                 ['PlaceVMsOnVirtualWire2'],
                 ['PlaceVMsOnVLAN'],
                 ['PowerOnVM1','PowerOnVM3','PowerOnVM5'],
                 ['PowerOnVM2','PowerOnVM4', 'PowerOnVM6'],
                 ['DeployEdge'],
                 ['CreateVXLANLIF1'],
                 ['CreateVXLANLIF2'],
                 ['CreateVLANLIF'],
                 ['SetVXLANIPVM1','SetVXLANIPVM2',
                  'SetVLANIPVM3','SetVXLANIPVM4',
                  'SetVXLANIPVM5','SetVLANIPVM6'],
                 ['AddVXLAN2RouteVM1','AddVXLAN1RouteVM2',
                  'AddVXLAN1RouteVM3','AddVXLAN2RouteVM4',
                  'AddVXLAN1RouteVM5','AddVXLAN1RouteVM6'],
                 ['AddVLANRouteVM1','AddVLANRouteVM2',
                  'AddVXLAN2RouteVM3','AddVLANRouteVM4',
                  'AddVLANRouteVM5','AddVXLAN2RouteVM6'],
                 ['NetperfTest1'],['NetperfTest2'],
                 ['NetperfTest3'],['NetperfTest4'],
                 ['PingTest1'],['PingTest2'],
                 ['PingTest3'],['PingTest4'],
	        ],
   ExitSequence =>  [['PowerOffVM1','PowerOffVM4','PowerOffVM2','PowerOffVM5'],
                     ['DeleteVNIC1','DeleteVNIC4','DeleteVNIC2','DeleteVNIC5'],
                     ['DeleteVDREdge'],
                     ['PowerOffVM3','PowerOffVM6'],
                     ['DeleteVNIC3','DeleteVNIC6'],
                     ['DeleteVirtualWires']],

   'CreateVirtualWires' => {
      Type              => "TransportZone",
      TestTransportZone => "vsm.[1].networkscope.[1]",
      VirtualWire       => {
         "[1]" => {
            name     => "AutoGenrate",
            tenantid => "AutoGenerate",
         },
         '[2]' => {
             name     => "AutoGenerate",
             tenantid => "AutoGenerate",
         },
         '[3]' => {
             name     => "AutoGenerate",
             tenantid => "AutoGenerate",
         },
      },
   },
   'DeleteVirtualWires' => {
      Type  => "TransportZone",
      TestTransportZone  => "vsm.[1].networkscope.[1]",
      deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-3]",
   },

   "DeployEdge"   => {
      Type    => "NSX",
      TestNSX => "vsm.[1]",
      vse => {
         '[1]' => {
            name          => "AutoGenerate",
            resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
            datacenter    => "vc.[1].datacenter.[1]",
            host          => "host.[2]",
            portgroup     => "vc.[1].dvportgroup.[1]",
            primaryaddress => "10.10.10.40",
            subnetmask     => "255.255.255.0",
         },
      },
   },
   'CreateVXLANLIF1' => {
      Type   => "VM",
      TestVM => "vsm.[1].vse.[1]",
      lif => {
         '[1]'   => {
             name        => "AutoGenerate",
             portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
             type        => "internal",
             connected   => 1,
             addressgroup => [{addresstype => "primary",
                              ipv4address => "192.168.1.1",
                              netmask     => "255.255.255.0",}]
         },
      },
   },
   'CreateVXLANLIF2' => {
      Type   => "VM",
      TestVM => "vsm.[1].vse.[1]",
      lif => {
         '[2]'   => {
            name        => "AutoGenerate",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
            type        => "internal",
            connected   => 1,
            addressgroup => [{addresstype => "primary",
                              ipv4address => "192.168.5.1",
                              netmask     => "255.255.255.0",}]
         },
      },
   },
   'CreateVLANLIF' => {
      Type   => "VM",
      TestVM => "vsm.[1].vse.[1]",
      lif => {
         '[3]'   => {
            name        => "AutoGenerate",
            portgroup   => "vc.[1].dvportgroup.[2]",
            type        => "internal",
            connected   => 1,
            addressgroup => [{addresstype => "primary",
                              ipv4address => "192.168.10.1",
                              netmask     => "255.255.255.0",}]
         },
      },
   },
   "DeleteVDREdge"   => {
       Type       => 'NSX',
       TestNSX    => "vsm.[1]",
       deletevse  => "vsm.[1].vse.[1]",
   },
   'PlaceVMsOnVirtualWire1' => {
      Type   => "VM",
      TestVM => "vm.[1],vm.[4]",
      vnic => {
         '[1]'   => {
            driver            => "e1000",
            portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
            connected         => 1,
            startconnected    => 1,
            allowguestcontrol => 1,
         },
      },
   },
   'DeleteVNIC1' => {
      Type   => "VM",
      TestVM => "vm.[1]",
      deletevnic => "vm.[1].vnic.[1]",
   },
   'DeleteVNIC2' => {
      Type   => "VM",
      TestVM => "vm.[2]",
      deletevnic => "vm.[2].vnic.[1]",
   },
   'DeleteVNIC3' => {
      Type   => "VM",
      TestVM => "vm.[3]",
      deletevnic => "vm.[3].vnic.[1]",
   },
   'DeleteVNIC4' => {
      Type   => "VM",
      TestVM => "vm.[4]",
      deletevnic => "vm.[4].vnic.[1]",
   },
   'DeleteVNIC5' => {
      Type   => "VM",
      TestVM => "vm.[5]",
      deletevnic => "vm.[5].vnic.[1]",
   },
   'DeleteVNIC6' => {
      Type   => "VM",
      TestVM => "vm.[6]",
      deletevnic => "vm.[6].vnic.[1]",
   },
   'PlaceVMsOnVirtualWire2' => {
      Type   => "VM",
      TestVM => "vm.[2],vm.[5]",
      vnic => {
         '[1]'   => {
            driver            => "e1000",
            portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
            connected         => 1,
            startconnected    => 1,
            allowguestcontrol => 1,
         },
      },
   },
   'PlaceVMsOnVLAN' => {
      Type   => "VM",
      TestVM => "vm.[3],vm.[6]",
      vnic => {
         '[1]'   => {
            driver            => "e1000",
            portgroup         => "vc.[1].dvportgroup.[2]",
            connected         => 1,
            startconnected    => 1,
            allowguestcontrol => 1,
         },
      },
   },
   'PowerOnVM1' => {
      Type    => "VM",
      TestVM  => "vm.[1]",
      vmstate => "poweron",
   },
   'PowerOnVM2' => {
      Type    => "VM",
      TestVM  => "vm.[2]",
      vmstate => "poweron",
   },
   'PowerOnVM3' => {
      Type    => "VM",
      TestVM  => "vm.[3]",
      vmstate => "poweron",
   },
   'PowerOnVM4' => {
      Type    => "VM",
      TestVM  => "vm.[4]",
      vmstate => "poweron",
   },
   'PowerOnVM5' => {
      Type    => "VM",
      TestVM  => "vm.[5]",
      vmstate => "poweron",
   },
   'PowerOnVM6' => {
      Type    => "VM",
      TestVM  => "vm.[6]",
      vmstate => "poweron",
   },
   'PowerOffVM1' => {
      Type    => "VM",
      TestVM  => "vm.[1]",
      vmstate => "poweroff",
   },
   'PowerOffVM2' => {
      Type    => "VM",
      TestVM  => "vm.[2]",
      vmstate => "poweroff",
   },
   'PowerOffVM3' => {
      Type    => "VM",
      TestVM  => "vm.[3]",
      vmstate => "poweroff",
   },
   'PowerOffVM4' => {
      Type    => "VM",
      TestVM  => "vm.[4]",
      vmstate => "poweroff",
   },
   'PowerOffVM5' => {
      Type    => "VM",
      TestVM  => "vm.[5]",
      vmstate => "poweroff",
   },
   'PowerOffVM6' => {
      Type    => "VM",
      TestVM  => "vm.[6]",
      vmstate => "poweroff",
   },
   "SetVXLANIPVM1" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[1].vnic.[1]",
      ipv4       => '192.168.1.5',
      netmask    => "255.255.255.0",
   },
   "SetVXLANIPVM2" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[2].vnic.[1]",
      ipv4       => '192.168.5.5',
      netmask    => "255.255.255.0",
   },
   "SetVLANIPVM3" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[3].vnic.[1]",
      ipv4       => '192.168.10.5',
      netmask    => "255.255.255.0",
   },
   "SetVXLANIPVM4" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[4].vnic.[1]",
      ipv4       => '192.168.1.10',
      netmask    => "255.255.255.0",
   },
   "SetVXLANIPVM5" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[5].vnic.[1]",
      ipv4       => '192.168.5.10',
      netmask    => "255.255.255.0",
   },
   "SetVLANIPVM6" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[6].vnic.[1]",
      ipv4       => '192.168.10.10',
      netmask    => "255.255.255.0",
   },
   "AddVXLAN2RouteVM1" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[1].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.5.0",
      gateway    => "192.168.1.1",
   },
   "AddVLANRouteVM1" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[1].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.10.0",
      gateway    => "192.168.1.1",
   },
   "AddVXLAN1RouteVM2" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[2].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.1.0",
      gateway    => "192.168.5.1",
   },
   "AddVLANRouteVM2" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[2].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.10.0",
      gateway    => "192.168.5.1",
   },
   "AddVXLAN1RouteVM3" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[3].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.1.0",
      gateway    => "192.168.10.1",
   },
   "AddVXLAN2RouteVM3" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[3].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.5.0",
      gateway    => "192.168.10.1",
   },
   "AddVXLAN2RouteVM4" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[4].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.5.0",
      gateway    => "192.168.1.1",
   },
   "AddVLANRouteVM4" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[4].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.10.0",
      gateway    => "192.168.1.1",
   },
   "AddVXLAN1RouteVM5" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[5].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.1.0",
      gateway    => "192.168.5.1",
   },
   "AddVLANRouteVM5" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[5].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.10.0",
      gateway    => "192.168.5.1",
   },
   "AddVXLAN1RouteVM6" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[6].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.1.0",
      gateway    => "192.168.10.1",
   },
   "AddVXLAN2RouteVM6" => {
      Type       => "NetAdapter",
      Testadapter=> "vm.[6].vnic.[1]",
      netmask    => "255.255.255.0",
      route      => "add",
      network    => "192.168.5.0",
      gateway    => "192.168.10.1",
   },
   # vxlan to vxlan routing same host.
   "PingTest1" => {
      Type            => "Traffic",
      ToolName        => "ping",
      TestAdapter     => "vm.[1].vnic.[1]",
      SupportAdapter  => "vm.[2].vnic.[1]",
      L3Protocol      => "ipv4",
      parallelsession => "yes",
      NoofOutbound    => "1",
      NoofInbound     => "1",
      TestDuration    => "180",
   },
   "NetperfTest1" => {
      Type            => "Traffic",
      ToolName        => "netperf",
      TestAdapter     => "vm.[1].vnic.[1]",
      SupportAdapter  => "vm.[2].vnic.[1]",
      L3Protocol      => "ipv4",
      L4Protocol      => "tcp,udp",
      parallelsession => "yes",
      SendMessageSize => "63488",
      NoofOutbound    => "1",
      NoofInbound     => "1",
      LocalSendSocketSize => "131072",
      RemoteSendSocketSize    => "131072",
      TestDuration    => "180",
      ExpectedResult  => "ignore",
   },
   # vxlan to vlan routing same host.
   "PingTest2" => {
      Type            => "Traffic",
      ToolName        => "ping",
      TestAdapter     => "vm.[2].vnic.[1]",
      SupportAdapter  => "vm.[3].vnic.[1]",
      L3Protocol      => "ipv4",
      parallelsession => "yes",
      NoofOutbound    => "1",
      NoofInbound     => "1",
      TestDuration    => "180",
   },
   "NetperfTest2" => {
      Type            => "Traffic",
      ToolName        => "netperf",
      TestAdapter     => "vm.[2].vnic.[1]",
      SupportAdapter  => "vm.[3].vnic.[1]",
      L3Protocol      => "ipv4",
      L4Protocol      => "tcp,udp",
      parallelsession => "yes",
      SendMessageSize => "63488",
      NoofOutbound    => "1",
      NoofInbound     => "1",
      LocalSendSocketSize => "131072",
      RemoteSendSocketSize    => "131072",
      TestDuration    => "180",
      ExpectedResult  => "ignore",
   },
   # vxlan to vxlan routing across host.
   "PingTest3" => {
      Type            => "Traffic",
      ToolName        => "ping",
      TestAdapter     => "vm.[5].vnic.[1]",
      SupportAdapter  => "vm.[1].vnic.[1]",
      L3Protocol      => "ipv4",
      parallelsession => "yes",
      NoofOutbound    => "1",
      NoofInbound     => "1",
      TestDuration    => "180",
   },
   "NetperfTest3" => {
      Type            => "Traffic",
      ToolName        => "netperf",
      TestAdapter     => "vm.[5].vnic.[1]",
      SupportAdapter  => "vm.[1].vnic.[1]",
      L3Protocol      => "ipv4",
      L4Protocol      => "tcp,udp",
      parallelsession => "yes",
      SendMessageSize => "63488",
      NoofOutbound    => "1",
      NoofInbound     => "1",
      LocalSendSocketSize => "131072",
      RemoteSendSocketSize    => "131072",
      TestDuration    => "180",
      ExpectedResult  => "ignore",
   },
   #vxlan to vlan routing across host.
   "PingTest4" => {
      Type            => "Traffic",
      ToolName        => "ping",
      TestAdapter     => "vm.[1].vnic.[1]",
      SupportAdapter  => "vm.[6].vnic.[1]",
      L3Protocol      => "ipv4",
      parallelsession => "yes",
      NoofOutbound    => "1",
      NoofInbound     => "1",
      TestDuration    => "180",
   },
   "NetperfTest4" => {
      Type            => "Traffic",
      ToolName        => "netperf",
      TestAdapter     => "vm.[1].vnic.[1]",
      SupportAdapter  => "vm.[6].vnic.[1]",
      L3Protocol      => "ipv4",
      L4Protocol      => "tcp,udp",
      parallelsession => "yes",
      SendMessageSize => "63488",
      NoofOutbound    => "1",
      NoofInbound     => "1",
      LocalSendSocketSize => "131072",
      RemoteSendSocketSize    => "131072",
      TestDuration    => "180",
      ExpectedResult  => "ignore",
   },
};


{
   %VDR = (
      'VXLAN2VXLANTraffic'   => {
         TestName         => 'VXLAN2VXLANTraffic',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route traffic between VXLANs',
         Procedure        => '1. Create 2 VXLAN networks ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TESTBEDSPEC,
         WORKLOADS=> {
            Sequence =>  [
                         ['CreateVirtualWires'],
                         ['PlaceVMsOnVirtualWire1'],
                         ['PlaceVMsOnVirtualWire2'],
                         ['PowerOnVM1','PowerOnVM3',
                          'PowerOnVM2','PowerOnVM4'],
                         ['DeployEdge'],
                         ['CreateVXLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['SetVXLANIPVM1','SetVXLANIPVM2',
                         'SetVXLANIPVM3','SetVXLANIPVM4'],
                         ['AddVXLANRouteVM1','AddVXLANRouteVM2',
                          'AddVXLANRouteVM3','AddVXLANRouteVM4'],
                         ['NetperfTest1'],['NetperfTest2'],
                         ['NetperfTest3'],['NetperfTest4'],
                         ['PingTest1'],['PingTest2'],
                         ['PingTest3'],['PingTest4'],
                         ],
            ExitSequence =>  [['PowerOffVM1','PowerOffVM3',
                               'PowerOffVM2','PowerOffVM4'],
                              ['DeleteVNIC1','DeleteVNIC2',
                               'DeleteVNIC3','DeleteVNIC4'],
                              ['DeleteVDREdge'],
                              ['DeleteVirtualWires']
                             ],

            'CreateVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
                  '[2]' => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-2]",
            },
            "DeployEdge"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[1]",
                     primaryaddress => "10.10.10.41",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            'CreateVXLANLIF1' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.1.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            'CreateVXLANLIF2' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[2]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.5.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVirtualWire1' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire2' => {
               Type   => "VM",
               TestVM => "vm.[2],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'DeleteVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               deletevnic => "vm.[3].vnic.[1]",
            },
            'DeleteVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               deletevnic => "vm.[4].vnic.[1]",
            },

            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOffVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweroff",
            },
            'PowerOffVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweroff",
            },
            "SetVXLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '192.168.1.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '192.168.5.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '192.168.1.10',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '192.168.5.10',
               netmask    => "255.255.255.0",
            },
            "AddVXLANRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
             "AddVXLANRouteVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
            "PingTest1" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest2" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest3" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest4" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               parallelsession => "yes",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "NetperfTest1" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest2" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest3" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest4" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
         },
      },
      'VXLAN2VLANTraffic'   => {
         TestName         => 'VXLAN2VLANTraffic',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route traffic between VXLAN and VLAN',
         Procedure        => '1. Create 2 VXLAN networks and VLAN network' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TESTBEDSPEC,
         WORKLOADS => {
             Sequence => [
                         ['CreateVirtualWires'],
                         ['PlaceVMsOnVirtualWire1'],
                         ['PlaceVMsOnVLAN'],
                         ['PowerOnVM1','PowerOnVM3',
                          'PowerOnVM2','PowerOnVM4'],
                         ['DeployEdge'],
                         ['CreateVLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['SetVLANIPVM1','SetVXLANIPVM2',
                          'SetVLANIPVM3','SetVXLANIPVM4'],
                         ['AddVLANRouteVM1','AddVXLANRouteVM2',
                          'AddVLANRouteVM3','AddVXLANRouteVM4'],
                         ['NetperfTest1'],['NetperfTest2'],
                         ['NetperfTest3'],['NetperfTest4'],
                         ['PingTest1'],['PingTest2'],
                         ['PingTest3'],['PingTest4'],
                         ],
            ExitSequence =>  [['PowerOffVM1','PowerOffVM3',
                               'PowerOffVM2','PowerOffVM4'],
                              ['DeleteVNIC2','DeleteVNIC4'],
                              ['DeleteVDREdge'],
                              ['DeleteVirtualWires']
                             ],

            'CreateVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenerate",
                     tenantid => "1",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
            },
            "DeployEdge"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[1]",
                     primaryaddress => "10.10.10.42",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            'CreateVLANLIF1' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vc.[1].dvportgroup.[2]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.1.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            'CreateVXLANLIF2' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[2]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.5.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVirtualWire1' => {
               Type   => "VM",
               TestVM => "vm.[2],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'DeleteVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               deletevnic => "vm.[4].vnic.[1]",
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVLAN' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOffVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweroff",
            },
            'PowerOffVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweroff",
            },
             "SetVLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '192.168.1.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '192.168.5.5',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '192.168.1.10',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '192.168.5.10',
               netmask    => "255.255.255.0",
            },
             "AddVLANRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
             "AddVLANRouteVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
            "PingTest1" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest2" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest3" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest4" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               parallelsession => "yes",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "NetperfTest1" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest2" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest3" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest4" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
         },
      },
      'VLAN2VLANTraffic'   => {
         TestName         => 'VLAN2VLANTraffic',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route between VLANs',
         Procedure        => '1. Create 2 VLAN networks ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TESTBEDSPEC,
         WORKLOADS => {
            Sequence => [
                         ['PlaceVMsOnVLAN1'],
                         ['PlaceVMsOnVLAN2'],
                         ['PowerOnVM1','PowerOnVM3',
                          'PowerOnVM2','PowerOnVM4'],
                         ['DeployEdge'],
                         ['CreateVLANLIF1'],
                         ['CreateVLANLIF2'],
                         ['SetVLANIPVM1','SetVLANIPVM2',
                         'SetVLANIPVM3','SetVLANIPVM4'],
                         ['AddVLANRouteVM1','AddVLANRouteVM2',
                          'AddVLANRouteVM3','AddVLANRouteVM4'],
                         ['NetperfTest1'],['NetperfTest2'],
                         ['NetperfTest3'],['NetperfTest4'],
                         ['PingTest1'],['PingTest2'],
                         ['PingTest3'],['PingTest4'],
                        ],
            ExitSequence =>  [['PowerOffVM1','PowerOffVM3',
                               'PowerOffVM2','PowerOffVM4'],
                              ['DeleteVDREdge']
                             ],
            "DeployEdge"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[1]",
                     primaryaddress => "10.10.10.43",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            'CreateVLANLIF1' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vc.[1].dvportgroup.[2]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.1.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            'CreateVLANLIF2' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vc.[1].dvportgroup.[3]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.5.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVLAN1' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVLAN2' => {
               Type   => "VM",
               TestVM => "vm.[2],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[3]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOffVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweroff",
            },
            'PowerOffVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweroff",
            },
            "SetVLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '192.168.1.5',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '192.168.5.5',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '192.168.1.10',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '192.168.5.10',
               netmask    => "255.255.255.0",
            },
             "AddVLANRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVLANRouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
             "AddVLANRouteVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVLANRouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
            "PingTest1" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "180",
            },
            "PingTest2" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "180",
            },
            "PingTest3" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "180",
            },
            "PingTest4" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               parallelsession => "yes",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "180",
            },
            "NetperfTest1" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest2" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest3" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest4" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
         },
      },
      'VDRTrafficWithTeamingEtherChannel'   => {
         TestName         => 'VDRTrafficWithTeamingEtherChannel',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route traffic with etherchannel teaming ',
         Procedure        => '1. Create 2 VXLAN networks with vxlan using the' .
                             '   Static Etherchannel and VDS having multiple nics'.
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs and VLAN'.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TEAMINGETHERCHANNEL_TESTBEDSPEC,
         WORKLOADS        => $teamingWorkload,
      },
      'VDRTrafficWithTeamingLACP'   => {
         TestName         => 'VDRTrafficWithTeamingLACP',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR traffic over LACP teaming ',
         Procedure        => '1. Create 2 VXLAN networks with vxlan configured'.
                             '   to use the lacp teaming policy'.
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'lacp',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TEAMINGLACP_TESTBEDSPEC,
         WORKLOADS      => {
            Sequence =>  [
                          ['ConfigureChannelGroup1'],
                          ['ConfigureChannelGroup2'],
                          ['AddPNICToLAG1'],
                          ['AddPNICToLAG2'],
                          ['InstallVibsAndVXLANWithLACP'],
                          ['CreateNetworkScope'],
                          ['CreateVirtualWires'],
                          ['PlaceVMsOnVirtualWire1'],
                          ['PlaceVMsOnVirtualWire2'],
                          ['PlaceVMsOnVLAN'],
                          ['PowerOnVM1','PowerOnVM3','PowerOnVM5',
                           'PowerOnVM2','PowerOnVM4', 'PowerOnVM6'],
                          ['DeployEdge'],
                          ['CreateVXLANLIF1'],
                          ['CreateVXLANLIF2'],
                          ['CreateVLANLIF'],
                          ['SetVXLANIPVM1','SetVXLANIPVM2',
                           'SetVLANIPVM3','SetVXLANIPVM4',
                           'SetVXLANIPVM5','SetVLANIPVM6'],
                          ['AddVXLAN2RouteVM1','AddVXLAN1RouteVM2',
                           'AddVXLAN1RouteVM3','AddVXLAN2RouteVM4',
                           'AddVXLAN1RouteVM5','AddVXLAN1RouteVM6'],
                          ['AddVLANRouteVM1','AddVLANRouteVM2',
                           'AddVXLAN2RouteVM3','AddVLANRouteVM4',
                           'AddVLANRouteVM5','AddVXLAN2RouteVM6'],
                          ['NetperfTest1'],['NetperfTest2'],
                          ['NetperfTest3'],['NetperfTest4'],
                          ['PingTest1'],['PingTest2'],
                          ['PingTest3'],['PingTest4'],
		         ],
            ExitSequence =>[
                              ['PowerOffVM1','PowerOffVM3',
                               'PowerOffVM2','PowerOffVM4',
                               'PowerOffVM5','PowerOffVM6'],
                              ['DeleteVNIC1','DeleteVNIC2',
                               'DeleteVNIC4','DeleteVNIC5'],
                              ['DeleteVDREdge'],
                              ['DeleteVirtualWires'],
                              ['DeleteNetworkScope'],
                              ['UnConfigureVXLAN'],
                              ['NoPortChannel'],
                              ['RemovePNICToLAG1'],
                              ['RemovePNICToLAG2'],
                              ],
            'AddPNICToLAG1' => {
               Type => "LACP",
               TestLag => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter => "host.[2].vmnic.[1-3]",
            },
            'AddPNICToLAG2' => {
               Type => "LACP",
               TestLag => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "add",
               vmnicadapter => "host.[3].vmnic.[1-3]",
            },
            'RemovePNICToLAG1' => {
               Type => "LACP",
               TestLag => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter => "host.[2].vmnic.[1-3]",
            },
            'RemovePNICToLAG2' => {
               Type => "LACP",
               TestLag => "vc.[1].vds.[1].lag.[1]",
               configuplinktolag => "remove",
               vmnicadapter => "host.[3].vmnic.[1-3]",
            },

            'ConfigureChannelGroup1' => {
               Type => "Port",
               TestPort => "host.[2].pswitch.[-1]",
               configurechannelgroup => "32",
               Mode => "Active",
            },
            'ConfigureChannelGroup2' => {
               Type => "Port",
               TestPort => "host.[3].pswitch.[-1]",
               configurechannelgroup => "62",
               Mode => "Active",
            },
            InstallVibsAndVXLANWithLACP => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     vibs         => "install",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => [22],
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "LACP_V2",
                  },
               },
            },
            'UnConfigureVXLAN' => {
               Type             => 'Cluster',
               testcluster      => "vsm.[1].vdncluster.[1]",
               vxlan            => "unconfigure",
            },
            CreateNetworkScope => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1-$$",
                     clusters     => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'DeleteNetworkScope' => DELETE_ALL_NETWORKSCOPES,
            'CreateVirtualWires' => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'DeleteVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            "DeployEdge"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[1]",
                     primaryaddress => "10.10.10.44",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            'CreateVXLANLIF1' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                         ipv4address => "192.168.1.1",
                         netmask     => "255.255.255.0",}]
                  },
               },
            },
            'CreateVXLANLIF2' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[2]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                              ipv4address => "192.168.5.1",
                              netmask     => "255.255.255.0",}]
                  },
               },
            },
            'CreateVLANLIF' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[3]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vc.[1].dvportgroup.[2]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                              ipv4address => "192.168.10.1",
                              netmask     => "255.255.255.0",}]
                  },
               },
            },
            "DeleteVDREdge"   => DELETE_ALL_EDGES,
            'PlaceVMsOnVirtualWire1' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'DeleteVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               deletevnic => "vm.[4].vnic.[1]",
            },
            'DeleteVNIC5' => {
               Type   => "VM",
               TestVM => "vm.[5]",
               deletevnic => "vm.[5].vnic.[1]",
            },
            'PlaceVMsOnVirtualWire2' => {
               Type   => "VM",
               TestVM => "vm.[2],vm.[5]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVLAN' => {
               Type   => "VM",
               TestVM => "vm.[3],vm.[6]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOnVM5' => {
               Type    => "VM",
               TestVM  => "vm.[5]",
               vmstate => "poweron",
            },
            'PowerOnVM6' => {
               Type    => "VM",
               TestVM  => "vm.[6]",
               vmstate => "poweron",
            },
            'PowerOffVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOffVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweroff",
            },
            'PowerOffVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweroff",
            },
            'PowerOffVM5' => {
               Type    => "VM",
               TestVM  => "vm.[5]",
               vmstate => "poweroff",
            },
            'PowerOffVM6' => {
               Type    => "VM",
               TestVM  => "vm.[6]",
               vmstate => "poweroff",
            },
            "SetVXLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '192.168.1.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '192.168.5.5',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '192.168.10.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '192.168.1.10',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM5" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[5].vnic.[1]",
               ipv4       => '192.168.5.10',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM6" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[6].vnic.[1]",
               ipv4       => '192.168.10.10',
               netmask    => "255.255.255.0",
            },
            "AddVXLAN2RouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVLANRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.10.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLAN1RouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
            "AddVLANRouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.10.0",
               gateway    => "192.168.5.1",
            },
            "AddVXLAN1RouteVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.10.1",
            },
            "AddVXLAN2RouteVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.10.1",
            },
            "AddVXLAN2RouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVLANRouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.10.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLAN1RouteVM5" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[5].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
            "AddVLANRouteVM5" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[5].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.10.0",
               gateway    => "192.168.5.1",
            },
            "AddVXLAN1RouteVM6" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[6].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.10.1",
            },
            "AddVXLAN2RouteVM6" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[6].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.10.1",
            },
            "NoPortChannel" => {
               Type            => "Port",
               TestPort        => "host.[-1].pswitchport.[-1]",
               configurechannelgroup => "no",
            },
            "RemoveChannelGroup1" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    => "32",
            },
            "RemoveChannelGroup2" => {
               Type                 => "Switch",
               TestSwitch           => "pswitch.[-1]",
               removeportchannel    => "62",
            },
            "PingTest1" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest2" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest3" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[5].vnic.[1]",
               SupportAdapter  => "vm.[1].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest4" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[6].vnic.[1]",
               parallelsession => "yes",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "NetperfTest1" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "PASS",
            },
            "NetperfTest2" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "PASS",
            },
            "NetperfTest3" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[5].vnic.[1]",
               SupportAdapter  => "vm.[1].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "PASS",
            },
            "NetperfTest4" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[6].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "PASS",
            },
         },
      },
      'VDRTrafficWithTeamingSRCMAC'   => {
         TestName         => 'VDRTrafficWithTeamingSRCMAC',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR traffic with SRCMAC teaming',
         Procedure        => '1. Create 2 VXLAN networks with vxlan configured'.
                             '   to use the src_mac lb teaming policy'.
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TEAMINGSRCMAC_TESTBEDSPEC,
         WORKLOADS        => $teamingWorkload,
      },
      'VDRTrafficWithTeamingSRCID'   => {
         TestName         => 'VDRTrafficWithTeamingSRCID',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR traffic over SRCID teaming',
         Procedure        => '1. Create 2 VXLAN networks with vxlan configured'.
                             '   to use the src_id teaming policy'.
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TEAMINGSRCID_TESTBEDSPEC,
         WORKLOADS        => $teamingWorkload,
      },
      'VDRTrafficWithTeamingLoadBased'   => {
         TestName         => 'VDRTrafficWithTeamingLoadBased',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR traffic over load based teaming',
         Procedure        => '1. Create 2 VXLAN networks with vxlan configured'.
                             '   to use the loadbased teaming policy'.
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TEAMINGLOADBASED_TESTBEDSPEC,
         WORKLOADS        => $teamingWorkload,
      },

      'VDRTrafficWithTeamingFailover'   => {
         TestName         => 'VDRTrafficWithTeamingFailover',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route traffic over FailOver teaming',
         Procedure        => '1. Create 2 VXLAN networks with vxlan configured'.
                             '   to use the explicit_failover teaming policy'.
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TEAMINGFAILOVER_TESTBEDSPEC,
         WORKLOADS        => $teamingWorkload,
      },
      'VDRTrafficWithTeamingFailoverWithMultipleVTEP'   => {
         TestName         => 'VDRTrafficWithTeamingFailoverWithMultipleVTEP',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route over FailoverWithMultipleVTEPs teaming',
         Procedure        => '1. Create 2 VXLAN networks with vxlan configured'.
                             '   to use the explicit_failover teaming policy'.
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDSTEAMING_FAILOVER_MULTIPLEVTEP_TESTBEDSPEC,
         WORKLOADS        => $teamingWorkload,
      },
      'VDRTrafficWithTransportVLAN'   => {
         TestName         => 'VDRTrafficWithTransportVLAN',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route traffic over transport vlan',
         Procedure        => '1. Create 2 VXLAN networks with vxlan configured'.
                             '   to use the explicit_failover teaming policy'.
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '8. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TRANSPORTVLAN_TESTBEDSPEC,
         WORKLOADS        => $teamingWorkload,
      },
      'VXLANToVLANBridge' => {
         TestName         => 'VXLANToVLANBridge',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR traffic over VLAN to VLAN bridging',
         Procedure        => '1. Create 2 VXLAN networks'.
                             '2. Create VDR instances on each host and add'.
                             '   create a bridge between vxlan and vlan'.
                             '3. Verify that LIF info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through.'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '9. Remove the bridge and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TESTBEDSPEC,
         WORKLOADS => {
            Sequence =>  [['CreateVirtualWires'],
                          ['PlaceVMsOnVirtualWire1'],
                          ['PlaceVMsOnVLAN'],
                          ['PowerOnVM1','PowerOnVM3',
                           'PowerOnVM2','PowerOnVM4'],
                          ['DeployEdge'],
                          ['BridgeVXLANToVLAN'],
                          ['SetVXLANIPVM1','SetVLANIPVM2',
                           'SetVXLANIPVM3','SetVLANIPVM4'],
                          ['NetperfTest1'],['NetperfTest2'],
                          ['NetperfTest3'],['NetperfTest4'],
                          ['PingTest1'],['PingTest2'],
                          ['PingTest3'],['PingTest4'],
		        ],
            ExitSequence =>  [['PowerOffVM1','PowerOffVM3',
                               'PowerOffVM2','PowerOffVM4'],
                              ['DeleteVNIC1'],
                              ['DeleteVNIC3'],
                              ['DeleteVDREdge'],
                              ['DeleteVirtualWires']],

            'CreateVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenerate",
                     tenantid => "1",
                     controlplanemode => "HYBRID_MODE",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
            },
            "DeployEdge"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[1]",
                     primaryaddress => "10.10.10.45",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            "BridgeVXLANToVLAN" => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               bridge => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     virtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     portgroup   => "vc.[1].dvportgroup.[2]",
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVirtualWire1' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               deletevnic => "vm.[3].vnic.[1]",
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVLAN' => {
               Type   => "VM",
               TestVM => "vm.[2],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOffVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweroff",
            },
            'PowerOffVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweroff",
            },
            "SetVXLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '192.168.20.1',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '192.168.20.2',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '192.168.20.3',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '192.168.20.4',
               netmask    => "255.255.255.0",
            },
            "PingTest1" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest2" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest3" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest4" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               parallelsession => "yes",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "NetperfTest1" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest2" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest3" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest4" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
         },
      },
      'VXLANToVXLANWithHeadendReplication'   => {
         TestName         => 'VXLANToVXLANWithHeadendReplication',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route traffic over VXLAN to VXLAN with Headend Replication',
         Procedure        => '1. Create 2 VXLAN networks with headend replication'.
                             '   enabled'.
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TESTBEDSPEC,
         WORKLOADS => {
           Sequence =>  [
                         ['CreateVirtualWires'],
                         ['PlaceVMsOnVirtualWire1'],
                         ['PlaceVMsOnVirtualWire2'],
                         ['PowerOnVM1','PowerOnVM3',
                          'PowerOnVM2','PowerOnVM4'],
                         ['DeployEdge'],
                         ['CreateVXLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['SetVXLANIPVM1','SetVXLANIPVM2',
                         'SetVXLANIPVM3','SetVXLANIPVM4'],
                         ['AddVXLANRouteVM1','AddVXLANRouteVM2',
                          'AddVXLANRouteVM3','AddVXLANRouteVM4'],
                         ['NetperfTest1'],['NetperfTest2'],
                         ['NetperfTest3'],['NetperfTest4'],
                         ['PingTest1'],['PingTest2'],
                         ['PingTest3'],['PingTest4'],
                        ],
            ExitSequence =>  [
                              ['PowerOffVM1','PowerOffVM3',
                               'PowerOffVM2','PowerOffVM4'],
                              ['DeleteVNIC1','DeleteVNIC2',
                               'DeleteVNIC3','DeleteVNIC4'],
                              ['DeleteVDREdge'],
                              ['DeleteVirtualWires']
                              ],

            'CreateVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                     controlplanemode => "UNICAST_MODE",
                  },
                  '[2]' => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                     controlplanemode => "UNICAST_MODE",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-2]",
            },
            "DeployEdge"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[1]",
                     primaryaddress => "10.10.10.46",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            'CreateVXLANLIF1' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.1.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            'CreateVXLANLIF2' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[2]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.5.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVirtualWire1' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire2' => {
               Type   => "VM",
               TestVM => "vm.[2],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'DeleteVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               deletevnic => "vm.[3].vnic.[1]",
            },
            'DeleteVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               deletevnic => "vm.[4].vnic.[1]",
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOffVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweroff",
            },
            'PowerOffVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweroff",
            },
            "SetVXLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '192.168.1.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '192.168.5.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '192.168.1.10',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '192.168.5.10',
               netmask    => "255.255.255.0",
            },
            "AddVXLANRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
             "AddVXLANRouteVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
            "PingTest1" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest2" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest3" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest4" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               parallelsession => "yes",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "NetperfTest1" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest2" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest3" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest4" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
         },
      },
      'AddDeleteLIFWithVDRTraffic'   => {
         TestName         => 'AddDeleteLIFWithVDRTraffic',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR can route traffic while adding and deleting LIFs ',
         Procedure        => '1. Create 2 VXLAN networks ' .
                             '2. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '3. Verify the route info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '5. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '6. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '7. Send unicast, multicast and broadcast traffic'.
                             '8. Run traffic between same host and different host'.
                             '9. While traffic is running do add/delete LIF'.
                             '9. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TESTBEDSPEC,
         WORKLOADS => {
            Sequence =>  [
                         ['CreateVirtualWires'],
                         ['PlaceVMsOnVirtualWire1'],
                         ['PlaceVMsOnVirtualWire2'],
                         ['PowerOnVM1','PowerOnVM3',
                          'PowerOnVM2','PowerOnVM4'],
                         ['DeployEdge'],
                         ['CreateVXLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['SetVXLANIPVM1','SetVXLANIPVM2',
                         'SetVXLANIPVM3','SetVXLANIPVM4'],
                         ['AddVXLANRouteVM1','AddVXLANRouteVM2',
                          'AddVXLANRouteVM3','AddVXLANRouteVM4'],
                         ['DeleteAddLIF1'],
                         ['NetperfTest1','DeleteAddLIF1'],
                         ['PingTest1PASS'],
                         ['NetperfTest2','DeleteAddLIF2'],
                         ['PingTest1PASS'],
                         ['PingTest2PASS'],
                         ],
            ExitSequence =>  [
                              ['PowerOffVM1','PowerOffVM3',
                               'PowerOffVM2','PowerOffVM4'],
                              ['DeleteVDREdge'],
                              ['DeleteVNIC1','DeleteVNIC2',
                               'DeleteVNIC3','DeleteVNIC4'],
                              ['DeleteVirtualWires'],
                              ],

            'CreateVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
                  '[2]' => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-2]",
            },
            "DeployEdge"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[3]",
                     primaryaddress => "10.10.10.47",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            'CreateVXLANLIF1' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               sleepbetweenworkloads => "20",
               lif => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.1.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            'DeleteAddLIF1' => {
               Type   => "VM",
               sleepbetweencombos => "90",
               Iterations => "5",
               TestVM => "vsm.[1].vse.[1]",
               deletelif => "vsm.[1].vse.[1].lif.[1]",
               RunWorkload => {
                  Type   => "VM",
                  TestVM => "vsm.[1].vse.[1]",
                  sleepbetweenworkloads => "20",
                  lif => {
                     '[1]'   => {
                        name        => "AutoGenerate",
                        portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                        type        => "internal",
                        connected   => 1,
                        addressgroup => [{addresstype => "primary",
                                          ipv4address => "192.168.1.1",
                                          netmask     => "255.255.255.0",}]
                     },
                  },
               },
            },
            'CreateVXLANLIF2' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               sleepbetweenworkloads => "20",
               lif => {
                  '[2]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.5.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            'DeleteAddLIF2' => {
               Type   => "VM",
               sleepbetweencombos => "60",
               TestVM => "vsm.[1].vse.[1]",
               deletelif => "vsm.[1].vse.[1].lif.[2]",
               RunWorkload => {
                  Type   => "VM",
                  TestVM => "vsm.[1].vse.[1]",
                  sleepbetweenworkloads => "20",
                  lif => {
                     '[2]'   => {
                        name        => "AutoGenerate",
                        portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                        type        => "internal",
                        connected   => 1,
                        addressgroup => [{addresstype => "primary",
                                          ipv4address => "192.168.5.1",
                                          netmask     => "255.255.255.0",}]
                     },
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVirtualWire1' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire2' => {
               Type   => "VM",
               TestVM => "vm.[2],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC1' => {
               Type   => "VM",
               TestVM => "vm.[1]",
               deletevnic => "vm.[1].vnic.[1]",
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'DeleteVNIC3' => {
               Type   => "VM",
               TestVM => "vm.[3]",
               deletevnic => "vm.[3].vnic.[1]",
            },
            'DeleteVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               deletevnic => "vm.[4].vnic.[1]",
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOffVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweroff",
            },
            'PowerOffVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweroff",
            },
            "SetVXLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '192.168.1.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '192.168.5.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '192.168.1.10',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '192.168.5.10',
               netmask    => "255.255.255.0",
            },
            "AddVXLANRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
             "AddVXLANRouteVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
            "NetperfTest1" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "600",
               ExpectedResult => "IGNORE",
            },
            "PingTest1PASS" => {
               Type            => "Traffic",
               ToolName        => "ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "180",
            },
            "NetperfTest2" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[4].vnic.[1]",
               SupportAdapter  => "vm.[1].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "600",
               ExpectedResult => "IGNORE",
            },
            "PingTest2PASS" => {
               Type            => "Traffic",
               ToolName        => "ping",
               TestAdapter     => "vm.[4].vnic.[1]",
               SupportAdapter  => "vm.[1].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration => "60",
            },
         },
      },
      'AddRemoveBridgeWithVDRTraffic' => {
         TestName         => 'AddRemoveBridgeWithTraffic',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VDR traffic while adding and deleting bridge',
         Procedure        => '1. Create 2 VXLAN networks'.
                             '2. Create VDR instances on each host and add'.
                             '   create a bridge between vxlan and vlan'.
                             '3. Verify that LIF info in the VDR'.
                             '4. Create 1 VM on each host with test vNICs'.
                             '   on different VXLANs'.
                             '5. Send traffic between the VMs and make sure it'.
                             '   goes through.'.
                             '6. Send unicast, multicast and broadcast traffic'.
                             '7. Run traffic between same host and different host'.
                             '8. Add/Remove Bridge while traffic is running'.
                             '9. Remove the bridge and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_ONE_VDS_TESTBEDSPEC,
         WORKLOADS => {
            Sequence =>  [
                         ['CreateVirtualWires'],
                         ['PlaceVMsOnVirtualWire1'],
                         ['PlaceVMsOnVLAN'],
                         ['PowerOnVM1','PowerOnVM3',
                          'PowerOnVM2','PowerOnVM4'],
                         ['DeployEdge'],
                         ['BridgeVXLANToVLAN'],
                         ['SetVLANIPVM1','SetVXLANIPVM2',
                         'SetVLANIPVM3','SetVXLANIPVM4'],
                         ['NetperfTest1','DeleteAddBridge'],
                         ['NetperfTest2','DeleteAddBridge'],
                         ['PingTest1Pass'],
                         ['PingTest2Pass'],
                         ],
            ExitSequence =>  [
                              ['PowerOffVM1','PowerOffVM3',
                               'PowerOffVM2','PowerOffVM4'],
                              ['DeleteVDREdge'],
                              ['DeleteVNIC2'],['DeleteVNIC4'],
                              ['DeleteVirtualWires']
                              ],

            'CreateVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
                  '[2]' => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-2]",
            },
            "DeployEdge"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[1]",
                     primaryaddress => "10.10.10.48",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            "BridgeVXLANToVLAN" => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               sleepbetweencombos => "20",
               bridge => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     virtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     portgroup   => "vc.[1].dvportgroup.[2]",
                  },
               },
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'DeleteVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               deletevnic => "vm.[4].vnic.[1]",
            },
            "DeleteAddBridge" => {
               Type => "VM",
               TestVM => "vsm.[1].vse.[1]",
               deletebridge => "vsm.[1].vse.[1].bridge.[1]",
               sleepbetweenworkloads => "90",
               Iterations => "5",
               RunWorkload => {
                  Type   => "VM",
                  TestVM => "vsm.[1].vse.[1]",
                  sleepbetweencombos => "20",
                  bridge => {
                     '[1]'   => {
                        name        => "AutoGenerate",
                        virtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVirtualWire1' => {
               Type   => "VM",
               TestVM => "vm.[2],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVLAN' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOffVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweroff",
            },
            'PowerOffVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweroff",
            },
             "SetVLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '192.168.20.1',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '192.168.20.2',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '192.168.20.3',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '192.168.20.4',
               netmask    => "255.255.255.0",
            },

            "NetperfTest1" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "420",
               ExpectedResult => "IGNORE",
            },
            "PingTest1Pass" => {
               Type            => "Traffic",
               ToolName        => "ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "180",
            },
            "NetperfTest2" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "420",
               ExpectedResult => "IGNORE",
            },
            "PingTest2Pass" => {
               Type            => "Traffic",
               ToolName        => "ping",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "180",
            },
         },
      },
      'VXLAN2VLANTrafficWithDifferentVDS'   => {
         TestName         => 'VXLAN2VLANTrafficWithDifferentVDS',
         Category         => 'Networking',
         Component        => 'Virtual Routing',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VDR',
         Summary          => 'Verify VXLAN to VLAN traffic with different VDS',
         Procedure        => '1. Create 2 VXLAN networks'.
                             '2. Create VLAN networks in different VDS'.
                             '3. Create VDR instances on each host and add'.
                             '   2 LIFs to route between the VXLANs '.
                             '   (this will come from VSE)'.
                             '4. Verify the route info in the VDR'.
                             '5. Create 1 VM on each host with test vNICs'.
                             '   on different VLANs'.
                             '6. In the VMs, set the default gateway to'.
                             '   respective VDRs'.
                             '7. Send traffic between the VMs and make sure it'.
                             '   goes through. From the source VM it should go'.
                             '   to VDR on that host and it should route'.
                             '   the pkts to VDR on the destination host.'.
                             '   Once the pkts reach VDR on the destination'.
                             '   host, it should forward the pkts to the'.
                             '   destination VM'.
                             '8. Send unicast, multicast and broadcast traffic'.
                             '9. Run traffic between same host and different host'.
                             '10. Delete the VMs, LIFs and the VDR',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '6650',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sbolla',
         Partnerfacing    => 'N',
         Duration         => '100',
         Version          => '2',
         TestbedSpec      => VDR_TWO_VDS_TESTBEDSPEC,
         WORKLOADS        => {
            Sequence =>  [
                         ['CreateVirtualWires'],
                         ['PlaceVMsOnVirtualWire1'],
                         ['PlaceVMsOnVLAN'],
                         ['PowerOnVM1','PowerOnVM3',
                          'PowerOnVM2','PowerOnVM4'],
                         ['DeployEdge'],
                         ['CreateVLANLIF1'],
                         ['CreateVXLANLIF2'],
                         ['SetVLANIPVM1','SetVXLANIPVM2',
                         'SetVLANIPVM3','SetVXLANIPVM4'],
                         ['AddVLANRouteVM1','AddVXLANRouteVM2',
                          'AddVLANRouteVM3','AddVXLANRouteVM4'],
                         ['NetperfTest1'],['NetperfTest2'],
                         ['NetperfTest3'],['NetperfTest4'],
                         ['PingTest1'],['PingTest2'],
                         ['PingTest3'],['PingTest4'],
		        ],
            ExitSequence =>  [['PowerOffVM1','PowerOffVM3',
                               'PowerOffVM2','PowerOffVM4'],
                              ['DeleteVDREdge'],
                              ['DeleteVNIC2','DeleteVNIC4'],
                              ['DeleteVirtualWires']],

            'CreateVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[1]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type  => "TransportZone",
               TestTransportZone  => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
            },
            "DeployEdge"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]",
                     portgroup     => "vc.[1].dvportgroup.[1]",
                     primaryaddress => "10.10.10.49",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            'CreateVLANLIF1' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[1]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vc.[1].dvportgroup.[2]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.1.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            'CreateVXLANLIF2' => {
               Type   => "VM",
               TestVM => "vsm.[1].vse.[1]",
               lif => {
                  '[2]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     type        => "internal",
                     connected   => 1,
                     addressgroup => [{addresstype => "primary",
                                       ipv4address => "192.168.5.1",
                                       netmask     => "255.255.255.0",}]
                  },
               },
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVirtualWire1' => {
               Type   => "VM",
               TestVM => "vm.[2],vm.[4]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'DeleteVNIC2' => {
               Type   => "VM",
               TestVM => "vm.[2]",
               deletevnic => "vm.[2].vnic.[1]",
            },
            'DeleteVNIC4' => {
               Type   => "VM",
               TestVM => "vm.[4]",
               deletevnic => "vm.[4].vnic.[1]",
            },
            "DeleteVDREdge"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[1]",
            },
            'PlaceVMsOnVLAN' => {
               Type   => "VM",
               TestVM => "vm.[1],vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver            => "e1000",
                     portgroup         => "vc.[1].dvportgroup.[2]",
                     connected         => 1,
                     startconnected    => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PowerOnVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweron",
            },
            'PowerOnVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweron",
            },
            'PowerOnVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweron",
            },
            'PowerOnVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweron",
            },
            'PowerOffVM1' => {
               Type    => "VM",
               TestVM  => "vm.[1]",
               vmstate => "poweroff",
            },
            'PowerOffVM2' => {
               Type    => "VM",
               TestVM  => "vm.[2]",
               vmstate => "poweroff",
            },
            'PowerOffVM3' => {
               Type    => "VM",
               TestVM  => "vm.[3]",
               vmstate => "poweroff",
            },
            'PowerOffVM4' => {
               Type    => "VM",
               TestVM  => "vm.[4]",
               vmstate => "poweroff",
            },
             "SetVLANIPVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               ipv4       => '192.168.1.5',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               ipv4       => '192.168.5.5',
               netmask    => "255.255.255.0",
            },
            "SetVLANIPVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               ipv4       => '192.168.1.10',
               netmask    => "255.255.255.0",
            },
            "SetVXLANIPVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               ipv4       => '192.168.5.10',
               netmask    => "255.255.255.0",
            },
             "AddVLANRouteVM1" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[1].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM2" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[2].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
             "AddVLANRouteVM3" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[3].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.5.0",
               gateway    => "192.168.1.1",
            },
            "AddVXLANRouteVM4" => {
               Type       => "NetAdapter",
               Testadapter=> "vm.[4].vnic.[1]",
               netmask    => "255.255.255.0",
               route      => "add",
               network    => "192.168.1.0",
               gateway    => "192.168.5.1",
            },
            "PingTest1" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest2" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest3" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "PingTest4" => {
               Type            => "Traffic",
               ToolName        => "Ping",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               parallelsession => "yes",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               TestDuration    => "120",
            },
            "NetperfTest1" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[2].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest2" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[3].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest3" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[1].vnic.[1]",
               SupportAdapter  => "vm.[4].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
            "NetperfTest4" => {
               Type            => "Traffic",
               ToolName        => "netperf",
               TestAdapter     => "vm.[2].vnic.[1]",
               SupportAdapter  => "vm.[3].vnic.[1]",
               L3Protocol      => "ipv4",
               L4Protocol      => "tcp,udp",
               parallelsession => "yes",
               SendMessageSize => "63488",
               NoofOutbound    => "1",
               NoofInbound     => "1",
               LocalSendSocketSize => "131072",
               RemoteSendSocketSize    => "131072",
               TestDuration => "180",
               ExpectedResult  => "ignore",
            },
         },
      },
   );
}

##########################################################################
# new --
#       This is the constructor for VDR TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of VDR class
#
# Side effects:
#       None
#
#########################################################################

sub new
{
   my ($proto) = @_;
   #
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   #
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%VDR);
   return (bless($self, $class));
}

1;
