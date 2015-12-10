#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::Networking::VirtualRouting::ScalabilityTds;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';

@ISA = qw(TDS::Main::VDNetMainTds);
{
   %Scalability = (
     'Create30KvWires' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "PylibPreCheckin",
         Version          => "2" ,
         Tags             => "precheckin",
         Summary          => "scale test with 30K vwires",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_TwoHost_TwoCluster,
         'WORKLOADS' => {
            Sequence => [
                         ['DeployFirstController'],
                         ['SetSegmentIDRange'],
                         ['SetMulticastRange'],
                         ['PrepCluster'],
                         ['CreateNetworkScope'],
                         ['Create100VirtualWires'],
                         ['Create1000VirtualWires'],
                         ['Create10000VirtualWires'],
                         ['Create20000VirtualWires'],
                         ['Create30000VirtualWires'],
                        ],
            ExitSequence => [
                             ['DeleteVirtualWires'],
                             ['DeleteNetworkScope'],
                             ['UnprepCluster'],
                            ],
            "DeployFirstController"   => {
               Type       => "NSX",
               TestNSX    => "vsm.[1]",
               vxlancontroller  => {
                  '[1]' => {
                     name         => "AutoGenerate",
                     firstnodeofcluster => "true",
                     ippool       => "vsm.[1].ippool.[1]",
                     resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
                     host         => "host.[1]",
                  },
               },
            },
            'SetSegmentIDRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               Segmentidrange => {
                  '[1]' => {
                     name  => "AutoGenerate",
                     begin => "10000",
                     end   => "99000",
                  },
               },
            },
            'SetMulticastRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               Multicastiprange => {
                  '[1]' => {
                     name  => "AutoGenerate",
                     begin => "239.0.0.100",
                     end   => "239.254.254.254",
                  },
               },
            },
            'PrepCluster' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     vibs         => "install",
                     vxlan        => "Configure",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => "19",
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "LACP_V2",
                  },
               },
            },
            'CreateNetworkScope' => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1-$$",
                     clusters     => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'CreateTempVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               maxtimeout        => "108000",
               VirtualWire       => {
                  "[4-10]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'Create100VirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               maxtimeout        => "108000",
               VirtualWire       => {
                  "[11-100]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'Create1000VirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               maxtimeout        => "108000",
               VirtualWire       => {
                  "[101-1000]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'Create10000VirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               maxtimeout        => "118000",
               VirtualWire       => {
                  "[1001-10000]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'Create20000VirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               maxtimeout        => "308000",
               VirtualWire       => {
                  "[10001-20000]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'Create30000VirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               maxtimeout        => "308000",
               VirtualWire       => {
                  "[20001-30000]" => {
                     name     => "AutoGenerate",
                     tenantid => "AutoGenerate",
                  },
               },
            },
            'DeleteNetworkScope'  => {
               Type               => 'NSX',
               TestNSX            => "vsm.[1]",
               deletenetworkscope => "vsm.[1].networkscope.[-1]",
             },
            'DeleteVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[-1]",
            },
            'DeleteSegmentIDRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteSegmentidrange => "vsm.[1].segmentidrange.[-1]",
            },
            'DeleteMulticastRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deleteMulticastiprange => "vsm.[1].multicastiprange.[-1]",
            },
         },
      },
      'DeployMultipleControllers' => {
         Category         => 'NSX',
         Component        => 'network vDR',
         TestName         => "JumboSanityTest",
         Version          => "2" ,
         Tags             => "RunOnCAT",
         Summary          => "vdr datapath sanity test for scale by deploying multiple controllers",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_TwoHost_TwoCluster,
         'WORKLOADS' => {
            Sequence => [
                         ['DeployFirstController'],
                         ['DeployMultipleController'],
                        ],
            ExitSequence => [
                             ['DeleteController'],
                            ],

            "DeployFirstController"   => {
               Type       => "NSX",
               TestNSX    => "vsm.[1]",
               vxlancontroller  => {
                  '[1]' => {
                     name         => "AutoGenerate",
                     firstnodeofcluster => "true",
                     ippool       => "vsm.[1].ippool.[1]",
                     resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
                     host         => "host.[1]",
                  },
               },
            },
            "DeployMultipleController"   => {
               Type       => "NSX",
               TestNSX    => "vsm.[1]",
               vxlancontroller  => {
                  '[2-3]' => {
                     name         => "AutoGenerate",
                     firstnodeofcluster => "false",

                     ippool       => "vsm.[1].ippool.[1]",
                     resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
                     host         => "host.[1]",
                  },
               },
            },
            "DeleteController"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevxlancontroller => "vsm.[1].vxlancontroller.[-1]",
            },
         },
      },
      'Create900VXLANLIFs' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "Create900VXLANLIFs",
         Tags             => "",
         Version          => "2" ,
         Summary          => "Test to create 900Lifs on one vdr edge ",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_TwoHost_TwoCluster,
         'WORKLOADS' => {
            Sequence => [
                         ['SetSegmentIDRange'],
                         ['SetMulticastRange'],
                         ['DeployFirstController', 'InstallVIBs_And_ConfigureVXLAN'],
                         ['CreateNetworkScope'],
                         ['Deploy10Edges'],
                         ['Create900VirtualWires'],
                         ['Create900VXLANLIFStress'],
                        ],
            ExitSequence => [
                             ['DeleteVDREdges'],
                             ['DeleteVirtualWires'],
                            ],

            "Deploy10Edges"   => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1-10]' => {
                     name          => "AutoGenerate",
                     resourcepool  => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter    => "vc.[1].datacenter.[1]",
                     host          => "host.[2]", # To pick datastore
                     portgroup     => "vc.[1].dvportgroup.[1]",
                     primaryaddress => "10.10.10.50",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
            "DeleteVDREdges"   => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               deletevse  => "vsm.[1].vse.[-1]",
            },
            'CreateNetworkScope' => {
               Type         => "NSX",
               TestNSX      => "vsm.[1]",
               networkscope => {
                  '[1]' => {
                     name         => "network-scope-1-$$",
                     clusters     => "vc.[1].datacenter.[1].cluster.[2]",
                  },
               },
            },
            'InstallVIBs_And_ConfigureVXLAN' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               VDNCluster => {
                  '[1]' => {
                     cluster      => "vc.[1].datacenter.[1].cluster.[2]",
                     vibs         => "install",
                     switch       => "vc.[1].vds.[1]",
                     vlan         => "19",
                     mtu          => "1600",
                     vmkniccount  => "1",
                     teaming      => "ETHER_CHANNEL",
                  },
               },
            },
            "DeployFirstController"   => {
               Type       => "NSX",
               TestNSX    => "vsm.[1]",
               vxlancontroller  => {
                  '[1]' => {
                     name         => "AutoGenerate",
                     firstnodeofcluster => "true",
                     ippool       => "vsm.[1].ippool.[1]",
                     resourcepool => "vc.[1].datacenter.[1].cluster.[1]",
                     host         => "host.[1]",
                  },
               },
            },
            'SetSegmentIDRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               # PR 1069737
               sleepbetweenworkloads => "10",
               Segmentidrange => {
                  '[1]' => {
                     name  => "segmentid-range-$$",
                     begin => "10000",
                     end   => "99000",
                  },
               },
            },
            'SetMulticastRange' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               Multicastiprange => {
                  '[1]' => {
                     name  => "multicastip-range-$$",
                     begin => "239.0.0.100",
                     end   => "239.254.254.254",
                  },
               },
            },
            'Create900VirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               maxtimeout        => "128000",
               VirtualWire       => {
                  "[1-900]" => {
                     name               => "AutoGenerate",
                     tenantid           => "AutoGenerate",
                  },
               },
            },
            'DeleteVirtualWires' => {
               Type              => "TransportZone",
               TestTransportZone => "vsm.[1].networkscope.[1]",
               deletevirtualwire => "vsm.[1].networkscope.[1].virtualwire.[-1]",
            },
            'Create900VXLANLIFStress' => {
               Type        => "VM",
               TestVM      => "vsm.[1].vse.[2]",
               maxtimeout  => "108000",
               lif => {
                  '[1-900]'   => {
                     name        => "AutoGenerate",
                     portgroup   => "vsm.[1].networkscope.[1].virtualwire.[x]",
                     type        => "internal",
                     connected   => 1,
                  },
               },
            },
            'DeleteLIFs' => {
               Type   => "VM",
               deletelif => "vsm.[1].vse.[1].lif.[-1]",
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
      my $self = $class->SUPER::new(\%Scalability);
      return (bless($self, $class));
}

1;
