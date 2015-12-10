#!/usr/bin/perl
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Appliance::NSXApplianceTds;

@ISA = qw(TDS::Main::VDNetMainTds);
#
# This file contains the structured hash for NSXAppliance Tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;
use TDS::NSX::Appliance::TestbedSpec;
use TDS::NSX::Appliance::TestbedSpec ':AllConstants';

#
# Begin test cases
#

{
   %NSXAppliance = (
      'NSXUpgrade' => {
         Component         => "NSXAPI",
         Category          => "Node Management",
         TestName          => "NSXUpgrade",
         Version           => "2",
         Tags              => "nsx, vsm",
         Summary           => "This test case upgrdes vsm",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
                                 "vsm" => {
                                    "[1]" => {
                                    },
                                 },
                              },
         WORKLOADS => {
            Sequence     => [
                                ["Upgrade"],
                            ],
            Upgrade => {
               Type          => "NSX",
               TestNSX       => "vsm.[1]",
               profile => "update",
               build => "1567396",
               name  => "VMware-NSX-Manager-upgrade-bundle-",
            },
         },
      },
      'UpgradeVSE' => {
         Component         => "NSXAPI",
         Category          => "Node Management",
         TestName          => "UpgradeVSE",
         Version           => "2",
         Tags              => "nsx, vsm",
         Summary           => "This test case upgrdes vShield Edge",
         ExpectedResult    => "PASS",
         TestbedSpec       => "VDR_ONE_VDS_TESTBEDSPEC",
         WORKLOADS => {
            Sequence     =>  [
                                ["VDR_DEPLOY_SEQUENCE"],
                                ["VDR_SETUP_SEQUENCE"],
                                ["VDR_DATAPATH_SEQUENCE"],
                                ["Upgrade"],
                                ["VDR_DATAPATH_SEQUENCE"],
                                ["VerifyUpgradeStatus"],
                                ["UpgradeVDNCluster"],
                                ["ResolveCluster"],
                                ["VDR_DATAPATH_SEQUENCE"],
                                ["UpgradeVSE"],
                                ["VDR_DATAPATH_SEQUENCE"],
                             ],
            GROUP1 => "VDR_DEPLOY_WORKLOADS",
            GROUP2 => "VDR_SETUP_WORKLOADS",
            GROUP3 => "VDR_DATAPATH_WORKLOADS",
            Upgrade => {
               Type          => "NSX",
               TestNSX       => "vsm.[1]",
               profile => "update",
               build => "from_buildweb",
               build_product => "vsmva",
               build_branch => "vshield-trinity-rel",
               build_context => "sb",
               build_type => "release",
               name  => "VMware-NSX-Manager-upgrade-bundle-",
            },
            UpgradeVDNCluster => {
               Type             => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[1]",
            },
            "VerifyUpgradeStatus" => {
               Type     => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               verifyupgradestatus => {
                  "resourceStatus[?]contain_once" => [
                     {
                        "featureId" => "com.vmware.vshield.vsm.nwfabric.hostPrep",
                       "updateAvailable" => "true",
                     }
                  ],
               },
            },
            "ResolveCluster" => {
              Type     => "Cluster",
              TestCluster   => "vsm.[1].vdncluster.[1]",
              resolve => "vibs",
            },
            'UpgradeVSE' => {
               Type             => "VM",
               TestVM   => "vsm.[1].vse.[1]",
               profile => "update",
            },
         },
      },
      'UpgradeAndResolveVDNCluster' => {
         Component         => "NSXAPI",
         Category          => "Node Management",
         TestName          => "UpgradeAndResolveVDNCluster",
         Version           => "2",
         Tags              => "nsx, vsm",
         Summary           => "This test case upgrdes vdn cluster vibs",
         ExpectedResult    => "PASS",
         TestbedSpec       => $TDS::NSX::Appliance::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_TwoHost_OneCluster,
         WORKLOADS => {
            Sequence     => [
                                ["EditCluster"],
                                ["GROUP:VIBS_DEPLOY_SEQUENCE"],
                                ["Upgrade"],
                                ["VerifyUpgradeStatus"],
                                ["UpgradeVDNCluster"],
                                ["ResolveCluster"],
                            ],
            GROUP1 => "VDR_DEPLOY_WORKLOADS",
            EditCluster => {
                Type => "Cluster",
                TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
                EditCluster => "edit",
                DRS  => 1,
            },
            UpgradeVDNCluster => {
               Type             => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[1]",
            },
            Upgrade => {
               Type          => "NSX",
               TestNSX       => "vsm.[1]",
               profile => "update",
               build => "from_buildweb",
               build_product => "vsmva",
               build_branch => "vshield-trinity-rel",
               build_context => "sb",
               build_type => "release",
               name  => "VMware-NSX-Manager-upgrade-bundle-",
            },
            "VerifyUpgradeStatus" => {
               Type     => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               verifyupgradestatus => {
                  "resourceStatus[?]contain_once" => [
                     {
                        "featureId" => "com.vmware.vshield.vsm.nwfabric.hostPrep",
                        "updateAvailable" => "true",
                     }
                  ],
               },
           },
           "ResolveCluster" => {
              Type     => "Cluster",
              TestCluster   => "vsm.[1].vdncluster.[1]",
              resolve => "vibs",
           },
           'SetSegmentIDRange'  => SET_SEGMENTID_RANGE,
           'SetMulticastRange'  => SET_MULTICAST_RANGE,
           'InstallVIBs_And_ConfigureVXLAN' => INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC_VDS1,
         },
      },
      'UpgradeVDNCluster' => {
         Component         => "NSXAPI",
         Category          => "Node Management",
         TestName          => "UpgradeVDNCluster",
         Version           => "2",
         Tags              => "nsx, vsm",
         Summary           => "This test case upgrdes vdn cluster vibs",
         ExpectedResult    => "PASS",
         TestbedSpec       => $TDS::NSX::Appliance::TestbedSpec::OneVSM_OneVC_OneDC_OneVDS_TwoHost_OneCluster,
         WORKLOADS => {
            Sequence     => [
                                ["GROUP:VIBS_DEPLOY_SEQUENCE"],
                                ["Upgrade"],
                                ["VerifyUpgradeStatus"],
                                ["UpgradeVDNCluster"],
                                ["RebootHosts"],
                            ],
            GROUP1 => "VDR_DEPLOY_WORKLOADS",
            UpgradeVDNCluster => {
               Type             => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               profile => "update",
               cluster => "vc.[1].datacenter.[1].cluster.[1]",
            },
            Upgrade => {
               Type          => "NSX",
               TestNSX       => "vsm.[1]",
               profile => "update",
               build => "from_buildweb",
               build_product => "vsmva",
               build_branch => "vshield-trinity-rel",
               build_context => "sb",
               build_type => "release",
               name  => "VMware-NSX-Manager-upgrade-bundle-",
            },
            "VerifyUpgradeStatus" => {
               Type     => "Cluster",
               TestCluster   => "vsm.[1].vdncluster.[1]",
               verifyupgradestatus => {
                  "resourceStatus[?]contain_once" => [
                     {
                        "featureId" => "com.vmware.vshield.vsm.nwfabric.hostPrep",
                        "updateAvailable" => "true",
                     }
                  ],
               },
           },
           "RebootHosts" => {
              Type => "Cluster",
              TestCluster => "vc.[1].datacenter.[1].cluster.[1]",
              hosts => "host.[1-2]",
              RebootHostsInCluster => "sequential",
           },
            'SetSegmentIDRange'  => SET_SEGMENTID_RANGE,
            'SetMulticastRange'  => SET_MULTICAST_RANGE,
            'InstallVIBs_And_ConfigureVXLAN' => INSTALLVIBS_CONFIGUREVXLAN_ClusterSJC_VDS1,
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for NSXApplianceTds
#
# Input:
#       none
#
# Results:
#       An instance/object of NSXApplianceTds class
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
   my $self = $class->SUPER::new(\%NSXAppliance);
   return (bless($self, $class));
}

1;

