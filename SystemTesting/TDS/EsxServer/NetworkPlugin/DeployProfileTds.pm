#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NetworkPlugin::DeployProfileTds;

#
# This file contains the structured hash for Deploy ESXi Image tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{

   %DeployProfile = (

      'DeployDatacenterProfile'   => {
         TestName         => 'DeployDatacenterProfile',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Deploy Profile Rule ' ,
         Procedure        =>
           '1. Deploy Esx Image to DatacCenter via Autodeploy Server ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                 datacenter => {
                    '[1]' => {
                       foldername => VDNetLib::TestData::TestConstants::DEFAULT_FOLDER,
                       name => VDNetLib::TestData::TestConstants::DEFAULT_DATACENTER,
                   },
                },
              },
           },
           host  => {
              '[1]'   => {
              },
              '[2]'   => {
              },
           },
           powerclivm  => {
              '[1]'   => {
                  host  => "host.[2]",
              },
           },
        },
        WORKLOADS => {
           Sequence => [
                        ["DeployDatacenterProfile"],
                       ],

           "DeployDatacenterProfile" => {
                Type => "VM",
                TestVM => "powerclivm.[1]",
                deployprofile  => "vc.[1].datacenter.[1]",
           },
        },
      },
      'DeployClusterProfile'   => {
         TestName         => 'DeployClusterProfile',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Deploy Profile Rule ' ,
         Procedure        =>
           '1. Deploy Esx Image to Cluster via Autodeploy Server',
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                 datacenter => {
                    '[1]' => {
                       foldername => VDNetLib::TestData::TestConstants::DEFAULT_FOLDER,
                       name => VDNetLib::TestData::TestConstants::DEFAULT_DATACENTER,
                       cluster => {
                          '[1]' => {
                             clustername => VDNetLib::TestData::TestConstants::DEFAULT_CLUSTER_NAME,
                          },
                      },
                   },
                },
              },
           },
           host  => {
              '[1]'   => {
              },
              '[2]'   => {
              },
           },
           powerclivm  => {
              '[1]'   => {
                  host  => "host.[2]",
              },
           },
        },
        WORKLOADS => {
           Sequence => [
                        ["DeployClusterProfile"],
                       ],
           "DeployClusterProfile" => {
                Type => "VM",
                TestVM => "powerclivm.[1]",
                deployprofile  => "vc.[1].datacenter.[1].cluster.[1]",
           },
        },
      },
      'ConfigureNextServer'   => {
         TestName         => 'ConfigureNextServer',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Configure next server using netfvt as tester ' ,
         Procedure        =>
           '1. Configure next server using netfvt as tester. ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                 datacenter => {
                    '[1]' => {
                       foldername => VDNetLib::TestData::TestConstants::DEFAULT_FOLDER,
                       name => VDNetLib::TestData::TestConstants::DEFAULT_DATACENTER,
                   },
                },
              },
           },
        },
        WORKLOADS => {
           Sequence => [
                        ["ConfigureNextServer"],
                       ],
          "ConfigureNextServer" => {
                Type           => "VC",
                TestVC         => "vc.[1].x.[x]",
                configurenextserver  => VDNetLib::Common::GlobalConfig::NETFVT_TRAMP,
                username => VDNetLib::Common::GlobalConfig::NETFVT_USER,
                password => VDNetLib::Common::GlobalConfig::NETFVT_PASSWORD,
          },
        },
      },
      'UpdateNextServer'   => {
         TestName         => 'UpdateNextServer',
         Category         => 'ESX Server',
         Component        => 'network plugin',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\NetworkPlugin',
         Summary          => 'Configure next server using netfvt as tester ' ,
         Procedure        =>
           '1. Update next server configured on Cisco Switch ' ,
         ExpectedResult   => 'PASS' ,
         Status           => 'Execution Ready',
         Tags             => '',
         PMT              => '',
         AutomationStatus => 'Automated',
         FullyAutomatable => 'Y',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => '',
         Partnerfacing    => 'N',
         Duration         => '',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                 datacenter => {
                    '[1]' => {
                       foldername => VDNetLib::TestData::TestConstants::DEFAULT_FOLDER,
                       name => VDNetLib::TestData::TestConstants::DEFAULT_DATACENTER,
                   },
                },
              },
           },
           pswitch => {
              '[1]'   => {
              },
           },
        },

        WORKLOADS => {
           Sequence => [
                        ["UpdateNextServer"],
                       ],

           "UpdateNextServer" => {
                Type            => "Switch",
                TestSwitch      => "pswitch.[1]",
                vc              => "vc.[1]",
                updatenextserver  => VDNetLib::TestData::TestConstants::DEFAULT_SERVER_ONE,
           },
        },
      },
   );
}


########################################################################
#
# new --
#       This is the constructor for DeployProfileTds
#
# Input:
#       none
#
# Results:
#       An instance/object of DeployProfileTds class
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
   my $self = $class->SUPER::new(\%DeployProfile);
   return (bless($self, $class));
}

1;
