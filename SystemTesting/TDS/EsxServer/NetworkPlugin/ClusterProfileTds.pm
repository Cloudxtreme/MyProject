#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetworkPlugin::ClusterProfileTds;

#
# This file contains the structured hash for category, cluster profile  tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   %ClusterProfile = (

      'ClusterProfile'   => {
         TestName         => 'ClusterProfile',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the maxConnection in updated ' .
                             'in hostprofile ',
         Procedure        =>
           '1. Extract host profile '.
           '2. Associate host profile with a cluster  ' .
           '3. Disassociate host profile from a cluster' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'cluster',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneCluster,

         WORKLOADS => {
            Sequence => [
                        ["CreateProfile"],
                        ["EnableMaintenanceMode"],
                        ["AssociateClusterProfile"],
                        ],
            ExitSequence   =>
                        [
                        ["DisAssociateClusterProfiles"],
                        ["DestroyProfile"],
                        ["DisableMaintenanceMode"]
                        ],

            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               createprofile  => "profile",
               SrcHost        => "host.[1].x.[x]",
               targetprofile  => "testprofile",
            },
            "AssociateClusterProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               targetprofile  => "testprofile",
               clusterprofile  => "associate",
               clusterpath    => VDNetLib::TestData::TestConstants::DEFAULT_CLUSTER,
            },
            "DisAssociateClusterProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               targetprofile  => "testprofile",
               clusterpath    => VDNetLib::TestData::TestConstants::DEFAULT_CLUSTER,
               clusterprofile  => "disassociate",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               destroyprofile => "testprofile",
            },
            "EnableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "false",
           },
         },
      },
      'ApplyClusterProfile'   => {
         TestName         => 'ApplyClusterProfile',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Verify the maxConnection in updated ' .
                             'in hostprofile ',
         Procedure        =>
           '1. Extract Hostprofile on host 2 testprofile_1'.
           '2. Extract Hostprofile on host 1 testprofile'.
           '3. Associate host 1 profile with a cluster  ' .
           '4. Apply cluster profile to host 2  ' .
           '5. Disassociate profile testprofile from a cluster' .
           '6. Destroy testprofile' .
           '7. Associate testprofile_1 with cluster' .
           '8. Apply cluster profile -testprofile_1 to host 2  ' .
           '9. Disassociate profile testprofile_1 from a cluster' .
           '10. Destroy testprofile_1' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => 'cluster',
         PMT              => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      =>
            $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneCluster,

         WORKLOADS => {
            Sequence => [
                        ["CreateProfile"],
                        ["CreateProfile_1"],
                        ["EnableMaintenanceMode"],
                        ["EnableMaintenanceMode_1"],
                        ["AssociateClusterProfile"],
                        ["ApplyProfile"],
                        ["EnableMaintenanceMode_1"],
                        ["DisAssociateClusterProfiles"],
                        ["DestroyProfile"],
                        ["AssociateClusterProfile_1"],
                        ["ApplyProfile_1"],
                        ],
            ExitSequence   =>
                        [
                        ["DisAssociateClusterProfiles_1"],
                        ["DestroyProfile_1"],
                        ["DisableMaintenanceMode"],
                        ["DisableMaintenanceMode_1"]
                        ],

            "CreateProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               createprofile  => "profile",
               SrcHost        => "host.[1].x.[x]",
               targetprofile  => "testprofile",
            },
            "CreateProfile_1" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               createprofile  => "profile",
               SrcHost        => "host.[2].x.[x]",
               targetprofile  => "testprofile_1",
            },

            "AssociateClusterProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               targetprofile  => "testprofile",
               clusterprofile  => "associate",
               clusterpath    => VDNetLib::TestData::TestConstants::DEFAULT_CLUSTER,
            },
            "DisAssociateClusterProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               targetprofile  => "testprofile",
               clusterpath    => VDNetLib::TestData::TestConstants::DEFAULT_CLUSTER,
               clusterprofile  => "disassociate",
            },
            "AssociateClusterProfile_1" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               targetprofile  => "testprofile_1",
               clusterprofile  => "associate",
               clusterpath    => VDNetLib::TestData::TestConstants::DEFAULT_CLUSTER,
            },
            "DisAssociateClusterProfiles_1" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               targetprofile  => "testprofile_1",
               clusterpath    => VDNetLib::TestData::TestConstants::DEFAULT_CLUSTER,
               clusterprofile  => "disassociate",
            },

            "ApplyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               applyprofile   => "testprofile",
               SrcHost        => "host.[2].x.[x]",
            },
            "ApplyProfile_1" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               applyprofile   => "testprofile_1",
               SrcHost        => "host.[2].x.[x]",
            },
            "DestroyProfile_1" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               destroyprofile => "testprofile_1",
            },
            "DestroyProfile" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               destroyprofile => "testprofile",
            },
           "EnableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "true",
           },
           "DisableMaintenanceMode" => {
              Type            => "Host",
              TestHost        => "host.[1].x.[x]",
              maintenancemode => "false",
           },
           "EnableMaintenanceMode_1" => {
              Type            => "Host",
              TestHost        => "host.[2].x.[x]",
              maintenancemode => "true",
           },
           "DisableMaintenanceMode_1" => {
              Type            => "Host",
              TestHost        => "host.[2].x.[x]",
              maintenancemode => "false",
           },
            "DisAssociateProfiles" => {
               Type           => "VC",
               TestVC         => "vc.[1].x.[x]",
               disassociateprofiles  => "testprofile_1",
               SrcHost        => "host.[2].x.[x]",
            },
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for ClusterProfileTds
#
# Input:
#       none
#
# Results:
#       An instance/object of ClusterProfileTds class
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
   my $self = $class->SUPER::new(\%ClusterProfile);
   return (bless($self, $class));
}

1;
