#!/usr/bin/perl
#########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::Networking::VirtualRouting::DHCPRelayFunctionalTds;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
#use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
@ISA = qw(TDS::Main::VDNetMainTds);

# Test constants
use constant TRAFFIC_TESTDURATION => "60";
use constant STRESS_ITERATIONS => "1";

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';
use TDS::NSX::Networking::VirtualRouting::TestbedSpec;

{
%Functional = (
#case 1
   'OneRelayServerOneRelayAgent' => {
      Category         => 'NSX',
      Component        => 'DHCP RELAY',
      TestName         => "OneRelayServerOneRelayAgent",
      Version          => "2" ,
      Tags             => "RunOnCAT",
      Summary          => "Verify relay works with one relay server and one relay agent",
      TestbedSpec      => $TDS::NSX::Networking::VirtualRouting::TestbedSpec::OneVC_OneDC_OneVDS_TwoCluster_ThreeHost_TenVMs,
      'WORKLOADS' => {
         Sequence => [
                       ['CreateNetworkScope'],
                       ['CreateVirtualWires'],

                       ['AddvNICsOnVMs'],
                       ['PoweronVM1','PoweronVM2'],
                       ['MakeSurevNICConnected'],
                       ['DeployEdge'],
                       ['CreateVXLANLIF1'],
                       ['CreateVXLANLIF2'],

                       # DHCPRelay test server configuration
                       ['PoweronDHCPServer'],
                       ['AddvNICOnDHCPserver'],
                       ['SetVXLANIPDHCPServer'],
                       ['SetVXLANRouteDHCPServer'],
                       ['SetupDHCPServer'],
                       ['EnableDHCPServerOninterfaces'],
                       ['SetLocalSubnetWithoutRange'],
                       ['SetDynamicBindingDHCP'],
                       ['SetStaticBindingDHCP'],
                       ['RestartDHCPServer'],

                       # ## DHCPRelay configuration on the VDR
                       ['ConfigureDHCPRelayForVDR'],
                       ['RunDHClientOnVM1'],
                       ['RunDHClientOnVM2'],

                       # verification workloads
                       ## Verify vnic ip workloads are blocked due to PR 1318542
                       #['VerifyVnicIPVM1'],
                       #['VerifyVnicIPVM2'],
                       ['PingTest'],
                       ['NetperfTest'],
                     ],
         ExitSequence => [
                          ['DeleteEdges'],
                          ['RemovevNICFromVM1'],
                          ['RemovevNICFromVM2'],
                          ['RemovevNICFromDHCPServer'],
                          ['Delete_All_VirtualWires'],
                          ['DeleteNetworkScope'],
                   ],
         'DeleteNetworkScope' => DELETE_ALL_NETWORKSCOPES,
         'Delete_All_VirtualWires' => DELETE_ALL_VIRTUALWIRES,
         'Uninstall_VDNCluster' => UNINSTALL_UNCONFIGURE_ALL_VDNCLUSTER,
         'MakeSurevNICConnected' => {
            Type           => "NetAdapter",
            reconfigure    => "true",
            testadapter    => "vm.[1-2].vnic.[1]",
            connected      => 1,
            startconnected => 1,
         },
         'VerifyVnicIPVM2' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[2].vnic.[1]',
             read =>  {
               'ipaddress[?]equal_to' => '172.31.1.100',
            },
         },
         'VerifyVnicIPVM1' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[1].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.31.1.10-172.31.1.50",
            },
         },
         'ConfigureDHCPRelayForVDR' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
              'dhcprelay' => {
                   '[1]' => {
                       'ip_addresses' => ["172.32.1.5"],
                       'relayagent' => 'vsm.[1].vse.[1].lif.[1]'
                      },
                 },
          },
         'SetDynamicBindingDHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.31.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.31.1.2-172.31.1.50",
               option_routers => "172.31.1.1",
            },
         },
         "SetLocalSubnetWithoutRange" => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.32.0.0",
               netmask => "255.255.0.0",
            },
         },
         'RestartDHCPServer'  => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            restart_dhcp_server => {},
          },

         'SetStaticBindingDHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'static',
               adapter_mac => 'vm.[2].vnic.[1]',
               host_name => 'host2',
               adapter_ip  => "172.31.1.100",
            },
         },
          'EnableDHCPServerOninterfaces' => {
             Type    => "DHCPServer",
             TestDHCPServer => "dhcpserver.[1]",
             enable_dhcp_server_on_interfaces => {
                adapter_interface => 'dhcpserver.[1].vnic.[1]',
            },
         },

         'AddvNICOnDHCPserver' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'SetupDHCPServer' => {
            Type    => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            unconfigure_dhcp_server => {
            },
         },
         'RemovevNICFromVM1' => {
            Type       => "VM",
            TestVM     => "vm.[1]",
            deletevnic => "vm.[1].vnic.[1]",
         },
         'RemovevNICFromVM2' => {
            Type       => "VM",
            TestVM     => "vm.[2]",
            deletevnic => "vm.[2].vnic.[1]",
         },
         'RemovevNICFromDHCPServer' => {
            Type       => "DHCPServer",
            TestDHCPServer     => "dhcpserver.[1]",
            deletevnic => "dhcpserver.[1].vnic.[1]",
         },
         "DeployEdge"   => {
            Type    => "NSX",
            TestNSX => "vsm.[1]",
            vse => {
               '[1]' => {
                  name          => "Edge-$$",
                  resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                  datacenter    => "vc.[1].datacenter.[1]",
                  host          => "host.[3]", # To pick datastore
                  portgroup     => "vc.[1].dvportgroup.[1]",
                  primaryaddress => "10.10.10.11",
                  subnetmask     => "255.255.255.0",
               },
            },
         },
         "DeleteEdges" => DELETE_ALL_EDGES,
         'CreateVXLANLIF1' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[1]'   => {
                  name        => "lif-vwire1-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.31.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF2' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[2]'   => {
                  name        => "lif-vwire2-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.32.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVLANLIF3' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[3]'   => {
                  name        => "lif-16-$$",
                  portgroup   => "vc.[1].dvportgroup.[2]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.16.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVLANLIF4' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[4]'   => {
                  name        => "lif-17-$$",
                  portgroup   => "vc.[1].dvportgroup.[3]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.17.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         "SetVXLANIPDHCPServer" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            ipv4       => '172.32.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANRouteDHCPServer" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.32.1.1",
         },
         "RunDHClientOnVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => "dhcp",
         },
         "PingTest" => {
            Type           => "Traffic",
            ToolName       => "Ping",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            TestDuration   => "60",
         },
         "NetperfTest" => {
            Type           => "Traffic",
            ToolName       => "Netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            L4Protocol     => "tcp,udp",
            ExpectedResult => "ignore",
            TestDuration   => "60",
         },
         'PoweronDHCPServer' => {
            Type    => "DHCPServer",
            TestDHCPServer  => "dhcpserver.[1]",
            vmstate => "poweron",
         },
         'PoweronVM1' => {
            Type    => "VM",
            TestVM  => "vm.[1]",
            vmstate => "poweron",
         },
         'PoweronVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweron",
         },
         'AddvNICsOnVMs' => {
            Type   => "VM",
            TestVM => "vm.[1],vm.[2]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'CreateNetworkScope' => CREATE_NETWORKSCOPE_ClusterSJC,
         'CreateVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            VirtualWire       => {
               "[1]" => {
                  name               => "AutoGenerate",
                  tenantid           => "1",
               },
               "[2]" => {
                  name               => "AutoGenerate",
                  tenantid           => "2",
               },
               "[3]" => {
                  name               => "AutoGenerate",
                  tenantid           => "3",
               },
            },
         },
         'GetVirtualWireID' => {
            Type            => "Switch",
            FindType            => "Switch",
            testvirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
         },
         'DeleteVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-3]",
         },
      },
   },

#case 2
  'OneRelayServerTwoRelayAgents' => {
      Category         => 'NSX',
      Component        => 'DHCP RELAY',
      TestName         => "OneRelayServerTwoRelayAgents",
      Version          => "2" ,
      Tags             => "RunOnCAT",
      Summary          => "Verify relay works with one relay server and two relay agents",
      TestbedSpec      => $TDS::NSX::Networking::VirtualRouting::TestbedSpec::OneVC_OneDC_OneVDS_TwoCluster_ThreeHost_TenVMs,
      'WORKLOADS' => {
         Sequence => [
                       ['CreateNetworkScope'],
                       ['CreateVirtualWires'],

                       ['AddvNICsOnVMs'],
                       ['AddvNICsOnOtherVMs'],
                       ['PoweronVM1','PoweronVM2',
                       'PoweronVM3','PoweronVM4'],
                       ['MakeSurevNICConnected'],
                       ['DeployEdge'],
                       ['CreateVXLANLIF1'],
                       ['CreateVXLANLIF2'],
                       ['CreateVXLANLIF3'],

                       # DHCPRelay test server configuration
                       ['PoweronDHCPServer'],
                       ['AddvNICOnDHCPserver'],
                       ['SetVXLANIPDHCPServer'],
                       ['SetVXLANRouteDHCPServer'],
                       ['SetupDHCPServer'],
                       ['EnableDHCPServerOninterfaces'],
                       ['SetLocalSubnetWithoutRange'],
                       ['SetDynamicBindingDHCP'],
                       ['SetDynamicBinding1DHCP'],
                       ['SetStaticBindingDHCP'],
                       ['SetStaticBinding1DHCP'],
                       ['RestartDHCPServer'],

                       # DHCPRelay configuration on the VDR
                       ['ConfigureDHCPRelayForVDR'],
                       ['RunDHClientOnVM1'],
                       ['RunDHClientOnVM2'],
                       ['RunDHClientOnVM3'],
                       ['RunDHClientOnVM4'],

                       # verification workloads
                       ## Verify vnic ip workloads are blocked due to PR 1318542
                       #   ['VerifyVnicIPVM1'],
                       #   ['VerifyVnicIPVM2'],
                       #   ['VerifyVnicIPVM3'],
                       #   ['VerifyVnicIPVM4'],
                       ["AddVXLANRouteVM1", "AddVXLANRouteVM2",
                        "AddVXLANRouteVM3", "AddVXLANRouteVM4"],
                       ['PingTest'],
                       ['NetperfTest'],
                     ],
         ExitSequence => [
                            ['DeleteEdges'],
                            ['RemovevNICFromVM1'],
                            ['RemovevNICFromVM2'],
                            ['RemovevNICFromVM3'],
                            ['RemovevNICFromVM4'],
                            ['RemovevNICFromDHCPServer'],
                            ['Delete_All_VirtualWires'],
                            ['DeleteNetworkScope'],
                         ],
         'DeleteNetworkScope' => DELETE_ALL_NETWORKSCOPES,
         'Delete_All_VirtualWires' => DELETE_ALL_VIRTUALWIRES,
         'RemovevNICFromDHCPServer' => {
            Type       => "DHCPServer",
            TestDHCPServer     => "dhcpserver.[1]",
            deletevnic => "dhcpserver.[1].vnic.[1]",
         },
         'MakeSurevNICConnected' => {
            Type           => "NetAdapter",
            reconfigure    => "true",
            testadapter    => "vm.[1-4].vnic.[1]",
            connected      => 1,
            startconnected => 1,
         },
         'VerifyVnicIPVM2' => {
             Type => 'NetAdapter',
             TestAdapter => 'dhcpserver.[1].vnic.[1]',
             read =>  {
               'ipaddress[?]equal_to' => '172.31.1.100',
            },
         },
         'VerifyVnicIPVM1' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[1].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.31.1.10-172.31.1.50",
            },
         },
         'VerifyVnicIPVM3' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[1].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.32.1.10-172.32.1.50",
            },
         },
         'VerifyVnicIPVM4' => {
             Type => 'NetAdapter',
             TestAdapter => 'dhcpserver.[1].vnic.[1]',
             read =>  {
               'ipaddress[?]equal_to' => '172.32.1.100',
            },
         },
         'ConfigureDHCPRelayForVDR' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
              'dhcprelay' => {
                   '[1]' => {
                       'ip_addresses' => ["172.33.1.5"],
                       'relayagent' => 'vsm.[1].vse.[1].lif.[1-2]'
                      },
                 },
          },
         'SetDynamicBindingDHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               subnet => "172.31.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.31.1.2-172.31.1.50",
               option_routers => "172.31.1.1",
            },
         },
         'SetDynamicBinding1DHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               subnet => "172.32.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.32.1.2-172.32.1.50",
               option_routers => "172.32.1.1",
            },
         },
         "SetLocalSubnetWithoutRange" => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.33.0.0",
               netmask => "255.255.0.0",
            },
         },
         'RestartDHCPServer'  => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            restart_dhcp_server => {},
          },

         'SetStaticBindingDHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'static',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               adapter_mac => 'vm.[2].vnic.[1]',
               #adapter_mac => 'dhcpserver.[1].vnic.[1]',
               host_name => 'host2',
               adapter_ip  => "172.31.1.100",
            },
         },
         'SetStaticBinding1DHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'static',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               adapter_mac => 'vm.[4].vnic.[1]',
               #adapter_mac => 'dhcpserver.[1].vnic.[1]',
               host_name => 'host3',
               adapter_ip  => "172.32.1.100",
            },
         },
          'EnableDHCPServerOninterfaces' => {
             Type    => "DHCPServer",
             TestDHCPServer => "dhcpserver.[1]",
             enable_dhcp_server_on_interfaces => {
                adapter_interface => 'dhcpserver.[1].vnic.[1]',
            },
         },

         'AddvNICOnDHCPserver' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[3]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'SetupDHCPServer' => {
            Type    => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            unconfigure_dhcp_server => {
            },
         },
         'RemovevNICFromVM1' => {
            Type       => "VM",
            TestVM     => "vm.[1]",
            deletevnic => "vm.[1].vnic.[1]",
         },
         'RemovevNICFromVM2' => {
            Type       => "VM",
            TestVM     => "vm.[2]",
            deletevnic => "vm.[2].vnic.[1]",
         },
         'RemovevNICFromVM3' => {
            Type       => "VM",
            TestVM     => "vm.[3]",
            deletevnic => "vm.[3].vnic.[1]",
         },
         'RemovevNICFromVM4' => {
            Type       => "VM",
            TestVM     => "vm.[4]",
            deletevnic => "vm.[4].vnic.[1]",
         },
         'PlaceVM1OnvWire1' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
         },
         'PlaceVM2OnvWire2' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[2].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
         },
         'PlaceVM3OnvWire2' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
         },
         'PlaceVM1OnvWire3' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[3]",
         },
         "DeployEdge"   => {
            Type    => "NSX",
            TestNSX => "vsm.[1]",
            vse => {
               '[1]' => {
                  name          => "Edge-$$",
                  resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                  datacenter    => "vc.[1].datacenter.[1]",
                  host          => "host.[3]", # To pick datastore
                  portgroup     => "vc.[1].dvportgroup.[1]",
                  primaryaddress => "10.10.10.11",
                  subnetmask     => "255.255.255.0",
               },
            },
         },
         "DeleteEdges" => DELETE_ALL_EDGES,
         'CreateVXLANLIF1' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[1]'   => {
                  name        => "lif-vwire1-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.31.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF2' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[2]'   => {
                  name        => "lif-vwire2-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.32.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF3' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[3]'   => {
                  name        => "lif-vwire3-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[3]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.33.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         "SetVLANIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "SetVLANIPVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "AddVLANRouteVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.17.0.0,172.31.0.0,172.32.0.0",
            gateway    => "172.16.1.1",
         },
         "AddVLANRouteVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.16.0.0,172.31.0.0,172.32.0.0",
            gateway    => "172.17.1.1",
         },
         "SetVXLANIPDHCPServer" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            ipv4       => '172.33.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANRouteDHCPServer" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.33.1.1",
         },
         "RunDHClientOnVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM4" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[4].vnic.[1]",
            ipv4       => "dhcp",
         },
         "AddVXLANRouteVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.31.1.1",
         },
         "AddVXLANRouteVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.31.1.1",
         },
         "AddVXLANRouteVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.32.1.1",
         },
         "AddVXLANRouteVM4" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[4].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.32.1.1",
         },
         "PingTest" => {
            Type           => "Traffic",
            ToolName       => "Ping",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],vm.[4].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            TestDuration   => "60",
         },
         "NetperfTest" => {
            Type           => "Traffic",
            ToolName       => "Netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],vm.[4].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            L4Protocol     => "tcp,udp",
            ExpectedResult => "ignore",
            TestDuration   => "60",
            ParallelSession => "yes",
         },
         'PoweroffDHCPServer' => {
            Type    => "DHCPServer",
            TestDHCPServer  => "dhcpserver.[1]",
            vmstate => "poweroff",
         },
         'PoweronDHCPServer' => {
            Type    => "DHCPServer",
            TestDHCPServer  => "dhcpserver.[1]",
            vmstate => "poweron",
         },
         'PoweronVM1' => {
            Type    => "VM",
            TestVM  => "vm.[1]",
            vmstate => "poweron",
         },
         'PoweronVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweron",
         },
         'PoweronVM3' => {
            Type    => "VM",
            TestVM  => "vm.[3]",
            vmstate => "poweron",
         },
         'PoweronVM4' => {
            Type    => "VM",
            TestVM  => "vm.[4]",
            vmstate => "poweron",
         },
         'PoweroffVM1' => {
            Type    => "VM",
            TestVM  => "vm.[1]",
            vmstate => "poweroff",
         },
         'PoweroffVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweroff",
         },
         'PoweroffVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweroff",
         },
         'AddvNICsOnVMs' => {
            Type   => "VM",
            TestVM => "vm.[1],vm.[2]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'AddvNICsOnOtherVMs' => {
            Type   => "VM",
            TestVM => "vm.[3],vm.[4]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'CreateNetworkScope' => CREATE_NETWORKSCOPE_ClusterSJC,
         'CreateVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            VirtualWire       => {
               "[1]" => {
                  name               => "AutoGenerate",
                  tenantid           => "1",
               },
               "[2]" => {
                  name               => "AutoGenerate",
                  tenantid           => "2",
               },
               "[3]" => {
                  name               => "AutoGenerate",
                  tenantid           => "3",
               },
            },
         },
         'DeleteVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-3]",
         },
      },
   },

#case 3
'OneRelayServerFourRelayAgents' => {
      Category         => 'NSX',
      Component        => 'DHCP RELAY',
      TestName         => "OneRelayServerFourRelayAgents",
      Version          => "2" ,
      Tags             => "RunOnCAT",
      Summary          => "Verify relay works with one relay server and one relay agent",
      TestbedSpec      => $TDS::NSX::Networking::VirtualRouting::TestbedSpec::OneVC_OneDC_OneVDS_TwoCluster_ThreeHost_TenVMs,
      'WORKLOADS' => {
         Sequence => [
                       ['CreateNetworkScope'],
                       ['CreateVirtualWires'],

                       ['AddvNICsOnVMsSet1'],
                       ['AddvNICsOnVMsSet2'],
                       ['AddvNICsOnVMsSet3'],
                       ['AddvNICsOnVMsSet4'],
                       ['PoweronVM1','PoweronVM2',
                       'PoweronVM3','PoweronVM4',
                       'PoweronVM5','PoweronVM6',
                       'PoweronVM7','PoweronVM8'],
                       ['MakeSurevNICConnected'],
                       ['DeployEdge1'],
                       ['DeployEdge2'],
                       ['CreateVXLANLIF1VDR1'],
                       ['CreateVXLANLIF2VDR1'],
                       ['CreateVXLANLIF1VDR2'],
                       ['CreateVXLANLIF2VDR2'],
                       ['CreateVXLANLIF3VDR1'],
                       ['CreateVXLANLIF3VDR2'],

                       # DHCPRelay test server configuration for VDR1
                       ['PoweronDHCPServer'],
                       ['AddvNICOnDHCPserver'],
                       ['SetVXLANIPDHCPServer'],
                       ['SetVXLANRouteDHCPServer'],
                       ['SetupDHCPServer'],
                       ['EnableDHCPServerOninterfaces'],
                       ['SetLocalSubnetWithoutRangeOnDHCPServer'],
                       ['SetDynamicBindingDHCPServer'],
                       ['SetDynamicBinding1DHCPServer'],
                       ['SetStaticBindingDHCP'],
                       ['SetStaticBinding1DHCP'],
                       ['RestartDHCPServer1'],

                       # ## DHCPRelay configuration on the VDR
                       ['ConfigureDHCPRelayForVDR1'],
                       ['RunDHClientOnVM1'],
                       ['RunDHClientOnVM2'],
                       ['RunDHClientOnVM3'],
                       ['RunDHClientOnVM4'],

                       # verification workloads
                       ## Verify vnic ip workloads are blocked due to PR 1318542
                       #  ['VerifyVnicIPVM1'],
                       #  ['VerifyVnicIPVM2'],
                       #  ['VerifyVnicIPVM3'],
                       #  ['VerifyVnicIPVM4'],
                       ['AddVXLANRouteVM1',
                        'AddVXLANRouteVM2',
                        'AddVXLANRouteVM3',
                        'AddVXLANRouteVM4'],
                       ['PingTestVDR1'],
                       ['NetperfTestVDR1'],

                       #DHCP server configuration for VDR2
                       ['PlaceDHCPServerOnvWire6'],
                       ['SetVXLANIP1DHCPServer'],
                       ['SetVXLANRoute1DHCPServer'],
                       ['SetupDHCPServer'],
                       ['EnableDHCPServerOninterfaces'],
                       ['SetLocalSubnet1WithoutRangeOnDHCPServer'],
                       ['SetDynamicBinding2DHCPServer'],
                       ['SetDynamicBinding3DHCPServer'],
                       ['SetStaticBinding2DHCP'],
                       ['SetStaticBinding3DHCP'],
                       ['RestartDHCPServer1'],

                       ['ConfigureDHCPRelayForVDR2'],
                       ['RunDHClientOnVM5'],
                       ['RunDHClientOnVM6'],
                       ['RunDHClientOnVM7'],
                       ['RunDHClientOnVM8'],
                       #DHCPRelay verification workloads
                       # Verify vnic ip workloads are blocked due to PR 1318542
                       #['VerifyVnicIPVM5'],
                       #['VerifyVnicIPVM6'],
                       #['VerifyVnicIPVM7'],
                       #['VerifyVnicIPVM8'],
                       ['AddVXLANRouteVM5',
                        'AddVXLANRouteVM6',
                        'AddVXLANRouteVM7',
                        'AddVXLANRouteVM8'],
                       ['PingTestVDR2'],
                       ['NetperfTestVDR2'],
                     ],
         ExitSequence => [
                          ['DeleteEdges'],
                          ['RemovevNICFromVM1'],
                          ['RemovevNICFromVM2'],
                          ['RemovevNICFromVM3'],
                          ['RemovevNICFromVM4'],
                          ['RemovevNICFromVM5'],
                          ['RemovevNICFromVM6'],
                          ['RemovevNICFromVM7'],
                          ['RemovevNICFromVM8'],
                          ['RemovevNICFromDHCPServer'],
                          ['Delete_All_VirtualWires'],
                          ['DeleteNetworkScope'],
                         ],
         'DeleteController' => DELETE_ALL_CONTROLLERS,
         'DeleteNetworkScope' => DELETE_ALL_NETWORKSCOPES,
         'Delete_All_VirtualWires' => DELETE_ALL_VIRTUALWIRES,
         'RemovevNICFromDHCPServer' => {
            Type       => "DHCPServer",
            TestDHCPServer     => "dhcpserver.[1]",
            deletevnic => "dhcpserver.[1].vnic.[1]",
         },
         'PlaceDHCPServerOnvWire6' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "dhcpserver.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[6]",
         },
         'MakeSurevNICConnected' => {
            Type           => "NetAdapter",
            reconfigure    => "true",
            testadapter    => "vm.[1-8].vnic.[1]",
            connected      => 1,
            startconnected => 1,
         },
         'VerifyVnicIPVM1' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[1].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.31.1.10-172.31.1.50",
            },
         },
         'VerifyVnicIPVM2' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[2].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.31.1.10-172.31.1.50",
            },
         },
         'VerifyVnicIPVM3' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[3].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.32.1.10-172.32.1.50",
            },
         },
         'VerifyVnicIPVM4' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[4].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.32.1.10-172.32.1.50",
            },
         },
         'VerifyVnicIPVM5' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[5].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.33.1.10-172.33.1.50",
            },
         },
         'VerifyVnicIPVM6' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[6].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.33.1.10-172.33.1.50",
            },
         },
         'VerifyVnicIPVM7' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[7].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.34.1.10-172.34.1.50",
            },
         },
         'VerifyVnicIPVM8' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[8].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.34.1.10-172.34.1.50",
            },
         },
         'ConfigureDHCPRelayForVDR1' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
              'dhcprelay' => {
                   '[1]' => {
                       'ip_addresses' => ["172.35.1.5"],
                       'relayagent' => 'vsm.[1].vse.[1].lif.[1-2]'
                      },
                 },
          },
         'ConfigureDHCPRelayForVDR2' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[2]",
              'dhcprelay' => {
                   '[1]' => {
                       'ip_addresses' => ["172.36.1.5"],
                       'relayagent' => 'vsm.[1].vse.[2].lif.[1-2]'
                      },
                 },
          },
         'SetDynamicBindingDHCPServer' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.31.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.31.1.2-172.31.1.50",
               option_routers => "172.31.1.1",
            },
         },
         'SetDynamicBinding1DHCPServer' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.32.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.32.1.2-172.32.1.50",
               option_routers => "172.32.1.1",
            },
         },
         'SetDynamicBinding2DHCPServer' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.33.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.33.1.2-172.33.1.50",
               option_routers => "172.33.1.1",
            },
         },
         'SetDynamicBinding3DHCPServer' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.34.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.34.1.2-172.34.1.50",
               option_routers => "172.34.1.1",
            },
         },
         'SetDynamicBindingDHCPServer2' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.32.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.33.1.2-172.33.1.50",
               option_routers => "172.33.1.1",
            },
         },
         'SetDynamicBinding1DHCPServer2' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.32.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.34.1.2-172.34.1.50",
               option_routers => "172.34.1.1",
            },
         },
         "SetLocalSubnetWithoutRangeOnDHCPServer" => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.35.0.0",
               netmask => "255.255.0.0",
            },
         },
         "SetLocalSubnet1WithoutRangeOnDHCPServer" => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.36.0.0",
               netmask => "255.255.0.0",
            },
         },
         "SetLocalSubnetWithoutRangeOnDHCPServer2" => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.36.0.0",
               netmask => "255.255.0.0",
            },
         },
         'RestartDHCPServer1'  => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            restart_dhcp_server => {},
          },

         'RestartDHCPServer2'  => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            restart_dhcp_server => {},
          },

         'SetStaticBindingDHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'static',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               adapter_mac => 'vm.[2].vnic.[1]',
               #adapter_mac => 'dhcpserver.[1].vnic.[1]',
               host_name => 'host2',
               adapter_ip  => "172.31.1.100",
            },
         },
         'SetStaticBinding1DHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'static',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               adapter_mac => 'vm.[4].vnic.[1]',
               #adapter_mac => 'dhcpserver.[1].vnic.[1]',
               host_name => 'host3',
               adapter_ip  => "172.32.1.100",
            },
         },
         'SetStaticBinding2DHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'static',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               adapter_mac => 'vm.[6].vnic.[1]',
               #adapter_mac => 'dhcpserver.[1].vnic.[1]',
               host_name => 'host4',
               adapter_ip  => "172.33.1.100",
            },
         },
         'SetStaticBinding3DHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'static',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               adapter_mac => 'vm.[8].vnic.[1]',
               #adapter_mac => 'dhcpserver.[1].vnic.[1]',
               host_name => 'host5',
               adapter_ip  => "172.34.1.100",
            },
         },
          'EnableDHCPServerOninterfaces' => {
             Type    => "DHCPServer",
             TestDHCPServer => "dhcpserver.[1]",
             enable_dhcp_server_on_interfaces => {
                adapter_interface => 'dhcpserver.[1].vnic.[1]',
            },
         },

          'EnableDHCPServer2Oninterfaces' => {
             Type    => "DHCPServer",
             TestDHCPServer => "dhcpserver.[2]",
             enable_dhcp_server_on_interfaces => {
                adapter_interface => 'dhcpserver.[2].vnic.[1]',
            },
         },

         'AddvNICOnDHCPserver' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[5]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'AddvNICOnDHCPserver2' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[6]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'SetupDHCPServer' => {
            Type    => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            unconfigure_dhcp_server => {
            },
         },
         'SetupDHCPServer2' => {
            Type    => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            unconfigure_dhcp_server => {
            },
         },
         'RemovevNICFromVM1' => {
            Type       => "VM",
            TestVM     => "vm.[1]",
            deletevnic => "vm.[1].vnic.[1]",
         },
         'RemovevNICFromVM2' => {
            Type       => "VM",
            TestVM     => "vm.[2]",
            deletevnic => "vm.[2].vnic.[1]",
         },
         'RemovevNICFromVM3' => {
            Type       => "VM",
            TestVM     => "vm.[3]",
            deletevnic => "vm.[3].vnic.[1]",
         },
         'RemovevNICFromVM4' => {
            Type       => "VM",
            TestVM     => "vm.[4]",
            deletevnic => "vm.[4].vnic.[1]",
         },
         'RemovevNICFromVM5' => {
            Type       => "VM",
            TestVM     => "vm.[5]",
            deletevnic => "vm.[5].vnic.[1]",
         },
         'RemovevNICFromVM6' => {
            Type       => "VM",
            TestVM     => "vm.[6]",
            deletevnic => "vm.[6].vnic.[1]",
         },
         'RemovevNICFromVM7' => {
            Type       => "VM",
            TestVM     => "vm.[7]",
            deletevnic => "vm.[7].vnic.[1]",
         },
         'RemovevNICFromVM8' => {
            Type       => "VM",
            TestVM     => "vm.[8]",
            deletevnic => "vm.[8].vnic.[1]",
         },
         'PlaceVM1OnvWire1' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
         },
         'PlaceVM2OnvWire2' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[2].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
         },
         'PlaceVM3OnvWire2' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
         },
         'PlaceVM1OnvWire3' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[3]",
         },
         "DeployEdge1"   => {
            Type    => "NSX",
            TestNSX => "vsm.[1]",
            vse => {
               '[1]' => {
                  name          => "Edge-1",
                  resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                  datacenter    => "vc.[1].datacenter.[1]",
                  host          => "host.[3]", # To pick datastore
                  portgroup     => "vc.[1].dvportgroup.[1]",
                  primaryaddress => "10.10.10.11",
                  subnetmask     => "255.255.255.0",
               },
            },
         },
         "DeployEdge2"   => {
            Type    => "NSX",
            TestNSX => "vsm.[1]",
            vse => {
               '[2]' => {
                  name          => "Edge-2",
                  resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                  datacenter    => "vc.[1].datacenter.[1]",
                  host          => "host.[3]", # To pick datastore
                  portgroup     => "vc.[1].dvportgroup.[1]",
                  primaryaddress => "10.10.10.12",
                  subnetmask     => "255.255.255.0",
               },
            },
         },
         "DeleteEdges" => DELETE_ALL_EDGES,
         'CreateVXLANLIF1VDR1' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[1]'   => {
                  name        => "lif-vwire1-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.31.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF2VDR1' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[2]'   => {
                  name        => "lif-vwire2-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.32.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF1VDR2' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[2]",
            lif => {
               '[1]'   => {
                  name        => "lif-vwire1-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[3]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.33.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF2VDR2' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[2]",
            lif => {
               '[2]'   => {
                  name        => "lif-vwire2-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[4]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.34.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF3VDR1' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[3]'   => {
                  name        => "lif-vwire3-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[5]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.35.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF3VDR2' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[2]",
            lif => {
               '[3]'   => {
                  name        => "lif-vwire3-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[6]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.36.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         "AddVXLANRouteVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.31.1.1",
         },
         "AddVXLANRouteVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.31.1.1",
         },
         "AddVXLANRouteVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.32.1.1",
         },
         "AddVXLANRouteVM4" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[4].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.32.1.1",
         },
         "AddVXLANRouteVM5" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[5].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.33.1.1",
         },
         "AddVXLANRouteVM6" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[6].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.33.1.1",
         },
         "AddVXLANRouteVM7" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[7].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.34.1.1",
         },
         "AddVXLANRouteVM8" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[8].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.34.1.1",
         },
         "SetVXLANIPDHCPServer" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            ipv4       => '172.35.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIP1DHCPServer" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            ipv4       => '172.36.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPDHCPServer2" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[2].vnic.[1]",
            ipv4       => '172.36.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANRouteDHCPServer" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.35.1.1",
         },
         "SetVXLANRoute1DHCPServer" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.36.1.1",
         },
         "RunDHClientOnVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM4" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[4].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM5" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[5].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM6" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[6].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM7" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[7].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM8" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[8].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM4" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[4].vnic.[1]",
            ipv4       => "dhcp",
         },
         "SetVXLANIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => '172.31.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => '172.32.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM2SamevWire" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => '172.31.1.6',
            netmask    => "255.255.0.0",
         },
         "PingTestVDR1" => {
            Type           => "Traffic",
            ToolName       => "Ping",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],vm.[4].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            TestDuration   => "60",
         },
         "NetperfTestVDR1" => {
            Type           => "Traffic",
            ToolName       => "Netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],vm.[4].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            L4Protocol     => "tcp,udp",
            ExpectedResult => "ignore",
            TestDuration   => "60",
            ParallelSession => "yes",
         },
         "PingTestVDR2" => {
            Type           => "Traffic",
            ToolName       => "Ping",
            TestAdapter    => "vm.[5].vnic.[1]",
            SupportAdapter => "vm.[6].vnic.[1],vm.[7].vnic.[1],vm.[8].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            TestDuration   => "60",
         },
         "NetperfTestVDR2" => {
            Type           => "Traffic",
            ToolName       => "Netperf",
            TestAdapter    => "vm.[5].vnic.[1]",
            SupportAdapter => "vm.[6].vnic.[1],vm.[7].vnic.[1],vm.[8].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            L4Protocol     => "tcp,udp",
            ExpectedResult => "ignore",
            TestDuration   => "60",
            ParallelSession => "yes",
         },
         'PoweroffDHCPServer' => {
            Type    => "DHCPServer",
            TestDHCPServer  => "dhcpserver.[1]",
            vmstate => "poweroff",
         },
         'PoweronDHCPServer' => {
            Type    => "DHCPServer",
            TestDHCPServer  => "dhcpserver.[1]",
            vmstate => "poweron",
         },
         'PoweronDHCPServer2' => {
            Type    => "DHCPServer",
            TestDHCPServer  => "dhcpserver.[2]",
            vmstate => "poweron",
         },
         'PoweronVM1' => {
            Type    => "VM",
            TestVM  => "vm.[1]",
            vmstate => "poweron",
         },
         'PoweronVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweron",
         },
         'PoweronVM3' => {
            Type    => "VM",
            TestVM  => "vm.[3]",
            vmstate => "poweron",
         },
         'PoweronVM4' => {
            Type    => "VM",
            TestVM  => "vm.[4]",
            vmstate => "poweron",
         },
         'PoweronVM5' => {
            Type    => "VM",
            TestVM  => "vm.[5]",
            vmstate => "poweron",
         },
         'PoweronVM6' => {
            Type    => "VM",
            TestVM  => "vm.[6]",
            vmstate => "poweron",
         },
         'PoweronVM7' => {
            Type    => "VM",
            TestVM  => "vm.[7]",
            vmstate => "poweron",
         },
         'PoweronVM8' => {
            Type    => "VM",
            TestVM  => "vm.[8]",
            vmstate => "poweron",
         },
         'PoweroffVM1' => {
            Type    => "VM",
            TestVM  => "vm.[1]",
            vmstate => "poweroff",
         },
         'PoweroffVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweroff",
         },
         'PoweroffVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweroff",
         },
         'AddvNICsOnVMsSet1' => {
            Type   => "VM",
            TestVM => "vm.[1],vm.[2]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'AddvNICsOnVMsSet2' => {
            Type   => "VM",
            TestVM => "vm.[3],vm.[4]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'AddvNICsOnVMsSet3' => {
            Type   => "VM",
            TestVM => "vm.[5],vm.[6]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[3]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'AddvNICsOnVMsSet4' => {
            Type   => "VM",
            TestVM => "vm.[7],vm.[8]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[4]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'CreateNetworkScope' => CREATE_NETWORKSCOPE_ClusterSJC,
         'CreateVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            VirtualWire       => {
               "[1]" => {
                  name               => "AutoGenerate",
                  tenantid           => "1",
               },
               "[2]" => {
                  name               => "AutoGenerate",
                  tenantid           => "2",
               },
               "[3]" => {
                  name               => "AutoGenerate",
                  tenantid           => "3",
               },
               "[4]" => {
                  name               => "AutoGenerate",
                  tenantid           => "4",
               },
               "[5]" => {
                  name               => "AutoGenerate",
                  tenantid           => "5",
               },
               "[6]" => {
                  name               => "AutoGenerate",
                  tenantid           => "6",
               },
            },
         },
         'DeleteVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-3]",
         },
      },
   },

##case 4
'TwoRelayServerFourRelayAgents' => {
      Category         => 'NSX',
      Component        => 'DHCP RELAY',
      TestName         => "TwoRelayServerFourRelayAgents",
      Version          => "2" ,
      Tags             => "RunOnCAT",
      Summary          => "Verify relay works with two relay servers and four relay agents",
      TestbedSpec      => $TDS::NSX::Networking::VirtualRouting::TestbedSpec::OneVC_OneDC_OneVDS_TwoCluster_ThreeHost_TenVMs,
      'WORKLOADS' => {
         Sequence => [
                       ['CreateNetworkScope'],
                       ['CreateVirtualWires'],

                       ['AddvNICsOnVMsSet1'],
                       ['AddvNICsOnVMsSet2'],
                       ['AddvNICsOnVMsSet3'],
                       ['AddvNICsOnVMsSet4'],
                       ['PoweronVM1','PoweronVM2',
                       'PoweronVM3','PoweronVM4',
                       'PoweronVM5','PoweronVM6',
                       'PoweronVM7','PoweronVM8'],
                       ['MakeSurevNICConnected'],
                       ['DeployEdge'],
                       ['CreateVXLANLIF1'],
                       ['CreateVXLANLIF2'],
                       ['CreateVXLANLIF3'],
                       ['CreateVXLANLIF4'],
                       ['CreateVXLANLIF5'],
                       ['CreateVXLANLIF6'],

                       # DHCPRelay test server configuration
                       ['PoweronDHCPServer1'],
                       ['AddvNICOnDHCPserver1'],
                       ['SetVXLANIPDHCPServer1'],
                       ['SetVXLANRouteDHCPServer1'],
                       ['SetupDHCPServer1'],
                       ['EnableDHCPServer1Oninterfaces'],
                       ['SetLocalSubnetWithoutRangeOnDHCPServer1'],
                       ['SetDynamicBindingDHCPServer1'],
                       ['SetDynamicBinding1DHCPServer1'],
                       ['RestartDHCPServer1'],

                       ['PoweronDHCPServer2'],
                       ['AddvNICOnDHCPserver2'],
                       ['SetVXLANIPDHCPServer2'],
                       ['SetVXLANRouteDHCPServer2'],
                       ['SetupDHCPServer2'],
                       ['EnableDHCPServer2Oninterfaces'],
                       ['SetLocalSubnetWithoutRangeOnDHCPServer2'],
                       ['SetDynamicBindingDHCPServer2'],
                       ['SetDynamicBinding1DHCPServer2'],
                       ['RestartDHCPServer2'],

                       # ## DHCPRelay configuration on the VDR
                       ['ConfigureDHCPRelayForVDR'],
                       ['RunDHClientOnVM1'],
                       ['RunDHClientOnVM2'],
                       ['RunDHClientOnVM3'],
                       ['RunDHClientOnVM4'],
                       ['RunDHClientOnVM5'],
                       ['RunDHClientOnVM6'],
                       ['RunDHClientOnVM7'],
                       ['RunDHClientOnVM8'],

                       # verification workloads
                       ## Verify vnic ip workloads are blocked due to PR 1318542
                       # ['VerifyVnicIPVM1'],
                       # ['VerifyVnicIPVM2'],
                       # ['VerifyVnicIPVM3'],
                       # ['VerifyVnicIPVM4'],
                       # ['VerifyVnicIPVM5'],
                       # ['VerifyVnicIPVM6'],
                       # ['VerifyVnicIPVM7'],
                       # ['VerifyVnicIPVM8'],
                       ['AddVXLANRouteVM1',
                        'AddVXLANRouteVM2',
                        'AddVXLANRouteVM3',
                        'AddVXLANRouteVM4'],
                       ['AddVXLANRouteVM5',
                        'AddVXLANRouteVM6',
                        'AddVXLANRouteVM7',
                        'AddVXLANRouteVM8'],
                       ['PingTest'],
                       ['NetperfTest'],
                     ],
         ExitSequence => [
                             ['DeleteEdges'],
                             ['RemovevNICFromVM1'],
                             ['RemovevNICFromVM2'],
                             ['RemovevNICFromVM3'],
                             ['RemovevNICFromVM4'],
                             ['RemovevNICFromVM5'],
                             ['RemovevNICFromVM6'],
                             ['RemovevNICFromVM7'],
                             ['RemovevNICFromVM8'],
                             ['RemovevNICFromDHCPServer1'],
                             ['RemovevNICFromDHCPServer2'],
                             ['Delete_All_VirtualWires'],
                             ['DeleteNetworkScope'],
                          ],
         'SetSegmentIDRange' => SET_SEGMENTID_RANGE,
         'SetMulticastRange' => SET_MULTICAST_RANGE,
         "DeployFirstController" => DEPLOY_FIRSTCONTROLLER,
         'DeleteController' => DELETE_ALL_CONTROLLERS,
         'DeleteNetworkScope' => DELETE_ALL_NETWORKSCOPES,
         'Install_Config_ClusterSJC' => INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC_VDS1,
         'Install_Config_ClusterSJC2' => INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC2_VDS1,
         'Delete_All_VirtualWires' => DELETE_ALL_VIRTUALWIRES,
         'Uninstall_VDNCluster' => UNINSTALL_UNCONFIGURE_ALL_VDNCLUSTER,
         "AddVXLANRouteVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.31.1.1",
         },
         "AddVXLANRouteVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.31.1.1",
         },
         "AddVXLANRouteVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.32.1.1",
         },
         "AddVXLANRouteVM4" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[4].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.32.1.1",
         },
         "AddVXLANRouteVM5" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[5].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.33.1.1",
         },
         "AddVXLANRouteVM6" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[6].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.33.1.1",
         },
         "AddVXLANRouteVM7" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[7].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.34.1.1",
         },
         "AddVXLANRouteVM8" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[8].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.34.1.1",
         },
         'RemovevNICFromDHCPServer1' => {
            Type       => "DHCPServer",
            TestDHCPServer     => "dhcpserver.[1]",
            deletevnic => "dhcpserver.[1].vnic.[1]",
         },
         'RemovevNICFromDHCPServer2' => {
            Type       => "DHCPServer",
            TestDHCPServer     => "dhcpserver.[2]",
            deletevnic => "dhcpserver.[2].vnic.[1]",
         },
         'MakeSurevNICConnected' => {
            Type           => "NetAdapter",
            reconfigure    => "true",
            testadapter    => "vm.[1-8].vnic.[1]",
            connected      => 1,
            startconnected => 1,
         },
         'VerifyVnicIPVM1' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[1].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.31.1.10-172.31.1.50",
            },
         },
         'VerifyVnicIPVM2' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[2].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.31.1.10-172.31.1.50",
            },
         },
         'VerifyVnicIPVM3' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[3].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.32.1.10-172.32.1.50",
            },
         },
         'VerifyVnicIPVM4' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[4].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.32.1.10-172.32.1.50",
            },
         },
         'VerifyVnicIPVM5' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[5].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.33.1.10-172.33.1.50",
            },
         },
         'VerifyVnicIPVM6' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[6].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.33.1.10-172.33.1.50",
            },
         },
         'VerifyVnicIPVM7' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[7].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.34.1.10-172.34.1.50",
            },
         },
         'VerifyVnicIPVM8' => {
             Type => 'NetAdapter',
             TestAdapter => 'vm.[8].vnic.[1]',
             read =>  {
               'ipaddress[?]ip_range' => "172.34.1.10-172.34.1.50",
            },
         },
         'ConfigureDHCPRelayForVDR' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
              'dhcprelay' => {
                   '[1]' => {
                       'ip_addresses' => ["172.35.1.5","172.36.1.5"],
                       'relayagent' => 'vsm.[1].vse.[1].lif.[1-4]'
                      },
                 },
          },
         'SetDynamicBindingDHCPServer1' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               subnet => "172.31.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.31.1.2-172.31.1.50",
               option_routers => "172.31.1.1",
            },
         },
         'SetDynamicBinding1DHCPServer1' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               subnet => "172.32.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.32.1.2-172.32.1.50",
               option_routers => "172.32.1.1",
            },
         },
         'SetDynamicBindingDHCPServer2' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               subnet => "172.33.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.33.1.2-172.33.1.50",
               option_routers => "172.33.1.1",
            },
         },
         'SetDynamicBinding1DHCPServer2' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               subnet => "172.34.0.0",
               netmask => "255.255.0.0",
               ip_range   => "172.34.1.2-172.34.1.50",
               option_routers => "172.34.1.1",
            },
         },
         "SetLocalSubnetWithoutRangeOnDHCPServer1" => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.35.0.0",
               netmask => "255.255.0.0",
            },
         },
         "SetLocalSubnetWithoutRangeOnDHCPServer2" => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            configure_dhcp_server => {
               dhcp_type => 'dynamic',
               subnet => "172.36.0.0",
               netmask => "255.255.0.0",
            },
         },
         'RestartDHCPServer1'  => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            restart_dhcp_server => {},
          },

         'RestartDHCPServer2'  => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            restart_dhcp_server => {},
          },

         'SetStaticBindingDHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'static',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               adapter_mac => 'vm.[2].vnic.[1]',
               #adapter_mac => 'dhcpserver.[1].vnic.[1]',
               host_name => 'host2',
               adapter_ip  => "172.31.1.100",
            },
         },
         'SetStaticBinding1DHCP' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            configure_dhcp_server => {
               dhcp_type => 'static',
               # adapter_interface => 'dhcpserver.[1].vnic.[1-2]',
               adapter_mac => 'vm.[4].vnic.[1]',
               #adapter_mac => 'dhcpserver.[1].vnic.[1]',
               host_name => 'host3',
               adapter_ip  => "172.32.1.100",
            },
         },
          'EnableDHCPServer1Oninterfaces' => {
             Type    => "DHCPServer",
             TestDHCPServer => "dhcpserver.[1]",
             enable_dhcp_server_on_interfaces => {
                adapter_interface => 'dhcpserver.[1].vnic.[1]',
            },
         },

          'EnableDHCPServer2Oninterfaces' => {
             Type    => "DHCPServer",
             TestDHCPServer => "dhcpserver.[2]",
             enable_dhcp_server_on_interfaces => {
                adapter_interface => 'dhcpserver.[2].vnic.[1]',
            },
         },

         'AddvNICOnDHCPserver1' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[5]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'AddvNICOnDHCPserver2' => {
            Type   => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[6]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'SetupDHCPServer1' => {
            Type    => "DHCPServer",
            TestDHCPServer => "dhcpserver.[1]",
            unconfigure_dhcp_server => {
            },
         },
         'SetupDHCPServer2' => {
            Type    => "DHCPServer",
            TestDHCPServer => "dhcpserver.[2]",
            unconfigure_dhcp_server => {
            },
         },
         'RemovevNICFromVM1' => {
            Type       => "VM",
            TestVM     => "vm.[1]",
            deletevnic => "vm.[1].vnic.[1]",
         },
         'RemovevNICFromVM2' => {
            Type       => "VM",
            TestVM     => "vm.[2]",
            deletevnic => "vm.[2].vnic.[1]",
         },
         'RemovevNICFromVM3' => {
            Type       => "VM",
            TestVM     => "vm.[3]",
            deletevnic => "vm.[3].vnic.[1]",
         },
         'RemovevNICFromVM4' => {
            Type       => "VM",
            TestVM     => "vm.[4]",
            deletevnic => "vm.[4].vnic.[1]",
         },
         'RemovevNICFromVM5' => {
            Type       => "VM",
            TestVM     => "vm.[5]",
            deletevnic => "vm.[5].vnic.[1]",
         },
         'RemovevNICFromVM6' => {
            Type       => "VM",
            TestVM     => "vm.[6]",
            deletevnic => "vm.[6].vnic.[1]",
         },
         'RemovevNICFromVM7' => {
            Type       => "VM",
            TestVM     => "vm.[7]",
            deletevnic => "vm.[7].vnic.[1]",
         },
         'RemovevNICFromVM8' => {
            Type       => "VM",
            TestVM     => "vm.[8]",
            deletevnic => "vm.[8].vnic.[1]",
         },
         "Expand_TZ" => {
            Type  => "TransportZone",
            TestTransportZone   => "vsm.[1].networkscope.[1]",
            transportzoneaction => "expand",
            clusters            => "vc.[1].datacenter.[1].cluster.[3]",
         },
         'PlaceVM1OnvWire1' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
         },
         'PlaceVM2OnvWire2' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[2].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
         },
         'PlaceVM3OnvWire2' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
         },
         'PlaceVM1OnvWire3' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[3]",
         },
         'PlaceVM1OnVLAN16' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[2]",
         },
         'PlaceVM2OnVLAN17' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[2].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[3]",
         },
         'PlaceVM2OnVLAN21' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[2].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[4]",
         },
         "DeployEdge"   => {
            Type    => "NSX",
            TestNSX => "vsm.[1]",
            vse => {
               '[1]' => {
                  name          => "Edge-$$",
                  resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                  datacenter    => "vc.[1].datacenter.[1]",
                  host          => "host.[3]", # To pick datastore
                  portgroup     => "vc.[1].dvportgroup.[1]",
                  primaryaddress => "10.10.10.11",
                  subnetmask     => "255.255.255.0",
               },
            },
         },
         "DeleteEdges" => DELETE_ALL_EDGES,
         'CreateVXLANLIF1' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[1]'   => {
                  name        => "lif-vwire1-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.31.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF2' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[2]'   => {
                  name        => "lif-vwire2-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.32.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF3' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[3]'   => {
                  name        => "lif-vwire3-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[3]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.33.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF4' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[4]'   => {
                  name        => "lif-vwire4-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[4]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.34.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF5' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[5]'   => {
                  name        => "lif-vwire5-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[5]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.35.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         'CreateVXLANLIF6' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            lif => {
               '[6]'   => {
                  name        => "lif-vwire6-$$",
                  portgroup   => "vsm.[1].networkscope.[1].virtualwire.[6]",
                  type        => "internal",
                  connected   => 1,
                  addressgroup => [{addresstype => "primary",
                                    ipv4address => "172.36.1.1",
                                    netmask     => "255.255.0.0",}]
               },
            },
         },
         "SetVXLANIPDHCPServer1" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            ipv4       => '172.35.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPDHCPServer2" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[2].vnic.[1]",
            ipv4       => '172.36.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANRouteDHCPServer1" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.35.1.1",
         },
         "SetVXLANRouteDHCPServer2" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[2].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.36.1.1",
         },
         "RunDHClientOnVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM4" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[4].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM5" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[5].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM6" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[6].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM7" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[7].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM8" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[8].vnic.[1]",
            ipv4       => "dhcp",
         },
         "SetVXLANIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => '172.31.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => '172.32.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM2SamevWire" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => '172.31.1.6',
            netmask    => "255.255.0.0",
         },
         "SetVXLANBridgeIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "SetVLANBridgeIPVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => '172.21.1.6',
            netmask    => "255.255.0.0",
         },
         "SetVXLANRouteDHCPServer" => {
            Type       => "NetAdapter",
            Testadapter=> "dhcpserver.[1].vnic.[1]",
            netmask    => "255.0.0.0",
            route      => "add",
            network    => "172.0.0.0",
            gateway    => "172.32.1.1",
         },
         "RunDHClientOnVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => "dhcp",
         },
         "RunDHClientOnVM4" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[4].vnic.[1]",
            ipv4       => "dhcp",
         },
         "SetVXLANIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => '172.31.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM2" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => '172.32.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM2SamevWire" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[2].vnic.[1]",
            ipv4       => '172.31.1.6',
            netmask    => "255.255.0.0",
         },
         "SetVXLANBridgeIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "PingTest" => {
            Type           => "Traffic",
            ToolName       => "Ping",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],vm.[4].vnic.[1],".
                              "vm.[5].vnic.[1],vm.[6].vnic.[1],vm.[7].vnic.[1],".
                              "vm.[8].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            TestDuration   => "60",
         },
         "NetperfTest" => {
            Type           => "Traffic",
            ToolName       => "Netperf",
            TestAdapter    => "vm.[1].vnic.[1]",
            SupportAdapter => "vm.[2].vnic.[1],vm.[3].vnic.[1],vm.[4].vnic.[1],".
                              "vm.[5].vnic.[1],vm.[6].vnic.[1],vm.[7].vnic.[1],".
                              "vm.[8].vnic.[1]",
            NoofOutbound   => 1,
            NoofInbound    => 1,
            L4Protocol     => "tcp,udp",
            TestDuration   => "60",
            ExpectedResult => "ignore",
            ParallelSession => "yes",
         },
         'PoweroffDHCPServer' => {
            Type    => "DHCPServer",
            TestDHCPServer  => "dhcpserver.[1]",
            vmstate => "poweroff",
         },
         'PoweronDHCPServer1' => {
            Type    => "DHCPServer",
            TestDHCPServer  => "dhcpserver.[1]",
            vmstate => "poweron",
         },
         'PoweronDHCPServer2' => {
            Type    => "DHCPServer",
            TestDHCPServer  => "dhcpserver.[2]",
            vmstate => "poweron",
         },
         'PoweronVM1' => {
            Type    => "VM",
            TestVM  => "vm.[1]",
            vmstate => "poweron",
         },
         'PoweronVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweron",
         },
         'PoweronVM3' => {
            Type    => "VM",
            TestVM  => "vm.[3]",
            vmstate => "poweron",
         },
         'PoweronVM4' => {
            Type    => "VM",
            TestVM  => "vm.[4]",
            vmstate => "poweron",
         },
         'PoweronVM5' => {
            Type    => "VM",
            TestVM  => "vm.[5]",
            vmstate => "poweron",
         },
         'PoweronVM6' => {
            Type    => "VM",
            TestVM  => "vm.[6]",
            vmstate => "poweron",
         },
         'PoweronVM7' => {
            Type    => "VM",
            TestVM  => "vm.[7]",
            vmstate => "poweron",
         },
         'PoweronVM8' => {
            Type    => "VM",
            TestVM  => "vm.[8]",
            vmstate => "poweron",
         },
         'PoweroffVM1' => {
            Type    => "VM",
            TestVM  => "vm.[1]",
            vmstate => "poweroff",
         },
         'PoweroffVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweroff",
         },
         'PoweroffVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweroff",
         },
         'AddvNICsOnVMsSet1' => {
            Type   => "VM",
            TestVM => "vm.[1],vm.[2]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[1]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'AddvNICsOnVMsSet2' => {
            Type   => "VM",
            TestVM => "vm.[3],vm.[4]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[2]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'AddvNICsOnVMsSet3' => {
            Type   => "VM",
            TestVM => "vm.[5],vm.[6]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[3]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'AddvNICsOnVMsSet4' => {
            Type   => "VM",
            TestVM => "vm.[7],vm.[8]",
            vnic => {
               '[1]'   => {
                  driver            => "vmxnet3",
                  portgroup         => "vsm.[1].networkscope.[1].virtualwire.[4]",
                  connected         => 1,
                  startconnected    => 1,
                  allowguestcontrol => 1,
               },
            },
         },
         'CreateNetworkScope' => CREATE_NETWORKSCOPE_ClusterSJC,
         'CreateVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            VirtualWire       => {
               "[1]" => {
                  name               => "AutoGenerate",
                  tenantid           => "1",
               },
               "[2]" => {
                  name               => "AutoGenerate",
                  tenantid           => "2",
               },
               "[3]" => {
                  name               => "AutoGenerate",
                  tenantid           => "3",
               },
               "[4]" => {
                  name               => "AutoGenerate",
                  tenantid           => "4",
               },
               "[5]" => {
                  name               => "AutoGenerate",
                  tenantid           => "5",
               },
               "[6]" => {
                  name               => "AutoGenerate",
                  tenantid           => "6",
               },
            },
         },
         'GetVirtualWireID' => {
            Type            => "Switch",
            FindType            => "Switch",
            testvirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1]",
         },
         'DeleteVirtualWires' => {
            Type              => "TransportZone",
            TestTransportZone => "vsm.[1].networkscope.[1]",
            deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[1-3]",
         },
         'UnconfigureVXLAN' => {
            Type             => 'Cluster',
            testcluster      => "vsm.[1].vdncluster.[1]",
            vxlan            => "unconfigure",
         },
         "RebootHost" => {
            Type            => "Host",
            TestHost        => "host.[1]",
            reboot          => "yes",
         },
         "RebootHost2" => {
            Type            => "Host",
            TestHost        => "host.[2]",
            reboot          => "yes",
         },
         "RebootHost3" => {
            Type            => "Host",
            TestHost        => "host.[3]",
            reboot          => "yes",
         },
      },
   },
 );
}

##########################################################################
# new --
#       This is the constructor for DHCPRelay TDS
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
########################################################################

sub new
{
   my ($proto) = @_;
      # Below way of getting class name is to allow new class as well as
      # $class->new.  In new class, proto itself is class, and $class->new,
      # ref($class) return the class
      my $class = ref($proto) || $proto;
      my $self = $class->SUPER::new(\%Functional);
      return (bless($self, $class));
}

1;
