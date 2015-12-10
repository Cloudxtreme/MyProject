package TDS::NSX::Networking::VXLAN::VXLANStressTds;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use TDS::NSX::Networking::VXLAN::TestbedSpec;
use TDS::NSX::Networking::VXLAN::CommonWorkloads ':AllConstants';
use TDS::NSX::Networking::VXLAN::TestbedSpec ':AllConstants';
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
@ISA = qw(TDS::Main::VDNetMainTds);

{
   %VXLANStress = (
      'StressControllerUpDown' => {
         TestName         => 'StressControllerUpDown',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify whether the controller is' .
                             'able to establish proper connections' .
                             'with all VTEPS simultaneously, when' .
                             'it is brought down and back up again. ',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automatic',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
                # step 1, make sure all three types of virtualwire works corerctly
                ['CreateVirtualWire'],
                ['PlaceVMsOnVirtualWire1'],
                ['PlaceVMsOnVirtualWire2'],
                ['PlaceVMsOnVirtualWire3'],
                ['PoweronVM1','PoweronVM2','PoweronVM3'],
                ['PoweronVM4','PoweronVM5','PoweronVM6'],
                ['PoweronVM7','PoweronVM8','PoweronVM9'],
                ['CheckWire2MTEPOnHost'],
                ['CheckWire3MTEPOnHost'],
                ['VerifyVirtualWire2ConnectionTableOnControllers',
                 'VerifyVirtualWire2VtepTableOnControllers',
                 'VerifyVirtualWire3ConnectionTableOnControllers',
                 'VerifyVirtualWire3VtepTableOnControllers'],
                ['NetperfTestVirtualWire1Unicat'],
                ['NetperfTestVirtualWire2Unicat'],
                ['NetperfTestVirtualWire3Unicat'],
                ['NetperfTestVirtualWire1Multicast'],
                ['NetperfTestVirtualWire2Multicast'],
                ['NetperfTestVirtualWire3Multicast'],
                ['PingTrafficVirtualWire1Broadcast'],
                ['PingTrafficVirtualWire2Broadcast'],
                ['PingTrafficVirtualWire3Broadcast'],

                # step 2, poweroff/power on controllers multi times and check the traffics
                ['StressPowerOffPowerOnAllControllers'],
                ['NetperfTestVirtualWire1Unicat'],
                ['NetperfTestVirtualWire2Unicat'],
                ['NetperfTestVirtualWire3Unicat'],
                ['VerifyVirtualWire2ConnectionTableOnControllers',
                 'VerifyVirtualWire2VtepTableOnControllers',
                 'VerifyVirtualWire3ConnectionTableOnControllers',
                 'VerifyVirtualWire3VtepTableOnControllers'],
                ['NetperfTestVirtualWire1Multicast'],
                ['NetperfTestVirtualWire2Multicast'],
                ['NetperfTestVirtualWire3Multicast'],
                ['PingTrafficVirtualWire1Broadcast'],
                ['PingTrafficVirtualWire2Broadcast'],
                ['PingTrafficVirtualWire3Broadcast'],

               ],
            ExitSequence => [
                ['PoweroffVM'],
                ['DeleteVM1Vnic1'],
                ['DeleteVM2Vnic1'],
                ['DeleteVM3Vnic1'],
                ['DeleteVM4Vnic1'],
                ['DeleteVM5Vnic1'],
                ['DeleteVM6Vnic1'],
                ['DeleteVM7Vnic1'],
                ['DeleteVM8Vnic1'],
                ['DeleteVM9Vnic1'],
                ['DeleteAllVirtualWires'],
               ],
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'DeleteVM3Vnic1' => DELETE_VM3_VNIC1,
            'DeleteVM4Vnic1' => DELETE_VM4_VNIC1,
            'DeleteVM5Vnic1' => DELETE_VM5_VNIC1,
            'DeleteVM6Vnic1' => DELETE_VM6_VNIC1,
            'DeleteVM7Vnic1' => DELETE_VM7_VNIC1,
            'DeleteVM8Vnic1' => DELETE_VM8_VNIC1,
            'DeleteVM9Vnic1' => DELETE_VM9_VNIC1,
            'CreateVirtualWire' => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-3]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire2' => {
               Type => "VM",
               TestVM => "vm.[4-6]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-9],",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[3]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM6' => POWERON_VM6,
            'PoweronVM7' => POWERON_VM7,
            'PoweronVM8' => POWERON_VM8,
            'PoweronVM9' => POWERON_VM9,

            'CheckWire2MTEPOnHost' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[2]",
               checkmteponhost => 'host.[2-4]',
            },
            'CheckWire3MTEPOnHost' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[3]",
               checkmteponhost => 'host.[2-4]',
            },
            "NetperfTestVirtualWire1Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp,udp",
               L3Protocol     => "ipv4,ipv6",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire2Unicat" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp,udp",
               L3Protocol     => "ipv4,ipv6",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire3Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp,udp",
               L3Protocol     => "ipv4,ipv6",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire1Multicast" => {
               Type           => "Traffic",
               RoutingScheme  => "Multicast",
               L3Protocol     => "ipv4",
               udpbandwidth   => VDNetLib::TestData::TestConstants::VXLAN_MULTICAST_UDP_BANDWIDTH,
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire2Multicast" => {
               Type           => "Traffic",
               RoutingScheme  => "Multicast",,
               L3Protocol     => "ipv4",
               udpbandwidth   => VDNetLib::TestData::TestConstants::VXLAN_MULTICAST_UDP_BANDWIDTH,
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire3Multicast" => {
               Type           => "Traffic",
               RoutingScheme  => "Multicast",
               L3Protocol     => "ipv4",
               udpbandwidth   => VDNetLib::TestData::TestConstants::VXLAN_MULTICAST_UDP_BANDWIDTH,
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
               TestDuration   => "30",
            },
            'PingTrafficVirtualWire1Broadcast' => {
               Type           => "Traffic",
               toolname       => "ping",
               Routingscheme  => "broadcast",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
            },
            'PingTrafficVirtualWire2Broadcast' => {
               Type           => "Traffic",
               toolname       => "ping",
               Routingscheme  => "broadcast",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
            },
            'PingTrafficVirtualWire3Broadcast' => {
               Type           => "Traffic",
               toolname       => "ping",
               Routingscheme  => "broadcast",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
            },
            'StressPowerOffPowerOnAllControllers' => {
               Type => "VM",
               TestVM => "vsm.[1].vxlancontroller.[-1]",
               iterations => "20",
               vmstate  => "poweroff,poweron",
               maxtimeout => "10800",
            },
           'VerifyVirtualWire2ConnectionTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyConnectionTableOnController[?]contain_once" => [
                   {
                      hostip  => "host.[2]",
                   },
                   {
                      hostip  => "host.[3]",
                   },
                   {
                      hostip  => "host.[4]",
                   },
               ],
               noofreties   => "5",
            },
            'VerifyVirtualWire3ConnectionTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyConnectionTableOnController[?]contain_once" => [
                   {
                      hostip  => "host.[2]",
                   },
                   {
                      hostip  => "host.[3]",
                   },
                   {
                      hostip  => "host.[4]",
                   },
               ],
               noofreties   => "5",
            },
            'VerifyVirtualWire2VtepTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyVtepTableOnController[?]contain_once" => [
                   {
                      vtepip  => "host.[2]",
                      cluster => "vc.[1].datacenter.[1].cluster.[2]",
                   },
                   {
                      vtepip  => "host.[3]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
                   {
                      vtepip  => "host.[4]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
               ],
               noofreties   => "5",
            },
            'VerifyVirtualWire3VtepTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyVtepTableOnController[?]contain_once" => [
                   {
                      vtepip  => "host.[2]",
                      cluster => "vc.[1].datacenter.[1].cluster.[2]",
                   },
                   {
                      vtepip  => "host.[3]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
                   {
                      vtepip  => "host.[4]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
               ],
               noofreties   => "5",
            },
         },
      },
      'StressVMIpMacChange' => {
         TestName         => 'StressVMIpMacChange',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'StressVMIpMacChange: To verify whether the' .
                             'controller updates all VTEPs instantaneously,' .
                             'when the ip address and mac address of a VM' .
                             'is changed continuously.',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automatic',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
              # step 1, check all the ARP and MAC addresses can be
              #         learned correctly on controllers
                ['CreateVirtualWire'],
                ['PlaceVMsOnVirtualWire1'],
                ['PlaceVMsOnVirtualWire2'],
                ['PlaceVMsOnVirtualWire3'],
                ['PoweronVM1','PoweronVM2','PoweronVM3'],
                ['PoweronVM4','PoweronVM5','PoweronVM6'],
                ['PoweronVM7','PoweronVM8','PoweronVM9'],
                ['NetperfTestVirtualWire2Unicat'],
                ['ArpPingVM4', 'ArpPingVM56'],
                ['VerifyVirtualWire2VMsArpEntryOnControllers',
                 'VerifyVirtualWire2VMsMacEntryOnControllers'],
                ['NetperfTestVirtualWire3Unicat'],
                ['ArpPingVM7', 'ArpPingVM89'],
                ['VerifyVirtualWire3VMsArpEntryOnControllers',
                 'VerifyVirtualWire3VMsMacEntryOnControllers'],

              # step 2, change securyPolicy accept
                ['SetVDS12vWire1MacAddressChangeSecurityPolicyAccept'],
                ['SetVDS12vWire1ForgedTransmitChangeSecurityPolicyAccept'],
                ['SetVDS12vWire2MacAddressChangeSecurityPolicyAccept'],
                ['SetVDS12vWire2ForgedTransmitChangeSecurityPolicyAccept'],
                ['SetVDS12vWire3MacAddressChangeSecurityPolicyAccept'],
                ['SetVDS12vWire3ForgedTransmitChangeSecurityPolicyAccept'],

              # step 3, change vm1 ip and mac ddresses to new ones,
              #         after change vms ip/mac addresses, check the new
              #         ARP and MAC addresses can be learned correctly
              #         on controllers, also check the traffic working
              #         correctly
                ['ChangeVM1Vnic1IpAddress'],
                ['ChangeVM1Vnic1MacAddress'],
                ['ArpPingVM1', 'ArpPingVM23'],
                ['NetperfTestVirtualWire1Unicat'],

              # step 4, iterator ip/mac change from vm1 to vm9, do all
              #         the same checking again
              # vm2:
                ['ChangeVM2Vnic1IpAddress'],
                ['ChangeVM2Vnic1MacAddress'],
                ['ArpPingVM1', 'ArpPingVM23'],
                ['NetperfTestVirtualWire1Unicat'],

              # vm3:
                ['ChangeVM3Vnic1IpAddress'],
                ['ChangeVM3Vnic1MacAddress'],
                ['ArpPingVM1', 'ArpPingVM23'],
                ['NetperfTestVirtualWire1Unicat'],

              # vm4:
                ['ChangeVM4Vnic1IpAddress'],
                ['ChangeVM4Vnic1MacAddress'],
                ['ArpPingVM4', 'ArpPingVM56'],
                ['VerifyVirtualWire2VMsArpEntryOnControllers',
                 'VerifyVirtualWire2VMsMacEntryOnControllers'],
                ['NetperfTestVirtualWire2Unicat'],

              # vm5:
                ['ChangeVM5Vnic1IpAddress'],
                ['ChangeVM5Vnic1MacAddress'],
                ['ArpPingVM4', 'ArpPingVM56'],
                ['VerifyVirtualWire2VMsArpEntryOnControllers',
                 'VerifyVirtualWire2VMsMacEntryOnControllers'],
                ['NetperfTestVirtualWire2Unicat'],

              # vm6:
                ['ChangeVM6Vnic1IpAddress'],
                ['ChangeVM6Vnic1MacAddress'],
                ['ArpPingVM4', 'ArpPingVM56'],
                ['VerifyVirtualWire2VMsArpEntryOnControllers',
                 'VerifyVirtualWire2VMsMacEntryOnControllers'],
                ['NetperfTestVirtualWire2Unicat'],

              # vm7:
                ['ChangeVM7Vnic1IpAddress'],
                ['ChangeVM7Vnic1MacAddress'],
                ['ArpPingVM7', 'ArpPingVM89'],
                ['VerifyVirtualWire3VMsArpEntryOnControllers',
                 'VerifyVirtualWire3VMsMacEntryOnControllers'],
                ['NetperfTestVirtualWire3Unicat'],

              # vm8:
                ['ChangeVM8Vnic1IpAddress'],
                ['ChangeVM8Vnic1MacAddress'],
                ['ArpPingVM7', 'ArpPingVM89'],
                ['VerifyVirtualWire3VMsArpEntryOnControllers',
                 'VerifyVirtualWire3VMsMacEntryOnControllers'],
                ['NetperfTestVirtualWire3Unicat'],

              # vm9:
                ['ChangeVM9Vnic1IpAddress'],
                ['ChangeVM9Vnic1MacAddress'],
                ['ArpPingVM7', 'ArpPingVM89'],
                ['VerifyVirtualWire3VMsArpEntryOnControllers',
                 'VerifyVirtualWire3VMsMacEntryOnControllers'],
                ['NetperfTestVirtualWire3Unicat'],

              # step 5, pick up vm4 to do the vm ip change for many times
              # also do the mac change for many times
                ['ChangeVM4Vnic1IpAddressManyTimes'],                
                ['ChangeVM4Vnic1MacAddressManyTimes'],
                ['ChangeVM4Vnic1IpAddress'],
                ['ChangeVM4Vnic1MacAddress'],
                ['ArpPingVM4', 'ArpPingVM56'],
                ['VerifyVirtualWire2VMsArpEntryOnControllers',
                 'VerifyVirtualWire2VMsMacEntryOnControllers'],
                ['NetperfTestVirtualWire2Unicat'],

            ],
            ExitSequence => [
                ['PoweroffVM'],
                ['DeleteVM1Vnic1'],
                ['DeleteVM2Vnic1'],
                ['DeleteVM3Vnic1'],
                ['DeleteVM4Vnic1'],
                ['DeleteVM5Vnic1'],
                ['DeleteVM6Vnic1'],
                ['DeleteVM7Vnic1'],
                ['DeleteVM8Vnic1'],
                ['DeleteVM9Vnic1'],
                ['DeleteAllVirtualWires'],
            ],
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'DeleteVM3Vnic1' => DELETE_VM3_VNIC1,
            'DeleteVM4Vnic1' => DELETE_VM4_VNIC1,
            'DeleteVM5Vnic1' => DELETE_VM5_VNIC1,
            'DeleteVM6Vnic1' => DELETE_VM6_VNIC1,
            'DeleteVM7Vnic1' => DELETE_VM7_VNIC1,
            'DeleteVM8Vnic1' => DELETE_VM8_VNIC1,
            'DeleteVM9Vnic1' => DELETE_VM9_VNIC1,

            'CreateVirtualWire' => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-3]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire2' => {
               Type => "VM",
               TestVM => "vm.[4-6]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-9],",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[3]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM6' => POWERON_VM6,
            'PoweronVM7' => POWERON_VM7,
            'PoweronVM8' => POWERON_VM8,
            'PoweronVM9' => POWERON_VM9,

            "ArpPingVM1" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[1].vnic.[1]",
               SupportAdapter   => "vm.[2-3].vnic.[1]",
               TestDuration     => "5",
               connectivitytest => "0",
            },
            "ArpPingVM23" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[2-3].vnic.[1]",
               SupportAdapter   => "vm.[1].vnic.[1]",
               TestDuration     => "5",
               connectivitytest => "0",
            },
            "ArpPingVM4" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[4].vnic.[1]",
               SupportAdapter   => "vm.[5-6].vnic.[1]",
               TestDuration     => "5",
               connectivitytest => "0",
            },
            "ArpPingVM56" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[5-6].vnic.[1]",
               SupportAdapter   => "vm.[4].vnic.[1]",
               TestDuration     => "5",
               connectivitytest => "0",
            },
            "ArpPingVM7" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[7].vnic.[1]",
               SupportAdapter   => "vm.[8-9].vnic.[1]",
               TestDuration     => "5",
               connectivitytest => "0",
            },
            "ArpPingVM89" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[8-9].vnic.[1]",
               SupportAdapter   => "vm.[7].vnic.[1]",
               TestDuration     => "5",
               connectivitytest => "0",
            },
            'VerifyVirtualWire1VMsArpEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[1]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyArpEntryOnController[?]contain_once" => [
                   {
                      ip   => "vm.[1].vnic.[1]",
                      mac  => "vm.[1].vnic.[1]",
                   },
                   {
                      ip   => "vm.[2].vnic.[1]",
                      mac  => "vm.[2].vnic.[1]",
                   },
                   {
                      ip   => "vm.[3].vnic.[1]",
                      mac  => "vm.[3].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire2VMsArpEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyArpEntryOnController[?]contain_once" => [
                   {
                      ip   => "vm.[4].vnic.[1]",
                      mac  => "vm.[4].vnic.[1]",
                   },
                   {
                      ip   => "vm.[5].vnic.[1]",
                      mac  => "vm.[5].vnic.[1]",
                   },
                   {
                      ip   => "vm.[6].vnic.[1]",
                      mac  => "vm.[6].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire3VMsArpEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyArpEntryOnController[?]contain_once" => [
                   {
                      ip   => "vm.[7].vnic.[1]",
                      mac  => "vm.[7].vnic.[1]",
                   },
                   {
                      ip   => "vm.[8].vnic.[1]",
                      mac  => "vm.[8].vnic.[1]",
                   },
                   {
                      ip   => "vm.[9].vnic.[1]",
                      mac  => "vm.[9].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire1VMsMacEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[1]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyMacEntryOnController[?]contain_once" => [
                   {
                      mac  => "vm.[1].vnic.[1]",
                   },
                   {
                      mac  => "vm.[2].vnic.[1]",
                   },
                   {
                      mac  => "vm.[3].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire2VMsMacEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyMacEntryOnController[?]contain_once" => [
                   {
                      mac  => "vm.[4].vnic.[1]",
                   },
                   {
                      mac  => "vm.[5].vnic.[1]",
                   },
                   {
                      mac  => "vm.[6].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire3VMsMacEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyMacEntryOnController[?]contain_once" => [
                   {
                      mac  => "vm.[7].vnic.[1]",
                   },
                   {
                      mac  => "vm.[8].vnic.[1]",
                   },
                   {
                      mac  => "vm.[9].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
             'SetVDS12vWire1MacAddressChangeSecurityPolicyAccept' => {
              'Type'           => 'Switch',
              'TestSwitch'     => 'vc.[1].vds.[1-2]',
              'virtualwire'    => "vsm.[1].networkscope.[1].virtualwire.[1]",
              'policytype'     => "macChanges",
              'securitypolicy' => 'Enable'
            },
            'SetVDS12vWire1ForgedTransmitChangeSecurityPolicyAccept' => {
              'Type'           => 'Switch',
              'TestSwitch'     => 'vc.[1].vds.[1-2]',
              'virtualwire'    => "vsm.[1].networkscope.[1].virtualwire.[1]",
              'policytype'     => "forgedTransmits",
              'securitypolicy' => 'Enable'
            },
            'SetVDS12vWire2MacAddressChangeSecurityPolicyAccept' => {
              'Type'           => 'Switch',
              'TestSwitch'     => 'vc.[1].vds.[1-2]',
              'virtualwire'    => "vsm.[1].networkscope.[1].virtualwire.[2]",
              'policytype'     => "macChanges",
              'securitypolicy' => 'Enable'
            },
            'SetVDS12vWire2ForgedTransmitChangeSecurityPolicyAccept' => {
              'Type'           => 'Switch',
              'TestSwitch'     => 'vc.[1].vds.[1-2]',
              'virtualwire'    => "vsm.[1].networkscope.[1].virtualwire.[2]",
              'policytype'     => "forgedTransmits",
              'securitypolicy' => 'Enable'
            },
            'SetVDS12vWire3MacAddressChangeSecurityPolicyAccept' => {
              'Type'           => 'Switch',
              'TestSwitch'     => 'vc.[1].vds.[1-2]',
              'virtualwire'    => "vsm.[1].networkscope.[1].virtualwire.[3]",
              'policytype'     => "macChanges",
              'securitypolicy' => 'Enable'
            },
            'SetVDS12vWire3ForgedTransmitChangeSecurityPolicyAccept' => {
              'Type'           => 'Switch',
              'TestSwitch'     => 'vc.[1].vds.[1-2]',
              'virtualwire'    => "vsm.[1].networkscope.[1].virtualwire.[3]",
              'policytype'     => "forgedTransmits",
              'securitypolicy' => 'Enable'
            },
            'ChangeVM1Vnic1IpAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_1,
               netmask        => "255.255.0.0",
            },
            'ChangeVM2Vnic1IpAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[2].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_2,
               netmask        => "255.255.0.0",
            },
            'ChangeVM3Vnic1IpAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[3].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_3,
               netmask        => "255.255.0.0",
            },
            'ChangeVM4Vnic1IpAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[4].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_4,
               netmask        => "255.255.0.0",
            },
            'ChangeVM5Vnic1IpAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[5].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_5,
               netmask        => "255.255.0.0",
            },
            'ChangeVM6Vnic1IpAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[6].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_1,
               netmask        => "255.255.0.0",
            },
            'ChangeVM7Vnic1IpAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[7].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_2,
               netmask        => "255.255.0.0",
            },
            'ChangeVM8Vnic1IpAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[8].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_3,
               netmask        => "255.255.0.0",
            },
            'ChangeVM9Vnic1IpAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[9].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_4,
               netmask        => "255.255.0.0",
            },
            'ChangeVM1Vnic1MacAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:11',
            },
            'ChangeVM2Vnic1MacAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[2].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:22',
            },
            'ChangeVM3Vnic1MacAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[3].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:33',
            },
            'ChangeVM4Vnic1MacAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[4].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:44',
            },
            'ChangeVM5Vnic1MacAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[5].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:55',
            },
            'ChangeVM6Vnic1MacAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[6].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:66',
            },
            'ChangeVM7Vnic1MacAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[7].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:77',
            },
            'ChangeVM8Vnic1MacAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[8].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:88',
            },
            'ChangeVM9Vnic1MacAddress' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[9].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:99',
            },
            "NetperfTestVirtualWire1Unicat" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
               TestDuration   => "5",
            },
            "NetperfTestVirtualWire2Unicat" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
               TestDuration   => "5",
            },
            "NetperfTestVirtualWire3Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
               TestDuration   => "5",
            },
            'ChangeVM4Vnic1IpAddressManyTimes' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[4].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_4,
               netmask        => "255.255.0.0",
               iterations     => "20",
               runworkload    => {
                                    Type           => "NetAdapter",
                                    TestAdapter    => "vm.[4].vnic.[1]",
                                    IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_5,
                                    netmask        => "255.255.0.0",
                                 },
            },
            'ChangeVM4Vnic1MacAddressManyTimes' => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[4].vnic.[1]",
               setmacaddr     => '00:11:22:33:44:44',
               iterations     => "20",
               runworkload    => {
                                    Type           => "NetAdapter",
                                    TestAdapter    => "vm.[4].vnic.[1]",
                                    setmacaddr     => '00:11:22:33:44:55',
                                 },
            },
         },
      },
      'StressVTEPIpChange' => {
         TestName         => 'StressVTEPIpChange',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'StressVTEPIpChange: To verify whether the controller' .
                             'updates all VTEPs instantaneously, when the ip address' .
                             'of the VTEP is changed continuously.',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automatic',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
              # step 1, check all the vtep table info
              #         learned correctly on controllers
                ['CreateVirtualWire'],
                ['PlaceVMsOnVirtualWire1'],
                ['PlaceVMsOnVirtualWire2'],
                ['PlaceVMsOnVirtualWire3'],
                ['PoweronVM1','PoweronVM2','PoweronVM3'],
                ['PoweronVM4','PoweronVM5','PoweronVM6'],
                ['PoweronVM7','PoweronVM8','PoweronVM9'],
                ['VerifyVirtualWire2VtepTableOnControllers'],
                ['VerifyVirtualWire3VtepTableOnControllers'],
                ['NetperfTestVirtualWire1Unicat'],
                ['NetperfTestVirtualWire2Unicat'],
                ['NetperfTestVirtualWire3Unicat'],

              # step 2, change vmkic ip address of vtep 2
              #         and check the vtep table
                ['ChangeVtep2StaticIpAddress'],
                ['VerifyVirtualWire2VtepTableOnControllers'],
                ['VerifyVirtualWire3VtepTableOnControllers'],
                ['NetperfTestVirtualWire1Unicat'],
                ['NetperfTestVirtualWire2Unicat'],
                ['NetperfTestVirtualWire3Unicat'],

              # step 3, change vmkic ip address of vtep 3
              #         and check the vtep table
                ['ChangeVtep3StaticIpAddress'],
                ['VerifyVirtualWire2VtepTableOnControllers'],
                ['VerifyVirtualWire3VtepTableOnControllers'],
                ['NetperfTestVirtualWire1Unicat'],
                ['NetperfTestVirtualWire2Unicat'],
                ['NetperfTestVirtualWire3Unicat'],

              # step 4, change vmkic ip address of vtep 4
              #         and check the vtep table
                ['ChangeVtep4StaticIpAddress'],
                ['VerifyVirtualWire2VtepTableOnControllers'],
                ['VerifyVirtualWire3VtepTableOnControllers'],
                ['NetperfTestVirtualWire1Unicat'],
                ['NetperfTestVirtualWire2Unicat'],
                ['NetperfTestVirtualWire3Unicat'],

              # step 5, change vmknic ip address of vtep 2
              #         for many times
                ['ChangeVtep2StaticIpAddressManyTimes'],
                ['VerifyVirtualWire3VtepTableOnControllers'],
                ['NetperfTestVirtualWire1Unicat'],
                ['NetperfTestVirtualWire2Unicat'],
                ['NetperfTestVirtualWire3Unicat'],

              # step 6, change vtep23 ip address back to dhcp mode
                ['ChangeVtep2DhcpIpAddress'],
                ['ChangeVtep3DhcpIpAddress'],
                ['ChangeVtep4DhcpIpAddress'],
                ['VerifyVirtualWire2VtepTableOnControllers'],
                ['VerifyVirtualWire3VtepTableOnControllers'],
                ['NetperfTestVirtualWire1Unicat'],
                ['NetperfTestVirtualWire2Unicat'],
                ['NetperfTestVirtualWire3Unicat'],

            ],
            ExitSequence => [
                ['PoweroffVM'],
                ['DeleteVM1Vnic1'],
                ['DeleteVM2Vnic1'],
                ['DeleteVM3Vnic1'],
                ['DeleteVM4Vnic1'],
                ['DeleteVM5Vnic1'],
                ['DeleteVM6Vnic1'],
                ['DeleteVM7Vnic1'],
                ['DeleteVM8Vnic1'],
                ['DeleteVM9Vnic1'],
                ['DeleteAllVirtualWires'],
            ],
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'DeleteVM3Vnic1' => DELETE_VM3_VNIC1,
            'DeleteVM4Vnic1' => DELETE_VM4_VNIC1,
            'DeleteVM5Vnic1' => DELETE_VM5_VNIC1,
            'DeleteVM6Vnic1' => DELETE_VM6_VNIC1,
            'DeleteVM7Vnic1' => DELETE_VM7_VNIC1,
            'DeleteVM8Vnic1' => DELETE_VM8_VNIC1,
            'DeleteVM9Vnic1' => DELETE_VM9_VNIC1,

            'CreateVirtualWire' => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-3]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire2' => {
               Type => "VM",
               TestVM => "vm.[4-6]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-9],",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[3]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM6' => POWERON_VM6,
            'PoweronVM7' => POWERON_VM7,
            'PoweronVM8' => POWERON_VM8,
            'PoweronVM9' => POWERON_VM9,

            'VerifyVirtualWire2VtepTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyVtepTableOnController[?]contain_once" => [
                   {
                      vtepip  => "host.[2]",
                      cluster => "vc.[1].datacenter.[1].cluster.[2]",
                   },
                   {
                      vtepip  => "host.[3]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
                   {
                      vtepip  => "host.[4]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
               ],
               noofretries  => "5",
            },
            'VerifyVirtualWire3VtepTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyVtepTableOnController[?]contain_once" => [
                   {
                      vtepip  => "host.[2]",
                      cluster => "vc.[1].datacenter.[1].cluster.[2]",
                   },
                   {
                      vtepip  => "host.[3]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
                   {
                      vtepip  => "host.[4]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
               ],
               noofretries  => "5",
            },

            "NetperfTestVirtualWire1Unicat" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
               TestDuration   => "15",
            },
            "NetperfTestVirtualWire2Unicat" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
               TestDuration   => "15",
            },
            "NetperfTestVirtualWire3Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
               TestDuration   => "15",
            },
            'ChangeVtep2StaticIpAddress' => {
               Type           => "Switch",
               testswitch     => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host           => "host.[2]",
               cluster        => "vc.[1].datacenter.[1].cluster.[2]",
               ipv4           => "static",
               ipv4address    => VDNetLib::TestData::TestConstants::VXLAN_VTEP_STATIC_IP_1,
               netmask        => "255.255.0.0",
            },
            'ChangeVtep3StaticIpAddress' => {
               Type           => "Switch",
               testswitch     => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host           => "host.[3]",
               cluster        => "vc.[1].datacenter.[1].cluster.[3]",
               ipv4           => "static",
               ipv4address    => VDNetLib::TestData::TestConstants::VXLAN_VTEP_STATIC_IP_C1,
               netmask        => "255.255.0.0",
            },
            'ChangeVtep4StaticIpAddress' => {
               Type           => "Switch",
               testswitch     => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host           => "host.[4]",
               cluster        => "vc.[1].datacenter.[1].cluster.[3]",
               ipv4           => "static",
               ipv4address    => VDNetLib::TestData::TestConstants::VXLAN_VTEP_STATIC_IP_C2,
               netmask        => "255.255.0.0",
            },
            'ChangeVtep2DhcpIpAddress' => {
               Type           => "Switch",
               testswitch     => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host           => "host.[2]",
               cluster        => "vc.[1].datacenter.[1].cluster.[2]",
               ipv4           => "dhcp",
            },
            'ChangeVtep3DhcpIpAddress' => {
               Type           => "Switch",
               testswitch     => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host           => "host.[3]",
               cluster        => "vc.[1].datacenter.[1].cluster.[3]",
               ipv4           => "dhcp",
            },
            'ChangeVtep4DhcpIpAddress' => {
               Type           => "Switch",
               testswitch     => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host           => "host.[4]",
               cluster        => "vc.[1].datacenter.[1].cluster.[3]",
               ipv4           => "dhcp",
            },
            'ChangeVtep2StaticIpAddressManyTimes' => {
               Type           => "Switch",
               testswitch     => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host           => "host.[2]",
               cluster        => "vc.[1].datacenter.[1].cluster.[2]",
               ipv4           => "static",
               ipv4address    => VDNetLib::TestData::TestConstants::VXLAN_VTEP_STATIC_IP_2,
               netmask        => "255.255.0.0",
               iterations     => "20",
               runworkload    => {
                                    Type           => "Switch",
                                    testswitch     => "vsm.[1].networkscope.[1].virtualwire.[2]",
                                    host           => "host.[2]",
                                    cluster        => "vc.[1].datacenter.[1].cluster.[2]",
                                    ipv4           => "static",
                                    ipv4address    => VDNetLib::TestData::TestConstants::VXLAN_VTEP_STATIC_IP_1,
                                    netmask        => "255.255.0.0",
                                    sleepbetweenworkloads => "30",
                                    runworkload    => {
                                                         Type         => "Switch",
                                                         testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                                                         controllers  => "vsm.[1].vxlancontroller.[-1]",
                                                         "VerifyVtepTableOnController[?]contain_once" => [
                                                             {
                                                                vtepip  => "host.[2]",
                                                                cluster => "vc.[1].datacenter.[1].cluster.[2]",
                                                             },
                                                             {
                                                                vtepip  => "host.[3]",
                                                                cluster => "vc.[1].datacenter.[1].cluster.[3]",
                                                             },
                                                             {
                                                                vtepip  => "host.[4]",
                                                                cluster => "vc.[1].datacenter.[1].cluster.[3]",
                                                             },
                                                         ],
                                                         noofretries  => "5",
                                                      },
                                 },
            },
         },
      },
      'Vdl2IPCacheUpdateFail' => {
         TestName         => 'Vdl2IPCacheUpdateFail',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To test the stress option: Vdl2IPCacheUpdateFail'.
                             'which will be triggered when VM IP address' .
                             'updates event is happened',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,beta',
         PMT              => '5511',
         AutomationLevel  => 'Automatic',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire2'],
               ['PlaceVMsOnVirtualWire3'],
               ['PoweronVM1','PoweronVM2','PoweronVM3'],
               ['SetVDS12MacAddressChangeSecurityPolicyAccept2'],
               ['SetVDS12ForgedTransmitChangeSecurityPolicyAccept2'],
               ['SetVdl2IPCacheUpdateFailOptionTo20'],
               ['SetIVM1Vnic1IP','SetIVM2Vnic1IP'],
               ['IperfTestVirtualWire2Unicat'],
               ['ArpPingVM1_Igore','SetIVM1Vnic1IP_Stress'],
               ['SetVdl2IPCacheUpdateFailOptionTo50'],
               ['ArpPingVM1_Igore','SetIVM1Vnic1IP_Stress'],
               #verify ARP/MAC/VTEP/Connection table on all controllers
               ['ArpPingVM1','ArpPingVM2'],
               ['VerifyVirtualWire2VMsArpEntryOnControllers',
                'VerifyVirtualWire2VMsMacEntryOnControllers'],
               ['VerifyVirtualWireVtepTableOnControllers',
                'VerifyVirtualWireConnectionTableOnControllers'],
               #verify ARP/MAC/VTEP/Connection table on all hosts
               ['ClearArpEntryForVirtualWire2OnAllHosts'],
               ['ArpPingVM12_FAIL'],
               ['ArpPingVM1','ArpPingVM2'],
               ['CheckVirtualWire2ArpEntryOnHost2',
                'CheckVirtualWire2ArpEntryOnHost3'],
               ['CheckVirtualWire2MacEntryOnHost2',
                'CheckVirtualWire2MacEntryOnHost3'],
               ['CheckVirtualWire2ControllerInfo'],
               ['CheckVirtualWire2MTEPOnAllHost'],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM1Vnic1'],
               ['DeleteVM2Vnic1'],
               ['DeleteVM3Vnic1'],
               ['DeleteAllVirtualWires'],
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'DeleteVM3Vnic1' => DELETE_VM3_VNIC1,
            'CreateVirtualWire'     => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'SetIVM1Vnic1IP_Stress' => {
               Type        => "NetAdapter",
               TestAdapter => "vm.[1].vnic.[1]",
               Iterations  => 60,
               maxtimeout  => "7200",
               IPv4        => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_1,
               netmask     => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
               runworkload => "SetIVM1Vnic1IP",
            },
            "SetIVM1Vnic1IP" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[1].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_3,
               netmask        => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
               sleepbetweenworkloads => '3',
            },
            "SetIVM2Vnic1IP" => {
               Type           => "NetAdapter",
               TestAdapter    => "vm.[2].vnic.[1]",
               IPv4           => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_2,
               netmask        => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
            },
            'PlaceVMsOnVirtualWire2' => {
               Type => "VM",
               TestVM => "vm.[1-2]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[3]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[3]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            "SetVdl2IPCacheUpdateFailOptionTo20" => {
               Type           => "Host",
               TestHost       => "host.[2-3]",
               Stress         => "Enable",
               stressoptions  => "{Vdl2IPCacheUpdateFail => 20}",
            },
            "SetVdl2IPCacheUpdateFailOptionTo50" => {
               Type           => "Host",
               TestHost       => "host.[2-3]",
               Stress         => "Enable",
               stressoptions  => "{Vdl2IPCacheUpdateFail => 50}",
            },
            'SetVDS12MacAddressChangeSecurityPolicyAccept2' => {
              'Type'           => 'Switch',
              'TestSwitch'     => 'vc.[1].vds.[1-2]',
              'virtualwire'    => "vsm.[1].networkscope.[1].virtualwire.[2]",
              'policytype'     => "macChanges",
              'securitypolicy' => 'Enable'
            },
            'SetVDS12ForgedTransmitChangeSecurityPolicyAccept2' => {
              'Type'           => 'Switch',
              'TestSwitch'     => 'vc.[1].vds.[1-2]',
              'virtualwire'    => "vsm.[1].networkscope.[1].virtualwire.[2]",
              'policytype'     => "forgedTransmits",
              'securitypolicy' => 'Enable'
            },
            "ArpPingVM1" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[1].vnic.[1]",
               SupportAdapter   => "vm.[2].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM2" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[2].vnic.[1]",
               SupportAdapter   => "vm.[1].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM1_Igore" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               Iterations       => 150,
               TestAdapter      => "vm.[1].vnic.[1]",
               SupportAdapter   => "vm.[2].vnic.[1]",
               TestDuration     => "2",
               ExpectedResult   => "Ignore",
               connectivitytest => "0",
            },
            "ArpPingVM12_FAIL" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[1-2].vnic.[1]",
               SupportAdapter   => "vm.[3].vnic.[1]",
               TestDuration     => "10",
               ExpectedResult   => "Fail",
               connectivitytest => "0",
            },
            'VerifyVirtualWire2VMsArpEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyArpEntryOnController[?]contain_once" => [
                   {
                      ip   => "vm.[1].vnic.[1]",
                      mac  => "vm.[1].vnic.[1]",
                   },
                   {
                      ip   => "vm.[2].vnic.[1]",
                      mac  => "vm.[2].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire2VMsMacEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyMacEntryOnController[?]contain_once" => [
                   {
                      mac  => "vm.[1].vnic.[1]",
                   },
                   {
                      mac  => "vm.[2].vnic.[1]",
                   },
               ],
            },
            'VerifyVirtualWireVtepTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyVtepTableOnController[?]contain_once" => [
                   {
                      vtepip  => "host.[2]",
                      cluster => "vc.[1].datacenter.[1].cluster.[2]",
                   },
                   {
                      vtepip  => "host.[3]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
               ],
               noofretries  => "5",
            },
            'VerifyVirtualWireConnectionTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyConnectionTableOnController[?]contains" => [
                   {
                      hostip  => "host.[2]",
                   },
                   {
                      hostip  => "host.[3]",
                   },
               ],
            },
            "IperfTestVirtualWire2Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "30",
            },
            'CheckVirtualWire2ControllerInfo' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllerstatusonhosts => 'up',
               hosts           => 'host.[2-3]',
               noofretries     => "10",
            },
            'CheckVirtualWire2MTEPOnAllHost' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[2]",
               checkmteponhost => 'host.[2-3]',
            },
            'CheckVirtualWire2ArpEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[2]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[2].vnic.[1]",
                     mac  => "vm.[2].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2ArpEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[3]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[1].vnic.[1]",
                     mac  => "vm.[1].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2MacEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[2]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[2].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2MacEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[3]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[1].vnic.[1]",
                  },
               ],
            },
            'ClearArpEntryForVirtualWire2OnAllHosts' => {
               Type       => "Switch",
               testswitch => "vsm.[1].networkscope.[1].virtualwire.[2]",
               clearvwireentryonhost => 'arp',
               hosts      => 'host.[2-3]',
            },
         },
      },
      'Vdl2PktNotWritable' => {
         TestName         => 'Vdl2PktNotWritable',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To test the stress option: Vdl2PktNotWritable'.
                             'which will be triggered when there is any VM' .
                             'traffic configured with VNI needs to be sent out',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,beta',
         PMT              => '5511',
         AutomationLevel  => 'Automatic',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire2'],
               ['PlaceVMsOnVirtualWire3'],
               ['PoweronVM4','PoweronVM5','PoweronVM7','PoweronVM8'],
               ['SetVdl2PktNotWritableOptionTo20'],
               ['Stress_IperfTestVirtualWire2Unicat'],
               ['Stress_IperfTestVirtualWire3Unicat'],
               ['SetVdl2PktNotWritableOptionTo100'],
               ['Stress_IperfTestVirtualWire2Unicat'],
               ['Stress_IperfTestVirtualWire3Unicat'],
               #verify ARP/MAC/VTEP/Connection table on all controllers
               ['ArpPingVM4','ArpPingVM5'],
               ['VerifyVirtualWire2VMsArpEntryOnControllers',
                'VerifyVirtualWire2VMsMacEntryOnControllers'],
               ['ArpPingVM7','ArpPingVM8'],
               ['VerifyVirtualWire3VMsArpEntryOnControllers',
                'VerifyVirtualWire3VMsMacEntryOnControllers'],
               ['VerifyVirtualWireVtepTableOnControllers',
                'VerifyVirtualWireConnectionTableOnControllers'],
               #verify ARP/MAC/VTEP/Connection table on all hosts
               ['ClearArpEntryForVirtualWire2OnAllHosts'],
               ['ArpPingVM45_FAIL'],
               ['ArpPingVM4','ArpPingVM5'],
               ['CheckVirtualWire2ArpEntryOnHost2',
                'CheckVirtualWire2ArpEntryOnHost3'],
               ['CheckVirtualWire2MacEntryOnHost2',
                'CheckVirtualWire2MacEntryOnHost3'],
               ['CheckVirtualWire2ControllerInfo'],
               ['CheckVirtualWire2MTEPOnAllHost'],
               ['ClearArpEntryForVirtualWire3OnAllHosts'],
               ['ArpPingVM78_FAIL'],
               ['ArpPingVM7','ArpPingVM8'],
               ['CheckVirtualWire3ArpEntryOnHost2',
                'CheckVirtualWire3ArpEntryOnHost3'],
               ['CheckVirtualWire3MacEntryOnHost2',
                'CheckVirtualWire3MacEntryOnHost3'],
               ['CheckVirtualWire3ControllerInfo'],
               ['CheckVirtualWire3MTEPOnAllHost'],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM4Vnic1'],
               ['DeleteVM5Vnic1'],
               ['DeleteVM7Vnic1'],
               ['DeleteVM8Vnic1'],
               ['DeleteAllVirtualWires'],
            ],
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM7' => POWERON_VM7,
            'PoweronVM8' => POWERON_VM8,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM4Vnic1' => DELETE_VM4_VNIC1,
            'DeleteVM5Vnic1' => DELETE_VM5_VNIC1,
            'DeleteVM7Vnic1' => DELETE_VM7_VNIC1,
            'DeleteVM8Vnic1' => DELETE_VM8_VNIC1,
            'CreateVirtualWire'     => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PlaceVMsOnVirtualWire2' => {
               Type => "VM",
               TestVM => "vm.[4-5]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-8]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[3]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            "SetVdl2PktNotWritableOptionTo100" => {
               Type           => "Host",
               TestHost       => "host.[2-3]",
               Stress         => "Enable",
               stressoptions  => "{Vdl2PktNotWritable => 100}",
            },
            "SetVdl2PktNotWritableOptionTo20" => {
               Type           => "Host",
               TestHost       => "host.[2-3]",
               Stress         => "Enable",
               stressoptions  => "{Vdl2PktNotWritable => 20}",
            },
            "ArpPingVM4" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[4].vnic.[1]",
               SupportAdapter   => "vm.[5].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM5" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[5].vnic.[1]",
               SupportAdapter   => "vm.[4].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM7" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[7].vnic.[1]",
               SupportAdapter   => "vm.[8].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM8" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[8].vnic.[1]",
               SupportAdapter   => "vm.[7].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM45_FAIL" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[4-5].vnic.[1]",
               SupportAdapter   => "vm.[7].vnic.[1]",
               TestDuration     => "10",
               ExpectedResult   => "Fail",
               connectivitytest => "0",
            },
            "ArpPingVM78_FAIL" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[7-8].vnic.[1]",
               SupportAdapter   => "vm.[4].vnic.[1]",
               TestDuration     => "10",
               ExpectedResult   => "Fail",
               connectivitytest => "0",
            },
            'VerifyVirtualWire2VMsArpEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyArpEntryOnController[?]contain_once" => [
                   {
                      ip   => "vm.[4].vnic.[1]",
                      mac  => "vm.[4].vnic.[1]",
                   },
                   {
                      ip   => "vm.[5].vnic.[1]",
                      mac  => "vm.[5].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire2VMsMacEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyMacEntryOnController[?]contain_once" => [
                   {
                      mac  => "vm.[4].vnic.[1]",
                   },
                   {
                      mac  => "vm.[5].vnic.[1]",
                   },
               ],
            },
            'VerifyVirtualWire3VMsArpEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyArpEntryOnController[?]contain_once" => [
                   {
                      ip   => "vm.[7].vnic.[1]",
                      mac  => "vm.[7].vnic.[1]",
                   },
                   {
                      ip   => "vm.[8].vnic.[1]",
                      mac  => "vm.[8].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire3VMsMacEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyMacEntryOnController[?]contain_once" => [
                   {
                      mac  => "vm.[7].vnic.[1]",
                   },
                   {
                      mac  => "vm.[8].vnic.[1]",
                   },
               ],
            },
            'VerifyVirtualWireVtepTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2-3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyVtepTableOnController[?]contain_once" => [
                   {
                      vtepip  => "host.[2]",
                      cluster => "vc.[1].datacenter.[1].cluster.[2]",
                   },
                   {
                      vtepip  => "host.[3]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
               ],
               noofretries  => "5",
            },
            'VerifyVirtualWireConnectionTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2-3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyConnectionTableOnController[?]contains" => [
                   {
                      hostip  => "host.[2]",
                   },
                   {
                      hostip  => "host.[3]",
                   },
               ],
            },
            "Stress_IperfTestVirtualWire2Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5].vnic.[1]",
               TestDuration   => "1200",
            },
            "Stress_IperfTestVirtualWire3Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8].vnic.[1]",
               TestDuration   => "1200",
            },
            'CheckVirtualWire2ArpEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[2]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[5].vnic.[1]",
                     mac  => "vm.[5].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2ArpEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[3]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[4].vnic.[1]",
                     mac  => "vm.[4].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2MacEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[2]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[5].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2MacEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[3]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[4].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2ControllerInfo' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllerstatusonhosts => 'up',
               hosts           => 'host.[2-3]',
               noofretries     => "10",
            },
            'CheckVirtualWire2MTEPOnAllHost' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[2]",
               checkmteponhost => 'host.[2-3]',
            },
            'ClearArpEntryForVirtualWire2OnAllHosts' => {
               Type       => "Switch",
               testswitch => "vsm.[1].networkscope.[1].virtualwire.[2]",
               clearvwireentryonhost => 'arp',
               hosts      => 'host.[2-3]',
            },
            'ClearArpEntryForVirtualWire3OnAllHosts' => {
               Type       => "Switch",
               testswitch => "vsm.[1].networkscope.[1].virtualwire.[3]",
               clearvwireentryonhost => 'arp',
               hosts      => 'host.[2-3]',
            },
            'CheckVirtualWire3ArpEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               host         => 'host.[2]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[8].vnic.[1]",
                     mac  => "vm.[8].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire3ArpEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               host         => 'host.[3]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[7].vnic.[1]",
                     mac  => "vm.[7].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire3MacEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               host         => 'host.[2]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[8].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire3MacEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               host         => 'host.[3]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[7].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire3ControllerInfo' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllerstatusonhosts => 'up',
               hosts           => 'host.[2-3]',
               noofretries     => "10",
            },
            'CheckVirtualWire3MTEPOnAllHost' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[3]",
               checkmteponhost => 'host.[2-3]',
            },
         },
      },
      'StressPortUpDown' => {
         TestName         => 'StressPortUpDown',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'StressPortUpDown: To verify the functionality when' .
                             'the uplink port of VTEPs and the controller is ' .
                             'brought up and down multiple times. ',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automatic',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [

              # step 1, check all the virtual wires and verify virtual wires
              #         exist on controllers and hosts
                  ['CreateVirtualWire'],
                  ['PlaceVMsOnVirtualWire1'],
                  ['PlaceVMsOnVirtualWire2'],
                  ['PlaceVMsOnVirtualWire3'],
                  ['PoweronVM1','PoweronVM2','PoweronVM3'],
                  ['PoweronVM4','PoweronVM5','PoweronVM6'],
                  ['PoweronVM7','PoweronVM8','PoweronVM9'],
                  ['NetperfTestVirtualWire1Unicat'],
                  ['NetperfTestVirtualWire2Unicat'],
                  ['NetperfTestVirtualWire3Unicat'],

              # step 2, up/down esx uplinks ports many times and verify traffic
                  ['UpDownUplinkPortsManyTimes'],
                  ['NetperfTestVirtualWire1Unicat'],
                  ['NetperfTestVirtualWire2Unicat'],
                  ['NetperfTestVirtualWire3Unicat'],

              # step 3, block/unbolck the connection between
              #         Esx and Controllers many times and verify traffic
                  ['EnableFirewallOnHosts'],
                  ['ReconfigureConnectionBetweenControllerAndEsx'],
                  ['NetperfTestVirtualWire1Unicat'],
                  ['NetperfTestVirtualWire2Unicat'],
                  ['NetperfTestVirtualWire3Unicat'],

              # step 4, shutdown/up the pswitch port which connect to controller host
                  ['Initpswitchport'],
                  ['DisableEnablePortManyTimes'],
                  ['NetperfTestVirtualWire1Unicat'],
                  ['NetperfTestVirtualWire2Unicat'],
                  ['NetperfTestVirtualWire3Unicat'],
            ],
            ExitSequence => [
                  ['UpUplinkPorts'],
                  ['NetCPAllowAllIP'],
                  ['DisableFirewallOnHosts'],
                  ['PoweroffVM'],
                  ['DeleteVM1Vnic1'],
                  ['DeleteVM2Vnic1'],
                  ['DeleteVM3Vnic1'],
                  ['DeleteVM4Vnic1'],
                  ['DeleteVM5Vnic1'],
                  ['DeleteVM6Vnic1'],
                  ['DeleteVM7Vnic1'],
                  ['DeleteVM8Vnic1'],
                  ['DeleteVM9Vnic1'],
                  ['DeleteAllVirtualWires'],
            ],
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'DeleteVM3Vnic1' => DELETE_VM3_VNIC1,
            'DeleteVM4Vnic1' => DELETE_VM4_VNIC1,
            'DeleteVM5Vnic1' => DELETE_VM5_VNIC1,
            'DeleteVM6Vnic1' => DELETE_VM6_VNIC1,
            'DeleteVM7Vnic1' => DELETE_VM7_VNIC1,
            'DeleteVM8Vnic1' => DELETE_VM8_VNIC1,
            'DeleteVM9Vnic1' => DELETE_VM9_VNIC1,

            'CreateVirtualWire' => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-3]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire2' => {
               Type => "VM",
               TestVM => "vm.[4-6]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-9],",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[3]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM6' => POWERON_VM6,
            'PoweronVM7' => POWERON_VM7,
            'PoweronVM8' => POWERON_VM8,
            'PoweronVM9' => POWERON_VM9,

            "NetperfTestVirtualWire1Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               L3Protocol     => "ipv4",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire2Unicat" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               L3Protocol     => "ipv4",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire3Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               L3Protocol     => "ipv4",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
               TestDuration   => "30",
            },
            'UpDownUplinkPortsManyTimes' => {
               Type         => 'NetAdapter',
               TestAdapter  => 'host.[2-4].vmnic.[1]',
               devicestatus => 'DOWN',
               iterations   => '20',
               runworkload  => {
                                 Type         => 'NetAdapter',
                                 TestAdapter  => 'host.[2-4].vmnic.[1]',
                                 devicestatus => 'UP',
                                 sleepbetweenworkloads => '10',
                              },
            },
            'UpUplinkPorts' => {
                Type         => 'NetAdapter',
                TestAdapter  => 'host.[2-4].vmnic.[1]',
                devicestatus => 'UP',
            },
            'EnableFirewallOnHosts' => {
               Type           => 'Host',
               TestHost       => 'host.[2-4]',
               reconfigurefirewall => 'true',
               ruleset        => 'netCP',
            },
            'DisableFirewallOnHosts' => {
               Type           => 'Host',
               TestHost       => 'host.[2-4]',
               reconfigurefirewall => 'false',
               ruleset        => 'netCP',
            },
            'ReconfigureConnectionBetweenControllerAndEsx' => {
               Type           => 'Host',
               TestHost       => 'host.[2-4]',
               Firewall       => "setallowedall",
               Servicename    => "netCP",
               Flag           => "false",
               iterations     => '20',
               runworkload => {
                                 Type        => 'Host',
                                 TestHost    => 'host.[2-4]',
                                 Firewall    => "setallowedall",
                                 Servicename => "netCP",
                                 Flag        => "true",
                                 sleepbetweenworkloads => '3',
                              },
            },
            'NetCPAllowAllIP' => {
               Type           => 'Host',
               TestHost       => 'host.[2-4]',
               Firewall       => "setallowedall",
               Servicename    => "netCP",
               Flag           => "true",
            },
            'Initpswitchport' => {
               Type  => "Host",
               TestHost => "host.[1]",
               pswitchport => {
                  '[0]' => {
                     vmnic => "host.[1].vmnic.[0]",
                  },
               },
            },
            "DisableEnablePortManyTimes" => {
               Type         => "Port",
               TestPort     => "host.[1].pswitchport.[0]",
               portstatus   => "disable",
               iterations   => "20",
               runworkload  => "EnablePort",
            },
            "EnablePort" => {
               Type         => "Port",
               TestPort     => "host.[1].pswitchport.[0]",
               portstatus   => "enable",
               sleepbetweenworkloads => '5',
            },
         },
      },
      'Vdl2CPWorldTaskPostFailAndCPUpdateFail' => {
         TestName         => 'Vdl2CPWorldTaskPostFailAndCPUpdateFail',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To test tep stress options below: '.
                             '1)Vdl2CPUpdateFail: which force control '.
                             '  plane update to fail'.
                             '2)Vdl2CPWorldTaskPostFail: which force control '.
                             '  plane world failing to post task',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,beta',
         PMT              => '5511',
         AutomationLevel  => 'Automatic',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire2'],
               ['PlaceVMsOnVirtualWire3'],
               ['PoweronVM4','PoweronVM5','PoweronVM7','PoweronVM8'],
               ['SetVdl2CPWorldTaskPostFailTo20'],
               ['SetVdl2CPUpdateFailTo20'],
               ['IperfTestVirtualWire2Unicat'],
               ['IperfTestVirtualWire3Unicat'],
               ['Stress_restartNetcpaOnAllHosts'],
               ['SetVdl2CPWorldTaskPostFailTo100'],
               ['SetVdl2CPUpdateFailTo100'],
               ['Stress_restartNetcpaOnAllHosts'],
               ['IperfTestVirtualWire2Unicat'],
               ['IperfTestVirtualWire3Unicat'],
               #verify ARP/MAC/VTEP/Connection table on all controllers
               ['ArpPingVM4','ArpPingVM5'],
               ['VerifyVirtualWire2VMsArpEntryOnControllers',
                'VerifyVirtualWire2VMsMacEntryOnControllers'],
               ['ArpPingVM7','ArpPingVM8'],
               ['VerifyVirtualWire3VMsArpEntryOnControllers',
                'VerifyVirtualWire3VMsMacEntryOnControllers'],
               ['VerifyVirtualWireVtepTableOnControllers',
                'VerifyVirtualWireConnectionTableOnControllers'],
               #verify ARP/MAC/VTEP/Connection table on all hosts
               ['ClearArpEntryForVirtualWire2OnAllHosts'],
               ['ArpPingVM45_FAIL'],
               ['ArpPingVM4','ArpPingVM5'],
               ['CheckVirtualWire2ArpEntryOnHost2',
                'CheckVirtualWire2ArpEntryOnHost3'],
               ['CheckVirtualWire2MacEntryOnHost2',
                'CheckVirtualWire2MacEntryOnHost3'],
               ['CheckVirtualWire2ControllerInfo'],
               ['CheckVirtualWire2MTEPOnAllHost'],
               ['ClearArpEntryForVirtualWire3OnAllHosts'],
               ['ArpPingVM78_FAIL'],
               ['ArpPingVM7','ArpPingVM8'],
               ['CheckVirtualWire3ArpEntryOnHost2',
                'CheckVirtualWire3ArpEntryOnHost3'],
               ['CheckVirtualWire3MacEntryOnHost2',
                'CheckVirtualWire3MacEntryOnHost3'],
               ['CheckVirtualWire3ControllerInfo'],
               ['CheckVirtualWire3MTEPOnAllHost'],
            ],
            ExitSequence => [
               ['PoweroffVM'],
               ['DeleteVM4Vnic1'],
               ['DeleteVM5Vnic1'],
               ['DeleteVM7Vnic1'],
               ['DeleteVM8Vnic1'],
               ['DeleteAllVirtualWires'],
            ],
            'PoweronVM4' => POWERON_VM4,
            'PoweronVM5' => POWERON_VM5,
            'PoweronVM7' => POWERON_VM7,
            'PoweronVM8' => POWERON_VM8,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM4Vnic1' => DELETE_VM4_VNIC1,
            'DeleteVM5Vnic1' => DELETE_VM5_VNIC1,
            'DeleteVM7Vnic1' => DELETE_VM7_VNIC1,
            'DeleteVM8Vnic1' => DELETE_VM8_VNIC1,
            'CreateVirtualWire'     => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PlaceVMsOnVirtualWire2' => {
               Type => "VM",
               TestVM => "vm.[4-5]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-8]",
               vnic => {
                  '[1]'   => {
                     driver     => "e1000",
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[3]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            "Stress_restartNetcpaOnAllHosts" => {
               Type           => "Host",
               TestHost       => "host.[2-3]",
               service        => "restart",
               name           => "netcpad",
               Iterations     => 120,
            },
            "SetVdl2CPWorldTaskPostFailTo100" => {
               Type           => "Host",
               TestHost       => "host.[2-3]",
               Stress         => "Enable",
               stressoptions  => "{Vdl2CPWorldTaskPostFail => 100}",
            },
            "SetVdl2CPWorldTaskPostFailTo20" => {
               Type           => "Host",
               TestHost       => "host.[2-3]",
               Stress         => "Enable",
               stressoptions  => "{Vdl2CPWorldTaskPostFail => 20}",
            },
            "SetVdl2CPUpdateFailTo100" => {
               Type           => "Host",
               TestHost       => "host.[2-3]",
               Stress         => "Enable",
               stressoptions  => "{Vdl2CPUpdateFail => 100}",
            },
            "SetVdl2CPUpdateFailTo20" => {
               Type           => "Host",
               TestHost       => "host.[2-3]",
               Stress         => "Enable",
               stressoptions  => "{Vdl2CPUpdateFail => 20}",
            },
            "ArpPingVM4" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[4].vnic.[1]",
               SupportAdapter   => "vm.[5].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM5" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[5].vnic.[1]",
               SupportAdapter   => "vm.[4].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM7" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[7].vnic.[1]",
               SupportAdapter   => "vm.[8].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM8" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[8].vnic.[1]",
               SupportAdapter   => "vm.[7].vnic.[1]",
               TestDuration     => "10",
               connectivitytest => "0",
            },
            "ArpPingVM45_FAIL" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[4-5].vnic.[1]",
               SupportAdapter   => "vm.[7].vnic.[1]",
               TestDuration     => "10",
               ExpectedResult   => "Fail",
               connectivitytest => "0",
            },
            "ArpPingVM78_FAIL" => {
               Type             => "Traffic",
               toolName         => "ArpPing",
               TestAdapter      => "vm.[7-8].vnic.[1]",
               SupportAdapter   => "vm.[4].vnic.[1]",
               TestDuration     => "10",
               ExpectedResult   => "Fail",
               connectivitytest => "0",
            },
            'VerifyVirtualWire2VMsArpEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyArpEntryOnController[?]contain_once" => [
                   {
                      ip   => "vm.[4].vnic.[1]",
                      mac  => "vm.[4].vnic.[1]",
                   },
                   {
                      ip   => "vm.[5].vnic.[1]",
                      mac  => "vm.[5].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire2VMsMacEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyMacEntryOnController[?]contain_once" => [
                   {
                      mac  => "vm.[4].vnic.[1]",
                   },
                   {
                      mac  => "vm.[5].vnic.[1]",
                   },
               ],
            },
            'VerifyVirtualWire3VMsArpEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyArpEntryOnController[?]contain_once" => [
                   {
                      ip   => "vm.[7].vnic.[1]",
                      mac  => "vm.[7].vnic.[1]",
                   },
                   {
                      ip   => "vm.[8].vnic.[1]",
                      mac  => "vm.[8].vnic.[1]",
                   },
               ],
               noofretries  => "3",
            },
            'VerifyVirtualWire3VMsMacEntryOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyMacEntryOnController[?]contain_once" => [
                   {
                      mac  => "vm.[7].vnic.[1]",
                   },
                   {
                      mac  => "vm.[8].vnic.[1]",
                   },
               ],
            },
            'VerifyVirtualWireVtepTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2-3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyVtepTableOnController[?]contain_once" => [
                   {
                      vtepip  => "host.[2]",
                      cluster => "vc.[1].datacenter.[1].cluster.[2]",
                   },
                   {
                      vtepip  => "host.[3]",
                      cluster => "vc.[1].datacenter.[1].cluster.[3]",
                   },
               ],
               noofretries  => "5",
            },
            'VerifyVirtualWireConnectionTableOnControllers' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2-3]",
               controllers  => "vsm.[1].vxlancontroller.[-1]",
               "VerifyConnectionTableOnController[?]contains" => [
                   {
                      hostip  => "host.[2]",
                   },
                   {
                      hostip  => "host.[3]",
                   },
               ],
            },
            "IperfTestVirtualWire2Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5].vnic.[1]",
               TestDuration   => "30",
            },
            "IperfTestVirtualWire3Unicat" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8].vnic.[1]",
               TestDuration   => "30",
            },
            'CheckVirtualWire2ArpEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[2]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[5].vnic.[1]",
                     mac  => "vm.[5].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2ArpEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[3]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[4].vnic.[1]",
                     mac  => "vm.[4].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2MacEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[2]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[5].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2MacEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[2]",
               host         => 'host.[3]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[4].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire2ControllerInfo' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllerstatusonhosts => 'up',
               hosts           => 'host.[2-3]',
               noofretries     => "10",
            },
            'CheckVirtualWire2MTEPOnAllHost' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[2]",
               checkmteponhost => 'host.[2-3]',
            },
            'ClearArpEntryForVirtualWire2OnAllHosts' => {
               Type       => "Switch",
               testswitch => "vsm.[1].networkscope.[1].virtualwire.[2]",
               clearvwireentryonhost => 'arp',
               hosts      => 'host.[2-3]',
            },
            'ClearArpEntryForVirtualWire3OnAllHosts' => {
               Type       => "Switch",
               testswitch => "vsm.[1].networkscope.[1].virtualwire.[3]",
               clearvwireentryonhost => 'arp',
               hosts      => 'host.[2-3]',
            },
            'CheckVirtualWire3ArpEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               host         => 'host.[2]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[8].vnic.[1]",
                     mac  => "vm.[8].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire3ArpEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               host         => 'host.[3]',
               'VerifyArpEntryOnHost[?]contain_once' => [
                  {
                     ip   => "vm.[7].vnic.[1]",
                     mac  => "vm.[7].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire3MacEntryOnHost2' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               host         => 'host.[2]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[8].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire3MacEntryOnHost3' => {
               Type         => "Switch",
               testswitch   => "vsm.[1].networkscope.[1].virtualwire.[3]",
               host         => 'host.[3]',
               'VerifyMacEntryOnHost[?]contains' => [
                  {
                     mac  => "vm.[7].vnic.[1]",
                  },
               ],
            },
            'CheckVirtualWire3ControllerInfo' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[3]",
               controllerstatusonhosts => 'up',
               hosts           => 'host.[2-3]',
               noofretries     => "10",
            },
            'CheckVirtualWire3MTEPOnAllHost' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[3]",
               checkmteponhost => 'host.[2-3]',
            },
         },
      },
      'StressvMotion' => {
         TestName         => 'vMotion',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify the vMotion in vxlan on hosts ',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity,physical',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P2',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_10,
         'WORKLOADS' => {
            Sequence => [
               ['CreateVirtualWire'],
               ['PlaceVMsOnVirtualWire1'],
               ['PoweronVM1','PoweronVM2'],
               ['PoweronVM3','PoweronVM4'],
               ['AddvmknicHost2DVPG1','AddvmknicHost3DVPG1',
                'AddvmknicHost4DVPG1','AddvmknicHost5DVPG1'],
               ['NetperfTestIgnorethroughput1','vMotionVM1ToHost3'],
               ['NetperfTestIgnorethroughput2','vMotionVM3ToHost5'],
            ],
            ExitSequence => [
               ['RemoveVmksOnAllHosts'],
               ['PoweroffVM'],
               ['DeleteVM1Vnic1'],
               ['DeleteVM2Vnic1'],
               ['DeleteVM3Vnic1'],
               ['DeleteVM4Vnic1'],
               ['DeleteAllVirtualWires'],
            ],
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'PoweroffVM' => POWEROFF_VM,
            'DeleteVM1Vnic1' => DELETE_VM1_VNIC1,
            'DeleteVM2Vnic1' => DELETE_VM2_VNIC1,
            'DeleteVM3Vnic1' => DELETE_VM3_VNIC1,
            'DeleteVM4Vnic1' => DELETE_VM4_VNIC1,
            'CreateVirtualWire'     => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'DeleteAllVirtualWires' => DELETE_ALL_VIRTUALWIRES,
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-4]",
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
            'PoweronVM1' => POWERON_VM1,
            'PoweronVM2' => POWERON_VM2,
            'PoweronVM3' => POWERON_VM3,
            'PoweronVM4' => POWERON_VM4,
            'AddvmknicHost2DVPG1' => {
               Type     => "Host",
               TestHost => "host.[2]",
               vmknic   => {
                  '[1]' => {
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     ipv4address => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_1,
                     netmask     => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                     configurevmotion => "enable",
                  },
               },
            },
            'AddvmknicHost3DVPG1' => {
               Type     => "Host",
               TestHost => "host.[3]",
               vmknic   => {
                  '[1]' => {
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     ipv4address => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_2,
                     netmask     => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                     configurevmotion => "enable",
                  },
               },
            },
            'AddvmknicHost4DVPG1' => {
               Type     => "Host",
               TestHost => "host.[4]",
               vmknic   => {
                  '[1]' => {
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     ipv4address => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_3,
                     netmask     => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                     configurevmotion => "enable",
                  },
               },
            },
            'AddvmknicHost5DVPG1' => {
               Type     => "Host",
               TestHost => "host.[5]",
               vmknic   => {
                  '[1]' => {
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                     ipv4address => VDNetLib::TestData::TestConstants::VXLAN_VM_STATIC_IP_4,
                     netmask     => VDNetLib::TestData::TestConstants::DEFAULT_NETMASK,
                     configurevmotion => "enable",
                  },
               },
            },
            'RemoveVmksOnAllHosts' => {
               Type => "Host",
               TestHost => "host.[1-4]",
               removevmknic => "host.[1].vmknic.[1]",
            },
            "NetperfTestIgnorethroughput1" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               L3Protocol     => "ipv4",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               TestDuration   => "100",
            },
            "NetperfTestIgnorethroughput2" => {
               Type           => "Traffic",
               toolname       => "iperf",
               L4Protocol     => "tcp",
               L3Protocol     => "ipv4",
               TestAdapter    => "vm.[3].vnic.[1]",
               SupportAdapter => "vm.[4].vnic.[1]",
               TestDuration   => "100",
            },
            "vMotionVM1ToHost3" => {
               Type           => "VM",
               TestVM         => "vm.[1]",
               vmotion        => "roundtrip",
               dsthost        => "host.[3]",
               Iterations     => 20,
            },
            "vMotionVM3ToHost5" => {
               Type           => "VM",
               TestVM         => "vm.[3]",
               vmotion        => "roundtrip",
               dsthost        => "host.[5]",
               Iterations     => 20,
            },
         },
      },
      'ScaleNewDeleteTZandVwire' => {
         TestName         => 'ScaleNewDeleteTZandVwire',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify controller info sync to host ',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '5511',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
               ['DeleteAllVirtualWires'],
               ['Create1000VirtualWire_Unicast'],
               ['DeleteAllVirtualWires'],
               ['Create1000VirtualWire_Multicast'],
               ['DeleteAllVirtualWires'],
               ['Create1000VirtualWire_Hybrid'],
               ['DeleteAllVirtualWires'],
               ['Create1000NetworkScope'],
               ['DeleteNetworkScopes'],
               ],
            ExitSequence => [
               ['DeleteNetworkScopes'],
               ['DeleteAllVirtualWires'],
            ],

            'Deploy_Controller1' => DEPLOY_FIRST_CONTROLLER,
            'Create1000NetworkScope' => {
               Type => 'NSX',
               testnsx => "vsm.[1]",
               networkscope => {
                  '[2-1000]' => {
                     name         => "network-scope-$$",
                     clusters     => "vc.[1].datacenter.[1].cluster.[2-3]",
                  },
               },
               maxtimeout    => "128000",
            },
            'DeleteNetworkScopes'  => {
               Type               => 'NSX',
               TestNSX            => "vsm.[1]",
               deletenetworkscope => "vsm.[1].networkscope.[-1]",
               sleepbetweenworkloads => "10",
               maxtimeout    => "8000",
            },
            'Create1000VirtualWire_Unicast' => {
               Type  => "TransportZone",
               testtransportzone   => "vsm.[1].networkscope.[1]",
               VirtualWire  => {
                  "[1-1000]" => {
                     name               => "AutoGenerate",
                     tenantid           => "AutoGenerate",
                     controlplanemode   => "UNICAST_MODE",
                  },
               },
               maxtimeout    => "128000",
            },
            'Create1000VirtualWire_Multicast' => {
               Type  => "TransportZone",
               testtransportzone   => "vsm.[1].networkscope.[1]",
               VirtualWire  => {
                  "[1-1000]" => {
                     name               => "AutoGenerate",
                     tenantid           => "AutoGenerate",
                     controlplanemode   => "MULTICAST_MODE",
                  },
               },
               maxtimeout    => "128000",
            },
            'Create1000VirtualWire_Hybrid' => {
               Type  => "TransportZone",
               testtransportzone   => "vsm.[1].networkscope.[1]",
               VirtualWire  => {
                  "[1-1000]" => {
                     name               => "AutoGenerate",
                     tenantid           => "AutoGenerate",
                     controlplanemode   => "HYBRID_MODE",
                  },
               },
               maxtimeout    => "128000",
            },
            'DeleteAllVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[-1]",
               maxtimeout    => "8000",
               sleepbetweenworkloads => "5",
            },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor for VXLAN Stress TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of VXLAN Stress class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my ($proto) = @_;
   #
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   #
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%VXLANStress);
   return (bless($self, $class));
}

1;

