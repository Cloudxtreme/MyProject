#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::ServiceInsertion::LegacyHostBasedServiceInsertionFunctionalTds;

#
# This file contains the structured hash for category, LegacyHostBasedServiceInsertionFunctional tests
# The following lines explain the keys of the internal
# Hash in general.
#

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use lib "$FindBin::Bin/../../..";

# Import Workloads which are very common across all tests
use TDS::NSX::ServiceInsertion::CommonWorkloads ':AllConstants';
use TDS::Main::VDNetMainTds;
use VDNetLib::TestData::TestbedSpecs::TestbedSpec;
use VDNetLib::TestData::TestConstants;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("");

   %HostBasedServiceInsertionFunctional = (
      'ServiceInsertionPreInstall' => {
         Category         => 'vShield',
         Component        => 'Service Insertion',
         TestName         => "ServiceInsertionPreInstall",
         Version          => "2" ,
         Tags             => "si",
         Summary          => "Initial setup before running service insertion scripts",
         TestbedSpec      => $VDNetLib::TestData::TestbedSpecs::TestbedSpec::OneVC_OneDC_OneVDS_OneDVPG_OneHost_OneVmnicForHost,
         'WORKLOADS' => {
            Sequence => [
                          ['PrepCluster'],
                          ['GetDatastore'],
                          ['CreateServiceManager'],
                          ['CreateService'],
                          ['CreateVendorTemplate'],
                          ['CreateVersionedDeploymentSpec'],
                          ['SetDeploymentScope'],
#                          ['InstallService'],
                        ],
            'PrepCluster' => PREP_CLUSTER,
            'GetDatastore' => GET_DATASTORE,
            'CreateServiceManager' => CREATE_SERVICE_MANAGER,
            'CreateService' => {
               Type       => 'NSX',
               TestNSX    => "vsm.[1]",
               service => {
                    '[1]' => {
                            'name' => "ABC Company Service",
                            'category' => 'IDS_IPS',
                            'servicemanager' => {
                               'objectid' => "vsm.[1].servicemanager.[1]",
                            },
                            'serviceattributes' => [
                               {
                                  'key' => 'agentName',
                                  'name' => 'Agent Name',
                                  'value' => 'My_agent',
                               },
                               {
                                  'key' => 'failOpen',
                                  'name' => 'Fail Open',
                                  'value' => 'true',
                               },
                               {
                                   'key' => 'default-action',
                                   'name' => 'Default Action',
                                   'value' => 'ACTION_ACCEPT',
                               },
                              ],
                            'vendortemplates' => '',
                            'usedby' => '',
                    },
               },
            },
            'CreateVendorTemplate' => CREATE_VENDOR_TEMPLATE,
            'CreateVersionedDeploymentSpec' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               versioneddeploymentspec => {
                    '[1]' => {
                            'hostversion' => "5.1.*",
                            'ovfurl' =>  VDNetLib::TestData::TestConstants::OVF_URL,
                            'vmcienabled' => "true",
                    },
               },
            },
            'SetDeploymentScope' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               deploymentscope => {
                  'clusterid' => "vc.[1].datacenter.[1].cluster.[1]",
               },
            },
            'InstallService' => {
               Type       => 'Service',
               TestService    => "vsm.[1].service.[1]",
               installservice => "123",
            }
         },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for HostBasedServiceInsertionFunctionalTds
#
# Input:
#       none
#
# Results:
#       An instance/object of HostBasedServiceInsertionFunctionalTds class
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
   my $self = $class->SUPER::new(\%HostBasedServiceInsertionFunctional);
   return (bless($self, $class));
}

1;