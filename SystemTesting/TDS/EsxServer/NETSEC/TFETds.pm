#!/usr/bin/perl
#########################################################################
#Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::NETSEC::TFETds;

#
# This file contains the structured hash for category, TFE tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
      @TESTS = ("MACMaskingandNegation",
                  "UnknownFilter");

      %TFE = (
        'MACMaskingandNegation' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'MACMasking and Negation',
         Summary          => 'To verify rules are applied ' .
                             'to the portgroup/port and working based ' .
                             'on the actions specified' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity,CAT_P0',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a VM to this dvpg' .
                             'Apply macmasking and negation ' .
                             'rules to this dvpg/port' .
                             'Verify the action',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
                  '[2]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[2].vmnic.[1]",
                    host => "host.[2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {

                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
          vm  => {
               '[1]'   => {
                  host  => "host.[1].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver     => "e1000",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver      => "e1000",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
         },
       },

        WORKLOADS => {
           Sequence => [
                        ['ConfigureIPv4Src'],
                        ['ConfigureIPv4Dst'],
                        ['AddFilter_Rule'],
                        ['TRAFFIC_2'],
                        ['TRAFFIC_3'],
                        ['TRAFFIC_4'],
                        ['TRAFFIC_1'],
                        ],
           ExitSequence   => [['DeleteFilter']],

           AddFilter_Rule => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Reconfigure => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourcemac'        => 'vm.[1].vnic.[1]',
                                   'sourceport'       => '11000',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'destinationmac'   => 'vm.[2].vnic.[1]',
                                   'sourcemacmask' => 'FF:FF:FF:00:00:00',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[2]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourcemac'        => 'vm.[1].vnic.[1]',
                                   'sourcemacmask'    => 'FF:FF:FF:00:00:00',
                                   'sourceport'       => '12000',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'destinationmac'   => 'vm.[2].vnic.[1]',
                                   'action'           => 'accept',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[3]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'sourceport'       => '13000',
                                   'sourceipnegation' => 'yes',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[4]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourceport'       => '14000',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'destinationipnegation' => 'yes',
                                   'action'           => 'Accept',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                             },
                         },
                   },

            },
            "DeleteFilter" => {
                  Type          => "PortGroup",
                  Testportgroup => "vc.[1].dvportgroup.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].filter.[1]",
            },
          "ConfigureIPv4Src" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               Ipv4        => "192.168.0.4",
               Netmask     => "255.255.255.0",
          },
          "ConfigureIPv4Dst" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[2].vnic.[1]",
               Ipv4        => "192.168.0.5",
               Netmask     => "255.255.255.0",
          },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               NoofInbound    => "1",
               L4Protocol     => "TCP",
               PortNumber     => "11000",
               ExpectedResult => "FAIL",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
          },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               NoofInbound    => "1",
               L4Protocol     => "TCP",
               PortNumber     => "12000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Accept",
          },
           "TRAFFIC_3" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               NoofInbound    => "1",
               TestDuration   => "5",
               L4Protocol     => "TCP",
               PortNumber     => "13000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Accept",
          },
           "TRAFFIC_4" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               NoofInbound    => "1",
               L4Protocol     => "TCP",
               PortNumber     => "14000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Accept",
          },
          "Verification_Accept" => {
              'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "vm.[1].vnic.[1]",
                  pktcount           => "100+",
               },
           },
         },
       },

        'RebootHost' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'RebootHost',
         Summary          => 'To verify rules are persistant ' .
                             'across Reboots' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity,hostreboot',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a vmknic to this dvpg' .
                             'Apply macmasking and negation ' .
                             'rules to this dvpg/port' .
                             'run the traffic' .
                             'verify the action' .
                             'Reboot the test host' .
                             'run the traffic' .
                             'Verify the action',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
                  '[2]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[2].vmnic.[1]",
                    host => "host.[2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {

                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
       },

        WORKLOADS => {
           Sequence => [
                        ['AddVmk1'],
                        ['AddVmk2'],
                        ['AddFilter_Rule'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ['RebootHost'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ],
           ExitSequence => [
                            ['DeleteVmknic1'],
                            ['DeleteVmknic2'],
                            ['DeleteFilter'],
                           ],

           AddFilter_Rule => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Reconfigure => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'host.[1].vmknic.[1]',
                                   'sourcemac'        => 'host.[1].vmknic.[1]',
                                   'sourcemacmask'    => 'FF:FF:FF:00:00:00',
                                   'sourceport'       => '14000',
                                   'action'           => 'accept',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[2]' => {
                                   'sourceip'         => 'host.[1].vmknic.[1]',
                                   'sourcemac'        => 'host.[1].vmknic.[1]',
                                   'sourcemacnegation' => 'yes',
                                   'destinationip'    => 'host.[2].vmknic.[1]',
                                   'destinationmac'   => 'host.[2].vmknic.[1]',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '1',
                                 },
                             },
                         },
                   },

            },
           "DeleteFilter" => {
                  Type          => "PortGroup",
                  Testportgroup => "vc.[1].dvportgroup.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].filter.[1]",
           },
           'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.20",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[1]",
                },
               },
           },
           'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.22",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[2]",
                },
               },
           },
           'DeleteVmknic1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               RemoveVmknic  => "host.[1].vmknic.[1]",
           },
           'DeleteVmknic2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               RemoveVmknic  => "host.[2].vmknic.[1]",
           },
           "RebootHost" => {
               Type           => "Host",
               TestHost       => "host.[1].x.x",
               reboot         => "yes",
            },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               NoofInbound    => "1",
               L4Protocol     => "TCP",
               PortNumber     => "14000",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
          },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "5",
               Pingpktsize    => "1000",
               NoofInbound    => "5",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               expectedresult => "fail",
          },
         },
       },

        'UnknownFilter' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'UNknownFilter',
         Summary          => 'To verify that adding unknown filter ' .
                             'does not cause PSOD on ESX Host' .
                             'on the actions specified' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => 'create VDS switch with dvpg'.
                             'Add and remove "dvfilter-unknown' .
                             'No PSOD',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
               },
             },
            },
          host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
       },

        WORKLOADS => {
           Sequence => [
                        ['AddFilter_Rule'],
                        ],
           ExitSequence   => [['DeleteFilter']],

           AddFilter_Rule => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Reconfigure => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-unknown',
                         },
                   },

            },
            "DeleteFilter" => {
                  Type          => "PortGroup",
                  Testportgroup => "vc.[1].dvportgroup.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].filter.[1]",
            },
         },
       },

       'FilterAddRemove' => {
         Category         => 'ESX Server',
         Component        => 'vmsafe-net',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'FilterAddRemove',
         Summary          => 'To verify rules are applied ' .
                             'through the slowpath and working based ' .
                             'on the actions specified' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity,CAT_P0',
         PMT              => '',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
       },

        WORKLOADS => {
           Sequence => [
                         ['AddFilter_Rule'],
                         ['DeleteFilter'],
                        ],
          Iterations => '9',
          ExitSequence   => [['AddFilter_Rule'],['DeleteFilter']],

           AddFilter_Rule => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Reconfigure => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1-50]' => {
                                   'sourceport'       => '17000',
                                   'dscptag'          => '40',
                                   'qostag'           => '5',
                                   'action'           => 'tag',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                             },
                         },
                   },

            },
            "DeleteFilter" => {
                  Type          => "PortGroup",
                  Testportgroup => "vc.[1].dvportgroup.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].filter.[1]",
            },
         },
       },

        'RebootVM' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'RebootVM',
         Summary          => 'To verify rules are persistent ' .
                             'across Vm reboots ' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity,hostreboot',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a VM to this dvpg' .
                             'Apply macmasking and negation ' .
                             'rules to this dvpg/port' .
                             'run the traffic' .
                             'verify the action' .
                             'Reboot the test VM' .
                             'run the traffic' .
                             'Verify the action',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
                  '[2]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[2].vmnic.[1]",
                    host => "host.[2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {

                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
          vm  => {
               '[1]'   => {
                  host  => "host.[1].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver      => "e1000",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver      => "e1000",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
         },
       },

        WORKLOADS => {
           Sequence => [
                        ['ConfigureIPv4Src'],
                        ['ConfigureIPv4Dst'],
                        ['AddFilter_Rule'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ['RebootVM'],
                        ['PowerOffVM'],
                        ['PowerOnVM'],
                        ['ConfigureIPv4Src'],
                        ['ConfigureIPv4Dst'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ],
           ExitSequence   => [['DeleteFilter']],

           AddFilter_Rule => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Reconfigure => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourcemac'        => 'vm.[1].vnic.[1]',
                                   'destinationmacmask' => 'FF:FF:FF:00:00:00',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'action'           => 'accept',
                                   'direction'        => 'both',
                                   'protocol'         => '1',
                                 },
                                '[2]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'sourceport'       => '15000',
                                   'sourceportnegation' => 'yes',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '11',
                                 },
                             },
                         },
                   },
            },
          "RebootVM" => {
               Type         => "VM",
               TestVM       => "vm.[1].x.x",
               Operation    => "reboot",
               waitforvdnet => 1,
          },
          "PowerOffVM" => {
               Type         => "VM",
               TestVM       => "vm.[1].x.x",
               vmstate      => "poweroff",
          },
          "PowerOnVM" => {
               Type         => "VM",
               TestVM       => "vm.[1].x.x",
               vmstate      => "poweron",
          },
          "ConfigureIPv4Src" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               Ipv4        => "192.168.0.4",
               Netmask     => "255.255.255.0",
          },
          "ConfigureIPv4Dst" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[2].vnic.[1]",
               Ipv4        => "192.168.0.5",
               Netmask     => "255.255.255.0",
          },
          "DeleteFilter" => {
                  Type          => "PortGroup",
                  Testportgroup => "vc.[1].dvportgroup.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].filter.[1]",
           },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               L4Protocol     => "UDP",
               PortNumber     => "15000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
          },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "5",
               Pingpktsize    => "1000",
               NoofInbound    => "5",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
          },
         },
       },

        'Vmotion' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'Vmotion',
         Summary          => 'To verify rules are persistent ' .
                             'after Vms are vmotioned ' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a VM to this dvpg' .
                             'Apply macmasking and negation ' .
                             'rules to this dvpg/port' .
                             'run the traffic' .
                             'verify the action' .
                             'Vmotion the test VM' .
                             'run the traffic' .
                             'Verify the action',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1-2].vmnic.[1]",
                    host => "host.[1-2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "2",
                     },
                     '[3]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                     '[4]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
          vm  => {
               '[1]'   => {
                  host  => "host.[1].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver     => "e1000",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
                  datastoreType    => "shared",
               },
               '[2]'   => {
                  host  => "host.[2].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver      => "e1000",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                     },
                  },
                  datastoreType    => "shared",
               },
         },
       },

        WORKLOADS => {
           Sequence => [
                        ['ConfigureIPv4Src'],
                        ['ConfigureIPv4Dst'],
                        ['AddVmk1'],
                        ['AddVmk2'],
                        ['AddFilter_Rule'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ['EnableVmotion'],
                        ['VmotionVM'],
                        ['DisableVmotion'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ],
           ExitSequence   => [
                              ['DeleteVmknic1'],
                              ['DeleteVmknic2'],
                              ['DeleteFilter'],
                             ],

           'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.20",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[3]",
                },
               },
            },
           'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.21",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[4]",
                },
               },
            },
          "ConfigureIPv4Src" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               Ipv4         => "192.168.0.4",
               Netmask      => "255.255.255.0",
          },
          "ConfigureIPv4Dst" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[2].vnic.[1]",
               Ipv4         => "192.168.0.5",
               Netmask      => "255.255.255.0",
          },
           'DeleteVmknic1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               RemoveVmknic  => "host.[1].vmknic.[1]",
           },
           'DeleteVmknic2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               RemoveVmknic  => "host.[2].vmknic.[1]",
           },
           "EnableVmotion" => {
               Type => "NetAdapter",
               TestAdapter => "host.[-1].vmknic.[1]",
               Tagging => "add",
               tagname => "VMotion",
            },
            "DisableVmotion" => {
               Type => "NetAdapter",
               TestAdapter => "host.[-1].vmknic.[1]",
               Tagging => "remove",
               tagname => "VMotion",
            },
            "VmotionVM"       => {
               Type           => "VM",
               TestVM         => "vm.[1].x.x",
               Vmotion        => "roundtrip",
               Iterations     => "3",
               DstHost        => "host.[2].x.x",
               Priority       => "high",
               Staytime       => "30",
               SleepBetweenCombos  => "30",
            },
           AddFilter_Rule => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Reconfigure => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourcemac'        => 'vm.[1].vnic.[1]',
                                   'sourcemacmask'    => 'FF:FF:FF:00:00:00',
                                   'sourceport'       => '16000',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'destinationmac'   => 'vm.[2].vnic.[1]',
                                   'action'           => 'accept',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[2]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'sourceport'       => '17000',
                                   'sourceipnegation' => 'yes',
                                   'destinationipnegation' => 'yes',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                             },
                         },
                   },

          },
          "DeleteFilter" => {
                  Type          => "PortGroup",
                  Testportgroup => "vc.[1].dvportgroup.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].filter.[1]",
            },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               L4Protocol     => "TCP",
               PortNumber     => "16000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Accept",
          },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               L4Protocol     => "TCP",
               PortNumber     => "17000",
               ExpectedResult => "FAIL",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
          },
          "Verification_Accept" => {
              'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "vm.[1].vnic.[1]",
                  pktcount           => "100+",
               },

           },
         },
       },

     'Vmknic' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'Vmknic',
         Summary          => 'To verify rules are working ' .
                             'when vmknic is connected ' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a Vmknic to this dvpg' .
                             'Apply macmasking and negation ' .
                             'rules to this dvpg/port' .
                             'run the traffic' .
                             'Verify the action',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
                  '[2]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[2].vmnic.[1]",
                    host => "host.[2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
       },

        WORKLOADS => {
           Sequence => [
                        ['AddVmk1'],
                        ['AddVmk2'],
                        ['AddFilter_Rule'],
                        ['TRAFFIC_2'],
                        ['TRAFFIC_1'],
                        ],
          ExitSequence   => [
                             ['DeleteVmknic1'],
                             ['DeleteVmknic2'],
                             ['DeleteFilter'],
                             ],

           'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.20",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[1]",
                },
               },
            },
           'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.21",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[2]",
                },
               },
            },
           'DeleteVmknic1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               RemoveVmknic  => "host.[1].vmknic.[1]",
           },
           'DeleteVmknic2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               RemoveVmknic  => "host.[2].vmknic.[1]",
           },
           AddFilter_Rule => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Reconfigure => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'host.[1].vmknic.[1]',
                                   'sourceport'       => '20000',
                                   'destinationip'    => 'host.[2].vmknic.[1]',
                                   'sourcemac'        => 'host.[1].vmknic.[1]',
                                   'sourcemacmask'    => 'FF:FF:FF:00:00:00',
                                   'action'           => 'accept',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[2]' => {
                                   'sourceip'         => 'host.[1].vmknic.[1]',
                                   'destinationip'    => 'host.[2].vmknic.[1]',
                                   'sourceport'       => '19000',
                                   'sourceportnegation' => 'yes',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                             },
                         },
                   },

          },
          "DeleteFilter" => {
                  Type          => "PortGroup",
                  Testportgroup => "vc.[1].dvportgroup.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].filter.[1]",
            },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               L4Protocol     => "TCP",
               PortNumber     => "20000",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
          },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               L4Protocol     => "TCP",
               PortNumber     => "19000",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
          },
         },
       },
        'DSCPTagging' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'DSCPtagging',
         Summary          => 'To verify rules for dSCP ' .
                             'Tagging is working ' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a VM to this dvpg' .
                             'Apply dscptagging ' .
                             'rules to this dvpg/port' .
                             'run the traffic' .
                             'Verify the action',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
                  '[2]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[2].vmnic.[1]",
                    host => "host.[2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
          vm  => {
               '[1]'   => {
                  host  => "host.[1].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver     => "e1000",
                        portgroup   => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver     => "e1000",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
         },
       },

       WORKLOADS => {
           Sequence => [
                        ['ConfigureIPv4Src'],
                        ['ConfigureIPv4Dst'],
                        ['AddFilter_Rule'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ],
        ExitSequence   => [['DeleteFilter']],

           AddFilter_Rule => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Reconfigure => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourceport'       => '19000',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'action'           => 'tag',
                                   'direction'        => 'outgoingPackets',
                                   'dscptag'          => '20',
                                   'protocol'         => '6',
                                 },
                                '[2]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'sourceport'       => '18000',
                                   'dscptag'          => '34',
                                   'action'           => 'tag',
                                   'direction'        => 'outgoingPackets',
                                   'protocol'         => '6',
                                 },
                             },
                         },
                   },

            },
          "DeleteFilter" => {
                  Type          => "PortGroup",
                  Testportgroup => "vc.[1].dvportgroup.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].filter.[1]",
            },
          "ConfigureIPv4Src" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               Ipv4         => "192.168.0.4",
               Netmask      => "255.255.255.0",
          },
          "ConfigureIPv4Dst" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[2].vnic.[1]",
               Ipv4         => "192.168.0.5",
               Netmask      => "255.255.255.0",
          },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "2",
               L4Protocol     => "TCP",
               PortNumber     => "19000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Tag1",
          },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "2",
               L4Protocol     => "TCP",
               PortNumber     => "18000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Tag2",
          },
          "Verification_Tag1" => {
              'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "dst",
                  pktcount           => "100+",
                  tos                => "0x50"
               },

           },
          "Verification_Tag2" => {
              'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "dst",
                  pktcount           => "100+",
                  tos                => "0x88"
               },

           },
         },
       },

       'QosTagging' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'QosTagging',
         Summary          => 'To verify rules for QOS Tagging ' .
                             'is working ' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a VM to this dvpg' .
                             'Apply Qos tagging  ' .
                             'rules to this dvpg/port' .
                             'run the traffic' .
                             'Verify the action',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
                  '[2]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[2].vmnic.[1]",
                    host => "host.[2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        ports   => "1",
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {

                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
          vm  => {
               '[1]'   => {
                  host  => "host.[1].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver     => "e1000",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver     => "e1000",
                        portgroup  => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
         },
       },

        WORKLOADS => {
           Sequence => [
                        ['ConfigureIPv4Src'],
                        ['ConfigureIPv4Dst'],
                        ['AddFilter_Rule'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ],
           ExitSequence   => [['DeleteFilter']],

           AddFilter_Rule => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Reconfigure => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourceport'       => '21000',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'qostag'           => '2',
                                   'action'           => 'tag',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[2]' => {
                                   'sourcemac'         => 'vm.[1].vnic.[1]',
                                   'destinationmac'    => 'vm.[2].vnic.[1]',
                                   'sourceport'       => '22000',
                                   'sourcemacnegation' => 'yes',
                                   'qostag'           => '5',
                                   'action'           => 'tag',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                             },
                         },
                   },

            },
          "DeleteFilter" => {
                  Type          => "PortGroup",
                  Testportgroup => "vc.[1].dvportgroup.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].filter.[1]",
            },
          "ConfigureIPv4Src" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               Ipv4         => "192.168.0.4",
               Netmask      => "255.255.255.0",
          },
          "ConfigureIPv4Dst" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[2].vnic.[1]",
               Ipv4         => "192.168.0.5",
               Netmask      => "255.255.255.0",
          },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               L4Protocol     => "TCP",
               PortNumber     => "21000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
          },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "20",
               L4Protocol     => "TCP",
               PortNumber     => "22000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Accept",
          },
          "Verification_Accept" => {
              'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "vm.[1].vnic.[1]",
                  pktcount           => "100+",
               },

           },
         },
       },
     'PortVmknic' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'PortVmknic',
         Summary          => 'To verify rules are working ' .
                             'when vmknic is connected ' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a Vmknic to this dvpg' .
                             'Apply macmasking and negation ' .
                             'rules to this dvpg/port' .
                             'run the traffic' .
                             'Verify the action',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
                  '[2]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[2].vmnic.[1]",
                    host => "host.[2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport  => {
                           '[1]' => {
                           },
                        },
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
       },

        WORKLOADS => {
           Sequence => [
                         ['AddVmk1'],
                         ['AddVmk2'],
                         ['AddAdv_config'],
                         ['AddPortFilter_Rule'],
                         ['TRAFFIC_2'],
                         ['TRAFFIC_1'],
                        ],
          ExitSequence   => [
                             ['DeleteVmknic1'],
                             ['DeleteVmknic2'],
                             ['DeletePortFilter'],
                             #['RemoveAdv_config'] #-PR-1068711
                             ],

           'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.20",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[1]",
                },
               },
            },
           'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.21",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[2]",
                },
               },
            },
           'DeleteVmknic1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               RemoveVmknic  => "host.[1].vmknic.[1]",
           },
           'DeleteVmknic2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               RemoveVmknic  => "host.[2].vmknic.[1]",
           },
           'AddAdv_config' => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Advanced => {
                    'overrideport' => {
                      'TrafficFilterandmarking' => 'allowed',
                    },
                 },
           },
           'RemoveAdv_config' => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Advanced => {
                    'overrideport' => {
                      'TrafficFilterandmarking' => 'disabled',
                    },
                 },
           },
           AddPortFilter_Rule => {
                 Type => "Port",
                 Testport => "vc.[1].dvportgroup.[1].dvport.[1]",
                 Reconfigurefilter => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'host.[1].vmknic.[1]',
                                   'sourceport'       => '20000',
                                   'destinationip'    => 'host.[2].vmknic.[1]',
                                   'sourcemac'        => 'host.[1].vmknic.[1]',
                                   'sourcemacmask'    => 'FF:FF:FF:00:00:00',
                                   'action'           => 'accept',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[2]' => {
                                   'sourceip'         => 'host.[1].vmknic.[1]',
                                   'destinationip'    => 'host.[2].vmknic.[1]',
                                   'sourceport'       => '19000',
                                   'sourceportnegation' => 'yes',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                             },
                         },
                   },

          },
          "DeletePortFilter" => {
                  Type          => "Port",
                  Testport      => "vc.[1].dvportgroup.[1].dvport.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].dvport.[1].filter.[1]",
            },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               L4Protocol     => "TCP",
               PortNumber     => "20000",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
          },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               L4Protocol     => "TCP",
               PortNumber     => "19000",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
          },
         },
       },
       'PortRebootHost' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'RebootHost',
         Summary          => 'To verify rules are persistant ' .
                             'across Reboots' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a vmknic to this dvpg' .
                             'Apply macmasking and negation ' .
                             'rules to this dvpg/port' .
                             'run the traffic' .
                             'verify the action' .
                             'Reboot the test host' .
                             'run the traffic' .
                             'Verify the action',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
                  '[2]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[2].vmnic.[1]",
                    host => "host.[2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport  => {
                           '[1]' => {
                           },
                        },
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {

                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
       },

        WORKLOADS => {
           Sequence => [
                        ['AddVmk1'],
                        ['AddVmk2'],
                        ['AddAdv_config'],
                        ['AddPortFilter_Rule'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ['RebootHost'],
                        ['TRAFFIC_1'],
                        ['TRAFFIC_2'],
                        ],
           ExitSequence => [
                            ['DeleteVmknic1'],
                            ['DeleteVmknic2'],
                            ['DeletePortFilter'],
                            #['RemoveAdv_config']   -PR-1068711
                           ],

           AddPortFilter_Rule => {
                 Type => "Port",
                 Testport => "vc.[1].dvportgroup.[1].dvport.[1]",
                 Reconfigurefilter => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'host.[1].vmknic.[1]',
                                   'sourcemac'        => 'host.[1].vmknic.[1]',
                                   'sourcemacmask'    => 'FF:FF:FF:00:00:00',
                                   'sourceport'       => '14000',
                                   'action'           => 'accept',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[2]' => {
                                   'sourceip'         => 'host.[1].vmknic.[1]',
                                   'sourcemac'        => 'host.[1].vmknic.[1]',
                                   'sourcemacnegation' => 'yes',
                                   'destinationip'    => 'host.[2].vmknic.[1]',
                                   'destinationmac'   => 'host.[2].vmknic.[1]',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '1',
                                 },
                             },
                         },
                   },

            },
           'AddAdv_config' => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Advanced => {
                    'overrideport' => {
                      'TrafficFilterandmarking' => 'allowed',
                    },
                 },
           },
           'RemoveAdv_config' => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Advanced => {
                    'overrideport' => {
                      'TrafficFilterandmarking' => 'disabled',
                    },
                 },
           },
           "DeletePortFilter" => {
                  Type          => "Port",
                  Testport      => "vc.[1].dvportgroup.[1].dvport.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].dvport.[1].filter.[1]",
           },
           'AddVmk1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.20",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[1]",
                },
               },
           },
           'AddVmk2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               vmknic => {
                "[1]" => {
                    ipv4address => "192.168.0.22",
                    netmask     => "255.255.255.0",
                    portgroup => "vc.[1].dvportgroup.[2]",
                },
               },
           },
           'DeleteVmknic1' => {
               Type => "Host",
               TestHost => "host.[1].x.[x]",
               RemoveVmknic  => "host.[1].vmknic.[1]",
           },
           'DeleteVmknic2' => {
               Type => "Host",
               TestHost => "host.[2].x.[x]",
               RemoveVmknic  => "host.[2].vmknic.[1]",
           },
           "RebootHost" => {
               Type           => "Host",
               TestHost       => "host.[1].x.x",
               reboot         => "yes",
            },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               NoofInbound    => "1",
               L4Protocol     => "TCP",
               PortNumber     => "14000",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
          },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Ping",
               TestDuration   => "5",
               Pingpktsize    => "1000",
               NoofInbound    => "5",
               TestAdapter    => "host.[1].vmknic.[1]",
               SupportAdapter => "host.[2].vmknic.[1]",
               expectedresult => "fail",
          },
         },
       },
        'PortMACMaskingandNegation' => {
         Category         => 'Networking',
         Component        => 'IO Filters',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'PortMACMasking and Negation',
         Summary          => 'To verify rules are applied ' .
                             'to the portgroup/port and working based ' .
                             'on the actions specified' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => 'Create VDS with dvpg' .
                             'Add a VM to this dvpg' .
                             'Apply macmasking and negation ' .
                             'rules to this port' .
                             'Verify the action',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1-2].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
                  '[2]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[2].vmnic.[1]",
                    host => "host.[2].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport  => {
                           '[1]' => {
                           },
                        },
                     },
                     '[2]'   => {
                        vds     => "vc.[1].vds.[2]",
                        ports   => "1",
                     },
               },

             },
            },
          host  => {
               '[1-2]'   => {

                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
          vm  => {
               '[1]'   => {
                  host  => "host.[1].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver     => "e1000",
                        portgroup  => "vc.[1].dvportgroup.[1]",
                     },
                  },
               },
               '[2]'   => {
                  host  => "host.[2].x.[x]",
                  vnic => {
                     '[1]'   => {
                        driver      => "e1000",
                        portgroup   => "vc.[1].dvportgroup.[2]",
                     },
                  },
               },
         },
       },

        WORKLOADS => {
           Sequence => [
                        ['ConfigureIPv4Src'],
                        ['ConfigureIPv4Dst'],
                        ['AddAdv_config'],
                        ['AddPortFilter_Rule'],
                        ['TRAFFIC_2'],
                        ['TRAFFIC_3'],
                        ['TRAFFIC_4'],
                        ['TRAFFIC_1'],
                        ],
           ExitSequence   => [
                              ['DeletePortFilter'],
                              #['RemoveAdv_config'] -PR-1068711
                             ],

           AddPortFilter_Rule => {
                 Type => "Port",
                 Testport => "vc.[1].dvportgroup.[1].dvport.[1]",
                 Reconfigurefilter => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourcemac'        => 'vm.[1].vnic.[1]',
                                   'sourceport'       => '11000',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'destinationmac'   => 'vm.[2].vnic.[1]',
                                   'sourcemacmask'    => 'FF:FF:FF:00:00:00',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[2]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourcemac'        => 'vm.[1].vnic.[1]',
                                   'sourcemacmask'    => 'FF:FF:FF:00:00:00',
                                   'sourceport'       => '12000',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'destinationmac'   => 'vm.[2].vnic.[1]',
                                   'action'           => 'accept',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[3]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'sourceport'       => '13000',
                                   'sourceipnegation' => 'yes',
                                   'action'           => 'drop',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                                '[4]' => {
                                   'sourceip'         => 'vm.[1].vnic.[1]',
                                   'sourceport'       => '14000',
                                   'destinationip'    => 'vm.[2].vnic.[1]',
                                   'destinationipnegation' => 'yes',
                                   'action'           => 'accept',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                             },
                         },
                   },

            },
           'AddAdv_config' => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Advanced => {
                    'overrideport' => {
                      'TrafficFilterandmarking' => 'allowed',
                    },
                 },
           },
           'RemoveAdv_config' => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Advanced => {
                    'overrideport' => {
                      'TrafficFilterandmarking' => 'disabled',
                    },
                 },
           },
           "DeletePortFilter" => {
                  Type          => "Port",
                  Testport      => "vc.[1].dvportgroup.[1].dvport.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].dvport.[1].filter.[1]",
           },
          "ConfigureIPv4Src" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[1].vnic.[1]",
               Ipv4         => "192.168.0.4",
               Netmask      => "255.255.255.0",
          },
          "ConfigureIPv4Dst" => {
               Type         => "NetAdapter",
               TestAdapter  => "vm.[2].vnic.[1]",
               Ipv4         => "192.168.0.5",
               Netmask      => "255.255.255.0",
          },
           "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               NoofInbound    => "1",
               L4Protocol     => "TCP",
               PortNumber     => "11000",
               ExpectedResult => "FAIL",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
          },
           "TRAFFIC_2" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               NoofInbound    => "1",
               L4Protocol     => "TCP",
               PortNumber     => "12000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Accept",
          },
           "TRAFFIC_3" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               NoofInbound    => "1",
               TestDuration   => "5",
               L4Protocol     => "TCP",
               PortNumber     => "13000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Accept",
          },
           "TRAFFIC_4" => {
               Type           => "Traffic",
               ToolName       => "Iperf",
               TestDuration   => "5",
               NoofInbound    => "1",
               L4Protocol     => "TCP",
               PortNumber     => "14000",
               TestAdapter    => "vm.[1].vnic.[1]",
               SupportAdapter => "vm.[2].vnic.[1]",
               Verification   => "Verification_Accept",
          },
          "Verification_Accept" => {
              'PktCapVerificaton' => {
                  verificationtype   => "pktcap",
                  target             => "vm.[1].vnic.[1]",
                  pktcount           => "100+",
               },
           },
         },
       },

       'PortFilterAddRemove' => {
         Category         => 'ESX Server',
         Component        => 'vmsafe-net',
         Product          => 'ESX',
         QCPath           => 'OP\Networking-FVT\TFE',
         TestName         => 'PortFilterAddRemove',
         Summary          => 'To verify rules are applied ' .
                             'through the slowpath and working based ' .
                             'on the actions specified' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Status           => 'Execution Ready',
         AutomationLevel  => 'Automated',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2' ,
         TestbedSpec   => {
            vc   => {
             '[1]'  => {
               datacenter => {
                     '[1]' => {
                        host => "host.[1].x.x",
                      },
               },
               vds  => {
                  '[1]'   => {
                    datacenter => "vc.[1].datacenter.[1]",
                    configurehosts => "add",
                    vmnicadapter => "host.[1].vmnic.[1]",
                    host => "host.[1].x.[x]",
                  },
               },
               dvportgroup  => {
                     '[1]'   => {
                        vds     => "vc.[1].vds.[1]",
                        dvport  => {
                           '[1]' => {
                           },
                        },
                     },
               },

             },
            },
          host  => {
               '[1]'   => {
                  vmnic => {
                     '[1]'   => {
                        driver => "any",
                     },
                  },
               },
          },
       },

        WORKLOADS => {
           Sequence => [
                         ['AddAdv_config'],
                         ['AddPortFilter_Rule'],
                         ['DeletePortFilter'],
                         ['AddPortFilter_Rule'],
                         ['DeletePortFilter'],
                         ['AddPortFilter_Rule'],
                         ['DeletePortFilter'],
                         ['AddPortFilter_Rule'],
                         ['DeletePortFilter'],
                         ['AddPortFilter_Rule'],
                         ['DeletePortFilter'],
                         ['AddPortFilter_Rule'],
                         ['DeletePortFilter'],
                         ['AddPortFilter_Rule'],
                         ['DeletePortFilter'],
                         ['AddPortFilter_Rule'],
                         ['DeletePortFilter'],
                         ['AddPortFilter_Rule'],
                         ['DeletePortFilter'],
                         ['AddPortFilter_Rule'],
                        ],
          ExitSequence   => [
                             ['DeletePortFilter'],
                            #['RemoveAdv_config'] -PR-1068711
                            ],

           AddPortFilter_Rule => {
                 Type => "Port",
                 Testport => "vc.[1].dvportgroup.[1].dvport.[1]",
                 Reconfigurefilter => "true",
                    'filter' => {
                        '[1]'  => {
                           'name' => 'dvfilter-generic-vmware',
                           'rule' => {
                                '[1-50]' => {
                                   'sourceport'       => '17000',
                                   'dscptag'          => '40',
                                   'qostag'           => '5',
                                   'action'           => 'tag',
                                   'direction'        => 'both',
                                   'protocol'         => '6',
                                 },
                             },
                         },
                   },

            },
           'AddAdv_config' => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Advanced => {
                    'overrideport' => {
                      'TrafficFilterandmarking' => 'allowed',
                    },
                 },
           },
           'RemoveAdv_config' => {
                 Type => "PortGroup",
                 Testportgroup => "vc.[1].dvportgroup.[1]",
                 Advanced => {
                    'overrideport' => {
                      'TrafficFilterandmarking' => 'disabled',
                    },
                 },
           },
           "DeletePortFilter" => {
                  Type          => "Port",
                  Testport      => "vc.[1].dvportgroup.[1].dvport.[1]",
                  DeleteFilter  => "vc.[1].dvportgroup.[1].dvport.[1].filter.[1]",
           },
         },
       },


  );
}

##########################################################################
# new --
#       This is the constructor for TFETds
#
# Input:
#       none
#
# Results:
#       An instance/object of TFETds class
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
      my $self = $class->SUPER::new(\%TFE);
      return (bless($self, $class));
}

1;


