#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::Internal::VDNet::InfrastructureTds;

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("RunAction1");

   %Infrastructure = (

      'VDTestInventory' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "VDTestInventory",
         Version          => "2" ,
         Tags             => "VDTestInventory,precheckin",
         Summary          => "This test case checks Test Inventory",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            testinventory => {
               '[1-3]'   => {
               },
            },
         },


         WORKLOADS => {
            Sequence      => [['InventoryWorkload1'],],
            Duration      => "time in seconds",

            "InventoryWorkload1" => {
               Type              => "TestInventory",
               testinventory     => "testinventory.[1].x.[x]",
               testcomponent     => {
                   '[1]'    => {
                       sleep  => "1",
                   },
                   '[2]'    => {
                       sleep  => "2",
                   },
               },
            },
         },
      },

     'VerificationUnitTest' => {
         Category         => 'Internal',
         Component        => 'Verification',
         TestName         => "VerificationUnitTest",
         Version          => "2" ,
         Tags             => "precheckin",
         Summary          => "Precheckin test for verification",
         'TestbedSpec' => {
            testinventory => {
               '[1]'   => {
                  'testcomponent' => {
                     '[1]' => {
                         'name'     => "test1",
                         'schema'   => "12345",
                         'ipaddress'=> "10.10.10.10",
                         'username' => "admin",
                         'password' => "default",
                     },
                  },
               },
               '[2]'   => {
                  'testcomponent' => {
                     '[1]' => {
                         'name'     => "test2",
                         'ipaddress'=> "10.10.10.10",
                         'schema'   => "12345",
                         'username' => "admin",
                         'password' => "default",
                     },
                  },
               },
            },
         },
         'WORKLOADS' => {
            Sequence => [
                         ['FirstVerification1'],
                         ['FirstVerification_CheckForDuplicate'],
                         ],

            'FirstVerification1' => {
               Type              => "TestComponent",
               TestComponent     => "testinventory.[2].testcomponent.[1]",
               Inventory         => "testinventory.[1]",
               CheckifExists => [{
                  'abc' => [{
                  'ipaddress[?]equal_to' => "self",
                  'name[?]equal_to'      => "test2",
                  'schema[?]equal_to'    => "12345",
                  'username[?]equal_to'  => "testinventory.[1].testcomponent.[1]",
                  'password[?]equal_to'  => "testinventory.[1].testcomponent.[1]",
                  'array'     => [
                     {
                        'cdf' => {
                        'zone[?]equal_to' => "testinventory.[1].testcomponent.[1]",
                       },
                     },
                     ],
                  },],},],
            },
            'FirstVerification_CheckForDuplicate' => {
              Type => 'TestComponent',
              Inventory => 'testinventory.[1]',
              TestComponent => 'testinventory.[1].testcomponent.[1]',
              'verifyABCD[?]contain_once' => [
                 {
                  'groupaddr[?]equal_to' => '239.1.1.1',
                  'mcastmode[?]equal_to'=> 'exclude',
                  'mcastprotocol[?]equal_to'=> 'igmp',
                  'mcastversion[?]equal_to'=> 'testinventory.[2].testcomponent.[1]',
                  'sourceaddrs[?]contain_once'=> [
                    { 'ip[?]contain_once'=> ["192.168.1.1", "192.168.1.2"],
                      'mac[?]equal_to'=> 'ABCDEFG'
                    }],
              }],
            },
         },
      },


     'VerificationStatsTest' => {
         Category         => 'Internal',
         Component        => 'Verification',
         TestName         => "VerificationUnitTest",
         Version          => "2" ,
         Tags             => "precheckin",
         Summary          => "Precheckin test for verification",
         'TestbedSpec' => {
            testinventory => {
               '[1]'   => {
                  'testcomponent' => {
                     '[1]' => {
                         'name'     => "test1",
                         'schema'   => "12345",
                         'ipaddress'=> "10.10.10.10",
                         'username' => "admin",
                         'password' => "default",
                     },
                  },
               },
               '[2]'   => {
                  'testcomponent' => {
                     '[1]' => {
                         'name'     => "test2",
                         'ipaddress'=> "10.10.10.10",
                         'schema'   => "12345",
                         'username' => "admin",
                         'password' => "default",
                     },
                  },
               },
            },
         },
         'WORKLOADS' => {
            Sequence => [
                         ['FirstVerification1'],
                         ['FirstVerification2'],
                         ['FirstVerification3'],
                         ],

            'FirstVerification1' => {
               Type              => "TestComponent",
               TestComponent     => "testinventory.[2].testcomponent.[1]",
               Inventory         => "testinventory.[1]",
               PersistData       => 'Yes',
               CheckifExists => [{
                  'abc' => [{
                  'ipaddress[?]equal_to' => "self",
                  'name[?]equal_to'      => "test2",
                  'schema[?]equal_to'    => "3",
                  'username[?]equal_to'  => "testinventory.[1].testcomponent.[1]",
                  'password[?]equal_to'  => "testinventory.[1].testcomponent.[1]",
                  'array'     => [
                     {
                        'cdf' => {
                        'zone[?]equal_to' => "testinventory.[1].testcomponent.[1]",
                       },
                     },
                     ],
                  },],},],
            },
            'FirstVerification2' => {
               Type              => "TestComponent",
               TestComponent     => "testinventory.[2].testcomponent.[1]",
               Inventory         => "testinventory.[1]",
               PersistData       => 'Yes',
               CheckifExists => [{
                  'abc' => [{
                  'ipaddress[?]equal_to' => "testinventory.[2].testcomponent.[1]->checkifexists->[0]->abc->[0]->ipaddress",
                  'username[?]equal_to'  => "FirstVerification1->1->testinventory.[2].testcomponent.[1]->checkifexists->[0]->abc->[0]->username",
                  'password[?]equal_to'  => "testinventory.[1].testcomponent.[1]",
                  'array'     => [
                     {
                        'cdf' => {
                        'zone[?]equal_to' => "testinventory.[1].testcomponent.[1]",
                       },
                     },
                     ],
                  },],},],
            },
            'FirstVerification3' => {
               Type              => "TestComponent",
               TestComponent     => "testinventory.[2].testcomponent.[1]",
               Inventory         => "testinventory.[1]",
               PersistData       => 'Yes',
               CheckifExists => [{
                  'abc' => [{
                  'ipaddress[?]equal_to' => "testinventory.[2].testcomponent.[1]->checkifexists->[0]->abc->[0]->ipaddress",
                  'username[?]equal_to'  => "testinventory.[2].testcomponent.[1]->checkifexists->[0]->abc->[0]->username",
                  'password[?]equal_to'  => "testinventory.[1].testcomponent.[1]",
                  'array'     => [
                     {
                        'cdf' => {
                        'zone[?]equal_to' => "testinventory.[2].testcomponent.[1]->checkifexists->[0]->abc->[0]->array->[0]->cdf->zone",
                       },
                     },
                     ],
                  },],},],
            },
         },
      },

     'VerificationDiffTest' => {
         Category         => 'Internal',
         Component        => 'Verification',
         TestName         => "VerificationDiffTest",
         Version          => "2" ,
         Tags             => "precheckin",
         Summary          => "Precheckin test for verification",
         'TestbedSpec' => {
            testinventory => {
               '[1]'   => {
                  'testcomponent' => {
                     '[1]' => {
                         'name'     => "test1",
                         'schema'   => "12345",
                         'ipaddress'=> "10.10.10.10",
                         'username' => "admin",
                         'password' => "default",
                     },
                  },
               },
            },
         },
         'WORKLOADS' => {
            Sequence => [
                         ['CollectLogs'],
                         ['CollectLogs'],
                         ['CollectLogsAgain'],
                         ['CollectLogsAgain'],
                         ],

            'CollectLogs' => {
               Type              => "TestComponent",
               TestComponent     => "testinventory.[1].testcomponent.[1]",
               VerificationStyle => 'diff',
               CheckifExists => [{
                  'abc' => [{
                  'ipaddress[?]!=' => "10.11.12.13",
                  'name[?]!='      => "test2",
                  'schema[?]equal_to'    => "0",
                  'username[?]equal_to'  => "admin",
                  'password[?]equal_to'  => "default",
                  'array'     => [
                     {
                        'cdf' => {
                        'zone[?]equal_to' => "0",
                       },
                     },
                     ],
                  },],},],
            },
            'CollectLogsAgain' => {
               Type              => "TestComponent",
               TestComponent     => "testinventory.[1].testcomponent.[1]",
               VerificationStyle => 'diff',
               CheckifExists => [{
                  'abc' => [{
                  'ipaddress[?]!=' => "10.11.12.13",
                  'name[?]!='      => "test2",
                  'schema[?]equal_to'    => "0",
                  'username[?]equal_to'  => "admin",
                  'password[?]equal_to'  => "default",
                  'array'     => [
                     {
                        'cdf' => {
                        'zone[?]equal_to' => "0",
                       },
                     },
                     ],
                  },],},],
            },
         },
      },
      # We can make this a precheckin test for KVM changes
      'KVMPowerOnVM' => {
         Component        => "Infrastructure",
         Category         => "vdnet",
         TestName         => "VDTestInventory",
         Version          => "2" ,
         Tags             => "",
         Summary          => "This test case checks Test Inventory",
         ExpectedResult   => "PASS",
         TestbedSpec      => {
            kvm => {
               '[1-2]'   => {
                  pif => {
                     '[0-1]' => {
                     },
                  },
               },
            },
         },
         WORKLOADS => {
            Sequence      => [
                ['InitializeBridges'],
                ['Createtty_linux'],
                ['CreateVM1'],
                ['CreateVM2'],
                ['CreateVM1','CreateVM2'],
                ['AddVIFsVM1','AddVIFsVM2'],
                ['PoweronVM1','PoweronVM2'],
                ['PoweronVM1'],
                ['PoweronVM2'],
                ['PoweroffVM1','PoweroffVM2'],
                ['PoweroffVM1'],
                ['AddVIF2VM1'],
                ['PoweronVM1'],
                ['PoweroffVM2'],
            ],
            Duration      => "time in seconds",

            CreateVM1 => {
               Type     => "Root",
               TestNode => "root.[1]",
               maxtimeout => "900000",
               vm => {
                  '[1]' => {
                     #template => 'rhel53-srv-32',
                     template => 'template_kvm_debian',
                     vmstate  => 'poweroff',
                     installtype => 'fullclone',
                     host     => "kvm.[1]",
                     vif => {
                        '[1]' => {
                           backing => "kvm.[1].bridge.[1]",
                        },
                     },
                  },
               },
            },
            CreateVM2 => {
               Type     => "Root",
               TestNode => "root.[1]",
               maxtimeout => "900000",
               vm => {
                  '[2]' => {
                     #template => 'rhel53-srv-32',
                     template => 'template_kvm_debian',
                     vmstate  => 'poweroff',
                     installtype => 'fullclone',
                     host     => "kvm.[2]",
                     vif => {
                        '[1]' => {
                           backing => "kvm.[2].bridge.[1]",
                        },
                     },
                  },
               },
            },
            Createtty_linux => {
               Type     => "Root",
               TestNode => "root.[1]",
               vm => {
                  '[5]' => {
                     template => 'tty_linux',
                     vmstate  => 'poweroff',
                     installtype => 'fullclone',
                     #host     => "kvm.[x:vdnetmod:2]",
                     host     => "kvm.[1]",
                  },
               },
            },
            AddVIFsVM1=> {
               Type     => "VM",
               TestVM => "vm.[1]",
               vif => {
                  '[1]' => {
                     backing => "kvm.[1].bridge.[1]",
                  },
               },
            },
            AddVIFsVM2=> {
               Type     => "VM",
               TestVM => "vm.[2]",
               vif => {
                  '[1]' => {
                     backing => "kvm.[2].bridge.[1]",
                  },
               },
            },
            AddVIF2VM1=> {
               Type     => "VM",
               TestVM => "vm.[1]",
               vif => {
                  '[2]' => {
                     backing => "kvm.[1].bridge.[1]",
                  },
               },
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
            InitializeBridges=> {
               Type     => "Host",
               Testhost => "kvm.[1-2]",
               bridge => {
                  '[1]' => {
                     name => "br-int",
                  },
               },
            },
         },
      },
   )
}

########################################################################
#
# new --
#       This is the constructor for SampleTds
#
# Input:
#       none
#
# Results:
#       An instance/object of SampleTds class
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
   my $self = $class->SUPER::new(\%Infrastructure);
   return (bless($self, $class));
}

1;
