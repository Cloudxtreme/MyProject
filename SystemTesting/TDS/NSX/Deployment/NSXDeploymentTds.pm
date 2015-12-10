#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::Deployment::NSXDeploymentTds;

#
# This file contains the structured hash for VDR TDS.
# The following lines explain the keys of the internal
# hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
@ISA = qw(TDS::Main::VDNetMainTds);

# Import Workloads which are very common across all tests
use TDS::NSX::Networking::VirtualRouting::CommonWorkloads ':AllConstants';

{
   %NSXDeployment = (
      'DeployFirstController' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "DeployFirstController",
         Version          => "2" ,
         Tags             => "RunOnCAT",
         Summary          => "This is the vxlan controller deployment testcase ",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_FourDVPG_ThreeHost_ThreeVM,
         'WORKLOADS' => {
            Sequence => [
                         ['DeployFirstController'],
                         ['DeleteController'],
                        ],
            ExitSequence => [
                             ['RebootHost'],
                            ],

            "DeployFirstController"=> DEPLOY_FIRSTCONTROLLER,
            "DeleteController"     => DELETE_ALL_CONTROLLERS,
            'DeleteIPPool'         => DELETE_ALL_IPPOOLS,
            "RebootHost" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               reboot          => "yes",
            },
         },
      },
      'DeployVDREdge' => {
         Category         => 'NSX Server',
         Component        => 'network vDR',
         TestName         => "DeployVDREdge",
         Tags             => "RunOnCAT",
         Version          => "2" ,
         Summary          => "This is the edge deployment testcase ",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_FourDVPG_ThreeHost_ThreeVM,
         'WORKLOADS' => {
            Sequence => [
                         ['SetSegmentIDRange'],
                         ['SetMulticastRange'],
                         ['DeployFirstController'],
                         ['Install_Config_ClusterSJC'],
                         ['CreateNetworkScope'],
                         ['CreateVirtualWires'],
                         ['DeployEdge'],
                         ['PowerOffController1'],
                         ['PowerOffEdge'],
                        ],
            ExitSequence => [
                             ['DeleteVDREdge'],
                             ['DeleteController'],
                             ['RebootHost'],
                            ],

            'SetSegmentIDRange'  => SET_SEGMENTID_RANGE,
            'DeleteIPPool'         => DELETE_ALL_IPPOOLS,
            'SetMulticastRange'  => SET_MULTICAST_RANGE,
            "DeployFirstController" => DEPLOY_FIRSTCONTROLLER,
            'CreateNetworkScope' => CREATE_NETWORKSCOPE_ClusterSJC,
            'CreateVirtualWires' => CREATE_VIRTUALWIRES_NETWORKSCOPE1,
            'Install_Config_ClusterSJC' => INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC_VDS1,
            'Install_Config_ClusterSJC2' => INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC2_VDS1,
            "Expand_TZ" => {
               Type  => "TransportZone",
               TestTransportZone   => "vsm.[1].networkscope.[1]",
               transportzoneaction => "expand",
               clusters            => "vc.[1].datacenter.[1].cluster.[3]",
            },
            'DeployEdge'         => {
               Type    => "NSX",
               TestNSX => "vsm.[1]",
               vse => {
                  '[1]' => {
                     name           => "Edge-$$",
                     resourcepool   => "vc.[1].datacenter.[1].cluster.[2]",
                     datacenter     => "vc.[1].datacenter.[1]",
                     host           => "host.[3]", # To pick datastore
                     portgroup      => "vc.[1].dvportgroup.[1]",
                     datastoretype  => "shared",
                     primaryaddress => "10.10.10.10",
                     subnetmask     => "255.255.255.0",
                  },
               },
            },
           "DeleteController"     => DELETE_ALL_CONTROLLERS,
           "DeleteVDREdge"      => DELETE_ALL_EDGES,
            "PowerOffController1" => {
               Type    => "VM",
               TestVM  => "vsm.[1].vxlancontroller.[1]",
               vmstate => "poweroff",
            },
            "PowerOffEdge" => {
               Type    => "VM",
               TestVM  => "vsm.[1].vse.[1]",
               vmstate => "poweroff",
            },
            "RebootHost" => {
               Type            => "Host",
               TestHost        => "host.[1]",
               reboot          => "yes",
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
      my $self = $class->SUPER::new(\%NSXDeployment);
      return (bless($self, $class));
}

1;
