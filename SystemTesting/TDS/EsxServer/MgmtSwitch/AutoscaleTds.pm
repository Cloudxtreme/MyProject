#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::MgmtSwitch::AutoscaleTds;

#
# This file contains the structured hash for category, vSwitch Autoscale
# tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   %Autoscale = (
     'PortsTest' => {
         Category         => 'ESX Server',
         Component        => 'Autoscale',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VSwitchAutoscale',
         TestName         => 'PortsTest',
         Summary          => 'Add autoscale ports test ',
         ExpectedResult   => 'PASS',
         Tags             => '',
         PMT              => '',
         Procedure        => '1. Run NetTest_PortsTest1'.
                             '2. Run NetTest_PortsTest2'.
                             '3. Run NetTest_PortsTest3'.
                             '4. Run NetTest_PortsTest4'.
                             '5. Run NetTest_PortsTest5'.
                             '6. Run NetTest_PortsTest6',
         Status           => 'Execution Ready',
         Tags             => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
           host  => {
               '[1]'   => {
               },
           },
         },

         WORKLOADS => {
            Sequence          => [['Autoscale']],
            Duration          => "time in seconds",

            "Autoscale" => {
               Type           => "Host",
               TestHost       => "host.[1].x.[x]",
               testesxcmd     => VDNetLib::TestData::TestConstants::VMK_TESTESX,
            },
         },
      },
     'AutoscaleSwitch' => {
         Category         => 'ESX Server',
         Component        => 'Autoscale',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VSwitchAutoscale',
         TestName         => 'AutoscaleSwitch',
         Summary          => 'Verify AutoScale switch ',
         ExpectedResult   => 'PASS',
         Tags             => '',
         PMT              => '',
         Procedure        => '1.vsish -e get /net/maxPortsSystemWide'.
                             '2.esxcli network vswitch standard list '.
                             '    -v vSwitch0 | grep "Num Ports" '.
                             '3.Check the return value are equal',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
           host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
              },
           },
         },
         WORKLOADS => {
            Sequence          => [['AutoscaleCheck']],
            Duration          => "time in seconds",
            "AutoscaleCheck" => {
               Type           => "Switch",
               TestSwitch     => "host.[1].vss.[1]",
               autoscale      => "true",
            },
          },
       },
      'NonAutoscaleSwitch' => {
         Category         => 'ESX Server',
         Component        => 'Autoscale',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VSwitchAutoscale',
         TestName         => 'NonAutoscaleSwitch',
         Summary          => 'Verify Non AutoScale switch ',
         ExpectedResult   => 'PASS',
         Tags             => '',
         PMT              => '',
         Procedure        => '1.vsish get -e get /net/maxPortsSystemWide'.
                             '2.esxcli network vswitch standard list'.
                             '  -v vSwitch0 | grep "Num Ports" '.
                             '3.Check the return value is not equal',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
         host  => {
               '[1]'   => {
                  vss   => {
                     '[1]'   => {
                     },
                  },
              },
           },
         },
         WORKLOADS => {
            Sequence          => [['AutoscaleCheck']],
            Duration          => "time in seconds",

            "AutoscaleCheck" => {
               Type           => "Switch",
               TestSwitch     => "host.[1].vss.[1]",
               autoscale      => "false",
            },
         },
      },
      'ActivePortsCheck' => {
         Category         => 'ESX Server',
         Component        => 'Autoscale',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VSwitchAutoscale',
         TestName         => 'ActivePortsCheck',
         Summary          => 'Verify Number of ActivePorts ',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity,CAT_P0',
         PMT              => '',
         Procedure        => '1.vsish -e get /net/numActivePortsSystemWide'.
                             '2.Create number of vswitches  '.
                             '3.vsish -e get /net/numActivePortsSystemWide'.
                             '4.Verify numActivePortsSystemWide: increment by the number'.
		             '5.Delete number of vswitches '.
                             '6.vsish -e get /net/numActivePortsSystemWide'.
                             '7.Verify numActivePortsSystemWide: decrement by the number',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            host  => {
               '[1]'   => {
              },
            },
         },
         WORKLOADS => {
            Sequence          => [
                                  ["AddVswitch"],
                                  ["DeleteVswitch"],
                                 ],
            Duration          => "time in seconds",

            "AddVswitch" => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               vss => {
                  '[1-10]' => {
                  },
               },
              'verification' => 'Verification_Port',
            },
            "DeleteVswitch" => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               deletevss => "host.[1].vss.[1-10]",
              'verification' => 'Verification_Port_1',
            },
            'Verification_Port' => {
              'PortVerification' => {
                  verificationtype   => "datadiff",
                  Target             => "host.[1].x.[x]",
                  data               => "activeportstats",
                  'activeportstats'        => "10",
             },
           },
           'Verification_Port_1' => {
              'PortVerification' => {
                  verificationtype   => "datadiff",
                  Target             => "host.[1].x.[x]",
                  data               => "activeportstats",
                  'activeportstats'        => "10-",
            },
          },
        },
      },
      'ActiveDVPortsCheck' => {
         Category         => 'ESX Server',
         Component        => 'Autoscale',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VSwitchAutoscale',
         TestName         => 'ActiveDVPortsCheck',
         Summary          => 'Verify Number of ActivePorts ',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => '1.Create number of dvs switch  '.
                             '2.vsish -e get /net/numActiveDVSPortsSystemWide'.
                             '3.Verify numActiveDVSPortsSystemWide: increment by the number',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Testbed          => '',
         Version          => '2',

         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1]",
                     },
                  },
                  vds      => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        configurehosts => "add",
                        numuplinkports => '4',
                        host => "host.[1]",
                     },
                  },
                  dvportgroup      => {
                     '[1-2]'  => {
                        vds  => "vc.[1].vds.[1]",
                        ports => "2",
                     },
                  },
               },
            },
            host  => {
               '[1]' => {
                  'vmknic' => {
                     '[1-2]' => {
                        'portgroup' => 'vc.[1].dvportgroup.[1]'
                     },
                     '[3-4]' => {
                        'portgroup' => 'vc.[1].dvportgroup.[2]'
                     }
                  },
               },
            },
         },

         WORKLOADS => {
            Sequence          => [
                                  ["CheckActiveDVPorts"],
                                 ],
            Duration          => "time in seconds",

            "CheckActiveDVPorts" => {
               Type           => "Host",
               TestHost       => "host.[1]",
               check_activedvports  => "8",
            },
         },
      },
      'MaxPortCheck' => {
         Category         => 'ESX Server',
         Component        => 'Autoscale',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VSwitchAutoscale',
         TestName         => 'MaxPortCheck',
         Summary          => 'Verify Max Ports ',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        =>
           '1.Create vswitch in a loop'.
           '  Until create vswitch failed with error message'.
           '  "out of resource" '.
           '2.Get vsish -e get /net/numActivePortsSystemWide'.
	   '3.Get vsish -e get /net/maxPortsSystemWide'.
           '4.Verify maxPortsSystemWide > numActivePortsSystemWide',
         Status           => 'Execution Ready',
         Tags             => '',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
         host  => {
               '[1]'   => {
               },
            },
         },
         WORKLOADS => {
            Sequence          => [
                                  ["AddVswitch"],
                                  ["MaxPortsCheck"],
                                 ],
            ExitSequence => [["DeleteVswitch"]],
            Duration          => "time in seconds",
            "AddVswitch" => {
               Type => "Host",
               TestHost => "host.[1]",
               vss => {
                  '[1-253]' => {
                  },
               },
            },
            "MaxPortsCheck"   => {
               Type => "Host",
               TestHost => "host.[1]",
               maxports       => "500",
           },
            "DeleteVswitch" => {
               Type => "Host",
               TestHost => "host.[1]",
               deletevss => "host.[1].vss.[-1]",
            },
        },
     },
     'AutoscaleDVSCheck' => {
         Category         => 'ESX Server',
         Component        => 'Autoscale',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\VSwitchAutoscale',
         TestName         => 'AutoscaleDVSCheck',
         Summary          => 'Check autoscale with DVS',
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        =>
            '1.Create DVS in VC'.
            '2.Add host to the DVS and set max proxy ports to 8'.
	    '3.Create 10 vmknics on the DVS on host'.
            '3.1 Create 8 vmknics from the testbed setup'.
            '4.0 Create 2 vmknics through workload'.
            '4.1 All 10 vmknics were added successfully',
         Status           => 'Execution Ready',
         Tags             => 'sanity',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'sho',
         Testbed          => '',
         Version          => '2',
         TestbedSpec      => {
            vc    => {
               '[1]'   => {
                  datacenter => {
                     '[1]' => {
                        host  => "host.[1].x.[x]",
                     },
                  },
                  vds        => {
                     '[1]'   => {
                        datacenter => "vc.[1].datacenter.[1]",
                        vmnicadapter => "host.[1].vmnic.[1]",
                        configurehosts => "add",
                        host => "host.[1].x.[x]",
                     },
                  },
                  dvportgroup      => {
                     '[1-10]'  => {
                        vds  => "vc.[1].vds.[1]",
                     },
                  },
               },
            },
            host  => {
               '[1]' => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
                  vmknic => {
                     '[1]'   => {
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                     '[2]'   => {
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                     '[3]'   => {
                        portgroup  => "vc.[1].dvportgroup.[3]",
                     },
                     '[4]'   => {
                        portgroup  => "vc.[1].dvportgroup.[4]",
                     },
                     '[5]'   => {
                        portgroup  => "vc.[1].dvportgroup.[5]",
                     },
                     '[6]'   => {
                        portgroup  => "vc.[1].dvportgroup.[6]",
                     },
                     '[7]'   => {
                        portgroup  => "vc.[1].dvportgroup.[7]",
                     },
                     '[8]'   => {
                        portgroup  => "vc.[1].dvportgroup.[8]",
                     },
                 },
              },
            },
         },
         WORKLOADS => {
            Sequence          => [
                                  ["EditProxyPort"],
                                  ["AddVmk1"],
                                  ["AddVmk2"],
                                  ["RemoveVmk1"],
                                  ["RemoveVmk2"],
                                 ],
            Duration          => "time in seconds",

            "EditProxyPort"   => {
               Type           => "Switch",
               TestSwitch     => "vc.[1].vds.[1]",
               host           => "host.[1].x.[x]",
               proxyports     => "8",
           },
           "AddVmk1" => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               vmknic => {
                 "[9]" =>{
                  portgroup => "vc.[1].dvportgroup.[9]",
                  ipv4address => "dhcp",
                 },
              },
            },
           "AddVmk2" => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               vmknic => {
                 "[10]" =>{
                  portgroup => "vc.[1].dvportgroup.[10]",
                  ipv4address => "dhcp",
                 },
              },
            },

            "RemoveVmk1" => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               deletevmknic => "host.[1].vmknic.[9]",
            },
            "RemoveVmk2" => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               deletevmknic => "host.[1].vmknic.[10]",
           },
        },
     },
  );
}


########################################################################
#
# new --
#       This is the constructor for AutoscaleTds
#
# Input:
#       none
#
# Results:
#       An instance/object of AutoscaleTds class
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
   my $self = $class->SUPER::new(\%Autoscale);
   return (bless($self, $class));
}

1;
