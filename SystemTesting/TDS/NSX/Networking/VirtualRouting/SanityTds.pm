#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::Networking::VirtualRouting::SanityTds;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
@ISA = qw(TDS::Main::VDNetMainTds);

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';
use TDS::NSX::Networking::VirtualRouting::TestbedSpec;

{
%Functional = (
   'RoutingBridgingSanity_DifferentHost' => {
      Category         => 'NSX',
      Component        => 'network vDR',
      TestName         => "JumboSanityTest_DifferentHost",
      Version          => "2" ,
      Tags             => "RunOnCAT",
      Summary          => "This is the vdr datapath sanity testcase for different hosts ",
      TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_FourDVPG_ThreeHost_ThreeVM,
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
                      ['CreateVLANLIF3'],
                      ['CreateVLANLIF4'],
                      ['BridgevWire3ToVLAN21'],

                      ########   Different Host   ########
                      ['PoweronVM3'],
                      # VXLAN test - VMs on same vWire
                      ['PlaceVM1OnvWire1','PlaceVM3OnvWire1'],
                      ['SetVXLANIPVM1','SetVXLANIPVM3SamevWire'],

                      # VDR test - VXLAN to VXLAN routing
                      ['PlaceVM1OnvWire1','PlaceVM3OnvWire2'],
                      ['SetVXLANIPVM1','SetVXLANIPVM3'],
                      ['AddVXLANRouteVM1','AddVXLANRouteVM3'],

                      # VDR test - VLAN to VLAN routing
                      ['PlaceVM1OnVLAN16','PlaceVM3OnVLAN17'],
                      ['SetVLANIPVM1','SetVLANIPVM3'],
                      ['AddVLANRouteVM1','AddVLANRouteVM3'],


                      # VDR test - Briding
                      ['PlaceVM1OnvWire3'],
                      ['PlaceVM3OnVLAN21'],
                      ['SetVXLANBridgeIPVM1','SetVLANBridgeIPVM3'],
                     ],
         ExitSequence => [
                       ['DeleteEdges'],
                       ['RemovevNICFromVM1'],
                       ['RemovevNICFromVM2'],
                       ['RemovevNICFromVM3'],
                       ['Delete_All_VirtualWires'],
                       ['DeleteNetworkScope'],
                      ],
         'DeleteNetworkScope' => DELETE_ALL_NETWORKSCOPES,
         'Delete_All_VirtualWires' => DELETE_ALL_VIRTUALWIRES,
         'PlaceVM1OnvWire1' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[1].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
         },
         'PlaceVM3OnvWire2' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[2]",
         },
         'PlaceVM3OnvWire1' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vsm.[1].networkscope.[1].virtualwire.[1]",
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
         'PlaceVM3OnVLAN17' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
            portgroup   => "vc.[1].dvportgroup.[3]",
         },
         'PlaceVM3OnVLAN21' => {
            Type        => "NetAdapter",
            reconfigure => "true",
            testadapter => "vm.[3].vnic.[1]",
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
         'BridgevWire3ToVLAN21' => {
            Type   => "VM",
            TestVM => "vsm.[1].vse.[1]",
            bridge => {
               '[1]'   => {
                  name        => "bridge-1-$$",
                  virtualwire => "vsm.[1].networkscope.[1].virtualwire.[3]",
                  portgroup   => "vc.[1].dvportgroup.[4]",
               },
            },
         },
         "SetVLANIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "SetVLANIPVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
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
         "AddVLANRouteVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.16.0.0,172.31.0.0,172.32.0.0",
            gateway    => "172.17.1.1",
         },
         "SetVXLANIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => '172.31.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM3SamevWire" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => '172.31.1.15',
            netmask    => "255.255.0.0",
         },
         "SetVXLANIPVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => '172.32.1.5',
            netmask    => "255.255.0.0",
         },
         "SetVXLANBridgeIPVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "SetVLANBridgeIPVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            ipv4       => 'dhcp',
         },
         "AddVXLANRouteVM1" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[1].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.32.0.0,172.16.0.0,172.17.0.0",
            gateway    => "172.31.1.1",
         },
         "AddVXLANRouteVM3" => {
            Type       => "NetAdapter",
            Testadapter=> "vm.[3].vnic.[1]",
            netmask    => "255.255.0.0",
            route      => "add",
            network    => "172.31.0.0,172.16.0.0,172.17.0.0",
            gateway    => "172.32.1.1",
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
         'PoweroffVM3' => {
            Type    => "VM",
            TestVM  => "vm.[3]",
            vmstate => "poweroff",
         },
         'PoweroffVM2' => {
            Type    => "VM",
            TestVM  => "vm.[2]",
            vmstate => "poweroff",
         },
         'AddvNICsOnVMs' => {
            Type   => "VM",
            TestVM => "vm.[1],vm.[2],vm.[3]",
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
         'MakeSurevNICConnected' => {
            Type           => "NetAdapter",
            reconfigure    => "true",
            testadapter    => "vm.[1-2].vnic.[1]",
            connected      => 1,
            startconnected => 1,
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
