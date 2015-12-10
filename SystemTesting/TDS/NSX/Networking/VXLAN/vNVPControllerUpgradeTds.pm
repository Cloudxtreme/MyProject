package TDS::NSX::Networking::VXLAN::vNVPControllerUpgradeTds;

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
   %vNVPControllerUpgrade = (
      'ControllerUpgrade' => {
         TestName         => 'ControllerUpgrade',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'To verify a 3 nodes controllers cluster can be upgraded succesfully',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         REDMINE          => '23423',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'mqing',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
             # step 1, before upgrade verfiy all the function and traffic works
              ['CreateVirtualWire'],
              ['PlaceVMsOnVirtualWire1'],
              ['PlaceVMsOnVirtualWire2'],
              ['PlaceVMsOnVirtualWire3'],
              ['PoweronVM1','PoweronVM2','PoweronVM3'],
              ['PoweronVM4','PoweronVM5','PoweronVM6'],
              ['PoweronVM7','PoweronVM8','PoweronVM9'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 2, first upgrade VSM and run basic traffic
              ['UpgradeNSX'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 3, upgrade the controllers cluster
              ['VerifyControllerClusterUpgradable'],
              ['VerifyClusterUpgradeNotUpgraded'],
              ['UpgradeControllersCluster'],
              ['VerifyClusterUpgradeComplete'],
              ['VerifyEachControllerUpgradeSuccess'],

            # step 4, set controller divvy to 3 , check its function
              ['ConfigureVxlanDelayDivvyTo3'],
              ['VerifyControllerDelayDivvyChangeTo3'],
              ['ShutdownActiveControllerForVirtualWire2'],
              ['CheckVirtualWireControllerInfo_Down'],
              ['PoweronActiveControllerForVirtualWire2'],
              ['CheckVirtualWireControllerInfo_UP'],

            # step 5, set controller divvy to 1, check its function
              ['ConfigureVxlanDelayDivvyTo1'],
              ['VerifyControllerDelayDivvyChangeBackTo1'],
              ['ShutdownActiveControllerForVirtualWire2'],
              ['CheckVirtualWireControllerInfo_UP'],
              ['PoweronActiveControllerForVirtualWire2'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 6, upgrade VDN clusters and run basic traffic
              ['VerifyUpgradeStatus'],
              ['UpgradeVDNCluster1'],
              ['UpgradeVDNCluster2'],
              ['RebootHost2','RebootHost3','RebootHost4'],
              ['PoweronVM1','PoweronVM2','PoweronVM3'],
              ['PoweronVM4','PoweronVM5','PoweronVM6'],
              ['PoweronVM7','PoweronVM8','PoweronVM9'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],
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
                     driver     => VXLAN_VNIC_DRIVER,
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
                     driver     => VXLAN_VNIC_DRIVER,
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-9]",
               vnic => {
                  '[1]'   => {
                     driver     => VXLAN_VNIC_DRIVER,
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
            "NetperfTestVirtualWire1" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire2" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "udp",
               udpbandwidth   => "100M",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire3" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
               TestDuration   => "30",
            },
            "VerifyControllerClusterUpgradable" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradecapability => {
                 'capability[?]equal_to' => "TRUE",
               },
            },
            "UpgradeNSX" => {
               Type          => "NSX",
               TestNSX       => "vsm.[1]",
               profile       => "update",
               build         => "from_yaml",
               name          => "VMware-NSX-Manager-upgrade-bundle-",
               maxtimeout    => "9000",
            },
            "VerifyClusterUpgradeNotUpgraded" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus=> {
                 'status[?]equal_to' => "NOT_UPGRADED",
               },
            },
            "UpgradeControllersCluster" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               vxlancontrollers => "UPGRADE",
            },
            "VerifyClusterUpgradeComplete" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus => {
                 'status[?]equal_to' => "UPGRADE_COMPLETE",
               },
            },
            "VerifyEachControllerUpgradeSuccess" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               controllerupgradestatus => {
                 'status[?]equal_to' => "UPGRADED",
               },
            },
            "ConfigureVxlanDelayDivvyTo3" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               setcmdoncontroller => "divvy",
               value          => "3",
            },
            "VerifyControllerDelayDivvyChangeTo3" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               verifycontrollerdelaydivvy => {
                 'divvy[?]equal_to' => "3",
               },
            },
            "ShutdownActiveControllerForVirtualWire2"   => {
               Type        => 'NSX',
               TestNSX     => "vsm.[1]",
               ActiveControllerState => "poweroff",
               controllers => "vsm.[1].vxlancontroller.[-1]",
               switches    => "vsm.[1].networkscope.[1].virtualwire.[2]",
            },
            "PoweronActiveControllerForVirtualWire2"   => {
               Type => "VM",
               TestVM => "vsm.[1].vxlancontroller.[1-3]",
               iterations => "2",
               vmstate  => "poweron",
            },
            'CheckVirtualWireControllerInfo_UP' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllerstatusonhosts => 'up',
               hosts           => 'host.[2-4]',
               noofretries     => "20",
            },
            'CheckVirtualWireControllerInfo_Down' => {
               Type            => "Switch",
               TestSwitch      => "vsm.[1].networkscope.[1].virtualwire.[2]",
               controllerstatusonhosts => 'down',
               hosts           => 'host.[2-4]',
               noofretries     => "20"
            },
            "ConfigureVxlanDelayDivvyTo1" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               setcmdoncontroller => "divvy",
               value          => "1",
            },
            "VerifyControllerDelayDivvyChangeBackTo1" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               verifycontrollerdelaydivvy => {
                 'divvy[?]equal_to' => "1",
               },
            },
            'UpgradeVDNCluster1' => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[2]",
            },
            'UpgradeVDNCluster2' => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[2]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[3]",
            },
            "VerifyUpgradeStatus" => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1-2]",
               verifyupgradestatus => {
                 "resourceStatus[?]contain_once" => [
                     {
                       "featureId" => "com.vmware.vshield.vsm.nwfabric.hostPrep",
                       "updateAvailable" => "true",
                     }
                  ],
               },
            },
            "RebootHost2" => {
              Type     => "Host",
              Testhost => "host.[2]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
            "RebootHost3" => {
              Type     => "Host",
              Testhost => "host.[3]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
            "RebootHost4" => {
              Type     => "Host",
              Testhost => "host.[4]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
         },
      },
      'VseUpgrade' => {
         TestName         => 'VseUpgrade',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'verify after Vse upgrade, traffic should still works',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         REDMINE          => '23423',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'mqing',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
            # step 1, before upgrade verfiy all the function and traffic works
              ['CreateVirtualWire'],
              ['PlaceVMsOnVirtualWire1'],
              ['PlaceVMsOnVirtualWire2'],
              ['PlaceVMsOnVirtualWire3'],
              ['PoweronVM1','PoweronVM2','PoweronVM3'],
              ['PoweronVM4','PoweronVM5','PoweronVM6'],
              ['PoweronVM7','PoweronVM8','PoweronVM9'],
              ['SetVXLANIPVM1','SetVXLANIPVM2','SetVXLANIPVM3'],
              ['SetVXLANIPVM4','SetVXLANIPVM5','SetVXLANIPVM6'],
              ['SetVXLANIPVM7','SetVXLANIPVM8','SetVXLANIPVM9'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 2 , deploy a VSE and verify the traffics between vWires
              ['CreateDVPG'],
              ['DeployEdge'],
              ['CreateVXLANLIF1'],
              ['CreateVXLANLIF2'],
              ['CreateVXLANLIF3'],
              ['AddVirtualWire2RouteVM123', 'AddVirtualWire1RouteVM456', 'AddVirtualWire1RouteVM789'],
              ['AddVirtualWire3RouteVM123', 'AddVirtualWire3RouteVM456', 'AddVirtualWire2RouteVM789'],
              ['NetperfTestVirtualWire12'],
              ['NetperfTestVirtualWire13'],
              ['NetperfTestVirtualWire23'],

            # step 3, first upgrade VSM and run basic traffic
              ['UpgradeNSX'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],
              ['NetperfTestVirtualWire12'],
              ['NetperfTestVirtualWire13'],
              ['NetperfTestVirtualWire23'],

            # step 4, upgrade the controllers cluster and run basic traffic
              ['VerifyControllerClusterUpgradable'],
              ['VerifyClusterUpgradeNotUpgraded'],
              ['UpgradeControllersCluster'],
              ['VerifyClusterUpgradeComplete'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 5, upgrade network fabric and run basic traffic
              ['VerifyUpgradeStatus'],
              ['UpgradeVDNCluster1'],
              ['UpgradeVDNCluster2'],
              ['RebootHost2','RebootHost3','RebootHost4'],
              ['PoweronVM1','PoweronVM2','PoweronVM3'],
              ['PoweronVM4','PoweronVM5','PoweronVM6'],
              ['PoweronVM7','PoweronVM8','PoweronVM9'],
              ['PoweronEdge'],
              ['SetVXLANIPVM1','SetVXLANIPVM2','SetVXLANIPVM3'],
              ['SetVXLANIPVM4','SetVXLANIPVM5','SetVXLANIPVM6'],
              ['SetVXLANIPVM7','SetVXLANIPVM8','SetVXLANIPVM9'],
              ['AddVirtualWire2RouteVM123', 'AddVirtualWire1RouteVM456', 'AddVirtualWire1RouteVM789'],
              ['AddVirtualWire3RouteVM123', 'AddVirtualWire3RouteVM456', 'AddVirtualWire2RouteVM789'],
              ['NetperfTestVirtualWire12'],
              ['NetperfTestVirtualWire13'],
              ['NetperfTestVirtualWire23'],

            # step 6, upgrade VSE and verify traffics works well
              ["UpgradeVSE"],
              ['NetperfTestVirtualWire12'],
              ['NetperfTestVirtualWire13'],
              ['NetperfTestVirtualWire23'],
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
              ['DeleteEdge'],
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
            'DeleteEdge'   => {
                Type       => "NSX",
                TestNSX    => "vsm.[1]",
                deletevse  => "vsm.[1].vse.[1]",
            },

            'CreateVirtualWire' => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-3]",
               vnic => {
                  '[1]'   => {
                     driver     => VXLAN_VNIC_DRIVER,
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
                     driver     => VXLAN_VNIC_DRIVER,
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-9]",
               vnic => {
                  '[1]'   => {
                     driver     => VXLAN_VNIC_DRIVER,
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
            'PoweronEdge' => {
                Type    =>  "VM",
                TestVM  =>  "vsm.[1].vse.[1]",
                vmstate => "poweron",
            },

            "SetVXLANIPVM1" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[1].vnic.[1]",
                ipv4        =>  '192.168.1.11',
                netmask     =>  "255.255.255.0",
            },
            "SetVXLANIPVM2" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[2].vnic.[1]",
                ipv4        =>  '192.168.1.12',
                netmask     =>  "255.255.255.0",
            },
            "SetVXLANIPVM3" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[3].vnic.[1]",
                ipv4        =>  '192.168.1.13',
                netmask     =>  "255.255.255.0",
            },
            "SetVXLANIPVM4" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[4].vnic.[1]",
                ipv4        =>  '192.168.2.14',
                netmask     =>  "255.255.255.0",
            },
            "SetVXLANIPVM5" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[5].vnic.[1]",
                ipv4        =>  '192.168.2.15',
                netmask     =>  "255.255.255.0",
            },
            "SetVXLANIPVM6" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[6].vnic.[1]",
                ipv4        =>  '192.168.2.16',
                netmask     =>  "255.255.255.0",
            },
            "SetVXLANIPVM7" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[7].vnic.[1]",
                ipv4        =>  '192.168.3.17',
                netmask     =>  "255.255.255.0",
            },
            "SetVXLANIPVM8" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[8].vnic.[1]",
                ipv4        =>  '192.168.3.18',
                netmask     =>  "255.255.255.0",
            },
            "SetVXLANIPVM9" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[9].vnic.[1]",
                ipv4        =>  '192.168.3.19',
                netmask     =>  "255.255.255.0",
            },
            "NetperfTestVirtualWire1" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire2" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "udp",
               udpbandwidth   => "100M",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire3" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
               TestDuration   => "30",
            },
            'CreateDVPG' => {
               Type => "VC",
               TestVC => "vc.[1]",
               dvportgroup => {
                  '[1]' => {
                     vds  => 'vc.[1].vds.[1]',
                  },
               },
            },
            'DeployEdge' => {
                Type    => "NSX",
                TestNSX => "vsm.[1]",
                vse => {
                    '[1]' => {
                        name         => "AutoGenerate",
                        resourcepool => "vc.[1].datacenter.[1].cluster.[2]",
                        datacenter   => "vc.[1].datacenter.[1]",
                        host         => "host.[2]",
                        portgroup    => "vc.[1].dvportgroup.[1]",
                        primaryaddress => "10.10.10.40",
                        subnetmask   => "255.255.255.0",
                    },
                },
            },
            "CreateVXLANLIF1" => {
                Type   =>  "VM",
                TestVM =>  "vsm.[1].vse.[1]",
                lif => {
                    '[1]' => {
                        name      =>  "AutoGenerate",
                        portgroup =>  "vsm.[1].networkscope.[1].virtualwire.[1]",
                        type      =>  "internal",
                        connected    =>  1,
                        addressgroup => [{
                           addresstype =>  "primary",
                           ipv4address =>  "192.168.1.1",
                           netmask     =>  "255.255.255.0",
                        }]
                    },
                },
            },
            "CreateVXLANLIF2" => {
                Type   =>  "VM",
                TestVM =>  "vsm.[1].vse.[1]",
                lif => {
                    '[2]' => {
                        name      =>  "AutoGenerate",
                        portgroup =>  "vsm.[1].networkscope.[1].virtualwire.[2]",
                        type      =>  "internal",
                        connected    =>  1,
                        addressgroup => [{
                           addresstype =>  "primary",
                           ipv4address =>  "192.168.2.1",
                           netmask     =>  "255.255.255.0",
                        }]
                    },
                },
            },
            "CreateVXLANLIF3" => {
                Type   =>  "VM",
                TestVM =>  "vsm.[1].vse.[1]",
                lif => {
                    '[3]' => {
                        name      =>  "AutoGenerate",
                        portgroup =>  "vsm.[1].networkscope.[1].virtualwire.[3]",
                        type      =>  "internal",
                        connected    =>  1,
                        addressgroup => [{
                           addresstype =>  "primary",
                           ipv4address =>  "192.168.3.1",
                           netmask     =>  "255.255.255.0",
                        }]
                    },
                },
            },
            "AddVirtualWire2RouteVM123" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[1-3].vnic.[1]",
                netmask     =>  "255.255.255.0",
                route       =>  "add",
                network     =>  "192.168.2.0",
                gateway     =>  "192.168.1.1",
            },
            "AddVirtualWire3RouteVM123" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[1-3].vnic.[1]",
                netmask     =>  "255.255.255.0",
                route       =>  "add",
                network     =>  "192.168.3.0",
                gateway     =>  "192.168.1.1",
            },
            "AddVirtualWire1RouteVM456" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[4-6].vnic.[1]",
                netmask     =>  "255.255.255.0",
                route       =>  "add",
                network     =>  "192.168.1.0",
                gateway     =>  "192.168.2.1",
            },
            "AddVirtualWire3RouteVM456" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[4-6].vnic.[1]",
                netmask     =>  "255.255.255.0",
                route       =>  "add",
                network     =>  "192.168.3.0",
                gateway     =>  "192.168.2.1",
            },
            "AddVirtualWire1RouteVM789" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[7-9].vnic.[1]",
                netmask     =>  "255.255.255.0",
                route       =>  "add",
                network     =>  "192.168.1.0",
                gateway     =>  "192.168.3.1",
            },
            "AddVirtualWire2RouteVM789" => {
                Type        =>  "NetAdapter",
                Testadapter =>  "vm.[7-9].vnic.[1]",
                netmask     =>  "255.255.255.0",
                route       =>  "add",
                network     =>  "192.168.2.0",
                gateway     =>  "192.168.3.1",
            },
            "NetperfTestVirtualWire12" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1-3].vnic.[1]",
               SupportAdapter => "vm.[4-6].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire13" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "udp",
               udpbandwidth   => "100M",
               TestAdapter    => "vm.[1-3].vnic.[1]",
               SupportAdapter => "vm.[7-9].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire23" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[4-6].vnic.[1]",
               SupportAdapter => "vm.[7-9].vnic.[1]",
               TestDuration   => "30",
            },
            "VerifyControllerClusterUpgradable" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradecapability => {
                 'capability[?]equal_to' => "TRUE",
               },
            },
            "UpgradeNSX" => {
               Type          => "NSX",
               TestNSX       => "vsm.[1]",
               profile       => "update",
               build         => "from_yaml",
               name          => "VMware-NSX-Manager-upgrade-bundle-",
               maxtimeout    => "9000",
            },
            "VerifyClusterUpgradeNotUpgraded" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus=> {
                 'status[?]equal_to' => "NOT_UPGRADED",
               },
            },
            "UpgradeControllersCluster" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               vxlancontrollers => "UPGRADE",
            },
            "VerifyClusterUpgradeComplete" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus => {
                 'status[?]equal_to' => "UPGRADE_COMPLETE",
               },
            },
            "VerifyEachControllerUpgradeSuccess" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               controllerupgradestatus => {
                 'status[?]equal_to' => "UPGRADED",
               },
            },
            'UpgradeVDNCluster1' => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[2]",
            },
            'UpgradeVDNCluster2' => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[2]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[3]",
            },
            "VerifyUpgradeStatus" => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1-2]",
               verifyupgradestatus => {
                 "resourceStatus[?]contain_once" => [
                     {
                       "featureId" => "com.vmware.vshield.vsm.nwfabric.hostPrep",
                       "updateAvailable" => "true",
                     }
                  ],
               },
            },
            "RebootHost2" => {
              Type     => "Host",
              Testhost => "host.[2]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
            "RebootHost3" => {
              Type     => "Host",
              Testhost => "host.[3]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
            "RebootHost4" => {
              Type     => "Host",
              Testhost => "host.[4]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
            'UpgradeVSE' => {
               Type     => "VM",
               TestVM   => "vsm.[1].vse.[1]",
               profile  => "update",
            },
         },
      },
      'ControllerUpgradeSuccessNegativeTest' => {
         TestName         => 'ControllerUpgradeSuccessNegativeTest',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'veirfy during vxlan upgrade, do some special ops',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         REDMINE          => '23423',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'mqing',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
            # step 1, before upgrade verfiy all the function and traffic works
              ['CreateVirtualWire'],
              ['PlaceVMsOnVirtualWire1'],
              ['PlaceVMsOnVirtualWire2'],
              ['PlaceVMsOnVirtualWire3'],
              ['PoweronVM1','PoweronVM2','PoweronVM3'],
              ['PoweronVM4','PoweronVM5','PoweronVM6'],
              ['PoweronVM7','PoweronVM8','PoweronVM9'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 2, first upgrade VSM and run basic traffic
              ['UpgradeNSX'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 3, during vxlan controllers upgrade do some special ops
              ['AddUnicastModeVirtualWire5'],
              ['AddHybridModeVirtualWire6'],
              ['VerifyControllerClusterUpgradable'],
              ['VerifyClusterUpgradeNotUpgraded'],
              ['UpgradeControllersCluster',
               'AddMulticastModeVirtualWire4',
               'DeleteMulticastModeVirtualWire4',
               'AddUnicastModeVirtualWire7',
               'DeleteUnicastModeVirtualWire5',
               'AddHybridModeVirtualWire8',
               'DeleteHybridModeVirtualWire6'],
              ['VerifyClusterUpgradeComplete'],
              ['VerifyEachControllerUpgradeSuccess'],
              ['VerifyControllerDelayDivvyUnChangedAs1'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 4, upgrade VDN clusters and run basic traffic
              ['VerifyUpgradeStatus'],
              ['UpgradeVDNCluster1'],
              ['UpgradeVDNCluster2'],
              ['RebootHost2','RebootHost3','RebootHost4'],
              ['PoweronVM1','PoweronVM2','PoweronVM3'],
              ['PoweronVM4','PoweronVM5','PoweronVM6'],
              ['PoweronVM7','PoweronVM8','PoweronVM9'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],
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
                     driver     => VXLAN_VNIC_DRIVER,
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
                     driver     => VXLAN_VNIC_DRIVER,
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-9]",
               vnic => {
                  '[1]'   => {
                     driver     => VXLAN_VNIC_DRIVER,
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
            "NetperfTestVirtualWire1" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire2" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "udp",
               udpbandwidth   => "100M",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire3" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
               TestDuration   => "30",
            },
            "VerifyControllerClusterUpgradable" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradecapability => {
                 'capability[?]equal_to' => "TRUE",
               },
            },
            "UpgradeNSX" => {
               Type          => "NSX",
               TestNSX       => "vsm.[1]",
               profile       => "update",
               build         => "from_yaml",
               name          => "VMware-NSX-Manager-upgrade-bundle-",
               maxtimeout    => "9000",
            },
            "VerifyClusterUpgradeNotUpgraded" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus=> {
                 'status[?]equal_to' => "NOT_UPGRADED",
               },
            },
            "UpgradeControllersCluster" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               vxlancontrollers => "UPGRADE",
            },
            "AddMulticastModeVirtualWire4" => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[4]" => {
                     name        => "AutoGenerate",
                     tenantid    => "AutoGenerate",
                     controlplanemode => "MULTICAST_MODE",
                  },
               },
               sleepbetweenworkloads => '60',
            },
            'DeleteMulticastModeVirtualWire4' => {
               Type                  => "TransportZone",
               TestTransportZone     => "vsm.[1].networkscope.[1]",
               DeleteVirtualWire     => "vsm.[1].networkscope.[1].virtualwire.[4]",
               sleepbetweenworkloads => '120',
            },
            "AddUnicastModeVirtualWire5" => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[5]" => {
                     name        => "AutoGenerate",
                     tenantid    => "AutoGenerate",
                     controlplanemode => "UNICAST_MODE",
                  },
               },
            },
            "AddUnicastModeVirtualWire7" => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[7]" => {
                     name        => "AutoGenerate",
                     tenantid    => "AutoGenerate",
                     controlplanemode => "UNICAST_MODE",
                  },
               },
               expectedresult => "Fail",
               sleepbetweenworkloads => '180',
            },
            'DeleteUnicastModeVirtualWire5' => {
               Type                  => "TransportZone",
               TestTransportZone     => "vsm.[1].networkscope.[1]",
               DeleteVirtualWire     => "vsm.[1].networkscope.[1].virtualwire.[5]",
               sleepbetweenworkloads => '240',
               expectedresult => "Fail"
            },
            "AddHybridModeVirtualWire6" => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[6]" => {
                     name        => "AutoGenerate",
                     tenantid    => "AutoGenerate",
                     controlplanemode => "HYBRID_MODE",
                  },
               },
            },
            "AddHybridModeVirtualWire8" => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               VirtualWire       => {
                  "[8]" => {
                     name        => "AutoGenerate",
                     tenantid    => "AutoGenerate",
                     controlplanemode => "HYBRID_MODE",
                  },
               },
               expectedresult => "Fail",
               sleepbetweenworkloads => '300',
            },
            'DeleteHybridModeVirtualWire6' => {
               Type                  => "TransportZone",
               TestTransportZone     => "vsm.[1].networkscope.[1]",
               DeleteVirtualWire     => "vsm.[1].networkscope.[1].virtualwire.[6]",
               sleepbetweenworkloads => '360',
               expectedresult => "Fail"
            },
            "VerifyClusterUpgradeComplete" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus => {
                 'status[?]equal_to' => "UPGRADE_COMPLETE",
               },
            },
            "VerifyEachControllerUpgradeSuccess" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               controllerupgradestatus => {
                 'status[?]equal_to' => "UPGRADED",
               },
            },
            "VerifyClusterUpgradeFailed" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus => {
                 'status[?]equal_to' => "UNKNOWN",
               },
            },
            "VerifyControllerDelayDivvyUnChangedAs1" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               verifycontrollerdelaydivvy => {
                 'divvy[?]equal_to' => "1",
               },
            },
            'UpgradeVDNCluster1' => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[2]",
            },
            'UpgradeVDNCluster2' => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[2]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[3]",
            },
            "VerifyUpgradeStatus" => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1-2]",
               verifyupgradestatus => {
                 "resourceStatus[?]contain_once" => [
                     {
                       "featureId" => "com.vmware.vshield.vsm.nwfabric.hostPrep",
                       "updateAvailable" => "true",
                     }
                  ],
               },
            },
            "RebootHost2" => {
              Type     => "Host",
              Testhost => "host.[2]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
            "RebootHost3" => {
              Type     => "Host",
              Testhost => "host.[3]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
            "RebootHost4" => {
              Type     => "Host",
              Testhost => "host.[4]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
         },
      },
      'ControllerUpgradeFailedNegativeTest' => {
         TestName         => 'ControllerUpgradeFailedNegativeTest',
         Category         => 'Networking',
         Component        => 'VXLAN',
         Product          => 'NSX',
         QCPath           => 'OP\Networking-FVT\VXLAN',
         Summary          => 'verify vxlan controller upgrade failed scenario',
         Procedure        => '',
         ExpectedResult   => 'PASS',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         PMT              => '',
         REDMINE          => '23423',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P1',
         Developer        => 'mqing',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2' ,

         'TestbedSpec' => Functional_Topology_15,
          'WORKLOADS' => {
            Sequence => [
            # step 1, before upgrade verfiy all the function and traffic works
              ['CreateVirtualWire'],
              ['PlaceVMsOnVirtualWire1'],
              ['PlaceVMsOnVirtualWire2'],
              ['PlaceVMsOnVirtualWire3'],
              ['PoweronVM1','PoweronVM2','PoweronVM3'],
              ['PoweronVM4','PoweronVM5','PoweronVM6'],
              ['PoweronVM7','PoweronVM8','PoweronVM9'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 2, first upgrade VSM and run basic traffic
              ['UpgradeNSX'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 3, make vxlan controllers upgrade failed by disconnect controllers and run basic traffic
              ['VerifyControllerClusterUpgradable'],
              ['VerifyClusterUpgradeNotUpgraded'],
              ['Initpswitchport'],
              ['UpgradeControllersCluster', 'DisablePswitchPort'],
              ['EnablePswitchPort'],
              ['VerifyClusterUpgradeFailed'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 4, make vxlan controllers upgrade failed by shutdown one controller and run basic traffic
              ['PowerOffController1'],
              ['VerifyControllerClusterUpgradable'],
              ['UpgradeControllersCluster'],
              ['VerifyClusterUpgradeFailed'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 5, try another upgrade and the upgrade will be successful
              ['PowerOnController1'],
              ['VerifyControllerClusterUpgradable'],
              ['UpgradeControllersCluster'],
              ['VerifyClusterUpgradeComplete'],
              ['VerifyEachControllerUpgradeSuccess'],
              ['VerifyControllerDelayDivvyUnchangedAs1'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],

            # step 6, upgrade VDN clusters and run basic traffic
              ['VerifyUpgradeStatus'],
              ['UpgradeVDNCluster1'],
              ['UpgradeVDNCluster2'],
              ['RebootHost2','RebootHost3','RebootHost4'],
              ['PoweronVM1','PoweronVM2','PoweronVM3'],
              ['PoweronVM4','PoweronVM5','PoweronVM6'],
              ['PoweronVM7','PoweronVM8','PoweronVM9'],
              ['NetperfTestVirtualWire1'],
              ['NetperfTestVirtualWire2'],
              ['NetperfTestVirtualWire3'],
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

            'PowerOffController1' => {
               Type => "VM",
               TestVM => "vsm.[1].vxlancontroller.[1]",
               vmstate  => "poweroff",
            },
            'PowerOnController1' => {
               Type => "VM",
               TestVM => "vsm.[1].vxlancontroller.[1]",
               vmstate  => "poweron",
            },
            'CreateVirtualWire' => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'PlaceVMsOnVirtualWire1' => {
               Type => "VM",
               TestVM => "vm.[1-3]",
               vnic => {
                  '[1]'   => {
                     driver     => VXLAN_VNIC_DRIVER,
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
                     driver     => VXLAN_VNIC_DRIVER,
                     portgroup  => "vsm.[1].networkscope.[1].virtualwire.[2]",
                     connected => 1,
                     startconnected => 1,
                     allowguestcontrol => 1,
                  },
               },
            },
            'PlaceVMsOnVirtualWire3' => {
               Type => "VM",
               TestVM => "vm.[7-9]",
               vnic => {
                  '[1]'   => {
                     driver     => VXLAN_VNIC_DRIVER,
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
            "NetperfTestVirtualWire1" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2-3].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire2" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "udp",
               udpbandwidth   => "100M",
               TestAdapter    => "vm.[4].vnic.[1]",
               SupportAdapter => "vm.[5-6].vnic.[1]",
               TestDuration   => "30",
            },
            "NetperfTestVirtualWire3" => {
               Type           => "Traffic",
               toolName       => "iperf",
               L4Protocol     => "tcp",
               TestAdapter    => "vm.[7].vnic.[1]",
               SupportAdapter => "vm.[8-9].vnic.[1]",
               TestDuration   => "30",
            },
            "VerifyControllerClusterUpgradable" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradecapability => {
                 'capability[?]equal_to' => "TRUE",
               },
            },
            "UpgradeNSX" => {
               Type          => "NSX",
               TestNSX       => "vsm.[1]",
               profile       => "update",
               build         => "from_yaml",
               name          => "VMware-NSX-Manager-upgrade-bundle-",
               maxtimeout    => "9000",
            },
            "VerifyClusterUpgradeNotUpgraded" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus=> {
                 'status[?]equal_to' => "NOT_UPGRADED",
               },
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
            "DisablePswitchPort" => {
               Type         => "Port",
               TestPort     => "host.[1].pswitchport.[0]",
               portstatus   => "disable",
               sleepbetweenworkloads => "60",
            },
            "EnablePswitchPort" => {
               Type         => "Port",
               TestPort     => "host.[1].pswitchport.[0]",
               portstatus   => "enable",
            },
            "UpgradeControllersCluster" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               vxlancontrollers => "UPGRADE",
            },
            "VerifyClusterUpgradeComplete" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus => {
                 'status[?]equal_to' => "UPGRADE_COMPLETE",
               },
            },
            "VerifyEachControllerUpgradeSuccess" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               controllerupgradestatus => {
                 'status[?]equal_to' => "UPGRADED",
               },
            },
            "VerifyClusterUpgradeFailed" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllerupgradestatus => {
                 'status[?]not_equal_to' => "UPGRADED",
               },
            },
            "VerifyControllerDelayDivvyUnchangedAs1" => {
               Type           => "NSX",
               testnsx        => "vsm.[1]",
               controllers    => "vsm.[1].vxlancontroller.[-1]",
               verifycontrollerdelaydivvy => {
                 'divvy[?]equal_to' => "1",
               },
            },
            'UpgradeVDNCluster1' => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[2]",
            },
            'UpgradeVDNCluster2' => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[2]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[3]",
            },
            "VerifyUpgradeStatus" => {
               Type          => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1-2]",
               verifyupgradestatus => {
                 "resourceStatus[?]contain_once" => [
                     {
                       "featureId" => "com.vmware.vshield.vsm.nwfabric.hostPrep",
                       "updateAvailable" => "true",
                     }
                  ],
               },
            },
            "RebootHost2" => {
              Type     => "Host",
              Testhost => "host.[2]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
            "RebootHost3" => {
              Type     => "Host",
              Testhost => "host.[3]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
            "RebootHost4" => {
              Type     => "Host",
              Testhost => "host.[4]",
              reboot   => "yes",
              sleepbetweenworkloads => '120',
            },
         },
      },
   );
}


##########################################################################
# new --
#       This is the constructor for VXLAN Controller Upgrade TDS
#
# Input:
#       none
#
# Results:
#       An instance/object of VXLAN controller Upgrade class
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
   my $self = $class->SUPER::new(\%vNVPControllerUpgrade);
   return (bless($self, $class));
}

1;

